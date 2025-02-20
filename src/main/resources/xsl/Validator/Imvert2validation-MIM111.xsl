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
        Validation of MIM 1.1.1 models. 
    -->
    
    <xsl:import href="Imvert2validation-MIM11.xsl"/>
    
    <!-- ik neem aan dat constraints alleen mogen voorkomen op 3 benoemde modelelementen -->
    
    <xsl:template match="imvert:constraint">
    
        <xsl:variable name="parent-stereotypes" select="../../imvert:stereotype"/>
        
        <xsl:sequence select="imf:report-error(., 
            not($parent-stereotypes/@id = ('stereotype-name-objecttype','stereotype-name-composite','stereotype-name-relatieklasse')), 
            'Constraint must not appear here', ())"/>
        
        <xsl:next-match/>
        
    </xsl:template>
    
</xsl:stylesheet>
