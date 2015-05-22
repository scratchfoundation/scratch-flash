// Derived from http://richapps.de/?p=97 - Benjamin Dobler (2007)
package util {
import flash.utils.ByteArray;
import flash.utils.Endian;
import flash.display.Loader;
import flash.events.Event;
import flash.media.Sound;
import flash.events.EventDispatcher;

import scratch.ScratchSound;

public class WaveSWF extends EventDispatcher {
	private var bitPos:int = 8;
	private var bitBuf = 0;
	private var loader:Loader;
	public var sound;

	//LinkageClassCode
	private var linkageClass:Array = [-65, 20, -39, 0, 0, 0, 1, 0, 0, 0, 0, 16, 0, 46, 0, 0, 0, 0, 10, 7, 100, 101, 46, 98, 101, 110, 122, 9, 119, 97, 118, 101, 115, 111, 117, 110, 100, 11, 102, 108, 97, 115, 104, 46, 109, 101, 100, 105, 97, 5, 83, 111, 117, 110, 100, 17, 100, 101, 46, 98, 101, 110, 122, 58, 119, 97, 118, 101, 115, 111, 117, 110, 100, 0, 6, 79, 98, 106, 101, 99, 116, 12, 102, 108, 97, 115, 104, 46, 101, 118, 101, 110, 116, 115, 15, 69, 118, 101, 110, 116, 68, 105, 115, 112, 97, 116, 99, 104, 101, 114, 6, 22, 1, 22, 3, 24, 5, 22, 6, 22, 8, 0, 5, 7, 1, 2, 7, 2, 4, 7, 4, 7, 7, 5, 9, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 2, 8, 3, 0, 1, 0, 0, 0, 1, 2, 1, 1, 4, 1, 0, 3, 0, 1, 1, 5, 6, 3, -48, 48, 71, 0, 0, 1, 1, 1, 6, 7, 6, -48, 48, -48, 73, 0, 71, 0, 0, 2, 2, 1, 1, 5, 23, -48, 48, 101, 0, 96, 3, 48, 96, 4, 48, 96, 2, 48, 96, 2, 88, 0, 29, 29, 29, 104, 1, 71, 0, 0];
	private var fileAttributesArray = [68, 17, 8, 0, 0, 0];

	//SymbolClass Code
	private var symbolClassArray:Array = [63, 19, 22, 0, 0, 0, 1, 0, 1, 0, 100, 101, 46, 98, 101, 110, 122, 46, 119, 97, 118, 101, 115, 111, 117, 110, 100, 0];

	function WaveSWF(waveReader:ScratchSound) {
		// Create DefineSound Tag
		var swfData:ByteArray = new ByteArray();

		// WRITE SWF HEADER
		swfData.endian = Endian.LITTLE_ENDIAN;
		swfData.writeUTFBytes("F");
		swfData.writeUTFBytes("W");
		swfData.writeUTFBytes("S");
		swfData.writeByte(9);
		swfData.writeByte(0x00); //Length kanne erst am Schluss ermittelt werden ???
		swfData.writeByte(0x00);
		swfData.writeByte(0x00);
		swfData.writeByte(0x00);
		var rectData:ByteArray = new ByteArray();
		var rect:Rect = new Rect(0, 200, 0, 200);
		rect.writeRect(swfData);
		swfData.writeShort(25 * 256);
		writeUI16(swfData, 1);

		// Write FileAttributes
		for (var i:int = 0; i < fileAttributesArray.length; i++) {
			swfData.writeByte(fileAttributesArray[i]);
		}

		var sampleSize:int = 0;
		if (waveReader.bitsPerSample == 16) {
			sampleSize = 1;
		} else {
			sampleSize = 0;
		}

		var sampleRate:int = 0;
		if (waveReader.rate == 44100) {
			sampleRate = 3;
		} else if (waveReader.rate == 22050) {
			sampleRate = 2;
		} else if (waveReader.rate == 11025) {
			sampleRate = 1;
		}


		// WRITE SOUNDSTREAMHEADER2 TAG
		writeRecordHeader(swfData, 45, 4);
		writeUBits(swfData, 4, 0);
		writeUBits(swfData, 2, sampleRate);
		writeUBits(swfData, 1, sampleSize);
		writeUBits(swfData, 1, waveReader.channels - 1);
		writeUBits(swfData, 4, 0);
		writeUBits(swfData, 2, sampleRate);
		writeUBits(swfData, 1, sampleSize);
		writeUBits(swfData, 1, waveReader.channels - 1);
		swfData.writeShort(0);

		// Write The linkage Class
		for (var i:int = 0; i < linkageClass.length; i++)
			swfData.writeByte(linkageClass[i]);

		// WRITE DEFINESOUND TAG
		writeRecordHeader(swfData, 14, waveReader.soundData.length - waveReader.sampleDataStart + 7);
		swfData.writeShort(1); // Sound Id


		var compression:int = 0; // only raw sound for now
		swfData.writeByte((compression << 4) + (sampleRate << 2) + (sampleSize << 1) + waveReader.channels - 1); //Sound Format + Sample Rate + SampleSize + Channels
		swfData.writeUnsignedInt(waveReader.sampleCount);
		swfData.writeBytes(waveReader.soundData, waveReader.sampleDataStart, waveReader.soundData.length - waveReader.sampleDataStart);


		// Write Symbol Class
		for (var i:int = 0; i < symbolClassArray.length; i++) {
			swfData.writeByte(symbolClassArray[i]);
		}

		// Show Frame
		writeRecordHeader(swfData, 1, 0);

		// EOF
		swfData.writeByte(0x00);
		swfData.writeByte(0x00);

		// UPDATE HEADER SIZE !!!
		swfData.endian = Endian.LITTLE_ENDIAN;
		swfData.position = 4;
		swfData.writeUnsignedInt(swfData.length);

		loader = new Loader();
		loader.loadBytes(swfData);
		loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderComplete);

	}

	private function onLoaderComplete(evt:Event):void {
		var SymbolClass:Class = loader.contentLoaderInfo.applicationDomain.getDefinition("de.benz.wavesound") as Class;
		sound = new SymbolClass() as Sound;
		dispatchEvent(new Event(Event.COMPLETE));
	}

	private function writeUI16(stream:ByteArray, val:int) {
		stream.writeByte(val & 0xff);
		stream.writeByte(val >> 8);
	}

	private function writeRecordHeader(stream:ByteArray, tagID:Number, dataSize:Number, forceLong:Boolean = false):void {
		if (dataSize <= 62 && forceLong == false)
			stream.writeShort((tagID << 6) + dataSize);
		else {
			stream.writeShort((tagID << 6) + 0x3F);
			stream.writeUnsignedInt(dataSize);
		}

	}

	/***
	 * Write an unsigned value to the output stream in the given number of bits
	 */
	private function writeUBits(stream:ByteArray, numBits:int, value:int):void {
		if (numBits == 0) return;

		if (bitPos == 0) bitPos = 8;  //bitBuf was empty

		var bitNum:int = numBits;

		while (bitNum > 0)  //write all bits
		{
			while (bitPos > 0 && bitNum > 0) //write into all position of the bit buffer
			{
				if (getBit(bitNum, value)) bitBuf = setBit(bitPos, bitBuf);

				bitNum--;
				bitPos--;
			}

			if (bitPos == 0) //bit buffer is full - write it
			{
				stream.writeByte(bitBuf);
				bitBuf = 0;
				if (bitNum > 0) bitPos = 8; //prepare for more bits
			}
		}
	}


	/***
	 * Get the given bit (where lowest bit is numbered 1)
	 */
	private function getBit(bitNum:int, value:int) {
		return (value & (1 << (bitNum - 1))) != 0;
	}

	/***
	 * Set the given bit (where lowest bit is numbered 1)
	 */
	private function setBit(bitNum:int, value:int) {
		return value | ( 1 << (bitNum - 1) );
	}


}
}

