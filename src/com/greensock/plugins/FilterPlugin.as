/**
 * VERSION: 2.03
 * DATE: 10/22/2009
 * ACTIONSCRIPT VERSION: 3.0 
 * UPDATES AND DOCUMENTATION AT: http://www.TweenMax.com
 **/
package com.greensock.plugins {
	import com.greensock.core.*;
	
	import flash.filters.*;
/**
 * @private
 * Base class for all filter plugins (like blurFilter, colorMatrixFilter, glowFilter, etc.). Handles common routines. 
 * There is no reason to use this class directly.<br /><br />
 * 
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 */
	public class FilterPlugin extends TweenPlugin {
		/** @private **/
		public static const VERSION:Number = 2.03;
		/** @private **/
		public static const API:Number = 1.0; //If the API/Framework for plugins changes in the future, this number helps determine compatibility
		
		/** @private **/
		protected var _target:Object;
		/** @private **/
		protected var _type:Class;
		/** @private **/
		protected var _filter:BitmapFilter;
		/** @private **/
		protected var _index:int;
		/** @private **/
		protected var _remove:Boolean;
		
		/** @private **/
		public function FilterPlugin() {
			super();
		}
		
		/** @private **/
		protected function initFilter(props:Object, defaultFilter:BitmapFilter, propNames:Array):void {
			var filters:Array = _target.filters, p:String, i:int, colorTween:HexColorsPlugin;
			var extras:Object = (props is BitmapFilter) ? {} : props;
			_index = -1;
			if (extras.index != null) {
				_index = extras.index;
			} else {
				i = filters.length;
				while (i--) {
					if (filters[i] is _type) {
						_index = i;
						break;
					}
				}
			}
			if (_index == -1 || filters[_index] == null || extras.addFilter == true) {
				_index = (extras.index != null) ? extras.index : filters.length;
				filters[_index] = defaultFilter;
				_target.filters = filters;
			}
			_filter = filters[_index];
			
			if (extras.remove == true) {
				_remove = true;
				this.onComplete = onCompleteTween;
			}
			i = propNames.length;
			while (i--) {
				p = propNames[i];
				if (p in props && _filter[p] != props[p]) {
					if (p == "color" || p == "highlightColor" || p == "shadowColor") {
						colorTween = new HexColorsPlugin();
						colorTween.initColor(_filter, p, _filter[p], props[p]);
						_tweens[_tweens.length] = new PropTween(colorTween, "changeFactor", 0, 1, p, false);
					} else if (p == "quality" || p == "inner" || p == "knockout" || p == "hideObject") {
						_filter[p] = props[p];
					} else {
						addTween(_filter, p, _filter[p], props[p], p);
					}
				}
			}
		}
		
		/** @private **/
		public function onCompleteTween():void {
			if (_remove) {
				var filters:Array = _target.filters;
				if (!(filters[_index] is _type)) { //a filter may have been added or removed since the tween began, changing the index.
					var i:int = filters.length;
					while (i--) {
						if (filters[i] is _type) {
							filters.splice(i, 1);
							break;
						}
					}
				} else {
					filters.splice(_index, 1);
				}
				_target.filters = filters;
			}
		}
		
		/** @private **/
		override public function set changeFactor(n:Number):void {
			var i:int = _tweens.length, ti:PropTween, filters:Array = _target.filters;
			while (i--) {
				ti = _tweens[i];
				ti.target[ti.property] = ti.start + (ti.change * n);
			}
			
			if (!(filters[_index] is _type)) { //a filter may have been added or removed since the tween began, changing the index.
				i = _index = filters.length; //default (in case it was removed)
				while (i--) {
					if (filters[i] is _type) {
						_index = i;
						break;
					}
				}
			}
			filters[_index] = _filter;
			_target.filters = filters;
		}
		
	}
}