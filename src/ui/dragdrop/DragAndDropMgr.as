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
import flash.filters.DropShadowFilter;
import flash.geom.*;
import flash.utils.Dictionary;

import org.gestouch.events.GestureEvent;
import org.gestouch.gestures.Gesture;
import org.gestouch.gestures.TransformGesture;

public class DragAndDropMgr {
	public var originalObj:Sprite;
	public var draggedObj:Sprite;

	static private var stage:Stage;
	static private var app:Scratch;
	static private var draggableItems:Dictionary = new Dictionary(true);
	static private var instances:Array = [];
	static private var canceledDrags:Object = {};
	public function DragAndDropMgr() {
		instances.push(this);
	}

	static public function init(scratchApp:Scratch):void {
		app = scratchApp;
		stage = scratchApp.stage;
	}

	// The 'transformGesture' parameter allows you to supply a custom transform gesture if necessary.
	// That gesture's target will be replaced and gesturesShouldRecognizeSimultaneouslyCallback will be added if empty.
	// Please note that dispose() will be called on the gesture when dragging is disabled with this function.
	static public function setDraggable(sprite:Sprite, draggable:Boolean = true, transformGesture:TransformGesture = null):void {
		function dragBegan(event:GestureEvent):void {
			new DragAndDropMgr().onTransformBegan(event);
		}
		if (draggable) {
			if (!(sprite in draggableItems)) {
				if (!transformGesture) {
					transformGesture = new TransformGesture(sprite);
				}
				else {
					transformGesture.target = sprite;
				}
				if (!transformGesture.gesturesShouldRecognizeSimultaneouslyCallback) {
					transformGesture.gesturesShouldRecognizeSimultaneouslyCallback = shouldDragSimultaneously;
				}
				transformGesture.addEventListener(GestureEvent.GESTURE_BEGAN, dragBegan);
				draggableItems[sprite] = transformGesture;
			}
		}
		else {
			if (sprite in draggableItems) {
				transformGesture = draggableItems[sprite];
				transformGesture.removeEventListener(GestureEvent.GESTURE_BEGAN, dragBegan);
				transformGesture.dispose();
				delete draggableItems[sprite];
			}
		}
	}

	private static function shouldDragSimultaneously(gesture:Gesture, otherGesture:Gesture):Boolean {
		// Allow drag to cooperate with another gesture on this same target, like a long-press in the tablet lobby.
		return gesture.target == otherGesture.target;
	}

	private static var originPt:Point = new Point();
	private function onTransformBegan(event:GestureEvent):void {
		var transformGesture:TransformGesture = event.target as TransformGesture;
		var original:IDraggable = transformGesture.target as IDraggable;
		var spr:Sprite = original ? original.getSpriteToDrag() : null;
		if (!spr) return;

		originalObj = original as Sprite;
		var origPos:Point = originalObj.localToGlobal(originPt);

		draggedObj = spr;
		startDrag();
		draggedObj.x = origPos.x + transformGesture.offsetX;
		draggedObj.y = origPos.y + transformGesture.offsetY;

		// Let the original object know about the dragging and let it do what it needs to the dragging object
		originalObj.dispatchEvent(new DragEvent(DragEvent.DRAG_START, draggedObj));
		stage.addChild(draggedObj);

		transformGesture.addEventListener(GestureEvent.GESTURE_CHANGED, onTransformChanged);
		transformGesture.addEventListener(GestureEvent.GESTURE_ENDED, onTransformEnded);
	}

	static public function getDraggedObjs():Array {
		var objs:Array = [];

		if (instances.length) {
			for each (var inst:DragAndDropMgr in instances)
				objs.push(inst.draggedObj);
		}

		return objs;
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

	public static function cancelDrag(item:Sprite):void {
		var tg:TransformGesture = draggableItems[item] as TransformGesture;
		if (tg) tg.reset();
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

	private function onTransformChanged(event:GestureEvent):void {
		var transformGesture:TransformGesture = event.target as TransformGesture;
		var dropTarget:DropTarget = getDropTarget(transformGesture.location);

		if (dropTarget != currentDropTarget) {
			if (currentDropTarget) currentDropTarget.dispatchEvent(new DragEvent(DragEvent.DRAG_OUT, draggedObj));
			currentDropTarget = dropTarget;
			if (currentDropTarget) currentDropTarget.dispatchEvent(new DragEvent(DragEvent.DRAG_OVER, draggedObj));
		}
		else if (currentDropTarget) {
			currentDropTarget.dispatchEvent(new DragEvent(DragEvent.DRAG_MOVE, draggedObj));
		}

		draggedObj.x += transformGesture.offsetX;
		draggedObj.y += transformGesture.offsetY;
	}

	private function onTransformEnded(event:GestureEvent):void {
		var transformGesture:TransformGesture = event.target as TransformGesture;
		var dropAccepted:Boolean = currentDropTarget && currentDropTarget.handleDrop(draggedObj);
		originalObj.dispatchEvent(new DragEvent(dropAccepted ? DragEvent.DRAG_STOP : DragEvent.DRAG_CANCEL, draggedObj));
		event.stopImmediatePropagation();
		stopDrag();

		originalObj = null;
		draggedObj = null;
		currentDropTarget = null;

		instances.splice(instances.indexOf(this), 1);
		transformGesture.removeEventListener(GestureEvent.GESTURE_CHANGED, onTransformChanged);
		transformGesture.removeEventListener(GestureEvent.GESTURE_ENDED, onTransformEnded);
	}

	private function getDropTarget(stagePoint:Point):DropTarget {
		if (Scratch.app.isIn3D && Scratch.app.stagePane.getBounds(stage).containsPoint(stagePoint))
			return Scratch.app.stagePane;

		draggedObj.visible = false;
		var possibleTargets:Array = stage.getObjectsUnderPoint(stagePoint);
		draggedObj.visible = true;

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
