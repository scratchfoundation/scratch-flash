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
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	
	import svgeditor.objs.ISVGEditable;
	
	import svgutils.SVGElement;
	
	public class SVGGroup extends Sprite implements ISVGEditable
	{
		private var element:SVGElement;

		public function SVGGroup(elem:SVGElement) {
			super();
			element = elem;
		}
		
		public function getElement():SVGElement {
			element.subElements = getSubElements();
			element.transform = transform.matrix;
			return element;
		}
		
		public function redraw(forHitTest:Boolean = false):void {
			if(element.transform) transform.matrix = element.transform;

			// Redraw the sub elements
			for(var i:uint = 0; i < numChildren; ++i) {
				var child:DisplayObject = getChildAt(i);
				if(child is ISVGEditable) {
					(child as ISVGEditable).redraw();
				}
			}
		}

		private function getSubElements():Array {
			var elements:Array = [];
			for(var i:uint = 0; i < numChildren; ++i) {
				var child:DisplayObject = getChildAt(i);
				if(child is ISVGEditable) {
					elements.push((child as ISVGEditable).getElement());
				}
			}
			return elements;
		}
		
		public function clone():ISVGEditable {
			var copy:SVGGroup = new SVGGroup(element.clone());
			(copy as DisplayObject).transform.matrix = transform.matrix.clone();

			var elements:Array = [];
			for(var i:uint = 0; i < numChildren; ++i) {
				var child:DisplayObject = getChildAt(i);
				if(child is ISVGEditable) {
					copy.addChild((child as ISVGEditable).clone() as DisplayObject);
				}
			}

			copy.redraw();
			return copy;
		}
	}
}