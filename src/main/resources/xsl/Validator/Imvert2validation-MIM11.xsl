<?xml version="1.0" encoding="UTF-8"?>
<!-- 
 * Copyright (C) 2016 
-->
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    
    xmlns:imvert="http://www.imvertor.org/schema/system"
    xmlns:ext="http://www.imvertor.org/xsl/extensions"
    xmlns:imf="http://www.imvertor.org/xsl/functions"
    
    exclude-result-prefixes="#all" 
    version="3.0"
    
    >

    <!-- 
        Validation of MIM 1.1 models. 
    -->
    
    <xsl:import href="../common/Imvert-common.xsl"/>
    <xsl:import href="../common/Imvert-common-validation.xsl"/>
    
    <xsl:variable name="application-package" select="//imvert:package[imf:boolean(imvert:is-root-package)]"/>
    <xsl:variable name="context-signaltype" select="'ERROR'"/><!-- TODO configureerbaar maken? -->
    
    <!-- 
        Document validation; this validates the root (application-)package.
    -->
    <xsl:template match="/imvert:packages">
        <imvert:report>
            <!-- process the application package -->
            <xsl:apply-templates select="imvert:package[imf:member-of(.,$application-package)]"/>
        </imvert:report>
    </xsl:template>
      
    <xsl:template match="imvert:attribute[imvert:stereotype/@id = 'stereotype-name-union-for-attributes']">
        <!--setup-->
        <xsl:sequence select="imf:report-error(., 
            (imvert:min-occurs ne '1' or imvert:max-occurs ne '1'), 
            'Attribute with stereotype [1] must have cardinality of 1..1', imf:get-config-name-by-id('stereotype-name-union'))"/>
        <xsl:next-match/>
    </xsl:template>
    
    <xsl:template match="imvert:association">
        <!--setup-->
        <xsl:variable name="stereotypes" select="imvert:stereotype"/>
        <xsl:variable name="parent-stereotypes" select="../../imvert:stereotype"/>
        <xsl:variable name="allowed-parent-stereotypes" select="$configuration-metamodel-file/stereotypes/stereo[@id = $stereotypes/@id]/context/parent-stereo" as="xs:string*"/>
        
        <xsl:sequence select="imf:report-validation(., 
            exists($allowed-parent-stereotypes) and not($parent-stereotypes/@id = $allowed-parent-stereotypes), 
            $context-signaltype,
            'Association with stereotype [1] must not appear here, expecting (any of) [2]', (imf:string-group($stereotypes),imf:string-group(for $s in $allowed-parent-stereotypes return imf:get-config-name-by-id($s))))"/>
        
        <xsl:next-match/>
    </xsl:template>
    
    <!-- generalisatie kan alleen betrekking hebben op gelijke stereotypen (objecttype generalisayie betreft objecttype etc.) -->
    
    <xsl:template match="imvert:*[imvert:supertype]">
        
        <xsl:variable name="stereotypes" select="imvert:stereotype"/>
        <xsl:variable name="super-stereotypes" select="(for $s in imvert:supertype/imvert:type-id return imf:get-construct-by-id($s))/imvert:stereotype"/>
        <xsl:variable name="allowed-super-stereotypes" select="$configuration-metamodel-file/stereotypes/stereo[@id = $stereotypes/@id]/context/super-stereo" as="xs:string*"/>
        
        <xsl:sequence select="imf:report-validation(., 
            not($super-stereotypes/@id = 'stereotype-name-interface') 
            and
            exists($allowed-super-stereotypes) and not($super-stereotypes/@id = $allowed-super-stereotypes), 
            $context-signaltype,
            'Unexpected stereotype [1] for supertype. My stereotype is [2]', (imf:string-group($super-stereotypes),imf:string-group($stereotypes)))"/>
         
        <xsl:next-match/>
    </xsl:template>
     
    <!--
        Stel vast dat alleen bepaalde stereotypen attribuutsoorten kunnen hebben. 
        
        Aan MIM 1.1 validatie toegevoegd bij de implementatie van MIM 1.1.1
    -->
    <xsl:template match="imvert:attribute" priority="10">
        <xsl:variable name="stereotypes" select="imvert:stereotype"/>
        <xsl:variable name="parent-stereotypes" select="../../imvert:stereotype"/>
        <xsl:variable name="allowed-parent-stereotypes" select="$configuration-metamodel-file/stereotypes/stereo[@id = $stereotypes/@id]/context/parent-stereo" as="xs:string*"/>
        
        <xsl:sequence select="imf:report-validation(., 
            exists($allowed-parent-stereotypes) and not($parent-stereotypes/@id = $allowed-parent-stereotypes), 
            $context-signaltype,
            'Attribute with stereotype [1] must not appear here, expecting (any of) [2]', (imf:string-group($stereotypes),imf:string-group(for $s in $allowed-parent-stereotypes return imf:get-config-name-by-id($s))))"/>
        
        <xsl:next-match/>
    </xsl:template>
    
    <!-- 
        other validation that is required for the immediate XMI translation result. 
    -->
    <xsl:template match="*"> 
        <xsl:apply-templates/>
    </xsl:template> 
    
    <xsl:template match="text()|processing-instruction()"> 
        <!-- nothing -->
    </xsl:template> 
    
</xsl:stylesheet>
