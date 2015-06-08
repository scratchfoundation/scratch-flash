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
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;

	import svgeditor.objs.ISVGEditable;

	import svgutils.SVGDisplayRender;
	import svgutils.SVGElement;

	public class SVGTextField extends TextField implements ISVGEditable
	{
		private var element:SVGElement;
		private var _editable:Boolean;

		public function SVGTextField(elem:SVGElement) {
			element = elem;
			if (element.text == null) element.text = '';
			_editable = false;
			antiAliasType = AntiAliasType.ADVANCED;
			cacheAsBitmap = true;
			embedFonts = true;
			backgroundColor = 0xFFFFFF;
			multiline = true;
		}

		public function getElement():SVGElement {
			element.transform = transform.matrix.clone();
			return element;
		}

		public function redraw(forHitTest:Boolean = false):void {
			var fixup:Boolean = (type == TextFieldType.INPUT && element.text.length < 4);
			var origText:String = element.text;
			if(element.text == "") element.text = " ";
			element.renderTextOn(this);
			element.text = origText;
			if(fixup) width += 25;
		}

		public function clone():ISVGEditable {
			var copy:SVGTextField = new SVGTextField(element.clone());
			copy.transform.matrix = transform.matrix.clone();
			copy.selectable = false;
			copy.redraw();
			return copy as ISVGEditable;
		}
	}
}
