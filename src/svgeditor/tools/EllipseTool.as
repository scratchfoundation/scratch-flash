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
	
	import svgeditor.DrawProperties;
	import svgeditor.ImageEdit;
	import svgeditor.objs.SVGShape;
	
	import svgutils.SVGElement;

	public final class EllipseTool extends SVGCreateTool
	{
		private var createOrigin:Point;
		private var newElement:SVGElement;

		public function EllipseTool(svgEditor:ImageEdit) {
			super(svgEditor);
			createOrigin = null;
			newElement = null;
		}

		override protected function mouseDown(p:Point):void {
			// If we're trying to draw with invisible settings then bail
			var props:DrawProperties = editor.getShapeProps();
			if(props.alpha == 0)
				return;

			createOrigin = p;

			newElement = new SVGElement('ellipse', null);
			newElement.setAttribute('cx', contentLayer.mouseX);
			newElement.setAttribute('cy', contentLayer.mouseY);
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

			// Shift key makes a circle
			if(currentEvent.shiftKey) {
				w = h = Math.max(w, h);
				p.x = createOrigin.x + (ofs.x < 0 ? w : -w);  
				p.y = createOrigin.y + (ofs.y < 0 ? h : -h);  
			}
			
			var rx:Number = w/2;
			var ry:Number = h/2;
			newElement.setAttribute('cx', Math.min(p.x, createOrigin.x) + rx);
			newElement.setAttribute('cy', Math.min(p.y, createOrigin.y) + ry);
			newElement.setAttribute('rx', rx);
			newElement.setAttribute('ry', ry);
			newElement.updatePath();
			newObject.redraw();
		}
	}
}