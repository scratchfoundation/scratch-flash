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
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import svgeditor.*;
	import svgeditor.objs.ISVGEditable;
	import svgeditor.objs.SVGShape;
	
	import svgutils.SVGElement;

	public final class CloneTool extends SVGCreateTool
	{
		private var copiedObjects:Array;
		private var previewObjects:Array;
		private var centerPt:Point;
		private var holder:Sprite;

		public function CloneTool(svgEditor:ImageEdit, s:Selection = null) {
			super(svgEditor, false);
			holder = new Sprite();
			addChild(holder);
			cursorBMName = 'cloneOff';
			cursorHotSpot = new Point(12,21);
			copiedObjects = null;
			previewObjects = null;
		}

		public function pasteFromClipboard(objs:Array):void {
			for each(var dObj:DisplayObject in objs) {
				contentLayer.addChild(dObj);
			}
			previewObjects = (new Selection(objs)).cloneObjs(contentLayer);
			copiedObjects = (new Selection(objs)).cloneObjs(contentLayer);
			for each(dObj in objs) {
				contentLayer.removeChild(dObj);
			}
			createPreview();
		}

		private function makeCopies(s:Selection):void {
			copiedObjects = s.cloneObjs(contentLayer);
			previewObjects = s.cloneObjs(contentLayer);
		}
		
		override protected function init():void {
			super.init();
			editor.getToolsLayer().mouseEnabled = false;
			editor.getToolsLayer().mouseChildren = false;
		}

		override protected function shutdown():void {
			editor.getToolsLayer().mouseEnabled = true;
			editor.getToolsLayer().mouseChildren = true;
			super.shutdown();
			clearCurrentClone();
		}

		private function clearCurrentClone():void {
			while(holder.numChildren) holder.removeChildAt(0);
			copiedObjects = null;
			previewObjects = null;
		}

		override protected function mouseMove(p:Point):void {
			if(copiedObjects) centerPreview();
			else checkUnderMouse();
		}

		override protected function mouseDown(p:Point):void {
			if(copiedObjects == null) {
				var obj:ISVGEditable = getEditableUnderMouse();
				if(obj) {
					makeCopies(new Selection([obj]));
					createPreview();
					checkUnderMouse(true);
				}
				return;
			}
		}

		override protected function mouseUp(p:Point):void {
			if(copiedObjects == null) return;

			for(var i:uint=0; i<copiedObjects.length; ++i) {
				var pObj:DisplayObject = previewObjects[i] as DisplayObject;
				var pt:Point = new Point(pObj.x, pObj.y);
				pt = holder.localToGlobal(pt);
				pt = contentLayer.globalToLocal(pt);

				var dObj:DisplayObject = copiedObjects[i] as DisplayObject;
				contentLayer.addChild(dObj);
				dObj.x = pt.x;
				dObj.y = pt.y;
			}

			// Save!
			dispatchEvent(new Event(Event.CHANGE));

			var s:Selection = new Selection(copiedObjects);
			if(currentEvent.shiftKey) {
				// Get another copy
				copiedObjects = s.cloneObjs(contentLayer);
			} else {
				// Select the copied objects
				editor.endCurrentTool(s);
			}
		}

		private function createPreview():void {
			x = y = 0;

			// Match the current content scale factor
			var m:Matrix = editor.getContentLayer().transform.concatenatedMatrix;
			holder.scaleX = m.deltaTransformPoint(new Point(0,1)).length;
			holder.scaleY = m.deltaTransformPoint(new Point(1,0)).length;

			// 
			for(var i:uint=0; i<copiedObjects.length; ++i) {
				var dObj:DisplayObject = previewObjects[i] as DisplayObject;
				holder.addChild(dObj);
			}

			var rect:Rectangle = getBounds(this);
			centerPt = new Point((rect.right + rect.left)/2, (rect.bottom + rect.top)/2);
			centerPreview();
			alpha = 0.5;
		}

		private function centerPreview():void {
			x += mouseX - centerPt.x;
			y += mouseY - centerPt.y;
		}

		private var highlightedObj:DisplayObject;
		private function checkUnderMouse(clear:Boolean = false):void {
			var obj:ISVGEditable = clear ? null : getEditableUnderMouse();
			
			if(obj != highlightedObj) {
				if(highlightedObj) highlightedObj.filters = [];
				highlightedObj = obj as DisplayObject;
				if(highlightedObj) highlightedObj.filters = [new GlowFilter(0x28A5DA)];
			}
		}
	}
}