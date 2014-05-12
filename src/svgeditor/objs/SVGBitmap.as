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
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.events.Event;
	
	import svgeditor.objs.ISVGEditable;
	
	import svgutils.SVGDisplayRender;
	import svgutils.SVGElement;
	
	public class SVGBitmap extends Bitmap implements ISVGEditable
	{
		private var element:SVGElement;

		public function SVGBitmap(elem:SVGElement, bitmapData:BitmapData=null)
		{
			element = elem;
			super(bitmapData);
		}

		public function getElement():SVGElement {
			element.transform = transform.matrix;
			return element;
		}

		public function redraw(forHitTest:Boolean = false):void {
			element.renderImageOn(this);
		}

		public function clone():ISVGEditable {
			var copy:ISVGEditable = new SVGBitmap(element.clone(), bitmapData);
			(copy as DisplayObject).transform.matrix = transform.matrix.clone();
			copy.redraw();
			return copy;
		}
	}
}