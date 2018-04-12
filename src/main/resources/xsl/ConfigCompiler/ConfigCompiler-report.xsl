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
    xmlns:ext="http://www.imvertor.org/xsl/extensions"
    xmlns:imvert="http://www.imvertor.org/schema/system"
    xmlns:imf="http://www.imvertor.org/xsl/functions"
    
    exclude-result-prefixes="#all"
    version="2.0">
    
    <!-- 
         report on configuration
    -->
    <xsl:import href="../common/Imvert-common.xsl"/>
    <xsl:import href="../common/Imvert-common-report.xsl"/>
    
    <xsl:import href="ConfigCompiler-conceptualschemas.xsl"/>
    
    <xsl:variable name="configuration-owner-files" select="string-join($configuration-owner-file//name[parent::project-owner],', ')"/>
    <xsl:variable name="configuration-metamodel-files" select="string-join($configuration-metamodel-file//name[parent::metamodel],', ')"/>
    <xsl:variable name="configuration-tagset-files" select="string-join($configuration-tvset-file//name[parent::tagset],', ')"/>
    <xsl:variable name="configuration-schemarules-files" select="string-join($configuration-schemarules-file//name[parent::schema-rules],', ')"/>

    <xsl:template match="/config">
        <report>
            <step-display-name>Config compiler</step-display-name>
            <summary>
                <info label="Models">
                    <xsl:sequence select="imf:report-label('Owner', $configuration-owner-files)"/>
                    <xsl:sequence select="imf:report-label('Metamodel',$configuration-metamodel-files )"/>
                    <xsl:sequence select="imf:report-label('Tagged values',$configuration-tagset-files)"/>
                    <xsl:sequence select="imf:report-label('Schema rules',$configuration-schemarules-files )"/>
                </info>
            </summary>
            <page>
                <title>Configuration</title>
                <content>
                    <div>
                        <h1>Owner</h1>
                        <xsl:apply-templates select="." mode="owner"/>
                    </div>
                    <div>
                        <h1>Metamodel: scalars</h1>
                        <xsl:apply-templates select="." mode="metamodel-scalars"/>
                    </div>        
                    <div>
                        <h1>Metamodel: stereotypes</h1>
                        <xsl:apply-templates select="." mode="metamodel-stereos"/>
                        <xsl:apply-templates select="." mode="metamodel-stereos-desc"/>
                    </div>  
                    <div>
                        <h1>Metamodel: tagged values</h1>
                        <xsl:apply-templates select="." mode="metamodel-tvs"/>
                        <xsl:apply-templates select="." mode="metamodel-tvs-desc"/>
                    </div>       
                    <div>
                        <h1>Conceptual schemas</h1>
                        <xsl:apply-templates select="." mode="metamodel-cs"/>
                    </div>       
                </content>
            </page>
        </report>
    </xsl:template>

    <xsl:template match="/config" mode="owner">
        <xsl:variable name="rows" as="element(tr)*">
            <xsl:for-each select="$configuration-owner-file/parameter">
                <xsl:sort select="@name"/>
                <tr>
                    <td>
                        <xsl:value-of select="@name"/>
                    </td>
                    <td>
                        <xsl:value-of select="."/>
                    </td>
                    <td>
                        <xsl:value-of select="@src"/>
                    </td>
                </tr>
            </xsl:for-each>
        </xsl:variable>
        <xsl:sequence select="imf:create-result-table-by-tr($rows,'parameter:30,value:50,config:20','table-owner')"/>
    </xsl:template>

    <xsl:template match="/config" mode="metamodel-scalars">
        <xsl:variable name="rows" as="element(tr)*">
            <xsl:for-each select="$configuration-metamodel-file//scalars/scalar">
                <xsl:sort select="name[1]"/>
                <tr>
                    <td>
                        <xsl:value-of select="string-join(name,', ')"/>
                        <span class="tid">
                            <xsl:value-of select="@id"/>
                        </span>
                    </td>
                    <td>
                        <xsl:value-of select="name[1]/@src"/>
                    </td>
                </tr>
            </xsl:for-each>
        </xsl:variable>
        <xsl:sequence select="imf:create-result-table-by-tr($rows,'scalar:80,config:20','table-scalars')"/>
    </xsl:template>
    
    <!--
         <stereo id="stereotype-name-referentielijst">
            <name lang="nl" original="referentielijst">REFERENTIELIJST</name>
            <desc>
                Een lijst met een opsomming van de mogelijke domeinwaarden van een attribuutsoort die in de loop van de tijd kan veranderen.
                Voorbeeld: referentielijst LAND, referentielijst NATIONALITEIT
               (Een "rij" in de "tabel".)
            </desc>
            <construct>class</construct>
            <construct>datatype</construct>
         </stereo>
    -->
    <xsl:template match="/config" mode="metamodel-stereos">
        <div>
            <h2>Stereotype configuration</h2>
            <xsl:variable name="rows" as="element(tr)*">
                <xsl:for-each select="$configuration-metamodel-file//stereotypes/stereo">
                    <xsl:sort select="name[1]"/>
                    <tr>
                        <td>
                            <xsl:value-of select="string-join(name,', ')"/>
                            <span class="tid">
                                <xsl:value-of select="@id"/>
                            </span>
                        </td>
                        <td>
                            <xsl:value-of select="string-join(construct,', ')"/>
                        </td>
                        <td>
                            <xsl:value-of select="name[1]/@src"/>
                        </td>
                    </tr>
                </xsl:for-each>
            </xsl:variable>
            <xsl:sequence select="imf:create-result-table-by-tr($rows,'stereo:40,on constructs:40,config:20','table-stereos')"/>
        </div>
    </xsl:template>
    
    <xsl:template match="/config" mode="metamodel-stereos-desc">
        <div>
            <h2>Stereotype descriptions</h2>
            <xsl:variable name="rows" as="element(tr)*">
                <xsl:for-each select="$configuration-metamodel-file//stereotypes/stereo">
                    <xsl:sort select="name[1]"/>
                    <tr>
                        <td>
                            <xsl:value-of select="string-join(name,', ')"/>
                            <span class="tid">
                                <xsl:value-of select="@id"/>
                            </span>
                        </td>
                        <td>
                            <xsl:value-of select="string-join(desc,', ')"/>
                        </td>
                    </tr>
                </xsl:for-each>
            </xsl:variable>
            <xsl:sequence select="imf:create-result-table-by-tr($rows,'stereo:20,description:80','table-stereo-desc')"/>
        </div>
    </xsl:template>
    
    <!--
     <tv id="CFG-TV-SOURCE" norm="space">
            <name lang="nl" original="Herkomst">herkomst</name>
            <derive>yes</derive>
            <stereotypes>
               <stereo required="yes" lang="nl" original="Objecttype">OBJECTTYPE</stereo>
               <stereo required="yes" lang="nl" original="Complex datatype">COMPLEX DATATYPE</stereo>
               <stereo required="yes" lang="nl" original="Data element">DATA ELEMENT</stereo>
               <stereo required="yes" lang="nl" original="Attribuutsoort">ATTRIBUUTSOORT</stereo>
               <stereo required="yes" lang="nl" original="Relatiesoort">RELATIESOORT</stereo>
               <stereo required="yes" lang="nl" original="Gegevensgroeptype">GEGEVENSGROEPTYPE</stereo>
               <stereo required="yes" lang="nl" original="Referentielijst">REFERENTIELIJST</stereo>
               <stereo required="yes" lang="nl" original="Referentie element">REFERENTIE ELEMENT</stereo>
               <stereo required="yes" lang="nl" original="Union">UNION</stereo>
               <stereo required="yes" lang="nl" original="Union element">UNION ELEMENT</stereo>
               <stereo required="no" lang="nl" original="Codelijst">CODELIJST</stereo>
               <stereo required="no" lang="nl" original="Relatierol">RELATIEROL</stereo>
            </stereotypes>
            <declared-values/>
     </tv> 
    -->
    <xsl:template match="/config" mode="metamodel-tvs">
        <div>
            <h2>Tagged value configuration</h2>
            <xsl:variable name="rows" as="element(tr)*">
                <xsl:for-each select="$configuration-tvset-file//tagged-values/tv">
                    <xsl:sort select="name[1]"/>
                    <tr>
                        <td>
                            <xsl:value-of select="string-join(name,', ')"/>
                            <span class="tid">
                                <xsl:value-of select="@id"/>
                            </span>
                            <xsl:value-of select="if (normalize-space(@cross-meta)) then concat('Cross meta: ', @cross-meta) else ''"/>
                        </td>
                        <td>
                           <xsl:value-of select="derive"/>
                        </td>
                        <td>
                            <xsl:variable name="subrows" as="element(tr)*">
                                <xsl:for-each select="stereotypes/stereo">
                                    <tr>
                                        <td><xsl:value-of select="."/></td>
                                        <td><xsl:value-of select="@original"/></td>
                                        <td><xsl:value-of select="@minmax"/></td>
                                    </tr>
                                </xsl:for-each>            
                            </xsl:variable>
                            <xsl:sequence select="imf:create-result-table-by-tr($subrows,'name:40,original name:40,required:20',concat('table-tvs-',generate-id(.)))"/>
                        </td>
                        <td>
                            <xsl:value-of select="name[1]/@src"/>
                        </td>
                    </tr>
                </xsl:for-each>
            </xsl:variable>
            <xsl:sequence select="imf:create-result-table-by-tr($rows,'tagged value:20,derive?:10,stereos:55,config:10','table-tvs')"/>
        </div>
    </xsl:template>
    
    <xsl:template match="/config" mode="metamodel-tvs-desc">
        <div>
            <h2>Tagged value descriptions</h2>
            <xsl:variable name="rows" as="element(tr)*">
                <xsl:for-each select="$configuration-tvset-file//tagged-values/tv">
                    <xsl:sort select="name[1]"/>
                    <tr>
                        <td>
                            <xsl:value-of select="string-join(name,', ')"/>
                            <span class="tid">
                                <xsl:value-of select="@id"/>
                            </span>
                        </td>
                        <td>
                            <xsl:value-of select="desc"/>
                        </td>
                    </tr>
                </xsl:for-each>
            </xsl:variable>
            <xsl:sequence select="imf:create-result-table-by-tr($rows,'tagged value:20,description:80','table-tvs-desc')"/>
        </div>
    </xsl:template>
</xsl:stylesheet>
