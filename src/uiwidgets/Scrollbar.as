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

package uiwidgets {
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.events.Event;
	import flash.filters.BevelFilter;
	import flash.geom.Point;
	import util.DragClient

public class Scrollbar extends Sprite implements DragClient {

	public static var color:int = 0xCBCDCF;
	public static var sliderColor:int = 0x424447;
	public static var cornerRadius:int = 9;
	public static var look3D:Boolean = false;

	public var w:int, h:int;

	private var base:Shape;
	private var slider:Shape;
	private var positionFraction:Number = 0;		// scroll amount (range: 0-1)
	private var sliderSizeFraction:Number = 0.1;	// slider size, used to show fraction of docutment vislbe (range: 0-1)
	private var isVertical:Boolean;
	private var dragOffset:int;
	private var scrollFunction:Function;

	public function Scrollbar(w:int, h:int, scrollFunction:Function = null) {
		this.scrollFunction = scrollFunction;
		base = new Shape();
		slider = new Shape();
		addChild(base);
		addChild(slider);
		if (look3D) addFilters();
		alpha = 0.7;
		setWidthHeight(w, h);
		allowDragging(true);
	}

	public function scrollValue():Number { return positionFraction }
	public function sliderSize():Number { return sliderSizeFraction }

	public function update(position:Number, sliderSize:Number = 0):Boolean {
		// Update the scrollbar scroll position (0-1) and slider size (0-1)
		var newPosition:Number = Math.max(0, Math.min(position, 1));
		var newSliderSize:Number = Math.max(0, Math.min(sliderSize, 1));
		if ((newPosition != positionFraction) || (newSliderSize != sliderSizeFraction)) {
			positionFraction = newPosition;
			sliderSizeFraction = newSliderSize;
			drawSlider();
			slider.visible = newSliderSize < 0.99;
		}
		return slider.visible;
	}

	public function setWidthHeight(w:int, h:int):void {
		this.w = w;
		this.h = h;
		base.graphics.clear();
		base.graphics.beginFill(color);
		base.graphics.drawRoundRect(0, 0, w, h, cornerRadius, cornerRadius);
		base.graphics.endFill();
		drawSlider();
	}

	private function drawSlider():void {
		var w:int, h:int, maxSize:int;
		isVertical = base.height > base.width;
		if (isVertical) {
			maxSize = base.height;
			w = base.width;
			h = Math.max(10, Math.min(sliderSizeFraction * maxSize, maxSize));
			slider.x = 0;
			slider.y = positionFraction * (this.height - h);
		} else {
			maxSize = base.width;
			w = Math.max(10, Math.min(sliderSizeFraction * maxSize, maxSize));
			h = base.height;
			slider.x = positionFraction * (this.width - w);
			slider.y = 0;
		}
		slider.graphics.clear();
		slider.graphics.beginFill(sliderColor);
		slider.graphics.drawRoundRect(0, 0, w, h, cornerRadius, cornerRadius);
		slider.graphics.endFill();
	}

	private function addFilters():void {
		var f:BevelFilter = new BevelFilter();
		f.distance = 1;
		f.blurX = f.blurY = 2;
		f.highlightAlpha = 0.5;
		f.shadowAlpha = 0.5;
		f.angle = 225;
		base.filters = [f];
		f = new BevelFilter();
		f.distance = 2;
		f.blurX = f.blurY = 4;
		f.highlightAlpha = 1.0;
		f.shadowAlpha = 0.5;
		slider.filters = [f];
	}

	public function allowDragging(flag:Boolean):void {
		if (flag) addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		else removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
	}

	private function mouseDown(evt:MouseEvent):void {
		Scratch.app.gh.setDragClient(this, evt);
	}

	public function dragBegin(evt:MouseEvent):void {
		var sliderOrigin:Point = slider.localToGlobal(new Point(0, 0));
		if (isVertical) {
			dragOffset = evt.stageY - sliderOrigin.y;
			dragOffset = Math.max(5, Math.min(dragOffset, slider.height - 5));
		} else {
			dragOffset = evt.stageX - sliderOrigin.x;
			dragOffset = Math.max(5, Math.min(dragOffset, slider.width - 5));
		}
		dispatchEvent(new Event(Event.SCROLL));
		dragMove(evt);
	}

	public function dragMove(evt:MouseEvent):void {
		var range:int, frac:Number;
		var localP:Point = globalToLocal(new Point(evt.stageX, evt.stageY));
		if (isVertical) {
			range = base.height - slider.height;
			positionFraction = (localP.y - dragOffset) / range;
		} else {
			range = base.width - slider.width;
			positionFraction = (localP.x - dragOffset) / range;
		}
		positionFraction = Math.max(0, Math.min(positionFraction, 1));
		drawSlider();
		if (scrollFunction != null) scrollFunction(positionFraction);
	}

	public function dragEnd(evt:MouseEvent):void {
		dispatchEvent(new Event(Event.COMPLETE));
	}
}}
