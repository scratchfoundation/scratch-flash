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

package sound {
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	import logging.LogLevel;

public class WAVFile {

	public static function empty():ByteArray {
		// Return sound containing a single zero-valued sample.
		// Note: A totally empty WAV file is considered broken by QuickTime and perhaps other sound tools.
		var data:ByteArray = new ByteArray();
		data.writeShort(0);
		return encode(data, 1, 22050, false);
	}

	public static function encode(sampleData:ByteArray, sampleCount:int, rate:int, doCompress:Boolean):ByteArray {
		// Encode the given 16-bit monophonic sample data in Windows WAV file format.
		// If doCompress is true, the sample data is compressed using (lossy) IMA ADPCM for 4:1 compression.
		var result:ByteArray = new ByteArray();
		result.endian = Endian.LITTLE_ENDIAN;
		if (doCompress) {
			writeCompressed(rate, imaCompress(sampleData, 512), sampleCount, 512, result);
		} else {
			writeUncompressed(rate, sampleData, result);
		}
		result.position = 0;
		return result;
	}

	public static function decode(waveData:ByteArray):Object {
		// Decode the given WAV file data and return an Object with the format and sample data.
		var result:Object = new Object();
		waveData.endian = Endian.LITTLE_ENDIAN;
		waveData.position = 0;

		// read WAVE File Header
		if (waveData.readUTFBytes(4) != 'RIFF') throw Error("WAVFile: bad file header");
		var totalSize:int = waveData.readInt();
		if (waveData.length != (totalSize + 8)) trace("WAVFile: bad RIFF size; ignoring");
		if (waveData.readUTFBytes(4) != 'WAVE') throw Error("WAVFile: not a WAVE file");

		// read format chunk
		var formatChunk:ByteArray = extractChunk('fmt ', waveData);
		if (formatChunk.length < 16) throw Error("WAVFile: format chunk is too small");
		var encoding:uint = formatChunk.readUnsignedShort();

		result.encoding = encoding;
		result.channels = formatChunk.readUnsignedShort();
		result.samplesPerSecond = formatChunk.readUnsignedInt();
		result.bytesPerSecond = formatChunk.readUnsignedInt();
		result.blockAlignment = formatChunk.readUnsignedShort();
		result.bitsPerSample = formatChunk.readUnsignedShort();
		if (formatChunk.length >= 18 && encoding == 0xFFFE) {
			var extensionSize:uint = formatChunk.readUnsignedShort();
			if (extensionSize == 22) {
				result.validBitsPerSample = formatChunk.readUnsignedShort();
				result.channelMask = formatChunk.readUnsignedInt();
				result.encoding = encoding = formatChunk.readUnsignedShort();
			}
		}

		// get size of data chunk
		var sampleDataStartAndSize:Array = dataChunkStartAndSize(waveData);
		if (sampleDataStartAndSize == null) sampleDataStartAndSize = [0, 0]; // no 'data' chunk
		result.sampleDataStart = sampleDataStartAndSize[0];
		result.sampleDataSize = sampleDataStartAndSize[1];

		// handle various encodings
		if (encoding == 1) {
			if (!((result.bitsPerSample == 8) || (result.bitsPerSample == 16))) {
				throw Error("WAVFile: can only handle 8-bit or 16-bit uncompressed PCM data");
			}
			result.sampleCount = (result.bitsPerSample == 8) ? result.sampleDataSize : result.sampleDataSize / 2;
		} else if (encoding == 3) {
			result.sampleCount = Math.floor(result.sampleDataSize / (result.bitsPerSample >>> 3));
			waveData.position = result.sampleDataStart;
		} else if (encoding == 17) {
			if (formatChunk.length < 20) throw Error("WAVFile: adpcm format chunk is too small");
			if (result.channels != 1) throw Error("WAVFile: adpcm supports only one channel (monophonic)");
			formatChunk.position += 2;  // skip extra header byte count
			var samplesPerBlock:int = formatChunk.readUnsignedShort();
			result.adpcmBlockSize = ((samplesPerBlock - 1) / 2) + 4; // block size in bytes
			var factChunk:ByteArray = extractChunk('fact', waveData);
			if ((factChunk != null) && (factChunk.length == 4)) {
				result.sampleCount = factChunk.readUnsignedInt();
			} else {
				// this should never happen, since there should always be a 'fact' chunk
				result.sampleCount = 2 * result.sampleDataSize;	 // slight over-estimate (doesn't take ADPCM headers into account)
			}
		} else if (encoding == 85) {
			factChunk = extractChunk('fact', waveData);
			if ((factChunk != null) && (factChunk.length == 4)) {
				result.sampleCount = factChunk.readUnsignedInt();
			}
		} else {
			throw Error("WAVFile: unknown encoding " + encoding);
		}

		return result;
	}

	public static function extractSamples(waveData:ByteArray):Vector.<int> {
		var result:Vector.<int> = new Vector.<int>();
		var info:Object;
		try {
			info = WAVFile.decode(waveData);
		}
		catch (e:*) {
			Scratch.app.log(LogLevel.WARNING, 'Error extracting samples from WAV file', {error: e});
			result.push(0); // a WAV file must have at least one sample
			return result;
		}
		var i:int;
		var v:int;
		if (info.encoding == 1) {
			waveData.position = info.sampleDataStart;
			for (i = 0; i < info.sampleCount; i++) {
				v = (info.bitsPerSample == 8) ? ((waveData.readUnsignedByte() - 128) << 8) : waveData.readShort();
				result.push(v);
			}
		} else if (info.encoding == 3) {
			waveData.position = info.sampleDataStart;
			for (i = 0; i < info.sampleCount; i++) {
				var f:Number = (info.bitsPerSample == 32 ? waveData.readFloat() : waveData.readDouble());
				if (f > 1.0) f = 1.0;
				if (f < -1.0) f = -1.0;
				v = f * 0x7fff;
				result.push(v);
			}
		} else if (info.encoding == 17) {
			var samples:ByteArray = imaDecompress(extractChunk('data', waveData), info.adpcmBlockSize);
			samples.position = 0;
			while (samples.bytesAvailable >= 2) result.push(samples.readShort());
		}
		return result;
	}

	private static function extractChunk(desiredType:String, waveData:ByteArray):ByteArray {
		// Return the contents of the first chunk of the given type or an empty ByteArray if it is not found.
		waveData.position = 12;
		while (waveData.bytesAvailable > 8) {
			var chunkType:String = waveData.readUTFBytes(4);
			var chunkSize:int = waveData.readUnsignedInt();
			if (chunkType == desiredType) {
				if (chunkSize > waveData.bytesAvailable)
					return null;
				var result:ByteArray = new ByteArray();
				result.endian = Endian.LITTLE_ENDIAN;
				waveData.readBytes(result, 0, chunkSize);
				result.position = 0;
				return result;
			} else {
				waveData.position += chunkSize;
			}
		}
		return new ByteArray();
	}

	private static function dataChunkStartAndSize(waveData:ByteArray):Array {
		// Return an Array with the starting offset and size of the first chunk of the given type.
		waveData.position = 12;
		while (waveData.bytesAvailable >= 8) {
			var chunkType:String = waveData.readUTFBytes(4);
			var chunkSize:int = waveData.readUnsignedInt();
			if (chunkType == 'data') {
				if (chunkSize > waveData.bytesAvailable) return null; // bad wave file
				return [waveData.position, chunkSize];
			} else {
				waveData.position += chunkSize;
			}
		}
		return null; // chunk not found; bad wave file
	}

	private static function writeUncompressed(rate:int, sampleData:ByteArray, result:ByteArray):void {
		// Write a header for an uncompressed, monophonic 16-bit PCM WAV file.
		// RIFF + WAVE header
		var sampleCount:int = sampleData.length / 2;
		result.writeUTFBytes('RIFF');
		result.writeInt((2 * sampleCount) + 36); // total size (excluding 8-byte RIFF header)
		result.writeUTFBytes('WAVE');
		// format chunk
		result.writeUTFBytes('fmt ');
		result.writeInt(16);				// format chunk size
		result.writeShort(1);				// encoding; 1 = PCM
		result.writeShort(1);				// channels; 1 = mono
		result.writeInt(rate);				// samplesPerSecond
		result.writeInt(rate * 2);			// bytesPerSecond
		result.writeShort(2);				// blockAlignment
		result.writeShort(16);				// bitsPerSample
		// data chunk
		result.writeUTFBytes('data');
		result.writeInt(2 * sampleCount);	// data chunk size
		result.writeBytes(sampleData);
	}

	private static function writeCompressed(rate:int, compressedData:ByteArray, sampleCount:int, blockSize:int, result:ByteArray):void {
		// Write a WAV file header for IMA ADPCM compression with a 512-byte block size (monophonic).
		// RIFF + WAVE header
		result.writeUTFBytes('RIFF');
		result.writeInt(compressedData.length + 52);	// total size (excluding 8-byte RIFF header)
		result.writeUTFBytes('WAVE');
		// format chunk
		result.writeUTFBytes('fmt ');
		result.writeInt(20);				// format chunk size
		result.writeShort(17);				// encoding; 17 (0x11) = IMA/DVI ADPCM
		result.writeShort(1);				// channels; 1 = mono
		result.writeInt(rate);				// samplesPerSecond
		// Computing bytesPerSec:
		// A byte holds two samples, so with no headers a block would hold 2 * blockSize samples.
		// This is adjusted by the average overhead for block headers. For example, a 512 byte
		// block with a header contains 1017 samples, vs. 1024 samples for no header. Finally,'
		// that ratio is multiplied by half the sampling rate (because of two samples per byte).
		var samplesPerBlock:int = (2 * (blockSize - 4)) + 1;
		var bytesPerSec:int = Math.floor(((2 * blockSize) / samplesPerBlock) * (rate / 2));
		result.writeInt(bytesPerSec);		// bytesPerSecond
		result.writeShort(blockSize);		// blockSize
		result.writeShort(4);				// bitsPerSample
		result.writeShort(2);				// extraHeaderBytes
		result.writeShort(samplesPerBlock);	// samplesPerBlock:
		// fact chunk
		result.writeUTFBytes('fact');
		result.writeInt(4);					// fact chunk size
		result.writeInt(sampleCount);		// sample count
		// data chunk
		result.writeUTFBytes('data');
		result.writeInt(compressedData.length); // data chunk size
		result.writeBytes(compressedData);
	}

	//-----------------------------------------------------------------------
	// ADPCM Sound Compression (WAV file IMA/DVI format, 4-bits per sample)
	//-----------------------------------------------------------------------

	private static const stepTable:Array = [
		7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 19, 21, 23, 25, 28, 31, 34, 37, 41, 45,
		50, 55, 60, 66, 73, 80, 88, 97, 107, 118, 130, 143, 157, 173, 190, 209, 230,
		253, 279, 307, 337, 371, 408, 449, 494, 544, 598, 658, 724, 796, 876, 963,
		1060, 1166, 1282, 1411, 1552, 1707, 1878, 2066, 2272, 2499, 2749, 3024, 3327,
		3660, 4026, 4428, 4871, 5358, 5894, 6484, 7132, 7845, 8630, 9493, 10442, 11487,
		12635, 13899, 15289, 16818, 18500, 20350, 22385, 24623, 27086, 29794, 32767];

	private static const indexTable:Array = [
		-1, -1, -1, -1, 2, 4, 6, 8,
		-1, -1, -1, -1, 2, 4, 6, 8];

	private static function imaCompress(sampleData:ByteArray, blockSize:int):ByteArray {
		// Compress sample data using the IMA ADPCM algorithm.
		// Note: Handles only one channel, 4-bits/sample. 
		var sample:int, predicted:int, index:int = 0;
		var step:int, code:int, diff:int, delta:int;
		var savedNibble:int = -1; // -1 indicates that there is no saved nibble
		var lastSamplePosition:int = sampleData.length - 2;
		var out:ByteArray = new ByteArray();
		out.endian = Endian.LITTLE_ENDIAN;

		// Round sample count up to integral an number of blocks
		var samplesPerBlock:int = (2 * (blockSize - 4)) + 1;
		var blockCount:int = Math.floor(((sampleData.length / 2) + samplesPerBlock - 1) / samplesPerBlock);
		var sampleCount:int = samplesPerBlock * blockCount;

		sampleData.position = 0;
		while (sampleCount-- > 0) {
			sample = (sampleData.position <= lastSamplePosition) ? sampleData.readShort() : 0;
			if ((out.position % blockSize) == 0) { // write the block header
				out.writeShort(sample);
				out.writeByte(index);
				out.writeByte(0);
				predicted = sample;
			} else {
				// compute the 4-bit code for this sample and the delta it encodes
				diff = sample - predicted;
				step = stepTable[index];
				code = delta = 0;
				if (diff < 0) { code = 8; diff = -diff } // negative difference
				if (diff >= step) { code |= 4; diff -= step; delta += step }
				step = step >> 1;
				if (diff >= step) { code |= 2; diff -= step; delta += step }
				step = step >> 1;
				if (diff >= step) { code |= 1; diff -= step; delta += step }
				delta += step >> 1;
				// output code
				if (savedNibble < 0) {
					savedNibble = code;
				} else {
					out.writeByte((code << 4) | savedNibble);
					savedNibble = -1;
				}
				// compute predicted next sample
				predicted += (code & 8) ? -delta : delta;
				if (predicted > 32767) predicted = 32767;
				if (predicted < -32768) predicted = -32768;
				// compute next index
				index += indexTable[code];
				if (index > 88) index = 88;
				if (index < 0) index = 0;
			}
		}
		if (savedNibble >= 0) out.writeByte(savedNibble);
		out.position = 0;
		return out;
	}

	private static function imaDecompress(compressedData:ByteArray, blockSize:int):ByteArray {
		// Decompress sample data using the IMA ADPCM algorithm.
		// Note: Handles only one channel, 4-bits/sample. 
		var sample:int, index:int = 0;
		var step:int, code:int, delta:int;
		var lastByte:int = -1; // -1 indicates that there is no saved lastByte
		var out:ByteArray = new ByteArray();
		out.endian = Endian.LITTLE_ENDIAN;

		// Bail and return no samples if we have no data
		if (!compressedData) return out;

		compressedData.position = 0;
		while (true) {
			if (((compressedData.position % blockSize) == 0) && (lastByte < 0)) { // read block header
				if (compressedData.bytesAvailable == 0) break;
				sample = compressedData.readShort();
				index = compressedData.readUnsignedByte();
				compressedData.position++; // skip extra header byte
				if (index > 88) index = 88;
				out.writeShort(sample);
			} else {
				// read 4-bit code and compute delta from previous sample
				if (lastByte < 0) {
					if (compressedData.bytesAvailable == 0) break;
					lastByte = compressedData.readUnsignedByte();
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
				sample += (code & 8) ? -delta : delta;
				if (sample > 32767) sample = 32767;
				if (sample < -32768) sample = -32768;
				out.writeShort(sample);
			}
		}
		out.position = 0;
		return out;
	}

}}
