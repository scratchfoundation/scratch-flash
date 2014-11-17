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

// ListPrimitives.as
// John Maloney, September 2010
//
// List primitives.

package primitives {
	import blocks.Block;
	import interpreter.Interpreter;
	import flash.utils.Dictionary;
	import watchers.ListWatcher;
	import scratch.ScratchObj;

public class ListPrims {

	private var app:Scratch;
	protected var interp:Interpreter;

	public function ListPrims(app:Scratch, interpreter:Interpreter) {
		this.app = app;
		this.interp = interpreter;
	}

	public function addPrimsTo(primTable:Dictionary):void {
		primTable[Specs.GET_LIST]		= primContents;
		primTable['append:toList:']		= primAppend;
		primTable['deleteLine:ofList:']	= primDelete;
		primTable['insert:at:ofList:']	= primInsert;
		primTable['setLine:ofList:to:']	= primReplace;
		primTable['getLine:ofList:']	= primGetItem;
		primTable['lineCountOfList:']	= primLength;
		primTable['list:contains:']		= primContains;
	}

	private function primContents(b:Block):String {
		var list:ListWatcher = interp.targetObj().lookupOrCreateList(b.spec);
		if (!list) return '';
		var allSingleLetters:Boolean = true;
		for each (var el:* in list.contents) {
			if (!((el is String) && (el.length == 1))) {
				allSingleLetters = false;
				break;
			}
		}
		return (list.contents.join(allSingleLetters ? '' : ' '));
	}

	private function primAppend(b:Block):void {
		var list:ListWatcher = listarg(b, 1);
		if (!list) return;
		listAppend(list, interp.arg(b, 0));
		if (list.visible) list.updateWatcher(list.contents.length, false, interp);
	}

	protected function listAppend(list:ListWatcher, item:*):void {
		list.contents.push(item);
	}

	private function primDelete(b:Block):void {
		var which:* = interp.arg(b, 0);
		var list:ListWatcher = listarg(b, 1);
		if (!list) return;
		var len:int = list.contents.length;
		if (which == 'all') {
			listSet(list, []);
			if (list.visible) list.updateWatcher(-1, false, interp);
		}
		var n:Number = (which == 'last') ? len : Number(which);
		if (isNaN(n)) return;
		var i:int = Math.round(n);
		if ((i < 1) || (i > len)) return;
		listDelete(list, i);
		if (list.visible) list.updateWatcher(((i == len) ? i - 1 : i), false, interp);
	}

	protected function listSet(list:ListWatcher, newValue:Array):void {
		list.contents = newValue;
	}

	protected function listDelete(list:ListWatcher, i:int):void {
		list.contents.splice(i - 1, 1);
	}

	private function primInsert(b:Block):void {
		var val:* = interp.arg(b, 0);
		var where:* = interp.arg(b, 1);
		var list:ListWatcher = listarg(b, 2);
		if (!list) return;
		if (where == 'last') {
			listAppend(list, val);
			if (list.visible) list.updateWatcher(list.contents.length, false, interp);
		} else {
			var i:int = computeIndex(where, list.contents.length + 1);
			if (i < 0) return;
			listInsert(list, i, val);
			if (list.visible) list.updateWatcher(i, false, interp);
		}
	}

	protected function listInsert(list:ListWatcher, i:int, item:*):void {
		list.contents.splice(i - 1, 0, item);
	}

	private function primReplace(b:Block):void {
		var list:ListWatcher = listarg(b, 1);
		if (!list) return;
		var i:int = computeIndex(interp.arg(b, 0), list.contents.length);
		if (i < 0) return;
		listReplace(list, i, interp.arg(b, 2));
		if (list.visible) list.updateWatcher(i, false, interp);
	}

	protected function listReplace(list:ListWatcher, i:int, item:*):void {
		list.contents[i - 1] = item;
	}

	private function primGetItem(b:Block):* {
		var list:ListWatcher = listarg(b, 1);
		if (!list) return '';
		var i:int = computeIndex(interp.arg(b, 0), list.contents.length);
		if (i < 0) return '';
		if (list.visible) list.updateWatcher(i, true, interp);
		return list.contents[i - 1];
	}

	private function primLength(b:Block):Number {
		var list:ListWatcher = listarg(b, 0);
		if (!list) return 0;
		return list.contents.length;
	}

	private function primContains(b:Block):Boolean {
		var list:ListWatcher = listarg(b, 0);
		if (!list) return false;
		var item:* = interp.arg(b, 1);
		if (list.contents.indexOf(item) >= 0) return true;
		for each (var el:* in list.contents) {
			// use Scratch comparison operator (Scratch considers the string '123' equal to the number 123)
			if (Primitives.compare(el, item) == 0) return true;
		}
		return false;
	}

	private function listarg(b:Block, i:int):ListWatcher {
		var listName:String = interp.arg(b, i);
		if (listName.length == 0) return null;
		var obj:ScratchObj = interp.targetObj();
		var result:ListWatcher = obj.listCache[listName];
		if (!result) {
			result = obj.listCache[listName] = obj.lookupOrCreateList(listName);
		}
		return result;
	}

	private function computeIndex(n:*, len:int):int {
		var i:int;
		if (!(n is Number)) {
			if (n == 'last') return (len == 0) ? -1 : len;
			if ((n ==  'any') || (n == 'random')) return (len == 0) ? -1 : 1 + Math.floor(Math.random() * len);
			n = Number(n);
			if (isNaN(n)) return -1;
		}
		i = (n is int) ? n : Math.floor(n);
		if ((i < 1) || (i > len)) return -1;
		return i;
	}

}}
