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

// ScratchSoundPlayer.as
// John Maloney, June 2010
//
// A ScratchSoundPlayer outputs sound samples to Flash. This class
// handles sample rate conversion (with interpolation) and optional
// ADPCM decompression. A static variable of this class remembers
// which sounds are playing to support stopAllSounds().

package sound {
	import flash.events.*;
	import flash.media.*;
	import flash.utils.*;
import flash.utils.ByteArray;

import scratch.ScratchSound;

public class ScratchSoundPlayer {

	static public var activeSounds:Array = [];

	static public function stopAllSounds():void {
		// Stop playing all currently playing sounds
		var oldSounds:Array = activeSounds;
		activeSounds = [];
		for each (var player:ScratchSoundPlayer in oldSounds) player.stopPlaying();
	}

	// sound being played
	public var scratchSound:ScratchSound;

	// sound data, step size, and current stream position
	protected var soundData:ByteArray;
	protected var startOffset:int;
	protected var endOffset:int;
	protected var stepSize:Number;
	private var adpcmBlockSize:int;
	protected var bytePosition:int;  // use our own position to allow sound data to be shared
	protected var soundChannel:SoundChannel;
	private var lastBufferTime:uint;

	// volume support
	public var client:*;
	protected var volume:Number = 1.0;
	private var lastClientVolume:Number;

	// interpolation function and state
	protected var getSample:Function;
	private var fraction:Number = 0.0;
	private var thisSample:int, nextSample:int;

	public function ScratchSoundPlayer(wavFileData:ByteArray) {
		getSample = getSample16Uncompressed;
		if (wavFileData != null) {
			var info:* = WAVFile.decode(wavFileData);
			soundData = wavFileData;
			startOffset = info.sampleDataStart;
			endOffset = startOffset + info.sampleDataSize;
			stepSize = info.samplesPerSecond / 44100.0;
			if (info.encoding == 17) {
				adpcmBlockSize = info.adpcmBlockSize;
				getSample = getSampleADPCM;
			} else {
				if (info.bitsPerSample == 8) getSample = getSample8Uncompressed;
				if (info.bitsPerSample == 16) getSample = getSample16Uncompressed;
			}
		}
	}

	public function atEnd():Boolean { return soundChannel == null }

	public function stopPlaying():void {
		if (soundChannel != null) {
			soundChannel.stop();
			soundChannel = null;
		}
		var i:int = activeSounds.indexOf(this);
		if (i >= 0) activeSounds.splice(i, 1);
	}

	public function startPlaying(doneFunction:Function = null):void {
		stopIfAlreadyPlaying();
		activeSounds.push(this);
		bytePosition = startOffset;
		nextSample = getSample();

		var flashSnd:Sound = new Sound();
		flashSnd.addEventListener(SampleDataEvent.SAMPLE_DATA, writeSampleData);
		soundChannel = flashSnd.play();
		if (doneFunction != null) soundChannel.addEventListener(Event.SOUND_COMPLETE, doneFunction);
	}

	protected function stopIfAlreadyPlaying():void {
		if (scratchSound == null) return;
		var stopped:Boolean, i:int;
		for (i = 0; i < activeSounds.length; i++) {
			if (activeSounds[i].scratchSound == scratchSound) {
				activeSounds[i].stopPlaying();
				stopped = true;
			}
		}
		if (stopped) {
			var stillPlaying:Array = [];
			for (i = 0; i < activeSounds.length; i++) {
				if (!activeSounds[i].atEnd()) stillPlaying.push(activeSounds[i]);
			}
			activeSounds = stillPlaying;
		}
	}

	protected function noteFinished():void {
		// Called by subclasses to force ending condition to be true in writeSampleData()
		bytePosition = endOffset;
	}

	private function writeSampleData(evt:SampleDataEvent):void {
		var i:int;
		if ((lastBufferTime != 0) && ((getTimer() - lastBufferTime) > 230)) {
			soundChannel = null; // don't explicitly stop the sound channel in this callback; allow it to stop on its own
			stopPlaying();
			return;
		}
		updateVolume();
		var data:ByteArray = evt.data;
		for (i = 0; i < 4096; i++) {
			var n:Number = interpolatedSample();
			data.writeFloat(n);
			data.writeFloat(n);
		}
		if ((bytePosition >= endOffset) && (lastBufferTime == 0)) {
			lastBufferTime = getTimer();
		}
	}

	protected function interpolatedSample():Number {
		fraction += stepSize;
		while (fraction >= 1.0) {
			thisSample = nextSample;
			nextSample = getSample();
			fraction -= 1.0;
		}
		var out:int = (fraction == 0) ?
			thisSample :
			thisSample + (fraction * (nextSample - thisSample));
		return (volume * out) / 32768.0;
	}

	private function getSample16Uncompressed():int {
		// 16-bit samples, high-byte stored first ("big-endian")
		var result:int = 0;
		if (bytePosition <= (endOffset - 2)) {
			result = (soundData[bytePosition + 1] << 8) + soundData[bytePosition];
			if (result > 32767) result = result - 65536;
			bytePosition += 2;
		} else {
			bytePosition = endOffset;
		}
		return result;
	}

	private function getSample8Uncompressed():int {
		// 8-bit samples, uncompressed
		if (bytePosition >= endOffset) return 0;
		return (soundData[bytePosition++] - 128) << 8;
	}

	public function updateVolume():void {
		if (client == null) {
			volume = 1.0;
			return;
		}
		if (client.volume == lastClientVolume) return; // optimization
		volume = Math.max(0.0, Math.min(client.volume / 100.0, 1.0));
		lastClientVolume = client.volume;
	}

	//-----------------------------------------------------------------------
	// Decoder/player for IMA ADPCM compressed sounds
	//-----------------------------------------------------------------------

	private const indexTable:Array = [-1, -1, -1, -1, 2, 4, 6, 8, -1, -1, -1, -1, 2, 4, 6, 8];
	private const stepTable:Array = [
		7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 19, 21, 23, 25, 28, 31, 34, 37, 41, 45,
		50, 55, 60, 66, 73, 80, 88, 97, 107, 118, 130, 143, 157, 173, 190, 209, 230,
		253, 279, 307, 337, 371, 408, 449, 494, 544, 598, 658, 724, 796, 876, 963,
		1060, 1166, 1282, 1411, 1552, 1707, 1878, 2066, 2272, 2499, 2749, 3024, 3327,
		3660, 4026, 4428, 4871, 5358, 5894, 6484, 7132, 7845, 8630, 9493, 10442, 11487,
		12635, 13899, 15289, 16818, 18500, 20350, 22385, 24623, 27086, 29794, 32767];

	// decoder state
	private var sample:int = 0;
	private var index:int = 0;
	private var lastByte:int = -1; // -1 indicates that there is no saved lastByte

	private function getSampleADPCM():int {
		// Decompress sample data using the IMA ADPCM algorithm.
		// Note: Handles only one channel, 4-bits/sample. 
		var step:int, code:int, delta:int;

		if ((((bytePosition - startOffset) % adpcmBlockSize) == 0) && (lastByte < 0)) { // read block header
			if (bytePosition > (endOffset - 4)) return 0;
			sample = (soundData[bytePosition + 1] << 8) + soundData[bytePosition];
			if (sample > 32767) sample = sample - 65536;
			index = soundData[bytePosition + 2];
			bytePosition += 4;
			if (index > 88) index = 88;
			lastByte = -1;
			return sample;
		} else {
			// read 4-bit code and compute delta
			if (lastByte < 0) {
				if (bytePosition >= endOffset) return 0;
				lastByte = soundData[bytePosition++];
				code = lastByte & 0xF;
			} else {
				code = (lastByte >> 4) & 0xF;
				lastByte = -1;
			}
			step = stepTable[index];
			delta = 0;
			if (code & 4) delta += step;
			if (code & 2) delta += step >> 1;
			if (code & 1) delta += step >> 2;
			delta += step >> 3;
			// compute next index
			index += indexTable[code];
			if (index > 88) index = 88;
			if (index < 0) index = 0;
			// compute and output sample
			sample += ((code & 8) ? -delta : delta);
			if (sample > 32767) sample = 32767;
			if (sample < -32768) sample = -32768;
			return sample;
		}
	}

}}
