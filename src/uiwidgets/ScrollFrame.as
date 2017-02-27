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
	import flash.events.*;
	import flash.filters.GlowFilter;
	import util.DragClient;

public class ScrollFrame extends Sprite implements DragClient {

	public var contents:ScrollFrameContents;
	public var allowHorizontalScrollbar:Boolean = true;
	public var allowVerticalScrollbar:Boolean = true;

	private const decayFactor:Number = 0.95;	// velocity decay (make zero to stop instantly)
	private const stopThreshold:Number = 0.4;	// stop when velocity is below threshold
	private const cornerRadius:int = 0;
	private const useFrame:Boolean = false;

	private var scrollbarThickness:int = 9;

	private var shadowFrame:Shape;
	private var hScrollbar:Scrollbar;
	private var vScrollbar:Scrollbar;

	private var dragScrolling:Boolean;
	private var xOffset:int;
	private var yOffset:int;
	private var xHistory:Array;
	private var yHistory:Array;
	private var xVelocity:Number = 0;
	private var yVelocity:Number = 0;

	public function ScrollFrame(dragScrolling:Boolean = false) {
		this.dragScrolling = dragScrolling;
		if (dragScrolling) scrollbarThickness = 3;
		mask = new Shape();
		addChild(mask);
		if (useFrame) addShadowFrame(); // adds a shadow to top and left
		setWidthHeight(100, 100);
		setContents(new ScrollFrameContents());
		addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		enableScrollWheel('vertical');
	}

	public function setWidthHeight(w:int, h:int):void {
		drawShape(Shape(mask).graphics, w, h);
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
		if (contents) this.removeChild(contents);
		contents = newContents as ScrollFrameContents;
		contents.x = contents.y = 0;
		addChildAt(contents, 1);
		contents.updateSize();
		updateScrollbars();
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
		var delta:int = 10 * evt.delta;
		if (scrollWheelHorizontal != evt.shiftKey) {
			contents.x = Math.min(0, Math.max(contents.x + delta, -maxScrollH()));
		} else {
			contents.y = Math.min(0, Math.max(contents.y + delta, -maxScrollV()));
		}
		updateScrollbars();
	}

	public function showHScrollbar(show:Boolean):void {
		if (hScrollbar) {
			removeChild(hScrollbar);
			hScrollbar = null;
		}
		if (show) {
			hScrollbar = new Scrollbar(50, scrollbarThickness, setHScroll);
			addChild(hScrollbar);
		}
		addChildAt(contents, 1);
		fixLayout();
	}

	public function showVScrollbar(show:Boolean):void {
		if (vScrollbar) {
			removeChild(vScrollbar);
			vScrollbar = null;
		}
		if (show) {
			vScrollbar = new Scrollbar(scrollbarThickness, 50, setVScroll);
			addChild(vScrollbar);
		}
		addChildAt(contents, 1);
		fixLayout();
	}

	public function visibleW():int { return mask.width }
	public function visibleH():int { return mask.height }

	public function updateScrollbars():void {
		if (hScrollbar) hScrollbar.update(-contents.x / maxScrollH(), visibleW() / contents.width);
		if (vScrollbar) vScrollbar.update(-contents.y / maxScrollV(), visibleH() / contents.height);
	}

	public function updateScrollbarVisibility():void {
		// Update scrollbar visibility when not in dragScrolling mode.
		// Called by the client after adding/removing content.
		if (dragScrolling) return;
		var shouldShow:Boolean, doesShow:Boolean;
		shouldShow = (visibleW() < contents.width) && allowHorizontalScrollbar;
		doesShow = hScrollbar != null;
		if (shouldShow != doesShow) showHScrollbar(shouldShow);
		shouldShow = (visibleH() < contents.height) && allowVerticalScrollbar;
		doesShow = vScrollbar != null;
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

	public function maxScrollH():int {
		return Math.max(0, contents.width - visibleW());
	}

	public function maxScrollV():int {
		return Math.max(0, contents.height - visibleH());
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
	}

	private function mouseDown(evt:MouseEvent):void {
		if (evt.shiftKey || !dragScrolling) return;
		if (evt.target == contents) {
			Object(root).gh.setDragClient(this, evt);
			contents.mouseChildren = false; // disable mouse events while scrolling
		}
	}

	public function dragBegin(evt:MouseEvent):void {
		xHistory = [mouseX, mouseX, mouseX];
		yHistory = [mouseY, mouseY, mouseY];
		xOffset = mouseX - contents.x;
		yOffset = mouseY - contents.y;

		if (visibleW() < contents.width) showHScrollbar(true);
		if (visibleH() < contents.height) showVScrollbar(true);
		if (hScrollbar) hScrollbar.allowDragging(false);
		if (vScrollbar) vScrollbar.allowDragging(false);
		updateScrollbars();

		removeEventListener(Event.ENTER_FRAME, step);
	}

	public function dragMove(evt:MouseEvent):void {
		xHistory.push(mouseX);
		yHistory.push(mouseY);
		xHistory.shift();
		yHistory.shift();
		contents.x = mouseX - xOffset;
		contents.y = mouseY - yOffset;
		constrainScroll();
		updateScrollbars();
	}

	public function dragEnd(evt:MouseEvent):void {
		xVelocity = (xHistory[2] - xHistory[0]) / 1.5;
		yVelocity = (yHistory[2] - yHistory[0]) / 1.5;
		if ((Math.abs(xVelocity) < 2) && (Math.abs(yVelocity) < 2)) {
			xVelocity = yVelocity = 0;
		}
		addEventListener(Event.ENTER_FRAME, step);
	}

	private function step(evt:Event):void {
		// Implements inertia after releasing the mouse when dragScrolling.
		xVelocity = decayFactor * xVelocity;
		yVelocity = decayFactor * yVelocity;
		if (Math.abs(xVelocity) < stopThreshold) xVelocity = 0;
		if (Math.abs(yVelocity) < stopThreshold) yVelocity = 0;
		contents.x += xVelocity;
		contents.y += yVelocity;

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
