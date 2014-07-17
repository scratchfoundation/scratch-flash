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

package svgeditor {
public class DrawProperties {

	// colors
	public var rawColor:uint = 0xFF000000;
	public var rawSecondColor:uint = 0xFFFFFFFF;

	public function set color(c:uint):void { rawColor = c }
	public function get color():uint { return rawColor & 0xFFFFFF }
	public function get alpha():Number { return ((rawColor >> 24) & 0xFF) / 0xFF }

	public function set secondColor(c:uint):void { rawSecondColor = c }
	public function get secondColor():uint { return rawSecondColor & 0xFFFFFF }
	public function get secondAlpha():Number { return ((rawSecondColor >> 24) & 0xFF) / 0xFF }

	// stroke
	public var smoothness:Number = 1;
	private var rawStrokeWidth:Number = 1;

	public function set strokeWidth(w:int):void { rawStrokeWidth = w }

	public function get strokeWidth():int {
		if (Scratch.app.imagesPart && (Scratch.app.imagesPart.editor is SVGEdit)) return rawStrokeWidth;

		// above 10, use Squeak brush sizes
		var n:Number = Math.max(1, Math.round(rawStrokeWidth));
		if (11 == n) return 13;
		if (12 == n) return 19;
		if (13 == n) return 29;
		if (14 == n) return 47;
		if (15 == n) return 75;
		return n;
	}

	// fill
	public var fillType:String = 'solid'; // solid, linearHorizontal, linearVertical, radial
	public var filledShape:Boolean = false;

	// font
	public var fontName:String = 'Helvetica';

}}