/**
 * Parts of this code are adapted of the Java transform library from http://www.flagstonesoftware.com/
 **/
import flash.utils.ByteArray;

class Rect {

	private var xMin:int;
	private var xMax:int;
	private var yMin:int;
	private var yMax:int;

	private var bitPos:int = 8;
	private var bitBuf = 0;

	function Rect(xMin:int, xMax:int, yMin:int, yMax:int) {
		this.xMin = xMin;
		this.xMax = xMax;
		this.yMin = yMin;
		this.yMax = yMax;
	}

	public function writeRect(out:ByteArray):void {
		var bitSize:int = getBitSize();
		writeUBits(out, 5, bitSize);
		writeSBits(out, bitSize, xMin);
		writeSBits(out, bitSize, xMax);
		writeSBits(out, bitSize, yMin);
		writeSBits(out, bitSize, yMax);

//		trace("bitPos "+bitPos);
		while (bitPos > 0) {
			writeUBits(out, 1, 0);
		}


//		trace("bitPos "+bitPos);
	}

	/***
	 * Calculate the minimum bit size based on the current values
	 */
	private function getBitSize():int {
		var bitSize:int = 0;
		var bsMinX:int = determineSignedBitSize(xMin);
		var bsMaxX = determineSignedBitSize(xMax);
		var bsMinY = determineSignedBitSize(yMin);
		var bsMaxY = determineSignedBitSize(yMax);

		bitSize = bsMinY;
		if (bitSize < bsMaxX) bitSize = bsMaxX;
		if (bitSize < bsMinX) bitSize = bsMinX;
		if (bitSize < bsMaxY) bitSize = bsMaxY;

		return bitSize;
	}

