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

package translation {
	import flash.events.Event;
	import flash.net.*;
	import flash.utils.ByteArray;
	import blocks.Block;
	import uiwidgets.Menu;
	import util.*;

public class Translator {

	public static var languages:Array = []; // contains pairs: [<language code>, <utf8 language name>]
	public static var currentLang:String = 'en';

	public static var rightToLeft:Boolean;
	public static var rightToLeftMath:Boolean; // true only for Arabic

	private static const font12:Array = ['fa', 'he','ja','ja_HIRA', 'zh_CN'];
	private static const font13:Array = ['ar'];

	private static var dictionary:Object = new Object();
	private static var isEnglish:Boolean = true;

	public static function initializeLanguageList():void {
		// Get a list of language names for the languages menu from the server.
		function saveLanguageList(data:String):void {
			if (!data) return;
			for each (var line:String in data.split('\n')) {
				var fields:Array = line.split(',');
				if (fields.length >= 2) {
					languages.push([trimWhitespace(fields[0]), trimWhitespace(fields[1])]);
				}
			}
		}
		languages = [['en', 'English']]; // English is always the first entry
		Scratch.app.server.getLanguageList(saveLanguageList);
	}

	public static function setLanguage(lang:String):void {
		function gotPOFile(data:ByteArray):void {
			if (data) {
				dictionary = parsePOData(data);
				checkBlockTranslations();
				setFontsFor(lang);
			}
			Scratch.app.translationChanged();
		}
		if ('import translation file' == lang) { importTranslationFromFile(); return; }
		if ('set font size' == lang) { fontSizeMenu(); return; }

		dictionary = new Object(); // default to English (empty dictionary) if there's no .po file
		isEnglish = true;
		setFontsFor('en');
		if ('en' == lang) Scratch.app.translationChanged(); // there is no .po file English
		else Scratch.app.server.getPOFile(lang, gotPOFile);

		Scratch.app.server.setSelectedLang(lang);
	}

	public static function importTranslationFromFile():void {
		function fileSelected(e:Event):void {
			var file:FileReference = FileReference(files.fileList[0]);
			var i:int = file.name.lastIndexOf('.');
			langName = file.name.slice(0, i);
			file.addEventListener(Event.COMPLETE, fileLoaded);
			file.load();
		}
		function fileLoaded(e:Event):void {
			var data:ByteArray = FileReference(e.target).data;
			if (data) {
				dictionary = new Object(); // default to English
				dictionary = parsePOData(data);
				setFontsFor(langName);
				checkBlockTranslations();
				Scratch.app.translationChanged();
			}
		}
		var langName:String;
		var files:FileReferenceList = new FileReferenceList();
		files.addEventListener(Event.SELECT, fileSelected);
		try {
			// Ignore the exception that happens when you call browse() with the file browser open
			files.browse();
		} catch(e:*) {}
	}

	private static function fontSizeMenu():void {
		function setFontSize(labelSize:int):void {
			var argSize:int = Math.round(0.9 * labelSize);
			var vOffset:int = labelSize > 13 ? 1 : 0;
			Block.setFonts(labelSize, argSize, false, vOffset);
			Scratch.app.translationChanged();
		}
		var m:Menu = new Menu(setFontSize);
		for (var i:int = 8; i < 25; i++) m.addItem(i.toString(), i);
		m.showOnStage(Scratch.app.stage);
	}

	private static function setFontsFor(lang:String):void {
		// Set the rightToLeft flag and font sizes the given language.

		currentLang = lang;
		isEnglish = (lang == 'en');

		const rtlLanguages:Array = ['ar', 'fa', 'he'];
		rightToLeft = rtlLanguages.indexOf(lang) > -1;
		rightToLeftMath = ('ar' == lang);
		Block.setFonts(10, 9, true, 0); // default font settings
		if (font12.indexOf(lang) > -1) Block.setFonts(11, 10, false, 0);
		if (font13.indexOf(lang) > -1) Block.setFonts(13, 12, false, 0);
	}

	public static function map(s:String):String {
//return TranslatableStrings.has(s) ? s.toUpperCase() : s;
//return (s.indexOf('%') > -1) ? s : s.toUpperCase(); // xxx testing only
		var result:* = dictionary[s];
//if (!isEnglish && (s.indexOf('%') == -1)) return s.toUpperCase(); // xxx for testing only; comment out before pushing!
		if ((result == null) || (result.length == 0)) return s;
		return result;
	}

	private static function parsePOData(bytes:ByteArray):Object {
		// Parse the given data in gettext .po file format.
		skipBOM(bytes);
		var lines:Array = [];
		while (bytes.bytesAvailable > 0) {
			var s:String = trimWhitespace(nextLine(bytes));
			if ((s.length > 0) && (s.charAt(0) != '#')) lines.push(s);
		}
		return makeDictionary(lines);
	}

	private static function skipBOM(bytes:ByteArray):void {
		// Some .po files begin with a three-byte UTF-8 Byte Order Mark (BOM).
		// Skip this BOM if it exists, otherwise do nothing.
		if (bytes.bytesAvailable < 3) return;
		var b1:int = bytes.readUnsignedByte();
		var b2:int = bytes.readUnsignedByte();
		var b3:int = bytes.readUnsignedByte();
		if ((b1 == 0xEF) && (b2 == 0xBB) && (b3 == 0xBF)) return; // found BOM
		bytes.position = bytes.position - 3; // BOM not found; back up
	}

	private static function trimWhitespace(s:String):String {
		// Remove leading and trailing whitespace characters.
		if (s.length == 0) return ''; // empty
		var i:int = 0;
		while ((i < s.length) && (s.charCodeAt(i) <= 32)) i++;
		if (i == s.length) return ''; // all whitespace
		var j:int = s.length - 1;
		while ((j > i) && (s.charCodeAt(j) <= 32)) j--;
		return s.slice(i, j + 1);
	}

	private static function nextLine(bytes:ByteArray):String {
		// Read the next line from the given ByteArray. A line ends with CR, LF, or CR-LF.
		var buf:ByteArray = new ByteArray();
		while (bytes.bytesAvailable > 0) {
			var byte:int = bytes.readUnsignedByte();
			if (byte == 13) { // CR
				// line could end in CR or CR-LF
				if (bytes.readUnsignedByte() != 10) bytes.position--; // try to read LF, but backup if not LF
				break;
			}
			if (byte == 10) break; // LF
			buf.writeByte(byte); // append anything else
		}
		buf.position = 0;
		return buf.readUTFBytes(buf.length);
	}

	private static function makeDictionary(lines:Array):Object {
		// Return a dictionary mapping original strings to their translations.
		var dict:Object = new Object();
		var mode:String = 'none'; // none, key, val
		var key:String = '';
		var val:String = '';
		for each (var line:String in lines) {
			if ((line.length >= 5) && (line.slice(0, 5).toLowerCase() == 'msgid')) {
				if (mode == 'val') dict[key] = val; // recordPairIn(key, val, dict);
				mode = 'key';
				key = '';
			} else if ((line.length >= 6) && (line.slice(0, 6).toLowerCase() == 'msgstr')) {
				mode = 'val';
				val = '';
			}
			if (mode == 'key') key += extractQuotedString(line);
			if (mode == 'val') val += extractQuotedString(line);
		}
		if (mode == 'val') dict[key] = val; // recordPairIn(key, val, dict);
		return dict;
	}

	private static function extractQuotedString(s:String):String {
		// Remove leading and trailing whitespace characters.
		var i:int = s.indexOf('"'); // find first double-quote
		if (i < 0) i = s.indexOf(' '); // if no double-quote, start after first space
		var result:String = '';
		for (i = i + 1; i < s.length; i++) {
			var ch:String = s.charAt(i);
			if ((ch == '\\') && (i < (s.length - 1))) {
				ch = s.charAt(++i);
				if (ch == 'n') ch = '\n';
				if (ch == 'r') ch = '\r';
				if (ch == 't') ch = '\t';
			}
			if (ch == '"') return result; // closing double-quote
			result += ch;
		}
		return result;
	}

	private static function recordPairIn(key:String, val:String, dict:Object):void {
		// Handle some special cases where block specs changed for Scratch 2.0.
		// Note: No longer needed now that translators are starting with current block specs.
		switch (key) {
		case '%a of %m':
			val = val.replace('%a', '%m.attribute');
			val = val.replace('%m', '%m.sprite');
			dict['%m.attribute of %m.sprite'] = val;
			break;
		case 'stop all':
			dict['@stop stop all'] = '@stop ' + val;
			break;
		case 'touching %m?':
			dict['touching %m.touching?'] = val.replace('%m', '%m.touching');
			break;
		case 'turn %n degrees':
			dict['turn @turnRight %n degrees'] = val.replace('%n', '@turnRight %n');
			dict['turn @turnLeft %n degrees'] = val.replace('%n', '@turnLeft %n');
			break;
		case 'when %m clicked':
			dict['when @greenFlag clicked'] = val.replace('%m', '@greenFlag');
			dict['when I am clicked'] = val.replace('%m', 'I am');
			break;
		default:
			dict[key] = val;
		}
	}

	private static function checkBlockTranslations():void {
		for each (var entry:Array in Specs.commands) checkBlockSpec(entry[0]);
	}

	private static function checkBlockSpec(spec:String):void {
		var translatedSpec:String = map(spec);
		if (translatedSpec == spec) return; // not translated
		var origArgs:Array = extractArgs(spec);
		if (!argsMatch(extractArgs(spec), extractArgs(translatedSpec))) {
			Scratch.app.log('Block argument mismatch:');
			Scratch.app.log('    ' + spec);
			Scratch.app.log('    ' + translatedSpec);
			delete dictionary[spec]; // remove broken entry from dictionary
		}
	}

	private static function argsMatch(args1:Array, args2:Array):Boolean {
		if (args1.length != args2.length) return false;
		for (var i:int = 0; i < args1.length; i++) {
			if (args1[i] != args2[i]) return false;
		}
		return true;
	}

	private static function extractArgs(spec:String):Array {
		var result:Array = [];
		var tokens:Array = ReadStream.tokenize(spec);
		for each (var s:String in tokens) {
			if ((s.length > 1) && ((s.charAt(0) == '%') || (s.charAt(0) == '@'))) result.push(s);
		}
		return result;
	}

}}
