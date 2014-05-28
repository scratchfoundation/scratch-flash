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

package watchers {
import flash.display.Sprite;
import flash.events.*;
import flash.text.*;
import uiwidgets.ResizeableFrame;
import util.Color;

public class ListCell extends Sprite {

	private const format:TextFormat = new TextFormat(CSS.font, 11, 0xFFFFFF, true);
	private static var normalColor:int = Specs.listColor;
	private static var focusedColor:int = Color.mixRGB(Color.scaleBrightness(Specs.listColor, 2), 0xEEEEEE, 0.6);

	public var tf:TextField;
	private var frame:ResizeableFrame;

	public function ListCell(s:String, width:int, whenChanged:Function, keyPress:Function) {
		frame = new ResizeableFrame(0xFFFFFF, normalColor, 6, true);
		addChild(frame);
		addTextField(whenChanged, keyPress);
		tf.text = s;
		setWidth(width);
	}

	public function setText(s:String, w:int = 0):void {
		// Set the text and, optionally, the width.
		tf.text = s;
		setWidth((w > 0) ? w : frame.w);
	}

	public function setEditable(isEditable:Boolean):void {
		tf.type = isEditable ? 'input' : 'dynamic';
	}

	public function setWidth(w:int):void {
		tf.width = Math.max(w, 15); // forces line wrapping, possibly changing tf.height
		var frameH:int = Math.max(tf.textHeight + 7, 20);
		frame.setWidthHeight(tf.width, frameH);
	}

	private function addTextField(whenChanged:Function, keyPress:Function):void {
		tf = new TextField();
		tf.type = 'input';
		tf.wordWrap = true;
		tf.autoSize = TextFieldAutoSize.LEFT;
		tf.defaultTextFormat = format;
		tf.x = 3;
		tf.y = 1;
		tf.addEventListener(Event.CHANGE, whenChanged);
		tf.addEventListener(KeyboardEvent.KEY_DOWN, keyPress);
		addChild(tf);
		tf.addEventListener(FocusEvent.FOCUS_IN, focusChange);
		tf.addEventListener(FocusEvent.FOCUS_OUT, focusChange);
	}

	public function select():void {
		stage.focus = tf;
		tf.setSelection(0, tf.text.length);
	}

	private function focusChange(e:FocusEvent):void {
		var hasFocus:Boolean = (e.type == FocusEvent.FOCUS_IN);
		frame.setColor(hasFocus ? focusedColor : normalColor);
		tf.textColor = (hasFocus ? 0 : 0xFFFFFF);
	}
}}