	public function determineSignedBitSize(value:int):int {
		if (value >= 0) return determineUnsignedBitSize(value) + 1;

		var topBit:int = 31;
		var mask = 0x40000000;

		while (topBit > 0) {
			if ((value & mask) == 0) break;

			mask >>= 1;
			topBit--;
		}

		if (topBit == 0) return 2;  //must have been -1

		//HACK: Flash represents -16 as 110000 rather than 10000 etc..
		var val2:int = value & (( 1 << topBit) - 1 );
		if (val2 == 0) {
			topBit++;
		}

		return topBit + 1;
	}

	public function determineUnsignedBitSize(value:int):int {
		//--This is probably a really bad way of doing this...
		var topBit:int = 32;
		var mask = 0x80000000;

		while (topBit > 0) {
			if ((value & mask) != 0) return topBit;

			mask >>= 1;
			topBit--;
		}

		return 0;
	}

	/***
	 * Write a signed value to the output stream in the given number of bits.
	 * The value must actually fit in that number of bits or it will be garbled
	 */
	public function writeSBits(stream:ByteArray, numBits:int, value:int):void {
		//--Mask out any sign bit
		var lval:int = value & 0x7FFFFFFF;

		if (value < 0) //add the sign bit
		{
			lval |= 1 << (numBits - 1); //lval |= 1L << (numBits-1);
		}

		//--Write the bits as if unsigned
		writeUBits(stream, numBits, lval);
	}

	/***
	 * Write an unsigned value to the output stream in the given number of bits
	 */
	public function writeUBits(stream:ByteArray, numBits:int, value:int):void {
		if (numBits == 0) return;

		if (bitPos == 0) bitPos = 8;  //bitBuf was empty

		var bitNum:int = numBits;

		while (bitNum > 0)  //write all bits
		{
			while (bitPos > 0 && bitNum > 0) //write into all position of the bit buffer
			{
				if (getBit(bitNum, value)) bitBuf = setBit(bitPos, bitBuf);

				bitNum--;
				bitPos--;
			}

			if (bitPos == 0) //bit buffer is full - write it
			{
				stream.writeByte(bitBuf);
				bitBuf = 0;
				if (bitNum > 0) bitPos = 8; //prepare for more bits
			}
		}
	}

	/***
	 * Get the given bit (where lowest bit is numbered 1)
	 */
	public function getBit(bitNum:int, value:int) {
		return (value & (1 << (bitNum - 1))) != 0;
	}

	/***
	 * Set the given bit (where lowest bit is numbered 1)
	 */
	public function setBit(bitNum:int, value:int) {
		return value | ( 1 << (bitNum - 1) );
	}
}