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
	import flash.display.DisplayObject;
import flash.display.*;
import flash.events.*;
import flash.filters.DropShadowFilter;
import flash.geom.*;
import flash.text.*;
import flash.utils.Dictionary;
import flash.utils.Timer;

import translation.Translator;

	public class SimpleTooltips {
		static private var instance:SimpleTooltip = null;
		/**
		 * Add a tooltip to a DisplayObject 
		 * @param dObj Attach the tooltip to this
		 * @param opts Options (just 'text' and 'direction' right now)
		 * 
		 */
		static public function add(dObj:DisplayObject, opts:Object):void {
			if(!instance) instance = new SimpleTooltip();
			instance.addTooltip(dObj, opts);
		}
		
		static public function hideAll():void {
			if(instance) instance.forceHide();
		}
		
		static public function showOnce(dObj:DisplayObject, opts:Object):void {
			if(!instance) instance = new SimpleTooltip();
			instance.showOnce(dObj, opts);
		}
	}
}

import flash.display.*;
import flash.events.*;
import flash.filters.DropShadowFilter;
import flash.geom.*;
import flash.text.*;
import flash.utils.Dictionary;
import flash.utils.Timer;

import translation.Translator;

class SimpleTooltip {
	// Map of DisplayObject => Strings
	private var tipObjs:Dictionary = new Dictionary();
	private var currentTipObj:DisplayObject;
	private var nextTipObj:DisplayObject;
	
	// Timing values (in milliseconds)
	private const delay:uint = 500;
	private const linger:uint = 1000;
	private const fadeIn:uint = 200;
	private const fadeOut:uint = 500;
	
	private const bgColor:uint = 0xfcfed4;
	
	// Timers
	private var showTimer:Timer;
	private var hideTimer:Timer;
	private var animTimer:Timer;
	
	private var sprite:Sprite;
	private var textField:TextField;
	private var stage:Stage;
	function SimpleTooltip() {
		// Setup timers
		showTimer = new Timer(delay);
		showTimer.addEventListener(TimerEvent.TIMER, eventHandler);
		hideTimer = new Timer(linger);
		hideTimer.addEventListener(TimerEvent.TIMER, eventHandler);
		
		// Setup display objects
		sprite = new Sprite();
		sprite.mouseEnabled = false;
		sprite.mouseChildren = false;
		sprite.filters = [new DropShadowFilter(4, 90, 0, 0.6, 12, 12, 0.8)];
		textField = new TextField();
		textField.autoSize = TextFieldAutoSize.LEFT;
		textField.selectable = false;
		textField.background = false;
		textField.defaultTextFormat = CSS.normalTextFormat;
		textField.textColor = CSS.buttonLabelColor;
		sprite.addChild(textField);
	}
	
	static private var instance:*;
	public function addTooltip(dObj:DisplayObject, opts:Object):void {
		if(!opts.hasOwnProperty('text') || !opts.hasOwnProperty('direction') ||
			['top', 'bottom', 'left', 'right'].indexOf(opts.direction) == -1) {
			trace('Invalid parameters!');
			return;
		}
		
		if(tipObjs[dObj] == null) {
			dObj.addEventListener(MouseEvent.MOUSE_OVER, eventHandler);
		}
		tipObjs[dObj] = opts;
	}
	
	private function eventHandler(evt:Event):void {
		switch(evt.type) {
			case MouseEvent.MOUSE_OVER:
				startShowTimer(evt.currentTarget as DisplayObject);
				break;
			case MouseEvent.MOUSE_OUT:
				(evt.currentTarget as DisplayObject).removeEventListener(MouseEvent.MOUSE_OUT, eventHandler);
				
				if(showTimer.running) {
					showTimer.reset();
					nextTipObj = null;
				}
				
				startHideTimer(evt.currentTarget as DisplayObject);
				break;
			case TimerEvent.TIMER:
				if(evt.target == showTimer) {
					startShow();
				}
				else {
					startHide(evt.target as Timer);
					if(evt.target != hideTimer) {
						(evt.target as Timer).removeEventListener(TimerEvent.TIMER, eventHandler);
					}
				}
				break;
		}
	}
	
