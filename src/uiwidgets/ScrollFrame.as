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

// ScrollFrame.as
// John Maloney, November 2010
//
// A ScrollFrame allows the user to view and scroll it's contents, an instance
// of ScrollFrameContents or one of its subclasses. The frame can have an outer
// frame or be undecorated. The default corner radius can be changed (make it
// zero for square corners).

// It updates its size to include all of its children, ensures that children do not have
// negative positions (which are outside the scroll range), and can have a color or an
// optional background texture. Set hExtra or vExtra to provide some additional empty
// space to the right or bottom of the content.
//
// Note: The client should call updateSize() after adding or removing contents.

package uiwidgets {
import flash.display.*;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filters.GlowFilter;
import flash.geom.Rectangle;

import org.gestouch.events.GestureEvent;
import org.gestouch.gestures.TransformGesture;

import ui.dragdrop.DropTarget;

public class ScrollFrame extends Sprite implements DropTarget {

	public var contents:ScrollFrameContents;
	public var allowHorizontalScrollbar:Boolean = true;

	private static const decayFactor:Number = 0.95;	// velocity decay (make zero to stop instantly)
	private static const stopThreshold:Number = 0.4;	// stop when velocity is below threshold
	private const cornerRadius:int = 0;
	private const useFrame:Boolean = false;

	private var scrollbarThickness:int = 9;

	private var shadowFrame:Shape;
	private var scrollbarStyle:int;
	private var hScrollbar:Scrollbar;
	private var vScrollbar:Scrollbar;

	private var dragScrolling:Boolean;
	private var xOffset:int;
	private var yOffset:int;
	private var xHistory:Array;
	private var yHistory:Array;
	private var xVelocity:Number = 0;
	private var yVelocity:Number = 0;
	private var contentW:Number;
	private var contentH:Number;
	private var contentDirty:Boolean;

	private var panGesture:TransformGesture;

	public function ScrollFrame(dragScrolling:Boolean = false, scrollbarStyle:int = 0) {
		this.scrollbarStyle = scrollbarStyle || Scrollbar.STYLE_DEFAULT;
		if (dragScrolling) scrollbarThickness = Scrollbar.STYLE_DEFAULT ? 3 : 5;
		mask = new Shape();
		addChild(mask);
		if (useFrame) addShadowFrame(); // adds a shadow to top and left
		setWidthHeight(100, 100);
		vScrollbar = new Scrollbar(scrollbarThickness, 50, setVScroll, scrollbarStyle);
		vScrollbar.alpha = idleAlpha;
		addChild(vScrollbar);
		setContents(new ScrollFrameContents());
		addEventListener(ScrollFrameContents.INTERACTION_BEGAN, handleContentInteraction);
		enableScrollWheel('vertical');
		if (dragScrolling) enableDragScrolling();
	}

	public function handleDrop(obj:Object):Boolean {
		if (contents is DropTarget) return (contents as DropTarget).handleDrop(obj);

		return false;
	}

	private function handleContentInteraction(event:Event):void {
		// Stop any scrolling
		if (panGesture) {
			panGesture.reset();
		}

		// Make sure the content is visible
		var b:Rectangle = event.target.getBounds(mask);
		if (b.bottom > mask.height) {
			contents.y -= b.bottom - mask.height;
		}
	}

	public function enableDragScrolling(dragGesture:TransformGesture = null):void {
		dragScrolling = true;
		if (dragGesture) {
			panGesture = dragGesture;
			panGesture.target = this;
		}
		else {
			panGesture = new TransformGesture(this);
		}
		panGesture.addEventListener(GestureEvent.GESTURE_BEGAN, onPanGestureBegan);
		panGesture.addEventListener(GestureEvent.GESTURE_CHANGED, onPanGestureChanged);
		panGesture.addEventListener(GestureEvent.GESTURE_ENDED, onPanGestureEnded);
	}

	public function dispose():void {
		if (panGesture) {
			panGesture.dispose();
			panGesture = null;
		}
	}

	public function setWidthHeight(w:int, h:int):void {
		drawShape(Shape(mask).graphics, w, h);
		if (contents) {
			graphics.clear();
			graphics.beginFill(contents.color);
			graphics.drawRect(0, 0, w, h);
			graphics.endFill();
		}

		if (shadowFrame) drawShape(shadowFrame.graphics, w, h);
		if (contents) contents.updateSize();
		fixLayout();
	}

	private function drawShape(g:Graphics, w:int, h:int):void {
		g.clear();
		g.beginFill(0xFF00, 1);
		g.drawRect(0, 0, w, h);
		g.endFill();
	}

	private function addShadowFrame():void {
		// Adds a shadow on top and left to make contents appear inset.
		shadowFrame = new Shape();
		addChild(shadowFrame);
		var f:GlowFilter = new GlowFilter(0x0F0F0F);
		f.blurX = f.blurY = 5;
		f.alpha = 0.2;
		f.inner = true;
		f.knockout = true;
		shadowFrame.filters = [f];
	}

	public function setContents(newContents:Sprite):void {
		if (contents) {
			contents.removeEventListener(Event.ADDED, contentChanged);
			contents.removeEventListener(Event.REMOVED, contentChanged);
			this.removeChild(contents);
		}
		contents = newContents as ScrollFrameContents;
		contents.x = contents.y = 0;
		addChildAt(contents, 1);
		contents.updateSize();
		updateScrollbars();
		contentDirty = true;
		contents.addEventListener(Event.ADDED, contentChanged, false, 0, true);
		contents.addEventListener(Event.REMOVED, contentChanged, false, 0, true);
	}

	private function contentChanged(e:Event):void {
		contentDirty = true;
	}

	private var scrollWheelHorizontal:Boolean;

	public function enableScrollWheel(type:String):void {
		// Enable or disable the scroll wheel.
		// Types other than 'vertical' or 'horizontal' disable the scroll wheel.
		removeEventListener(MouseEvent.MOUSE_WHEEL, handleScrollWheel);
		if (('horizontal' == type) || ('vertical' == type)) {
			addEventListener(MouseEvent.MOUSE_WHEEL, handleScrollWheel);
			scrollWheelHorizontal = ('horizontal' == type);
		}
	}

	private function handleScrollWheel(evt:MouseEvent):void {
		var delta:int = 2 * evt.delta;
		if (scrollWheelHorizontal) {
			xVelocity = delta;
//			contents.x = Math.min(0, Math.max(contents.x + delta, -maxScrollH()));
		} else {
			yVelocity = delta;
//			contents.y = Math.min(0, Math.max(contents.y + delta, -maxScrollV()));
		}

		if (!hasEventListener(Event.ENTER_FRAME)) addEventListener(Event.ENTER_FRAME, step);
		updateScrollbarVisibility();
	}

	private const idleAlpha:Number = 0.3;
	public function showHScrollbar(show:Boolean):void {
		if (show && !hScrollbar) {
			hScrollbar = new Scrollbar(50, scrollbarThickness, setHScroll, scrollbarStyle);
			addChild(hScrollbar);
			addChildAt(contents, 1);
		}
		if (hScrollbar) {
			hScrollbar.alpha = show ? 1 : idleAlpha;
			fixLayout();
		}
	}

	public function showVScrollbar(show:Boolean):void {
		if (vScrollbar) {
			vScrollbar.alpha = show ? 1 : idleAlpha
			fixLayout();
		}
	}

	public function visibleW():int { return mask.width }
	public function visibleH():int { return mask.height }

	public function updateScrollbars():void {
		if (hScrollbar) hScrollbar.update(-contents.x / maxScrollH(), visibleW() / getContentW());
		if (vScrollbar) vScrollbar.update(-contents.y / maxScrollV(), visibleH() / getContentH());
	}

	public function updateScrollbarVisibility():void {
		// Update scrollbar visibility when not in dragScrolling mode.
		// Called by the client after adding/removing content.
		//if (dragScrolling) return;
		var shouldShow:Boolean, doesShow:Boolean;
		shouldShow = (visibleW() < getContentW()) && allowHorizontalScrollbar && (!dragScrolling || xVelocity);
		doesShow = hScrollbar && hScrollbar.alpha == 1;
		if (shouldShow != doesShow) showHScrollbar(shouldShow);
		shouldShow = visibleH() < getContentH() && (!dragScrolling || yVelocity);
		doesShow = vScrollbar && vScrollbar.alpha == 1;
		if (shouldShow != doesShow) showVScrollbar(shouldShow);
		updateScrollbars();
	}

	private function setHScroll(frac:Number):void {
		contents.x = -frac * maxScrollH();
		xVelocity = yVelocity = 0;
	}

	private function setVScroll(frac:Number):void {
		contents.y = -frac * maxScrollV();
		xVelocity = yVelocity = 0;
	}

	private function getContentW():Number {
		if (contentDirty) {
			contentW = contents.width;
			contentH = contents.height;
			contentDirty = false;
		}

		return contentW;
	}

	private function getContentH():Number {
		if (contentDirty) {
			contentW = contents.width;
			contentH = contents.height;
			contentDirty = false;
		}

		return contentH;
	}

	public function maxScrollH():int {
		return Math.max(0, getContentW() - visibleW());
	}

	public function maxScrollV():int {
		return Math.max(0, getContentH() - visibleH());
	}

	public function canScrollLeft():Boolean {return contents.x < 0}
	public function canScrollRight():Boolean {return contents.x > -maxScrollH()}
	public function canScrollUp():Boolean {return contents.y < 0}
	public function canScrollDown():Boolean {return contents.y > -maxScrollV()}

	private function fixLayout():void {
		var inset:int = 2;
		if (hScrollbar) {
			hScrollbar.setWidthHeight(mask.width - 14, hScrollbar.h);
			hScrollbar.x = inset;
			hScrollbar.y = mask.height - hScrollbar.h - inset;
		}
		if (vScrollbar) {
			vScrollbar.setWidthHeight(vScrollbar.w, mask.height - (2 * inset));
			vScrollbar.x = mask.width - vScrollbar.w - inset;
			vScrollbar.y = inset;
		}
		updateScrollbars();
	}

	public function constrainScroll():void {
		contents.x = Math.max(-maxScrollH(), Math.min(contents.x, 0));
		contents.y = Math.max(-maxScrollV(), Math.min(contents.y, 0));

		var h:Number = mask.height;
		for (var i:int=0; i<contents.numChildren; ++i) {
			var dObj:DisplayObject = contents.getChildAt(i);
			if (dObj != mask) {
				var yy:Number = dObj.y + contents.y;
				var v:Boolean = (yy < h && yy + dObj.height > 0);
				if (dObj.visible != v)
					dObj.visible = v;
			}
		}
	}

	protected function onPanGestureBegan(event:GestureEvent):void {
		xHistory = [0,0,0];
		yHistory = [0,0,0];
		contents.mouseChildren = false;
		contents.mouseEnabled = false;
//		contents.cacheAsBitmap = true;
//		Scratch.app.cacheAsBitmap = true;
		removeEventListener(Event.ENTER_FRAME, step);
		onPanGestureChanged(event);
	}

	protected function onPanGestureChanged(event:GestureEvent):void {
		var panGesture:TransformGesture = event.target as TransformGesture;

		xVelocity = allowHorizontalScrollbar ? panGesture.offsetX : 0;
		yVelocity = panGesture.offsetY;

		xHistory.push(panGesture.offsetX);
		yHistory.push(panGesture.offsetY);
		xHistory.shift();
		yHistory.shift();

		contents.x = contents.x + xVelocity;
		contents.y = contents.y + yVelocity;
		constrainScroll();

		updateScrollbarVisibility();
	}

	protected function onPanGestureEnded(event:GestureEvent):void {
		var historyLength:uint = xHistory.length;
		xVelocity = yVelocity = 0;
		for (var i:uint = 0; i < historyLength; ++i) {
			xVelocity += xHistory[i];
			yVelocity += yHistory[i];
		}
		var scaleBy:Number = 0.75 / historyLength;
		xVelocity *= scaleBy;
		yVelocity *= scaleBy;

		if ((Math.abs(xVelocity) < 2) && (Math.abs(yVelocity) < 2)) {
			xVelocity = yVelocity = 0;
		}
		addEventListener(Event.ENTER_FRAME, step);
		contents.mouseChildren = true;
		contents.mouseEnabled = true;
//		contents.cacheAsBitmap = false;
//		Scratch.app.cacheAsBitmap = false;
	}

	public function shutdown():void {}

	private function step(evt:Event):void {
		// Implements inertia after releasing the mouse when dragScrolling.
		xVelocity = decayFactor * xVelocity;
		yVelocity = decayFactor * yVelocity;
		if (Math.abs(xVelocity) < stopThreshold) xVelocity = 0;
		if (Math.abs(yVelocity) < stopThreshold) yVelocity = 0;
		if (allowHorizontalScrollbar) contents.x = contents.x + xVelocity;
		contents.y = contents.y + yVelocity;

		contents.x = Math.max(-maxScrollH(), Math.min(contents.x, 0));
		contents.y = Math.max(-maxScrollV(), Math.min(contents.y, 0));

		if ((contents.x > -1) || ((contents.x - 1) < -maxScrollH())) xVelocity = 0; // hit end, so stop
		if ((contents.y > -1) || ((contents.y - 1) < -maxScrollV())) yVelocity = 0; // hit end, so stop
		constrainScroll();
		updateScrollbars();

		if ((xVelocity == 0) && (yVelocity == 0)) { // stopped
			if (hScrollbar) hScrollbar.allowDragging(true);
			if (vScrollbar) vScrollbar.allowDragging(true);
			showHScrollbar(false);
			showVScrollbar(false);
			contents.mouseChildren = true;
			removeEventListener(Event.ENTER_FRAME, step);
		}
	}

}}
