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
	import svgeditor.tools.PathEndPointManager;
	import svgeditor.objs.ISVGEditable;
	import svgeditor.objs.SVGShape;

	public class PathEndPoint extends Sprite
	{
		private var editor:ImageEdit;
		private var shape:SVGShape;
		private var strokeWidth:Number;
		public function PathEndPoint(ed:ImageEdit, a:SVGShape, p:Point) {
			editor = ed;
			shape = a;
			x = p.x;
			y = p.y;

			addEventListener(MouseEvent.MOUSE_OVER, toggleHighlight, false, 0 , true);
			addEventListener(MouseEvent.MOUSE_OUT, toggleHighlight, false, 0 , true);
			addEventListener(MouseEvent.MOUSE_DOWN, proxyEvent, false, 0 , true);
			addEventListener(MouseEvent.MOUSE_MOVE, showOrb, false, 0 , true);

			graphics.clear();
			graphics.beginFill(0, 0);
			graphics.drawCircle(0, 0, 10);
			graphics.endFill();
		}

		private function toggleHighlight(e:MouseEvent):void {
			PathEndPointManager.toggleEndPoint(e.type == MouseEvent.MOUSE_OVER, new Point(x, y));
			editor.getWorkArea().dispatchEvent(e);

			if(e.type == MouseEvent.MOUSE_OVER) {
				strokeWidth = editor.getShapeProps().strokeWidth;
			}
		}

		private function proxyEvent(e:MouseEvent):void {
			editor.getCanvasLayer().dispatchEvent(e);
			e.stopImmediatePropagation();
		}

		private function showOrb(e:MouseEvent):void {
			var w:Number = (strokeWidth + shape.getElement().getAttribute('stroke-width', 1)) / 4;
			PathEndPointManager.updateOrb((new Point(mouseX, mouseY)).length < w);
		}
	}
}
