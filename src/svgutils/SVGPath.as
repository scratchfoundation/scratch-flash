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

// SVGPath.as
// John Maloney, June 2012.
//
// This utility class provides a static method to draw a simplified SVG path.
// It includes code to set the border, fill color, and gradient fill properties.
//
//
// Shane Clements, October 2012
// Turned into a non-static class extending the Array class so that it can be used
// as an Array of path commands by other classes.

package svgutils {
	import flash.display.*;
	import flash.geom.*;

	import svgeditor.objs.PathDrawContext;
	import svgeditor.tools.PixelPerfectCollisionDetection;

public dynamic class SVGPath extends Array {
	private const adjustmentFactor:Number = 0.5;
	private var dirty:Boolean;  // has the path been altered since it was loaded or exported?

	function SVGPath(...args) {
		var n:uint = args.length;
		if (n == 1 && (args[0] is Number)) {
			var dlen:Number = args[0];
			var ulen:uint = dlen;
			if(ulen != dlen) throw new RangeError("Array index is not a 32-bit unsigned integer ("+dlen+")");
			length = ulen;
		}
		else {
			length = n;
			for(var i:int=0; i < n; ++i)
				this[i] = args[i];
		}
		dirty = false;
	}

	public function clone():SVGPath {
		var p:SVGPath = new SVGPath(length);
		for(var i:int=0; i < length; ++i)
			p[i] = this[i].slice();

		return p;
	}

	public function set(cmds:Array):void {
		length = cmds.length;
		for(var i:int=0; i < length; ++i)
			this[i] = cmds[i];
	}

	public function setDirty():void {
		dirty = true;
	}

	static public const ADJUST:Object = {
		NONE:	0,
		NORMAL:	1,
		CORNER:	2
	};

	public function move(index:uint, pt:Point, adjust:uint = 1):void {
		if(index < length) {
			var cmd:Array = this[index];
			var ends:Array = getSegmentEndPoints(index);
			switch (cmd[0]) {
				case 'M':
				case 'L':
					cmd[1] = pt.x; cmd[2] = pt.y;
					dirty = true;
					break;
				case 'C':
					cmd[5] = pt.x; cmd[6] = pt.y;
					if(adjust == ADJUST.CORNER) {
						cmd[3] = pt.x; cmd[4] = pt.y;
					}
					dirty = true;
					break;
				case 'Q':
					// Unhandled!  All C cmds should be converted into Q cmds.
					trace("ERROR!"); throw new Error("Ack!");
					cmd[3] = pt.x; cmd[4] = pt.y;
					break;
			}

			// If we're moving the end point of a closed path, then move the first point too
			if(ends[2] && (cmd[0] == 'C' || cmd[0] == 'L') && index == ends[1] && ends[0] != index && this[ends[0]][0] == 'M') {
				move(ends[0], pt, ADJUST.NONE);
			}

			// Adjust the path?
			if(adjust == ADJUST.NORMAL)
				adjustPathAroundAnchor(index);
		}
	}

	public function transform(src:DisplayObject, dst:DisplayObject):void {
		for(var i:uint=0; i<length; ++i) {
			var cmd:Array = this[i];
			var pt:Point;
			switch (cmd[0]) {
				case 'C':
					pt = dst.globalToLocal(src.localToGlobal(new Point(cmd[5], cmd[6])));
					cmd[5] = pt.x; cmd[6] = pt.y;
				case 'Q':
					pt = dst.globalToLocal(src.localToGlobal(new Point(cmd[3], cmd[4])));
					cmd[3] = pt.x; cmd[4] = pt.y;
				case 'M':
				case 'L':
					pt = dst.globalToLocal(src.localToGlobal(new Point(cmd[1], cmd[2])));
					cmd[1] = pt.x; cmd[2] = pt.y;
					break;
			}
		}
	}

	public function remove(index:uint):void {
		if(index < length) {
			var ends:Array = getSegmentEndPoints(index);
			var p:Point;

			// If the point removed is on a closed path segment and it is the last point,
			// then move the first move command to match the new last point
			if(index == ends[1] && ends[2] && ends[0]>0 && this[ends[0] - 1][0] == 'M') {
				p = getPos(index - 1);
				this[ends[0] - 1] = ['M', p.x, p.y];
			}
			else if(index == ends[0] && !ends[2] && index < length - 1 && this[index][0] == 'M') {
				p = getPos(index + 1);
				this[index + 1] = ['M', p.x, p.y];
			}

			splice(index, 1);

			// Now adjust the path
			adjustPathAroundAnchor(Math.min(ends[1] - 1, index));
			dirty = true;
		}
	}

	public function add(index:uint, pt:Point, normal:Boolean):void {
		if(index < length) {
			var curve:Boolean = this[index][0] == 'C';
			if(!normal) curve = !curve;
			var cmd:Array;
			if(curve) {
				var indices:Array = getIndicesAroundAnchor(index, 2);
				var cPts1:Array = SVGPath.getControlPointsAdjacentAnchor(getPos(indices[0]), getPos(indices[1]), pt);
				var cPts2:Array = SVGPath.getControlPointsAdjacentAnchor(getPos(indices[1]), pt, getPos(indices[2]));

				// Keep the original control point from curve before the added curve
				if(this[index][0] == 'C') {
					cmd = this[index];
					cPts1[1].x = cmd[1];
					cPts1[1].y = cmd[2];
				}

				// Add the curve
				cmd = ['C', cPts1[1].x, cPts1[1].y, cPts2[0].x, cPts2[0].y, pt.x, pt.y];

				// Apply the second control point to the next cubic bezier curve if there is one
				if(this[indices[2]][0] == 'C') {
					var cmd2:Array = this[indices[2]];
					cmd2[1] = cPts2[1].x;
					cmd2[2] = cPts2[1].y;
				}
			} else {
				cmd = ['L', pt.x, pt.y];
			}
			splice(index, 0, cmd);

			// Now adjust the path
			adjustPathAroundAnchor(index);
			dirty = true;
		}
	}

	public function getPos(index:uint, time:Number = 1.0):Point {
		if(index < length) {
			var cmd:Array = this[index];
			switch (cmd[0]) {
				case 'M':
					return new Point(cmd[1], cmd[2]);
				case 'L':
					if(time > 0.999)
						return new Point(cmd[1], cmd[2]);
					else
						return getPosByTime(time, getPos(index-1), null, null, new Point(cmd[1], cmd[2]));
				case 'C':
					if(time > 0.999)
						return new Point(cmd[5], cmd[6]);
					else
						return getPosByTime(time, getPos(index-1),  new Point(cmd[1], cmd[2]),  new Point(cmd[3], cmd[4]), new Point(cmd[5], cmd[6]));
				case 'Q':
					// Unhandled!  All Q cmds should be converted into C cmds.
					trace("ERROR!"); throw new Error("Ack!");
					return new Point(cmd[3], cmd[4]);
				case 'Z':
					// Return the position of the first point
					var indices:Array = getSegmentEndPoints(index);
					if(indices[0] < index) {
						return getPos(indices[0]);
					}
					else {
						trace("ERROR! Couldn't find beginning of path.");
						return new Point();
					}
			}
		}

		return null;
	}

	public function adjustPathAroundAnchor(index:uint, proximity:uint = 1, strength:Number = 0.5):void {
		if(index >= length) return;

		var ends:Array = getSegmentEndPoints(index);
		// Handle the special 2-point path case
		var cmd:Array;
		if(!ends[2] && ends[1] - ends[0] == 1) {
			cmd = this[ends[1]];
			if(cmd[0] == 'C') {
				var p:Point = getPos(ends[0]);
				cmd[1] = p.x;
				cmd[2] = p.y;
				cmd[3] = cmd[5];
				cmd[4] = cmd[6];
			}
			return;
		}

		// Get additional indices for the before/after of the proximity edges
		var indices:Array = getIndicesAroundAnchor(index, proximity + 1);
		var midIdx:uint = indices.indexOf(index);
		var lastIdx:uint = indices.length - 1;
		var lastC2:Point;
		for(var i:uint = 1; i < lastIdx; ++i) {
			var before:Point = here ? here : getPos(indices[i - 1]);
			var here:Point = after ? after : getPos(indices[i]);
			var after:Point = getPos(indices[i + 1]);
			var cPts:Array = SVGPath.getControlPointsAdjacentAnchor(before, here, after);
			cmd = this[indices[i]];
			var currStr:Number = Math.pow(strength, 1+Math.abs(midIdx - i));
			if(!ends[2] && (indices[i] == ends[0] || indices[i] == ends[1]))
				currStr = 1;

			if(cmd[0] == 'C') {
				if(indices[i] == ends[1] && !ends[2]) {
					cmd[3] = here.x;
					cmd[4] = here.y;
				}
				else {
					var c1:Point = Point.interpolate(cPts[0], new Point(cmd[3], cmd[4]), currStr);
					cmd[3] = c1.x;
					cmd[4] = c1.y;
				}
			}
			else if(!ends[2] && cmd[0] == 'M'){
				cPts = SVGPath.getControlPointsAdjacentAnchor(before, before, here);
			}
			else {
				cPts = SVGPath.getControlPointsAdjacentAnchor(before, here, here.add(here.subtract(before)));
			}

			// Apply the second control point to the next cubic bezier curve if there is one
			var cmd2:Array = this[indices[i+1]];
			if(indices[i] != indices[i+1] && cmd2[0] == 'C') {
				var c2:Point = Point.interpolate(cPts[1], new Point(cmd2[1], cmd2[2]), currStr);
				cmd2[1] = c2.x;
				cmd2[2] = c2.y;
			}
		}
	}

	private function getIndicesAroundAnchor(index:uint, proximity:uint = 1):Array {
		var centerIndex:uint = index;
		var indices:Array = [];
		var ends:Array = getSegmentEndPoints(index);
		var closed:Boolean = ends[2];

		proximity = Math.min(Math.max(index - ends[0], ends[1] - index), proximity);
		// Walk down the path and store the indices
		for(var i:int = index - proximity; i <= index + proximity; ++i) {
			var realIndex:uint = i;
			if(i < ends[0] || (i == ends[0] && closed)) {
				if(closed)
					realIndex = ends[1] + (i - ends[0]);
				else
					continue;
			}
			else if(closed && i > ends[1]) {
				realIndex = ends[0] + (i - ends[1]);
			}
			else if(i > ends[1]) {
				continue;
			}

			if(i == index) centerIndex = realIndex;

			indices.push(realIndex);
		}

		// If we didn't get enough points then duplicate the points on the ends
		var indexPos:uint = indices.indexOf(centerIndex);
		var lastIndex:uint = indices.length - 1;
		if(indexPos < ends[0] + proximity) {
			indices.unshift(indices[0]);
		}
		if(lastIndex - indexPos < proximity) {
			indices.push(indices[indices.length-1]);
		}

		return indices;
	}

	public function getSegmentEndPoints(index:uint = 0):Array {
		index = Math.min(index, length - 1);
		var indices:Array = [index, index, false];

		var last:uint = index;
		i = index + 1;
		while(i <= length - 1 && this[i][0] != 'Z' && this[i][0] != 'M') {
			last = i;
			++i;
		}
		indices[1] = last;

		// Was it a closed path
		indices[2] = (i <= length - 1 && this[i][0] == 'Z');

		var first:uint = last;
		var i:int = last - 1;
		// TODO: handle nested closed segments
		while(i >= 0 && this[i][0] != 'Z' && this[first][0] != 'M') {
			first = i;
			--i;
		}
		indices[0] = first;

		return indices;
	}

	// Create control points on either side of an anchor point
	// Each handle is 1/3 the length of the segment on that side of the anchor
	// The vector of the handles is determined by the vector between the anchor points on either side of 'here'
	static public function getControlPointsAdjacentAnchor(before:Point, here:Point, after:Point):Array {
		var v1:Point = before.subtract(here);
		var c1l:Number = v1.length * 0.333;
		var v2:Point = after.subtract(here);
		var c2l:Number = v2.length * 0.333;
		var v3:Point = before.subtract(after);
		var v3l:Number = v3.length * 0.5;
		var r:Number = Math.min(1, v3l / (c1l + c2l));
		v3.normalize(r * Math.max(Math.min(c1l, v3l), c2l / 4));
		var c1:Point = here.add(v3);
		v3.normalize(r * Math.max(Math.min(c2l, v3l), c1l / 4))
		var c2:Point = here.subtract(v3);

		return [c1, c2];
	}

	public function isClosed():Boolean {
		return (length && this[length-1] is Array && this[length-1][0] == 'z');
	}

	public static function render(el:SVGElement, g:Graphics, forHitTest:Boolean = false):void {
		if (!el.path || el.path.length == 0) return;
		var cmds:Vector.<int> = new Vector.<int>;
		var points:Vector.<Number> = new Vector.<Number>;
		var lastX:Number = 0, lastY:Number = 0;
		var lastMove:Point = new Point();
		setBorderAndFill(g, el, gradientBoxForPath(el.path), forHitTest);
		for each (var cmd:Array in el.path) {
			switch (cmd[0]) {
				case 'C':
					drawCubicBezier(g,
						new Point(lastX, lastY),
						new Point(cmd[1], cmd[2]),
						new Point(cmd[3], cmd[4]),
						new Point(cmd[5], cmd[6]),
						cmds, points);
					break;
				case 'L':
					cmds.push(GraphicsPathCommand.LINE_TO);
					points.push(cmd[1], cmd[2]);
					break;
				case 'M':
					cmds.push(GraphicsPathCommand.MOVE_TO);
					points.push(cmd[1], cmd[2]);
					lastMove = new Point(cmd[1], cmd[2]);
					break;
				case 'Q':
					cmds.push(GraphicsPathCommand.CURVE_TO);
					points.push(cmd[1], cmd[2], cmd[3], cmd[4]);
					break;
				case 'Z':
					cmds.push(GraphicsPathCommand.LINE_TO);
					points.push(lastMove.x, lastMove.y);
					break;
			}
			lastX = cmd[cmd.length - 2];
			lastY = cmd[cmd.length - 1];
		}

		var fillRule:String = (el.getAttribute('fill-rule', 'nonzero') == 'nonzero') ? 'nonZero' : 'evenOdd';
		g.drawPath(cmds, points, fillRule);
		g.endFill();
//		debugDrawPoints(el.path, g);
	}

	public static function drawCubicBezier(g:Graphics, p0:Point, p1:Point, p2:Point, p3:Point, cmds:Vector.<int>, points:Vector.<Number>):void {
		// Approximate a a cubic Bezier with four quadratic ones.
		// Based on Timothee Groleau's Bezier_lib.as - v1.2, 19/05/02, which
		// uses a simplified version of the midPoint algorithm by Helen Triolo.
		// calculates the useful base points
		var pa:Point = Point.interpolate(p1, p0, 3/4);
		var pb:Point = Point.interpolate(p2, p3, 3/4);

		// compute 1/16 of the [p3, p0] segment
		var dx:Number = (p3.x - p0.x) / 16;
		var dy:Number = (p3.y - p0.y) / 16;

		// calculates control point 1
		var pc1:Point = Point.interpolate(p1, p0, 3/8);

		// calculates control point 2
		var pc2:Point = Point.interpolate(pb, pa, 3/8);
		pc2.x -= dx;
		pc2.y -= dy;

		// calculates control point 3
		var pc3:Point = Point.interpolate(pa, pb, 3/8);
		pc3.x += dx;
		pc3.y += dy;

		// calculates control point 4
		var pc4:Point = Point.interpolate(p2, p3, 3/8);

		// calculates the 3 anchor points
		var pa1:Point = Point.interpolate(pc1, pc2, 1/2);
		var pa2:Point = Point.interpolate(pa, pb, 1/2);
		var pa3:Point = Point.interpolate(pc3, pc4, 1/2);

		// draw the four quadratic subsegments
		if(cmds) {
			cmds.push(
				GraphicsPathCommand.CURVE_TO,
				GraphicsPathCommand.CURVE_TO,
				GraphicsPathCommand.CURVE_TO,
				GraphicsPathCommand.CURVE_TO);
			points.push(
				pc1.x, pc1.y, pa1.x, pa1.y,
				pc2.x, pc2.y, pa2.x, pa2.y,
				pc3.x, pc3.y, pa3.x, pa3.y,
				pc4.x, pc4.y, p3.x, p3.y);
		} else if(g) {
			g.curveTo(pc1.x, pc1.y, pa1.x, pa1.y);
			g.curveTo(pc2.x, pc2.y, pa2.x, pa2.y);
			g.curveTo(pc3.x, pc3.y, pa3.x, pa3.y);
			g.curveTo(pc4.x, pc4.y, p3.x, p3.y);
		}
	}

	// -----------------------------
	// Border, Fill, and Gradients
	//------------------------------
	private static var capConversion:Object = {
		butt:	CapsStyle.NONE,
		round:	CapsStyle.ROUND,
		square:	CapsStyle.SQUARE
	};

	public static function setBorderAndFill(g:Graphics, el:SVGElement, box:Rectangle, forHitTest:Boolean = false):void {
		var alpha:Number;

		var stroke:* = el.getAttribute('stroke');
		if (stroke && (stroke != 'none')) {
			alpha = Number(el.getAttribute('stroke-opacity', 1));
			alpha = Math.max(0, Math.min(alpha, 1));

			var capStyle:String = el.getAttribute('stroke-linecap', 'butt');
			if(capStyle in capConversion)
				capStyle = capConversion[capStyle];
			else
				capStyle = CapsStyle.NONE;

			if (stroke is SVGElement) setGradient(g, stroke, box, alpha, true, el.getAttribute('stroke-width', 1));
			else g.lineStyle(el.getAttribute('stroke-width', 1), el.getColorValue(stroke), alpha,
									false, "normal", capStyle, JointStyle.MITER);
		} else {
			g.lineStyle(NaN); // no line
		}

		var fill:* = el.getAttribute('fill', 'black');
		if (fill != 'none') {
			alpha = Number(el.getAttribute('fill-opacity', 1));
			alpha = Math.max(0, Math.min(alpha, 1));

			if (fill is SVGElement) setGradient(g, fill, box, alpha);
			else g.beginFill(el.getColorValue(fill), alpha);
		} else if(el.path && el.path.getSegmentEndPoints(0)[2] && !forHitTest) {
			// TODO: Make this only happen on objects spawned by the SVGEditor
			g.beginFill(0xFFFFFF, 0.01);
		}
	}

	private static function setGradient(g:Graphics, gradEl:SVGElement, box:Rectangle, alpha:Number, isLine:Boolean=false, lineWidth:Number=0):void {
		var colors:Array = [];
		var alphas:Array = [];
		var ratios:Array = [];
		var m:Matrix;
		for each (var stopEl:SVGElement in gradEl.subElements) {
			colors.push(stopEl.getColorValue(stopEl.getAttribute('stop-color', 0)));
			alphas.push(stopEl.getAttribute('stop-opacity', 1) * alpha);
			ratios.push(255 * stopEl.getAttribute('offset', 0));
		}

		// Fix old gradients which went to the wrong transparent color
		if(colors.length == 2) {
			if(alphas[0] == 0) colors[0] = colors[1];
			else if(alphas[1] == 0) colors[1] = colors[0];
		}

		if (colors.length == 0) {
			if(!isLine) g.beginFill(0x808080);
			else g.lineStyle(lineWidth, 0x808080);
		}
		else if (colors.length == 1) {
			if(!isLine) g.beginFill(gradEl.getColorValue(colors[0]));
			else g.lineStyle(lineWidth, gradEl.getColorValue(colors[0]));
		}
		else if (gradEl.tag == 'linearGradient') {
			m = linearGradientMatrix(gradEl, box);
			if(!isLine) g.beginGradientFill(GradientType.LINEAR, colors, alphas, ratios, m);
			else {
				g.lineStyle(lineWidth);
				g.lineGradientStyle(GradientType.LINEAR, colors, alphas, ratios, m);
			}
		}
		else if (gradEl.tag == 'radialGradient') {
			m = radialGradientMatrix(gradEl, box);
			if(!isLine) g.beginGradientFill(GradientType.RADIAL, colors, alphas, ratios, m, "pad", "rgb", gradEl.getAttribute('fpRatio', 0));
			else {
				g.lineStyle(lineWidth);
				g.lineGradientStyle(GradientType.RADIAL, colors, alphas, ratios, m, "pad", "rgb", gradEl.getAttribute('fpRatio', 0));
			}
		}
	}

	private static function linearGradientMatrix(gradEl:SVGElement, box:Rectangle):Matrix {
		var x1:Number = gradEl.getAttribute('x1', 0);
		var y1:Number = gradEl.getAttribute('y1', 0);
		var x2:Number = gradEl.getAttribute('x2', 0);
		var y2:Number = gradEl.getAttribute('y2', 0);
		var userSpace:Boolean = (gradEl.getAttribute('gradientUnits', '') == 'userSpaceOnUse');
		if (userSpace) {
			x1 = x1 / box.width;
			x2 = x2 / box.width;
			y1 = y1 / box.height;
			y2 = y2 / box.height;
		}
		var radians:Number = Math.atan2(y2 - y1, x2 - x1);
		var m:Matrix = new Matrix();
		m.createGradientBox(box.width, box.height, radians, box.x, box.y);
		return m;
	}

	private static function radialGradientMatrix(gradEl:SVGElement, box:Rectangle):Matrix {
		// Note: Ignores fx and fy; assumes focus at the center.
		var userSpace:Boolean = (gradEl.getAttribute('gradientUnits', '') == 'userSpaceOnUse');
		var rScale:Number = Math.max(0, gradEl.getAttribute('r', 0.5));
		var cx:Number = box.x + (box.width * gradEl.getAttribute('cx', 0.5));
		var cy:Number = box.y + (box.height * gradEl.getAttribute('cy', 0.5));
		var fx:Number = box.x + (box.width * gradEl.getAttribute('fx', gradEl.getAttribute('cx', 0.5)));
		var fy:Number = box.y + (box.height * gradEl.getAttribute('fy', gradEl.getAttribute('cy', 0.5)));
		if (userSpace) {
			rScale = Math.max(0, gradEl.getAttribute('r', 0)) / box.width;
			cx = gradEl.getAttribute('cx', box.width / 2);
			cy = gradEl.getAttribute('cy', box.height / 2);
			fx = gradEl.getAttribute('fx', cx);
			fy = gradEl.getAttribute('fy', cy);
		}

		// The radius is the maximum dimension of the box
		var rx:Number = box.width * rScale;
		var ry:Number = box.height * rScale;
		var focusX:Number = (fx - cx) / rx;
		var focusY:Number = (fy - cy) / ry;
		var focalPointAngle:Number = Math.atan2(focusY, focusX);
		var focalPointRatio:Number = Math.sqrt((focusX * focusX) + (focusY * focusY));
		// Unfortunately, this is the only way to hand this value back for the beginGradientFill call
		gradEl.setAttribute('fpRatio', focalPointRatio);

		var m:Matrix = new Matrix();
		m.createGradientBox(2 * rx, 2 * ry, focalPointAngle, cx - rx, cy - ry);
		return m;
	}

	private static function gradientBoxForPath(pathCmds:Array):Rectangle {
		// Return a Point containing the approximate width and height for the
		// the given path, not including its borders or the parts of curves that
		// bulge outside of their endpoints.
		// NOTE: Approximation acceptable for gradient fills, but not much else.
		var minX:Number, minY:Number, maxX:Number, maxY:Number;
		var firstCmd:Array = pathCmds[0];
		minX = maxX = firstCmd[1];
		minY = maxY = firstCmd[2];
		for each (var cmd:Array in pathCmds) {
			var x:Number = cmd[1];
			var y:Number = cmd[2];
			if (x < minX) minX = x;
			if (y < minY) minY = y;
			if (x > maxX) maxX = x;
			if (y > maxY) maxY = y;
		}
		return new Rectangle(minX, minY, maxX - minX, maxY - minY);
	}

	//////////////////////////////////////////////////////
	// From anchorpoints to Bezier
	/////////////////////////////////////////////////////
	public function fromAnchorPoints(points:Array):void {
		var first:Point = points[0];
		length = 0;
		this.push(['M', first.x, first.y]);
		if (points.length < 3 ) {
			this.push(['L', points[1].x, points[1].y]);
		}
		else {
			var ctx:PathDrawContext = new PathDrawContext();
			ctx.cmds = this;
			for (var i:uint = 1; i < points.length - 1; ++i)
				processSegment(points[i-1], points[i], points[i+1], ctx);

			// Choose whether to close the path (because the first and last points are "fairly close")
			var lastpoint:Point = points[points.length-1];
			var fairlyClose:Boolean = lastpoint.subtract(first).length < 10;
			if (fairlyClose) {
				processSegment(points[points.length-2], lastpoint, first, ctx);
				ctx.cmds.push(['z']);
			}
			else {
				processSegment(points[points.length-2], lastpoint, lastpoint, ctx);
			}
		}
	}

	public function pathIsClosed():Boolean {
		var s:Shape = new Shape();
		var g:Graphics = s.graphics;
		var lastCP:Point = new Point();

		// Pre-render to get ther path bounds
		g.lineStyle(0.5);
		for each(var cmd:Array in this)
			renderPathCmd(cmd, g, lastCP);

		var dRect:Rectangle = s.getBounds(s);
		dRect.width = Math.max(dRect.width, 1);
		dRect.height = Math.max(dRect.height, 1);

		// Adjust the path so that the top left is at 0,0 locally
		// This allows us to create the smallest bitmap for rendering it to
		var bmp:BitmapData = new BitmapData(dRect.width, dRect.height, true, 0);
		var m:Matrix = new Matrix(1, 0, 0, 1, -dRect.topLeft.x, -dRect.topLeft.y);

		// Clear the bitmap
		bmp.fillRect(bmp.rect, 0xFFFFFFFF);
		bmp.draw(s, m);
		// Try filling from the corners and see if there are any transparent pixels left
		// TODO: How can we easily improve this?  fill from next-to / near one of the end points?
		bmp.floodFill(0, 0, 0xFF000000);
		bmp.floodFill(0, bmp.height-1, 0xFF000000);
		bmp.floodFill(bmp.width-1, bmp.height-1, 0xFF000000);
		bmp.floodFill(bmp.width-1, 0, 0xFF000000);

		var colorRect:Rectangle = bmp.getColorBoundsRect(0xFFFFFFFF, 0xFFFFFFFF);
		bmp.dispose();

		if (colorRect != null && colorRect.size.length> 0) return true;
		else return false;
	}

	// Split a cubic bezier curve into two at t and
	// return the index of the command before the split
	public function splitCurve(index:uint, t:Number):uint {
//trace('splitCurve('+index+', '+t+')');
		if(index < 1)
			return 0;

		if(index >= length)
			return length - 1;

		if(t < 0.01)
			return index - 1;

		if(t > 0.99)
			return index;

		var cmd:Array = this[index];
		var p1:Point = getPos(index - 1);
		var p2:Point = getPos(index);
		var newCmd:Array;
		if(cmd[0] == 'C') {
//trace('Splitting curve #'+index+' @ '+t);
			var c1:Point = new Point(cmd[1], cmd[2]);
			var c2:Point = new Point(cmd[3], cmd[4]);
			var sp:Point = Point.interpolate(c2, c1, t);
			c1 = Point.interpolate(c1, p1, t);
			var nc2:Point = Point.interpolate(p2, c2, t);
			c2 = Point.interpolate(sp, c1, t);
			var nc1:Point = Point.interpolate(nc2, sp, t);
			p2 = Point.interpolate(nc1, c2, t);
			newCmd = cmd.slice(0);
			cmd[1] = c1.x;
			cmd[2] = c1.y;
			cmd[3] = c2.x;
			cmd[4] = c2.y;
			cmd[5] = p2.x;
			cmd[6] = p2.y;

			// Update the new curve command
			newCmd[1] = nc1.x;
			newCmd[2] = nc1.y;
			newCmd[3] = nc2.x;
			newCmd[4] = nc2.y;
			splice(index + 1, 0, newCmd);
		}
		else if(cmd[0] == 'L') {
			var np:Point = Point.interpolate(p2, p1, t);
			splice(index, 0, ['L', np.x, np.y]);
		}

		return index;
	}

	public function removeInvalidSegments(strokeWidth:Number):void {
		var minWidth:Number = Math.min(Math.max(1, strokeWidth * 0.2), 5);
		var i:int = 0;
		// Remove any segments with very short lengths
		while(i<length) {
			var indices:Array = getSegmentEndPoints(i);
			var start:Point = getPos(indices[0]);
			var next:int = indices[0]+1;
			var len:int = indices[1] - indices[0];
			if(len>0) {
				var dist:Number = start.subtract(getPos(next)).length;
				if(getPos(indices[1]).subtract(start).length < minWidth && dist < minWidth) {
					do {
						splice(next, 1);
						--len;
						if(next < length)
							dist+= start.subtract(getPos(next)).length;
					} while(dist < minWidth && len>1);
					if(len < 2)
						splice(indices[0], len+1);
					else
						i = indices[1] + 1;
				}
				else {
					i = indices[1] + 1;
				}
			}
			else {
				splice(indices[0], 1);
			}
		}
	}

	public function reversePath(indexInSegment:uint = 0):void {
		var indices:Array = getSegmentEndPoints(indexInSegment);
		var newCmds:Array = new Array(indices[1] - indices[0] + (indices[2] ? 2 : 1));
		var lastCmd:Array = null;
		var j:int = 0;
		for(var i:int=indices[1]; i>=indices[0]; --i) {
			var cmd:Array = this[i];
			var pos:Point = getPos(i);
			var newCmd:Array;
			if(lastCmd == null) {
				newCmd = ['M', pos.x, pos.y];
			}
			else if(lastCmd[0] == 'C') {
				newCmd = ['C', lastCmd[3], lastCmd[4], lastCmd[1], lastCmd[2], pos.x, pos.y];
			}
			else if(lastCmd[0] == 'L') {
				newCmd = ['L', pos.x, pos.y];
			}
			else {
				throw new Error('Invalid path command!');
			}

			newCmds[j] = newCmd;
			lastCmd = cmd;
			++j;
		}

		if(indices[2])
			newCmds[j] = ['Z'];

		// Delete existing commands
		newCmds.unshift(newCmds.length);

		// Insert new commands at beginning of segment
		newCmds.unshift(indices[0]);

		super.splice.apply(this, newCmds);
	}

	static public function getPosByTime(ratio:Number, p1:Point, cp1:Point, cp2:Point, p2:Point):Point {
		// Do Bezier
		if(cp1) {
			ratio = 1 - ratio;
			function b1(t:Number):Number { return t*t*t }
			function b2(t:Number):Number { return 3*t*t*(1-t) }
			function b3(t:Number):Number { return 3*t*(1-t)*(1-t) }
			function b4(t:Number):Number { return (1-t)*(1-t)*(1-t) }
			return new Point(p1.x*b1(ratio) + cp1.x*b2(ratio) + cp2.x*b3(ratio) + p2.x*b4(ratio),
				p1.y*b1(ratio) + cp1.y*b2(ratio) + cp2.y*b3(ratio) + p2.y*b4(ratio));
		}
		else {
			return Point.interpolate(p2, p1, ratio);
		}
	}

	// Draw segment takes 3 anchor points to draw an SVG "S" command
	// as a Cubic Bezier ("C" command in SVG) curve with:
	// the first control as the flip of the last curve 2nd control point
	// and the second control from the internal calculation (specific to our UI)
	// the end point is the current anchor point in the loop
	// (the start point is the previous point)
	static private const tolerance:Number = 1;
	private function processSegment(before:Point, here:Point, after:Point, ctx:PathDrawContext):void {
		var l1:Number = before.subtract(here).length;
		var l2:Number = here.subtract(after).length;
		var l3:Number = before.subtract(after).length;
		var l:Number = l3 / (l1 + l2);
		var min:Number = Math.min(l1,l2);
		//if ((l1 + l2) >  3 * l3)	l = 0;

		// This is the key equation that creates a control point
		var vTangent:Point = getCurveTangent(before, here, after);
		var fudge:Number = l * l * min * 0.666 ; // needs more work on the fudge factor
		vTangent.x *= fudge;
		vTangent.y *= fudge;
		var c1:Point = ctx.acurve ? before.add(before.subtract(ctx.lastcxy)) : before;
		var c2:Point = here.subtract(vTangent);

		getQuadraticBezierPoints(before, c1, c2, here, ctx);
		ctx.acurve = true;
		ctx.lastcxy = c2;
	}

	// This is actually the tangent vector at "here" in the direction from "here" to "after"
	static private function getCurveTangent(before:Point, here:Point, after:Point):Point {
		var beforev:Point = before.subtract(here);
		var afterv:Point =  after.subtract(here);
		beforev.normalize(1.0);
		afterv.normalize(1.0);
		var bisect:Point = beforev.add(afterv);
		var perp:Point = new Point(-bisect.y, bisect.x);
		if (perp.x * afterv.x + perp.y * afterv.y < 0) perp = new Point(-perp.x, -perp.y);
		return perp;
	}

	// functions below were take from com.lorentz.SVG.utils.Bezier
	// and addapted for our purposes
	private function getQuadraticBezierPoints(a:Point, b:Point, c:Point, d:Point, ctx:PathDrawContext):void {
		// find intersection between bezier arms
		var s:Point = intersect2Lines(a, b, c, d);
		if (s && !isNaN(s.x) && !isNaN(s.y) && !ctx.adjust) {
			// find distance between the midpoints
			var dx:Number = (a.x + d.x + s.x * 4 - (b.x + c.x) * 3) * .125;
			var dy:Number = (a.y + d.y + s.y * 4 - (b.y + c.y) * 3) * .125;

			// Don't split the curve if the quadratic is close enough
			if (dx*dx + dy*dy <= tolerance*tolerance) {
				// end recursion and save points
				ctx.cmds.push(['Q', s.x, s.y, d.x, d.y]);
				return;
			}
		} else {
			var mp:Point = Point.interpolate(a, d, 0.5);
			if(Point.distance(a, mp) <= tolerance || ctx.adjust) {
				ctx.cmds.push(['Q', mp.x, mp.y, d.x, d.y]);
				return;
			}
		}

		var halves:Object = bezierSplit(a, b, c, d);
		var b0:Object = halves.b0;
		var b1:Object = halves.b1;

		// recursive call to subdivide curve
		getQuadraticBezierPoints(a, b0.b, b0.c, b0.d, ctx);
		getQuadraticBezierPoints(b1.a, b1.b, b1.c, d, ctx);
	}

	static private function intersect2Lines(p1:Point, p2:Point, p3:Point, p4:Point):Point {
		var x1:Number = p1.x; var y1:Number = p1.y;
		var x4:Number = p4.x; var y4:Number = p4.y;

		var dx1:Number = p2.x - x1;
		var dx2:Number = p3.x - x4;

		if (!dx1 && !dx2) return null; // new Point(NaN, NaN);

		var m1:Number = (p2.y - y1) / dx1;
		var m2:Number = (p3.y - y4) / dx2;

		if (!dx1) return new Point(x1, m2 * (x1 - x4) + y4);
		else if (!dx2) return new Point(x4, m1 * (x4 - x1) + y1);

		var xInt:Number = (-m2 * x4 + y4 + m1 * x1 - y1) / (m1 - m2);
		var yInt:Number = m1 * (xInt - x1) + y1;

		return new Point(xInt, yInt);
	}

	static private function bezierSplit(p0:Point, p1:Point, p2:Point, p3:Point):Object {
		var p01:Point = Point.interpolate(p0, p1, 0.5);
		var p12:Point = Point.interpolate(p1, p2, 0.5);
		var p23:Point = Point.interpolate(p2, p3, 0.5);
		var p02:Point = Point.interpolate(p01, p12, 0.5);
		var p13:Point = Point.interpolate(p12, p23, 0.5);
		var p03:Point = Point.interpolate(p02, p13, 0.5);
		return {b0:{a:p0,  b:p01, c:p02, d:p03},
			b1:{a:p03, b:p13, c:p23, d:p3}};
	}

	static public function renderPathCmd(cmd:Array, g:Graphics, lastCP:Point, startP:Point = null):void {
		switch (cmd[0]) {
			case 'C':
				SVGPath.drawCubicBezier(g,
					new Point(lastCP.x, lastCP.y),
					new Point(cmd[1], cmd[2]),
					new Point(cmd[3], cmd[4]),
					new Point(cmd[5], cmd[6]),
					null, null);
				break;
			case 'L':
				g.lineTo(cmd[1], cmd[2]);
				break;
			case 'M':
				g.moveTo(cmd[1], cmd[2]);
				if(startP) {
					startP.x = cmd[1];
					startP.y = cmd[2];
				}
				break;
			case 'Q':
				g.curveTo(cmd[1], cmd[2], cmd[3], cmd[4]);
				break;
			case 'Z':
				if(startP)
					g.lineTo(startP.x, startP.y);
				break;
		}
		lastCP.x = cmd[cmd.length - 2];
		lastCP.y = cmd[cmd.length - 1];
	}

	/* debugging */
	private static function debugDrawPoints(cmds:Array, g:Graphics):void {
		g.lineStyle(); // no outline
		for each (var cmd:Array in cmds) {
			var len:int = cmd.length;
			g.beginFill(0xFF);
			g.drawCircle(cmd[len - 2], cmd[len - 1], 3);
			g.beginFill(0xFFFF00);
			if (cmd.length > 3) g.drawCircle(cmd[1], cmd[2], 2);
			g.beginFill(0xFF00FF);
			if (cmd.length > 5) g.drawCircle(cmd[3], cmd[4], 2);
		}
	}

	public function outputCommands(start:int=0, end:int=-1):void {
		if(end==-1) end=length-1;
		for(var k:int=start; k<=end; ++k) {
			var c:Array = this[k];
			trace('Command #'+k+': '+c.join(','));
		}
	}
}}
