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
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import svgeditor.ImageEdit;
	import svgeditor.objs.ISVGEditable;
	import svgeditor.objs.SVGShape;

	public class PathControlPoint extends Sprite
	{
		static private const h_fill:uint = 0xDDDDDD; // highlight version
		static private const fill:uint = 0xCCFF33;
		static private const stroke:uint = 0x28A5DA;
		static private const h_opacity:Number = 1.0; // highlight version
		static private const opacity:Number = 0.6;
		private var pathEditTool:PathEditTool;
		public var index:uint;
		private var bFirst:Boolean;
		public function PathControlPoint(editTool:PathEditTool, idx:uint, first:Boolean) {
			pathEditTool = editTool;
			index = idx;
			bFirst = first;

			render(graphics);
			makeInteractive();
		}

		static public function render(g:Graphics, highlight:Boolean = false):void {
			g.clear();
			g.lineStyle(1, stroke, (highlight ? h_opacity : opacity));
			g.beginFill((highlight ? h_fill : fill), (highlight ? h_opacity : opacity));
			g.drawCircle(0, 0, 5);
			g.endFill();
		}

		public function refresh():void {
			var pt:Point = pathEditTool.getControlPos(index, bFirst);
			x = pt.x;
			y = pt.y;
		}

		private function makeInteractive():void {
			addEventListener(MouseEvent.MOUSE_DOWN, eventHandler);
			addEventListener(MouseEvent.MOUSE_OVER, toggleHighlight);
			addEventListener(MouseEvent.MOUSE_OUT, toggleHighlight);
		}

		private function eventHandler(event:MouseEvent):void {
			var p:Point;
			switch(event.type) {
				case MouseEvent.MOUSE_DOWN:
					stage.addEventListener(MouseEvent.MOUSE_MOVE, arguments.callee);
					stage.addEventListener(MouseEvent.MOUSE_UP, arguments.callee);
					break;
				case MouseEvent.MOUSE_MOVE:
					p = new Point(stage.mouseX, stage.mouseY);
					pathEditTool.moveControlPoint(index, bFirst, p);
					p = pathEditTool.globalToLocal(p);
					x = p.x;
					y = p.y;
					break;
				case MouseEvent.MOUSE_UP:
					// Save the path
					p = new Point(stage.mouseX, stage.mouseY);
					pathEditTool.moveControlPoint(index, bFirst, p);

					stage.removeEventListener(MouseEvent.MOUSE_MOVE, arguments.callee);
					stage.removeEventListener(MouseEvent.MOUSE_UP, arguments.callee);
					break;
			}
		}

		private function toggleHighlight(e:MouseEvent):void{
			render(graphics, e.type == MouseEvent.MOUSE_OVER);
		}
	}
}