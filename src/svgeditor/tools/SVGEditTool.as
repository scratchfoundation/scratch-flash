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
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	
	import svgeditor.ImageEdit;
	import svgeditor.Selection;
	import svgeditor.objs.ISVGEditable;

	public class SVGEditTool extends SVGTool
	{
		protected var object:ISVGEditable;
		private var editTag:Array;

		public function SVGEditTool(ed:ImageEdit, tag:* = null) {
			super(ed);
			touchesContent = true;
			object = null;
			editTag = (tag is String) ? [tag] : tag;
		}

		public function editSelection(s:Selection):void {
			if(s && s.getObjs().length == 1)
				setObject(s.getObjs()[0] as ISVGEditable);
		}

		public function setObject(obj:ISVGEditable):void {
			edit(obj, null);
		}

		public function getObject():ISVGEditable {
			return object;
		}

		// When overriding this method, usually an event handler will be added with a higher priority
		// so that the mouseDown method below is overridden
		protected function edit(obj:ISVGEditable, event:MouseEvent):void {
			if(obj == object) return;
			
			if(object) {
				//(object as DisplayObject).filters = [];
			}

			if(obj && (!editTag || editTag.indexOf(obj.getElement().tag) > -1)) {
				object = obj;
				
				if(object) {
					//(object as DisplayObject).filters = [new GlowFilter(0x28A5DA)];
				}
			} else {
				object = null;
			}
			dispatchEvent(new Event('select'));
		}

		override protected function init():void {
			super.init();
			editor.getContentLayer().addEventListener(MouseEvent.MOUSE_DOWN, mouseDown, false, 0, true);
		}

		override protected function shutdown():void {
			editor.getContentLayer().removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			super.shutdown();

			if(object) {
				setObject(null);
			}
		}

		protected function mouseDown(event:MouseEvent):void {
			var obj:ISVGEditable = getEditableUnderMouse(!(this is PathEditTool));
			currentEvent = event;
			edit(obj, event);
			currentEvent = null;
			
			event.stopPropagation();
		}
	}
}
