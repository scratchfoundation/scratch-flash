/**
 * VERSION: 1.61
 * DATE: 2010-09-18
 * ACTIONSCRIPT VERSION: 3.0 
 * UPDATES AND DOCUMENTATION AT: http://www.TweenMax.com
 **/
package com.greensock.plugins {
	import com.greensock.*;
	
/**
 * Tweens numbers in an Array. <br /><br />
 * 
 * <b>USAGE:</b><br /><br />
 * <code>
 * 		import com.greensock.TweenLite; <br />
 * 		import com.greensock.plugins.TweenPlugin; <br />
 * 		import com.greensock.plugins.EndArrayPlugin; <br />
 * 		TweenPlugin.activate([EndArrayPlugin]); //activation is permanent in the SWF, so this line only needs to be run once.<br /><br />
 * 
 * 		var myArray:Array = [1,2,3,4];<br />
 * 		TweenLite.to(myArray, 1.5, {endArray:[10,20,30,40]}); <br /><br />
 * </code>
 * 
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 */	
	public class EndArrayPlugin extends TweenPlugin {
		/** @private **/
		public static const API:Number = 1.0; //If the API/Framework for plugins changes in the future, this number helps determine compatibility
		
		/** @private **/
		protected var _a:Array;
		/** @private **/
		protected var _info:Array = [];
		
		/** @private **/
		public function EndArrayPlugin() {
			super();
			this.propName = "endArray"; //name of the special property that the plugin should intercept/manage
			this.overwriteProps = ["endArray"];
		}
		
		/** @private **/
		override public function onInitTween(target:Object, value:*, tween:TweenLite):Boolean {
			if (!(target is Array) || !(value is Array)) {
				return false;
			}
			init(target as Array, value);
			return true;
		}
		
		/** @private **/
		public function init(start:Array, end:Array):void {
			_a = start;
			var i:int = end.length;
			while (i--) {
				if (start[i] != end[i] && start[i] != null) {
					_info[_info.length] = new ArrayTweenInfo(i, _a[i], end[i] - _a[i]);
				}
			}
		}
		
		/** @private **/
		override public function set changeFactor(n:Number):void {
			var i:int = _info.length, ti:ArrayTweenInfo;
			if (this.round) {
				var val:Number;
				while (i--) {
					ti = _info[i];
					val = ti.start + (ti.change * n);
					if (val > 0) {
						_a[ti.index] = (val + 0.5) >> 0; //4 times as fast as Math.round()
					} else {
						_a[ti.index] = (val - 0.5) >> 0;
					}
				}
			} else {
				while (i--) {
					ti = _info[i];
					_a[ti.index] = ti.start + (ti.change * n);
				}
			}
		}
		
	}
}

internal class ArrayTweenInfo {
	public var index:uint;
	public var start:Number;
	public var change:Number;
	
	public function ArrayTweenInfo(index:uint, start:Number, change:Number) {
		this.index = index;
		this.start = start;
		this.change = change;
	}
}