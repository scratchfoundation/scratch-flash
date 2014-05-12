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

// Color.as
// John Maloney, August 2009
//
// Color utility methods, such as HSV/RGB conversions.

package util {
public class Color {

	// Convert hue (0-360), saturation (0-1), and brightness (0-1) to RGB.
	public static function fromHSV(h:Number, s:Number, v:Number):int {
		var r:Number, g:Number, b:Number;
		h = h % 360;
		if (h < 0) h += 360;
		s = Math.max(0, Math.min(s, 1));
		v = Math.max(0, Math.min(v, 1));

		var i:Number = Math.floor(h / 60);
		var f:Number = (h / 60) - i;
		var p:Number = v * (1 - s);
		var q:Number = v * (1 - (s * f));
		var t:Number = v * (1 - (s * (1 - f)));
		if (i == 0) { r = v; g = t; b = p; }
		else if (i == 1) { r = q; g = v; b = p; }
		else if (i == 2) { r = p; g = v; b = t; }
		else if (i == 3) { r = p; g = q; b = v; }
		else if (i == 4) { r = t; g = p; b = v; }
		else if (i == 5) { r = v; g = p; b = q; }
		r = Math.floor(r * 255);
		g = Math.floor(g * 255);
		b = Math.floor(b * 255);
		return (r << 16) | (g << 8) | b;
	}

	// Convert RGB to an array containing the hue, saturation, and brightness.
	public static function rgb2hsv(rgb:Number):Array {
		var h:Number, s:Number, v:Number, x:Number, f:Number, i:Number;
		var r:Number = ((rgb >> 16) & 255) / 255;
		var g:Number = ((rgb >> 8) & 255) / 255;
		var b:Number = (rgb & 255) / 255;
		x = Math.min(Math.min(r, g), b);
		v = Math.max(Math.max(r, g), b);
		if (x == v) return [0, 0, v]; // gray; hue arbitrarily reported as zero
		f = (r == x) ? g - b : ((g == x) ? b - r : r - g);
		i = (r == x) ? 3 : ((g == x) ? 5 : 1);
		h = ((i - (f / (v - x))) * 60) % 360;
		s = (v - x) / v;
		return [h, s, v];
	}

	public static function scaleBrightness(rgb:Number, scale:Number):int {
		var hsv:Array = rgb2hsv(rgb);
		var val:Number = Math.max(0, Math.min(scale * hsv[2], 1));
		return fromHSV(hsv[0], hsv[1], val);
	}

	public static function mixRGB(rgb1:int, rgb2:int, fraction:Number):int {
		// Mix rgb1 with rgb2. 0 gives all rgb1, 1 gives rbg2, .5 mixes them 50/50.
		if (fraction <= 0) return rgb1;
		if (fraction >= 1) return rgb2;
		var r1:int = (rgb1 >> 16) & 255;
		var g1:int = (rgb1 >> 8) & 255;
		var b1:int = rgb1 & 255;
		var r2:int = (rgb2 >> 16) & 255;
		var g2:int = (rgb2 >> 8) & 255;
		var b2:int = rgb2 & 255;
		var r:int = ((fraction * r2) + ((1.0 - fraction) * r1)) & 255;
		var g:int = ((fraction * g2) + ((1.0 - fraction) * g1)) & 255;
		var b:int = ((fraction * b2) + ((1.0 - fraction) * b1)) & 255;
		return (r << 16) | (g << 8) | b;
	}

	public static function random():int {
		// return a random color
		var h:Number = 360 * Math.random();
		var s:Number = 0.7 + (0.3 * Math.random());
		var v:Number = 0.6 + (0.4 * Math.random());
		return fromHSV(h, s, v);
	}

}}
