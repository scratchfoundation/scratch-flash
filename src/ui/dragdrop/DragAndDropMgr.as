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
/**
 * Created by shanemc on 12/8/14.
 */
package ui.dragdrop {
import flash.display.*;
import flash.events.MouseEvent;
import flash.filters.DropShadowFilter;
import flash.geom.*;
import flash.utils.Dictionary;

import ui.ITool;
import ui.ToolMgr;

public class DragAndDropMgr implements ITool{
	public var originalObj:Sprite;
	public var draggedObj:Sprite;

	private var stage:Stage;
	private var app:Scratch;
	static private var draggableItems:Dictionary = new Dictionary(true);
	static private var instance:DragAndDropMgr;
	public function DragAndDropMgr(app:Scratch) {
		this.app = app;
		this.stage = app.stage;
		instance = this;
	}

	static public function setDraggable(sprite:Sprite, draggable:Boolean = true):void {
		if (draggable) {
			if (!(sprite in draggableItems)) {
				sprite.addEventListener(MouseEvent.MOUSE_DOWN, draggableMouseHandler, false, 0, true);
				draggableItems[sprite] = true;
			}
		}
		else {
			if (sprite in draggableItems) {
				sprite.removeEventListener(MouseEvent.MOUSE_DOWN, draggableMouseHandler);
				delete draggableItems[sprite];
			}
		}
	}

	static private var origParent:DisplayObjectContainer;
	static private var origPos:Point;
	static public function draggableMouseHandler(e:MouseEvent):void {
		var ct:Sprite = e.currentTarget as Sprite;
		switch (e.type) {
			case MouseEvent.MOUSE_DOWN:
				ct.addEventListener(MouseEvent.MOUSE_MOVE, draggableMouseHandler, false, 0, true);
				ct.addEventListener(MouseEvent.MOUSE_UP, draggableMouseHandler, false, 0, true);
				break;

			case MouseEvent.MOUSE_MOVE:
				instance.drag(ct as IDraggable);

			case MouseEvent.MOUSE_UP:
				ct.removeEventListener(MouseEvent.MOUSE_MOVE, draggableMouseHandler);
				ct.removeEventListener(MouseEvent.MOUSE_UP, draggableMouseHandler);
				break;
		}
	}

	private static var originPt:Point = new Point();
	public function drag(original:IDraggable):void {
		if (!ToolMgr.isToolActive()) {
			var spr:Sprite = original.getSpriteToDrag();
			if (!spr) return;

			originalObj = original as Sprite;
			origParent = originalObj.parent;
			origPos = originalObj.localToGlobal(originPt);

			draggedObj = spr;
			draggedObj.x = origPos.x;
			draggedObj.y = origPos.y;
			startDrag();
			ToolMgr.activateTool(this);
		}
	}

	private function startDrag():void {
		// Let the original object know about the dragging and let it do what it needs to the dragging object
		originalObj.dispatchEvent(new DragEvent(DragEvent.DRAG_START, draggedObj));
		draggedObj.startDrag();

		var f:DropShadowFilter = new DropShadowFilter();
		var blockScale:Number = (app.scriptsPane) ? app.scriptsPane.scaleX : 1;
		f.distance = 8 * blockScale;
		f.blurX = f.blurY = 2;
		f.alpha = 0.4;
		draggedObj.filters = draggedObj.filters.concat([f]);
		draggedObj.mouseEnabled = false;
		draggedObj.mouseChildren = false;
		stage.addChild(draggedObj);
	}

	private function stopDrag():void {
		var newFilters:Array = [];
		for each (var f:* in draggedObj.filters) {
			if (!(f is DropShadowFilter)) newFilters.push(f);
		}
		draggedObj.filters = newFilters;
		draggedObj.stopDrag();
		draggedObj.mouseEnabled = true;
		draggedObj.mouseChildren = true;

		if (originalObj != draggedObj && draggedObj.parent == stage)
			stage.removeChild(draggedObj);
	}


	public function shutdown():void {
		if (originalObj)
			originalObj.dispatchEvent(new DragEvent(DragEvent.DRAG_CANCEL, draggedObj));

		if (draggedObj)
			stopDrag();

		draggedObj = null;
		originalObj = null;
		currentDropTarget = null;
	}

	// Stay active until we're done and don't allow mouse events to get to buttons
	public function isSticky():Boolean { return true; }

	private var currentDropTarget:DropTarget;
	public function mouseHandler(e:MouseEvent):void {
		switch (e.type) {
			case MouseEvent.MOUSE_MOVE:
				var dropTarget:DropTarget = getCurrentDropTarget();
//trace('dropTarget = '+dropTarget);
				if (dropTarget != currentDropTarget) {
					if (currentDropTarget) currentDropTarget.dispatchEvent(new DragEvent(DragEvent.DRAG_OUT, draggedObj));
					currentDropTarget = dropTarget;
					if (currentDropTarget) currentDropTarget.dispatchEvent(new DragEvent(DragEvent.DRAG_OVER, draggedObj));
				}
				else if (currentDropTarget) {
					currentDropTarget.dispatchEvent(new DragEvent(DragEvent.DRAG_MOVE, draggedObj));
				}
				break;

			case MouseEvent.MOUSE_UP:
				var dropAccepted:Boolean = currentDropTarget && currentDropTarget.handleDrop(draggedObj);
				originalObj.dispatchEvent(new DragEvent(dropAccepted ? DragEvent.DRAG_STOP : DragEvent.DRAG_CANCEL, draggedObj));
				stopDrag();

				originalObj = null;
				draggedObj = null;
				currentDropTarget = null;

				ToolMgr.deactivateTool(this);
				break;
		}
	}

	private function getCurrentDropTarget():DropTarget {
		var possibleTargets:Array = stage.getObjectsUnderPoint(new Point(stage.mouseX, stage.mouseY));
		possibleTargets.reverse();
		for (var l:int=possibleTargets.length, i:int=l-1; i>-1; --i) {
			var o:DisplayObject = possibleTargets[i];
			while (o) { // see if some parent can handle the drop
				if (o is DropTarget) {
					return o as DropTarget;
				}
				o = o.parent;
			}
		}

		return null;
	}

//
//	private function drop(evt:MouseEvent):void {
//		if (carriedObj == null) return;
//		if(carriedObj is DisplayObject) carriedObj.cacheAsBitmap = false;
//		carriedObj.stopDrag();
//		//carriedObj.mouseEnabled = carriedObj.mouseChildren = true;
//		removeDropShadowFrom(carriedObj);
//		carriedObj.parent.removeChild(carriedObj);
//		carriedObj.scaleX = carriedObj.scaleY = originalScale;
//
//		var dropAccepted:Boolean = dropHandled(carriedObj, evt);
//		if (!dropAccepted) {
//			if (carriedObj is Block) {
//				Block(carriedObj).restoreOriginalState();
//			} else if (originalParent) { // put carriedObj back where it came from
//				carriedObj.x = originalPosition.x;
//				carriedObj.y = originalPosition.y;
//				originalParent.addChild(carriedObj);
//				if (carriedObj is ScratchSprite) {
//					var ss:ScratchSprite = carriedObj as ScratchSprite;
//					ss.updateCostume();
//					ss.updateBubble();
//				}
//			}
//
//			originalObj.dispatchEvent(new DragEvent(DragEvent.DRAG_CANCEL, carriedObj))
//		}
//		app.scriptsPane.draggingDone();
//	}
}}
