package leelib.util.flvEncoder
{
	import flash.display.BitmapData;
	import flash.system.System;
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	/**
	 * AS-3 only algorithm.
	 * No SWC dependencies, no Flash 10 requirement  
	 */	
	public class VideoPayloadMaker implements IVideoPayload
	{
		public function make($bitmapData:BitmapData):ByteArray
		{
			var w:int = $bitmapData.width;
			var h:int = $bitmapData.height;
			
			var ba:ByteArray = new ByteArray();
			
			// VIDEODATA 'header' - frametype (1) + codecid (3)
			ba.writeByte(0x13); 
			
			// SCREENVIDEOPACKET 'header' 
			FlvEncoder.writeUI4_12(ba, int(FlvEncoder.BLOCK_WIDTH/16) - 1,  w); 	// blockwidth/16-1 (4bits) + imagewidth (12bits)
			FlvEncoder.writeUI4_12(ba, int(FlvEncoder.BLOCK_HEIGHT/16) - 1, h);	// blockheight/16-1 (4bits) + imageheight (12bits)			
			
			// IMAGEBLOCKS
			
			var rowMax:int = int(h/FlvEncoder.BLOCK_HEIGHT);
			var rowRemainder:int = h % FlvEncoder.BLOCK_HEIGHT; 
			if (rowRemainder > 0) rowMax += 1;
			
			var colMax:int = int(w/FlvEncoder.BLOCK_WIDTH);
			var colRemainder:int = w % FlvEncoder.BLOCK_WIDTH;				
			if (colRemainder > 0) colMax += 1;
			
			var block:ByteArray = new ByteArray();
			block.endian = Endian.LITTLE_ENDIAN;
			
			for (var row:int = 0; row < rowMax; row++)
			{
				for (var col:int = 0; col < colMax; col++) 
				{
					var xStart:uint = col * FlvEncoder.BLOCK_WIDTH;
					var xLimit:int = (colRemainder > 0 && col + 1 == colMax) ? colRemainder : FlvEncoder.BLOCK_WIDTH;
					var xEnd:int = xStart + xLimit;
					
					var yStart:uint = h - (row * FlvEncoder.BLOCK_HEIGHT); // * goes from bottom to top
					var yLimit:int = (rowRemainder > 0 && row + 1 == rowMax) ? rowRemainder : FlvEncoder.BLOCK_HEIGHT;	
					var yEnd:int = yStart - yLimit;

					// re-use ByteArray
					block.length = 0; 
					
					for (var y:int = yStart-1; y >= yEnd; y--) // (flv's store image data from bottom to top)
					{
						for (var x:int = xStart; x < xEnd; x++) 
						{
							var p:uint = $bitmapData.getPixel(x, y);
							block.writeByte( p & 0xff );	
							block.writeShort(p >> 8);
							// ... this is the equivalent of writing the B, G, and R bytes in sequence 
						}
					}
					
					block.compress();
					
					FlvEncoder.writeUI16(ba, block.length); // write block length (UI16)
					ba.writeBytes( block ); // write block
				}
			}

			block.length = 0;
			block = null;

			return ba;
		}
		
		public function init($width:int, $height:int):void
		{
			// (no particular need in AS3 version)
		}
		
		public function kill():void
		{
			// (no particular need in AS3 version)
		}
	}
	
}