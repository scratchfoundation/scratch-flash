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

// ScratchSound.as
// John Maloney, June 2010
//
// Represents a Scratch sampled sound.
// Possible formats:
//	''			WAVE format 1, 16-bit uncompressed
//	'adpcm'		WAVE format 17, 4-bit ADPCM
//	'squeak'	Squeak ADPCM format, 2-bits to 5-bits per sample
//
// Note: 'mp3' format was removed during alpha test to avoid the need to support MP3 in the future.

package scratch {
import by.blooddy.crypto.MD5;

import flash.utils.*;
	import sound.*;
	import sound.mp3.MP3Loader;
	import util.*;

public class ScratchSound {

	public var soundName:String = '';
	public var soundID:int;
	public var md5:String;
	private var __soundData:ByteArray = new ByteArray();
	public var format:String = '';
	public var rate:int = 44100;
	public var sampleCount:int;
	public var bitsPerSample:int; // used only for compressed Squeak sounds; not saved

	public var editorData:Object; // cache of data used by sound editor; not saved
	private const WasEdited:int = -10; // special soundID used to indicate sounds that have been edited

	// Undo support; not saved
	public var undoList:Array = [];
	public var undoListIndex:int;

	public function ScratchSound(name:String, sndData:ByteArray) {
		this.soundName = name;
		if (sndData != null) {
			try {
				var info:* = WAVFile.decode(sndData);
				if (!((info.encoding == 1) || (info.encoding == 17))) throw Error('Unsupported WAV format');
				soundData = sndData;
				format = (info.encoding == 17) ? 'adpcm' : '';
				rate = info.samplesPerSecond;
				sampleCount = info.sampleCount;
				reduceSizeIfNeeded(info.channels);
			} catch (e:*) {
				setSamples(new Vector.<int>(0), 22050);
			}
		}
	}

	public function get soundData():ByteArray {
		return __soundData;
	}

	public function set soundData(data:ByteArray):void {
		__soundData = data;
		md5 = null;
	}

	private function reduceSizeIfNeeded(channels:int):void {
		// Convert stereo to mono, downsample if rate > 32000, or both.
		// Compress if data is over threshold and not already compressed.
		const compressionThreshold:int = 30 * 44100; // about 30 seconds
		if ((rate > 32000) || (channels == 2)) {
			var newRate:int = (rate > 32000) ? rate / 2 : rate;
			var oldSamples:Vector.<int> = WAVFile.extractSamples(soundData);
			var newSamples:Vector.<int> =
				(channels == 2) ?
					stereoToMono(oldSamples, (newRate < rate)) :
					downsample(oldSamples);
			setSamples(newSamples, newRate, true);
			soundID = 0;
		} else if ((soundData.length > compressionThreshold) && ('' == format)) {
			// Compress large, uncompressed sounds
			setSamples(WAVFile.extractSamples(soundData), rate, true);
		}
	}

	private function stereoToMono(stereo:Vector.<int>, downsample:Boolean):Vector.<int> {
		var mono:Vector.<int> = new Vector.<int>();
		var skip:int = downsample ? 4 : 2;
		var i:int = 0, end:int = stereo.length - 1;
		while (i < end) {
			mono.push((stereo[i] + stereo[i + 1]) / 2);
			i += skip;
		}
		return mono;
	}

	private function downsample(samples:Vector.<int>):Vector.<int> {
		var result:Vector.<int> = new Vector.<int>();
		for (var i:int = 0; i < samples.length; i += 2) result.push(samples[i]);
		return result;
	}

	public function setSamples(samples:Vector.<int>, samplingRate:int, compress:Boolean = false):void {
		var data:ByteArray = new ByteArray();
		data.endian = Endian.LITTLE_ENDIAN;
		for (var i:int = 0; i < samples.length; i++) data.writeShort(samples[i]);
		if (samples.length == 0) data.writeShort(0); // a WAV file must have at least one sample

		soundID = WasEdited;
		soundData = WAVFile.encode(data, samples.length, samplingRate, compress);
		format = compress ? 'adpcm' : '';
		rate = samplingRate;
		sampleCount = samples.length;
	}

	public function convertMP3IfNeeded():void {
		// Support for converting MP3 format sounds in Scratch projects was removed during alpha test.
		// If this is on old, MP3 formatted sound, convert it to WAV format. Otherwise, do nothing.
		function whenDone(snd:ScratchSound):void {
Scratch.app.log('Converting MP3 to WAV: ' + soundName);
			md5 = null;
			soundData = snd.soundData;
			format = snd.format;
			rate = snd.rate;
			sampleCount = snd.sampleCount;
		}
		if (format == 'mp3') {
			if (soundData) MP3Loader.convertToScratchSound('', soundData, whenDone);
			else setSamples(new Vector.<int>, 22050);
		}
	}

	public function sndplayer():ScratchSoundPlayer {
		var player:ScratchSoundPlayer
		if (format == 'squeak') player = new SqueakSoundPlayer(soundData, bitsPerSample, rate);
		else if ((format == '') || (format == 'adpcm')) player = new ScratchSoundPlayer(soundData);
		else player = new ScratchSoundPlayer(WAVFile.empty()); // player on empty sound
		player.scratchSound = this;
		return player;
	}

	public function duplicate():ScratchSound {
		var dup:ScratchSound = new ScratchSound(soundName, null);
		dup.setSamples(getSamples(), rate, (format == 'adpcm'));
		return dup;
	}

	public function getSamples():Vector.<int> {
		if (format == 'squeak') prepareToSave(); // convert to WAV
		if ((format == '') || (format == 'adpcm')) return WAVFile.extractSamples(soundData);
		return new Vector.<int>(0); // dummy data
	}

	public function getLengthInMsec():Number { return (1000.0 * sampleCount) / rate};

	public function toString():String {
		var secs:Number = Math.ceil(getLengthInMsec() / 1000);
		var result:String = 'ScratchSound(' + secs + ' secs, ' + rate;
		if (format != '') result += ' ' + format;
		result += ')';
		return result;
	}

	public function prepareToSave():void {
		if (format == 'squeak') { // convert Squeak ADPCM to WAV ADPCM
			var uncompressedData:ByteArray = new SqueakSoundDecoder(bitsPerSample).decode(soundData);
			if (uncompressedData.length == 0) uncompressedData.writeShort(0); // a WAV file must have at least one sample
Scratch.app.log('Converting squeak sound to WAV ADPCM; sampleCount old: ' + sampleCount + ' new: ' + (uncompressedData.length / 2));
			sampleCount = uncompressedData.length / 2;
			soundData = WAVFile.encode(uncompressedData, sampleCount, rate, true);
			format = 'adpcm';
			bitsPerSample = 4;
			md5 = null;
		}
		reduceSizeIfNeeded(1); // downsample or compress to reduce size before saving
		if (soundID == WasEdited) { md5 = null; soundID = -1 } // sound was edited; force md5 to be recomputed
		if (!md5) md5 = by.blooddy.crypto.MD5.hashBytes(soundData) + '.wav';
	}

	public static function isWAV(data:ByteArray):Boolean {
		if (data.length < 12) return false;
		data.position = 0;
		if (data.readUTFBytes(4) != 'RIFF') return false;
		data.readInt();
		return (data.readUTFBytes(4) == 'WAVE');
	}

	public function writeJSON(json:util.JSON):void {
		json.writeKeyValue('soundName', soundName);
		json.writeKeyValue('soundID', soundID);
		json.writeKeyValue('md5', md5);
		json.writeKeyValue('sampleCount', sampleCount);
		json.writeKeyValue('rate', rate);
		json.writeKeyValue('format', format);
	}

	public function readJSON(jsonObj:Object):void {
		soundName = jsonObj.soundName;
		soundID = jsonObj.soundID;
		md5 = jsonObj.md5;
		sampleCount = jsonObj.sampleCount;
		rate = jsonObj.rate;
		format = jsonObj.format;
	}

}}
