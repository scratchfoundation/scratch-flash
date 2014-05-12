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

package uiwidgets {
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;

public class TextPane extends Sprite {

	private static var scrollbarWidth:int = 10;

	public var textField:TextField;
	public var scrollbar:Scrollbar;

	public function TextPane() {
		addTextField();
		scrollbar = new Scrollbar(scrollbarWidth, textField.height, scrollTextField);
		setWidthHeight(400, 500);
		addChild(scrollbar);
		addEventListener(Event.ENTER_FRAME, updateScrollbar);
	}

	public function setWidthHeight(w:int, h:int):void {
		textField.width = w - scrollbar.width;
		textField.height = h;
		scrollbar.x = textField.width;
		scrollbar.setWidthHeight(scrollbarWidth, h);
	}

	public function append(s:String):void {
		textField.appendText(s);
		textField.scrollV = textField.maxScrollV - 1;
		updateScrollbar(null);
	}

	public function clear():void {
		textField.text = "";
		textField.scrollV = 0;
		updateScrollbar(null);
	}

	public function setText(s:String):void {
		textField.text = s;
		textField.scrollV = textField.maxScrollV - 1;
		updateScrollbar(null);
	}

	private function scrollTextField(scrollFraction:Number):void {
		textField.scrollV = scrollFraction * textField.maxScrollV;
	}

	private function updateScrollbar(evt:Event):void {
		var scroll:Number = textField.scrollV / textField.maxScrollV;
		var visible:Number = textField.height / textField.textHeight;
		scrollbar.update(scroll, visible);
	}

	private function addTextField():void {
		textField = new TextField();
		textField.background = true;
		textField.type = TextFieldType.INPUT;
		textField.defaultTextFormat = new TextFormat(CSS.font, 14);
		textField.multiline = true;
		textField.wordWrap = true;
		addChild(textField);
	}

}}
