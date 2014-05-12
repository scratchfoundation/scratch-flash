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
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import svgeditor.ImageEdit;
	import svgeditor.objs.ISVGEditable;
	import svgeditor.objs.SVGShape;

	public class PathAnchorPoint extends Sprite
	{
		// Standard anchor point
		static private const h_fill:uint = 0xCCCCCC; // highlight version
		static private const fill:uint = 0xFFFFFF;

		// End point anchor
		static private const ep_h_fill:uint = 0xCCEECC; // highlight version
		static private const ep_fill:uint = 0xDDFFDD;

		static private const stroke:uint = 0x28A5DA;
		static private const h_opacity:Number = 1.0; // highlight version
		static private const opacity:Number = 0.6;
		private var pathEditTool:PathEditTool;
		private var _index:uint;
		private var controlPoints:Array;
		private var isEndPoint:Boolean;
		public function PathAnchorPoint(editTool:PathEditTool, idx:uint, endPoint:Boolean) {
			pathEditTool = editTool;
			_index = idx;
			isEndPoint = endPoint;

			render(graphics, false, isEndPoint);
			makeInteractive();

			// TODO: enable this when the user is altering control points
			if(false) {
				var pcp:PathControlPoint = editTool.getControlPoint(idx, true);
				if(pcp) {
					controlPoints = [];
					controlPoints.push(pcp);
					controlPoints.push(editTool.getControlPoint(idx, false));
					addEventListener(Event.REMOVED, removedFromStage);
				}
			}
		}

		public function set index(idx:uint):void {
			_index = idx;
			if(controlPoints) {
				controlPoints[0].index = idx;
				controlPoints[1].index = idx;
			}
		}

		public function get index():uint {
			return _index;
		}

		public function set endPoint(ep:Boolean):void {
			isEndPoint = ep;
			render(graphics, false, isEndPoint);
		}
		
		public function get endPoint():Boolean {
			return isEndPoint;
		}
		
		private function removedFromStage(e:Event):void {
			if(e.target != this) return;
			
			removeEventListener(Event.REMOVED, removedFromStage);
			pathEditTool.removeChild(controlPoints.pop());
			pathEditTool.removeChild(controlPoints.pop());
		}

		static public function render(g:Graphics, highlight:Boolean = false, endPoint:Boolean = false):void {
			g.clear();
			g.lineStyle(1, stroke, (highlight ? h_opacity : opacity));
			var f:uint;
			if(endPoint)
				f = highlight ? ep_h_fill : ep_fill;
			else
				f = highlight ? h_fill : fill;
			g.beginFill(f, (highlight ? h_opacity : opacity));
			g.drawCircle(0, 0, 5);
			g.endFill();
		}

		private function makeInteractive():void {
			addEventListener(MouseEvent.MOUSE_DOWN, eventHandler);
			addEventListener(MouseEvent.MOUSE_OVER, toggleHighlight);
			addEventListener(MouseEvent.MOUSE_OUT, toggleHighlight);
		}

		private var wasMoved:Boolean = false;
		private var canDelete:Boolean = false;
		private function eventHandler(event:MouseEvent):void {
			var p:Point;
			switch(event.type) {
				case MouseEvent.MOUSE_DOWN:
					stage.addEventListener(MouseEvent.MOUSE_MOVE, arguments.callee);
					stage.addEventListener(MouseEvent.MOUSE_UP, arguments.callee);
					wasMoved = false;
					canDelete = !isNaN(event.localX);
					break;
				case MouseEvent.MOUSE_MOVE:
					p = new Point(stage.mouseX, stage.mouseY);
					pathEditTool.movePoint(index, p);
					p = pathEditTool.globalToLocal(p);
					x = p.x;
					y = p.y;
					wasMoved = true;
					break;
				case MouseEvent.MOUSE_UP:
					stage.removeEventListener(MouseEvent.MOUSE_MOVE, arguments.callee);
					stage.removeEventListener(MouseEvent.MOUSE_UP, arguments.callee);

					// Save the path
					p = new Point(x, y);
					p = pathEditTool.localToGlobal(p);
					pathEditTool.movePoint(index, p, true);

					if(!wasMoved && canDelete) pathEditTool.removePoint(index, event);
					break;
			}
		}

		private function toggleHighlight(e:MouseEvent):void{
			render(graphics, e.type == MouseEvent.MOUSE_OVER, isEndPoint);
		}
	}
}