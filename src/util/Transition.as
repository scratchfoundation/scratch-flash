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

package util {
	import flash.utils.getTimer;

public class Transition {

	private static var activeTransitions:Array = [];

	private var interpolate:Function;
	private var setValue:Function;
	private var startValue:*;
	private var endValue:*;
	private var delta:*;
	private var whenDone:Function;
	private var startMSecs:uint;
	private var duration:uint;

	public function Transition(interpolate:Function, setValue:Function, startValue:*, endValue:*, secs:Number, whenDone:Function) {
		// Create a transition animation between two values (either scalars or Arrays).
		this.interpolate = interpolate;
		this.setValue = setValue;
		this.startValue = startValue;
		this.endValue = endValue;
		this.whenDone = whenDone;
		if (startValue is Array) {
			delta = [];
			for (var i:int = 0; i < startValue.length; i++) {
				this.delta.push(endValue[i] - startValue[i]);
			}
		} else {
			delta = endValue - startValue;
		}
		startMSecs = getTimer();
		duration = 1000 * secs;
	}

	public static function linear(setValue:Function, startValue:*, endValue:*, secs:Number, whenDone:Function = null):void {
		activeTransitions.push(new Transition(linearFunc, setValue, startValue, endValue, secs, whenDone));
	}

	public static function quadratic(setValue:Function, startValue:*, endValue:*, secs:Number, whenDone:Function = null):void {
		activeTransitions.push(new Transition(quadraticFunc, setValue, startValue, endValue, secs, whenDone));
	}

	public static function cubic(setValue:Function, startValue:*, endValue:*, secs:Number, whenDone:Function = null):void {
		activeTransitions.push(new Transition(cubicFunc, setValue, startValue, endValue, secs, whenDone));
	}

	public static function step(evt:*):void {
		if (activeTransitions.length == 0) return;
		var now:uint = getTimer();
		var newActive:Array = [];
		for each (var t:Transition in activeTransitions) {
			 if (t.apply(now)) newActive.push(t);
		}
		activeTransitions = newActive;
	}

	private function apply(now:uint):Boolean {
		var msecs:int = now - startMSecs;
		if (msecs < 50) { // ensure that start value is processed for at least one frame
			setValue(startValue);
			return true;
		}
		var t:Number = (now - startMSecs) / duration;
		if (t > 1.0) {
			setValue(endValue);
			if (whenDone != null) whenDone();
			return false;
		}
		if (startValue is Array) {
			var a:Array = [];
			for (var i:int = 0; i < startValue.length; i++) {
				a.push(startValue[i] + (delta[i] * (1.0 - interpolate(1.0 - t))));
			}
			setValue(a);
		} else {
			setValue(startValue + (delta * (1.0 - interpolate(1.0 - t))));
		}
		return true;
	}

	// Transition functions:
	private static function linearFunc(t:Number):Number { return t }
	private static function quadraticFunc(t:Number):Number { return t * t }
	private static function cubicFunc(t:Number):Number { return t * t * t }

}}
