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

// SoundLevelMeter.as
// John Maloney, March 2012

package soundedit {
	import flash.display.*;
	import flash.text.TextFormat;
	import assets.Resources;

public class SoundLevelMeter extends Sprite {

	private var w:int, h:int;
	private var bar:Shape;
	private var recentMax:Number = 0;

	public function SoundLevelMeter(barWidth:int, barHeight:int) {
		w = barWidth;
		h = barHeight;

		// frame
		graphics.lineStyle(1, CSS.borderColor, 1, true);
		graphics.drawRoundRect(0, 0, w, h, 7, 7);

		// meter bar
		addChild(bar = new Shape());
	}

	public function clear():void {
		recentMax = 0;
		setLevel(0);
	}

	public function setLevel(percent:Number):void {
		recentMax *= 0.85;
		recentMax = Math.max(percent, recentMax);
		drawBar(recentMax);
	}

	private function drawBar(percent:Number):void {
		const red:int = 0xFF0000;
		const yellow:int = 0xFFFF00;
		const green:int = 0xFF00;
		const r:int = 3;

		var g:Graphics = bar.graphics;
		g.clear();

		g.beginFill(red);
		var barH:int = (h - 1) * Math.min(percent, 100) / 100;
		g.drawRoundRect(1, h - barH, w - 1, barH, r, r);

		g.beginFill(yellow);
		barH = h * Math.min(percent, 95) / 100;
		g.drawRoundRect(1, h - barH, w - 1, barH, r, r);

		g.beginFill(green);
		barH = h * Math.min(percent, 70) / 100;
		g.drawRoundRect(1, h - barH, w - 1, barH, r, r);
	}

}}
