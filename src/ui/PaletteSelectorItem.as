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

// PaletteSelectorItem.as
// John Maloney, August 2009
//
// A PaletteSelectorItem is a text button for a named category in a PaletteSelector.
// It handles mouse over, out, and up events and changes its appearance when selected.

package ui {
	import flash.display.*;
	import flash.events.MouseEvent;
	import flash.text.*;

public class PaletteSelectorItem extends Sprite {

	public var categoryID:int;
	public var label:TextField;
	public var isSelected:Boolean;

	private var color:uint;

	public function PaletteSelectorItem(id: int, s:String, c:uint) {
		categoryID = id;
		addLabel(s);
		color = c;
		setSelected(false);
		addEventListener(MouseEvent.MOUSE_OVER, mouseOver);
		addEventListener(MouseEvent.MOUSE_OUT, mouseOut);
		addEventListener(MouseEvent.CLICK, mouseUp);
	}

	private function addLabel(s:String):void {
		label = new TextField();
		label.autoSize = TextFieldAutoSize.LEFT;
		label.selectable = false;
		label.text = s;
		addChild(label);
	}

	public function setSelected(flag:Boolean):void {
		var w:int = 100;
		var h:int = label.height + 2;
		var tabInset:int = 8;
		var tabW:int = 7;
		isSelected = flag;
		var fmt:TextFormat = new TextFormat(CSS.font, 12, (isSelected ? CSS.white : CSS.offColor), isSelected);
		label.setTextFormat(fmt);
		label.x = 17;
		label.y = 1;
		var g:Graphics = this.graphics;
		g.clear();
		g.beginFill(0xFF00, 0); // invisible, but mouse sensitive
		g.drawRect(0, 0, w, h);
		g.endFill();
		g.beginFill(color);
		g.drawRect(tabInset, 1, isSelected ? w - tabInset - 1 : tabW, h - 2);
		g.endFill();
	}

	private function mouseOver(event:MouseEvent):void {
		label.textColor = isSelected ? CSS.white : CSS.buttonLabelOverColor;
	}

	private function mouseOut(event:MouseEvent):void {
		label.textColor = isSelected ? CSS.white : CSS.offColor;
	}

	private function mouseUp(event:MouseEvent):void {
		if (parent is PaletteSelector) {
			PaletteSelector(parent).select(categoryID, event.shiftKey);
		}
	}

}}
