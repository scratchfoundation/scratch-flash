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

// MenuItem.as
// Shane M. Clements, May 2015
//
// A single menu item for Menu.as.

package uiwidgets {
import flash.display.*;
import flash.text.*;
import translation.Translator;
import ui.Utility;

public class NewMenuItem extends Sprite {
	protected var menu:NewMenu;
	protected var isSeparator:Boolean;

	public function NewMenuItem(m:NewMenu, ... elems) {
		menu = m;

		// elements can come as an array or multiple arguments
		if (elems.length == 1 && elems[0] is Array) elems = elems[0];

		isSeparator = (elems.length == 0);
		if (!isSeparator) {
//			addEventListener(MouseEvent.MOUSE_OVER, mouseOver);
//			addEventListener(MouseEvent.MOUSE_OUT, mouseOut);
//			addEventListener(MouseEvent.MOUSE_UP, mouseUp);
			addElements(elems);
		}
	}

	private function addElements(elems:Array):void {
		var _x:Number = 0;
		for(var i:int=0, l:int=elems.length; i<l; ++i) {
			var elem:* = elems[i];
			if (elem is String)
				elem = elems[i] = makeLabel(elem);

			// Handle horizontal separation of elements
			elem.x = _x;
			_x += elem.width + (i < l - 1 && elems[i+1] is String && elem is TextField ? CSS.smallPadding / 2 : CSS.smallPadding);
			addChild(elem);
		}

		elems.unshift(0);
		Utility.verticallyCenterElements.apply(null, elems);
	}

	public function isLine():Boolean { return isSeparator; }
	private function makeLabel(s:String):DisplayObject {
		return new SimpleTextField(s, null, menu);
	}

	public function refreshText():void {
		// Find all text fields and call refreshText()
	}

//	protected function mouseOver(evt:MouseEvent):void { setHighlight(true) }
//	protected function mouseOut(evt:MouseEvent):void { setHighlight(false) }
//	protected function mouseUp(evt:MouseEvent):void { menu.selected(selection) }
}}
