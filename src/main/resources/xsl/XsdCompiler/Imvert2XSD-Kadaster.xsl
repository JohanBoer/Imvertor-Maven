<?xml version="1.0" encoding="UTF-8"?>
<!-- 
 * Copyright (C) 2016 Dienst voor het kadaster en de openbare registers
 * 
 * This file is part of Imvertor.
 *
 * Imvertor is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Imvertor is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Imvertor.  If not, see <http://www.gnu.org/licenses/>.
-->

<!-- adaptations
     
     after 1.27.1
        introduce <mark approach="elm"">
        remove estimations
        remove approach="att"

-->

<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:UML="omg.org/UML1.3"
    
    xmlns:imvert="http://www.imvertor.org/schema/system"
    xmlns:ext="http://www.imvertor.org/xsl/extensions"
    xmlns:imf="http://www.imvertor.org/xsl/functions"
    
    xmlns:ekf="http://EliotKimber/functions"

    exclude-result-prefixes="#all"
    version="2.0">

    <!-- TODO enhance - Schema indent nice and predictable; 
        attributes alphabetically sorted within element. Texts must be normalized-spaced. Needed for technical diffs. -->
    
    <xsl:import href="../common/Imvert-common.xsl"/>
    <xsl:import href="../common/Imvert-common-derivation.xsl"/>
    <xsl:import href="../common/Imvert-common-doc.xsl"/>
    
    <xsl:variable name="stylesheet-code">KAS</xsl:variable>
    <xsl:variable name="debugging" select="imf:debug-mode($stylesheet-code)"/>
    
    <xsl:variable name="avoid-substitutions" select="not(imf:boolean($use-substitutions))"/>
    
    <xsl:param name="config-file-path">unknown-file</xsl:param>
   
    <xsl:variable name="work-xsd-folder-url" select="imf:file-to-url(imf:get-config-string('system','work-xsd-folder-path'))"/>
    <xsl:variable name="xsd-subpath" select="encode-for-uri(imf:merge-parms(imf:get-config-string('cli','xsdsubpath')))"/>
    
    <xsl:variable name="is-forced-nillable" select="imf:boolean(imf:get-config-string('cli','forcenillable'))"/>
    
    <xsl:variable name="allow-scalar-in-union" select="imf:boolean($configuration-metamodel-file//features/feature[@name='allow-scalar-in-union'])"/>

    <xsl:variable name="meta-is-role-based" select="imf:boolean($configuration-metamodel-file//features/feature[@name='role-based'])"/>
    
    <!-- 
        What types result in an attribute in stead of an element? 
        This is always the case for ID values.
        It is not possible to mix the use of types on elements and attributes. 
        Note that Imvertor is element-oriented, not attribute-oriented.
    -->
    <xsl:variable name="xml-attribute-type" select="('ID')"/>

    <xsl:variable 
        name="external-schemas" 
        select="$imvert-document//imvert:package[imvert:stereotype/@id = ('stereotype-name-external-package','stereotype-name-system-package')]" 
        as="element(imvert:package)*"/>
    
    <xsl:variable 
        name="external-schema-names" 
        select="$external-schemas/imvert:name" 
        as="xs:string*"/>
    
    <xsl:variable 
        name="reference-classes" 
        select="$imvert-document//imvert:class[imvert:ref-master]" 
        as="node()*"/>
    
    <xsl:variable name="base-namespace" select="/imvert:packages/imvert:base-namespace"/>
    
    <xsl:template match="/">
        <imvert:schemas>
            <xsl:sequence select="imf:create-info-element('imvert:exporter',$imvert-document/imvert:packages/imvert:exporter)"/>
            <xsl:sequence select="imf:create-info-element('imvert:schema-exported',$imvert-document/imvert:packages/imvert:exported)"/>
            <xsl:sequence select="imf:create-info-element('imvert:schema-filter-version',imf:get-svn-id-info($imvert-document/imvert:packages/imvert:filters/imvert:filter/imvert:version))"/>
            <xsl:sequence select="imf:create-info-element('imvert:latest-svn-revision',concat($char-dollar,'Id',$char-dollar))"/>
            
            <!-- Schemas for external packages are not generated, but added to the release manually. -->
            <xsl:apply-templates select="$imvert-document/imvert:packages/imvert:package[not(imvert:name = $external-schema-names)]"/>
            
            <!-- 
                Do we need to reference external schema's? 
                If so, a reference is made to the name of the external schema.
            -->
            <xsl:variable name="externals" select="//imvert:type-package[.=$external-schema-names]"/>
            <xsl:for-each-group select="$externals" group-by=".">
                <xsl:for-each select="current-group()[1]"><!-- singleton imvert:type-package element--> 
                    <xsl:variable name="external-package" select="imf:get-construct-by-id(../imvert:type-package-id)"/>
                    <imvert:schema>
                        <xsl:sequence select="imf:create-info-element('imvert:name',$external-package/imvert:name)"/>
                        <xsl:sequence select="imf:create-info-element('imvert:prefix',$external-package/imvert:short-name)"/>
                        <xsl:sequence select="imf:create-info-element('imvert:namespace',$external-package/imvert:namespace)"/>
                        <xsl:choose>
                            <xsl:when test="imf:boolean($external-schemas-reference-by-url)">
                                <xsl:comment>Referenced by URL</xsl:comment>
                                <xsl:sequence select="imf:create-info-element('imvert:result-file-subpath',$external-package/imvert:location)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:comment>Referenced by local path</xsl:comment>
                                <xsl:variable name="schema-subpath" select="imf:get-xsd-filesubpath($external-package)"/>
                                <xsl:variable name="file-fullpath" select="imf:get-xsd-filefullpath($external-package)"/>
                                <xsl:sequence select="imf:create-info-element('imvert:result-file-subpath',$schema-subpath)"/>
                                <xsl:sequence select="imf:create-info-element('imvert:result-file-fullpath',$file-fullpath)"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </imvert:schema>
                </xsl:for-each>
            </xsl:for-each-group>
            <!-- add an external package that is a sentinel if not yet added -->
            <xsl:for-each select="$imvert-document/imvert:packages/imvert:package[imf:boolean(imvert:sentinel) and not(imvert:name = $externals)]">
                <xsl:variable name="external-package" select="."/>
                <imvert:schema>
                    <xsl:sequence select="imf:create-info-element('imvert:name',$external-package/imvert:name)"/>
                    <xsl:sequence select="imf:create-info-element('imvert:prefix',$external-package/imvert:short-name)"/>
                    <xsl:sequence select="imf:create-info-element('imvert:namespace',$external-package/imvert:namespace)"/>
                    <xsl:choose>
                        <xsl:when test="imf:boolean($external-schemas-reference-by-url)">
                            <xsl:comment>Referenced by URL</xsl:comment>
                            <xsl:sequence select="imf:create-info-element('imvert:result-file-subpath',$external-package/imvert:location)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:comment>Referenced by local path</xsl:comment>
                            <xsl:variable name="schema-subpath" select="imf:get-xsd-filesubpath($external-package)"/>
                            <xsl:variable name="file-fullpath" select="imf:get-xsd-filefullpath($external-package)"/>
                            <xsl:sequence select="imf:create-info-element('imvert:result-file-subpath',$schema-subpath)"/>
                            <xsl:sequence select="imf:create-info-element('imvert:result-file-fullpath',$file-fullpath)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </imvert:schema>
            </xsl:for-each>
        </imvert:schemas>
    </xsl:template>
    
    <!-- Internal packages processed here. -->
    <xsl:template match="imvert:package">
        <xsl:variable name="this-package" select="."/>
        <xsl:variable name="this-package-is-referencing" select="$this-package/imvert:ref-master"/>
        
        <xsl:variable name="this-package-associations" select="
            ($this-package/imvert:class/imvert:associations/imvert:association, 
            $this-package/imvert:class/imvert:attributes/imvert:attribute)" as="node()*"/>
        <xsl:variable name="this-package-associated-classes" select="$document-classes[imvert:id=$this-package-associations/imvert:type-id]" as="node()*"/>
        <xsl:variable name="this-package-associated-types" select="$this-package-associated-classes/imvert:name" as="xs:string*"/>
        <xsl:variable name="this-package-associated-type-ids" select="$this-package-associated-classes/imvert:id" as="xs:string*"/>
        
        <xsl:variable name="this-package-referenced-linkable-subclasses" as="node()*">
            <xsl:for-each select="$this-package-associated-classes">
                <xsl:sequence select="imf:get-linkable-subclasses-or-self(.)"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="this-package-referenced-substitutable-subclasses-or-self" as="node()*">
            <xsl:if test="$avoid-substitutions">
                <xsl:for-each select="$this-package-associated-classes">
                    <xsl:sequence select="imf:get-substitutable-subclasses(.,true())"/>
                </xsl:for-each>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="this-package-referenced-substitutable-subclasses" as="node()*">
            <xsl:if test="$avoid-substitutions">
                <xsl:for-each select="$this-package-associated-classes">
                    <xsl:sequence select="imf:get-substitutable-subclasses(.,false())"/>
                </xsl:for-each>
            </xsl:if>
        </xsl:variable>
        
        <xsl:variable name="schema-version" select="imvert:version"/>
        <xsl:variable name="schema-phase" select="imvert:phase"/>
        <xsl:variable name="schema-release" select="imf:get-release(.)"/>
        
        <!-- historical note: we removed nsim-tally, and introduced a second step: the import XSL -->
        
        <xsl:variable name="schema-subpath" select="imf:get-xsd-filesubpath(.)"/>
        <xsl:variable name="schemafile" select="imf:get-xsd-filefullpath(.)"/>
        <imvert:schema> 
            <xsl:sequence select="imvert:name"/>
            <xsl:sequence select="imf:create-info-element('imvert:prefix',imvert:short-name)"/>
            <xsl:sequence select="imf:create-info-element('imvert:is-referencing',$this-package-is-referencing)"/>
            <xsl:sequence select="imf:create-info-element('imvert:namespace',imf:get-namespace(.))"/>
            <xsl:sequence select="imf:create-info-element('imvert:result-file-subpath',$schema-subpath)"/>
            <xsl:sequence select="imf:create-info-element('imvert:result-file-fullpath',$schemafile)"/>
        
            <xs:schema>
                <!-- schema attributes -->
                <xsl:attribute name="targetNamespace" select="imf:get-namespace(.)"/>
                <xsl:attribute name="elementFormDefault" select="'qualified'"/>
                <xsl:attribute name="attributeFormDefault" select="'unqualified'"/>
                
                <!-- set version attribute to the version number -->
                <xsl:attribute name="version" select="concat($schema-version,'-',$schema-phase)"/>
        
                <!-- set my own namespaces (qualified) -->
                <xsl:namespace name="{imvert:short-name}" select="imf:get-namespace(.)"/>
                
                <!-- version info -->
                <xsl:sequence select="imf:get-annotation(.,imf:get-schema-info(.),imf:get-appinfo-version(.))"/>
                
                <!-- XSD complextypes -->
                <xsl:apply-templates select="imvert:class[not(imvert:stereotype/@id = ('stereotype-name-enumeration','stereotype-name-codelist','stereotype-name-simpletype'))]"/>
            
                <!-- XSD simpletypes -->
                <xsl:apply-templates select="imvert:class[imvert:stereotype/@id = ('stereotype-name-simpletype')]"/>
  
                <!-- XSD enumerations -->
                <xsl:apply-templates select="imvert:class[imvert:stereotype/@id = ('stereotype-name-enumeration','stereotype-name-codelist')]"/>
                
                <?x
                <!-- simple type attributes for attributes types that restrict a simple type; needed to set nilReason attribute -->
                <xsl:apply-templates 
                    select="imvert:class/imvert:attributes/imvert:attribute[(imvert:stereotype/@id = ('stereotype-name-voidable') or $is-forced-nillable) and imf:is-restriction(.)]"
                    mode="nil-reason">
                    <xsl:with-param name="package-name" select="$this-package/imvert:name"/>
                </xsl:apply-templates>
                x?>
                
                <xsl:if test="imvert:class/imvert:attributes/imvert:attribute[imvert:type-name='scalar-date' and imvert:type-modifier='?']">
                    <xs:simpleType name="Fixtype_incompleteDate">
                        <xsl:sequence select="imf:create-fixtype-property('scalar-date')"/>
                    </xs:simpleType>
                </xsl:if> 
                <xsl:if test="imvert:class/imvert:attributes/imvert:attribute[imvert:type-name=('scalar-datetime') and imvert:type-modifier='?']">
                    <xs:simpleType name="Fixtype_incompleteDateTime">
                        <xsl:sequence select="imf:create-fixtype-property('scalar-datetime')"/>
                    </xs:simpleType>
                </xsl:if> 
                <xsl:if test="imvert:class/imvert:attributes/imvert:attribute[imvert:type-name=('scalar-time') and imvert:type-modifier='?']">
                    <xs:simpleType name="Fixtype_incompleteTime">
                        <xsl:sequence select="imf:create-fixtype-property('scalar-time')"/>
                    </xs:simpleType>
                </xsl:if> 
            </xs:schema>
        
        </imvert:schema>
    </xsl:template>
        
    <xsl:template match="imvert:class[imvert:stereotype/@id = ('stereotype-name-enumeration')]">
        <xs:simpleType name="{imvert:name}">
            <xsl:sequence select="imf:get-annotation(.)"/>
            <xs:restriction base="xs:string">
                <xsl:for-each select="imvert:enum">
                    <xsl:sort select="imf:calculate-position(.)" data-type="number" order="ascending"/>
                    <xs:enumeration value="{.}"/>
                </xsl:for-each>
            </xs:restriction>
        </xs:simpleType>
    </xsl:template>    
    
    <xsl:template match="imvert:class[imvert:stereotype/@id = ('stereotype-name-codelist')]">
        <xs:simpleType name="{imvert:name}">
            <xsl:variable name="data-location" select="imf:get-appinfo-location(.)"/>
            <xsl:sequence select="imf:get-annotation(.,(),$data-location)"/>
            <xs:restriction base="xs:string">
                <xsl:sequence select="imf:create-datatype-property(.)"/>
            </xs:restriction>
        </xs:simpleType>
    </xsl:template>    
    
    <xsl:template match="imvert:class[imvert:stereotype/@id = ('stereotype-name-simpletype')]">
        <xsl:choose>
            <xsl:when test="imvert:attributes/* or imvert:associations/*">
                <xsl:sequence select="imf:create-xml-debug-comment(.,'Datatype with data elements or associations')"/>
                <xsl:next-match/> <!-- i.e. template that matches imvert:class --> 
            </xsl:when>
            <xsl:when test="imvert:union">
                <xsl:sequence select="imf:create-xml-debug-comment(.,'Datatype is a union')"/>
                <xs:simpleType name="{imvert:name}">
                    <xsl:sequence select="imf:get-annotation(.)"/>
                    <xsl:apply-templates select="imvert:union"/>
                </xs:simpleType>
            </xsl:when>
            <xsl:otherwise>
                <!-- A type like zipcode -->
                <xsl:sequence select="imf:create-xml-debug-comment(.,'A simple datatype')"/>
                <xs:simpleType name="{imvert:name}">
                    <xsl:sequence select="imf:get-annotation(.)"/>
                    <xs:restriction base="xs:string">
                        <xsl:sequence select="imf:create-datatype-property(.)"/>
                    </xs:restriction>
                </xs:simpleType>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="imvert:class[imvert:stereotype/@id = ('stereotype-name-service')]">
        
        <xsl:variable name="method" select="imf:get-most-relevant-compiled-taggedvalue(.,'##CFG-TV-ENVELOPEMETHOD')"/>
     
        <xsl:variable name="type-name" select="imvert:name"/>
        <xsl:variable name="package-name" select="parent::imvert:package/imvert:name"/>

        <xsl:variable name="assocs" select="imvert:associations/imvert:association"/>
        <xsl:variable name="assoc-pr" select="$assocs[imvert:type-name='ProcesResultaat']"/>
        <xsl:variable name="assoc-pg" select="$assocs[imvert:type-name='ProductGegevens']"/>
        <xsl:variable name="assoc-log" select="$assocs[imvert:type-name='Log']"/>
        <xsl:variable name="assoc-proces" select="$assocs except ($assoc-pr,$assoc-pg,$assoc-log)"/> <!-- rest of the assocs must be products -->
        
        <xsl:variable name="targets" select="for $target in $assocs/imvert:type-id return imf:get-construct-by-id($target)"/>
        <xsl:variable name="products" select="$targets[imvert:stereotype/@id = ('stereotype-name-product')]"/>
      
        <!-- get the name of the first association that has a name entered by the modeller. --> 
        <xsl:variable name="rname" select="($assocs/imvert:name[not(@origin = 'system')])[1]"/>
        <xsl:variable name="results-name" select="if ($products[2] or empty($rname)) then 'GeleverdProduct' else $rname"/>
        
        <xsl:variable name="EnvelopProces-prefix" select="'pr'"/>
        <xsl:variable name="EnvelopProduct-prefix" select="'pg'"/>
        <xsl:variable name="EnvelopLog-prefix" select="'lg'"/>
        
        <xsl:variable name="is-request" select="ends-with(imvert:name,'Request')"/>
        <xsl:variable name="is-response" select="ends-with(imvert:name,'Response')"/>
        
        <xs:element name="{$type-name}">
            <xs:complexType>
                <xs:sequence>
                    <xsl:if test="exists($assoc-pr)">
                        <xs:element ref="{$EnvelopProces-prefix}:ProcesVerwerking" minOccurs="{$assoc-pr/imvert:min-occurs}" maxOccurs="{$assoc-pr/imvert:max-occurs}"/>
                    </xsl:if> 
                    <xsl:if test="exists($assoc-pg)">
                        <xs:element ref="{$EnvelopProduct-prefix}:ProductGegevens" minOccurs="{$assoc-pg/imvert:min-occurs}" maxOccurs="{$assoc-pg/imvert:max-occurs}"/>
                    </xsl:if> 
                    <xsl:variable name="products" as="element()*">
                        <xsl:for-each select="$assoc-proces">
                            <xsl:variable name="target" select="imf:get-construct-by-id(imvert:type-id)"/>
                            <xsl:variable name="min-occurs" select="imvert:min-occurs"/>
                            <xsl:variable name="max-occurs" select="imvert:max-occurs"/>
                            
                            <!-- test if the target is a product -->
                            <xsl:sequence select="
                                if (not($target/imvert:stereotype/@id = ('stereotype-name-process'))) 
                                then imf:msg(.,'ERROR','Target in [1] is not [2]',(imf:get-config-stereotypes('stereotype-name-service'),imf:get-config-stereotypes('stereotype-name-product'))) else ()"/>
                            
                            <xs:element ref="{imf:get-type($target/imvert:name,$target/parent::imvert:package/imvert:name)}" minOccurs="{$min-occurs}" maxOccurs="{$max-occurs}"/>
                        </xsl:for-each>
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test="$is-request">
                            <xs:element name="verzoek">
                                <xs:complexType>
                                    <xs:choice>
                                        <xsl:sequence select="$products"/>
                                    </xs:choice>
                                </xs:complexType>
                            </xs:element>
                        </xsl:when>
                        <xsl:when test="$is-response">
                            <xs:element name="antwoord">
                                <xs:complexType>
                                    <xs:choice>
                                        <xsl:sequence select="$products"/>
                                    </xs:choice>
                                </xs:complexType>
                            </xs:element>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:sequence select="imf:msg(.,'ERROR','This service is not a request or response',())"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:if test="exists($assoc-log)">
                        <xs:element ref="{$EnvelopLog-prefix}:Log"  minOccurs="{$assoc-log/imvert:min-occurs}" maxOccurs="{$assoc-log/imvert:max-occurs}"/>
                    </xsl:if>
                </xs:sequence>
            </xs:complexType>
        </xs:element>
    </xsl:template>
    
    <xsl:template match="imvert:class">
        <xsl:variable name="package-name" select="parent::imvert:package/imvert:name"/>
        <xsl:variable name="type-name" select="imvert:name"/>
        <xsl:variable name="type-id" select="imvert:id"/>
        <xsl:variable name="primitive" select="imvert:primitive"/>
        <xsl:variable name="supertype" select="imvert:supertype[not(imvert:stereotype/@id = ('stereotype-name-static-generalization'))][1]"/>
        <xsl:variable name="supertype-name" select="$supertype/imvert:type-name"/>
        <xsl:variable name="supertype-package-name" select="$supertype/imvert:type-package"/>
        <xsl:variable name="supertype-substitutiongroup" select="$supertype/imvert:xsd-substitutiongroup"/> 
        <xsl:variable name="abstract" select="imvert:abstract"/>
        <xsl:variable name="is-includable" select="imf:boolean(imf:get-tagged-value(.,'##CFG-TV-INCLUDABLE'))"/>
        <xsl:variable name="data-location" select="imf:get-appinfo-location(.)"/>
        <!-- all classes are element + complex type declaration; except for datatypes (<<datatype>>). -->
        <xsl:variable name="is-choice-member" select="$document-classes[imvert:stereotype/@id = ('stereotype-name-union') and imvert:attributes/imvert:attribute/imvert:type-id = $type-id]"/>
        
        <xsl:variable name="is-keyed" select="imvert:attributes/imvert:attribute/imvert:stereotype/@id = 'stereotype-name-key'"/><!-- keyed classes are never represented on their own -->
        
        <xsl:variable name="ref-master" select="if (imvert:ref-master) then imf:get-construct-by-id(imvert:ref-master-id) else ()"/>
        <xsl:variable name="ref-masters" select="if ($ref-master) then ($ref-master,imf:get-superclasses($ref-master)) else ()"/>
        <xsl:variable name="ref-master-idatts" select="for $m in $ref-masters return $m/imvert:attributes/imvert:attribute[imf:boolean(imvert:is-id)]"/>
        <xsl:variable name="ref-master-identifiable-subtype-idatts" select="for $s in imf:get-subclasses($ref-master) return imf:get-id-attribute($s)"/>
        <xsl:variable name="ref-master-identifiable-subtypes-with-domain" select="for $a in $ref-master-identifiable-subtype-idatts return if (imf:get-tagged-value($a,'##CFG-TV-DOMAIN')) then $a/ancestor::imvert:class else ()"/>
        
        <xsl:variable name="use-identifier-domains" select="imf:boolean(imf:get-xparm('cli/identifierdomains','no'))"/>
        <xsl:variable name="domain-values" select="for $i in $ref-master-idatts return imf:get-tagged-value($i,'##CFG-TV-DOMAIN')"/>
        <xsl:variable name="domain-value" select="$domain-values[1]"/>
        
        <xsl:variable name="formal-pattern" select="imf:get-facet-pattern(.)"/>
        
        <xsl:sequence select="imf:create-xml-debug-comment(.,'Base class processing')"/>
        <xsl:if test="(not(imvert:stereotype/@id = ('stereotype-name-simpletype')) or $is-choice-member) and not($is-keyed)">
            <xsl:sequence select="imf:create-xml-debug-comment(.,'A union element, or not a datatype and not keyed')"/>
            <xs:element name="{$type-name}" type="{imf:get-type($type-name,$package-name)}" abstract="{$abstract}">
                <xsl:choose>
                    <xsl:when test="not($supertype-name and not($avoid-substitutions))">
                        <!-- nothing -->
                    </xsl:when>
                    <xsl:when test="$supertype-substitutiongroup = $name-none">
                        <!-- nothing: explicit skip of this link to the subsitution group -->
                    </xsl:when>
                    <xsl:when test="$supertype-substitutiongroup">
                        <xsl:attribute name="substitutionGroup" select="imf:get-type($supertype-substitutiongroup,$supertype-package-name)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:attribute name="substitutionGroup" select="imf:get-type($supertype-name,$supertype-package-name)"/>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:sequence select="imf:get-annotation(.,(),$data-location)"/>
            </xs:element>
        </xsl:if>
        
        <xsl:variable name="content" as="element()?">
            <xsl:choose>
                <xsl:when test="imvert:stereotype/@id = ('stereotype-name-system-reference-class') and $use-identifier-domains and not($supertype-name) and $domain-value">
                    <complex>
                        <xsl:sequence select="imf:create-xml-debug-comment(.,'Has a domain value')"/>
                        <xs:simpleContent>
                            <xs:extension base="xs:string">
                                <xs:attribute ref="xlink:href" use="optional"/>
                                <xs:attribute name="domein" use="optional" fixed="{$domain-value}"/>
                            </xs:extension>
                        </xs:simpleContent>
                    </complex>
                </xsl:when>
                <xsl:when test="imvert:stereotype/@id = ('stereotype-name-system-reference-class') and $use-identifier-domains and exists($ref-master-identifiable-subtypes-with-domain)">
                    <complex>
                        <xsl:sequence select="imf:create-xml-debug-comment(.,'Reference master has (some) identifiable subtypes that have a domain')"/>
                        <xs:simpleContent>
                            <xs:extension base="xs:string">
                                <xs:attribute ref="xlink:href" use="optional"/>
                                <xs:attribute name="domein" use="optional" type="xs:string"/>
                            </xs:extension>
                        </xs:simpleContent>
                    </complex>
                </xsl:when>
                <xsl:when test="imvert:stereotype/@id = ('stereotype-name-system-reference-class') and not($supertype-name)">
                    <complex>
                        <xsl:sequence select="imf:create-xml-debug-comment(.,'No supertypes, no domain processing')"/>
                        <xs:simpleContent>
                            <xs:extension base="xs:string">
                                <xs:attribute ref="xlink:href" use="optional"/><!-- sinds 1.61 -->
                            </xs:extension>
                        </xs:simpleContent>
                    </complex>
                </xsl:when>
                <xsl:when test="imvert:stereotype/@id = ('stereotype-name-union')">
                    <!-- attributes of a NEN3610 union, i.e. a choice between classes. The choice is a specialization of a datatype -->
                    <xsl:variable name="atts">
                        <xsl:for-each select="imvert:attributes/imvert:attribute">
                            <xsl:sort select="imf:calculate-position(.)" data-type="number" order="ascending"/>
                            <xsl:variable name="defining-class" select="imf:get-defining-class(.)"/>   
                            <xsl:variable name="defining-class-subclasses" select="imf:get-subclasses($defining-class)"/>   
                            
                            <xsl:variable name="defining-class-is-datatype" select="$defining-class/imvert:stereotype/@id = (
                                ('stereotype-name-simpletype','stereotype-name-enumeration','stereotype-name-codelist','stereotype-name-complextype','stereotype-name-union'))"/>   
                            <xsl:variable name="defining-class-is-primitive" select="exists(imvert:primitive)"/>   
                            <xsl:choose>
                                <xsl:when test="$defining-class-is-datatype or $defining-class-is-primitive">
                                    <xsl:sequence select="imf:create-xml-debug-comment(.,'A choice member, which is a datatype')"/>
                                    <xsl:sequence select="imf:create-element-property(.)"/>
                                </xsl:when>
                                <xsl:when test="empty($defining-class) and $allow-scalar-in-union">
                                    <xsl:sequence select="imf:create-xml-debug-comment(.,'A choice member, which is a scalar type')"/>
                                    <xsl:sequence select="imf:create-element-property(.)"/>
                                </xsl:when>
                                <xsl:when test="empty($defining-class)">
                                    <xsl:sequence select="imf:msg(.,'ERROR', 'Unable to create a union of scalar types',())"/> <!-- IM-291 -->
                                </xsl:when>
                                <xsl:when test="imf:is-linkable($defining-class) and imf:boolean($buildcollection) and exists($defining-class-subclasses)"> 
                                    <!-- insert the subtypes rather than the abstract supertype -->
                                    <xsl:sequence select="imf:create-xml-debug-comment(.,'A choice member, linkable, abstract')"/>
                                    <xsl:for-each select="($defining-class,$defining-class-subclasses)">
                                        <xs:element ref="{imf:get-reference-class-name(.)}"/>
                                    </xsl:for-each>
                                </xsl:when>
                                <xsl:when test="imf:is-linkable($defining-class) and imf:boolean($buildcollection)"> 
                                    <!-- when the class is linkable, and using collections, use the reference element name -->
                                    <xsl:sequence select="imf:create-xml-debug-comment(.,'A choice member, linkable')"/>
                                    <xs:element ref="{imf:get-reference-class-name($defining-class)}"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:sequence select="imf:create-xml-debug-comment(.,'A choice member')"/>
                                    <xsl:variable name="minOccurs" select="if (imvert:min-occurs) then imvert:min-occurs else '1'"/>
                                    <xsl:variable name="maxOccurs" select="if (imvert:max-occurs) then imvert:max-occurs else '1'"/>
                                    <xs:element ref="{imf:get-qname($defining-class)}" minOccurs="{$minOccurs}" maxOccurs="{$maxOccurs}"/>  
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>
                    </xsl:variable>
                    <xsl:if test="$atts">
                        <complex>
                            <xs:choice>
                                <xsl:attribute name="minOccurs" select="if (imvert:min-occurs) then imvert:min-occurs else '1'"/>
                                <xsl:attribute name="maxOccurs" select="if (imvert:max-occurs) then imvert:max-occurs else '1'"/>
                                <xsl:sequence select="imf:create-xml-debug-comment(.,'A number of choices')"/>
                                <xsl:sequence select="$atts"/>
                            </xs:choice>
                        </complex>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="imvert:stereotype/@id = ('stereotype-name-complextype') and exists($formal-pattern)"><!-- IM-325 -->
                    <simple>
                        <xs:annotation>
                            <xs:documentation>This complex datatype is transformed to a simple type because a content pattern is defined.</xs:documentation>
                        </xs:annotation>
                        <xs:restriction base="xs:string">
                            <xs:pattern value="{$formal-pattern}"/>
                        </xs:restriction>
                    </simple>
                </xsl:when>
                <xsl:when test="imvert:stereotype/@id = ('stereotype-name-simpletype') and exists($formal-pattern)">
                    <simple>
                        <xs:restriction base="xs:string">
                            <xs:pattern value="{$formal-pattern}"/>
                        </xs:restriction>
                    </simple>
                </xsl:when>
                
                <xsl:otherwise>
                    <complex>
                        <!-- XML elements are declared first -->
                        <xsl:variable name="atts" as="item()*">
                            <!-- 
                            UML Attribute positions default to 100. 
                            UML Association positions default to 200.
                            If all positions are explicitly set, use any value above 300 for convenience.
                            -->
                            <xsl:for-each select="imvert:attributes/imvert:attribute[not(imvert:type-name=$xml-attribute-type)] | imvert:associations/imvert:association">
                                <xsl:sort select="imf:calculate-position(.)" data-type="number" order="ascending"/>
                                <xsl:sequence select="imf:create-element-property(.)"/>
                            </xsl:for-each>
                            <?x associates komen niet meer voor?
                            <!-- then add associates for association class -->
                            <xsl:if test="imvert:associates">
                                <xsl:variable name="assoc-id" select="imvert:associates/imvert:target/imvert:id"/>
                                <xsl:variable name="association-class" select="$document//imvert:class[imvert:id=$assoc-id]"/>
                                <xs:element ref="{imf:get-qname($association-class)}"/>
                            </xsl:if>
                            ?>
                        </xsl:variable>
                        <xsl:if test="exists($atts)">
                            <xs:sequence>
                                <xsl:sequence select="$atts"/>
                            </xs:sequence>
                        </xsl:if>
                        <xsl:sequence select="imf:add-xmlbase($is-includable)"/>
                        
                        <!-- XML attributes are declared last -->
                        <!-- when <<ObjectType>> and no supertypes, assign id. -->
                        <!-- TODO enhance / Check if external schema provides ID
                            This assumes that any superclass taken from an external schema will provide the ID attribute. 
                            This should however be checked formally.
                            For kadaster schema's this is always the case, as may only inherit from AbstractFeatureType which defines an ID.
                        --> 
                        
                        <!-- IM-124 xml attribute id soms niet nodig -->
                        <xsl:variable name="incoming-refs" select="imf:get-references(.)"/>
                        <xsl:variable name="super-incoming-refs" select="for $c in imf:get-superclasses(.) return imf:get-references($c)"/>
                        
                        <xsl:if test="imvert:stereotype/@id = ('stereotype-name-objecttype') and exists($incoming-refs) and not(exists($super-incoming-refs))">
                            <xs:attribute name="id" type="xs:ID" use="optional"/>
                        </xsl:if>
                        <xsl:for-each select="imvert:attributes/imvert:attribute[imvert:type-name=$xml-attribute-type]">
                            <xsl:sort select="imf:calculate-position(.)" data-type="number" order="ascending"/>
                            <xsl:sequence select="imf:create-attribute-property(.)"/>
                        </xsl:for-each>
                    </complex>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="$is-keyed">
                <!-- skip -->
            </xsl:when>
            <xsl:when test="$content/self::complex">
                <xs:complexType>
                    <xsl:attribute name="name" select="$type-name"/>
                    <xsl:attribute name="abstract" select="$abstract"/>
                    <xsl:choose>
                        <xsl:when test="$supertype-name">
                            <xs:complexContent>
                                <xs:extension base="{imf:get-type($supertype-name,$supertype-package-name)}">
                                    <xsl:if test="exists($content/*)">
                                        <xsl:sequence select="$content/node()"/>
                                    </xsl:if>
                                </xs:extension>
                            </xs:complexContent>
                        </xsl:when>
                        <xsl:when test="exists($content/*)">
                            <xsl:sequence select="$content/node()"/>
                        </xsl:when>
                    </xsl:choose>      
                </xs:complexType>
            </xsl:when>
            <xsl:otherwise>
                <xs:simpleType>
                    <xsl:attribute name="name" select="$type-name"/>
                    <xsl:choose>
                        <xsl:when test="$supertype-name">
                            <xs:simpleContent>
                                <xs:extension base="{imf:get-type($supertype-name,$supertype-package-name)}">
                                    <xsl:if test="exists($content/*)">
                                        <xsl:sequence select="$content/node()"/>
                                    </xsl:if>
                                </xs:extension>
                            </xs:simpleContent>
                        </xsl:when>
                        <xsl:when test="exists($content/*)">
                            <xsl:sequence select="$content/node()"/>
                        </xsl:when>
                    </xsl:choose>      
                </xs:simpleType>
            </xsl:otherwise>
        </xsl:choose>
                
    </xsl:template>
    
    <?x
    <!-- 
        Create a simpletype from which a voidable simpletype can inherit (through restriction); needed to add a nilreason.
        See also http://stackoverflow.com/questions/626319/add-attributes-to-a-simpletype-or-restrictrion-to-a-complextype-in-xml-schema
    --> 
    <xsl:template match="imvert:attribute" mode="nil-reason">
        <xsl:variable name="basetype-name" select="imf:get-restriction-basetype-name(.)"/> <!-- e.g. Basetype_Bike_color -->
        
        <xsl:variable name="scalar" select="$all-scalars[@id=current()/imvert:type-name]"/> <!-- this is a scalar-string or the like -->
        <xsl:variable name="xs-type" select="$scalar/type-map[@formal-lang='xs']"/> <!-- returns xs:string or the like -->
        
        <xs:simpleType name="{$basetype-name}">
            <xs:annotation>
                <xs:documentation><p>Generated class. Introduced because the identified attribute is voidable and is a restriction of a simple type.</p></xs:documentation>
            </xs:annotation>
            <xs:restriction base="xs:{$xs-type}">
                <xsl:sequence select="imf:create-datatype-property(.)"/>
            </xs:restriction>
        </xs:simpleType>
    </xsl:template>
    x?>
    
    <xsl:template match="*|@*|text()">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:function name="imf:get-annotation" as="node()?">
        <xsl:param name="this" as="node()"/>
        <xsl:sequence select="imf:get-annotation($this,(),())"/>
    </xsl:function>
    <xsl:function name="imf:get-annotation" as="node()?">
        <xsl:param name="this" as="node()"/>
        <xsl:param name="added-documentation" as="node()*"/>
        <xsl:param name="added-appinfo" as="node()*"/>
        <xsl:variable name="documentation" select="($added-documentation, imf:get-documentation($this))"/>
        <xsl:if test="$added-appinfo or $documentation">
            <xs:annotation>
                <xsl:sequence select="$added-appinfo"/>
                <xsl:sequence select="$documentation"/>
            </xs:annotation>
        </xsl:if>
    </xsl:function>
    
    <xsl:function name="imf:get-schema-info" as="node()*">
        <xsl:param name="this" as="node()"/>
        <xsl:sequence select="imf:create-doc-element('xs:documentation','http://www.imvertor.org/schema-info/file-location',imf:get-xsd-filesubpath($this))"/>
        <xsl:sequence select="imf:create-doc-element('xs:documentation','http://www.imvertor.org/schema-info/conversion',imf:get-config-parameter('pretext-encoding'))"/>
    </xsl:function>
    
    <!-- 
        get a type name based on the type specified, that is suited for XSD 
        
        The type may be somting like:
        
        Class1
        scalar-string
    
        The package name is always specified but is irrelevant for scalars.
    -->
    <xsl:function name="imf:get-type" as="xs:string">
        <xsl:param name="uml-type" as="xs:string"/> 
        <xsl:param name="package-name" as="xs:string?"/> 
        
        <!-- check if the package is external -->
        <xsl:variable name="external-package" select="$external-schemas[imvert:name = $package-name]"/>
        
        <xsl:variable name="defining-class" select="imf:get-class($uml-type,$package-name)"/>
        <xsl:variable name="defining-package" select="$defining-class/.."/>
        
        <xsl:choose>
            <xsl:when test="exists($external-package)">
                <xsl:value-of select="concat($external-package/imvert:short-name,':',$uml-type)"/>
            </xsl:when>
            
            <xsl:when test="$package-name and empty($defining-package)">
                <!-- this is a class that is not known. This is the case for nilreasons on scalar types, we need to create a class for that. -->  
                <xsl:variable name="short-name" select="$document-packages[imvert:name = $package-name]/imvert:short-name"/>
                <xsl:value-of select="concat($short-name,':',$uml-type)"/>
            </xsl:when>
           
            <xsl:otherwise>
                
                <xsl:variable name="primitive" select="$defining-class/imvert:primitive"/> <!-- e.g. BOOLEAN -->
                
                <xsl:variable name="uml-type-name" select="if (contains($uml-type,':')) then substring-after($uml-type,':') else $uml-type"/>
                <xsl:variable name="primitive-type" select="substring-after($uml-type-name,'http://schema.omg.org/spec/UML/2.1/uml.xml#')"/>
                
                <xsl:variable name="base-type" select="
                    if ($primitive)
                    then $primitive
                    else
                        if ($primitive-type) 
                        then $primitive-type 
                        else 
                            if (not($package-name) or imf:is-system-package($package-name)) 
                            then $uml-type-name 
                            else ()"/>
                
                <xsl:variable name="scalar" select="$all-scalars[@id=$base-type][last()]"/>
                
                <xsl:choose>
                    <xsl:when test="$base-type"> 
                        <xsl:variable name="xs-type" select="$scalar/type-map[@formal-lang='xs']"/>
                        <xsl:choose>
                            <xsl:when test="exists($scalar) and starts-with($xs-type,'#')">
                                <xsl:value-of select="$xs-type"/>
                            </xsl:when> 
                            <xsl:when test="exists($scalar)">
                                <xsl:value-of select="concat('xs:', $xs-type)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="'xs:string'"/>
                                <xsl:sequence select="imf:msg('ERROR', 'Unknown native type: [1]', $base-type)"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="concat($defining-package/imvert:short-name,':',$uml-type-name)"/>
                    </xsl:otherwise>
                </xsl:choose>
                
            </xsl:otherwise>
        </xsl:choose>
        
        
    </xsl:function>
    
    <xsl:function name="imf:create-element-property" as="item()*">
        <xsl:param name="this" as="node()"/>
        
        <!-- nilllable may be forced for specific circumstances. This only applies to attributes of a true class or associations -->
        <xsl:variable name="is-property" select="exists(($this/self::imvert:attribute,$this/self::imvert:association))"/>
        <xsl:variable name="force-nillable" select="$is-property and $is-forced-nillable"/>
        
        <xsl:variable name="has-nilreason" select="imf:boolean(imf:get-tagged-value($this,'##CFG-TV-REASONNOVALUE'))"/>
        <xsl:variable name="has-voidable" select="imf:boolean(imf:get-tagged-value($this,'##CFG-TV-VOIDABLE'))"/>
        
        <xsl:variable name="is-voidable" select="$this/imvert:stereotype/@id = ('stereotype-name-voidable')"/> <!-- this is a kadaster combi: voidable and tv both required -->
        <xsl:variable name="is-nillable" select="$is-voidable or $has-voidable or $force-nillable"/>
        
        <xsl:variable name="is-restriction" select="imf:is-restriction($this)"/>
        <xsl:variable name="basetype-name" select="if ($is-nillable) then imf:get-restriction-basetype-name($this) else ''"/>
        <xsl:variable name="package-name" select="$this/ancestor::imvert:package[last()]/imvert:name"/>
        
        <xsl:variable name="name" select="if ($this/self::imvert:association and $meta-is-role-based) then $this/imvert:target/imvert:role else $this/imvert:name"/>
        <xsl:variable name="found-type" select="imf:get-type($this/imvert:type-name,$this/imvert:type-package)"/>
      
        <xsl:variable name="is-any" select="$found-type = '#any'"/>
        <xsl:variable name="is-mix" select="$found-type = '#mix'"/>
        
        <xsl:variable name="defining-class" select="imf:get-defining-class($this)"/>                            
        <xsl:variable name="is-enumeration-or-codelist" select="$defining-class/imvert:stereotype/@id = ('stereotype-name-enumeration','stereotype-name-codelist')"/>
        <xsl:variable name="is-datatype" select="$defining-class/imvert:stereotype/@id = ('stereotype-name-simpletype')"/>
        <xsl:variable name="is-complextype" select="$defining-class/imvert:stereotype/@id = (('stereotype-name-complextype','stereotype-name-referentielijst'))"/>
        
        <xsl:variable name="is-conceptual-complextype" select="$this/imvert:attribute-type-designation='complextype'"/>
        <xsl:variable name="is-conceptual-hasnilreason" select="imf:boolean($this/imvert:attribute-type-hasnilreason)"/> <!-- IM-477 the conceptual type in external schema is nillable and therefore has nilReason attribute -->
        <xsl:variable name="name-conceptual-type" select="if ($this/imvert:attribute-type-name) then imf:get-type($this/imvert:attribute-type-name,$this/imvert:type-package) else ''"/>
        
        <xsl:variable name="type" select="if ($name-conceptual-type) then $name-conceptual-type else $found-type"/>
        
        <xsl:variable name="is-external" select="not($defining-class) and $this/imvert:type-package=$external-schema-names"/>
        <xsl:variable name="is-choice" select="$defining-class/imvert:stereotype/@id = ('stereotype-name-union')"/>
        <xsl:variable name="is-choice-member" select="$this/ancestor::imvert:class/imvert:stereotype/@id = ('stereotype-name-union')"/>
        <xsl:variable name="is-composite" select="$this/imvert:aggregation='composite'"/>
        <xsl:variable name="is-collection-member" select="$this/../../imvert:stereotype/@id = ('stereotype-name-collection')"/>
        <xsl:variable name="is-primitive" select="exists($this/imvert:primitive)"/>
        <xsl:variable name="is-anonymous" select="$this/imvert:stereotype/@id = ('stereotype-name-anonymous')"/>
        <xsl:variable name="is-type-modified-incomplete" select="$this/imvert:type-modifier = '?'"/>
        
        <xsl:variable name="association-class-id" select="$this/imvert:association-class/imvert:type-id"/>
        <xsl:variable name="min-occurs-assoc" select="if ($this/imvert:min-occurs='0') then '0' else '1'"/>
        <xsl:variable name="min-occurs-target" select="if ($this/imvert:min-occurs='0') then '1' else $this/imvert:min-occurs"/>
        
        <xsl:variable name="data-location" select="imf:get-appinfo-location($this)"/>
        
        <xsl:variable name="has-key" select="$defining-class/imvert:attributes/imvert:attribute[imvert:stereotype/@id = 'stereotype-name-key']"/>
        
        <xsl:variable name="is-includable" select="imf:boolean(imf:get-tagged-value($this,'##CFG-TV-INCLUDABLE'))"/>
        
        <xsl:variable name="use-identifier-domains" select="imf:boolean(imf:get-xparm('cli/identifierdomains','no'))"/>
        <xsl:variable name="domain-value" select="imf:get-tagged-value($this,'##CFG-TV-DOMAIN')"/>
        
        <mark nillable="{$is-nillable}" nilreason="{$has-nilreason}">
            <xsl:choose>
            <!-- any type, i.e. #any -->
            <xsl:when test="$is-any">
                <xsl:variable name="package-name" select="$this/imvert:any-from-package"/>
                <xsl:variable name="package-namespace" select="$document-packages[imvert:name=$package-name]/imvert:namespace"/>
                <xs:element>
                    <xsl:attribute name="name" select="$name"/>
                    <xsl:attribute name="minOccurs" select="$this/imvert:min-occurs"/>
                    <xsl:attribute name="maxOccurs" select="$this/imvert:max-occurs"/>
                    <xsl:sequence select="imf:create-xml-debug-comment($this,'Any type')"/>
                    <xs:complexType mixed="true">
                        <xs:sequence>
                            <xs:any minOccurs="0" maxOccurs="unbounded">
                                <xsl:attribute name="namespace" select="if (exists($package-name)) then $package-namespace else '##any'"/>
                                <xsl:attribute name="processContents">lax</xsl:attribute>
                            </xs:any>
                        </xs:sequence>
                    </xs:complexType>
                </xs:element>
            </xsl:when>
            <xsl:when test="$is-mix">
                <xs:element>
                    <xsl:attribute name="name" select="$name"/>
                    <xsl:attribute name="minOccurs" select="$this/imvert:min-occurs"/>
                    <xsl:attribute name="maxOccurs" select="$this/imvert:max-occurs"/>
                    <xsl:sequence select="imf:create-xml-debug-comment($this,'Mix of elements')"/>
                    <xs:complexType mixed="true">
                        <!-- TODO how to define possible elements in mixed contents? -->
                    </xs:complexType>
                </xs:element>
            </xsl:when>
            
            <xsl:when test="exists($has-key)">
                <xs:element>
                    <xsl:attribute name="name" select="$name"/>
                    <xsl:attribute name="minOccurs" select="$this/imvert:min-occurs"/>
                    <xsl:attribute name="maxOccurs" select="$this/imvert:max-occurs"/>
                    <xsl:sequence select="imf:create-xml-debug-comment($this,'A keyed value')"/>
                    <xs:complexType>
                        <xs:simpleContent>
                            <xs:extension base="xs:string">
                                <xs:attribute name="{$has-key/imvert:name}" type="xs:string"/>
                            </xs:extension>
                        </xs:simpleContent>
                    </xs:complexType>
                </xs:element>  
            </xsl:when>
            
            <xsl:when test="$type=('postcode')"> <!--TODO remove -->
                <xs:element>
                    <xsl:attribute name="name" select="$name"/>
                    <xsl:attribute name="minOccurs" select="$min-occurs-assoc"/>
                    <xsl:attribute name="maxOccurs" select="$this/imvert:max-occurs"/>
                    <xsl:sequence select="imf:create-xml-debug-comment($this,'A postcode')"/>
                    <xsl:sequence select="imf:get-annotation($this,$data-location,())"/>
                    <xs:simpleType>
                        <xs:restriction base="xs:string">
                            <xs:pattern value="[0-9]{{4}}[A-Z]{{2}}"/>
                        </xs:restriction>
                    </xs:simpleType>
                </xs:element>
            </xsl:when>
            
            <xsl:when test="$type=('xs:dateTime','xs:date','xs:time') and $is-type-modified-incomplete"> <!-- incomplete type -->
                 <xsl:variable name="fixtype">
                    <xsl:choose>
                        <xsl:when test="$type='xs:dateTime'">Fixtype_incompleteDateTime</xsl:when>
                        <xsl:when test="$type='xs:date'">Fixtype_incompleteDate</xsl:when>
                        <xsl:when test="$type='xs:time'">Fixtype_incompleteTime</xsl:when>
                    </xsl:choose>
                </xsl:variable>
                <xs:element>
                    <xsl:attribute name="name" select="$name"/>
                    <xsl:attribute name="type" select="imf:get-type($fixtype,$package-name)"/>
                    <xsl:attribute name="minOccurs" select="$min-occurs-assoc"/>
                    <xsl:attribute name="maxOccurs" select="$this/imvert:max-occurs"/>
                    <xsl:sequence select="imf:create-xml-debug-comment($this,'An incomplete datetime, date or time')"/>
                    <xsl:sequence select="imf:get-annotation($this,$data-location,())"/>
                </xs:element>
            </xsl:when>
            <xsl:when test="starts-with($type,'xs:') and $is-restriction"> <!-- any xsd primitve type such as xs:string, with local restrictions such as patterns -->
                <xs:element>
                    <xsl:attribute name="name" select="$name"/>
                    <xsl:attribute name="minOccurs" select="$min-occurs-assoc"/>
                    <xsl:attribute name="maxOccurs" select="$this/imvert:max-occurs"/>
                    <xsl:sequence select="imf:create-xml-debug-comment($this,'A restriction on a primitive type')"/>
                    <xsl:sequence select="imf:get-annotation($this,$data-location,())"/>
                    <xs:simpleType>
                        <xs:restriction base="{$type}">
                            <xsl:sequence select="imf:create-datatype-property($this)"/>
                        </xs:restriction>
                    </xs:simpleType>
                </xs:element>
            </xsl:when>
            <xsl:when test="$type=('xs:string') and not($this/imvert:baretype='TXT')"> <!-- these types could be, but may may not be empty -->
                <xs:element>
                    <xsl:attribute name="name" select="$name"/>
                    <xsl:attribute name="minOccurs" select="$min-occurs-assoc"/>
                    <xsl:attribute name="maxOccurs" select="$this/imvert:max-occurs"/>
                    <xsl:sequence select="imf:create-xml-debug-comment($this,'A string')"/>
                    <xsl:sequence select="imf:get-annotation($this,$data-location,())"/>
                    <xs:simpleType>
                        <xs:restriction base="{$type}">
                            <xs:pattern value="\S.*"/> <!-- Note: do not use xs:minLength as this allows for a single space -->
                        </xs:restriction>
                    </xs:simpleType>
                </xs:element>
            </xsl:when>
            <?x            
            <xsl:when test="starts-with($type,'xs:')"> 
                <!-- 
                    Determine the effective type, this is the actual type such as xs:string or a generated basetype 
                    When basetype, the type referenced in the extension is the generated type, 'Basetype_*', introduced at the end of the schema 
                -->
                <xsl:variable name="effective-type" select="if ($is-restriction) then imf:get-type($basetype-name,$package-name) else $type"/>
                <xs:element>
                    <xsl:attribute name="name" select="$name"/>
                    <xsl:attribute name="type" select="$effective-type"/>
                    <xsl:attribute name="minOccurs" select="$min-occurs-assoc"/>
                    <xsl:attribute name="maxOccurs" select="$this/imvert:max-occurs"/>
                    <xsl:sequence select="imf:create-xml-debug-comment($this,'A voidable primitive type')"/>
                    <xsl:sequence select="imf:get-annotation($this,$data-location,())"/>
                </xs:element>
            </xsl:when>
            x?>
            <xsl:when test="starts-with($type,'xs:')"> 
                <!-- any xsd primitve type such as xs:integer, and the TXT type -->
                <xs:element>
                    <xsl:attribute name="name" select="$name"/>
                    <xsl:attribute name="type" select="$type"/>
                    <xsl:attribute name="minOccurs" select="$min-occurs-assoc"/>
                    <xsl:attribute name="maxOccurs" select="$this/imvert:max-occurs"/>
                    <xsl:sequence select="imf:create-xml-debug-comment($this,'A primitive type')"/>
                    <xsl:sequence select="imf:get-annotation($this)"/>
                </xs:element>
            </xsl:when>
            <xsl:when test="$is-primitive and $is-restriction"> 
                <!-- any xsd primitve type such as integer -->
                <xs:element>
                    <xsl:attribute name="name" select="$name"/>
                    <xsl:attribute name="minOccurs" select="$min-occurs-assoc"/>
                    <xsl:attribute name="maxOccurs" select="$this/imvert:max-occurs"/>
                    <xsl:sequence select="imf:create-xml-debug-comment($this,'A restriction on a primitive type, after mapping')"/>
                    <xsl:sequence select="imf:get-annotation($this)"/>
                    <xs:simpleType>
                        <xs:restriction base="{$this/imvert:type-name}">
                            <xsl:sequence select="imf:create-datatype-property($this)"/>
                        </xs:restriction>
                    </xs:simpleType>
                </xs:element>
            </xsl:when>
            <xsl:when test="$is-primitive"> 
                <!-- any xsd primitve type such as integer -->
                <xs:element>
                    <xsl:attribute name="name" select="$name"/>
                    <xsl:attribute name="type" select="$this/imvert:type-name"/>
                    <xsl:attribute name="minOccurs" select="$min-occurs-assoc"/>
                    <xsl:attribute name="maxOccurs" select="$this/imvert:max-occurs"/>
                    <xsl:sequence select="imf:create-xml-debug-comment($this,'A primitive type, after mapping')"/>
                    <xsl:sequence select="imf:get-annotation($this)"/>
                </xs:element>
            </xsl:when>
            <xsl:when test="$is-enumeration-or-codelist">
                <!-- an enumeration or a datatype such as postcode -->
                <xs:element>
                    <xsl:attribute name="name" select="$name"/>
                    <xsl:attribute name="type" select="$type"/>
                    <xsl:attribute name="minOccurs" select="$this/imvert:min-occurs"/>
                    <xsl:attribute name="maxOccurs" select="$this/imvert:max-occurs"/>
                    <xsl:sequence select="imf:create-xml-debug-comment($this,'An enumeration or codelist')"/>
                    <xsl:sequence select="imf:get-annotation($this,$data-location,())"/>
                </xs:element>
            </xsl:when>
            <xsl:when test="($is-complextype or $is-conceptual-complextype)">
                <!-- note that we do not support avoiding substitution on complex datatypes --> 
                <xs:element>
                    <xsl:attribute name="name" select="$name"/>
                    <xsl:attribute name="type" select="$type"/>
                    <xsl:attribute name="minOccurs" select="$this/imvert:min-occurs"/>
                    <xsl:attribute name="maxOccurs" select="$this/imvert:max-occurs"/>
                    <xsl:sequence select="imf:create-xml-debug-comment($this,'A complex type')"/>
                    <xsl:sequence select="imf:get-annotation($this,$data-location,())"/>
                </xs:element>
            </xsl:when>
                <xsl:when test="$is-datatype and $use-identifier-domains and $domain-value">
                    <xs:element>
                        <xsl:attribute name="name" select="$name"/>
                        <xsl:attribute name="minOccurs" select="$this/imvert:min-occurs"/>
                        <xsl:attribute name="maxOccurs" select="$this/imvert:max-occurs"/>
                        <xsl:sequence select="imf:create-xml-debug-comment($this,'A datatype with domain')"/>
                        <xsl:sequence select="imf:get-annotation($this,$data-location,())"/>
                        <xs:complexType>
                            <xs:simpleContent>
                                <xs:extension base="{$type}">
                                    <xs:attribute name="domein" type="xs:string" fixed="{$domain-value}"/>
                                </xs:extension>
                            </xs:simpleContent>
                        </xs:complexType>
                    </xs:element>
                </xsl:when>
                <xsl:when test="$is-datatype">
                    <xs:element>
                        <xsl:attribute name="name" select="$name"/>
                        <xsl:attribute name="type" select="$type"/>
                        <xsl:attribute name="minOccurs" select="$this/imvert:min-occurs"/>
                        <xsl:attribute name="maxOccurs" select="$this/imvert:max-occurs"/>
                        <xsl:sequence select="imf:create-xml-debug-comment($this,'A datatype')"/>
                        <xsl:sequence select="imf:get-annotation($this,$data-location,())"/>
                    </xs:element>
                </xsl:when>
                <xsl:when test="not($name) and $is-external">
                <!-- a reference to an external construct -->
                <xs:element>
                    <xsl:attribute name="ref" select="$type"/>
                    <xsl:attribute name="minOccurs" select="$this/imvert:min-occurs"/>
                    <xsl:attribute name="maxOccurs" select="$this/imvert:max-occurs"/>
                    <xsl:sequence select="imf:create-xml-debug-comment($this,'No name and the type is external')"/>
                    <xsl:sequence select="imf:get-annotation($this,$data-location,())"/>
                </xs:element>
            </xsl:when>
            <xsl:when test="$is-choice"> 
                <xs:element>
                    <xsl:attribute name="name" select="$name"/>
                    <xsl:attribute name="type" select="$type"/>
                    <xsl:attribute name="minOccurs" select="$this/imvert:min-occurs"/>
                    <xsl:attribute name="maxOccurs" select="$this/imvert:max-occurs"/>
                    <xsl:sequence select="imf:create-xml-debug-comment($this,'The type of this property is a union')"/>
                    <xsl:sequence select="imf:get-annotation($this)"/>
                </xs:element>
            </xsl:when>
            <xsl:when test="$is-choice-member"> 
                <!-- an attribute of a NEN3610 union -->
                <xs:element>
                    <xsl:attribute name="ref" select="$type"/>
                    <xsl:attribute name="minOccurs" select="$this/imvert:min-occurs"/>
                    <xsl:attribute name="maxOccurs" select="$this/imvert:max-occurs"/>
                    <xsl:sequence select="imf:create-xml-debug-comment($this,'A member of a union')"/>
                    <xsl:sequence select="imf:get-annotation($this)"/>
                </xs:element>
            </xsl:when>
            <xsl:when test="$is-external">
                <xs:element>
                    <xsl:attribute name="name" select="$name"/>
                    <xsl:attribute name="minOccurs" select="$min-occurs-assoc"/>
                    <xsl:attribute name="maxOccurs" select="1"/>
                    <xsl:sequence select="imf:create-xml-debug-comment($this,'An external type')"/>
                    <xsl:sequence select="imf:get-annotation($this,$data-location,())"/>
                    <!-- TODO continue: introduce correct reference / see IM-59 -->
                    <xsl:variable name="reftype" select="$type"/>
                    <xs:complexType>
                        <xs:sequence>
                            <xs:element ref="{$reftype}" minOccurs="{$min-occurs-target}" maxOccurs="{$this/imvert:max-occurs}"/>
                        </xs:sequence>
                    </xs:complexType>
                </xs:element>
            </xsl:when>
            <xsl:when test="not($defining-class)">
                <xsl:sequence select="imf:create-xml-debug-comment($this,'No defining class!')"/>
                <xsl:sequence select="imf:msg('ERROR','Reference to an undefined class [1]',$type)"/>
                <!-- this can be the case when this class is not part of a configured package, please correct in UML -->
            </xsl:when>
            <xsl:when test="not($name) or $is-anonymous"> 
                <!-- an unnamed association -->
                <xsl:choose>
                    <xsl:when test="$avoid-substitutions">
                        <xs:choice minOccurs="{$this/imvert:min-occurs}" maxOccurs="{$this/imvert:max-occurs}">
                            <xsl:variable name="sub-classes" select="($defining-class, imf:get-substitution-classes($defining-class))"/>
                            <xsl:sequence select="imf:create-xml-debug-comment($this,'An unnamed association, avoiding substitutions')"/>
                            <xsl:sequence select="imf:get-annotation($this,$data-location,())"/>
                            <xsl:for-each select="$sub-classes[not(imf:boolean(imvert:abstract))]">
                                <xs:element ref="{imf:get-qname(.)}"/>
                            </xsl:for-each>
                        </xs:choice>
                    </xsl:when>
                    <xsl:otherwise>
                        <xs:element>
                            <xsl:attribute name="ref" select="$type"/>
                            <xsl:attribute name="minOccurs" select="$this/imvert:min-occurs"/>
                            <xsl:attribute name="maxOccurs" select="$this/imvert:max-occurs"/>
                            <xsl:sequence select="imf:create-xml-debug-comment($this,'An unnamed association')"/>
                            <xsl:sequence select="imf:get-annotation($this,$data-location,())"/>
                        </xs:element>
                    </xsl:otherwise>            
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$name and $is-collection-member and imf:boolean($profile-collection-wrappers)">
                <!-- must wrap the element -->
                <xs:element>
                    <xsl:attribute name="name" select="$name"/>
                    <xsl:attribute name="minOccurs" select="$this/imvert:min-occurs"/>
                    <xsl:attribute name="maxOccurs" select="$this/imvert:max-occurs"/>
                    <xsl:choose>
                        <xsl:when test="$avoid-substitutions">
                            <xs:complexType>
                                <xs:choice>
                                    <xsl:variable name="sub-classes" select="($defining-class, imf:get-substitution-classes($defining-class))"/>
                                    <xsl:sequence select="imf:create-xml-debug-comment($this,'A wrapped member, avoiding substitutions')"/>
                                    <xsl:sequence select="imf:get-annotation($this,$data-location,())"/>
                                    <xsl:for-each select="$sub-classes[not(imf:boolean(imvert:abstract))]">
                                        <xs:element ref="{imf:get-qname(.)}"/>
                                    </xsl:for-each>
                                </xs:choice>
                            </xs:complexType>
                        </xsl:when>
                        <xsl:otherwise>
                            <xs:element>
                                <xsl:attribute name="ref" select="$type"/>
                                <xsl:sequence select="imf:create-xml-debug-comment($this,'A wrapped member')"/>
                                <xsl:sequence select="imf:get-annotation($this,$data-location,())"/>
                            </xs:element>
                        </xsl:otherwise>            
                    </xsl:choose>
                </xs:element>
            </xsl:when>
            <xsl:when test="imf:is-linkable($defining-class)">
                <!-- TODO IM-83 STALLED, BUT IMPLEMENTED FOR THIS CASE -->
                <!-- 
                    The class is an Objecttype, and therefore linkable.
                    This also covers void.
                    When component, and if components must be anonymous, do not create named element for relation type. (IM-83)
                -->
                <xsl:variable name="content">
                    <xsl:variable name="ref-classes" select="imf:get-linkable-subclasses-or-self($defining-class)"/>
                    <xsl:variable name="choice">
                        <!-- 
                            Any reference to an object type is realized through an Xref element.
                            We do not consider composite relations to be treated specially 
                            (and do not place a reference to X).
                        -->
                        <xsl:for-each select="$ref-classes">
                            <!-- IM-110 alle elementen hier zijn linkable -->
                            <xsl:choose>
                                <xsl:when test="not(imf:boolean($buildcollection)) and imf:is-abstract(.)">
                                    <xsl:sequence select="imf:create-xml-debug-comment($this,'Buildcollection suppressed, abstract class ignored')"/>
                                </xsl:when>
                                <xsl:when test="not(imf:boolean($buildcollection))">
                                    <xsl:sequence select="imf:create-xml-debug-comment($this,'Buildcollection suppressed')"/>
                                    <xs:element ref="{imf:get-qname(.)}"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:sequence select="imf:create-xml-debug-comment($this,'Buildcollection allowed')"/>
                                    <xs:element ref="{imf:get-reference-class-name(.)}"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test="$association-class-id">
                            <xs:sequence minOccurs="{$min-occurs-target}" maxOccurs="{$this/imvert:max-occurs}">
                                <xs:choice>
                                    <xsl:sequence select="$choice"/>
                                </xs:choice>
                                <!-- TODO improvement / association class probably not covered well -->
                                <xsl:sequence select="imf:create-xml-debug-comment($this,'An association class')"/>
                                <xsl:variable name="association-class" select="$imvert-document//imvert:class[imvert:id=$association-class-id]"/>
                                <xs:element ref="{imf:get-qname($association-class)}"/>
                            </xs:sequence>
                        </xsl:when>
                        <xsl:otherwise>
                            <xs:choice minOccurs="{$min-occurs-target}" maxOccurs="{$this/imvert:max-occurs}">
                                <xsl:sequence select="$choice"/>
                            </xs:choice>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="$is-composite and imf:boolean($anonymous-components) and not($is-nillable)">
                        <xsl:sequence select="imf:get-annotation($this,$data-location,())"/>
                        <xs:sequence>
                            <xsl:attribute name="minOccurs" select="$min-occurs-assoc"/>
                            <xsl:attribute name="maxOccurs" select="1"/>
                            <xsl:sequence select="imf:create-xml-debug-comment($this,'An objecttype, anonymous')"/>
                            <xsl:sequence select="$content"/>
                        </xs:sequence>
                    </xsl:when>
                    <xsl:otherwise>
                        <xs:element>
                            <xsl:attribute name="name" select="$name"/>
                            <xsl:attribute name="minOccurs" select="$min-occurs-assoc"/>
                            <xsl:attribute name="maxOccurs" select="1"/>
                            <xsl:choose>
                                <xsl:when test="$is-composite and imf:boolean($anonymous-components) and $is-nillable">
                                    <xsl:sequence select="imf:create-xml-debug-comment($this,'An objecttype, anonymous, but voidable')"/>
                                    <xsl:sequence select="imf:msg('WARNING','Anonymous component is voidable and therefore must be named: [1]',$name)"/>
                                </xsl:when>
                                <xsl:when test="$is-nillable">
                                    <xsl:sequence select="imf:create-xml-debug-comment($this,'An objecttype, voidable')"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:sequence select="imf:create-xml-debug-comment($this,'An objecttype')"/>
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:sequence select="imf:get-annotation($this,$data-location,())"/>
                            <xs:complexType>
                                <xsl:sequence select="$content"/>
                            </xs:complexType>                            
                        </xs:element>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <!-- TODO IM-83 STALLED, NOT IMPLEMENTED YET FOR THIS CASE -->
                <xs:element>
                    <xsl:attribute name="name" select="$name"/>
                    <xsl:attribute name="minOccurs" select="$min-occurs-assoc"/>
                    <xsl:attribute name="maxOccurs" select="1"/>
                    <xsl:sequence select="imf:get-annotation($this,$data-location,())"/>
                    <xs:complexType>
                        <xsl:variable name="result">
                            <xsl:choose>
                                <!-- TODO improvement / association classes are not covered well by current implementation; check out more contexts where the assoc. class may occur -->
                                <xsl:when test="$association-class-id">
                                    <xsl:sequence select="imf:create-xml-debug-comment($this,'Default property definition: an association class')"/>
                                    <xsl:variable name="association-class" select="$imvert-document//imvert:class[imvert:id=$association-class-id]"/>
                                    <xs:element ref="{imf:get-qname($association-class)}" minOccurs="{$min-occurs-target}" maxOccurs="{$this/imvert:max-occurs}"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:choose>
                                        <xsl:when test="$avoid-substitutions">
                                            <xsl:sequence select="imf:create-xml-debug-comment($this,'Default property definition, avoiding substitutions')"/>
                                            <xsl:variable name="sub-classes" select="($defining-class, imf:get-substitution-classes($defining-class))"/>
                                            <xsl:variable name="result-set" select="$sub-classes[not(imf:boolean(imvert:abstract))]"/>
                                            <xsl:choose>
                                                <xsl:when test="count($result-set) gt 1">
                                                    <xs:choice>
                                                        <xsl:attribute name="minOccurs" select="$min-occurs-target"/>
                                                        <xsl:attribute name="maxOccurs" select="$this/imvert:max-occurs"/>
                                                        <xsl:sequence select="imf:create-xml-debug-comment($this,'... and the result set counts more that 1')"/>
                                                        <xsl:for-each select="$result-set">
                                                            <xs:element ref="{imf:get-qname(.)}"/>
                                                        </xsl:for-each>
                                                    </xs:choice>
                                                </xsl:when>
                                                <xsl:when test="count($result-set) eq 0">
                                                    <xsl:sequence select="imf:msg('ERROR','Attempt to reference an abstract class: [1]',$name)"/>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xs:element ref="{imf:get-qname($result-set)}">
                                                        <xsl:attribute name="minOccurs" select="$min-occurs-target"/>
                                                        <xsl:attribute name="maxOccurs" select="$this/imvert:max-occurs"/>
                                                        <xsl:sequence select="imf:create-xml-debug-comment($this,'... and the result set counts 1')"/>
                                                    </xs:element>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:sequence select="imf:create-xml-debug-comment($this,'Default property definition')"/>
                                            <xs:element ref="{$type}" minOccurs="{$min-occurs-target}" maxOccurs="{$this/imvert:max-occurs}"/>
                                        </xsl:otherwise>            
                                    </xsl:choose>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>
                        <xsl:if test="$result">
                            <xs:sequence>
                                <xsl:sequence select="$result"/>
                            </xs:sequence>
                        </xsl:if>
                    </xs:complexType>
                </xs:element>
            </xsl:otherwise>
        </xsl:choose>
        </mark>
    </xsl:function>
    
    <xsl:function name="imf:create-attribute-property" as="item()*">
        <xsl:param name="this" as="node()"/>
  
        <xsl:variable name="voidable" select="$this/imvert:stereotype/@id = ('stereotype-name-voidable')"/>
        <xsl:variable name="type" select="imf:get-type($this/imvert:type-name,$this/imvert:type-package)"/>
        <xs:attribute>
            <xsl:attribute name="name" select="$this/imvert:name"/>
            <xsl:attribute name="use" select="if ($this/imvert:min-occurs='0') then 'optional' else 'required'"/>
            <xsl:attribute name="type" select="$type"/>
            <xsl:sequence select="imf:get-annotation($this)"/>
        </xs:attribute>
    </xsl:function>

    <xsl:function name="imf:create-datatype-property" as="node()*">
        <xsl:param name="this" as="node()"/>
        
        <xsl:variable name="p" select="imf:get-facet-pattern($this)"/>
        <xsl:if test="$p">
            <xs:pattern value="{$p}"/>
        </xsl:if>
  
        <xsl:variable name="l" select="imf:get-facet-max-length($this)"/>
        <xsl:variable name="min-l" select="imf:convert-to-atomic(substring-before($l,'..'),'xs:integer',true())"/>
        <xsl:variable name="max-l" select="imf:convert-to-atomic(substring-after($l,'..'),'xs:integer',true())"/>
        <xsl:variable name="pre-l" select="imf:convert-to-atomic(substring-before($l,','),'xs:integer',true())"/>
        <xsl:variable name="post-l" select="imf:convert-to-atomic(substring-after($l,','),'xs:integer',true())"/>
        <xsl:variable name="t" select="imf:convert-to-atomic(imf:get-facet-total-digits($this),'xs:integer',true())"/>
        <xsl:variable name="f" select="imf:convert-to-atomic(imf:get-facet-fraction-digits($this),'xs:integer',true())"/>
       
        <xsl:if test="$min-l">
            <xs:minLength value="{$min-l}"/>
        </xsl:if>
        <xsl:if test="$max-l">
            <xs:maxLength value="{$max-l}"/>
        </xsl:if>
        <xsl:if test="$l and not($min-l) and not($pre-l)">
            <xs:length value="{$l}"/>
        </xsl:if>
        <xsl:if test="$post-l">
            <xs:fractionDigits value="{$post-l}"/>
        </xsl:if>
        <xsl:if test="$pre-l">
            <xs:totalDigits value="{$pre-l + $post-l}"/>
        </xsl:if>
        <xsl:if test="$f and not($min-l) and not($pre-l)">
            <xs:fractionDigits value="{$f}"/>
        </xsl:if>
        <xsl:if test="$t and not($min-l) and not($pre-l)">
            <xs:totalDigits value="{$t}"/>
        </xsl:if>
        
        <xsl:if test="empty(($p,$t)) and not($this/imvert:baretype='TXT')">
            <xsl:sequence select="imf:create-nonempty-constraint($this/imvert:type-name)"/>
        </xsl:if>
    </xsl:function>
  
    <xsl:template match="imvert:union">
        <xsl:variable name="membertypes" as="item()*">
            <!-- for each referenced datatype, determine the actual XSD equivalent. Produce a xs:union construct. -->
            <xsl:for-each select="tokenize(normalize-space(.),'\s+')">
                <xsl:value-of select="imf:get-type(.,'')"/>
            </xsl:for-each>
        </xsl:variable>
        <xs:union memberTypes="{string-join($membertypes,' ')}"/>
    </xsl:template>
    
    <xsl:function name="imf:is-system-package" as="xs:boolean">
        <xsl:param name="package-name" as="xs:string"/>
        <xsl:copy-of select="substring-before($package-name,'_') = ('EA','Info')"/>
    </xsl:function>
   
    <xsl:function name="imf:is-restriction" as="xs:boolean">
        <xsl:param name="this" as="node()"/>
        <xsl:sequence select="exists((imf:get-facet-pattern($this), imf:get-facet-max-length($this), imf:get-facet-total-digits($this), imf:get-facet-fraction-digits($this)))"/>
    </xsl:function>
    
    <?x associates komen niet meer voor?
        
    <xsl:function name="imf:is-association-class" as="xs:boolean">
        <xsl:param name="this" as="node()"/>
        <xsl:value-of select="exists($this/imvert:associates)"/>
    </xsl:function>
    ?>
    
    <xsl:function name="imf:get-restriction-basetype-name" as="xs:string">
        <xsl:param name="this" as="node()"/> <!-- any attribute/association node. -->
        <xsl:value-of select="concat('Basetype_',$this/ancestor::imvert:class/imvert:name,'_',$this/imvert:name)"/>
    </xsl:function>
    
    <xsl:function name="imf:create-nilreason">
        <xsl:param name="is-conceptual-hasnilreason"/><!-- IM-477 -->
        <xsl:if test="not($is-conceptual-hasnilreason)">
            <xs:attribute name="nilReason" type="xs:string" use="optional"/>
        </xsl:if>
    </xsl:function>
    
    <xsl:function name="imf:get-documentation" as="node()*">
        <xsl:param name="construct" as="node()"/>
        <xsl:sequence select="imf:create-doc-element('xs:documentation','http://www.imvertor.org/schema-info/technical-documentation',
            imf:xhtml-to-flatdoc(imf:get-compiled-documentation-as-html($construct)))"/>
        <xsl:sequence select="imf:create-doc-element('xs:documentation','http://www.imvertor.org/schema-info/content-documentation',())"/>
        <xsl:sequence select="imf:create-doc-element('xs:documentation','http://www.imvertor.org/schema-info/version-documentation',())"/>
        <xsl:sequence select="imf:create-doc-element('xs:documentation','http://www.imvertor.org/schema-info/external-documentation',())"/>
    </xsl:function>
    
    <xsl:function name="imf:get-appinfo-version" as="node()*">
        <xsl:param name="this" as="node()"/>
        <xsl:sequence select="imf:create-doc-element('xs:appinfo','http://www.imvertor.org/schema-info/uri',$this/imvert:namespace)"/>
        <xsl:sequence select="imf:create-doc-element('xs:appinfo','http://www.imvertor.org/schema-info/version',$this/imvert:version)"/>
        <xsl:sequence select="imf:create-doc-element('xs:appinfo','http://www.imvertor.org/schema-info/phase',$this/imvert:phase)"/>
        <xsl:sequence select="imf:create-doc-element('xs:appinfo','http://www.imvertor.org/schema-info/release',imf:get-release($this))"/> 
        <xsl:sequence select="imf:create-doc-element('xs:appinfo','http://www.imvertor.org/schema-info/generated',$generation-date)"/> 
        <xsl:sequence select="imf:create-doc-element('xs:appinfo','http://www.imvertor.org/schema-info/generator',$imvertor-version)"/>
        <xsl:sequence select="imf:create-doc-element('xs:appinfo','http://www.imvertor.org/schema-info/owner',$owner-name)"/> 
        <!--<xsl:sequence select="imf:create-doc-element('xs:appinfo','http://www.imvertor.org/schema-info/svn',concat($char-dollar,'Id',$char-dollar))"/>-->
    </xsl:function>
    
    <xsl:function name="imf:get-appinfo-location" as="node()*">
        <xsl:param name="this" as="node()"/>
        <xsl:sequence select="imf:create-doc-element('xs:appinfo','http://www.imvertor.org/data-info/uri',imf:get-data-location($this))"/>
    </xsl:function>
    
    <xsl:function name="imf:create-doc-element" as="node()*">
        <xsl:param name="element-name" as="xs:string"/>
        <xsl:param name="namespace" as="xs:string"/>
        <xsl:param name="value" as="xs:string*"/>
        <xsl:for-each select="$value[normalize-space(.)]">
            <xsl:element name="{$element-name}">
                <xsl:attribute name="source" select="$namespace"/>
                <xsl:value-of select="."/>
            </xsl:element>
        </xsl:for-each>
    </xsl:function>
    
    <xsl:function name="imf:create-info-element" as="node()*">
        <xsl:param name="element-name" as="xs:string"/>
        <xsl:param name="value" as="xs:string*"/>
        <xsl:for-each select="$value">
            <xsl:element name="{$element-name}">
                <xsl:value-of select="."/>
            </xsl:element>
        </xsl:for-each>
    </xsl:function>
        
    <xsl:function name="imf:get-qname" as="xs:string">
        <xsl:param name="class" as="node()"/>
        <xsl:value-of select="concat($class/parent::imvert:package/imvert:short-name,':',$class/imvert:name)"/>
    </xsl:function>
    
    <xsl:function name="imf:get-namespace" as="xs:string">
        <xsl:param name="this" as="node()"/>
        <xsl:choose>
            <xsl:when test="$this/imvert:stereotype='external-package'">
                <xsl:value-of select="$this/imvert:namespace"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat($this/imvert:namespace,'/v', imf:get-release($this))"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="imf:create-nonempty-constraint" as="item()*">
        <xsl:param name="type" as="xs:string?"/>
        <xsl:if test="$type=('scalar-string', 'scalar-uri') or not($type)">
            <xs:pattern value="\S.*"/> <!-- Note: do not use xs:minLength as this allows for a single space -->
        </xsl:if>
    </xsl:function>
    
    <!-- return the class that defines the type of the attribute or association passed. --> 
    <xsl:function name="imf:get-defining-class" as="node()?">
        <xsl:param name="this" as="node()"/>
       
        <!-- overrule name based searches, must be ID based.
            <xsl:sequence select="$document-packages[imvert:name=$this/imvert:type-package]/imvert:class[imvert:name=$this/imvert:type-name]"/> 
        --> 
        <xsl:sequence select="$document-classes[imvert:id=$this/imvert:type-id]"/> 
        
    </xsl:function>

    <!-- 
        Return the complete subpath and filename of the xsd file to be generated.
        Sample: xsd-folder/subpath/my/schema/MyappMypackage_1_0_3.xsd
        
        xsd-folder/subpath is provided as a cli parameter cli/xsdsubpath
    -->
    <xsl:function name="imf:get-xsd-filesubpath" as="xs:string">
        <xsl:param name="this" as="node()"/> <!-- a package -->
        <xsl:choose>
            <xsl:when test="$this/imvert:stereotype/@id = (('stereotype-name-external-package','stereotype-name-system-package'))"> 
                <!-- 
                    the package is external (GML, Xlink or the like). 
                    Place reference to that external pack. 
                    The package is copied alongside the target application package.
                --> 
                <xsl:value-of select="imf:get-uri-parts($this/imvert:location)/path"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat($xsd-subpath, '/', imf:get-xsd-filefolder($this), '/', encode-for-uri(imf:get-xsd-filename($this)))"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
  
    <!-- 
        return the full XSD file path of the package passed.
    -->
    <xsl:function name="imf:get-xsd-filefullpath" as="xs:string">
        <xsl:param name="this" as="element()"/>
        <xsl:variable name="schema-subpath" select="imf:get-xsd-filesubpath($this)"/>
        <xsl:value-of select="concat($work-xsd-folder-url,'/',$schema-subpath)"/>
    </xsl:function>
  
    <!-- 
        Get the path of the xsd file. This is the part of the namespace that is behind the repository-url.
        Example:
        root namespace (alias) is: 
            http://www.imvertor.org/schema
        URL is: 
            http://www.imvertor.org/schema/my/schema/
        and release is: 
            20120307
        returns: 
            my/schema/v20120307
    -->    
    <xsl:function name="imf:get-xsd-filefolder" as="xs:string">
        <xsl:param name="this" as="node()"/> <!-- an imvert:package -->
        <xsl:variable name="localpath" select="substring-after($this/imvert:namespace,concat($base-namespace,'/'))"/>
        <xsl:value-of select="concat(if (normalize-space($localpath)) then $localpath else 'unknown','/v',$this/imvert:release)"/>
    </xsl:function>
    
    <!--
        Return the file name of the XSD to be generated.
    -->
    <xsl:function name="imf:get-xsd-filename" as="xs:string">
        <xsl:param name="this" as="node()"/>
        
        <xsl:sequence select="imf:set-config-string('work','xsd-domain',$this/imvert:name,true())"/>
        <xsl:sequence select="imf:set-config-string('work','xsd-version',replace($this/imvert:version,'\.','_'),true())"/>
        <xsl:sequence select="imf:set-config-string('work','xsd-application',$application-package-name,true())"/>
        
        <xsl:value-of select="imf:merge-parms(imf:get-config-string('cli','xsdfilename'))"/>
    </xsl:function>
    
    <!-- 
        return the release number of the Model and therefore the XSD to be generated 
    -->
    <xsl:function name="imf:get-release" as="xs:string?">
        <xsl:param name="this" as="node()"/>
        <!-- 
            Assume release of supplier, unless release specified.
        -->
        <xsl:variable name="release" select="$this/imvert:release"/>
        <xsl:choose>
            <xsl:when test="exists($release)">
                <xsl:value-of select="$release"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="imf:msg('ERROR', 'No release found for package: [1] ([2])',($this/imvert:name,$this/imvert:namespace))"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- 
        Get the name of the referencing element. 
        This is the reference class for internal classes (such as AbcRef), or the element itself in any external schema.
        When the external schema conforms to the imvert mode for referencing (AbcRef), and a reference is made to this schema, 
        the reference package (normally generated implictly and on the fly) must be included explicitly.
    -->
    <xsl:function name="imf:get-reference-class-name" as="xs:string">
        <xsl:param name="this" as="node()"/> <!-- any defining class -->
        <xsl:variable name="external-package" select="$this/ancestor::imvert:package[imvert:stereotype/@id = ('stereotype-name-external-package')][1]"/>
        <xsl:variable name="ref-classes" select="$reference-classes[imvert:ref-master=$this/imvert:name]"/> <!-- returns Class1Ref or the like -->
        <xsl:variable name="ref-class" select="$ref-classes[parent::imvert:package/imvert:ref-master=$this/parent::imvert:package/imvert:name]"/>
        <xsl:choose>
            <xsl:when test="$external-package">
                <xsl:value-of select="imf:get-qname($this)"/>
            </xsl:when>
            <xsl:when test="not($external-package) and not($ref-class)">
                <xsl:value-of select="imf:msg('ERROR', 'Cannot determine the reference class for class [1] (package [2])', ($this/imvert:name, $this/parent::imvert:package/imvert:name))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="imf:get-qname($ref-class)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- 
        Return the members of sequence set1 that are not in set2. 
        The comparison is based on the string value of the members. 
    -->
    <xsl:function name="imf:sequence-except-by-string-value" as="item()*">
        <xsl:param name="set1" as="item()*"/>
        <xsl:param name="set2" as="item()*"/>
        <xsl:for-each select="$set1">
            <xsl:variable name="stringvalue" select="xs:string(.)"/>
            <xsl:if test="not($set2 = $stringvalue)">
                <xsl:sequence select="."/>
            </xsl:if>
        </xsl:for-each>
    </xsl:function>

    <!-- 
        Return this class and all classes that are substitutable for this class, that are also linkable (and therefore a reference element must be created). 
        The class passed as rootclass may be abstract and still be linkable; linkable substitution classes must be concrete.
   
        This set also includes classes that realize this class in a static way.
        These classes do not inherit any properties of the realizes class, but can take its place. 
    -->
    <xsl:function name="imf:get-linkable-subclasses-or-self" as="node()*">
        <xsl:param name="rootclass" as="node()"/>
        <xsl:sequence select="imf:get-substitutable-subclasses($rootclass,true())[imf:is-linkable(.)]"/>
    </xsl:function>
    
    <!-- 
        Return all classes that can be substituted for the class passed, and self. 
        Do not return abstract classes. 
    -->
    <xsl:function name="imf:get-substitutable-subclasses" as="element()*">
        <xsl:param name="rootclass" as="element()"/>
        <xsl:param name="include-self" as="xs:boolean"/>
        <xsl:variable name="substitution-classes" select="imf:get-substitution-classes($rootclass)"/>
        <xsl:sequence select="if ($include-self) then $rootclass else ()"/>
        <xsl:sequence select="$substitution-classes"/>
    </xsl:function>
    
    <!-- 
        Return all classes that can be substituted for the class passed, but not self.
        Also returns abstract classes.
    -->
    <xsl:function name="imf:get-substitution-classes" as="node()*">
        <xsl:param name="class" as="node()"/>
        <xsl:variable name="class-id" select="$class/imvert:id"/>
        <xsl:for-each select="$document-classes[imvert:substitution/imvert:supplier-id=$class-id or imvert:supertype/imvert:type-id=$class-id]">
            <xsl:sequence select="."/>
            <xsl:sequence select="imf:get-substitution-classes(.)"/>
        </xsl:for-each>
    </xsl:function>
        
    <xsl:function name="imf:create-xml-debug-comment" as="comment()?">
        <xsl:param name="info-node" as="item()?"/>
        <xsl:param name="text" as="xs:string"/>
        <xsl:param name="parms" as="item()*"/>
        <xsl:if test="$debugging">
            <xsl:comment select="concat(if ($info-node) then imf:get-display-name($info-node) else concat('&quot;',$info-node,'&quot;'),' - ',imf:insert-fragments-by-index($text,$parms))"/>
        </xsl:if>
    </xsl:function>
    
    <xsl:function name="imf:create-xml-debug-comment" as="comment()?">
        <xsl:param name="info-node" as="item()?"/>
        <xsl:param name="text" as="xs:string"/>
        <xsl:sequence select="imf:create-xml-debug-comment($info-node,$text,())"/>
    </xsl:function>

    <!-- return all associations to this class -->
    <xsl:function name="imf:get-references">
        <xsl:param name="class" as="element()"/>
        <xsl:variable name="id" select="$class/imvert:id"/>
        <xsl:sequence select="for $a in $document-classes//imvert:association return if ($a/imvert:type-id = $id) then $a else ()"/>
    </xsl:function>
    
    <xsl:function name="imf:is-abstract">
        <xsl:param name="class"/>
        <xsl:sequence select="imf:boolean($class/imvert:abstract)"/>        
    </xsl:function>

    <xsl:function name="imf:create-scalar-property">
        <xsl:param name="this"/>
        
        <xsl:variable name="scalar-type" select="$this/imvert:type-name"/>
        
        <xsl:variable name="scalar" select="$all-scalars[@id = $scalar-type][last()]"/>
        <xsl:variable name="scalar-construct-pattern" select="$scalar/type-modifier/pattern[@lang=$language]"/>
        <xsl:variable name="scalar-construct-union" select="$scalar/type-modifier/type-map"/>
        
        <xsl:variable name="type-construct">
            <xsl:choose>
                <xsl:when test="exists($scalar-construct-pattern)">
                    <xs:restriction base="xs:string">
                        <xs:pattern value="{$scalar-construct-pattern}"/>
                    </xs:restriction>
                </xsl:when>
                <xsl:when test="exists($scalar-construct-union)">
                    <xs:union memberTypes="{for $t in $scalar-construct-union return concat('xs:', $t)}"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="imf:msg('ERROR','Cannot create scalar type property')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:sequence select="$type-construct"/>
        
    </xsl:function>
    
    <xsl:function name="imf:create-fixtype-property">
        <xsl:param name="scalar-type" as="xs:string"/>
        
        <xsl:variable name="scalar" select="$all-scalars[@id = $scalar-type][last()]"/>
        <xsl:variable name="scalar-construct-pattern" select="$scalar/type-modifier/pattern[@lang=$language]"/>
        <xsl:variable name="scalar-construct-union" select="$scalar/type-modifier/type-map"/>
        
        <xsl:choose>
            <xsl:when test="exists($scalar-construct-pattern)">
                <xs:restriction base="xs:string">
                    <xs:pattern value="{$scalar-construct-pattern}"/>
                </xs:restriction>
            </xsl:when>
            <xsl:when test="exists($scalar-construct-union)">
                <xs:union memberTypes="{for $t in $scalar-construct-union return concat('xs:', $t)}"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="imf:msg('ERROR','Cannot create fixtype property')"/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:function>
    
    <xsl:function name="imf:add-xmlbase" as="element(xs:attribute)?">
        <xsl:param name="is-includable"/>
        <xsl:if test="$is-includable">
            <xs:attribute ref="xml:base" use="optional"/>
        </xsl:if>
    </xsl:function>
    
    <xsl:function name="imf:get-id-attribute" as="element(imvert:attribute)?">
        <xsl:param name="class" as="element(imvert:class)"/>
        <xsl:sequence select="$class/imvert:attributes/imvert:attribute[imf:boolean(imvert:is-id)]"/>
    </xsl:function>
    
</xsl:stylesheet>
