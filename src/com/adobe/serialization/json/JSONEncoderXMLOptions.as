package com.adobe.serialization.json
{
public class JSONEncoderXMLOptions
{
    /**
     * Controls whether the encoder omits the XML root element or not.
     * 
     * @default true
     */
    public var omitRootElement:Boolean = true;

    /**
     * XML attributes are converted to JSON object properties. This option
     * controls whether the names of those properties should be prepended with
     * "@" or not.
     * 
     * @default true
     */
    public var useAttributeAtSymbol:Boolean = true;

    /**
     * Specifies the label to use for an XML element's simple content.
     * 
     * Simple content is usually encoded as 'elementName':'simpleContent', but
     * in some cases, notably when the element has attributes, the simple 
     * content needs to be bound to its own property.
     * 
     * Common labels are 'label' and '#text'.
     * 
     * @default '#text'
     */
    public var defaultSimpleContentLabel:String = '#text';

    public function JSONEncoderXMLOptions()
    {
    }
}
}