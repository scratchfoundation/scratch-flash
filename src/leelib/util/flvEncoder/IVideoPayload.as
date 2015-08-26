package leelib.util.flvEncoder
{
	import flash.display.BitmapData;
	import flash.utils.ByteArray;

	public interface IVideoPayload
	{
		function init($width:int, $height:int):void
		function make($bitmapData:BitmapData):ByteArray;
		function kill():void
	}
}