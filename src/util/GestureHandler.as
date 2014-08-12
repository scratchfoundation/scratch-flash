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

// GestureHandler.as
// John Maloney, April 2010
//
// This class handles mouse gestures at a global level. While some UI widgets must
// do their own event handling, an object that only needs to respond to clicks or
// provide a contextual menu may do so simply by implementing one of these methods:
//
//		click()
//		doubleClick()
//		menu(evt)
//
// GestureHandler also supports mouse handling on objects such as sliders via
// the DragClient interface. This mechanism ensures that the widget will continue
// to receive mouse move events until the mouse goes up even if the mouse is moved
// away from the widget. This is useful because the native Flash mouse handling stops
// sending mouse events to an object if the mouse moves off that object.
//
// GestureHandler supports a simple drag-n-drop ("grab-n-drop") mechanism.
// To become draggable, an object merely needs to implement the method objToGrab().
// If that returns a DisplayObject, the object will be dragged until the mouse is released.
// If objToGrab() returns null no object is dragged. To become a drop target, an object
// implements the handleDrop() method. This method returns true if the dropped object is
// accepted, false if the drop is rejected. Dragged objects are provided with a drop shadow
// in editMode.
//
// For developers, if DEBUG is true then shift-click will highlight objects in the
// DisplayObject hierarchy and print their names in the console. This can be used to
// understand the nesting of UI objects.

