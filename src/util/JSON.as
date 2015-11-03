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

// JSON.as
// John Maloney, September 2010
//
// Convert between objects and their JSON string representation.
// Usage:
//	var s:String, obj:Object;
//	s = JSON.stringify(obj)
//  obj = JSON.parse(s)

package util {
	import flash.display.BitmapData;
	import flash.utils.*;

public class JSON {

	private var src:ReadStream;
	private var buf:String = "";
	private var tabs:String = "";
	private var needsComma:Boolean = false;
	private var doFormatting:Boolean;

	public static function stringify(obj:*, doFormatting:Boolean = true):String {
		// Return the JSON string representation for the given object.
		var json:util.JSON = new util.JSON();
		json.doFormatting = doFormatting;
		json.write(obj);
		return json.buf;
	}

	public static function parse(s:String):Object {
		// Parse the JSON string and return the resulting object.
		var json:util.JSON = new util.JSON();
		json.buf = s;
		json.src = new ReadStream(s);
		return json.readValue();
	}

	public static function escapeForJS(s:String):String {
		var ch:String, result:String = '';
		for (var i:int; i < s.length; i++) {
			result += (ch = s.charAt(i));
			if ('\\' == ch) result += '\\';
		}
		return result;
	}

	//----------------------------
	// JSON to string support
	//----------------------------

	private function readValue():Object {
		skipWhiteSpaceAndComments();
		var ch:String = src.peek();
		if (("0" <= ch) && (ch <= "9")) return readNumber(); // common case

		switch(ch) {
		case '"': return readString();
		case "[": return readArray();
		case "{": return readObject();
		case "t":
			if (src.nextString(4) == "true") return true;
			else error("Expected 'true'");
		case "f":
			if (src.nextString(5) == "false") return false;
			else error("Expected 'false'");
		case "n":
			if (src.nextString(4) == "null") return null;
			else error("Expected 'null'");
		case "-":
			if (src.peekString(9) == "-Infinity") {
				src.skip(9);
				return Number.NEGATIVE_INFINITY;
			} else return readNumber();
		case "I":
			if (src.nextString(8) == "Infinity") return Number.POSITIVE_INFINITY;
			else error("Expected 'Infinity'");
		case "N":
			if (src.nextString(3) == "NaN") return NaN;
			else error("Expected 'NaN'");
		case "":
			error("Incomplete JSON data");
		default:
			error("Bad character: " + ch);
		}
		return null;
	}

	private function readArray():Array {
		var result:Array = [];
		src.skip(1); // skip "["
		while (true) {
			if (src.atEnd()) return error("Incomplete array");
			skipWhiteSpaceAndComments();
			if (src.peek() == "]") break;
			result.push(readValue());
			skipWhiteSpaceAndComments();
			if (src.peek() == ",") {
				src.skip(1);
				continue;
			}
			if (src.peek() == "]") break;
			else error("Bad array syntax");
		}
		src.skip(1); // skip "]"
		return result;
	}

	private function readObject():Object {
		var result:Object = {};
		src.skip(1); // skip "{"
		while (true) {
			if (src.atEnd()) return error("Incomplete object");
			skipWhiteSpaceAndComments();
			if (src.peek() == "}") break;
			if (src.peek() != '"') error("Bad object syntax");
			var key:String = readString();
			skipWhiteSpaceAndComments();
			if (src.next() != ":") error("Bad object syntax");
			skipWhiteSpaceAndComments();
			var value:Object = readValue();
			result[key] = value;
			skipWhiteSpaceAndComments();
			if (src.peek() == ",") {
				src.skip(1);
				continue;
			}
			if (src.peek() == "}") break;
			else error("Bad object syntax");
		}
		src.skip(1); // skip "}"
		return result;
	}

	private function readNumber():Number {
		var numStr:String = "";
		var ch:String = src.peek();

		if ((ch == "0") && (src.peek2() == "x")) { // hex number
			numStr = src.nextString(2) + readHexDigits();
			return Number(numStr);
		}

		if (ch == "-") numStr += src.next();
		numStr += readDigits();
		if ((numStr == "") || (numStr == "-")) error("At least one digit expected");
		if (src.peek() == ".") numStr += src.next() + readDigits();
		ch = src.peek();
		if ((ch == "e") || (ch == "E")) {
			numStr += src.next();
			ch = src.peek();
			if ((ch == "+") || (ch == "-")) numStr += src.next();
			numStr += readDigits();
		}
		return Number(numStr);
	}

	private function readDigits():String {
		var result:String = "";
		while (true) {
			var ch:String = src.next();
			if (("0" <= ch) && (ch <= "9")) result += ch;
			else {
				if (ch != "") src.skip(-1);
				break;
			}
		}
		return result;
	}

	private function readHexDigits():String {
		var result:String = "";
		while (true) {
			var ch:String = src.next();
			if (("0" <= ch) && (ch <= "9")) result += ch;
			else if (("a" <= ch) && (ch <= "f")) result += ch;
			else if (("A" <= ch) && (ch <= "F")) result += ch;
			else {
				if (!src.atEnd()) src.skip(-1);
				break;
			}
		}
		return result;
	}

	private function readString():String {
		var result:String = "";
		src.skip(1); // skip opening quote
		var ch:String;
		while ((ch = src.next()) != '"') {
			if (ch == "") return error("Incomplete string");
			if (ch == "\\") result += readEscapedChar();
			else result += ch;
		}
		return result;
	}

	private function readEscapedChar():String {
		var ch:String = src.next();
		switch(ch) {
		case "b": return "\b";
		case "f": return "\f";
		case "n": return "\n";
		case "r": return "\r";
		case "t": return "\t";
		case "u": return String.fromCharCode(int("0x" + src.nextString(4)));
		}
		return ch;
	}

	private function skipWhiteSpaceAndComments():void {
		while (true) {
			// skip comments and white space until the stream position does not change
			var lastPos:int = src.pos();
			src.skipWhiteSpace();
			skipComment();
			if (src.pos() == lastPos) break; // done
		}
	}

	private function skipComment():void {
		var ch:String;
		if ((src.peek() == "/") && (src.peek2() == "/")) {
			src.skip(2);
			while ((ch = src.next()) != "\n") { // comments goes until the end of the line
				if (ch == "") return; // end of stream
			}
		}
		if ((src.peek() == "/") && (src.peek2() == "*")) {
			src.skip(2);
			var lastWasAsterisk:Boolean = false;
			while (true) {
				ch = src.next();
				if (ch == "") return; // end of stream
				if (lastWasAsterisk && (ch == "/")) return; // end of comment
				if (ch == "*") lastWasAsterisk = true;
			}
		}
	}

	private function error(msg:String):* {
		throw new Error(msg + " [pos=" + src.pos()) + "] in " + buf;
	}

	//----------------------------
	// Object to JSON support
	//----------------------------

	public function writeKeyValue(key:String, value:*):void {
		// This method is called by custom writeJSON() methods.
		if (needsComma) buf += doFormatting ? ",\n" : ", ";
		buf += tabs + '"' + key + '": ';
		write(value);
		needsComma = true;
	}

	private function write(value:*):void {
		// Write a value in JSON format. The argument of the top-level call is usually an object or array.
		if (value is Number) buf += isFinite(value) ? value : '0';
		else if (value is Boolean) buf += value;
		else if (value is String) buf += '"' + encodeString(value) + '"';
		else if (value is ByteArray) buf += '"' + encodeString(value.toString()) + '"';
		else if (value == null) buf += "null";
		else if (value is Array) writeArray(value);
		else if (value is BitmapData) buf += "null"; // bitmaps sometimes appear in old project info objects
		else writeObject(value);
	}

	private function writeObject(obj:*):void {
		var savedNeedsComma:Boolean = needsComma;
		needsComma = false;
		buf += "{";
		if (doFormatting) buf += "\n";
		indent();
		if (isClass(obj, 'Object') || isClass(obj, 'Dictonary')) {
			for (var k:String in obj) writeKeyValue(k, obj[k]);
		} else {
			obj.writeJSON(this);
		}
		if (doFormatting && needsComma) buf += '\n';
		outdent();
		buf += tabs + "}";
		needsComma = savedNeedsComma;
	}

	private function isClass(obj:*, className:String):Boolean {
		var fullName:String = getQualifiedClassName(obj);
		var i:int = fullName.lastIndexOf(className);
		return i == (fullName.length - className.length);
	}

	private function writeArray(a:Array):void {
		var separator:String = ", ";
		var indented:Boolean = doFormatting && ((a.length > 13) || needsMultipleLines(a, 13));
		buf += "[";
		indent();
		if (indented) separator = ",\n" + tabs;
		for (var i:int = 0; i < a.length; i++) {
			write(a[i]);
			if (i < (a.length - 1)) buf += separator;
		}
		outdent();
		buf += "]";
	}

	private function needsMultipleLines(arrayValue:Array, limit:int):Boolean {
		// Return true if this array is short enough to fit on one line.
		// (This is simply to make the JSON representation of stacks more readable.)
		var i:int, count:int;
		var toDo:Array = [arrayValue];
		while (toDo.length > 0) {
			var a:Array = toDo.pop();
			count += a.length;
			if (count > limit) return true;
			for (i = 0; i < a.length; i++) {
				var item:* = a[i];
				if ((item is Number) || (item is Boolean) || (item is String) || (item == null)) continue; // atomic value
				if (item is Array) toDo.push(item);
				else return true; // object with fields
			}
		}
		return false;
	}

	private function encodeString(s:String):String {
		var result:String = "";
		for (var i:int = 0; i < s.length; i++) {
			var ch:String = s.charAt(i);
			var code:int = s.charCodeAt(i);
			if (code < 32) {
				if (code == 9) result += "\\t";
				else if (code == 10) result += "\\n";
				else if (code == 13) result += "\\r";
				else {
					var hex:String = code.toString(16);
					while (hex.length < 4) hex = '0' + hex;
					result += '\\u' + hex;
				}
				continue;
			} else if (ch == "\\") result += "\\\\";
			else if (ch == '"') result += '\\"';
			else if (ch == "/") result += "\\/";
			else result += ch;
		}
		return result;
	}

	private function indent():void { if (doFormatting) tabs += "\t" }

	private function outdent():void {
		if (tabs.length == 0) return;
		tabs = tabs.slice(0, tabs.length - 1);
	}

}}
