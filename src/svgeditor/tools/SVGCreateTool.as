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
import flash.events.MouseEvent;
import flash.geom.Point;

import svgeditor.ImageCanvas;
import svgeditor.ImageEdit;
import svgeditor.objs.ISVGEditable;

import ui.events.PointerEvent;

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

	override protected function start():void {
		super.start();
	}

	override protected function stop():void {
		//editor.toggleZoomUI(true);
		super.stop();
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

	override public function mouseHandler(e:PointerEvent):Boolean {
		if(!contentLayer) return false;
		var p:Point = new Point(contentLayer.mouseX, contentLayer.mouseY);
		p.x = Math.min(ImageCanvas.canvasWidth, Math.max(0, p.x));
		p.y = Math.min(ImageCanvas.canvasHeight, Math.max(0, p.y));
		currentEvent = e;

		if(e.type == PointerEvent.POINTER_DOWN) {
			//editor.toggleZoomUI(false);
			mouseDown(p);
			if(isQuick && !isShuttingDown) {
				// Add the mouse event handlers
//					editor.stage.addEventListener(PointerEvent.POINTER_MOVE, eventHandler, false, 0, true);
//					editor.stage.addEventListener(PointerEvent.POINTER_UP, eventHandler, false, 0, true);
			}
			lastPos = p;
		} else if(e.type == PointerEvent.POINTER_MOVE) {
			mouseMove(p);
			lastPos = p;
		} else if(e.type == PointerEvent.POINTER_UP) {
			//editor.toggleZoomUI(true);
			if(!stage) return false;

			// If the mouse came up outside of the canvas, use the last mouse position within the canvas
			if(!editor.getCanvasLayer().hitTestPoint(stage.mouseX, stage.mouseY, true))
				p = lastPos;

			mouseUp(p);
			if(isQuick) editor.endCurrentTool(newObject);
		}

		return true;
	}
}}
