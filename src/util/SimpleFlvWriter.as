/*
 * Scratch Project Editor and Player
 * Copyright (C) 2014 Massachusetts Institute of Technology
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

/*
	SimpleFlvWriter.as
	Lee Felarca
	http://www.zeropointnine.com/blog
	5-2007
	v0.8
	
	Singleton class to create uncompressed FLV files.
	Does not handle audio. Feel free to extend.
	
	Source code licensed under a Creative Commons Attribution 3.0 License.
	http://creativecommons.org/licenses/by/3.0/
	Some Rights Reserved.

	EXAMPLE USAGE:
	
		var myWriter:SimpleFlvWriter = SimpleFlvWriter.getInstance();
		myWriter.createFile(myFile, 320,240, 30, 120);
		myWriter.saveFrame( myBitmapData1 );
		myWriter.saveFrame( myBitmapData2 );
		myWriter.saveFrame( myBitmapData3 ); // etc.
*/
	
package util {
    import flash.display.BitmapData;
    import flash.net.*;
    import flash.utils.ByteArray;

public class SimpleFlvWriter {
		static private var _instance:SimpleFlvWriter;
				
		private var frameWidth:int;
		private var frameHeight:int;
		private var frameRate:Number;
		private var duration:Number;

		private var fs:ByteArray = new ByteArray();
		private const blockWidth:int = 32;
		private const blockHeight:int = 32;
		private var previousTagSize:uint = 0;
		private var iteration:int = 0;
		private var bmp:BitmapData;
		

		public static function getInstance():SimpleFlvWriter 
		{
			if(SimpleFlvWriter._instance == null) 
				SimpleFlvWriter._instance = new SimpleFlvWriter(new SingletonEnforcer());
			return SimpleFlvWriter._instance;
		}

		public function SimpleFlvWriter(singletonEnforcer:SingletonEnforcer)
		{
		}

		public function createFile(bytes:ByteArray, pWidth:int, pHeight:int, pFramesPerSecond:Number, pDurationInSeconds:Number=0):void
		{
			/*
				Parameters:
				
				pFile: The file which will be created and written to
				pWidth: Video height
				pWidth: Video width
				pFramesPerSecond: Determines framerate of created video
				pDurationInSeconds: Duration of video file to be created. Used for metadata only. Optional.
			*/
			
			
			frameWidth = pWidth;
			frameHeight = pHeight;
			frameRate = pFramesPerSecond;
			duration = pDurationInSeconds;

			fs = bytes;

			// create header
			fs.writeBytes( header() );
			
			// create metadata tag
			fs.writeUnsignedInt( previousTagSize );
			fs.writeBytes( flvTagOnMetaData() );
		}

		public function saveFrame(pBitmapData:BitmapData):void
		{
			// bitmap dimensions should of course match parameters passed to createFile()
			bmp = pBitmapData;
			fs.writeUnsignedInt( previousTagSize );
			fs.writeBytes( flvTagVideo() );	
		}
		
		private function header():ByteArray
		{
			var ba:ByteArray = new ByteArray();
			ba.writeByte(0x46) // 'F'
			ba.writeByte(0x4C) // 'L'
			ba.writeByte(0x56) // 'V'
			ba.writeByte(0x01) // Version 1
			ba.writeByte(0x01) // misc flags - video stream only
			ba.writeUnsignedInt(0x09) // header length
			return ba;
		}		
		
		private function flvTagVideo():ByteArray
		{
			var tag:ByteArray = new ByteArray();
			var dat:ByteArray = videoData();
			var timeStamp:uint = uint(1000/frameRate * iteration++);

			// tag 'header'
			tag.writeByte( 0x09 ); 					// tagType = video
			writeUI24(tag, dat.length); 			// data size
			writeUI24(tag, timeStamp);				// timestamp in ms
			tag.writeByte(0);						// timestamp extended, not using *** 
			writeUI24(tag, 0);						// streamID always 0
			
			// videodata			
			tag.writeBytes( dat );
			
			previousTagSize = tag.length;
			return tag;
		}
		
		private function videoData():ByteArray
		{
			var v:ByteArray = new ByteArray;
			
			// VIDEODATA 'header'
			v.writeByte(0x13); // frametype (1) + codecid (3)
			
			// SCREENVIDEOPACKET 'header'			
			// blockwidth/16-1 (4bits) + imagewidth (12bits)
			writeUI4_12(v, int(blockWidth/16) - 1,  frameWidth);
			// blockheight/16-1 (4bits) + imageheight (12bits)
			writeUI4_12(v, int(blockHeight/16) - 1, frameHeight);			

			// VIDEODATA > SCREENVIDEOPACKET > IMAGEBLOCKS:

			var yMax:int = int(frameHeight/blockHeight);
			var yRemainder:int = frameHeight % blockHeight; 
			if (yRemainder > 0) yMax += 1;

			var xMax:int = int(frameWidth/blockWidth);
			var xRemainder:int = frameWidth % blockWidth;				
			if (xRemainder > 0) xMax += 1;
				
			for (var y1:int = 0; y1 < yMax; y1++)
			{
				for (var x1:int = 0; x1 < xMax; x1++) 
				{
					// create block
					var block:ByteArray = new ByteArray();
					
					var yLimit:int = blockHeight;	
					if (yRemainder > 0 && y1 + 1 == yMax) yLimit = yRemainder;

					for (var y2:int = 0; y2 < yLimit; y2++) 
					{
						var xLimit:int = blockWidth;
						if (xRemainder > 0 && x1 + 1 == xMax) xLimit = xRemainder;
						
						for (var x2:int = 0; x2 < xLimit; x2++) 
						{
							var px:int = (x1 * blockWidth) + x2;
							var py:int = frameHeight - ((y1 * blockHeight) + y2); // (flv's save from bottom to top)
							var p:uint = bmp.getPixel(px, py);

							block.writeByte( p & 0xff ); 		// blue	
							block.writeByte( p >> 8 & 0xff ); 	// green
							block.writeByte( p >> 16 ); 		// red
						}
					}
					block.compress();

					writeUI16(v, block.length); // write block length (UI16)
					v.writeBytes( block ); // write block
				}
			}
			return v;
		}

		private function flvTagOnMetaData():ByteArray
		{
			var tag:ByteArray = new ByteArray();
			var dat:ByteArray = metaData();

			// tag 'header'
			tag.writeByte( 18 ); 					// tagType = script data
			writeUI24(tag, dat.length); 			// data size
			writeUI24(tag, 0);						// timestamp should be 0 for onMetaData tag
			tag.writeByte(0);						// timestamp extended
			writeUI24(tag, 0);						// streamID always 0
			
			// data tag		
			tag.writeBytes( dat );
			
			previousTagSize = tag.length;
			return tag;
		}

		private function metaData():ByteArray
		{
			// onMetaData info goes in a ScriptDataObject of data type 'ECMA Array'

			var b:ByteArray = new ByteArray();
			
			// ObjectNameType (always 2)
			b.writeByte(2);	
		
			// ObjectName (type SCRIPTDATASTRING):
			writeUI16(b, "onMetaData".length); // StringLength
			b.writeUTFBytes( "onMetaData" ); // StringData
		
			// ObjectData (type SCRIPTDATAVALUE):
			
			b.writeByte(8); // Type (ECMA array = 8)
			b.writeUnsignedInt(7) // // Elements in array
		
			// SCRIPTDATAVARIABLES...
			
			if (duration > 0) {
				writeUI16(b, "duration".length);
				b.writeUTFBytes("duration");
				b.writeByte(0); 
				b.writeDouble(duration);
			}
			
			writeUI16(b, "width".length);
			b.writeUTFBytes("width");
			b.writeByte(0); 
			b.writeDouble(frameWidth);

			writeUI16(b, "height".length);
			b.writeUTFBytes("height");
			b.writeByte(0); 
			b.writeDouble(frameHeight);

			writeUI16(b, "framerate".length);
			b.writeUTFBytes("framerate");
			b.writeByte(0); 
			b.writeDouble(frameRate);

			writeUI16(b, "videocodecid".length);
			b.writeUTFBytes("videocodecid");
			b.writeByte(0); 
			b.writeDouble(3); // 'Screen Video' = 3

			writeUI16(b, "canSeekToEnd".length);
			b.writeUTFBytes("canSeekToEnd");
			b.writeByte(1); 
			b.writeByte(int(true));

			var mdc:String = "SimpleFLVWriter.as v0.8 zeropointnine.com";			
			writeUI16(b, "metadatacreator".length);
			b.writeUTFBytes("metadatacreator");
			b.writeByte(2); 
			writeUI16(b, mdc.length);
			b.writeUTFBytes(mdc);
			
			// VariableEndMarker1 (type UI24 - always 9)
			writeUI24(b, 9);
		
			return b;			
		}

		private function writeUI24(stream:*, p:uint):void
		{
			var byte1:int = p >> 16;
			var byte2:int = p >> 8 & 0xff;
			var byte3:int = p & 0xff;
			stream.writeByte(byte1);
			stream.writeByte(byte2);
			stream.writeByte(byte3);
		}
		
		private function writeUI16(stream:*, p:uint):void
		{
			stream.writeByte( p >> 8 )
			stream.writeByte( p & 0xff );			
		}

		private function writeUI4_12(stream:*, p1:uint, p2:uint):void
		{
			// writes a 4-bit value followed by a 12-bit value in two sequential bytes

			var byte1a:int = p1 << 4;
			var byte1b:int = p2 >> 8;
			var byte1:int = byte1a + byte1b;
			var byte2:int = p2 & 0xff;

			stream.writeByte(byte1);
			stream.writeByte(byte2);
		}		
	}
}

class SingletonEnforcer {}

/*
	FLV structure summary:

		header
		previoustagsize
		flvtag
			[info]
			videodata
				[info]
				screenvideopacket
					[info]
					imageblocks
					imageblocks
					...
		previoustagsize
		flvtag
		...
		

	FLV file format:
	
		header
		
		last tag size
	
		FLVTAG:
			tagtype
			datasize
			timestamp
			timestampextended
			streamid						
			data [VIDEODATA]:
				frametype
				codecid
				videodata [SCREENVIDEOPACKET]:
					blockwidth						ub[4]
					imagewidth						ub[12]
					blockheight						ub[4]
					imageheight						ub[12]
					imageblocks [IMAGEBLOCKS[]]:	
						datasize					ub[16] <same as 'ub16', i think>
						data..
		
		last tag size
		
		FLVTAG
		
		etc.		
*/
