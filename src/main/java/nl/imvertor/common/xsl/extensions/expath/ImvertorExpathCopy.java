/*
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
 *
 */

package nl.imvertor.common.xsl.extensions.expath;

import net.sf.saxon.expr.XPathContext;
import net.sf.saxon.lib.ExtensionFunctionCall;
import net.sf.saxon.lib.ExtensionFunctionDefinition;
import net.sf.saxon.om.Sequence;
import net.sf.saxon.om.StructuredQName;
import net.sf.saxon.trans.XPathException;
import net.sf.saxon.value.EmptySequence;
import net.sf.saxon.value.SequenceType;
import net.sf.saxon.value.StringValue;
import nl.imvertor.common.Configurator;
import nl.imvertor.common.file.AnyFile;


/**
 * Write XML contents to a file. Circumvents limits of writing to a file from within Saxon/XSLT.
 * 
 * @author Maarten Kroon
 */
public class ImvertorExpathCopy extends ExtensionFunctionDefinition {
  
  private static final StructuredQName qName = new StructuredQName("", Configurator.NAMESPACE_EXTENSION_FUNCTIONS, "imvertorExpathCopy");
  
  @Override
  public StructuredQName getFunctionQName() {
    return qName;
  }

  @Override
  public int getMinimumNumberOfArguments() {
    return 2;
  }

  @Override
  public int getMaximumNumberOfArguments() {
    return 2;
  }

  @Override
  public SequenceType[] getArgumentTypes() {    
    return new SequenceType[] { 
        SequenceType.SINGLE_STRING,
        SequenceType.SINGLE_STRING
    };
  }
  
  @Override
  public SequenceType getResultType(SequenceType[] suppliedArgumentTypes) {    
    return SequenceType.EMPTY_SEQUENCE;
  }
  
  @Override
  public boolean hasSideEffects() {    
    return true;
  }

  @Override
  public ExtensionFunctionCall makeCallExpression() {    
    return new ImvertorExpathCopyCall();
  }
  
  private static class ImvertorExpathCopyCall extends ExtensionFunctionCall {
    
	  private boolean append;
	  
	  @Override
	  public Sequence call(XPathContext context, Sequence[] arguments) throws XPathException {
	    try {
	      AnyFile sourcefile = new AnyFile(((StringValue) arguments[0].head()).getStringValue());
	      AnyFile targetfile = new AnyFile(((StringValue) arguments[1].head()).getStringValue());
	      if (sourcefile.isDirectory()) {
		        throw new XPathException(String.format("Path \"%s\" points to a directory", 
		            sourcefile.getAbsolutePath()), "ERROR_PATH_IS_DIRECTORY");
		      }
	      if (targetfile.isDirectory()) {
		        throw new XPathException(String.format("Path \"%s\" points to a directory", 
		            targetfile.getAbsolutePath()), "ERROR_PATH_IS_DIRECTORY");
		      }
	      sourcefile.copyFile(targetfile);
	      return EmptySequence.getInstance();
	    } catch (XPathException fe) {
	      throw fe;
	    } catch (Exception e) {
	      throw new XPathException("Cannot copy file", e);
	    }
	  }
  }
}
