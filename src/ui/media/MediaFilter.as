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

// MediaFilter.as
// John Maloney, February 2013

package ui.media {
	import flash.display.*;
	import flash.text.*;
	import assets.Resources;
	import translation.Translator;
	import flash.events.MouseEvent;

public class MediaFilter extends Sprite {

	private const titleFormat:TextFormat = new TextFormat(CSS.font, 15, CSS.buttonLabelOverColor, false);
	private const selectorFormat:TextFormat = new TextFormat(CSS.font, 14, CSS.textColor);

	private const unselectedColor:int = CSS.overColor; // 0x909090;
	private const selectedColor:int = CSS.textColor;
	private const rolloverColor:int = CSS.buttonLabelOverColor;

	private var title:TextField;
	private var selectorNames:Array = []; // strings representing tags/themes/categories
	private var selectors:Array = []; // TextFields (translated)
	private var selection:String = '';
	private var whenChanged:Function;

	public function MediaFilter(filterName:String, elements:Array, whenChanged:Function = null) {
		addChild(title = Resources.makeLabel(Translator.map(filterName), titleFormat));
		this.whenChanged = whenChanged;
		for each (var selName:String in elements) addSelector(selName);
		select(0); // select first selector by default
		fixLayout();
	}

	public function set currentSelection(s:String):void { select(selectorNames.indexOf(s)) }
	public function get currentSelection():String { return selection }

	private function fixLayout():void {
		title.x = title.y = 0;
		var nextY:int = title.height + 2;
		for each (var sel:TextField in selectors) {
			sel.x = 15;
			sel.y = nextY;
			nextY += sel.height;
		}
	}

	private function addSelectors(selList:Array):void {
		for each (var selName:String in selList) addSelector(selName);
	}

	private function addSelector(selName:String):void {
		function mouseDown(ignore:*):void {
			select(selectorNames.indexOf(selName));
			if (whenChanged != null) whenChanged(sel.parent);
		}
		var sel:TextField = Resources.makeLabel(Translator.map(selName), selectorFormat);
		sel.addEventListener(MouseEvent.MOUSE_OVER, mouseOver);
		sel.addEventListener(MouseEvent.MOUSE_OUT, mouseOver);
		sel.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		selectorNames.push(selName);
		selectors.push(sel);
		addChild(sel);
	}

	private function mouseOver(evt:MouseEvent):void {
		var sel:TextField = evt.target as TextField;
		if (sel.textColor != selectedColor) {
			sel.textColor = (evt.type == MouseEvent.MOUSE_OVER) ? rolloverColor : unselectedColor;
		}
	}

	private function select(index:int):void {
		// Highlight the new selection and unlight all others.
		selection = ''; // nothing selected
		var fmt:TextFormat = new TextFormat();
		for (var i:int = 0; i < selectors.length; i++) {
			if (i == index) {
				selection = selectorNames[i];
				fmt.bold = true;
				selectors[i].setTextFormat(fmt);
				selectors[i].textColor = selectedColor;
			} else {
				fmt.bold = false;
				selectors[i].setTextFormat(fmt);
				selectors[i].textColor = unselectedColor;
			}
		}
	}

}}
