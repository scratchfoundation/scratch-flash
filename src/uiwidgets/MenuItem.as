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
// John Maloney, October 2009
//
// A single menu item for Menu.as.

package uiwidgets {
	import flash.display.*;
	import flash.events.MouseEvent;
	import flash.text.*;
	import scratch.BlockMenus;
	import translation.Translator;
	import util.Color;

public class MenuItem extends Sprite {

	private const leftMargin:int = 22;
	private const rightMargin:int = 10;
	private const checkmarkColor:int = 0xF0F0F0;

	private var menu:Menu;
	private var label:TextField; // if label is null, this item is a divider line
	private var checkmark:Shape;
	private var selection:*;

	private var base:Shape;
	private var w:int, h:int;

	public function MenuItem(menu:Menu, labelText:*, selection:*, enabled:Boolean) {
		this.menu = menu;
		this.selection = (selection == null) ? labelText : selection;
		addChild(base = new Shape());
		if (labelText == Menu.line) return;
		addCheckmark();
		addLabel(String(labelText), enabled);
		setBaseColor(menu.color);
		if (enabled) {
			addEventListener(MouseEvent.MOUSE_OVER, mouseOver);
			addEventListener(MouseEvent.MOUSE_OUT, mouseOut);
			addEventListener(MouseEvent.MOUSE_UP, mouseUp);
		}
	}

	public function setWidthHeight(w:int, itemHeight:int):void {
		this.w = w;
		this.h = 1;
		if (label) {
			this.h = Math.max(label.height, itemHeight);
			label.y = Math.max(0, (h - label.height) / 2);
		}
		setBaseColor(menu.color);
	}

	public function isLine():Boolean { return !label }

	public function getLabel():String { return label ? label.text : '' }
	public function showCheckmark(flag:Boolean):void { if (checkmark) checkmark.visible = flag }

	public function translate(menuName:String):void {
		if (label && BlockMenus.shouldTranslateItemForMenu(label.text, menuName)) {
			label.text = Translator.map(label.text);
		}
	}

	private function addCheckmark():void {
		checkmark = new Shape();
		drawCheckmark(checkmarkColor);
		checkmark.x = 6;
		checkmark.y = 8;
		checkmark.visible = true;
		addChild(checkmark);
	}

	private function drawCheckmark(c:int):void {
		var g:Graphics = checkmark.graphics;
		g.clear();
		g.beginFill(c);
		g.moveTo(0, 6);
		g.lineTo(5, 12);
		g.lineTo(12.5, 0.5);
		g.lineTo(12, 0);
		g.lineTo(5, 9);
		g.lineTo(0, 5.5);
		g.endFill();
	}

	private function addLabel(s:String, enabled:Boolean):void {
		label = new TextField();
		label.autoSize = TextFieldAutoSize.LEFT;
		label.selectable = false;
		label.defaultTextFormat = new TextFormat(CSS.font, CSS.menuFontSize, CSS.white);
		label.text = s;
		label.x = leftMargin;
		label.y = 0;
		label.alpha = enabled ? 1 : 0.5;
		w = label.width + leftMargin + rightMargin;
		h = Math.max(label.height, menu.itemHeight);
		addChild(label);
		setBaseColor(menu.color);
	}

	private function setHighlight(highlight:Boolean):void {
		setBaseColor(highlight ? selectedColorFrom(menu.color) : menu.color);
		label.textColor = highlight ? colorWithBrightness(menu.color, 0.3) : CSS.white;
		if (checkmark.visible) drawCheckmark(highlight ? colorWithBrightness(menu.color, 0.5) : checkmarkColor);
	}

	private function setBaseColor(c:int):void {
		var g:Graphics = base.graphics;
		g.clear();
		if (label) {
			g.beginFill(c);
			g.drawRect(0, 0, w, h);
			g.endFill();
		} else { // divider line
			g.beginFill(colorWithBrightness(menu.color, 0.5));
			base.graphics.drawRect(0, 0, w, 1);
			g.endFill();
		}
	}

	private function selectedColorFrom(rgb:Number):int {
		var hsv:Array = Color.rgb2hsv(rgb);
		var sat:Number = hsv[1];
		var bri:Number = 0.9;
		if (sat > 0.5) {
			sat = 0.3;
			bri = 1;
		}
		return Color.fromHSV(hsv[0], sat, bri);
	}

	private function colorWithBrightness(rgb:Number, brightness:Number):int {
		var hsv:Array = Color.rgb2hsv(rgb);
		return Color.fromHSV(hsv[0], hsv[1], brightness);
	}

	private function mouseOver(evt:MouseEvent):void { setHighlight(true) }
	private function mouseOut(evt:MouseEvent):void { setHighlight(false) }
	private function mouseUp(evt:MouseEvent):void { menu.selected(selection) }

}}
