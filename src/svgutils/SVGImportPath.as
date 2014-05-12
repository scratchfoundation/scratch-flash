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

// SVGImportPath.as
// John Maloney, June 2012
//
// Generate an array of simplified, absolute path commands for an SVG shape or
// line element such as a circle, ellipse, line, paths, polygons, and polylines.
// A simplified path contains only M, L, C, and Q commands with absolute coordinates.
//
// Using a standard path format simplifies the rendering and editing code.
	
package svgutils {
	import flash.geom.Point;

public class SVGImportPath {

	// -----------------------------
	// Generate path commands for circles, ellipses, lines, polylines, polygon, and rects.
	//------------------------------

	public function generatePathCmds(el:SVGElement):void {
		// Generate a path command list for the given element, if applicable.
		switch (el.tag) {
		case 'circle': el.path = cmdsForCircleOrEllipse(el); break;
		case 'ellipse': el.path = cmdsForCircleOrEllipse(el); break;
		case 'line': el.path = cmdsForLine(el); break;
		case 'path': el.path = cmdsForPath(el); break;
		case 'polygon': el.path = cmdsForPolygon(el); break;
		case 'polyline': el.path = cmdsForPolyline(el); break;
		case 'rect': el.path = cmdsForRect(el); break;
		}
	}

	private function cmdsForCircleOrEllipse(el:SVGElement):SVGPath {
		// Approximate ellipse with four Cubic Beziers.
		var cx:Number = el.getAttribute('cx', 100);
		var cy:Number = el.getAttribute('cy', 100);
		var rx:Number, ry:Number;
		if ('circle' == el.tag) {
			rx = ry = el.getAttribute('r', 10);
		} else {
			rx = el.getAttribute('rx', 10);
			ry = el.getAttribute('ry', 5);
		}

		var path:SVGPath = new SVGPath(['M', cx, cy - ry],
			quarterCircle(true, cx, cy - ry, cx + rx, cy),
			quarterCircle(false, cx + rx, cy, cx, cy + ry),
			quarterCircle(true, cx, cy + ry, cx - rx, cy),
			quarterCircle(false, cx - rx, cy, cx, cy - ry),['Z']);
	
		path.splitCurve(1, 0.5);
		path.splitCurve(3, 0.5);
		path.splitCurve(5, 0.5);
		path.splitCurve(7, 0.5);
		return path;
	}

	private function quarterCircle(xFirst:Boolean, srcX:Number, srcY:Number, dstX:Number, dstY:Number):Array {
		// Approximate a quarter ellipse using a cubic Bezier curve, based on
		// "Approximating a Circle or an Ellipse Using Four Bezier Cubic Splines" by Don Lancaster.
		const k:Number = 0.551784; // magic constant
		var dx:Number = dstX - srcX;
		var dy:Number = dstY - srcY;
		return xFirst ?
			['C', srcX + (k * dx), srcY, dstX, dstY - (k * dy), dstX, dstY] :
			['C', srcX, srcY + (k * dy), dstX - (k * dx), dstY, dstX, dstY];
	}
	
	private function cmdsForLine(el:SVGElement):SVGPath {
		return new SVGPath(
			['M', el.getAttribute('x1', 0), el.getAttribute('y1', 0)],
			['L', el.getAttribute('x2', 0), el.getAttribute('y2', 0)]);
	}

	private function cmdsForPolygon(el:SVGElement):SVGPath {
		var result:SVGPath = cmdsForPolyline(el);
		if (result.length == 0) return new SVGPath();
		var firstCmd:Array = result[0];
		result.push(['L', firstCmd[1], firstCmd[2]]); // close the polygon
		return result;
	}

	private function cmdsForPolyline(el:SVGElement):SVGPath {
		var result:SVGPath = new SVGPath();
		var points:Array = el.extractNumericArgs(el.getAttribute('points', ''));
		if (points.length < 4) return new SVGPath();
		result.push(['M', points[0], points[1]]);
		for (var i:int = 2; i < (points.length - 1); i += 2) {
			result.push(['L', points[i], points[i + 1]]);
		}
		return result;
	}

	private function cmdsForRect(el:SVGElement):SVGPath {
		var left:Number = el.getAttribute('x', 0);
		var top:Number = el.getAttribute('y', 0);
		var w:Number = el.getAttribute('width', 10);
		var h:Number = el.getAttribute('height', 10);
		return new SVGPath(
			['M', left, top],
			['L', left + w, top],
			['L', left + w, top + h],
			['L', left, top + h],
			['L', left, top],['Z']);
	}

	// -----------------------------
	// Parse an SVG path and generate an array of simplified, absolute path commands.
	//------------------------------

	private var firstMove:Boolean;
	private var startX:Number;
	private var startY:Number;
	private var lastX:Number;
	private var lastY:Number;
	private var lastCX:Number;
	private var lastCY:Number;

	private function cmdsForPath(el:SVGElement):SVGPath {
		// Convert an SVG path to a Flash-friendly version that contains only absolute
		// move, line, cubic, and quadratic curve commands (M, L, C, Q). The output is
		// an array of command arrays of the form [<cmd> args...].
		var result:SVGPath = new SVGPath();
		firstMove = true;
		startX = startY = 0;
		lastX = lastY = 0;
		lastCX = lastCY = 0;
		var svgPath:String = el.getAttribute('d');
		for each(var cmdString:String in svgPath.match(/[A-DF-Za-df-z][^A-Za-df-z]*/g)) {
			var cmd:String = cmdString.charAt(0);
			var args:Array = el.extractNumericArgs(cmdString.substr(1));
			var argCount:int = pathCmdArgCount[cmd];
			if (argCount == 0) {
				result.push(simplePathCommand(cmd, args));
				continue;
			}
			if (('m' == cmd.toLowerCase()) && (args.length > 2)) {
				// Special case: If 'M' or 'm' has more than 2 arguments, the
				// extra arguments are for an implied 'L' or 'l' line command.
				result.push(simplePathCommand(cmd, args));
				args = args.slice(2);
				cmd = ('M' == cmd) ? 'L' : 'l';
			}
			while (args.length >= argCount) { // sequence commands of the same kind (with command letter omitted)
				result.push(simplePathCommand(cmd, args));
				args = args.slice(argCount);
			}
		}
		return result;
	}

	private const pathCmdArgCount:Object = {
		A: 7, a: 7,
		C: 6, c: 6,
		H: 1, h: 1,
		L: 2, l: 2,
		M: 2, m: 2,
		Q: 4, q: 4,
		S: 4, s: 4,
		T: 2, t: 2,
		V: 1, v: 1,
		Z: 0, z: 0
	}

	private function simplePathCommand(cmd:String, args:Array):Array {
		// Return a simple path command for the given SVG command letter
		// and arguments, converting relative commands to absolute ones.
		// The resulting command is an array consists of a letter from the
		// set {M, L, C, Q} followed by two to six numeric arguments.
		switch (cmd) {
		case 'A': return arcCmd(args, false);
		case 'a': return arcCmd(args, true);
		case 'C': return cubicCurveCmd(args, false);
		case 'c': return cubicCurveCmd(args, true);
		case 'H': return hLineCmd(args[0]);
		case 'h': return hLineCmd(lastX + args[0]);
		case 'L': return lineCmd(absoluteArgs(args));
		case 'l': return lineCmd(relativeArgs(args));
		case 'M': return moveCmd(absoluteArgs(args));
		case 'm': return moveCmd(relativeArgs(args));
		case 'Q': return quadraticCurveCmd(args, false);
		case 'q': return quadraticCurveCmd(args, true);
		case 'S': return cubicCurveSmoothCmd(args, false);
		case 's': return cubicCurveSmoothCmd(args, true);
		case 'T': return quadraticCurveSmoothCmd(args, false);
		case 't': return quadraticCurveSmoothCmd(args, true);
		case 'V': return vLineCmd(args[0]);
		case 'v': return vLineCmd(lastY + args[0]);
		case 'Z':
		case 'z': return ['Z'];
		}
		trace('Unknown path command: ' + cmd); // unknown path command; should not happen
		return ['M', lastX, lastY];	// return a command that has no effect
	}

	private function absoluteArgs(args:Array):Array {
		lastX = args[0];
		lastY = args[1];
		return args;
	}

	private function relativeArgs(args:Array):Array {
		lastX += args[0];
		lastY += args[1];
		return args;
	}

	private function arcCmd(args:Array, isRelative:Boolean):Array {
		// ToDo: Arcs not fully supported because they're quite complicated.
		// An partial solution that works for many uses of the arc command
		// found in Inkscape files is to use a cubic Bezier curve to approximate
		// a half-circle. Although this is not correct for partial arc segments
		// (i.e. in pie charts) or ellipses, the Inkscape ellipse tool generates
		// a pair of arc commands, so a semi-circle is often correct in practice
		// (e.g. for small dots or eyes). This is just a placeholder until we
		// have a chance to do a correct implementation.
		var startX:Number = lastX;
		var startY:Number = lastY;
		lastX = isRelative ? lastX + args[5] : args[5];
		lastY = isRelative ? lastY + args[6] : args[6];
		var d:Number = Point.distance(new Point(startX, startY), new Point(lastX, lastY));
		var unit:Point = new Point((lastX - startX) / d, (lastY - startY) / d);
		var normal:Point = new Point(unit.y, -unit.x);
		var c1x:Number = startX + (2/3 * d * normal.x) + (0.05 * unit.x);
		var c1y:Number = startY + (2/3 * d * normal.y) + (0.05 * unit.y);
		var c2x:Number = lastX + (2/3 * d * normal.x) - (0.05 * unit.x);
		var c2y:Number = lastY + (2/3 * d * normal.y) - (0.05 * unit.y);
		return ['C', c1x, c1y, c2x, c2y, lastX, lastY];
	}

	private function closePath():Array {
		lastX = startX;
		lastY = startY;
		firstMove = true;
		return ['L', lastX, lastY];
	}

	private function hLineCmd(endX:Number):Array {
		lastX = endX;
		return ['L', lastX, lastY];
	}

	private function lineCmd(args:Array):Array {
		return ['L', lastX, lastY];
	}

	private function moveCmd(args:Array):Array {
		if (firstMove) {
			startX = lastX;
			startY = lastY;
			lastCX = lastX;
			lastCY = lastY;
			firstMove = false;
		}
		return ['M', lastX, lastY];
	}

	private function vLineCmd(endY:Number):Array {
		lastY = endY;
		return ['L', lastX, lastY];
	}

	private function cubicCurveCmd(args:Array, isRelative:Boolean):Array {
		// 'C' or 'c' command. Args: cx1 cy1 cx2 cy2 x y
		var c1x:Number = isRelative ? lastX + args[0] : args[0];
		var c1y:Number = isRelative ? lastY + args[1] : args[1];
		lastCX = isRelative ? lastX + args[2] : args[2];
		lastCY = isRelative ? lastY + args[3] : args[3];
		lastX = isRelative ? lastX + args[4] : args[4];
		lastY = isRelative ? lastY + args[5] : args[5];
		return ['C', c1x, c1y, lastCX, lastCY, lastX, lastY];
	}

	private function cubicCurveSmoothCmd(args:Array, isRelative:Boolean):Array {
		// 'S' or 's' command. Args: cx2 cy2 x y
		var c1x:Number = lastX + (lastX - lastCX);
		var c1y:Number = lastY + (lastY - lastCY);
		lastCX = isRelative ? lastX + args[0] : args[0];
		lastCY = isRelative ? lastY + args[1] : args[1];
		lastX = isRelative ? lastX + args[2] : args[2];
		lastY = isRelative ? lastY + args[3] : args[3];
		return ['C', c1x, c1y, lastCX, lastCY, lastX, lastY];
	}

	private function quadraticCurveCmd(args:Array, isRelative:Boolean):Array {
		// 'Q' or 'q' command. Args: cx cy x y
		var p0x:Number = lastX;
		var p0y:Number = lastY;
		lastCX = isRelative ? lastX + args[0] : args[0];
		lastCY = isRelative ? lastY + args[1] : args[1];
		lastX = isRelative ? lastX + args[2] : args[2];
		lastY = isRelative ? lastY + args[3] : args[3];
		var c1x:Number = p0x + (lastCX - p0x) * 2/3;
		var c1y:Number = p0y + (lastCY - p0y) * 2/3;
		var c2x:Number = lastX + (lastCX - lastX) * 2/3;
		var c2y:Number = lastY + (lastCY - lastY) * 2/3;
		
		return ['C', c1x, c1y, c2x, c2y, lastX, lastY];
	}

	private function quadraticCurveSmoothCmd(args:Array, isRelative:Boolean):Array {
		// 'T' or 't' command. Args: x y
		// Control point is the reflection of the last control point through the last endpoint.
		var p0x:Number = lastX;
		var p0y:Number = lastY;
		lastCX = lastX + (lastX - lastCX);
		lastCY = lastY + (lastY - lastCY);
		lastX = isRelative ? lastX + args[0] : args[0];
		lastY = isRelative ? lastY + args[1] : args[1];
		var c1x:Number = p0x + (lastCX - p0x) * 2/3;
		var c1y:Number = p0y + (lastCY - p0y) * 2/3;
		var c2x:Number = lastX + (lastCX - lastX) * 2/3;
		var c2y:Number = lastY + (lastCY - lastY) * 2/3;
		
		return ['C', c1x, c1y, c2x, c2y, lastX, lastY];
	}

}}
