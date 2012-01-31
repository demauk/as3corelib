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

	public class JSONToXMLDecoder
	{

		/** 
		 * Flag indicating if the parser should be strict about the format
		 * of the JSON string it is attempting to decode.
		 */
		private var strict:Boolean;

		/** The value that will get parsed from the JSON string */
		private var value:XML;

		/** The tokenizer designated to read the JSON string */
		private var tokenizer:JSONTokenizer;

		/** The current token from the tokenizer */
		private var token:JSONToken;

		/**
		 * Constructs a new JSONToXMLDecoder to parse a JSON string 
		 * into an XML object. 
		 *
		 * @param s The JSON string to be converted into an XML object. It can 
         *      be a single object, which would requires a rootElementName, or 
         *      a single name:value pair, where the value cannot be an array. 
         * @param rootElementName The name of the root element to which the
         *      contents of the JSON string will be appended. If null, the 
         *      parser will attempt to determine a root element from the first
         *      JSON property name.
		 * @param strict Flag indicating if the JSON string needs to
		 * 		strictly match the JSON standard or not.
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 9.0
		 * @tiptext
		 */
		public function JSONToXMLDecoder( s:String, 
                                          rootElementName:String = null,
                                          strict:Boolean = true )
		{
			this.strict = strict;
			tokenizer = new JSONTokenizer( s, strict );

            nextToken();

            if ( !rootElementName ) 
            {
                // The first JSON token must be a single property with an object
                // value: "xmlRoot":{ ... }
                // We'll parse it separately
                value = parseWithRootElement();
            } 
            else
            {
                // User has provided the root name, we'll create it
                value = XML( '<' + rootElementName + '/>' );
                // We have a root element, parse the rest of the JSON into it
                // if there is anything left to parse
                if ( token != null )
                {
                    parseValueInto( value );
                }
            }

			// Make sure the input stream is empty
			if ( strict && nextToken() != null )
			{
				tokenizer.parseError( "Unexpected characters left in input stream" );
			}
		}

		/**
		 * Gets the internal XML that was created by parsing
		 * the JSON string passed to the constructor.
		 *
		 * @return The internal XML representation of the JSON
		 * 		string that was passed to the constructor
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 9.0
		 * @tiptext
		 */
		public function getValue():XML
		{
			return value;
		}

		/**
		 * Returns the next token from the tokenzier reading
		 * the JSON string
		 */
		private function nextToken():JSONToken
		{
			return token = tokenizer.getNextToken();
		}

		/**
		 * Attempt to parse an Array, appending x elements to the XML parent 
         * node, where x is the number of Array members.
         * 
         * @param elementName The name of the element that each array member 
         *      will be decoded into.
         * @param parentNode The node to which the Array members must be 
         *      appended to.
         *  
         * @example Array notation must be very specific in order to be 
         * successfully decoded into XML. The JSON string must be in this sequence:
         * <listing version="3.0">
         * "Element" : [ 
         *      {
         *          "x" : "xvalue",
         *          "y" : "yvalue"
         *      },
         *      {
         *          "x" : "xvalue2",
         *          "y" : "yvalue2"
         *      }
         *  ] 
         * </listing>
         * 
         * The resulting XML elements would be appended to the provided parentNode:
         * <listing version="3.0">
         *  <![CDATA[
         *      <Element>
         *          <x>xvalue</x>
         *          <y>yvalue</y>
         *      </Element>
         *      <Element>
         *          <x>xvalue2</x>
         *          <y>yvalue2</y>
         *      </Element>
         *  ]]>
         * </listing> 
		 */
		private function parseArrayAs( elementName:String, parentNode:XML ):void
		{
			// create a node internally that we're going to attempt
			// to parse from the tokenizer
            var node:XML;

			// grab the next token from the tokenizer to move
			// past the opening [
			nextToken();

			// check to see if we have an empty list
			if ( token.type == JSONTokenType.RIGHT_BRACKET )
			{
				// we're done reading the list
				return;
			}
			// in non-strict mode an empty array is also a comma
			// followed by a right bracket
			else if ( !strict && token.type == JSONTokenType.COMMA )
			{
				// move past the comma
				nextToken();

				// check to see if we're reached the end of the array
				if ( token.type == JSONTokenType.RIGHT_BRACKET )
				{
					return;	
				}
				else
				{
					tokenizer.parseError( "Leading commas are not supported.  Expecting ']' but found " + token.value );
				}
			}

            // deal with elements of the array, and use an "infinite"
			// loop because we could have any amount of elements
			while ( true )
			{
                // array contents should be objects, each of them should 
                // translate to an XML element, which we create here
                node = XML( '<' + elementName + '/>' );

                // parse array member into this element
                parseValueInto( node );

                // append this array element to the array's parent
				parentNode.appendChild( node );

				// after the value there should be a ] or a ,
				nextToken();

				if ( token.type == JSONTokenType.RIGHT_BRACKET )
				{
					// we're done reading the list
					return;
				}
				else if ( token.type == JSONTokenType.COMMA )
				{
					// move past the comma and read another value
					nextToken();

					// Allow arrays to have a comma after the last element
					// if the decoder is not in strict mode
					if ( !strict )
					{
						// Reached ",]" as the end of the array, so return it
						if ( token.type == JSONTokenType.RIGHT_BRACKET )
						{
							return;
						}
					}
				}
				else
				{
					tokenizer.parseError( "Expecting ] or , but found " + token.value );
				}
			}
            return;
		}

		/**
		 * Attempt to parse an object into a list of XML elements.
         * 
         * @param currentNode The XML node that will be the parent of the 
         *      object's name:value pairs.
		 */
		private function parseObjectInto( currentNode:XML ):void
		{
			// create the node internally that we're going to
			// attempt to parse from the tokenizer
            var childNode:XML;

			// store the string part of an object member so
			// that we can assign it a value in the object
			var name:String;

			// property:value pairs in a JSON object can mean many things in XML
            var isElement:Boolean = false;
            var isAttribute:Boolean = false;
            var isTextNode:Boolean = false;

			// grab the next token from the tokenizer, moving past the { char
			nextToken();

			// check to see if we have an empty object
			if ( token.type == JSONTokenType.RIGHT_BRACE )
			{
                return;
            }
			// in non-strict mode an empty object is also a comma
			// followed by a right bracket
			else if ( !strict && token.type == JSONTokenType.COMMA )
			{
				// move past the comma
				nextToken();

				// check to see if we're reached the end of the object
				if ( token.type == JSONTokenType.RIGHT_BRACE )
				{
                    return;
				}
				else
				{
					tokenizer.parseError( "Leading commas are not supported.  Expecting '}' but found " + token.value );
				}
			}

			// deal with members of the object, use an "infinite"
			// loop because we could have any amount of members
			while ( true )
			{
				if ( token.type == JSONTokenType.STRING )
				{
					// the string value we read is the key for the object
					name = String( token.value );

                    isAttribute = name.slice( 0, 1 ) == '@';
                    isTextNode = name == '#text';
                    isElement = !isAttribute && !isTextNode;

					// move past the string to see what's next
					nextToken();

					// after the string there should be a :
					if ( token.type == JSONTokenType.COLON )
					{	
						// move past the : char
						nextToken();

                        if ( isAttribute ) 
                        {
                            // the JSON value should be a simple attr value
                            currentNode.@[name.slice( 1 )] = parseSimpleValue();
                        }
                        else if ( isTextNode )
                        {
                            // the JSON value should be a simple text node value
                            currentNode.appendChild( parseSimpleValue() );
                        }
                        else
                        {
                            // name:value maps neatly to <name>value</name>
                            childNode = XML( '<' + name + '/>' );
                            if ( parseValueInto( childNode, currentNode ) )
                            {
                                // We're parsing a regular Object, append it.
                                currentNode.appendChild( childNode );
                            }
                            // Else, we're parsing an Object-child of an Array,
                            // in which case, there's no need to append it;
                            // the parseArray function will take care of that.
                        }

						// move past the value to see what's next
						nextToken();

						// after the value there's either a } or a ,
						if ( token.type == JSONTokenType.RIGHT_BRACE )
						{
							// we're done reading the object
							return;	
						}
						else if ( token.type == JSONTokenType.COMMA )
						{
							// skip past the comma and read another member
							nextToken();

							// Allow objects to have a comma after the last member
							// if the decoder is not in strict mode
							if ( !strict )
							{
								// Reached ",}" as the end of the object
								if ( token.type == JSONTokenType.RIGHT_BRACE )
								{
									return;
								}
							}
						}
						else
						{
							tokenizer.parseError( "Expecting } or , but found " + token.value );
						}
					}
					else
					{
						tokenizer.parseError( "Expecting : but found " + token.value );
					}
				}
				else
				{	
					tokenizer.parseError( "Expecting string but found " + token.value );
				}
			}
		}

        /**
         * Attempt to parse some XML simple content.
         * 
         * @return A native value.
         */
        private function parseSimpleValue():Object
        {
            // Catch errors when the input stream ends abruptly
            if ( token == null )
            {
                tokenizer.parseError( "Unexpected end of input" );
            }

            if ( token.type & ( JSONTokenType.STRING
                | JSONTokenType.NUMBER 
                | JSONTokenType.TRUE 
                | JSONTokenType.FALSE 
                | JSONTokenType.NULL ) )
            {
                return token.value;
            }

            else
            {
                tokenizer.parseError( "Unexpected token. Expected a simple value but found " + token.value );
            }
            return null;
        }

        /**
         * Attempts to parse a JSON string with a single name:obj entry, where
         * name is the XML root, and obj is an object representing the rest of
         * the XML document.
         * 
         * @return An XML document.
         * @throws JSONParseError 
         */
        private function parseWithRootElement():XML
        {
            var rootName:String;
            var rootNode:XML = null;

            if ( token == null )
            {
                tokenizer.parseError( "Unexpected end of input" );
            }

            // first token must be {
            if ( token.type == JSONTokenType.LEFT_BRACE )
            {
                nextToken();

                // next token must be a string
                if ( token.type == JSONTokenType.STRING ) 
                {
                    // save the prospective root name
                    rootName = token.value.toString();

                    // must check if it's a top-level object
                    nextToken();

                    // next token should be a :
                    if ( token.type == JSONTokenType.COLON ) 
                    {
                        // keep going
                        nextToken();

                        rootNode = XML( '<' + rootName + '/>' );

                        // parse the rest of the string into rootNode
                        parseValueInto( rootNode );

                        nextToken();

                        // next should be the closing }
                        if ( token.type == JSONTokenType.RIGHT_BRACE )
                        {
                            // We're done.
                            // With non-strict parsing, we simply ignore any 
                            // tokens that might remain.
                            // But if it's strict, there should be nothing left.
                            if ( strict && nextToken() != null )
                            {
                                tokenizer.parseError( "Unexpected characters left in input stream" );
                            }
                        }
                        else
                        {
                            tokenizer.parseError( "Unexpected token. Expected } but found " + token.value );
                        }
                    }
                    else 
                    {
                        tokenizer.parseError( "Unexpected token. Expected : but found " + token.value );
                    }
                }
                else
                {
                    tokenizer.parseError( "Unexpected root token. Expected a string but found " + token.value );
                }
            }
            else if ( token.type == JSONTokenType.STRING && token.value == "null" )
            {
                // not a parse error, but there's nothing else to do
            }
            else
            {
                tokenizer.parseError( "Unexpected token. Expected { but found " + token.value );
            }
            return rootNode;
        }

		/**
		 * Attempt to parse an XML value.
         * 
         * @param currentNode The XML node that will contain the value. Unless
         *      the parsed value is an Array, in which case only the 
         *      currentNode's name is used.
         * @param parent The parent-to-be of the currentNode, only necessary
         *      when the parsed value is an Array.
         * @return The completed currentNode, or false if the parsed value was
         *       an Array. 
		 */
		private function parseValueInto( currentNode:XML, parent:XML = null ):Object
		{
			// Catch errors when the input stream ends abruptly
			if ( token == null )
			{
				tokenizer.parseError( "Unexpected end of input" );
			}

			if ( token.type == JSONTokenType.LEFT_BRACE )
            {
				parseObjectInto( currentNode );
            }

            else if ( token.type == JSONTokenType.LEFT_BRACKET )
            {
                if ( !parent )
                {
                    tokenizer.parseError( "Unexpected " + token.value + ". Arrays cannot be decoded into XML if they are not assigned to a property name." );
                }
				parseArrayAs( currentNode.localName(), parent );
                return false;
            }

            else if ( token.type == JSONTokenType.STRING )
            {
                if ( token.value != 'null' )
                {
                    currentNode.appendChild( token.value );
                }
                // if string value is "null" consider it an empty XML value
                // and don't add anything
            }

            else if ( token.type == JSONTokenType.NULL )
            {
                // Adding "null" to an XML value makes no sense,
                // we're leaving the value empty instead,
                // which means not adding any children:
                // currentNode.appendChild( NOTHING );
            }

            else if ( token.type & ( JSONTokenType.NUMBER 
                                    | JSONTokenType.TRUE 
                                    | JSONTokenType.FALSE ) )
            {
                // any other type, add it
                currentNode.appendChild( token.value );
            }

            else
            {
                tokenizer.parseError( "Unexpected " + token.value );
			}

            return currentNode;
		}
	}
}
