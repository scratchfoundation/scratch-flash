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

package sound.mp3 {
	import flash.display.*;
	import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.media.Sound;
	import flash.system.*;
	import flash.utils.*;
	import scratch.ScratchSound;

public class MP3Loader {

	public static function convertToScratchSound(sndName:String, sndData:ByteArray, whenDone:Function):void {
		// Attempt to convert the given mp3 data into a ScratchSound (encoded as a WAV file).
		// Call whenDone with the new sound if successful.
		function loaded(mp3Snd:Sound):void {
			extractSamples(sndName, mp3Snd, mp3Info.sampleCount, whenDone);
		}
		var mp3Info:Object = new MP3FileReader(sndData).getInfo();
		if (mp3Info.sampleCount == 0) { // bad MP3 data
			if (Scratch.app.lp) Scratch.app.removeLoadProgressBox();
			whenDone(null);
			return;
		}
		load(sndData, loaded);
	}

	public static function extractSamples(sndName:String, mp3Snd:Sound, mp3SampleCount:int, whenDone:Function):void {
		// Extract the samples from the given mp3 Sound object and convert them into
		// a ScratchSound object, merging stereo channels and downsampling to 22050 samples/second
		// if needed. When finished, call whenDone with the new ScratchSound.
		// Note: The Flash extract() method provides sound data as stereo at 44100 samples/second
		// regardless of the original format of the MP3 file.

		var extractedSamples:Vector.<int> = new Vector.<int>();
		var buf:ByteArray = new ByteArray;
		var convertedSamples:int;

		function convertNextChunk():void {
			buf.position = 0;
			var count:int = mp3Snd.extract(buf, 4000);
			if (count == 0 || convertedSamples >= mp3SampleCount) { // finished!
				if (Scratch.app.lp) Scratch.app.lp.setTitle('Compressing...');
				setTimeout(compressSamples, 50);
				return;
			}
			convertedSamples += count;
			buf.position = 0;
			count = count / 2; // downsample to 22050 samples/sec
			for (var i:int = 0; i < count; i++) {
				// output is the average of left and right channels
				var s:Number = buf.readFloat() + buf.readFloat();
				extractedSamples.push(16383 * s); // s range is -2 to 2; output range is -32766 to 32766
				buf.position += 8; // skip one stereo sample (downsampling)
			}
			if (Scratch.app.lp) Scratch.app.lp.setProgress(Math.min(convertedSamples / mp3SampleCount, 1));
			setTimeout(convertNextChunk, 1);
		}
		function compressSamples():void {
			var snd:ScratchSound = new ScratchSound(sndName, null);
			snd.setSamples(extractedSamples, 22050, true);
			whenDone(snd);
		}

		mp3Snd.extract(buf, 0, 0); // start at the beginning
		convertNextChunk();
	}

	public static function load(mp3Data:ByteArray, whenDone:Function):void {
		function done(snd:Sound):void {
			mp3Data.endian = originalEndian;
			whenDone(snd);
		}
		var originalEndian:String = mp3Data.endian;
		mp3Data.endian = Endian.BIG_ENDIAN;
		var mp3Parser:MP3FileReader = new MP3FileReader(mp3Data);
		generateSound(mp3Parser, whenDone)
	}

	private static function generateSound(mp3Source:MP3FileReader, whenDone:Function):void {
		function swfCreated(evt:Event):void {
			var loaderInfo:LoaderInfo = evt.currentTarget as LoaderInfo;
			var soundClass:Class = loaderInfo.applicationDomain.getDefinition("SoundClass") as Class;
			whenDone(new soundClass());
		}

		var swfBytes:ByteArray = new ByteArray();
		swfBytes.endian = Endian.LITTLE_ENDIAN;

		// Build a SoundClass SWF that contains the definition for class SoundClass
		// containing MP3 audio data. The SWF is constructed in a ByteArray as follows:
		//
		// soundClassSwfBytes1
		// UI32: the total size of the SWF in bytes
		// soundClassSwfBytes2
		// UI32: the size of the audio data in bytes + 9
		// Byte: 1
		// Byte: 0
		// SWF format byte
		// UI32: The number of samples in the audio data (incl seekSamples if mp3)
		// [SI16 seekSamples]
		// audio data
		// soundClassSwfBytes3
		//
		appendBytes(swfBytes, soundClassSwfBytes1);
		var swfSizePosition:uint = swfBytes.position;
		swfBytes.writeInt(0); //swf size will go here
		appendBytes(swfBytes, soundClassSwfBytes2);
		var audioSizePosition:uint = swfBytes.position;
		swfBytes.writeInt(0); // audio data size + 9 will go here
		swfBytes.writeByte(1);
		swfBytes.writeByte(0);
		swfBytes.writeByte(mp3Source.swfFormatByte());
		var sampleSizePosition:uint = swfBytes.position;
		swfBytes.writeInt(0); // the number of samples will go here
		swfBytes.writeShort(0); // seeksamples

		var frameCount:uint = 0;
		var byteCount:uint = 0; // this includes the seeksamples written earlier
		while (true) {
			var frameSize:int = mp3Source.appendFrame(swfBytes);
			if (frameSize == 0) break;
			byteCount += frameSize;
			frameCount++;
		}
		if (byteCount == 0) return;
		appendBytes(swfBytes, soundClassSwfBytes3);

		// update count and size fields
		swfBytes.position = audioSizePosition;
		swfBytes.writeInt(byteCount + 9);
		swfBytes.position = sampleSizePosition;
		swfBytes.writeInt(frameCount * 1152);
		swfBytes.position = swfSizePosition;
		swfBytes.writeInt(swfBytes.length);

		swfBytes.position = 0;

		var loaderContext: LoaderContext = new LoaderContext();
		if (Capabilities.playerType == 'Desktop') loaderContext.allowLoadBytesCodeExecution = true;
		var swfBytesLoader:Loader = new Loader();
		swfBytesLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, swfCreated);
		swfBytesLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(e:Event):void { whenDone(null); });
		swfBytesLoader.loadBytes(swfBytes, loaderContext);
	}

	private static function appendBytes(swf:ByteArray, bytes:Array):void {
		for (var i:int = 0; i < bytes.length; i++) swf.writeByte(bytes[i]);
	}

	private static const soundClassSwfBytes1:Array = [0x46, 0x57, 0x53, 0x09];

	private static const soundClassSwfBytes2:Array = [
		0x78, 0x00, 0x05, 0x5F, 0x00, 0x00, 0x0F, 0xA0,
		0x00, 0x00, 0x0C, 0x01, 0x00, 0x44, 0x11, 0x08,
		0x00, 0x00, 0x00, 0x43, 0x02, 0xFF, 0xFF, 0xFF,
		0xBF, 0x15, 0x0B, 0x00, 0x00, 0x00, 0x01, 0x00,
		0x53, 0x63, 0x65, 0x6E, 0x65, 0x20, 0x31, 0x00,
		0x00, 0xBF, 0x14, 0xC8, 0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, 0x10, 0x00, 0x2E, 0x00,
		0x00, 0x00, 0x00, 0x08, 0x0A, 0x53, 0x6F, 0x75,
		0x6E, 0x64, 0x43, 0x6C, 0x61, 0x73, 0x73, 0x00,
		0x0B, 0x66, 0x6C, 0x61, 0x73, 0x68, 0x2E, 0x6D,
		0x65, 0x64, 0x69, 0x61, 0x05, 0x53, 0x6F, 0x75,
		0x6E, 0x64, 0x06, 0x4F, 0x62, 0x6A, 0x65, 0x63,
		0x74, 0x0F, 0x45, 0x76, 0x65, 0x6E, 0x74, 0x44,
		0x69, 0x73, 0x70, 0x61, 0x74, 0x63, 0x68, 0x65,
		0x72, 0x0C, 0x66, 0x6C, 0x61, 0x73, 0x68, 0x2E,
		0x65, 0x76, 0x65, 0x6E, 0x74, 0x73, 0x06, 0x05,
		0x01, 0x16, 0x02, 0x16, 0x03, 0x18, 0x01, 0x16,
		0x07, 0x00, 0x05, 0x07, 0x02, 0x01, 0x07, 0x03,
		0x04, 0x07, 0x02, 0x05, 0x07, 0x05, 0x06, 0x03,
		0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x02, 0x00,
		0x00, 0x00, 0x02, 0x00, 0x00, 0x01, 0x01, 0x02,
		0x08, 0x04, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
		0x02, 0x01, 0x01, 0x04, 0x01, 0x00, 0x03, 0x00,
		0x01, 0x01, 0x05, 0x06, 0x03, 0xD0, 0x30, 0x47,
		0x00, 0x00, 0x01, 0x01, 0x01, 0x06, 0x07, 0x06,
		0xD0, 0x30, 0xD0, 0x49, 0x00, 0x47, 0x00, 0x00,
		0x02, 0x02, 0x01, 0x01, 0x05, 0x1F, 0xD0, 0x30,
		0x65, 0x00, 0x5D, 0x03, 0x66, 0x03, 0x30, 0x5D,
		0x04, 0x66, 0x04, 0x30, 0x5D, 0x02, 0x66, 0x02,
		0x30, 0x5D, 0x02, 0x66, 0x02, 0x58, 0x00, 0x1D,
		0x1D, 0x1D, 0x68, 0x01, 0x47, 0x00, 0x00, 0xBF,
		0x03
	];

	private static const soundClassSwfBytes3:Array = [
		0x3F, 0x13, 0x0F, 0x00, 0x00, 0x00, 0x01, 0x00,
		0x01, 0x00, 0x53, 0x6F, 0x75, 0x6E, 0x64, 0x43,
		0x6C, 0x61, 0x73, 0x73, 0x00, 0x44, 0x0B, 0x0F,
		0x00, 0x00, 0x00, 0x40, 0x00, 0x00, 0x00
	];

}}