package util {
	import flash.display.*;
	import flash.events.MouseEvent;
	import flash.filters.*;
	import flash.geom.*;
	import flash.text.*;
	import flash.utils.getTimer;
	import blocks.*;
	import scratch.*;
	import uiwidgets.*;
	import svgeditor.*;
	import watchers.*;

public class GestureHandler {

	private const DOUBLE_CLICK_MSECS:int = 400;
	private const DEBUG:Boolean = false;

	public var mouseIsDown:Boolean;

	// Grab-n-drop support:
	public var carriedObj:Sprite;
	private var originalParent:DisplayObjectContainer;
	private var originalPosition:Point;
	private var originalScale:Number;

	private var app:Scratch;
	private var stage:Stage;
	private var dragClient:DragClient;
	private var mouseDownTime:uint;
	private var gesture:String = "idle";
	private var mouseTarget:*;
	private var objToGrabOnUp:Sprite;
	private var mouseDownEvent:MouseEvent;
	private var inIE:Boolean;

	private var bubble:TalkBubble;
	private var bubbleStartX:Number;
	private var bubbleStartY:Number;
	private static var bubbleRange:Number = 25;
	private static var bubbleMargin:Number = 5;

	public function GestureHandler(app:Scratch, inIE:Boolean) {
		this.app = app;
		this.stage = app.stage;
		this.inIE = inIE;
	}

	public function setDragClient(newClient:DragClient, evt:MouseEvent):void {
		Menu.removeMenusFrom(stage);
		if (carriedObj) return;
		if (dragClient != null) dragClient.dragEnd(evt);
		dragClient = newClient as DragClient;
		dragClient.dragBegin(evt);
		evt.stopImmediatePropagation();
	}

	public function grabOnMouseUp(obj:Sprite):void {
		if (CursorTool.tool == 'copy') {
			// If duplicate tool, grab right away
			grab(obj, null);
			gesture = 'drag';
		} else {
			objToGrabOnUp = obj;
		}
	}

	public function step():void {
		if ((getTimer() - mouseDownTime) > DOUBLE_CLICK_MSECS) {
			if (gesture == "unknown") {
				if (mouseTarget != null) handleDrag(null);
				if (gesture != 'drag') handleClick(mouseDownEvent);
			}
			if (gesture == "clickOrDoubleClick") {
				handleClick(mouseDownEvent);
			}
		}
	}

	public function rightMouseClick(evt:MouseEvent):void {
		// You only get this event in AIR.
		rightMouseDown(evt.stageX, evt.stageY, false);
	}

	public function rightMouseDown(x:int, y:int, isChrome:Boolean):void {
		// To avoid getting the Adobe menu on right-click, JavaScript captures
		// right-button mouseDown events and calls this method.'
		Menu.removeMenusFrom(stage);
		var menuTarget:* = findTargetFor('menu', app, x, y);
		if (!menuTarget) return;
		try { var menu:Menu = menuTarget.menu(new MouseEvent('right click')) } catch (e:Error) {}
		if (menu) menu.showOnStage(stage, x, y);
		if (!isChrome) Menu.removeMenusFrom(stage); // hack: clear menuJustCreated because there's no rightMouseUp
	}

	private function findTargetFor(property:String, obj:*, x:int, y:int):DisplayObject {
		// Return the innermost child  of obj that contains the given (global) point
		// and implements the menu() method.
		if (!obj.visible || !obj.hitTestPoint(x, y, true)) return null;
		if (obj is DisplayObjectContainer) {
			for (var i:int = obj.numChildren - 1; i >= 0; i--) {
				var found:DisplayObject = findTargetFor(property, obj.getChildAt(i), x, y);
				if (found) return found;
			}
		}
		return (property in obj) ? obj : null;
	}

	public function mouseDown(evt:MouseEvent):void {
		if(inIE && app.editMode && app.jsEnabled)
			app.externalCall('tip_bar_api.fixIE');

		evt.updateAfterEvent(); // needed to avoid losing display updates with later version of Flash 11
		hideBubble();
		mouseIsDown = true;
		if (gesture == 'clickOrDoubleClick') {
			handleDoubleClick(mouseDownEvent);
			return;
		}
		if (CursorTool.tool) {
			handleTool(evt);
			return;
		}
		mouseDownTime = getTimer();
		mouseDownEvent = evt;
		gesture = "unknown";
		mouseTarget = null;

		if (carriedObj != null) { drop(evt); return; }

		if (dragClient != null) {
			dragClient.dragBegin(evt);
			return;
		}
		if (DEBUG && evt.shiftKey) return showDebugFeedback(evt);

		var t:* = evt.target;
		if ((t is TextField) && (TextField(t).type == TextFieldType.INPUT)) return;
		mouseTarget = findMouseTarget(evt, t);
		if (mouseTarget == null) {
			gesture = "ignore";
			return;
		}

		if (doClickImmediately()) {
			handleClick(evt);
			return;
		}
		if (evt.shiftKey && app.editMode && ('menu' in mouseTarget)) {
			gesture = "menu";
			return;
		}
	}

	private function doClickImmediately():Boolean {
		// Answer true when clicking on the stage or a locked sprite in play (presentation) mode.
		if (app.editMode) return false;
		if (mouseTarget is ScratchStage) return true;
		return (mouseTarget is ScratchSprite) && !ScratchSprite(mouseTarget).isDraggable;
	}

	public function mouseMove(evt:MouseEvent):void {
		if (gesture == "debug") { evt.stopImmediatePropagation(); return; }
		mouseIsDown = evt.buttonDown;
		if (dragClient != null) {
			dragClient.dragMove(evt);
			return;
		}
		if (gesture == "unknown") {
			if (mouseTarget != null) handleDrag(evt);
			return;
		}
		if ((gesture == "drag") && (carriedObj is Block)) {
			app.scriptsPane.updateFeedbackFor(Block(carriedObj));
		}
		if ((gesture == "drag") && (carriedObj is ScratchSprite)) {
			var stageP:Point = app.stagePane.globalToLocal(carriedObj.localToGlobal(new Point(0, 0)));
			var spr:ScratchSprite = ScratchSprite(carriedObj);
			spr.scratchX = stageP.x - 240;
			spr.scratchY = 180 - stageP.y;
			spr.updateBubble();
		}
		if (bubble) {
			var dx:Number = bubbleStartX - stage.mouseX;
			var dy:Number = bubbleStartY - stage.mouseY;
			if (dx * dx + dy * dy > bubbleRange * bubbleRange) {
				hideBubble();
			}
		}
	}

	public function mouseUp(evt:MouseEvent):void {
		if (gesture == "debug") { evt.stopImmediatePropagation(); return; }
		mouseIsDown = false;
		if (dragClient != null) {
			var oldClient:DragClient = dragClient;
			dragClient = null;
			oldClient.dragEnd(evt);
			return;
		}
		drop(evt);
		Menu.removeMenusFrom(stage);
		if (gesture == "unknown") {
			if (mouseTarget && ('doubleClick' in mouseTarget)) gesture = "clickOrDoubleClick";
			else {
				handleClick(evt);
				mouseTarget = null;
				gesture = "idle";
			}
			return;
		}
		if (gesture == "menu") handleMenu(evt);
		if (app.scriptsPane) app.scriptsPane.draggingDone();
		mouseTarget = null;
		gesture = "idle";
		if (objToGrabOnUp != null) {
			gesture = "drag";
			grab(objToGrabOnUp, evt);
			objToGrabOnUp = null;
		}
	}

	public function mouseWheel(evt:MouseEvent):void {
		hideBubble();
	}

	private function findMouseTarget(evt:MouseEvent, target:*):DisplayObject {
		// Find the mouse target for the given event. Return null if no target found.

		if ((target is TextField) && (TextField(target).type == TextFieldType.INPUT)) return null;
		if ((target is Button) || (target is IconButton)) return null;

		var o:DisplayObject = evt.target as DisplayObject;
		var mouseTarget:Boolean = false;
		while (o != null) {
			if (isMouseTarget(o, evt.stageX / app.scaleX, evt.stageY / app.scaleY)) {
				mouseTarget = true;
				break;
			}
			o = o.parent;
		}
		var rect:Rectangle = app.stageObj().getRect(stage);
		if(!mouseTarget && rect.contains(evt.stageX, evt.stageY))  return findMouseTargetOnStage(evt.stageX / app.scaleX, evt.stageY / app.scaleY);
		if (o == null) return null;
		if ((o is Block) && Block(o).isEmbeddedInProcHat()) return o.parent;
		if (o is ScratchObj) return findMouseTargetOnStage(evt.stageX / app.scaleX, evt.stageY / app.scaleY);
		return o;
	}

	private function findMouseTargetOnStage(globalX:int, globalY:int):DisplayObject {
		// Find the front-most, visible stage element at the given point.
		// Take sprite shape into account so you can click or grab a sprite
		// through a hole in another sprite that is in front of it.
		// Return the stage if no other object is found.
		if(app.isIn3D) app.stagePane.visible = true;
		var uiLayer:Sprite = app.stagePane.getUILayer();
		for (var i:int = uiLayer.numChildren - 1; i > 0; i--) {
			var o:DisplayObject = uiLayer.getChildAt(i) as DisplayObject;
			if (o is Bitmap) break; // hit the paint layer of the stage; no more elments
			if (o.visible && o.hitTestPoint(globalX, globalY, true)) {
				if(app.isIn3D) app.stagePane.visible = false;
				return o;
			}
		}
		if(app.stagePane != uiLayer) {
			for (i = app.stagePane.numChildren - 1; i > 0; i--) {
				o = app.stagePane.getChildAt(i) as DisplayObject;
				if (o is Bitmap) break; // hit the paint layer of the stage; no more elments
				if (o.visible && o.hitTestPoint(globalX, globalY, true)) {
					if(app.isIn3D) app.stagePane.visible = false;
					return o;
				}
			}
		}

		if(app.isIn3D) app.stagePane.visible = false;
		return app.stagePane;
	}

	private function isMouseTarget(o:DisplayObject, globalX:int, globalY:int):Boolean {
		// Return true if the given object is hit by the mouse and has a
		// method named click, doubleClick, menu or objToGrab.
		if (!o.hitTestPoint(globalX, globalY, true)) return false;
		if (('click' in o) || ('doubleClick' in o)) return true;
		if (('menu' in o) || ('objToGrab' in o)) return true;
		return false;
	}

	private function handleDrag(evt:MouseEvent):void {
		// Note: Called with a null event if gesture is click and hold.
		Menu.removeMenusFrom(stage);
		if (!('objToGrab' in mouseTarget)) return;
		if (!app.editMode) {
			if ((mouseTarget is ScratchSprite) && !ScratchSprite(mouseTarget).isDraggable) return; // don't drag locked sprites in presentation mode
			if ((mouseTarget is Watcher) || (mouseTarget is ListWatcher)) return; // don't drag watchers in presentation mode
		}
		grab(mouseTarget, evt);
		gesture = 'drag';
		if (carriedObj is Block) {
			app.scriptsPane.updateFeedbackFor(Block(carriedObj));
		}
	}

	private function handleClick(evt:MouseEvent):void {
		if (mouseTarget == null) return;
		evt.updateAfterEvent();
		if ('click' in mouseTarget) mouseTarget.click(evt);
		gesture = 'click';
	}

	private function handleDoubleClick(evt:MouseEvent):void {
		if (mouseTarget == null) return;
		if ('doubleClick' in mouseTarget) mouseTarget.doubleClick(evt);
		gesture = "doubleClick";
	}

	private function handleMenu(evt:MouseEvent):void {
		if (mouseTarget == null) return;
		var menu:Menu;
		try { menu = mouseTarget.menu(evt) } catch (e:Error) {}
		if (menu) menu.showOnStage(stage, evt.stageX / app.scaleX, evt.stageY / app.scaleY);
	}

	private var lastGrowShrinkSprite:Sprite;

	private function handleTool(evt:MouseEvent):void {
		var isGrowShrink:Boolean = ('grow' == CursorTool.tool) || ('shrink' == CursorTool.tool);
		var t:* = findTargetFor('handleTool', app, evt.stageX / app.scaleX, evt.stageY / app.scaleY);
		if(!t) t = findMouseTargetOnStage(evt.stageX / app.scaleX, evt.stageY / app.scaleY);

		if (isGrowShrink && (t is ScratchSprite)) {
			function clearTool(e:MouseEvent):void {
				if (lastGrowShrinkSprite) {
					lastGrowShrinkSprite.removeEventListener(MouseEvent.MOUSE_OUT, clearTool);
					lastGrowShrinkSprite = null;
					app.clearTool();
				}
			}
			if (!lastGrowShrinkSprite && !evt.shiftKey) {
				t.addEventListener(MouseEvent.MOUSE_OUT, clearTool);
				lastGrowShrinkSprite = t;
			}
			t.handleTool(CursorTool.tool, evt);
			return;
		}
		if (t && 'handleTool' in t) t.handleTool(CursorTool.tool, evt);
		if (isGrowShrink && (t is Block && t.isInPalette || t is ImageCanvas)) return; // grow/shrink sticky for scripting area

		if (!evt.shiftKey) app.clearTool(); // don't clear if shift pressed
	}

	private function grab(obj:*, evt:MouseEvent):void {
		// Note: Called with a null event if gesture is click and hold.
		if (evt) drop(evt);

		var globalP:Point = obj.localToGlobal(new Point(0, 0)); // record the original object's global position
		obj = obj.objToGrab(evt ? evt : new MouseEvent('')); // can return the original object, a new object, or null
		if (!obj) return; // not grabbable
		if (obj.parent) globalP = obj.localToGlobal(new Point(0, 0)); // update position if not a copy

		originalParent = obj.parent; // parent is null if objToGrab() returns a new object
		originalPosition = new Point(obj.x, obj.y);
		originalScale = obj.scaleX;

		if (obj is Block) {
			var b:Block = Block(obj);
			b.saveOriginalState();
			if (b.parent is Block) Block(b.parent).removeBlock(b);
			if (b.parent != null) b.parent.removeChild(b);
			app.scriptsPane.prepareToDrag(b);
		} else if (obj is ScratchComment) {
			var c:ScratchComment = ScratchComment(obj);
			if (c.parent != null) c.parent.removeChild(c);
			app.scriptsPane.prepareToDragComment(c);
		} else {
			var inStage:Boolean = (obj.parent == app.stagePane);
			if (obj.parent != null) {
				if(obj is ScratchSprite && app.isIn3D)
					(obj as ScratchSprite).prepareToDrag();

				obj.parent.removeChild(obj);
			}
			if (inStage && (app.stagePane.scaleX != 1)) {
				obj.scaleX = obj.scaleY = (obj.scaleX * app.stagePane.scaleX);
			}
		}

		if (app.editMode) addDropShadowTo(obj);
		stage.addChild(obj);
		obj.x = globalP.x;
		obj.y = globalP.y;
		if (evt && mouseDownEvent) {
			obj.x += evt.stageX - mouseDownEvent.stageX;
			obj.y += evt.stageY - mouseDownEvent.stageY;
		}
		obj.startDrag();
		if(obj is DisplayObject) obj.cacheAsBitmap = true;
		carriedObj = obj;
	}

	private function dropHandled(droppedObj:*, evt:MouseEvent):Boolean {
		// Search for an object to handle this drop and return true one is found.
		// Note: Search from front to back, so the front-most object catches the dropped object.
		if(app.isIn3D) app.stagePane.visible = true;
		var possibleTargets:Array = stage.getObjectsUnderPoint(new Point(evt.stageX / app.scaleX, evt.stageY / app.scaleY));
		if(app.isIn3D) {
			app.stagePane.visible = false;
			if(possibleTargets.length == 0 && app.stagePane.scrollRect.contains(app.stagePane.mouseX, app.stagePane.mouseY))
				possibleTargets.push(app.stagePane);
		}
		possibleTargets.reverse();
		var tried:Array = [];
		for each (var o:* in possibleTargets) {
			while (o) { // see if some parent can handle the drop
				if (tried.indexOf(o) == -1) {
					if (('handleDrop' in o) && o.handleDrop(droppedObj)) return true;
					tried.push(o);
				}
				o = o.parent;
			}
		}
		return false;
	}

	private function drop(evt:MouseEvent):void {
		if (carriedObj == null) return;
		if(carriedObj is DisplayObject) carriedObj.cacheAsBitmap = false;
		carriedObj.stopDrag();
		removeDropShadowFrom(carriedObj);
		carriedObj.parent.removeChild(carriedObj);

		if (!dropHandled(carriedObj, evt)) {
			if (carriedObj is Block) {
				Block(carriedObj).restoreOriginalState();
			} else if (originalParent) { // put carriedObj back where it came from
				carriedObj.x = originalPosition.x;
				carriedObj.y = originalPosition.y;
				carriedObj.scaleX = carriedObj.scaleY = originalScale;
				originalParent.addChild(carriedObj);
				if (carriedObj is ScratchSprite) {
					var ss:ScratchSprite = carriedObj as ScratchSprite;
					ss.updateCostume();
					ss.updateBubble();
				}
			}
		}
		app.scriptsPane.draggingDone();
		carriedObj = null;
		originalParent = null;
		originalPosition = null;
	}

	private function addDropShadowTo(o:DisplayObject):void {
		var f:DropShadowFilter = new DropShadowFilter();
		var blockScale:Number = (app.scriptsPane) ? app.scriptsPane.scaleX : 1;
		f.distance = 8 * blockScale;
		f.blurX = f.blurY = 2;
		f.alpha = 0.4;
		o.filters = o.filters.concat([f]);
	}

	private function removeDropShadowFrom(o:DisplayObject):void {
		var newFilters:Array = [];
		for each (var f:* in o.filters) {
			if (!(f is DropShadowFilter)) newFilters.push(f);
		}
		o.filters = newFilters;
	}

	public function showBubble(text:String, x:Number, y:Number, width:Number = 0):void {
		hideBubble();
		bubble = new TalkBubble(text || ' ', 'say', 'result', this);
		bubbleStartX = stage.mouseX;
		bubbleStartY = stage.mouseY;
		var bx:Number = x + width;
		var by:Number = y - bubble.height;
		if (bx + bubble.width > stage.stageWidth - bubbleMargin && x - bubble.width > bubbleMargin) {
			bx = x - bubble.width;
			bubble.setDirection('right');
		} else {
			bubble.setDirection('left');
		}
		bubble.x = Math.max(bubbleMargin, Math.min(stage.stageWidth - bubbleMargin, bx));
		bubble.y = Math.max(bubbleMargin, Math.min(stage.stageHeight - bubbleMargin, by));

		var f:DropShadowFilter = new DropShadowFilter();
		f.distance = 4;
		f.blurX = f.blurY = 8;
		f.alpha = 0.2;
		bubble.filters = bubble.filters.concat(f);

		stage.addChild(bubble);
	}

	public function hideBubble():void {
		if (bubble) {
			stage.removeChild(bubble);
			bubble = null;
		}
	}

	/* Debugging */

	private var debugSelection:DisplayObject;

	private function showDebugFeedback(evt:MouseEvent):void {
		// Highlights the clicked DisplayObject and prints it in the debug console.
		// Multiple clicks walk up the display hierarchy. This is useful for understanding
		// the structure of the UI.

		evt.stopImmediatePropagation(); // don't let the clicked object handle this event
		gesture = "debug"; // prevent mouseMove and mouseUp processing

		var stage:DisplayObject = evt.target.stage;
		if (debugSelection != null) {
			removeDebugGlow(debugSelection);
			if (debugSelection.getRect(stage).containsPoint(new Point(stage.mouseX, stage.mouseY))) {
				debugSelection = debugSelection.parent;
			} else {
				debugSelection = DisplayObject(evt.target);
			}
		} else {
			debugSelection = DisplayObject(evt.target);
		}
		if (debugSelection is Stage) {
			debugSelection = null;
			return;
		}
		trace(debugSelection);
		addDebugGlow(debugSelection);
	}

	private function addDebugGlow(o:DisplayObject):void {
		var newFilters:Array = [];
		if (o.filters != null) newFilters = o.filters;
		var f:GlowFilter = new GlowFilter(0xFFFF00);
		f.strength = 15;
		f.blurX = f.blurY = 6;
		f.inner = true;
		newFilters.push(f);
		o.filters = newFilters;
	}

	private function removeDebugGlow(o:DisplayObject):void {
		var newFilters:Array = [];
		for each (var f:* in o.filters) {
			if (!(f is GlowFilter)) newFilters.push(f);
		}
		o.filters = newFilters;
	}

}}
