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

// UIPart.as
// John Maloney, November 2011
//
// This is the superclass for the main parts of the Scratch UI.
// It holds drawing style constants and code shared by all parts.
// Subclasses often implement one or more of the following:
//
//		refresh() - update this part after a change (e.g. changing the selected object)
//		step() - do background tasks

package ui.parts {
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.text.*;
	import translation.Translator;
	import uiwidgets.IconButton;
 	import util.DrawPath;

public class UIPart extends Sprite {

	protected static const cornerRadius:int = 8;

	public var app:Scratch;
	public var w:int, h:int;

	public function right():int { return x + w }
	public function bottom():int { return y + h }

	public static function makeLabel(s:String, fmt:TextFormat, x:int = 0, y:int = 0):TextField {
		// Create a non-editable text field for use as a label.
		var tf:TextField = new TextField();
		tf.autoSize = TextFieldAutoSize.LEFT;
		tf.selectable = false;
		tf.defaultTextFormat = fmt;
		tf.text = s;
		tf.x = x;
		tf.y = y;
		return tf;
	}

	public static function drawTopBar(g:Graphics, colors:Array, path:Array, w:int, h:int, borderColor:int = -1):void {
		if (borderColor < 0) borderColor = CSS.borderColor;
		g.clear();
		drawBoxBkgGradientShape(g, Math.PI / 2, colors,[0x00, 0xFF], path, w, h);
		g.lineStyle(0.5, borderColor, 1, true);
		DrawPath.drawPath(path, g);
	}

	protected static function drawSelected(g:Graphics, colors:Array, path:Array,  w:int, h:int):void {
		g.clear();
		drawBoxBkgGradientShape(g, Math.PI / 2, colors, [0xDC, 0xFF], path, w, h);
		g.lineStyle(0.5,CSS.borderColor,1,true);
		DrawPath.drawPath(path, g);
	}

	private function curve(g:Graphics, p1x:int, p1y:int, p2x:int, p2y:int, roundness:Number = 0.42):void {
		// Compute the Bezier control point by following an orthogal vector from the midpoint
		// of the line between p1 and p2 scaled by roundness * dist(p1, p2). The default roundness
		// approximates a circular arc. Negative roundness gives a concave curve.

		var midX:Number = (p1x + p2x) / 2.0;
		var midY:Number = (p1y + p2y) / 2.0;
		var cx:Number = midX + (roundness * (p2y - p1y));
		var cy:Number = midY - (roundness * (p2x - p1x));
		g.curveTo(cx, cy, p2x, p2y);
	}

	protected static function drawBoxBkgGradientShape(g:Graphics, angle:Number, colors:Array, ratios:Array, path:Array, w:Number, h:Number):void {
		var m:Matrix = new Matrix();
		m.createGradientBox(w, h, angle, 0, 0);
		g.beginGradientFill(GradientType.LINEAR, colors , [100, 100], ratios, m);
		DrawPath.drawPath(path, g);
		g.endFill();
	}

	public static function getTopBarPath(w:int, h:int):Array {
		return [["m", 0, h], ["v", -h + cornerRadius], ["c", 0, -cornerRadius, cornerRadius, -cornerRadius],
				["h", w - cornerRadius * 2], ["c", cornerRadius, 0, cornerRadius, cornerRadius],
				["v", h - cornerRadius]];
	}

	/* Text Menu Buttons */

	public static function makeMenuButton(s:String, fcn:Function, hasArrow:Boolean = false, labelColor:int = 0xFFFFFF):IconButton {
		var onImg:Sprite = makeButtonLabel(Translator.map(s), CSS.buttonLabelOverColor, hasArrow);
		var offImg:Sprite = makeButtonLabel(Translator.map(s), labelColor, hasArrow);
		var btn:IconButton = new IconButton(fcn, onImg, offImg);
		btn.isMomentary = true;
		return btn;
	}

	public static function makeButtonLabel(s:String, labelColor:int, hasArrow:Boolean):Sprite {
		var label:TextField = makeLabel(s, CSS.topBarButtonFormat);
		label.textColor = labelColor;
		var img:Sprite = new Sprite();
		img.addChild(label);
		if (hasArrow) img.addChild(menuArrow(label.textWidth + 5, 6, labelColor));
		return img;
	}

	private static function menuArrow(x:int, y:int, c:int):Shape {
		var arrow:Shape = new Shape();
		var g:Graphics = arrow.graphics;
		g.beginFill(c);
		g.lineTo(8, 0);
		g.lineTo(4, 6)
		g.lineTo(0, 0);
		g.endFill();
		arrow.x = x;
		arrow.y = y;
		return arrow;
	}

}}
