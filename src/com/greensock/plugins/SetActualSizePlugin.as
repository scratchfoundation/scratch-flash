/**
 * VERSION: 1.02
 * DATE: 10/2/2009
 * ACTIONSCRIPT VERSION: 3.0 
 * UPDATES AND DOCUMENTATION AT: http://www.TweenMax.com
 **/
package com.greensock.plugins {
	import com.greensock.*;
/**
 * Some components require resizing with setActualSize() instead of standard tweens of width/height in
 * order to scale properly. The SetActualSizePlugin accommodates this easily. You can define the width, 
 * height, or both. <br /><br />
 * 
 * <b>USAGE:</b><br /><br />
 * <code>
 * 		import com.greensock.TweenLite; <br />
 * 		import com.greensock.plugins.TweenPlugin; <br />
 * 		import com.greensock.plugins.SetActualSizePlugin; <br />
 * 		TweenPlugin.activate([SetActualSizePlugin]); //activation is permanent in the SWF, so this line only needs to be run once.<br /><br />
 * 
 * 		TweenLite.to(myComponent, 1, {setActualSize:{width:200, height:30}});<br /><br />
 * </code>
 * 
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 */
	public class SetActualSizePlugin extends TweenPlugin {
		/** @private **/
		public static const API:Number = 1.0; //If the API/Framework for plugins changes in the future, this number helps determine compatibility
		
		/** @private **/
		public var width:Number;
		/** @private **/
		public var height:Number;
		
		/** @private **/
		protected var _target:Object;
		/** @private **/
		protected var _setWidth:Boolean;
		/** @private **/
		protected var _setHeight:Boolean;
		/** @private **/
		protected var _hasSetSize:Boolean;
		
		/** @private **/
		public function SetActualSizePlugin() {
			super();
			this.propName = "setActualSize";
			this.overwriteProps = ["setActualSize","setSize","width","height","scaleX","scaleY"];
			this.round = true;
		}
		
		/** @private **/
		override public function onInitTween(target:Object, value:*, tween:TweenLite):Boolean {
			_target = target;
			_hasSetSize = Boolean("setActualSize" in _target);
			if ("width" in value && _target.width != value.width) {
				addTween((_hasSetSize) ? this : _target, "width", _target.width, value.width, "width");
				_setWidth = _hasSetSize;
			}
			if ("height" in value && _target.height != value.height) {
				addTween((_hasSetSize) ? this : _target, "height", _target.height, value.height, "height");
				_setHeight = _hasSetSize;
			}
			if (_tweens.length == 0) { //protects against occassions when the tween's start and end values are the same. In that case, the _tweens Array will be empty.
				_hasSetSize = false;
			}	
			return true;
		}
		
		/** @private **/
		override public function killProps(lookup:Object):void {
			super.killProps(lookup);
			if (_tweens.length == 0 || "setActualSize" in lookup) {
				this.overwriteProps = [];
			}
		}
		
		/** @private **/
		override public function set changeFactor(n:Number):void {
			updateTweens(n);
			if (_hasSetSize) {
				_target.setActualSize((_setWidth) ? this.width : _target.width, (_setHeight) ? this.height : _target.height);
			}
		}
		

	}
}