	private function startShow():void {
		//trace('startShow()');
		showTimer.reset();
		hideTimer.reset();
		sprite.alpha = 0;
		var ttOpts:Object = tipObjs[nextTipObj];
		renderTooltip(ttOpts.text);
		currentTipObj = nextTipObj;
		
		// TODO: Make it fade in
		sprite.alpha = 1;
		stage.addChild(sprite);
		
		var pos:Point = getPos(ttOpts.direction);
		sprite.x = pos.x;
		sprite.y = pos.y;
	}
	
	public function showOnce(dObj:DisplayObject, ttOpts:Object):void {
		if(!stage && dObj.stage) stage = dObj.stage;
		//trace('showOnce()');
		forceHide();
		showTimer.reset();
		hideTimer.reset();
		sprite.alpha = 0;
		renderTooltip(ttOpts.text);
		currentTipObj = dObj;
		
		// TODO: Make it fade in
		sprite.alpha = 1;
		stage.addChild(sprite);
		
		var pos:Point = getPos(ttOpts.direction);
		sprite.x = pos.x;
		sprite.y = pos.y;
		
		// Show the tooltip for twice as long
		var myTimer:Timer = new Timer(5000);
		myTimer.addEventListener(TimerEvent.TIMER, eventHandler);
		myTimer.reset();
		myTimer.start();
	}
	
	private function getPos(direction:String):Point {
		var rect:Rectangle = currentTipObj.getBounds(stage);
		var pos:Point;
		switch(direction) {
			case 'right':
				pos = new Point(rect.right + 5, Math.round((rect.top + rect.bottom - sprite.height)/2));
				break;
			case 'left':
				pos = new Point(rect.left - 5 - sprite.width, Math.round((rect.top + rect.bottom - sprite.height)/2));
				break;
			case 'top':
				pos = new Point(Math.round((rect.left + rect.right - sprite.width)/2), rect.top - 4 - sprite.height);
				break;
			case 'bottom':
				pos = new Point(Math.round((rect.left + rect.right - sprite.width)/2), rect.bottom + 4);
				break;
		}
		if (pos.x < 0) pos.x = 0;
		if (pos.y < 0) pos.y = 0;
		return pos;
	}
	
	public function forceHide():void {
		startHide(hideTimer);
	}
	
	private function startHide(timer:Timer):void {
		//trace('startHide()');
		hideTimer.reset();
		currentTipObj = null;
		sprite.alpha = 0;
		if(sprite.parent) stage.removeChild(sprite);
	}
	
	private function renderTooltip(text:String):void {
		//trace('renderTooltip(\''+text+'\')');
		var g:Graphics = sprite.graphics;
		textField.text = Translator.map(text);
		g.clear();
		g.lineStyle(1, 0xCCCCCC);
		g.beginFill(bgColor);
		g.drawRect(0, 0, textField.textWidth + 5, textField.textHeight + 3);
		g.endFill();
	}
	
	private function startShowTimer(dObj:DisplayObject):void {
		//trace('startShowTimer()');
		if(!stage && dObj.stage) stage = dObj.stage;
		
		dObj.addEventListener(MouseEvent.MOUSE_OUT, eventHandler);
		
		if(dObj === currentTipObj) {
			hideTimer.reset();
			return;
		}
		
		if(tipObjs[dObj] is Object) {
			nextTipObj = dObj;
			
			showTimer.reset();
			showTimer.start();
		}
	}
	
	private function startHideTimer(dObj:DisplayObject):void {
		//trace('startHideTimer()');
		if(dObj !== currentTipObj) return;
		
		hideTimer.reset();
		hideTimer.start();
	}
}
