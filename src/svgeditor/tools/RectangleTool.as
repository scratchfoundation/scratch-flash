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
	import flash.geom.Point;
	
	import svgeditor.ImageEdit;
	import svgeditor.DrawProperties;
	import svgeditor.objs.SVGShape;
	
	import svgutils.SVGElement;

	public final class RectangleTool extends SVGCreateTool
	{
		private var createOrigin:Point;
		private var newElement:SVGElement;

		public function RectangleTool(svgEditor:ImageEdit) {
			super(svgEditor);
		}

		override protected function mouseDown(p:Point):void {
			// If we're trying to draw with invisible settings then bail
			var props:DrawProperties = editor.getShapeProps();
			if(props.alpha == 0)
				return;

			createOrigin = p;

			newElement = new SVGElement('rect', null);
			if(props.filledShape) {
				newElement.setShapeFill(props);
				newElement.setAttribute('stroke', 'none');
			}
			else {
				newElement.setShapeStroke(props);
				newElement.setAttribute('fill', 'none');
			}

			newObject = new SVGShape(newElement);
			contentLayer.addChild(newObject as DisplayObject);
		}
		
		override protected function mouseMove(p:Point):void {
			if(!createOrigin) return;

			var ofs:Point = createOrigin.subtract(p);
			var w:Number = Math.abs(ofs.x);
			var h:Number = Math.abs(ofs.y);

			// Shift key makes a square
			if(currentEvent.shiftKey) {
				w = h = Math.max(w, h);
				p.x = createOrigin.x + (ofs.x < 0 ? w : -w);  
				p.y = createOrigin.y + (ofs.y < 0 ? h : -h);  
			}

			newElement.setAttribute('x', Math.min(p.x, createOrigin.x));
			newElement.setAttribute('y', Math.min(p.y, createOrigin.y));
			newElement.setAttribute('width', w);
			newElement.setAttribute('height', h);
//newElement.setAttribute('scratch-type', 'backdrop-fill');
			newElement.updatePath();
			newObject.redraw();
		}
	}
}