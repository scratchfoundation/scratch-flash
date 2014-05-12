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
	import flash.text.*;
	import uiwidgets.ResizeableFrame;

public class WatcherReadout extends Sprite {

	private var smallFont:TextFormat = new TextFormat(CSS.font, 10, 0xFFFFFF, true);
	private var largeFont:TextFormat = new TextFormat(CSS.font, 15, 0xFFFFFF, true);

	private var frame:ResizeableFrame;
	private var tf:TextField;
	private var isLarge:Boolean;

	public function WatcherReadout() {
		frame = new ResizeableFrame(0xFFFFFF, Specs.variableColor, 8, true);
		addChild(frame);
		addTextField();
		beLarge(false);
	}

	public function getColor():int { return frame.getColor() }
	public function setColor(color:int):void { frame.setColor(color) }

	public function get contents():String { return tf.text }

	public function setContents(s:String):void {
		if (s == tf.text) return; // no change
		tf.text = s;
		fixLayout();
	}

	public function beLarge(newValue:Boolean):void {
		isLarge = newValue;
		var fmt:TextFormat = isLarge ? largeFont : smallFont;
		fmt.align = TextFormatAlign.CENTER;
		tf.defaultTextFormat = fmt;
		tf.setTextFormat(fmt); // force font change
		fixLayout();
	}

	private function fixLayout():void {
		var w:int = isLarge ? 48 : 40;
		var h:int = isLarge ? 20 : 14;
		var hPad:int = isLarge ? 12 : 5;
		w = Math.max(w, tf.textWidth + hPad);
		tf.width = w;
		tf.height = h;
		tf.y = isLarge ? 0 : -1;
		if ((w != frame.w) || (h != frame.h)) frame.setWidthHeight(w, h);
	}

	private function addTextField():void {
		tf = new TextField();
		tf.type = "dynamic";
		tf.selectable = false;
		addChild(tf);
	}

}}
