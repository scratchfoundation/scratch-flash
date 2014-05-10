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

package scratch {
	import flash.display.*;
	import flash.text.*;

public class TalkBubble extends Sprite {

	public var pointsLeft:Boolean;

	private var type:String; // 'say' or 'think'
	private var style:String; // 'say' or 'ask' or 'result'
	private var shape:Shape;
	private var text:TextField;
	private static var textFormat:TextFormat = new TextFormat(CSS.font, 14, 0, true, null, null, null, null, TextFormatAlign.CENTER);
	private static var resultFormat:TextFormat = new TextFormat(CSS.font, 12, CSS.textColor, null, null, null, null, null, TextFormatAlign.CENTER);
	private var outlineColor:int = 0xA0A0A0;
	private var radius:int = 8;  // corner radius
	private var padding:int = 5;
	private var minWidth:int = 55;
	private var lastXY:Array;
	private var pInset1:int = 16
	private var pInset2:int = 50
	private var pDrop:int = 17;
	private var pDropX:int = 8;
	private var lineWidth:Number = 3;

	public function TalkBubble(s:String, type:String, style:String) {
		this.type = type;
		this.style = style;
		if (style == 'ask') {
			outlineColor = 0x4AADDE;
		} else if (style == 'result') {
			outlineColor = 0x888888;
			minWidth = 16;
			padding = 3;
			radius = 5;
			pInset1 = 8;
			pInset2 = 16;
			pDrop = 5;
			pDropX = 4;
			lineWidth = 0.5;
		}
		pointsLeft = true;
		shape = new Shape();
		addChild(shape);
		text = makeText();
		addChild(text);
		setText(s);
	}

	public function setDirection(dir:String):void {
		// set direction of balloon tail to 'left' or 'right'
		// and redraw balloon if necessary
		var newValue:Boolean = (dir == 'left');
		if (pointsLeft == newValue) return;
		pointsLeft = newValue;
		setWidthHeight(text.width + padding * 2, text.height + padding * 2);
	}

	public function getText():String { return text.text }

	private function setText(s:String):void {
		var desiredWidth:int = 135;
		text.width = desiredWidth + 100; // wider than desiredWidth
		text.text = s;
		text.width = Math.max(minWidth, Math.min(text.textWidth + 8, desiredWidth)); // fix word wrap
		setWidthHeight(text.width + padding * 2, text.height + padding * 2);
	}

	private function setWidthHeight(w:int, h:int):void {
		var g:Graphics = shape.graphics;
		g.clear();
		g.beginFill(0xFFFFFF);
		g.lineStyle(lineWidth, outlineColor);
		if (type == 'think') drawThink(w, h);
		else drawTalk(w, h);
	}

	private function makeText():TextField {
		var result:TextField = new TextField();
		result.autoSize = TextFieldAutoSize.LEFT;
		result.defaultTextFormat = style == 'result' ? resultFormat : textFormat;
		result.selectable = false;  // not selectable
		result.type = 'dynamic';  // not editable
		result.wordWrap = true;
		result.x = padding;
		result.y = padding;
		return result;
	}

	private function drawTalk(w:int, h:int):void {
		var insetW:int = w - radius;
		var insetH:int = h - radius;
		// pointer geometry:
		startAt(radius, 0);
		line(insetW, 0);
		arc(w, radius);
		line(w, insetH);
		arc(insetW, h);
		if (pointsLeft) {
			line(pInset2, h);
			line(pDropX, h + pDrop);
			line(pInset1, h);
		} else {
			line(w - pInset1, h);
			line(w - pDropX, h + pDrop);
			line(w - pInset2, h);
		}
		line(radius, h);
		arc(0, insetH);
		line(0, radius);
		arc(radius, 0);
	}

	private function drawThink(w:int, h:int):void {
		var insetW:int = w - radius;
		var insetH:int = h - radius;
		startAt(radius, 0);
		line(insetW, 0);
		arc(w, radius);
		line(w, insetH);
		arc(insetW, h);
		line(radius, h);
		arc(0, insetH);
		line(0, radius);
		arc(radius, 0);
		if (pointsLeft) {
			ellipse(16, h +  2, 12, 7, 2);
			ellipse(12, h + 10,  8, 5, 2);
			ellipse( 6, h + 15,  6, 4, 1);
		} else {
			ellipse(w - 29, h +  2, 12, 7, 2);
			ellipse(w - 20, h + 10,  8, 5, 2);
			ellipse(w - 12, h + 15,  6, 4, 1);
		}
	}

	private function startAt(x:int, y:int):void {
		shape.graphics.moveTo(x, y);
		lastXY = [x, y];
	}

	private function line(x:int, y:int):void {
		shape.graphics.lineTo(x, y);
		lastXY = [x, y];
	}

	private function ellipse(x:int, y:int, w:int, h:int, lineW:int):void {
		shape.graphics.lineStyle(lineW, outlineColor);
		shape.graphics.drawEllipse(x, y, w, h);
	}

	private function arc(x:int, y:int):void {
		// Draw a curve between two points. Compute control point by following an orthogal vector
		// from the midpoint of the L between p1 and p2 scaled by roundness * dist(p1, p2).
		// If concave is true, invert the curvature.

		var roundness:Number = 0.42; // approximates a quarter-circle
		var midX:Number = (lastXY[0] + x) / 2.0;
		var midY:Number = (lastXY[1]  + y) / 2.0;
		var cx:Number = midX + (roundness * (y - lastXY[1]));
		var cy:Number = midY - (roundness * (x - lastXY[0]));
		shape.graphics.curveTo(cx, cy, x, y);
		lastXY = [x, y];
	}

}}
