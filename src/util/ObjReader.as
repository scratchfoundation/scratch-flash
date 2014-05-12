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

// ObjReader.as
// John Maloney, May 2010.
// First version ported from Java by Nick Bushak.
//
//	A reader for the serialized object format used to store Scratch projects (.sb file format).
//
//	The result of readObjTable() is a table of objects. There are three
//	kinds of object records, determined by the 8-bit classID at the
//	start of the record:
//		a. fixed-format class records (<classID><...data...>), Class ID's 0 to 98
//		b. an object reference (an object table index to the target object), ClassID = 99
//		c. user-class records (<classID><class version #>[<field>]*), ClassID's 100-255
//
//	The process of reading in the object table is:
//		a. read all objects
//		b. build image and sound objects
//		c. instantiate stage, sprite, costume, sound, and watcher objects
//		d. dereference object references (Ref objects) in the fields list of
//		   user-classes and in fixed-format collection objects.
//		e. initalize variable and list watchers
//		f. initialize costumes and sounds
//
//	Typically, the client calls readObjTable(), then scans the processed object table to
//	extract the stage, sprites, and watchers that constitute a Scratch project.

package util {
	import flash.display.BitmapData;
	import flash.errors.IOError;
	import flash.geom.Rectangle;
	import flash.utils.*;
	import blocks.BlockArg;
	import scratch.*;
	import sound.*;
	import watchers.*;

public class ObjReader {
	private const OBJ_REF:int = 99;

	private var s:IDataInput;
	private var objTable:Array = [];

	public function ObjReader(s:IDataInput) {
		this.s = s;
	}

	public static function isOldProject(data:ByteArray):Boolean {
		if (data.length < 10) return false;
		data.position = 0;
		var s:String = data.readUTFBytes(10);
		data.position = 0;
		return ('ScratchV01' == s) || ('ScratchV02' == s);
	}

	public function readInfo():Object {
		var id:String = this.s.readMultiByte(10, 'macintosh');
		if (id != 'ScratchV01' && id != 'ScratchV02') {
			throw new IOError('Not a valid Scratch file');
		}

		var infoBytes:int = s.readInt();
		readObjTable();

		// convert the array of names and values into a dictionary
		var infoDict:Object = new Object();
		var keysAndValues:Array = objTable[0][0];
		for (var i:int = 0; i < (keysAndValues.length - 1); i += 2) {
			infoDict[keysAndValues[i]] = keysAndValues[i + 1];
		}
		return infoDict;
	}

	public function readObjTable():Array {
		var buf:String;
		if (s.readMultiByte(4, 'macintosh') != 'ObjS' || s.readByte() != 1) {
			throw new IOError();
		}
		if (s.readMultiByte(4, 'macintosh') != 'Stch' || s.readByte() != 1) {
			throw new IOError();
		}

		objTable = [];
		var objCount:int = s.readInt();
		for (var i:int = 0; i < objCount; i++) {
			objTable[i] = readObj();
		}

		// post processing
		// Note: must decode images and instantiate objects before fixing references
		decodeSqueakImages();
		instantiateScratchObjects();
		fixReferences();
		initWatchers();
		initListWatchers();
		initCostumes();
		initSounds();
		return objTable;
	}

	private function readObj():Array {
		var result:Array = [];

		var classID:int = s.readUnsignedByte();
		if (classID < OBJ_REF) {
			result[0] = readFixedFormat(classID);
			result[1] = classID;
		} else {
			var classVersion:int = s.readUnsignedByte();
			var fieldCount:int = s.readUnsignedByte();
			result[0] = null; // placeholder for resulting object
			result[1] = classID;
			result[2] = classVersion;
			for (var i:int = 3; i < 3 + fieldCount; i++) {
				result[i] = readField();
			}
		}
		return result;
	}

	private function readField():Object {
		var classID:int = s.readUnsignedByte();
		if (classID == OBJ_REF) {
			var i:int = s.readUnsignedByte() << 16;
			i += s.readUnsignedByte() << 8;
			i += s.readUnsignedByte();
			return new Ref(i);
		}
		return readFixedFormat(classID);
	}

	private function readFixedFormat(classID:int):Object {
		var count:int, i:int;
		var bytes:ByteArray = new ByteArray();
		var objList:Array;

		switch (classID) {
		case 1:
			return null;
		case 2:
			return true;
		case 3:
			return false;
		case 4:
			return s.readInt();
		case 5:
			return s.readShort();
		case 6:
		case 7:
			var num:Number = 0.0;
			var multiplier:Number = 1.0;
			count = s.readShort();
			for (i = 0; i < count; i++) {
				num += multiplier * s.readUnsignedByte();
				multiplier *= 256.0;
			}
			return num;
		case 8:
			num = s.readDouble();
			if (num is int) num += BlockArg.epsilon; // ensure result is a float, even if it has no fractional part
			return num;
		case 9:
		case 10:
			count = s.readInt();
			return s.readMultiByte(count, 'macintosh');
		case 11:
			count = s.readInt();
			if (count > 0) s.readBytes(bytes, 0, count);
			return bytes;
		case 12:
			count = s.readInt();
			if (count > 0) s.readBytes(bytes, 0, 2 * count);
			return bytes;
		case 13: // bitmap
			count = s.readInt();
			objList = new Array(count);
			for (i = 0; i < count; i++) {
				objList[i] = s.readUnsignedInt();
			}
			return objList;
		case 14: // UTF8
			count = s.readInt();
			return s.readMultiByte(count, 'utf-8');
		case 20:
		case 21:
		case 22:
		case 23: // array
			count = s.readInt();
			objList = new Array(count);
			for (i = 0; i < count; i++) {
				objList[i] = readField();
			}
			return objList;
		case 24:
		case 25: // dictionary
			count = s.readInt();
			objList = new Array(2 * count);
			for (i = 0; i < 2 * count; i++) {
				objList[i] = readField();
			}
			return objList;
		case 30:
		case 31: // color
			var rgb:int = s.readInt();
			var alpha:int = (classID == 31) ? s.readUnsignedByte() : 0xFF;
			var r:int = (rgb >> 22) & 0xFF;
			var g:int = (rgb >> 12) & 0xFF;
			var b:int = (rgb >>  2) & 0xFF;
			return (alpha << 24) | (r << 16) | (g << 8) | b;
		case 32: // point
			objList = new Array(2);
			objList[0] = readField();
			objList[1] = readField();
			return objList;
		case 33: // rectangle
			objList = new Array(4);
			objList[0] = readField();
			objList[1] = readField();
			objList[2] = readField();
			objList[3] = readField();
			return objList;
		case 34:
		case 35: // Squeak image
			var fields:Array = new Array();
			for (i = 0; i < 5; i++) {
				fields[i] = readField();
			}
			if (classID == 35) fields[5] = readField(); // colormap
			return fields;
		default:
			throw new IOError('Unknown fixed-format class ' + classID);
		}
	}

	private function instantiateScratchObjects():void {
		for (var i:int = 0; i < objTable.length; i++) {
			var classID:int = objTable[i][1];
			if (classID == 124) objTable[i][0] = new ScratchSprite();
			if (classID == 125) objTable[i][0] = new ScratchStage();
			if (classID == 155) objTable[i][0] = new Watcher();
			if (classID == 162) objTable[i][0] = new ScratchCostume('uninitialized', null);
			if (classID == 164) objTable[i][0] = new ScratchSound('uninitialized', null);
			if (classID == 175) objTable[i][0] = new ListWatcher();
		}
	}

	private function decodeSqueakImages():void {
		for (var i:int = 0; i < objTable.length; i++) {
			var classID:int = objTable[i][1];
			if ((classID == 34) || (classID == 35)) { // Squeak Form and ColorForm images
				var fields:Array = objTable[i][0];
				var w:int		= fields[0];
				var h:int		= fields[1];
				var depth:int	= fields[2];

				var rect:Rectangle = new Rectangle(0, 0, w, h);
				var raster:Vector.<uint> = decodePixels(objTable[fields[4].index][0], (depth == 32));
				var bmpData:BitmapData = new BitmapData(w, h);

				if (depth <= 8) {
					var colormap:Vector.<uint> = (depth == 1) ? defaultOneBitColorMap : defaultColorMap;
					if (fields[5] != null) {
						var colors:Array = objTable[fields[5].index][0];
						colormap = buildCustomColormap(depth, colors);
					}
					bmpData.setVector(rect, unpackPixels(raster, w, h, depth, colormap));
				}
				if (depth == 16) {
					bmpData.setVector(rect, raster16to32(raster, w, h));
				}
				if (depth == 32) {
					bmpData.setVector(rect, raster);
				}
				objTable[i][0] = bmpData;
			}
		}
	}

	private function fixReferences():void {
		for (var i:int = 0; i < objTable.length; i++) {
			var classID:int = objTable[i][1];
			var j:int, el:*;

			if ((classID >= 20) && (classID <= 29)) { // process collection elements
				var list:Array = objTable[i][0];
				for (j = 0; j < list.length; j++) {
					el = list[j];
					if (el is Ref) list[j] = deRef(el);
				}
			}
			if (classID > OBJ_REF) { // process fields of a user-defined object
				for (j = 3; j < objTable[i].length; j++) {
					el = objTable[i][j];
					if (el is Ref) objTable[i][j] = deRef(el);
				}
			}
		}
	}

	private function deRef(r:*):Object {
		var entry:Array = objTable[Ref(r).index];
		return (entry[0] == null) ? entry : entry[0];
	}

	private function initCostumes():void {
		// convert ImageMedia objects to ScratchCostume objects
		for each (var entry:Array in objTable) {
			if (entry[1] == 162) { // ImageMedia
				var costume:ScratchCostume = entry[0];
				costume.costumeName = entry[3];
				costume.bitmap = entry[4];
				costume.rotationCenterX = entry[5][0];
				costume.rotationCenterY = entry[5][1];
				var textDetails:Array = entry[6];
				if ((textDetails != null) && (textDetails.length >= 15)) {
					var lines:Array = textDetails[14];
					costume.text = '';
					for (var i:int = 0; i < lines.length; i++) costume.text += lines[i];
					var r:Array = textDetails[3];
					costume.textRect = new Rectangle(r[0], r[1], r[2], r[3]);
					costume.textColor = textDetails[12];
					costume.fontName = textDetails[11][0];
					costume.fontSize = textDetails[11][1];
				}
				if (entry[7] != null) {
					costume.baseLayerData = entry[7]; // JPEG data
					costume.bitmap = null;
				} else {
					costume.baseLayerBitmap = costume.bitmap;
				}
				if (entry[8] != null) costume.bitmap = costume.oldComposite = entry[8];
			}
		}
	}

	private function initWatchers():void {
		for each (var entry:Array in objTable) {
			if (entry[1] == 155) { // Watcher
				var w:Watcher = entry[0];
				var version:int = entry[2];
				var box:Array = entry[3];
				var title:Array = entry[16];
				var readout:Array = entry[17];
				var readoutFrame:Array = entry[18];
				var readoutValue:* = readout[11];
				var target:* = readout[13];
				var cmd:String = readout[14];
				var param:String = readout[16];
				var color:int = readoutFrame[6];
				w.initWatcher(target, cmd, param, color);
				w.x = box[0];
				w.y = box[1];
				// set slider range:
				if (version > 3) {
					w.setSliderMinMax(entry[23], entry[24], readoutValue);
				}
				// set the mode:
				var slider:* = entry[19];
				var readoutBox:Array = readoutFrame[3];
				var mode:int;
				if (slider == null) {
					mode = ((readoutBox [3] - readoutBox[1]) <= 14) ? 1 : 2;
				} else {
					mode = 3;
				}
				w.setMode(mode);
			}
		}
	}

	private function initListWatchers():void {
		for each (var entry:Array in objTable) {
			if (entry[1] == 175) { // ListWatcher
				var listWatcher:ListWatcher = entry[0];
				var box:Array = entry[3];
				if (entry[4] == null) {
					listWatcher.x = listWatcher.y = 5; // watcher is hidden; use arbitrary position
				} else {
					listWatcher.x = box[0] + 1;
					listWatcher.y = box[1] + 1;
				}
				listWatcher.setWidthHeight(box[2] - box[0] - 2, box[3] - box[1] - 2);
				listWatcher.listName = entry[11];
				listWatcher.contents = entry[12];
				listWatcher.target = entry[13];
			}
		}
	}

	private function initSounds():void {
		// Convert SoundMedia objects to ScratchSound objects.
		// To speed up reading old Scratch projects, compressed sounds
		// are kept in Squeak format until the project is saved.
		var cache:Dictionary = new Dictionary(); // used to avoid converting multiple identical copies of a sound to WAV
		var sndData:ByteArray;
		for each (var entry:Array in objTable) {
			if (entry[1] == 164) { // SoundMedia
				var snd:ScratchSound = entry[0];
				snd.soundName = entry[3];

				if (entry[9] == null) {
					var uncompressedSound:Array = entry[4];
					sndData = uncompressedSound[6];
					snd.format = '';
					snd.rate = uncompressedSound[7];
					snd.bitsPerSample = 16;
					snd.sampleCount = sndData.length / 2;
					if (cache[sndData] != null) {
						snd.soundData = cache[sndData]; // use cached sound data
					} else {
						snd.soundData = WAVFile.encode(reverseBytes(sndData), snd.sampleCount, snd.rate, false);
						cache[sndData] = snd.soundData;
					}
				} else {
					sndData = entry[9];
					snd.format = 'squeak';
					snd.rate = entry[7];
					snd.bitsPerSample = entry[8];
					snd.sampleCount = Math.floor((8 * sndData.length) / snd.bitsPerSample);
					snd.soundData = sndData;
				}
			}
		}
	}

	private function reverseBytes(orig:ByteArray):ByteArray {
		var out:ByteArray = new ByteArray();
		var end:int = orig.length - 1;
		for (var i:int = 0; i < end; i += 2) {
			out.writeByte(orig[i + 1]);
			out.writeByte(orig[i]);
		}
		out.endian = Endian.LITTLE_ENDIAN;
		return out;
	}

	private function decodePixels(data:Object, addAlpha:Boolean):Vector.<uint> {
		var result:Vector.<uint>, i:int, w:uint;
		if (data is Array) {
			result = Vector.<uint>(data); // already an array (uncompressed pixel data)
			if (addAlpha) {
				for (i = 0; i < result.length; i++) {
					if ((w = result[i]) != 0) result[i] = 0xFF000000 | w;
				}
			}
			return result;
		}

		var s:ByteArray = ByteArray(data);
		var n:uint = decodeInt(s);
		result = new Vector.<uint>(n);
		i = 0;
		while ((s.bytesAvailable > 0) && (i < n)) {
			var runLengthAndCode:uint = decodeInt(s);
			var runLength:int = runLengthAndCode >> 2;
			var code:int = runLengthAndCode & 3;
			switch (code) {
			case 0:
				i += runLength;
				break;
			case 1:
				w = s.readUnsignedByte();
				w = (w << 24) | (w << 16) | (w << 8) | w;
				if (addAlpha && (w != 0)) w |= 0xFF000000;
				for (var j:int = 0; j < runLength; j++) result[i++] = w;
				break;
			case 2:
				w = s.readInt();
				if (addAlpha && (w != 0)) w |= 0xFF000000;
				for (j = 0; j < runLength; j++) result[i++] = w;
				break;
			case 3:
				for (j = 0; j < runLength; j++) {
					w = (s.readUnsignedByte()) << 24;
					w |= (s.readUnsignedByte()) << 16;
					w |= (s.readUnsignedByte()) << 8;
					w |= s.readUnsignedByte();
					if (addAlpha && (w != 0)) w |= 0xFF000000;
					result[i++] = w;
				}
				break;
			}
		}
		return result;
	}

	private function decodeInt(s:ByteArray):uint {
		// Decode an integer as follows...
		//	 0-223		0-223
		//	 224-254	(0-30)*256 + next byte (0-7935)
		//	 255		next 4 bytes as big-endian integer
		var count:int = s.readUnsignedByte();
		if (count <= 223) return count;
		if (count <= 254) return ((count - 224) * 256) + (s.readUnsignedByte());
		return s.readUnsignedInt();
	}

	private function unpackPixels(words:Vector.<uint>, w:int, h:int, depth:int, colormap:Vector.<uint>):Vector.<uint> {
		var result:Vector.<uint> = new Vector.<uint>(w * h);
		var span:int = words.length / h;
		var mask:int = (1 << depth) - 1;
		var pixels_per_word:int = 32 / depth;
		var dst:int = 0;

		for (var y:int = 0; y < h; y++) {
			var src:int = y * span;
			var word:uint, shift:int = -1;
			for (var x:int = 0; x < w; x++) {
				if (shift < 0) {
					shift = depth * (pixels_per_word - 1);
					word = words[src++];
				}
				result[dst++] = colormap[(word >> shift) & mask];
				shift -= depth;
			}
		}
		return result;
	}

	private function raster16to32(raster16:Vector.<uint>, w:int, h:int):Vector.<uint> {
		var result:Vector.<uint> = new Vector.<uint>(2 * raster16.length);
		var shift:int, word:uint, pix:int;
		var src:int, dst:int;
		for (var y:int = 0; y < h; y++) {
			shift = -1;
			for (var x:int = 0; x < w; x++) {
				if (shift < 0) {
					shift = 16;
					word = raster16[src++];
				}
				pix = (word >> shift) & 0xFFFF;
				if (pix != 0) {
					var r:int = (pix >> 7) & 0xF8;
					var g:int = (pix >> 2) & 0xF8;
					var b:int = (pix << 3) & 0xF8;
					pix = 0xFF000000 | (r << 16) | (g << 8) | b;
				}
				result[dst++] = pix;
				shift -= 16;
			}
		}
		return result;
	}

	private function buildCustomColormap(depth:int, colors:Array):Vector.<uint> {
		// a colormap is an array of ARGB ints
		var result:Vector.<uint> = new Vector.<uint>(1 << depth);
		for (var i:int = 0; i < colors.length; i++) {
			result[i] = objTable[colors[i].index][0];
		}
		return result;
	}

	private const defaultOneBitColorMap:Vector.<uint> = Vector.<uint>([0xFFFFFFFF, 0xFF000000]); // 0 -> white, 1 -> black

	private const defaultColorMap:Vector.<uint> = Vector.<uint>([
		0x00000000, 0xFF000000, 0xFFFFFFFF, 0xFF808080, 0xFFFF0000, 0xFF00FF00, 0xFF0000FF, 0xFF00FFFF,
		0xFFFFFF00, 0xFFFF00FF, 0xFF202020, 0xFF404040, 0xFF606060, 0xFF9F9F9F, 0xFFBFBFBF, 0xFFDFDFDF,
		0xFF080808, 0xFF101010, 0xFF181818, 0xFF282828, 0xFF303030, 0xFF383838, 0xFF484848, 0xFF505050,
		0xFF585858, 0xFF686868, 0xFF707070, 0xFF787878, 0xFF878787, 0xFF8F8F8F, 0xFF979797, 0xFFA7A7A7,
		0xFFAFAFAF, 0xFFB7B7B7, 0xFFC7C7C7, 0xFFCFCFCF, 0xFFD7D7D7, 0xFFE7E7E7, 0xFFEFEFEF, 0xFFF7F7F7,
		0xFF000000, 0xFF003300, 0xFF006600, 0xFF009900, 0xFF00CC00, 0xFF00FF00, 0xFF000033, 0xFF003333,
		0xFF006633, 0xFF009933, 0xFF00CC33, 0xFF00FF33, 0xFF000066, 0xFF003366, 0xFF006666, 0xFF009966,
		0xFF00CC66, 0xFF00FF66, 0xFF000099, 0xFF003399, 0xFF006699, 0xFF009999, 0xFF00CC99, 0xFF00FF99,
		0xFF0000CC, 0xFF0033CC, 0xFF0066CC, 0xFF0099CC, 0xFF00CCCC, 0xFF00FFCC, 0xFF0000FF, 0xFF0033FF,
		0xFF0066FF, 0xFF0099FF, 0xFF00CCFF, 0xFF00FFFF, 0xFF330000, 0xFF333300, 0xFF336600, 0xFF339900,
		0xFF33CC00, 0xFF33FF00, 0xFF330033, 0xFF333333, 0xFF336633, 0xFF339933, 0xFF33CC33, 0xFF33FF33,
		0xFF330066, 0xFF333366, 0xFF336666, 0xFF339966, 0xFF33CC66, 0xFF33FF66, 0xFF330099, 0xFF333399,
		0xFF336699, 0xFF339999, 0xFF33CC99, 0xFF33FF99, 0xFF3300CC, 0xFF3333CC, 0xFF3366CC, 0xFF3399CC,
		0xFF33CCCC, 0xFF33FFCC, 0xFF3300FF, 0xFF3333FF, 0xFF3366FF, 0xFF3399FF, 0xFF33CCFF, 0xFF33FFFF,
		0xFF660000, 0xFF663300, 0xFF666600, 0xFF669900, 0xFF66CC00, 0xFF66FF00, 0xFF660033, 0xFF663333,
		0xFF666633, 0xFF669933, 0xFF66CC33, 0xFF66FF33, 0xFF660066, 0xFF663366, 0xFF666666, 0xFF669966,
		0xFF66CC66, 0xFF66FF66, 0xFF660099, 0xFF663399, 0xFF666699, 0xFF669999, 0xFF66CC99, 0xFF66FF99,
		0xFF6600CC, 0xFF6633CC, 0xFF6666CC, 0xFF6699CC, 0xFF66CCCC, 0xFF66FFCC, 0xFF6600FF, 0xFF6633FF,
		0xFF6666FF, 0xFF6699FF, 0xFF66CCFF, 0xFF66FFFF, 0xFF990000, 0xFF993300, 0xFF996600, 0xFF999900,
		0xFF99CC00, 0xFF99FF00, 0xFF990033, 0xFF993333, 0xFF996633, 0xFF999933, 0xFF99CC33, 0xFF99FF33,
		0xFF990066, 0xFF993366, 0xFF996666, 0xFF999966, 0xFF99CC66, 0xFF99FF66, 0xFF990099, 0xFF993399,
		0xFF996699, 0xFF999999, 0xFF99CC99, 0xFF99FF99, 0xFF9900CC, 0xFF9933CC, 0xFF9966CC, 0xFF9999CC,
		0xFF99CCCC, 0xFF99FFCC, 0xFF9900FF, 0xFF9933FF, 0xFF9966FF, 0xFF9999FF, 0xFF99CCFF, 0xFF99FFFF,
		0xFFCC0000, 0xFFCC3300, 0xFFCC6600, 0xFFCC9900, 0xFFCCCC00, 0xFFCCFF00, 0xFFCC0033, 0xFFCC3333,
		0xFFCC6633, 0xFFCC9933, 0xFFCCCC33, 0xFFCCFF33, 0xFFCC0066, 0xFFCC3366, 0xFFCC6666, 0xFFCC9966,
		0xFFCCCC66, 0xFFCCFF66, 0xFFCC0099, 0xFFCC3399, 0xFFCC6699, 0xFFCC9999, 0xFFCCCC99, 0xFFCCFF99,
		0xFFCC00CC, 0xFFCC33CC, 0xFFCC66CC, 0xFFCC99CC, 0xFFCCCCCC, 0xFFCCFFCC, 0xFFCC00FF, 0xFFCC33FF,
		0xFFCC66FF, 0xFFCC99FF, 0xFFCCCCFF, 0xFFCCFFFF, 0xFFFF0000, 0xFFFF3300, 0xFFFF6600, 0xFFFF9900,
		0xFFFFCC00, 0xFFFFFF00, 0xFFFF0033, 0xFFFF3333, 0xFFFF6633, 0xFFFF9933, 0xFFFFCC33, 0xFFFFFF33,
		0xFFFF0066, 0xFFFF3366, 0xFFFF6666, 0xFFFF9966, 0xFFFFCC66, 0xFFFFFF66, 0xFFFF0099, 0xFFFF3399,
		0xFFFF6699, 0xFFFF9999, 0xFFFFCC99, 0xFFFFFF99, 0xFFFF00CC, 0xFFFF33CC, 0xFFFF66CC, 0xFFFF99CC,
		0xFFFFCCCC, 0xFFFFFFCC, 0xFFFF00FF, 0xFFFF33FF, 0xFFFF66FF, 0xFFFF99FF, 0xFFFFCCFF, 0xFFFFFFFF]);

	private function classIDToName(id:int):String {
		if (id == 9) return 'String';
		if (id == 10) return 'Symbol';
		if (id == 11) return 'ByteArray';
		if (id == 12) return 'SoundBuffer';
		if (id == 13) return 'Bitmap';
		if (id == 14) return 'UTF8';
		if (id == 20) return 'Array';
		if (id == 21) return 'OrderedCollection';
		if (id == 22) return 'Set';
		if (id == 23) return 'IdentitySet';
		if (id == 24) return 'Dictionary';
		if (id == 25) return 'IdentityDictionary';
		if (id == 30) return 'Color';
		if (id == 31) return 'ColorAlpha';
		if (id == 32) return 'Point';
		if (id == 33) return 'Rectangle';
		if (id == 34) return 'Form';
		if (id == 35) return 'ColorForm';
		if (id == 100) return 'Morph';
		if (id == 104) return 'Alignment';
		if (id == 105) return 'String';
		if (id == 106) return 'UpdatingString';
		if (id == 109) return 'SampledSound';
		if (id == 110) return 'ImageMorph';
		if (id == 124) return 'Sprite';
		if (id == 125) return 'Stage';
		if (id == 155) return 'Watcher';
		if (id == 162) return 'ImageMedia';
		if (id == 164) return 'SoundMedia';
		if (id == 171) return 'MultilineString';
		if (id == 173) return 'WatcherReadoutFrame';
		if (id == 174) return 'WatcherSlider';
		if (id == 175) return 'ListWatcher';
		return 'Unknown(' + id + ')';
	}

}}

class Ref {
	internal var index:int;
	function Ref(i:int) { index = i - 1 }
	internal function toString():String { return 'Ref(' + index + ')' }
}
