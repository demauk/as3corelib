package com.adobe.serialization.json
{
public class JSONEncoderObjectOptions
{
	/**
	 * List of Object properties that the JSONEncoder should exclude.
	 * 
	 * Cheap way of avoiding problematic references.
	 * 
	 * channelSets and responders have circular references, but they're not
	 * problematic thanks to maxDepth.
	 * 
	 * target and currentTarget have not proven themselves very useful, and
	 * excluding them typically reduces the size of the JSON string by an order 
	 * of magnitude.
	 */
	public var excludedProperties:Array =
		[	'target'
		,	'currentTarget'
		];

	/**
	 * Maximum depth of property inspection when encoding Objects and Arrays.
	 * 
	 * Prevents circular references.
	 */
	public var maxDepth:int = 4;

	public function JSONEncoderObjectOptions()
	{
	}
}
}