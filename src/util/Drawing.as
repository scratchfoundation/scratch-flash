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

// Drawing.as
// Shane M. Clements, November 2014
//
// Drawing utility methods, such as for drawing arcs.

package util {
import flash.display.Graphics;

public class Drawing {
	private var g:Graphics;
	private var lastX:Number;
	private var lastY:Number;
	function Drawing(gfx:Graphics, startX:int = 0, startY:int = 0) {
		g = gfx;
		lastX = startX;
		lastY = startY;
		g.moveTo(lastX, lastY);
	}

	public function deltaLine(dx:int, dy:int):void {
		line(lastX + dx, lastY + dy);
	}

	public function line(x:int, y:int):void {
		g.lineTo(x, y);
		lastX = x;
		lastY = y;
	}

	public function deltaCurve(dx:int, dy:int, roundness:Number = 0.42):void {
		curve(lastX + dx, lastY + dy, roundness);
	}

	public function curve(x:int, y:int, roundness:Number = 0.42):void {
		// Draw a curve between two points. Compute control point by following an orthogonal vector
		// from the midpoint of the L between p1 and p2 scaled by roundness * dist(p1, p2).
		// If concave is true, invert the curvature.

		var midX:Number = (lastX + x) / 2.0;
		var midY:Number = (lastY  + y) / 2.0;
		var cx:Number = midX + (roundness * (y - lastY));
		var cy:Number = midY - (roundness * (x - lastX));
		g.curveTo(cx, cy, x, y);
		lastX = x;
		lastY = y;
	}
}}