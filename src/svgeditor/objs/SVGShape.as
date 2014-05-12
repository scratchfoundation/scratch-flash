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

package svgeditor.objs
{
	import flash.display.*;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import svgeditor.objs.ISVGEditable;
	import svgeditor.tools.PixelPerfectCollisionDetection;
	
	import svgutils.SVGDisplayRender;
	import svgutils.SVGElement;
	import svgutils.SVGExport;
	import svgutils.SVGImporter;
	import svgutils.SVGPath;

	public class SVGShape extends Shape implements ISVGEditable
	{
		private var element:SVGElement;

		public function SVGShape(elem:SVGElement) {
			element = elem;
		}

		public function getElement():SVGElement {
			element.transform = transform.matrix;
			return element;
		}

		public function redraw(forHitTest:Boolean = false):void {
			graphics.clear();
			element.renderPathOn(this, forHitTest);
		}

		public function clone():ISVGEditable {
			var copy:ISVGEditable = new SVGShape(element.clone());
			(copy as DisplayObject).transform.matrix = transform.matrix.clone();
			copy.redraw();
			return copy;
		}

		private var collisionState:Boolean;
		private var testWidth:Number = 2.0;
		private var interval:Number = 0.1;
		private var eraserMode:Boolean = false;
		public var debugMode:Boolean = false;
		public var distCheck:Number = 0.05;
		static public var bisectionDistCheck:Number = 0.05;
		static public var eraserDistCheck:Number = 0.5;
		public function getAllIntersectionsWithShape(otherShape:DisplayObject, forEraser:Boolean=false):Array {
			var intersections:Array = [];
			var g:Graphics = graphics;
			var path:SVGPath = getElement().path;
			var startPos:Point = path.getPos(0);
			collisionState = false;
			eraserMode = forEraser;
			var maxCmdDist1:Number = 10;
			var maxCmdDist2:Number = 10;
			var distInterval:Number = 0.75;
			for(var i:int=1; i<path.length; ++i) {
				g.clear();
				g.moveTo(startPos.x, startPos.y);
				setTestStroke();
				SVGPath.renderPathCmd(path[i], g, startPos);
				if(PixelPerfectCollisionDetection.isColliding(this, otherShape)) {
					findIntersections(i, otherShape, intersections);
				}
				else if(collisionState) {
					intersections[intersections.length-1].end = {index: i-1, time: 1};
					collisionState = false;
				}
			}

			if(collisionState) {
				intersections[intersections.length-1].end = {index: i-1, time: 1};
				collisionState = false;
			}

			return intersections;
		}

		private function setTestStroke():void {
			if(eraserMode)
				graphics.lineStyle(element.getAttribute('stroke-width', 1), 0, 1, true, "normal", CapsStyle.ROUND, JointStyle.MITER);
			else
				graphics.lineStyle(testWidth, 0, 1, false, "normal", CapsStyle.NONE, JointStyle.MITER, 0);
		}

		private function findIntersections(index:int, otherShape:DisplayObject, intersections:Array):void {
			if(debugMode) {
				var y:Number = 0;
				if(debugCD) {
					y = debugCD.y + debugCD.height;
				}
				debugCD = new Sprite();
				parent.addChild(debugCD);
			}

			var path:SVGPath = element.path;			
			var cmd:Array = path[index];
			var p1:Point = path.getPos(index-1);
			var p2:Point = path.getPos(index);
			if(cmd[0] == 'C' || cmd[0] == 'L') {
				var c1:Point = (cmd[0] == 'C' ? new Point(cmd[1], cmd[2]) : null);
				var c2:Point = (cmd[0] == 'C' ? new Point(cmd[3], cmd[4]) : null);

				var minDist:Number = interval * 2;
				var time:Number = 0;
				var curr:Object = null;
				interval = 0.1;
				while(time > -1) {
					time = getNextCollisionChange(time, p1, c1, c2, p2, otherShape);
					if(time > -1) {
						if(collisionState) {
							// Should we make sure that we've moved at least a certain amount?
							//if(!curr || time - curr.end.time > minDist) {
								curr = {start:{index: index, time: time}};
								intersections.push(curr);
								interval = Math.min(0.1, interval * 32);
							//}
						}
						else {
							intersections[intersections.length-1].end = {index: index, time: time};
							interval = 0.1;
						}
						//trace('intersecting at ('+time+')');
					} else {
						break;
					}
				}
			}
			
			showIntersections(intersections);
		}

		private function getNextCollisionChange(time:Number, p1:Point, cp1:Point, cp2:Point, p2:Point, otherShape:DisplayObject):Number {
			var g:Graphics = graphics;
//trace('getNextCollisionChange('+time+', '+interval+')');
			for(var i:Number=time + interval; i<=1.0; i+= interval) {
				g.clear();
				var ct:Number = i - interval;
				var pt:Point = SVGPath.getPosByTime(ct - interval, p1, cp1, cp2, p2);
				g.moveTo(pt.x, pt.y);
				setTestStroke();
				//if(npt) trace("Moving "+npt.subtract(SVGPath.getPosByTime(i, p1, cp1, cp2, p2)).length+" @ t="+i);
				var npt:Point = SVGPath.getPosByTime(i, p1, cp1, cp2, p2);
				g.lineTo(npt.x, npt.y);
				var colliding:Boolean = PixelPerfectCollisionDetection.isColliding(this, otherShape);//, false, debugCD);
				if(colliding != collisionState) {
					//trace("At time "+ct+" colliding="+colliding)
					if(npt.subtract(pt).length > distCheck) {
						// Recurse to get a more precise time
						interval *= 0.5;
						return getNextCollisionChange(ct, p1, cp1, cp2, p2, otherShape); 
					}
					else {
						collisionState = colliding;
						return colliding ? i - interval : ct;
					}
				}
			}
			
			return -1;
		}

		public function getPathCmdIndexUnderMouse():int {
			if(!element.path || element.path.length < 2)
				return -1;

			var canvas:Shape = new Shape();
			var g:Graphics = canvas.graphics;
			var w:Number = element.getAttribute("stroke-width");
			// TODO: Make this better by making the bitmap size scale if current element is scaled
			w = Math.max(8, (isNaN(w) ? 12 : w) + 2);
			g.lineStyle(w, 0xff00FF, 1, true, "normal", CapsStyle.ROUND, JointStyle.MITER);

			var forceLines:Boolean = (element.path.length < 3 );
			var dRect:Rectangle = getBounds(this);
			
			// Adjust the path so that the top left is at 0,0 locally
			// This allows us to create the smallest bitmap for rendering it to
			var bmp:BitmapData = new BitmapData(dRect.width, dRect.height, true, 0);
			var m:Matrix = new Matrix(1, 0, 0, 1, -dRect.topLeft.x, -dRect.topLeft.y);
			
			var lastCP:Point = new Point();
			var startP:Point = new Point();
			var mousePos:Point = new Point(mouseX, mouseY);
			var index:int = -1;
			var max:uint = element.path.length - 1;
			for(var i:uint = 0; i <= max; ++i) {
				// Clear the bitmap
				bmp.fillRect(bmp.rect, 0x00000000);
				
				// Draw the path up until point #i
				SVGPath.renderPathCmd(element.path[i], g, lastCP, startP);
				
				// Return this index if the mouse location has been drawn on
				bmp.draw(canvas, m);
				if(bmp.hitTest(dRect.topLeft, 0xFF, mousePos)) {
					index = i;
					break;
				}
			}
			
			bmp.dispose();
			return index;
		}

		// Walk the path an try removing any commands to see if they change the shape too much
		public function smoothPath(maxRatio:Number):void {
			// Remove the fill so that we're only checking changes in the stroke changing
			var fill:String = getElement().getAttribute('fill');
			getElement().setAttribute('fill', 'none');
			var stroke:String = getElement().getAttribute('stroke');
			if(stroke == 'none')
				getElement().setAttribute('stroke', 'black');

			// Take a snapshot
			redraw();
			var rect:Rectangle = getBounds(stage);
			var img:BitmapData = new BitmapData(rect.width, rect.height, true, 0x00000000);
			var m:Matrix = transform.concatenatedMatrix.clone();
			m.translate(-rect.x, -rect.y);
			
			var removedPoint:Boolean = false;
			var start:Number = (new Date).getTime();
			var elem:SVGElement = getElement();
			do {
				var index:uint = 1;
				removedPoint = false;
				var dirty:Boolean;
				while(index < elem.path.length) {
					// Skip Move and Close commands
					if(elem.path[index][0] == 'Z' || elem.path[index][0] == 'M') {
						++index;
						continue;
					}

					redraw();
					img.fillRect(img.rect, 0);
					img.draw(this, m);
					img.threshold(img, img.rect, new Point, "<", 0xF0000000, 0, 0xF0000000);
					
					var cmd:Array = elem.path[index];
					elem.path.splice(index, 1);
					elem.path.adjustPathAroundAnchor(index, 3, 1);
					redraw();
					
					img.draw(this, m, null, BlendMode.ERASE);
					img.threshold(img, img.rect, new Point, "<", 0xF0000000, 0, 0xF0000000);
					var r:Rectangle = img.getColorBoundsRect(0xFF000000, 0xFF000000, true);
					if(r && r.width > 1 && r.height > 1) {
						var pixelCount:uint = 0;
						for(var i:uint = r.left; i<r.right; ++i)
							for(var j:uint = r.top; j<r.bottom; ++j)
								if((img.getPixel32(i, j)>>24) & 0xF0)
									++pixelCount;
						var len:Number = (new Point(r.width, r.height)).length;
						var ratio:Number = pixelCount / len;
						//trace(r + '    '+ratio + ' > '+maxRatio + ' '+ (ratio > maxRatio ? 'SAVED' : 'DISCARDED'));
						if(ratio > maxRatio) {
							elem.path.splice(index, 0, cmd);
							elem.path.adjustPathAroundAnchor(index);
						}
						else {
							removedPoint = true;
						}
					} else {
						removedPoint = true;
					}
					elem.path.adjustPathAroundAnchor(index, 3, 1);
					elem.path.adjustPathAroundAnchor(index, 3, 1);
					elem.path.adjustPathAroundAnchor(index, 3, 1);
					++index;
				}
			} while(removedPoint)
			img.dispose();

			// Reset stroke and fill then redraw
			getElement().setAttribute('stroke', stroke);
			getElement().setAttribute('fill', fill);
			redraw();
			trace('smoothPath() took '+((new Date).getTime() - start)+'ms.');
		}

		// Walk the path an try removing any commands to see if they change the shape too much
		public function smoothPath2(maxRatio:Number):void {
			maxRatio *= 0.01;

			// Remove the fill so that we're only checking changes in the stroke changing
			var elem:SVGElement = getElement();
			var fill:String = elem.getAttribute('fill');
			elem.setAttribute('fill', 'none');
			var stroke:String = elem.getAttribute('stroke');
			var strokeWidth:String = elem.getAttribute('stroke-width');
			if(stroke == 'none') {
				elem.setAttribute('stroke', 'black');
				elem.setAttribute('stroke-width', 2);
			}
			
			// Take a snapshot
			redraw();
			var rect:Rectangle = getBounds(stage);
			var img:BitmapData = new BitmapData(rect.width, rect.height, true, 0x00000000);
			var img2:BitmapData = img.clone();
			var m:Matrix = transform.concatenatedMatrix.clone();
			m.translate(-rect.x, -rect.y);

			// Render for comparison
			img.draw(this, m);
			img.threshold(img, img.rect, new Point, "<", 0xF0000000, 0, 0xF0000000);

			// Count the pixels painted
			var or:Rectangle = img.getColorBoundsRect(0xFF000000, 0xFF000000, true);
			var totalPixels:uint = 0;
			for(var i:uint = or.left; i<or.right; ++i)
				for(var j:uint = or.top; j<or.bottom; ++j)
					if((img.getPixel32(i, j)>>24) & 0xF0)
						++totalPixels;
			
			var removedPoint:Boolean = false;
			var start:Number = (new Date).getTime();
			var passCount:uint = 0;
			var endPointDistFromEnd:uint = elem.path.length - elem.path.getSegmentEndPoints()[1];
			do {
//trace('Starting pass #'+(passCount+1));
				var tries:uint = elem.path.length - endPointDistFromEnd;
				var index:uint = 1;
				removedPoint = false;
				var dirty:Boolean;
				while(tries) {
					--tries;
					// Pick a random command to try to remove
					index = Math.floor(Math.random() * (elem.path.length - endPointDistFromEnd));

					// Skip Move and Close commands
					if(elem.path[index][0] == 'Z' || elem.path[index][0] == 'M') {
						//++index;
						continue;
					}

					// Get a fresh copy of the original render
					img2.copyPixels(img, img.rect, new Point);
					
					var cmd:Array = elem.path[index];
					elem.path.splice(index, 1);
					elem.path.adjustPathAroundAnchor(index, 3, 1);
					redraw();
					
					img2.draw(this, m, null, BlendMode.ERASE);
					img2.threshold(img, img.rect, new Point, "<", 0xF0000000, 0, 0xF0000000);
					var r:Rectangle = img.getColorBoundsRect(0xFF000000, 0xFF000000, true);
					if(r && r.width > 1 && r.height > 1) {
//trace(or + ' : ' + r);
						var pixelCount:uint = 0;
						for(i = r.left; i<r.right; ++i)
							for(j = r.top; j<r.bottom; ++j)
								if((img2.getPixel32(i, j)>>24) & 0xF0)
									++pixelCount;
						var ratio:Number = pixelCount / totalPixels;
//trace('Cmd #'+index+'    '+ratio + ' > '+maxRatio + ' '+ (ratio > maxRatio ? 'SAVED' : 'DISCARDED'));
						if(ratio > maxRatio) {
							elem.path.splice(index, 0, cmd);
							elem.path.adjustPathAroundAnchor(index);
						}
						else {
							removedPoint = true;
						}
					} else {
						removedPoint = true;
					}
					elem.path.adjustPathAroundAnchor(index, 3, 1);
					elem.path.adjustPathAroundAnchor(index, 3, 1);
					elem.path.adjustPathAroundAnchor(index, 3, 1);
					//++index;
				}
				++passCount;
			} while(removedPoint)
			img.dispose();
			img2.dispose();
			
			// Reset stroke and fill then redraw
			elem.setAttribute('stroke', stroke);
			elem.setAttribute('stroke-width', strokeWidth);
			elem.setAttribute('fill', fill);
			redraw();
//trace('smoothPath() took '+((new Date).getTime() - start)+'ms.  '+elem.path.length+' commands left.');
		}

		// Debugging stuff!
		static private var debugShape:Shape;
		static private var debugCD:Sprite;
		public function showIntersections(intersections:Array):void {
			if(debugMode) {
				if(debugShape) {
					if(debugShape.parent)
						debugShape.parent.removeChild(debugShape);
					debugShape.graphics.clear();
				}
				else {
					debugShape = new Shape();
					debugShape.alpha = 0.25;
					//debugShape.x = 15;
				}
				parent.addChild(debugShape);
				debugShape.transform = transform;
			}
			
			for(var i:int=0; i<intersections.length; ++i) {
				var section:Object = intersections[i];
				var stopTime:Number = (section.end && section.start.index == section.end.index) ? section.end.time : 1.0;
				showPartialCurve(section.start.index, section.start.time, stopTime);
				if(section.end && section.start.index != section.end.index) {
					if(section.end.index > section.start.index + 1) {
						for(var j:int=section.start.index+1; j<section.end.index; ++ j)
							showPartialCurve(j, 0, 1);
					}
					showPartialCurve(section.end.index, 0, section.end.time);
				}
			}
		}
		
		public function showPoints():void {
			debugShape.graphics.lineStyle(2, 0x00CCFF);
			for(var j:int=0; j<element.path.length; ++j) {
				var pt:Point = element.path.getPos(j);
				debugShape.graphics.drawCircle(pt.x, pt.y, 3);
			}
		}
		
		private function showPartialCurve(index:int, start:Number, stop:Number):void {
			if(!debugMode)
				return;

			var cmd:Array = element.path[index];
			var p1:Point = element.path.getPos(index-1);
			var c1:Point = new Point(cmd[1], cmd[2]);
			var c2:Point = new Point(cmd[3], cmd[4]);
			var p2:Point = new Point(cmd[5], cmd[6]);
			var g:Graphics = debugShape.graphics;
			var pt:Point = SVGPath.getPosByTime(start, p1, c1, c2, p2);
			var overlap:Number = interval;
			g.moveTo(pt.x, pt.y);
			g.lineStyle(5, 0xFF0000, 0.7, true, "normal", CapsStyle.NONE, JointStyle.MITER);
			for(var i:Number=start; i<=stop; i += interval) {
				//g.clear();
				var percComp:Number = (i - start) / Math.min(stop - start, 0.01);
				pt = SVGPath.getPosByTime(i - interval - overlap, p1, c1, c2, p2);
				//g.moveTo(pt.x, pt.y);
				//var grn:int = ((1 - percComp) * 0xFF) << 8;
				//g.lineStyle(5, 0xFF0000 + grn, 0.5, false, "normal", CapsStyle.NONE, JointStyle.MITER, 0);
				
				pt = SVGPath.getPosByTime(i, p1, c1, c2, p2);
				g.lineTo(pt.x, pt.y);
			}
		}

		public function connectPaths(otherShape:SVGShape):Boolean {
			var otherElem:SVGElement = otherShape.getElement();
			var strokeWidth:Number = element.getAttribute('stroke-width', 1);

			var endPts:Array = otherElem.path.getSegmentEndPoints();
			if(endPts[2])
				return false;

			var otherStart:Point = otherShape.localToGlobal(otherElem.path.getPos(endPts[0]));
			var otherEnd:Point = otherShape.localToGlobal(otherElem.path.getPos(endPts[1]));

			endPts = element.path.getSegmentEndPoints();
			if(endPts[2])
				return false;

			var thisStart:Point = localToGlobal(element.path.getPos(endPts[0]));
			var thisEnd:Point = localToGlobal(element.path.getPos(endPts[1]));
			var indexContinued:uint = 0;
			var endContinued:Boolean = false;
			if(thisEnd.subtract(otherStart).length < strokeWidth * 2) {
				indexContinued = endPts[1];
				endContinued = true;
			}
			else if(thisEnd.subtract(otherEnd).length < strokeWidth * 2) {
				indexContinued = endPts[1];
				otherElem.path.reversePath();
				endContinued = true;
			}
			else if(thisStart.subtract(otherEnd).length < strokeWidth * 2) {
				indexContinued = endPts[0];
			}
			else if(thisStart.subtract(otherStart).length < strokeWidth * 2) {
				indexContinued = endPts[0];
				otherElem.path.reversePath();
			}

			// Setup the arguments to call splice() on the existing path
			otherElem.path.transform(otherShape, this);
			var args:Array = otherElem.path.concat();
			if(endContinued)
				args.shift();
			
			args.unshift(endContinued ? 0 : 1);
			
			var insertIndex:int = (endContinued ? indexContinued + 1 : indexContinued);
			args.unshift(insertIndex);
			
			// Insert the curve commands
			var pc:SVGPath = element.path;
			pc.splice.apply(pc, args);
			
			// Close the path?
			endPts = element.path.getSegmentEndPoints();
			if(element.path.getPos(endPts[0]).subtract(element.path.getPos(endPts[1])).length < strokeWidth * 2) {
				element.path.splice(endPts[1] + 1, 0, ['Z']);
				element.path.adjustPathAroundAnchor(endPts[1]);
				element.path.adjustPathAroundAnchor(endPts[0]);
			}
			return true;
		}
	}
}