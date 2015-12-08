package leelib.util.flvEncoder
{
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;

	/**
	 * IBytes allows FlvEncoder to do byte operations on either a ByteArray or a FileStream instance,
	 * without explicitly typing to either.
	 * 
	 * But must be used with an instance of "ByteArrayWrapper" or "FileStreamWrapper" rather than
	 * ByteArray or FileStream directly.
	 * 
	 * "position" has a different signature in ByteArray versus FileStream (uint versus Number),   
	 *	so it gets wrapped with the getter/setter "pos"
	 * 
	 * "length" also needs to values > 2^32 so same treatment applies 
	 */
	public interface IByteable extends IDataInput, IDataOutput
	{
		function get pos():Number;
		function set pos($n:Number):void;

		function get len():Number;
		
		function kill():void;
	}
}
