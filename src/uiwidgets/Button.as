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
	import flash.display.*;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.text.*;

import translation.Translator;

public class Button extends Sprite {
	protected var labelOrIcon:DisplayObject;
	protected var normalColor:* = CSS.titleBarColors;
	protected var overColor:uint = CSS.overColor;
	protected var textColor:uint = CSS.buttonLabelColor;
	protected var textOverColor:uint = CSS.white;
	protected var color:* = normalColor;
	protected var minWidth:int = 50;
	protected var compact:Boolean;

	private var action:Function;
	private var tipName:String;

	public function Button(label:String, action:Function = null, compact:Boolean = false, tipName:String = null) {
		this.action = action;
		this.compact = compact;
		this.tipName = tipName;
		addLabel(label);
		mouseChildren = false;
		addEventListener(MouseEvent.MOUSE_OVER, mouseOver);
		addEventListener(MouseEvent.MOUSE_OUT, mouseOut);
		addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		addEventListener(MouseEvent.MOUSE_UP, mouseUp);
		setColor(normalColor);
	}

	public function setLabel(s:String):void {
		if (labelOrIcon is TextField) {
			TextField(labelOrIcon).text = s;
			setMinWidthHeight(0, 0);
		} else {
			if ((labelOrIcon != null) && (labelOrIcon.parent != null)) labelOrIcon.parent.removeChild(labelOrIcon);
			addLabel(s);
		}
	 }

	public function setIcon(icon:DisplayObject):void {
		if ((labelOrIcon != null) && (labelOrIcon.parent != null)) {
			labelOrIcon.parent.removeChild(labelOrIcon);
		}
		labelOrIcon = icon;
		if (icon != null) addChild(labelOrIcon);
		setMinWidthHeight(0, 0);
	}

	public function setMinWidthHeight(minW:int, minH:int):void {
		if (labelOrIcon != null) {
			var w:Number = labelOrIcon.width;
			var h:Number = labelOrIcon.height;
			if (labelOrIcon is TextField) {
				var tf:TextField = (labelOrIcon as TextField);
				minW = Math.max(minWidth, tf.textWidth + 11);
				minH = tf.textHeight + (compact ? 0 : 5);
				w = tf.textWidth;
				h = tf.textHeight;
			} else {
				minW = Math.max(minWidth, labelOrIcon.width + 12);
				minH = Math.max(minH, labelOrIcon.height + 11);
			}
			labelOrIcon.x = ((minW - w) / 2);
			labelOrIcon.y = ((minH - h) / 2);
		}
		// outline
		graphics.clear();
		graphics.lineStyle(0.5, CSS.borderColor, 1, true);
		if (color is Array) {
	 		var matr:Matrix = new Matrix();
 			matr.createGradientBox(minW, minH, Math.PI / 2, 0, 0);
 			graphics.beginGradientFill(GradientType.LINEAR, CSS.titleBarColors , [100, 100], [0x00, 0xFF], matr);
  		}
		else graphics.beginFill(color);
		graphics.drawRoundRect(0, 0, minW, minH, 12);
 		graphics.endFill();
	}

	protected function mouseOver(evt:MouseEvent):void { setColor(overColor) }
	protected function mouseOut(evt:MouseEvent):void { setColor(normalColor) }
	protected function mouseDown(evt:MouseEvent):void { Menu.removeMenusFrom(stage) }
	protected function mouseUp(evt:MouseEvent):void {
		if (action != null) action();
		evt.stopImmediatePropagation();
	}

	public function handleTool(tool:String, evt:MouseEvent):void {
		if (tool == 'help' && tipName) Scratch.app.showTip(tipName);
	}

	protected function setColor(c:*):void {
		color = c;
		if (labelOrIcon is TextField) {
			(labelOrIcon as TextField).textColor = (c == overColor) ? textOverColor : textColor;
		}
		setMinWidthHeight(5, 5);
	}

	private function addLabel(s:String):void {
		var label:TextField = new TextField();
		label.autoSize = TextFieldAutoSize.LEFT;
		label.selectable = false;
		label.background = false;
		label.defaultTextFormat = CSS.normalTextFormat;
		label.textColor = CSS.buttonLabelColor;
		label.text = Translator.map(s);
		labelOrIcon = label;
		setMinWidthHeight(0, 0);
		addChild(label);
	}

}}
