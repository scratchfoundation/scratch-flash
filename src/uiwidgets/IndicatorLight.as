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

// IndicatorLight.as
// John Maloney, September 2013
//
// A simple indicator light with a color and a tooltip. Used to show extension state.

package uiwidgets {
	import flash.display.*;
	import uiwidgets.SimpleTooltips;

public class IndicatorLight extends Sprite {

	public var target:*;

	private var color:int;
	private var msg:String = '';

	public function IndicatorLight(target:* = null) {
		this.target = target;
		redraw();
	}

	public function setColorAndMsg(color:int, msg:String):void {
		if ((color == this.color) && (msg == this.msg)) return; // no change
		this.color = color;
		this.msg = msg;
		SimpleTooltips.add(this, {text: msg, direction: 'bottom'});
		redraw();
	}

	private function redraw():void {
		const borderColor:int = 0x505050;
		var g:Graphics = graphics;
		g.clear();
		g.lineStyle(1, borderColor);
		g.beginFill(color);
		g.drawCircle(7, 7, 6);
		g.endFill();
	}

}}
