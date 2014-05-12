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

// Multipart.as
// John Maloney, August 2013
//
// Multi-part MIME form creator.

package util {
	import flash.utils.ByteArray;

public class Multipart {

	public var separator:String;

	private const crlf:String = '\r\n';
	private var parts:Array = []; // list of name-value-type triples
	
	public function Multipart() {
		separator = generateSeparator();
	}

	public function addPart(name:String, value:*, type:String = null):void {
		if (!type) type = '';
		parts.push([name, value, type]);
	}

	public function formData():ByteArray {
		var result:ByteArray = new ByteArray();
		var s:String;
		for (var i:int = 0; i < parts.length; i++) {
			var name:String = parts[i][0];
			var value:* = parts[i][1];
			var type:* = parts[i][2];
			if ('' == type) {
				s = '--' + separator + crlf;
				s += 'Content-Disposition: form-data; name="' + name + '"' + crlf + crlf;
				s += value.toString() + crlf;
				result.writeUTFBytes(s);
			} else {
				s = '--' + separator + crlf;
				s += 'Content-Disposition: form-data; name="' + name + '"; filename="' + name + '"' + crlf;
				s += 'Content-Type: ' + type + crlf + crlf;
				result.writeUTFBytes(s);
				result.writeBytes(value);
				result.writeUTFBytes(crlf);
			}
		}
		result.writeUTFBytes('--' + separator + '--' + crlf);
		return result;
	}

	private function generateSeparator():String {
		// Create a randomized part separator.
		const chars:String = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
		var result:String = '-----';
		for (var i:int = 0; i < 15; i++) {
			var rand:int = Math.floor(Math.random() * chars.length);
			result += chars.charAt(rand);
		}
		return result;
	}

}}