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

package svgeditor.tools
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.CapsStyle;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.JointStyle;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import svgeditor.ImageEdit;
	import svgeditor.objs.ISVGEditable;
	import svgeditor.objs.PathDrawContext;
	import svgeditor.objs.SVGShape;
	
	import svgutils.SVGElement;
	import svgutils.SVGPath;

	public final class PathEditTool extends SVGEditTool
	{
		private var pathElem:SVGElement;
		private var controlPoints:Array;
		private var toolsLayer:Sprite;
		private var currentEndPoints:Array;

		public function PathEditTool(ed:ImageEdit) {
			super(ed, ['path', 'rect', 'ellipse', 'circle']);
			reset();
		}

		override protected function init():void {
			super.init();
			showPathPoints();
		}

		override protected function shutdown():void {
			super.shutdown();
			PathEndPointManager.removeEndPoints();
		}
		
		private function reset():void {
			pathElem = null;
			controlPoints = null;
		}

		override public function refresh():void {
			if(!object) return;

			var obj:ISVGEditable = object;
			edit(null, currentEvent);
			edit(obj, currentEvent);
		}

		////////////////////////////////////////
		// UI Path editing Adding Points
		///////////////////////////////////////
		override protected function edit(obj:ISVGEditable, event:MouseEvent):void {
			// Select a new object?  or add a point
			if(obj != object) {
				PathEndPointManager.removeEndPoints();
				currentEndPoints = null;
				if(object) {
					for(var i:uint = 0; i< controlPoints.length; ++i)
						removeChild(controlPoints[i]);
					
					reset();
				}

				super.edit(obj, event);
				if(object) {
					pathElem = object.getElement();

					// Convert non-path elements to path elements
					if(pathElem.tag != 'path') {
						pathElem.convertToPath();
						object.redraw();
					}

					showPathPoints();
				}
				return;
			}

			if(object) {
				var indx:int = (object as SVGShape).getPathCmdIndexUnderMouse();
				if(indx < 0) return;
				
				// Add the new point
				var dObj:DisplayObject = (object as DisplayObject);
				addPoint(indx, new Point(dObj.mouseX, dObj.mouseY));
			}
		}
		
		// SVG Element access
		private function getAttribute(attr:String):* {
			return pathElem.getAttribute(attr);
		}

		/////////////////////////////////////////////////////////////
		//  Path editing
		////////////////////////////////////////////////////////////
		private function showPathPoints():void{
			if(controlPoints && controlPoints.length) {
				for each(var cp:PathAnchorPoint in controlPoints) {
					removeChild(cp);
				}
			}
			controlPoints = [];
			if (!object || !parent) return;

			var len:int = pathElem.path.length;
			var i:int = 0;
			var endPoints:Array = pathElem.path.getSegmentEndPoints(0);
			for (var j:uint = 0; j < len; ++j) {
				if(j > endPoints[1]) endPoints = pathElem.path.getSegmentEndPoints(j);
				if(!validAnchorIndex(j)) continue;
				var ep:Boolean = !endPoints[2] && (j == endPoints[0] || j == endPoints[1]);
				controlPoints.push(
					getAnchorPoint(j, ep)
				);
				++i;
			}
		}

		private function resetControlPointIndices():void {
			var len:int = pathElem.path.length;
			var i:int = 0;
			var endPoints:Array = pathElem.path.getSegmentEndPoints(0);
			for (var j:uint = 0; j < len; ++j) {
				if(j > endPoints[1]) endPoints = pathElem.path.getSegmentEndPoints(j);
				if(!validAnchorIndex(j)) continue;
				controlPoints[i].index = j;
				controlPoints[i].endPoint = !endPoints[2] && (j == endPoints[0] || j == endPoints[1]);
				++i;
			}
		}

		private function redrawObj(bSkipSave:Boolean = false):void {
			object.redraw();

			// The object changed!
			if(!bSkipSave)
				dispatchEvent(new Event(Event.CHANGE));
		}

		public function moveControlPoint(index:uint, bFirst:Boolean, p:Point, bDone:Boolean = false):void {
			if(index < pathElem.path.length && pathElem.path[index][0] == 'C') {
				p = (object as DisplayObject).globalToLocal(p);
				var cmd:Array = pathElem.path[index];
				if(bFirst) {
					cmd[1] = p.x;
					cmd[2] = p.y;
				}
				else {
					cmd[3] = p.x;
					cmd[4] = p.y;
				}
				redrawObj(!bDone);
			}
		}

		private var movingPoint:Boolean;
		public function movePoint(index:uint, p:Point, bDone:Boolean = false):void {
			var dObj:DisplayObject = object as DisplayObject;
			p = dObj.globalToLocal(p);
			pathElem.path.move(index, p);
			redrawObj(!bDone);

			if(bDone) {
				currentEndPoints = pathElem.path.getSegmentEndPoints(index);
				if(!currentEndPoints[2]) {
					// TODO: Make a generic way to test whether it's close enough to the other end-point
					// TODO: Add a visual effect for before the stop moving the point to show that it
					// is going to close the path
					var w:Number = 2 * (getAttribute("stroke-width") || 1);
					if((currentEndPoints[0] == index &&
						pathElem.path.getPos(index).subtract(pathElem.path.getPos(currentEndPoints[1])).length < w) ||
						(currentEndPoints[1] == index &&
							pathElem.path.getPos(index).subtract(pathElem.path.getPos(currentEndPoints[0])).length < w)) {
						
						// Close the path and refresh the anchor points
						pathElem.path.splice(currentEndPoints[1] + 1, 0, ['Z']);
						pathElem.path.adjustPathAroundAnchor(currentEndPoints[1], 1, 1);
						pathElem.path.adjustPathAroundAnchor(currentEndPoints[1], 1, 1);
						redrawObj(!bDone);
						refresh();
					}
					else {
						dObj.visible = false;
						var retval:Object = getContinuableShapeUnderMouse(getAttribute("stroke-width") || 1);
						dObj.visible = true;
						if(retval && (object as SVGShape).connectPaths(retval.shape)) {
							(retval.shape as DisplayObject).parent.removeChild((retval.shape as DisplayObject));
							(object as SVGShape).redraw();
							refresh();
						}
					}
				}
				movingPoint = false;
				PathEndPointManager.removeEndPoints();
			}
			else if(!movingPoint) {
				currentEndPoints = pathElem.path.getSegmentEndPoints(index);
				if(!currentEndPoints[2] && (index == currentEndPoints[0] || index == currentEndPoints[1])) 
					PathEndPointManager.makeEndPoints(dObj);
				movingPoint = true;
			}

			// TODO: enable this when the user is altering control points
			for(var i:uint=0; i<numChildren; ++i) {
				dObj = getChildAt(i);
				if(dObj is PathControlPoint) {
					(dObj as PathControlPoint).refresh();
				}
			}
		}

		public function removePoint(index:uint, event:MouseEvent):void {
			var endPoints:Array = pathElem.path.getSegmentEndPoints(index);

			// Get the control point index
			var len:int = pathElem.path.length;
			var cp_idx:int = 0;
			for (var j:uint = 0; j < len; ++j) {
				if(!validAnchorIndex(j)) continue;
				if(j == index) {
					break;
				}
				++cp_idx;
			}

			// If we want to prevent removing 2-point paths by removing a point,
			// then uncomment this code:
			//if(endPoints[1] - endPoints[0] < 2) return;
			
			// Cut the path here if the shift key was down and the point is not an end-point
			var pos:Point;
			if((index < endPoints[1] || (endPoints[2] && index == endPoints[1])) && index > endPoints[0] && event.shiftKey) {
				var intersections:Array = (object as SVGShape).getAllIntersectionsWithShape(controlPoints[cp_idx], true);
				var pos1:Point = pathElem.path.getPos(intersections[0].start.index, intersections[0].start.time);
				var pos2:Point = pathElem.path.getPos(intersections[0].end.index, intersections[0].end.time);
				pathElem.path.move(index, pos1, SVGPath.ADJUST.NONE);
				pathElem.path.splice(index + 1, 0, ['M', pos2.x, pos2.y]);

				if(endPoints[2]) {
					// Bind a segment which had closed the path to the beginning of the path
					// Copy the commands but not the ending 'Z' command
					var indices:Array = pathElem.path.getSegmentEndPoints(index + 1);
					var cmds:Array = pathElem.path.splice(indices[0], indices[1] + 1);
					cmds.length--;
					var stitchIndex:int = cmds.length - 1;
					
					// Re-insert the commands at the beginning
					cmds.unshift(1);
					cmds.unshift(0);
					pathElem.path.splice.apply(pathElem.path, cmds);
					
					pathElem.path.adjustPathAroundAnchor(stitchIndex, 2);
					pathElem.path.adjustPathAroundAnchor(0, 2);
					endPoints = pathElem.path.getSegmentEndPoints(0);

					var fill:* = pathElem.getAttribute('fill');
					if(fill != 'none' && pathElem.getAttribute('stroke') == 'none') {
						pathElem.setAttribute('stroke', fill);
					}
					pathElem.setAttribute('fill', 'none');
				}
				else if(index <= endPoints[1]){
					// Make a copy to hold the path after the point
					var newPath:SVGShape = (object as SVGShape).clone() as SVGShape;
					(object as SVGShape).parent.addChildAt(newPath, (object as SVGShape).parent.getChildIndex(object as DisplayObject));
					
					// TODO: Make work with inner paths???
					// TODO: Handle closed paths!
					newPath.getElement().path.splice(0, index + 1);
					newPath.redraw();
	
					// Now truncate the existing path
					pathElem.path.length = index + 1;
				}

				// Reset everything
				refresh();
			}
			else {
				removeChild(controlPoints[cp_idx]);
				controlPoints.splice(cp_idx, 1);

				pathElem.path.remove(index);
				if(index == endPoints[1] && endPoints[2]) {
					// If we just removed the end point of a closed path then move the
					// first command, a move command, to the last point on the path
					pos = pathElem.path.getPos(index - 1);
					pathElem.path[endPoints[0]][1] = pos.x;
					pathElem.path[endPoints[0]][2] = pos.y;
				}

				// Shift the indices of the control points after the deleted point
				resetControlPointIndices();
			}

			if(controlPoints.length == 1) {
				var dObj:DisplayObject = object as DisplayObject;
				dObj.parent.removeChild(dObj);
				setObject(null);
				dispatchEvent(new Event(Event.CHANGE));
			}
			else {
				redrawObj();
			}
		}

		// TODO: Make it so that we can add points AT the Z command when it's preceded by an L command
		private function validAnchorIndex(index:uint):Boolean {
			var ends:Array = pathElem.path.getSegmentEndPoints(index);
			if(pathElem.path[index][0] == 'Z' || (ends[2] && index == ends[0]))
				return false;
			return true;
		}

		private function addPoint(index:uint, pt:Point, isLine:Boolean = false):void {
			var dObj:DisplayObject = (object as DisplayObject);
			var len:int = pathElem.path.length;
			var i:int = 0;
			var cp:PathAnchorPoint;
			for (var j:uint = 0; j < len; ++j) {
				if(!validAnchorIndex(j)) continue;
				if(j == index) {
					pathElem.path.add(j, pt, !currentEvent.shiftKey);
					cp = getAnchorPoint(j, false);
					controlPoints.splice(i, 0, cp);
					break;
				}
				++i;
			}
			
			// Shift the indices of the control points after the inserted point
			resetControlPointIndices();
			redrawObj();

			// Allow the user to drag the new control point
			if(cp) {
				cp.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OVER));
				cp.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN));
			}
		}

		private function getAnchorPoint(idx:uint, endPoint:Boolean):PathAnchorPoint{
			var pt:Point = globalToLocal((object as DisplayObject).localToGlobal(pathElem.path.getPos(idx)));
			var pap:PathAnchorPoint = new PathAnchorPoint(this, idx, endPoint);
			pap.x = pt.x;
			pap.y = pt.y;
			addChild(pap);
			return pap;
		}

		public function getControlPoint(idx:uint, first:Boolean):PathControlPoint{
			var pcp:PathControlPoint = null;
			if(pathElem.path[idx][0] == 'C') {
				var cmd:Array = pathElem.path[idx];
				var pt:Point = getControlPos(idx, first);
				pcp = new PathControlPoint(this, idx, first);
				pcp.x = pt.x;
				pcp.y = pt.y;
				addChild(pcp);
			}
			return pcp;
		}

		public function getControlPos(idx:uint, first:Boolean):Point {
			var pt:Point = null;
			if(pathElem.path[idx][0] == 'C') {
				var cmd:Array = pathElem.path[idx];
				pt = new Point(first ? cmd[1] : cmd[3], first ? cmd[2] : cmd[4]);
				pt = globalToLocal((object as DisplayObject).localToGlobal(pt));
			}

			return pt;
		}
	}
}
