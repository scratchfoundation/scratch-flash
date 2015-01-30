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

	static private var stage:Stage;
	static private var app:Scratch;
	static private var draggableItems:Dictionary = new Dictionary(true);
	static private var instances:Array = new Array();
	public function DragAndDropMgr() {
		instances.push(this);
	}

	static public function init(scratchApp:Scratch):void {
		app = scratchApp;
		stage = scratchApp.stage;
	}

	static public function setDraggable(sprite:Sprite, draggable:Boolean = true):void {
		if (draggable) {
			if (!(sprite in draggableItems)) {
				sprite.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler, false, 0, true);
				draggableItems[sprite] = true;
			}
		}
		else {
			if (sprite in draggableItems) {
				sprite.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
				delete draggableItems[sprite];
			}
		}
	}

	private var origParent:DisplayObjectContainer;
	private var origPos:Point;
	static public function mouseDownHandler(e:MouseEvent):void {
		var ct:Sprite = e.currentTarget as Sprite;

		var mouseDownX:Number = e.stageX;
		var mouseDownY:Number = e.stageY;
		function startDragHandler(evt:MouseEvent):void {
			if (evt.type == MouseEvent.MOUSE_MOVE && !ToolMgr.isToolActive())
				new DragAndDropMgr().drag(ct as IDraggable, mouseDownX, mouseDownY, e);

			ct.removeEventListener(MouseEvent.MOUSE_MOVE, startDragHandler);
			ct.removeEventListener(MouseEvent.MOUSE_UP, startDragHandler);
		}

		ct.addEventListener(MouseEvent.MOUSE_MOVE, startDragHandler, false, 0, true);
		ct.addEventListener(MouseEvent.MOUSE_UP, startDragHandler, false, 0, true);
		e.stopPropagation();
	}

	static public function startDragging(original:IDraggable, mouseDownX:Number, mouseDownY:Number, event:MouseEvent):void {
		new DragAndDropMgr().drag(original, mouseDownX, mouseDownY, event);
	}

	static public function getDraggedObjs():Array {
		var objs:Array = [];

		if (instances.length) {
			for each (var inst:DragAndDropMgr in instances)
				objs.push(inst.draggedObj);
		}

		return objs;
	}

	private static var originPt:Point = new Point();
	private var dragOffset:Point = new Point();
	public function drag(original:IDraggable, mouseDownX:Number, mouseDownY:Number, event:MouseEvent):void {
		if (!ToolMgr.isToolActive()) {
			var mouseX:Number = isNaN(event.stageX) ? stage.mouseX : event.stageX;
			var mouseY:Number = isNaN(event.stageY) ? stage.mouseY : event.stageY;
			var spr:Sprite = original.getSpriteToDrag();
			if (!spr) return;

			originalObj = original as Sprite;
			origParent = originalObj.parent;
			origPos = originalObj.localToGlobal(originPt);

			draggedObj = spr;
			startDrag();
			draggedObj.x = origPos.x + (mouseX - mouseDownX);
			draggedObj.y = origPos.y + (mouseY - mouseDownY);

			// Let the original object know about the dragging and let it do what it needs to the dragging object
			originalObj.dispatchEvent(new DragEvent(DragEvent.DRAG_START, draggedObj));
			stage.addChild(draggedObj);
			dragOffset.x = draggedObj.x - mouseX;
			dragOffset.y = draggedObj.y - mouseY;
			ToolMgr.activateTool(this);
		}
	}

	private function startDrag():void {
		var f:DropShadowFilter = new DropShadowFilter();
		var blockScale:Number = (app.scriptsPane) ? app.scriptsPane.scaleX : 1;
		f.distance = 8 * blockScale;
		f.blurX = f.blurY = 2;
		f.alpha = 0.4;
		draggedObj.filters = draggedObj.filters.concat([f]);
		draggedObj.mouseEnabled = false;
		draggedObj.mouseChildren = false;
	}

	private function stopDrag():void {
		var newFilters:Array = [];
		for each (var f:* in draggedObj.filters)
			if (!(f is DropShadowFilter)) newFilters.push(f);

		draggedObj.filters = newFilters;
		//draggedObj.stopDrag();
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

	private var currentDropTarget:DropTarget;
	public function mouseHandler(e:MouseEvent):Boolean {
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

				draggedObj.x = e.stageX + dragOffset.x;
				draggedObj.y = e.stageY + dragOffset.y;
				e.updateAfterEvent();
				break;

			case MouseEvent.MOUSE_UP:
				var dropAccepted:Boolean = currentDropTarget && currentDropTarget.handleDrop(draggedObj);
				originalObj.dispatchEvent(new DragEvent(dropAccepted ? DragEvent.DRAG_STOP : DragEvent.DRAG_CANCEL, draggedObj));
				stopDrag();

				originalObj = null;
				draggedObj = null;
				currentDropTarget = null;

				ToolMgr.deactivateTool(this);
				instances.splice(instances.indexOf(this), 1);
				break;
		}

		return true;
	}

	private function getCurrentDropTarget():DropTarget {
		var possibleTargets:Array = stage.getObjectsUnderPoint(new Point(stage.mouseX, stage.mouseY));
		//possibleTargets.reverse();
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
}}
