/**
 * VERSION: 2.11
 * DATE: 11/14/2009
 * ACTIONSCRIPT VERSION: 3.0 
 * UPDATES AND DOCUMENTATION AT: http://www.TweenMax.com
 **/
package com.greensock.plugins {
	import com.greensock.*;
/**
 * Toggles the visibility at the end of a tween. For example, if you want to set <code>visible</code> to false
 * at the end of the tween, do:<br /><br /><code>
 * 
 * TweenLite.to(mc, 1, {x:100, visible:false});<br /><br /></code>
 * 
 * The <code>visible</code> property is forced to true during the course of the tween. <br /><br />
 * 
 * <b>USAGE:</b><br /><br />
 * <code>
 * 		import com.greensock.TweenLite; <br />
 * 		import com.greensock.plugins.TweenPlugin; <br />
 * 		import com.greensock.plugins.VisiblePlugin; <br />
 * 		TweenPlugin.activate([VisiblePlugin]); //activation is permanent in the SWF, so this line only needs to be run once.<br /><br />
 * 
 * 		TweenLite.to(mc, 1, {x:100, visible:false}); <br /><br />
 * </code>
 * 
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 */
	public class VisiblePlugin extends TweenPlugin {
		/** @private **/
		public static const API:Number = 1.0; //If the API/Framework for plugins changes in the future, this number helps determine compatibility
		
		/** @private **/
		protected var _target:Object;
		/** @private **/
		protected var _tween:TweenLite;
		/** @private **/
		protected var _visible:Boolean;
		/** @private **/
		protected var _initVal:Boolean;
		
		/** @private **/
		public function VisiblePlugin() {
			super();
			this.propName = "visible";
			this.overwriteProps = ["visible"];
		}
		
		/** @private **/
		override public function onInitTween(target:Object, value:*, tween:TweenLite):Boolean {
			_target = target;
			_tween = tween;
			_initVal = _target.visible;
			_visible = Boolean(value);
			return true;
		}
		
		/** @private **/
		override public function set changeFactor(n:Number):void {
			if (n == 1 && (_tween.cachedDuration == _tween.cachedTime || _tween.cachedTime == 0)) { //a changeFactor of 1 doesn't necessarily mean the tween is done - if the ease is Elastic.easeOut or Back.easeOut for example, they could hit 1 mid-tween. The reason we check to see if cachedTime is 0 is for from() tweens
				_target.visible = _visible;
			} else {
				_target.visible = _initVal; //in case a completed tween is re-rendered at an earlier time.
			}
		}

	}
}