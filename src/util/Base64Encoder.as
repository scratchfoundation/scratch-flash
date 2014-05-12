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
	import flash.utils.ByteArray;

public class Base64Encoder {

	private static var alphabet:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

	public static function encodeString(s:String):String {
		var data:ByteArray = new ByteArray();
		data.writeUTFBytes(s);
		return encode(data);
	}

	public static function encode(data:ByteArray):String {
		var result:String = "";
		var n:int;
		data.position = 0;
		while (data.bytesAvailable > 2) { // 24 bits -> 4 characters
			n = (data.readUnsignedByte() << 16) | (data.readUnsignedByte() << 8) | data.readUnsignedByte();
			result += alphabet.charAt((n >> 18) & 0x3F);
			result += alphabet.charAt((n >> 12) & 0x3F);
			result += alphabet.charAt((n >>  6) & 0x3F);
			result += alphabet.charAt(n & 0x3F);
		}
		if (data.bytesAvailable == 2) { // leftover 16 bits -> 3 characters + 1 padding character
			n = (data.readUnsignedByte() << 16) | (data.readUnsignedByte() << 8);
			result += alphabet.charAt((n >> 18) & 0x3F);
			result += alphabet.charAt((n >> 12) & 0x3F);
			result += alphabet.charAt((n >>  6) & 0x3F);
			result += "=";			
		}
		if (data.bytesAvailable == 1) { // leftover 8 bits -> 2 characters + 2 padding characters
			n = data.readUnsignedByte() << 16;
			result += alphabet.charAt((n >> 18) & 0x3F);
			result += alphabet.charAt((n >> 12) & 0x3F);
			result += "==";			
		}
		return result;
	}

	public static function decode(s:String):ByteArray {
		var result:ByteArray = new ByteArray();
		var buf:int = 0;
		var bufCount:int = 0;
		for (var i:int = 0; i < s.length; i++) {
			var sixBits:int = alphabet.indexOf(s.charAt(i))
			if (sixBits >= 0) {  // ignore characters not in alphabet (i.e. indexOf() returns -1)
				buf = (buf << 6) + sixBits;
				bufCount++;
			}
			if (bufCount == 4) {
				result.writeByte((buf >> 16) & 0xFF);
				result.writeByte((buf >> 8) & 0xFF);
				result.writeByte(buf & 0xFF);
				buf = 0;
				bufCount = 0;
			}
		}
		if (bufCount > 0) { // write partial buffer (bufCount is 1, 2, or 3)
			buf = buf << ((4 - bufCount) * 6); // zero-pad on right
			result.writeByte((buf >> 16) & 0xFF);
			if (bufCount > 1) result.writeByte((buf >> 8) & 0xFF);
			if (bufCount > 2) result.writeByte(buf & 0xFF);
		}
		result.position = 0;
		return result;
	}

}}
