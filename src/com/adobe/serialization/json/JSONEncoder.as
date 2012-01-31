/*
  Copyright (c) 2008, Adobe Systems Incorporated
  All rights reserved.

  Redistribution and use in source and binary forms, with or without 
  modification, are permitted provided that the following conditions are
  met:

  * Redistributions of source code must retain the above copyright notice, 
    this list of conditions and the following disclaimer.
  
  * Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the 
    documentation and/or other materials provided with the distribution.
  
  * Neither the name of Adobe Systems Incorporated nor the names of its 
    contributors may be used to endorse or promote products derived from 
    this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
  IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR 
  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

package com.adobe.serialization.json 
{

	import flash.utils.describeType;

	public class JSONEncoder
	{
	
		/** The string that is going to represent the object we're encoding */
		private var jsonString:String;

		/** The options for encoding XML objects */
		private var xmlEncodingOptions:JSONEncoderXMLOptions;
		
		/** The options for encoding Object variables */
		private var encodingOptions:JSONEncoderObjectOptions;

		/** The current level of recursion for encoding Objects and Arrays */
		private var recursionLevel:int = 0;

        /**
		 * Creates a new JSONEncoder.
		 *
		 * @param value The object to encode as a JSON string
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 9.0
		 * @tiptext
		 */
		public function JSONEncoder( value:*,
									 objOptions:JSONEncoderObjectOptions = null,
									 xmlOptions:JSONEncoderXMLOptions = null )
		{

			encodingOptions = objOptions || new JSONEncoderObjectOptions();
			xmlEncodingOptions = xmlOptions || new JSONEncoderXMLOptions();

			jsonString = convertToString( value );
		}
		
		/**
		 * Gets the JSON string from the encoder.
		 *
		 * @return The JSON string representation of the object
		 * 		that was passed to the constructor
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 9.0
		 * @tiptext
		 */
		public function getString():String 
		{
			return jsonString;
		}
		
		/**
		 * Converts a value to it's JSON string equivalent.
		 *
		 * The whole function is one big try/catch. I see no reason why 
		 * "stringifying" something should fail. The least we could do is:
		 * 	{ "unencodablePropertyName" : "Could not encode." }
		 *  
		 * @param value The value to convert.  Could be any 
		 *		type (object, number, array, etc)
		 */
		private function convertToString( value:* ):String
		{
			var tempString:String;
			// determine what value is and convert it based on it's type
			if ( value is String )
			{
				
				// escape the string so it's formatted correctly
				return escapeString( value as String );
				
			}
			else if ( value is Number )
			{
				
				// only encode numbers that finate
				return isFinite( value as Number) ? value.toString() : "null";

			}
			else if ( value is Boolean )
			{
				
				// convert boolean to string easily
				return value ? "true" : "false";

			}
			else if ( value is Array )
			{

				if ( recursionLevel < encodingOptions.maxDepth )
				{ 
					recursionLevel += 1;
					// call the helper method to convert an array
					tempString = arrayToString( value as Array );
					recursionLevel -= 1;
				}
				else
				{
					// could return "null", but this is more informative
					tempString = "\"Max. recursion reached.\"";
				}

				return tempString;

            }
			else if ( value is XML )
			{

                // call the helper method to convert an XML object
                return xmlToString( value );

			}
			else if ( value is Object )
			{

				if ( value != null && recursionLevel < encodingOptions.maxDepth )
				{
					recursionLevel += 1;
					// call the helper method to convert an object
					tempString = objectToString( value );
					recursionLevel -= 1;
				}
				else
				{
					// could return "null", but this is more informative
					tempString = "\"Max. recursion reached.\"";
				}

				return tempString;
			}
            return "null";
		}
		
		/**
		 * Escapes a string accoding to the JSON specification.
		 *
		 * @param str The string to be escaped
		 * @return The string with escaped special characters
		 * 		according to the JSON specification
		 */
		private function escapeString( str:String ):String
		{
			// create a string to store the string's jsonstring value
			var s:String = "";
			// current character in the string we're processing
			var ch:String;
			// store the length in a local variable to reduce lookups
			var len:Number = str.length;
			
			// loop over all of the characters in the string
			for ( var i:int = 0; i < len; i++ )
			{
			
				// examine the character to determine if we have to escape it
				ch = str.charAt( i );
				switch ( ch )
				{

					case '"':	// quotation mark
						s += "\\\"";
						break;

					//case '/':	// solidus
					//	s += "\\/";
					//	break;

					case '\\':	// reverse solidus
						s += "\\\\";
						break;

					case '\b':	// bell
						s += "\\b";
						break;

					case '\f':	// form feed
						s += "\\f";
						break;

					case '\n':	// newline
						s += "\\n";
						break;

					case '\r':	// carriage return
						s += "\\r";
						break;

					case '\t':	// horizontal tab
						s += "\\t";
						break;

					default:	// everything else

						// check for a control character and escape as unicode
						if ( ch < ' ' ) 
						{
							// get the hex digit(s) of the character (either 1 or 2 digits)
							var hexCode:String = ch.charCodeAt( 0 ).toString( 16 );

							// ensure that there are 4 digits by adjusting
							// the # of zeros accordingly.
							var zeroPad:String = hexCode.length == 2 ? "00" : "000";

							// create the unicode escape sequence with 4 hex digits
							s += "\\u" + zeroPad + hexCode;
						}
						else
						{
							// no need to do any special encoding, just pass-through
							s += ch;
						}
				} // end switch

			} // end for loop

			return "\"" + s + "\"";
		}
		
		/**
		 * Converts an array to it's JSON string equivalent
		 *
		 * @param a The array to convert
		 * @return The JSON string representation of <code>a</code>
		 */
		private function arrayToString( a:Array ):String
		{
			// create a string to store the array's jsonstring value
			var s:String = "";
			
			// loop over the elements in the array and add their converted
			// values to the string
			for ( var i:int = 0; i < a.length; i++ ) 
			{
				// when the length is 0 we're adding the first element so
				// no comma is necessary
				if ( s.length > 0 ) 
				{
					// we've already added an element, so add the comma separator
					s += ","
				}
				
				// convert the value to a string
				s += convertToString( a[ i ] );
			}
			
			// KNOWN ISSUE:  In ActionScript, Arrays can also be associative
			// objects and you can put anything in them, ie:
			//		myArray["foo"] = "bar";
			//
			// These properties aren't picked up in the for loop above because
			// the properties don't correspond to indexes.  However, we're
			// sort of out luck because the JSON specification doesn't allow
			// these types of array properties.
			//
			// So, if the array was also used as an associative object, there
			// may be some values in the array that don't get properly encoded.
			//
			// A possible solution is to instead encode the Array as an Object
			// but then it won't get decoded correctly (and won't be an
			// Array instance)
						
			// close the array and return it's string value
			return "[" + s + "]";
		}
		
        /**
         * Converts an XML object to its JSON string equivalent. All text nodes
         * and attribute values are encoded as strings, even if the contents are
         * entirely numerical.
         * 
         * @param xml The XML object to convert
         * @return The JSON string representation of <code>xml</code>
         */
        private function xmlToString( xml:XML ):String
        {
            return "{" 
                + readNode( xml, 0, 1, xmlEncodingOptions.omitRootElement ) 
                + "}";
        }

        private function updateSiblingCount( oCount:Object, name:String ):void
        {
            if ( oCount.hasOwnProperty( name ) )
            {
                oCount[name] += 1;
            }
            else
            {
                oCount[name] = 0;
            }
        }
        private function fixArrayString( s:String, currentSib:int, totalSibs:int, sibName:String ):String
        {
            var result:String = ''

            if ( currentSib == 0 )
            {
                result += escapeString( sibName ) + " : [ ";
            }

            result += s;

            if ( currentSib == totalSibs - 1 )
            {
                result += " ] ";
            }

            return result;
        }

        /**
         * Recursive helper function to convert an XML object to JSON string
         * 
         * @param xml The XML node to convert
         * @param currentSibling The sequence number of this node with respect
         *      to its siblings
         * @param totalSiblings The total number of siblings, including the given node
         * @param omitMe Whether to omit this node's name and attributes. The 
         *      node's children are still parsed. Used at the begining of the 
         *      encoding when the root element is to be skipped. 
         *      Default is false, that is, use the node fully.
         * @return The JSON string representing the <code>xml</code> node
         */ 
        private function readNode( xml:XML, currentSibling:int, totalSiblings:int, omitMe:Boolean = false ):String
        {
            var s:String = "";

            if ( xml.hasSimpleContent() && xml.attributes().length() == 0 && !omitMe )
            {
                // node has simple content and no attributes
                if ( omitMe )
                {
                    // get only the node's contents
                    s += escapeString( xml.toString() );
                }
                else if ( totalSiblings == 1 )
                {
                    // simple element with simple content
                    s += escapeString( xml.localName().toString() ) + ":" 
                        + escapeString( xml.toString() );
                }
                else
                {
                    // simple content, with siblings, must use simplecontentlabel

                    // objectify it
                    s = "{" + escapeString( xmlEncodingOptions.defaultSimpleContentLabel ) 
                        + ":" + escapeString( xml.toString() ) + "}";

                    // fix array issues if any
                    s = fixArrayString( s, currentSibling, totalSiblings, xml.localName().toString() );
                }
            } 
            else
            {
                // s will be a JSON object, "name : { }", but it's better to
                // construct its list of name:value properties first.

                if ( !omitMe )
                {
                    // could combine with the identical _if_ below, but we like
                    // having attributes first in the JSON String, and who knows, 
                    // some JSON-to-XML parsers might actually require it

                    // add attributes as @properties
                    for each ( var attr:XML in xml.attributes() )
                    {
                        if ( s.length > 0 ) {
                            s += ",";
                        }
                        
                        if ( xmlEncodingOptions.useAttributeAtSymbol )
                        {
                            s += escapeString( "@" + attr.localName().toString() );
                        }
                        else
                        {
                            s += escapeString( attr.localName().toString() );
                        }
                        s += ":" + escapeString( attr.toString() );
                    }
                }

                if ( xml.hasSimpleContent() && xml.toString().length > 0 )
                {
                    if ( s.length > 0 ) {
                        s += ",";
                    }

                    // Var xml has simple content with attributes.
                    // The simple content needs its own propertyname.
                    s += escapeString( xmlEncodingOptions.defaultSimpleContentLabel ) 
                        + ":" + escapeString( xml.toString() );
                }
                else
                {
                    var childCount:Object = {};
                    var totalChildrenCount:int;
                    // Loop over all of the children in the XML and 
                    // serialize them along with their values.
                    for each ( var child:XML in xml.children() )
                    {
                        if ( s.length > 0 ) {
                            s += ",";
                        }

                        // xml has complex content 
                        // KNOWN ISSUE: does not deal with namespaced elements properly
                        if ( child.nodeKind() == 'text' )
                        {
                            s += escapeString( xmlEncodingOptions.defaultSimpleContentLabel ) 
                                + ":" + escapeString( xml.toString() );
                        }
                        else if ( child.nodeKind() == 'element' )
                        {
                            updateSiblingCount( childCount, child.localName() );
                            totalChildrenCount = xml.child( child.name() ).length();
    
                            s += readNode( child, childCount[child.localName()], totalChildrenCount );
                        }
                        // parser skips xml comments and processing instructions
                    }
                }

                // s is now a collection of name:value pairs separated by commas.
                
                if ( !omitMe )
                {
                    if ( totalSiblings == 1 )
                    {
                        // Re-assign the value of s to make it a JSON object.
                        s = escapeString( xml.localName().toString() ) 
                            + " : { " + s + " } ";
                    }
                    else
                    {
                        // objectify name:value collection
                        s = " {" + s + "}";
                        
                        // fix array issues
                        s = fixArrayString( s, currentSibling, totalSiblings, xml.localName().toString() );
                    }
                }
            }
            return s;
        }

		/**
		 * Converts an object to its JSON string equivalent
		 *
		 * @param o The object to convert
		 * @return The JSON string representation of <code>o</code>
		 */
		private function objectToString( o:Object ):String
		{
			// create a string to store the object's jsonstring value
			var s:String = "";
			
			// determine if o is a class instance or a plain object
			var classInfo:XML = describeType( o );
			if ( classInfo.@name.toString() == "Object" )
			{
				// the value of o[key] in the loop below - store this 
				// as a variable so we don't have to keep looking up o[key]
				// when testing for valid values to convert
				var value:Object;
				
				// loop over the keys in the object and add their converted
				// values to the string
				for ( var key:String in o )
				{
					// assign value to a variable for quick lookup
					value = o[key];
					
					// don't add function's to the JSON string
					if ( value is Function )
					{
						// skip this key and try another
						continue;
					}
					
					// when the length is 0 we're adding the first item so
					// no comma is necessary
					if ( s.length > 0 )
					{
						// we've already added an item, so add the comma separator
						s += ","
					}
					
					s += escapeString( key ) + ":" + convertToString( value );
				}
			}
			else // o is a class instance
			{
				// Loop over all of the variables and accessors in the class and 
				// serialize them along with their values.
				for each ( var v:XML in classInfo..*.( 
					name() == "variable"
					||
					( 
						name() == "accessor"
						// Issue #116 - Make sure accessors are readable
						&& attribute( "access" ).charAt( 0 ) == "r" ) 
					) )
				{
					// Issue #110 - If [Transient] metadata exists, then we should skip
					if ( v.metadata && v.metadata.( @name == "Transient" ).length() > 0 )
					{
						continue;
					}

					// If property is declared as internal, skip it
					if ( v.@uri != '' && String(v.@uri).indexOf( "internal" ) != -1 )
					{
						continue;
					}

					// When the length is 0 we're adding the first item so
					// no comma is necessary
					if ( s.length > 0 )
					{
						// We've already added an item, so add the comma separator
						s += ","
					}
					
					// If the property matches the exclude list, add it as "excluded"
					if ( encodingOptions.excludedProperties.indexOf( v.@name.toString() ) != -1 )
					{
						s += escapeString( v.@name.toString() ) + ":\"excluded\"";
						continue;
					}

					s += escapeString( v.@name.toString() ) + ":" 
							+ convertToString( o[ v.@name ] );
				}
				
			}
			
			return "{" + s + "}";
		}

	}

}
