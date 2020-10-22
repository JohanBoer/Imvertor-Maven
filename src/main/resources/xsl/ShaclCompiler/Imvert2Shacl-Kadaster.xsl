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
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:UML="omg.org/UML1.3"
    
    xmlns:imvert="http://www.imvertor.org/schema/system"
    xmlns:ext="http://www.imvertor.org/xsl/extensions"
    xmlns:imf="http://www.imvertor.org/xsl/functions"
    
    xmlns:ekf="http://EliotKimber/functions"

    xmlns:xhtml="http://www.w3.org/1999/xhtml"

    exclude-result-prefixes="#all"
    version="2.0">

    <xsl:import href="../common/Imvert-common.xsl"/>
    <xsl:import href="../common/Imvert-common-derivation.xsl"/>
    <xsl:import href="../common/Imvert-common-conceptual-map.xsl"/>
    
    <xsl:variable name="stylesheet-code">SHACL</xsl:variable>
    <xsl:variable name="debugging" select="imf:debug-mode($stylesheet-code)"/>
    
    <xsl:variable name="str3quot">'''</xsl:variable>
    <xsl:variable name="str2quot">"</xsl:variable>
    <xsl:variable name="str1quot">'</xsl:variable>
    <xsl:variable name="apos">'</xsl:variable>
    
    <xsl:variable name="mn" select="imf:extract(/imvert:packages/imvert:application,'[A-Za-z0-9]+')"/>
    <xsl:variable name="prefixData" select="concat($mn,'Data')"/>
    <xsl:variable name="prefixShacl" select="concat($mn,'Shacl')"/>
    <xsl:variable name="baseurl" select="$configuration-shaclrules-file/vocabularies/base"/>
    
    <xsl:output method="text"/>
    
    <xsl:template match="/">
        <xsl:value-of select="imf:ttl-comment(('Generated by', imf:get-config-string('run','version'), ''))"/>
        <xsl:value-of select="imf:ttl-comment(('Generated at', imf:get-config-string('run','start'), ''))"/>
        <xsl:value-of select="imf:ttl-comment(())"/>
        
        <!-- 
            read the configured info 
        -->
        <xsl:apply-templates select="$configuration-shaclrules-file/vocabularies/vocabulary" mode="preamble"/>
    
        <!-- introduce this model -->
        <xsl:value-of select="imf:ttl-comment(())"/>
        <xsl:value-of select="imf:ttl(('@prefix', concat($prefixData,':'), concat('&lt;',$baseurl,$mn,'#&gt;'), '.'))"/>
        <xsl:value-of select="imf:ttl(('@prefix', concat($prefixShacl,':'), concat('&lt;',$baseurl,'shacl/def/',$mn,'/&gt;'), '.'))"/>
        <xsl:value-of select="imf:ttl-comment(())"/>
        
        <!-- 
            process the imvertor info 
        -->
        <xsl:value-of select="imf:ttl-comment('## Data')"/>
        <xsl:value-of select="imf:ttl(())"/>
        <xsl:apply-templates select="$document-packages" mode="mode-data-subject"/>
        
        <xsl:value-of select="imf:ttl-comment('## Nodeshapes')"/>
        <xsl:value-of select="imf:ttl(())"/>
        <xsl:apply-templates select="$document-packages" mode="mode-shacl-subject"/>
        
    </xsl:template>
   
    <xsl:template match="vocabulary" mode="preamble">
        <xsl:value-of select="imf:ttl(('@prefix', concat(prefix,':'), concat('&lt;', URI ,'&gt;'), '.'))"/>
    </xsl:template>
    
    <xsl:template match="imvert:package" mode="mode-data-subject mode-shacl-subject">
        <xsl:value-of select="imf:ttl-comment(('## Package',imvert:name/@original))"/>
        <xsl:value-of select="imf:ttl(())"/>
        <xsl:apply-templates select="imvert:class" mode="#current"/>
    </xsl:template>
    
    <!--=============== objects ================== -->
    
    <xsl:template match="imvert:class" mode="mode-data-subject">
        <xsl:variable name="this" select="."/>
        
        <xsl:value-of select="imf:ttl-debug(.,'mode-data-subject')"/>
        
        <xsl:value-of select="imf:ttl-start($this)"/>

        <xsl:value-of select="imf:ttl(('kkg:indicatieAbstractObject ',if (imf:boolean($this/imvert:abstract)) then imf:ttl-value($this/imvert:abstract,'2q') else ()))"/>

        <xsl:value-of select="for $super in imf:get-superclass($this) return imf:ttl(('rdfs:subClassOf',imf:ttl-get-uri-name($super)))"/>
       
        <!-- specific properties of class types -->
        
        <xsl:variable name="types" as="xs:string*">
            <!-- stereotype-name-objecttype -->
            <xsl:if test="imvert:stereotype/@id = ('stereotype-name-objecttype')">
                <xsl:value-of select="imf:ttl(('rdf:type','owl:Class'))"/>
            </xsl:if>
            <!-- stereotype-name-composite -->
            <xsl:if test="imvert:stereotype/@id = ('stereotype-name-composite')">
                <xsl:value-of select="imf:ttl(('rdf:type','owl:Class'))"/>
            </xsl:if>
            <!-- stereotype-name-koppelklasse -->
            <xsl:if test="imvert:stereotype/@id = ('stereotype-name-koppelklasse')">
                <xsl:value-of select="imf:ttl(('rdf:type','owl:Class'))"/>
            </xsl:if>
            <!-- stereotype-name-relatieklasse -->
            <xsl:if test="imvert:stereotype/@id = ('stereotype-name-relatieklasse')">
                <xsl:value-of select="imf:ttl(('rdf:type','owl:Class'))"/>
            </xsl:if>
            <!-- stereotype-name-enumeration -->
            <xsl:if test="imvert:stereotype/@id = ('stereotype-name-enumeration')">
                <xsl:value-of select="imf:ttl(('rdf:type','rdfs:Datatype'))"/>
            </xsl:if>
            <!-- stereotype-name-codelist -->
            <xsl:if test="imvert:stereotype/@id = ('stereotype-name-codelist')">
                <xsl:value-of select="imf:ttl(('rdf:type','rdfs:Datatype'))"/>
            </xsl:if>
            <!-- stereotype-name-complextype -->
            <xsl:if test="imvert:stereotype/@id = ('stereotype-name-complextype')">
                <xsl:value-of select="imf:ttl(('rdf:type','rdfs:DatatypeProperty'))"/>
            </xsl:if>
            <!-- stereotype-name-simpletype -->
            <xsl:if test="imvert:stereotype/@id = ('stereotype-name-simpletype')">
                <xsl:value-of select="imf:ttl(('rdf:type','rdfs:DatatypeProperty'))"/>
            </xsl:if>
            <!-- stereotype-name-referentielijst -->
            <xsl:if test="imvert:stereotype/@id = ('stereotype-name-referentielijst')">
                <xsl:value-of select="imf:ttl(('rdf:type','rdfs:Datatype'))"/>
            </xsl:if>
            <!-- stereotype-name-union -->
            <xsl:if test="imvert:stereotype/@id = ('stereotype-name-union')">
                <xsl:value-of select="imf:ttl(('rdf:type','rdfs:Datatype'))"/>
            </xsl:if>
            <!-- stereotype-name-interface -->
            <xsl:if test="imvert:stereotype/@id = ('stereotype-name-interface')">
                <xsl:variable name="type" select="imf:get-conceptual-construct(.)/rdf-type/@name"/>
                <xsl:value-of select="imf:ttl(('rdf:type',$type))"/>
            </xsl:if>
        </xsl:variable>
       
        <xsl:choose>
            <xsl:when test="exists($types)">
                <xsl:value-of select="string-join($types,'')"/>
     
                <xsl:sequence select="imf:ttl-get-all-tvs($this)"/>
                
                <xsl:value-of select="imf:ttl('.')"/>
                
                <!-- loop door alle attributen en associaties heen, en maak daarvoor een subject -->
                <xsl:apply-templates select="$this/imvert:attributes/imvert:attribute[imvert:stereotype/@id = ('stereotype-name-attribute')]" mode="mode-data-subject"/>
                <xsl:apply-templates select="$this/imvert:attributes/imvert:attribute[imvert:stereotype/@id = ('stereotype-name-attributegroup')]" mode="mode-data-subject"/>
                <xsl:apply-templates select="$this/imvert:attributes/imvert:attribute[imvert:stereotype/@id = ('stereotype-name-enum')]" mode="mode-data-subject"/>
                <xsl:apply-templates select="$this/imvert:attributes/imvert:attribute[imvert:stereotype/@id = ('stereotype-name-referentie-element')]" mode="mode-data-subject"/>
                <xsl:apply-templates select="$this/imvert:attributes/imvert:attribute[imvert:stereotype/@id = ('stereotype-name-union-element')]" mode="mode-data-subject"/>
                
                <xsl:apply-templates select="$this/imvert:associations/imvert:association[imvert:target/imvert:stereotype/@id = ('stereotype-name-relation-role')]" mode="mode-data-subject"/>

            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="imf:msg(.,'WARNING','Unable to determine the rdfs:type, stereotype is: [1]',(imf:string-group(imvert:stereotype)))"/>
                <xsl:value-of select="imf:ttl('.')"/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
    <!--=============== subjects ================== -->
    
    <xsl:template match="imvert:attribute" mode="mode-data-subject">
        <xsl:variable name="this" select="."/>
        
        <xsl:value-of select="imf:ttl-debug(.,'mode-data-subject 1')"/>
        
        <xsl:value-of select="imf:ttl-start($this)"/>
        
        <xsl:value-of select="imf:ttl(('kkg:identificerend',imf:ttl-value($this/imvert:is-id,'2q')))"/>
        <xsl:value-of select="imf:ttl(('prov:wasDerivedFrom',imf:ttl-value($this/imvert:is-value-derived,'2q')))"/>
        
        <!-- stereotype-name-attribute -->
        <xsl:if test="imvert:stereotype/@id = ('stereotype-name-attribute')">
            <xsl:value-of select="imf:ttl(('rdf:type','owl:DatatypeProperty'))"/>
        </xsl:if>
        <!-- stereotype-name-attributegroup -->
        <xsl:if test="imvert:stereotype/@id = ('stereotype-name-attributegroup')">
            <xsl:value-of select="imf:ttl(('rdf:type','owl:ObjectProperty'))"/>
        </xsl:if>
        <!-- stereotype-name-union-element -->
        <xsl:if test="imvert:stereotype/@id = ('stereotype-name-union-element')">
            <xsl:value-of select="imf:ttl(('rdf:type','rdfs:DatatypeProperty'))"/>
        </xsl:if>
        <!-- stereotype-name-union-element -->
        <xsl:if test="imvert:stereotype/@id = ('stereotype-name-data-element')">
            <xsl:value-of select="imf:ttl(('rdf:type','rdfs:DatatypeProperty'))"/>
        </xsl:if>
        
        <xsl:sequence select="imf:ttl-get-all-tvs($this)"/>

        <xsl:value-of select="imf:ttl('.')"/>        
        
    </xsl:template>
    
    <xsl:template match="imvert:attribute[imvert:stereotype/@id = ('stereotype-name-enum')]" mode="mode-data-subject">
        <xsl:variable name="this" select="."/>
        
        <xsl:value-of select="imf:ttl-debug(.,'mode-data-subject 2')"/>
        
        <xsl:value-of select="imf:ttl-start($this)"/>

        <!-- géén rdf type, het is alleen een label -->
        <xsl:value-of select="imf:ttl(('uml:stereotype','kkgshape:Enumeratiewaarde'))"/>     
        
        <xsl:sequence select="imf:ttl-get-all-tvs($this)"/>
        
        <xsl:value-of select="imf:ttl('.')"/>        
    </xsl:template>
        
    <xsl:template match="imvert:association" mode="mode-data-subject">
        <xsl:variable name="this" select="."/>
        
        <xsl:value-of select="imf:ttl-debug(.,'mode-data-subject')"/>
        
        <xsl:value-of select="imf:ttl-start($this)"/>
        
        <xsl:variable name="defining-class" select="imf:ttl-get-defining-class($this)"/>
        <xsl:value-of select="imf:ttl(('kkg:gerelateerdObjecttype',imf:ttl-get-uri-name($defining-class)))"/>

        <xsl:value-of select="imf:ttl(('kkg:identificerend',imf:ttl-value($this/imvert:is-id,'2q')))"/>
        <xsl:value-of select="imf:ttl(('prov:wasDerivedFrom',imf:ttl-value($this/imvert:is-value-derived,'2q')))"/>
        <xsl:value-of select="imf:ttl(('kkg:typeAggregatie',if (imvert:aggregation = 'composite') then imf:ttl-value('composite','2q') else ()))"/>
        
        <!-- stereotype-name-attribute -->
        <xsl:if test="imvert:stereotype/@id = ('stereotype-name-attribute')">
            <xsl:value-of select="imf:ttl(('rdf:type','kkgshape:Attribuutsoort'))"/>     
            <xsl:value-of select="imf:ttl(('uml:stereotype','kkg:attribute'))"/>
        </xsl:if>
        <!-- stereotype-name-attributegroup -->
        <xsl:if test="imvert:stereotype/@id = ('stereotype-name-attributegroup')">
            <xsl:value-of select="imf:ttl(('rdf:type','kkgshape:Attribuutgroep'))"/>
            <xsl:value-of select="imf:ttl(('uml:stereotype','kkg:attributegroup'))"/>
        </xsl:if>
        <xsl:if test="imvert:stereotype/@id = ('stereotype-name-enum')">
            <xsl:value-of select="imf:ttl(('rdf:type','kkg:Enum'))"/>     
        </xsl:if>
        <!-- stereotype-name-identification -->
        <xsl:if test="imvert:stereotype/@id = ('stereotype-name-identification')">
            <xsl:value-of select="imf:ttl(('uml:stereotype','kkg:identificatie'))"/>
        </xsl:if>
        
        <xsl:sequence select="imf:ttl-get-all-tvs($this/imvert:target)"/>
        
        <xsl:value-of select="imf:ttl('.')"/>        
        
    </xsl:template>
    
    <!-- == shacl module == -->
    
    <xsl:template match="imvert:class" mode="mode-shacl-subject">
        <xsl:variable name="this" select="."/>
        
        <xsl:value-of select="imf:ttl-debug(.,'mode-shacl-subject 1')"/>
        
        <xsl:value-of select="imf:ttl((concat($prefixShacl,':',$this/@formal-name,'Shape'),'rdf:type','sh:NodeShape',';'))"/>
        
        <xsl:value-of select="imf:ttl(('sh:targetClass',concat($prefixData,':',$this/@formal-name)))"/>
        
        <!-- loop door alle attributen en associaties heen, en plaats een property (predicate object), dus een link naar het attribuut -->
        <xsl:apply-templates select="$this/imvert:attributes/imvert:attribute[imvert:stereotype/@id = ('stereotype-name-attribute')]" mode="mode-shacl-object"/>
        <xsl:apply-templates select="$this/imvert:attributes/imvert:attribute[imvert:stereotype/@id = ('stereotype-name-attributegroup')]" mode="mode-shacl-object"/>
        <xsl:apply-templates select="$this/imvert:attributes/imvert:attribute[imvert:stereotype/@id = ('stereotype-name-enum')]" mode="mode-shacl-object"/>
        <xsl:apply-templates select="$this/imvert:attributes/imvert:attribute[imvert:stereotype/@id = ('stereotype-name-referentie-element')]" mode="mode-shacl-object"/>
        <xsl:apply-templates select="$this/imvert:attributes/imvert:attribute[imvert:stereotype/@id = ('stereotype-name-union-element')]" mode="mode-shacl-object"/>
        
        <xsl:apply-templates select="$this/imvert:associations/imvert:association[imvert:target/imvert:stereotype/@id = ('stereotype-name-relation-role')]" mode="mode-shacl-object"/>
        
        <!-- stereotype-name-objecttype -->
        <xsl:if test="imvert:stereotype/@id = ('stereotype-name-objecttype')">
            <xsl:value-of select="imf:ttl(('uml:stereotype','kkgshape:ObjectType'))"/>
        </xsl:if>
        <!-- stereotype-name-composite -->
        <xsl:if test="imvert:stereotype/@id = ('stereotype-name-composite')">
            <xsl:value-of select="imf:ttl(('uml:stereotype','kkgshape:Gegevensgroeptype'))"/>
        </xsl:if>
        <!-- stereotype-name-koppelklasse -->
        <xsl:if test="imvert:stereotype/@id = ('stereotype-name-koppelklasse')">
            <xsl:value-of select="imf:ttl(('uml:stereotype','kkg:Koppelklasse'))"/>
        </xsl:if>
        <!-- stereotype-name-relatieklasse -->
        <xsl:if test="imvert:stereotype/@id = ('stereotype-name-relatieklasse')">
            <xsl:value-of select="imf:ttl(('uml:stereotype','kkgshape:Relatieklasse'))"/>
        </xsl:if>
        <!-- stereotype-name-enumeration -->
        <xsl:if test="imvert:stereotype/@id = ('stereotype-name-enumeration')">
            <xsl:value-of select="imf:ttl(('uml:stereotype','kkgshape:Enumeratie'))"/>
        </xsl:if>
        <!-- stereotype-name-codelist -->
        <xsl:if test="imvert:stereotype/@id = ('stereotype-name-codelist')">
            <xsl:value-of select="imf:ttl(('uml:stereotype','kkgshape:Codelist'))"/>
        </xsl:if>
        <!-- stereotype-name-complextype -->
        <xsl:if test="imvert:stereotype/@id = ('stereotype-name-complextype')">
            <xsl:value-of select="imf:ttl(('uml:stereotype','kkgshape:GestructureerdDatatype'))"/>
        </xsl:if>
        <!-- stereotype-name-simpletype -->
        <xsl:if test="imvert:stereotype/@id = ('stereotype-name-simpletype')">
            <xsl:value-of select="imf:ttl(('uml:stereotype','kkgshape:PrimitiefDatatype'))"/>
        </xsl:if>
        <!-- stereotype-name-referentielijst -->
        <xsl:if test="imvert:stereotype/@id = ('stereotype-name-referentielijst')">
            <xsl:value-of select="imf:ttl(('uml:stereotype','kkgshape:Referentielijst'))"/>
        </xsl:if>
        <!-- stereotype-name-union -->
        <xsl:if test="imvert:stereotype/@id = ('stereotype-name-union')">
            <xsl:value-of select="imf:ttl(('uml:stereotype','kkgshape:Union'))"/>
        </xsl:if>
        
        <xsl:value-of select="imf:ttl(('sh:severity','sh:Violation'))"/>
      
        <xsl:value-of select="imf:ttl('.')"/>
        
        <!-- loop door alle attributen en associaties heen, en maak daarvoor een subject -->
        <xsl:apply-templates select="$this/imvert:attributes/imvert:attribute[imvert:stereotype/@id = ('stereotype-name-attribute')]" mode="mode-shacl-subject"/>
        <xsl:apply-templates select="$this/imvert:attributes/imvert:attribute[imvert:stereotype/@id = ('stereotype-name-attributegroup')]" mode="mode-shacl-subject"/>
        <xsl:apply-templates select="$this/imvert:attributes/imvert:attribute[imvert:stereotype/@id = ('stereotype-name-enum')]" mode="mode-shacl-subject"/>
        <xsl:apply-templates select="$this/imvert:attributes/imvert:attribute[imvert:stereotype/@id = ('stereotype-name-referentie-element')]" mode="mode-shacl-subject"/>
        <xsl:apply-templates select="$this/imvert:attributes/imvert:attribute[imvert:stereotype/@id = ('stereotype-name-union-element')]" mode="mode-shacl-subject"/>
        
        <xsl:apply-templates select="$this/imvert:associations/imvert:association[imvert:target/imvert:stereotype/@id = ('stereotype-name-relation-role')]" mode="mode-shacl-subject"/>
   
    </xsl:template>
    
    <xsl:template match="imvert:attribute" mode="mode-shacl-object">
        <xsl:variable name="this" select="."/>
        
        <xsl:value-of select="imf:ttl-debug(.,'mode-shacl-object 1')"/>
        
        <xsl:value-of select="imf:ttl(('sh:property',concat($prefixShacl,':',$this/@formal-name,'Shape')))"/>
        
    </xsl:template>
    
    <xsl:template match="imvert:attribute | imvert:association" mode="mode-shacl-subject">
        <xsl:variable name="this" select="."/>
        
        <xsl:value-of select="imf:ttl-debug(.,'mode-shacl-subject 2')"/>
        
        <xsl:value-of select="imf:ttl((concat($prefixShacl,':',$this/@formal-name,'Shape'),'rdf:type','sh:PropertyShape',';'))"/>
        <xsl:value-of select="imf:ttl(('sh:name',imf:ttl-value($this/imvert:name,'2q')))"/>
        <xsl:value-of select="imf:ttl(('sh:path',concat($prefixData,':',$this/@formal-name)))"/>
        
        <xsl:choose>
            <xsl:when test="empty(imvert:baretype)"> <!-- an enum value -->
                <?x
                <xsl:value-of select="imf:ttl(('rdf:type','owl:DatatypeProperty'))"/>
                ?>
            </xsl:when>
            <xsl:when test="empty(imvert:type-id)">
                <?x
                <xsl:value-of select="imf:ttl(('rdf:type','owl:ObjectProperty'))"/>
                ?>
                <xsl:value-of select="imf:ttl(('sh:datatype',imf:get-shacl-primitive-type(imvert:type-name)))"/>
            </xsl:when>
            <xsl:otherwise>
                <?x
                <xsl:value-of select="imf:ttl(('rdf:type','owl:ObjectProperty'))"/>
                ?>
                <xsl:value-of select="imf:ttl(('sh:targetClass',concat($prefixData,':',imf:get-construct-by-id(imvert:type-id)/@formal-name)))"/>
            </xsl:otherwise>
        </xsl:choose>
        
        <!-- stereotype-name-attribute -->
        <xsl:if test="imvert:stereotype/@id = ('stereotype-name-attribute')">
            <xsl:value-of select="imf:ttl(('uml:stereotype','kkgshape:Attribuutsoort'))"/>
        </xsl:if>
        <!-- stereotype-name-attributegroup -->
        <xsl:if test="imvert:stereotype/@id = ('stereotype-name-attributegroup')">
            <xsl:value-of select="imf:ttl(('uml:stereotype','kkgshape:Gegevensgroep'))"/>
        </xsl:if>
        <!-- stereotype-name-union-element -->
        <xsl:if test="imvert:stereotype/@id = ('stereotype-name-union-element')">
            <xsl:value-of select="imf:ttl(('uml:stereotype','kkgshape:UnionElement'))"/>
        </xsl:if>
        <!-- stereotype-name-union-element -->
        <xsl:if test="imvert:stereotype/@id = ('stereotype-name-data-element')">
            <xsl:value-of select="imf:ttl(('uml:stereotype','kkgshape:DataElement'))"/>
        </xsl:if>
        
        <xsl:value-of select="imf:ttl(('sh:minCount',if ($this/imvert:min-occurs != '0') then imf:ttl-value($this/imvert:min-occurs,'2q') else ()))"/>
        <xsl:value-of select="imf:ttl(('sh:maxCount',if ($this/imvert:max-occurs != 'unbounded') then imf:ttl-value($this/imvert:max-occurs,'2q') else ()))"/>

        <xsl:value-of select="imf:ttl(('sh:severity','sh:Violation'))"/>
        <xsl:value-of select="imf:ttl('.')"/>
        
    </xsl:template>
    
    <xsl:template match="node()" mode="mode-data-subject mode-shacl-subject preamble">
        <!-- skip -->        
    </xsl:template>
    
    <!-- formatteren van de TTL: 
        als drie of meer items, spatie gescheiden aan elkaar plakken.
        als twee, dan eindigen met ';';
        anders overslaan.
    -->
    <xsl:function name="imf:ttl" as="xs:string?">
        <xsl:param name="parts" as="item()*"/>
        <xsl:choose>
            <xsl:when test="$parts[3]">
                <xsl:value-of select="concat(string-join($parts,' '),'&#10;')"/>
            </xsl:when>
            <xsl:when test="$parts[2]">
                <xsl:value-of select="concat('   ', $parts[1],' ',$parts[2],' ;','&#10;')"/>
            </xsl:when>
            <xsl:when test="$parts[1] = '.'">
                <xsl:value-of select="concat('.','&#10;&#10;')"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- skip -->
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="imf:ttl-start" as="xs:string">
        <xsl:param name="this" as="element()"/>
        <xsl:variable name="name" select="($this/imvert:target/imvert:role/@original,$this/imvert:name/@original)[1]"/>
        <xsl:value-of select="concat(
            imf:ttl-comment(('Construct:',imf:get-display-name($this), concat('(', string-join($this/imvert:stereotype,', ') ,')'))),
            concat(imf:ttl-get-uri-name($this),'&#10;'),
            imf:ttl(('skos:prefLabel',imf:ttl-value($name,'2q'))),
            imf:ttl(('rdfs:label',imf:ttl-value($name,'2q'))))
        "/>
    </xsl:function>
    
    <xsl:function name="imf:ttl-comment" as="xs:string">
        <xsl:param name="parts" as="item()*"/>
        <xsl:value-of select="concat(if ($parts[1]) then '# ' else '', string-join($parts,' '),'&#10;')"/>
    </xsl:function>
    
    <xsl:function name="imf:ttl-debug" as="xs:string?">
        <xsl:param name="this" as="item()*"/>
        <xsl:param name="parts" as="item()*"/>
        <xsl:if test="$debugging">
            <xsl:value-of select="imf:ttl-comment(('DEBUG: ', imf:get-display-name($this), string-join($this/imvert:stereotype,' | '), $parts))"/>
        </xsl:if>
    </xsl:function>
    
    <!-- return (name, type) sequence -->
    <xsl:function name="imf:ttl-map" as="element(map)?">
        <xsl:param name="id"/>
        <xsl:sequence select="$configuration-shaclrules-file//node-mapping/map[@id=$id]"/>
    </xsl:function>
    
    <xsl:function name="imf:ttl-value" as="xs:string?">
        <xsl:param name="item" as="item()*"/>
        <xsl:param name="type" as="xs:string?"/>
        <xsl:variable name="strings" as="xs:string*">
            <xsl:choose>
                <xsl:when test="$item/xhtml:body">
                    <xsl:for-each select="$item/xhtml:body/*">
                        <xsl:value-of select="."/>
                    </xsl:for-each>
                </xsl:when>
                <xsl:when test="$item/*">
                    <xsl:for-each select="$item/*">
                        <xsl:value-of select="."/>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$item"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="string" select="string-join($strings,'\n')"/>
        <xsl:choose>
            <xsl:when test="not(normalize-space($string))">
                <!-- skip -->
            </xsl:when>
            <xsl:when test="$type = '3q'">
                <xsl:value-of select="concat($str3quot,imf:normalize-ttl-string($string),$str3quot)"/>
            </xsl:when>
            <xsl:when test="$type = '2q'">
                <xsl:value-of select="concat($str2quot,imf:normalize-ttl-string($string),$str2quot)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat($str1quot,imf:normalize-ttl-string($string),$str1quot)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- 
        Haal alle tagged values op in TTL statement formaat.
        Dit zijn alle relevante tv's, dus ook die waarvan de waarde is afgeleid.
    -->
    <xsl:function name="imf:ttl-get-all-tvs">
        <xsl:param name="this"/>
        <!-- loop door alle tagged values heen -->
        <xsl:for-each select="imf:get-config-applicable-tagged-value-ids($this)">
            <xsl:variable name="tv" select="imf:get-most-relevant-compiled-taggedvalue-element($this,concat('##',.))"/>
            <xsl:variable name="map" select="imf:ttl-map($tv/@id)"/>
            <xsl:if test="exists($tv) and exists($map)">
                <xsl:value-of select="imf:ttl(($map, imf:ttl-value($tv,$map/@type)))"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:function>
    
    <!-- 
        return for passed attribute or assoc the class when this is defined in terms of classes 
    -->
    <xsl:function name="imf:ttl-get-defining-class" as="element()?">
        <xsl:param name="this"/>
        <xsl:variable name="type-id" select="$this/imvert:type-id"/>
        <xsl:if test="exists($type-id)">
            <xsl:sequence select="$document-classes[imvert:id = $type-id]"/>
        </xsl:if>
    </xsl:function>
    
    <xsl:function name="imf:ttl-get-uri-name">
        <xsl:param name="construct"/>
        <!--
        <xsl:variable name="dn" select="subsequence(tokenize(imf:get-display-name($class),'\s\('),1,1)"/>
        <xsl:value-of select="concat('data:', string-join(tokenize($dn,'[^A-Za-z0-9]+'),'_'))"/>
        -->
        <xsl:value-of select="concat($prefixData,':', $construct/@formal-name)"/>
    </xsl:function>
    
    <xsl:function name="imf:normalize-ttl-string">
        <xsl:param name="string"/>
        <xsl:value-of select="replace(replace(replace(replace($string,'\\','\\\\'),'&#10;','\\n'),'&quot;','\\&quot;'),$apos,concat('\\',$apos))"/>
    </xsl:function>
    
    <xsl:function name="imf:get-shacl-primitive-type">
        <xsl:param name="imvertor-type-name"/>
        <xsl:choose>
            <xsl:when test="$imvertor-type-name = 'scalar-string'">xsd:string</xsl:when>
            <xsl:when test="$imvertor-type-name = 'scalar-integer'">xsd:integer</xsl:when>
            <xsl:when test="$imvertor-type-name = 'scalar-decimal'">xsd:decimal</xsl:when>
            <xsl:when test="$imvertor-type-name = 'scalar-real'">xsd:decimal</xsl:when>
            <xsl:when test="$imvertor-type-name = 'scalar-boolean'">xsd:boolean</xsl:when>
            <xsl:when test="$imvertor-type-name = 'scalar-datetime'">xsd:dateTime</xsl:when>
            <xsl:when test="$imvertor-type-name = 'scalar-year'">xsd:gYear</xsl:when>
            <xsl:when test="$imvertor-type-name = 'scalar-month'">xsd:gMonth</xsl:when>
            <xsl:when test="$imvertor-type-name = 'scalar-day'">xsd:gDay</xsl:when>
            <xsl:when test="$imvertor-type-name = 'scalar-date'">xsd:date</xsl:when>
            <xsl:when test="$imvertor-type-name = 'scalar-uri'">xsd:anyURI</xsl:when>
            <xsl:otherwise>TODO</xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    
</xsl:stylesheet>
