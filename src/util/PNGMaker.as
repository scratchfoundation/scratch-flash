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
package util {
import flash.display.BitmapData;
import flash.utils.ByteArray;

public class PNGMaker {

	private var crcTable:Array;

	public function PNGMaker() {
		computerCRCTable();
	}

	public function encode(img:BitmapData, pixelsPerInch:int = 72):ByteArray {
		var png:ByteArray = new ByteArray();

		// PNG signature
		png.writeUnsignedInt(0x89504e47);
		png.writeUnsignedInt(0x0D0A1A0A);

		// header chunk
		var IHDR:ByteArray = new ByteArray();
		IHDR.writeInt(img.width);
		IHDR.writeInt(img.height);
		IHDR.writeUnsignedInt(0x08060000);  // 32-bit RGBA
		IHDR.writeByte(0);
		writeChunk(png, 0x49484452, IHDR);

		// physical pixel dimensions, if needed
		if (pixelsPerInch != 72) {
			const inchesPerMeter:Number = 1 / 0.0254;
			var pHYs:ByteArray = new ByteArray();
			pHYs.writeUnsignedInt(pixelsPerInch * inchesPerMeter);
			pHYs.writeUnsignedInt(pixelsPerInch * inchesPerMeter);
			pHYs.writeByte(1);
			writeChunk(png, 0x70485973, pHYs);
		}

		// data chunk
		var IDAT:ByteArray= new ByteArray();
		for (var i:int = 0; i < img.height; i++) {
			IDAT.writeByte(0);  // no filter
			var j:int, p:uint;
			if (!img.transparent) {
				for (j = 0; j < img.width; j++) {
					p = img.getPixel(j, i);
					IDAT.writeUnsignedInt(((p & 0xFFFFFF) << 8) | 0xFF);
				}
			} else {
				for (j = 0; j < img.width; j++) {
					p = img.getPixel32(j, i);
					IDAT.writeUnsignedInt(((p & 0xFFFFFF) << 8) | (p >>> 24));
				}
			}
		}
		IDAT.compress();
		writeChunk(png, 0x49444154, IDAT);

		// end chunk
		writeChunk(png, 0x49454E44, null);
		return png;
	}

	private function writeChunk(png:ByteArray, chunkType:uint, data:ByteArray):void {
		// write length and type
		png.writeUnsignedInt((data == null) ? 0 : data.length);
		var start:int = png.position;
		png.writeUnsignedInt(chunkType);

		// write data, if any
		if (data != null) png.writeBytes(data);
		var end:int = png.position;

		// compute CRC
		png.position = start;
		var c:uint = 0xFFFFFFFF;
		for (var i:int = 0; i < (end - start); i++) {
			c = crcTable[(c ^ png.readUnsignedByte()) & 0xFF] ^ (c >>> 8);
		}
		c = c ^ 0xFFFFFFFF;

		// write CRC
		png.position = end;
		png.writeUnsignedInt(c);
	}

	private function computerCRCTable():void {
		crcTable = [];
		for (var i:int = 0; i < 256; i++) {
			var c:uint = i;
			for (var j:int = 0; j < 8; j++) {
				c = (c & 1) ? 0xEDB88320 ^ (c >>> 1) : c >>> 1;
			}
			crcTable[i] = c;
		}
	}

}}