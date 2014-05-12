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

// EditableLabel.as
// John Maloney, July 2011
//
// An EditableLabel is an editable text field with an optional bezel (box) around it.
// By default, the bezel is always visible, but useDynamicBezel() can be used to make
// it appear only while the user is editing the text (i.e. it has keyboard focus).

package uiwidgets {
	import flash.display.*;
	import flash.events.*;
	import flash.filters.*;
	import flash.text.*;

public class EditableLabel extends Sprite {

	private const defaultFormat:TextFormat = new TextFormat(CSS.font, 13, 0x929497);
	private const bgColor:int = 0xFFFFFF;
	private const frameColor:int = 0xA6A8AB;

	public var tf:TextField;

	private var bezel:Shape;
	private var dynamicBezel:Boolean;
	private var textChanged:Function;

	public function EditableLabel(textChanged:Function, format:TextFormat = null) {
		this.textChanged = textChanged;
		bezel = new Shape();
		addChild(bezel);
		addFilter();
		if (format == null) format = defaultFormat;
		addTextField(format);
		setWidth(100);
	}

	public function setWidth(w:int):void {
		if (tf.text.length == 0) tf.text = ' '; // needs at least one character to compute textHeight
		var h:int = tf.textHeight + 5; // the height is determined by the font
		var g:Graphics = bezel.graphics;
		g.clear();
		g.lineStyle(0.5, frameColor, 1, true);
		g.beginFill(bgColor);
		g.drawRoundRect(0, 0, w, h, 7, 7);
		g.endFill();
		tf.width = w - 3;
		tf.height = h - 1;
	}

	public function contents():String { return tf.text }
	public function setContents(s:String):void { tf.text = s }
	public function setEditable(flag:Boolean):void {
		tf.type = flag ? TextFieldType.INPUT : TextFieldType.DYNAMIC;
		tf.selectable = flag;
		bezel.visible = flag;
	}

	public function useDynamicBezel(flag:Boolean):void {
		dynamicBezel = flag;
		bezel.visible = !dynamicBezel;
	}

	private function focusChange(evt:FocusEvent):void {
		if (dynamicBezel) bezel.visible = ((root.stage.focus == tf) && (tf.type == TextFieldType.INPUT));
		if ((evt.type == FocusEvent.FOCUS_OUT) && (textChanged != null)) textChanged();
	}

	private function keystroke(evt:KeyboardEvent):void {
		// Called after each keystroke.
		var k:int = evt.charCode;
		if ((k == 10) || (k == 13)) {
			stage.focus = null; // relinquish keyboard focus
			evt.stopPropagation();
		}
	}

	private function addTextField(format:TextFormat):void {
		tf = new TextField();
		tf.defaultTextFormat = format;
		tf.type = TextFieldType.INPUT;
		var debugAlignment:Boolean = false;
		if (debugAlignment) {
			tf.background = true;
			tf.backgroundColor = 0xA0A0FF;
		}
		tf.x = 2;
		tf.y = 1;
		tf.addEventListener(FocusEvent.FOCUS_IN, focusChange);
		tf.addEventListener(FocusEvent.FOCUS_OUT, focusChange);
		tf.addEventListener(KeyboardEvent.KEY_DOWN, keystroke);
		addChild(tf);
	}

	private function addFilter():void {
		var f:BevelFilter = new BevelFilter();
		f.angle = 225;
		f.shadowAlpha = 0.5;
		f.distance = 2;
		f.strength = 0.5;
		f.blurX = f.blurY = 2;
		bezel.filters = [f];
	}

}}