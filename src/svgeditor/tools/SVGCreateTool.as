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
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import svgeditor.ImageEdit;
	import svgeditor.ImageCanvas;
	import svgeditor.DrawProperties;
	import svgeditor.objs.ISVGEditable;
	import svgeditor.objs.SVGShape;

	public class SVGCreateTool extends SVGTool
	{
		protected var newObject:ISVGEditable;
		protected var contentLayer:Sprite;
		protected var isQuick:Boolean;
		private var lastPos:Point;

		public function SVGCreateTool(svgEditor:ImageEdit, quick:Boolean = true) {
			super(svgEditor);
			contentLayer = editor.getContentLayer();
			isQuick = quick;
		}

		// Pretend these are abstract ;)
		// Mouse down
		protected function mouseDown(p:Point):void {}

		// Mouse move
		protected function mouseMove(p:Point):void {}

		// Mouse up
		protected function mouseUp(p:Point):void {}

		public function getObject():ISVGEditable {
			return newObject;
		}

		override protected function init():void {
			super.init();
			addEventHandlers();
		}

		override protected function shutdown():void {
			//editor.toggleZoomUI(true);
			removeEventHandlers();
			super.shutdown();
			newObject = null;
			contentLayer = null;
		}

		override public function cancel():void {
			// Remove the object if it was added to the display list
			if(newObject && newObject is DisplayObject) {
				var dObj:DisplayObject = newObject as DisplayObject;
				if(dObj.parent) {
					dObj.parent.removeChild(dObj);
				}
				newObject = null;
			}
			
			super.cancel();
		}

		public function eventHandler(e:MouseEvent = null):void {
			if(!contentLayer) return;
			var p:Point = new Point(contentLayer.mouseX, contentLayer.mouseY);
			p.x = Math.min(ImageCanvas.canvasWidth, Math.max(0, p.x));
			p.y = Math.min(ImageCanvas.canvasHeight, Math.max(0, p.y));
			currentEvent = e;
			
			if(e.type == MouseEvent.MOUSE_DOWN) {
				//editor.toggleZoomUI(false);
				mouseDown(p);
				if(isQuick && !isShuttingDown) {
					// Add the mouse event handlers
					editor.stage.addEventListener(MouseEvent.MOUSE_MOVE, eventHandler, false, 0, true);
					editor.stage.addEventListener(MouseEvent.MOUSE_UP, eventHandler, false, 0, true);
				}
				lastPos = p;
			} else if(e.type == MouseEvent.MOUSE_MOVE) {
				mouseMove(p);
				lastPos = p;
			} else if(e.type == MouseEvent.MOUSE_UP) {
				//editor.toggleZoomUI(true);
				if(!stage) return;

				// If the mouse came up outside of the canvas, use the last mouse position within the canvas
				if(!editor.getCanvasLayer().hitTestPoint(stage.mouseX, stage.mouseY, true))
					p = lastPos;

				mouseUp(p);
				if(isQuick) editor.endCurrentTool(newObject);
			}
		}

		private function addEventHandlers():void  {
			editor.getCanvasLayer().addEventListener(MouseEvent.MOUSE_DOWN, eventHandler, false, 0, true);
			if(!isQuick) {
				editor.stage.addEventListener(MouseEvent.MOUSE_MOVE, eventHandler, false, 0, true);
				editor.stage.addEventListener(MouseEvent.MOUSE_UP, eventHandler, false, 0, true);
			}
		}

		private function removeEventHandlers():void {
			editor.getCanvasLayer().removeEventListener(MouseEvent.MOUSE_DOWN, eventHandler);
			if(editor.stage) {
				editor.stage.removeEventListener(MouseEvent.MOUSE_MOVE, eventHandler);
				editor.stage.removeEventListener(MouseEvent.MOUSE_UP, eventHandler);
			}
		}
	}
}