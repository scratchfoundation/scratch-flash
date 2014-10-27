/**
 * VERSION: 2.3
 * DATE: 10/17/2009
 * ACTIONSCRIPT VERSION: 3.0 
 * UPDATES AND DOCUMENTATION AT: http://www.TweenMax.com
 **/
package com.greensock.plugins {
	import com.greensock.*;
/**
 * Tweening "autoAlpha" is exactly the same as tweening an object's "alpha" except that it ensures 
 * that the object's "visible" property is true until autoAlpha reaches zero at which point it will 
 * toggle the "visible" property to false. That not only improves rendering performance in the Flash Player, 
 * but also hides DisplayObjects so that they don't interact with the mouse. <br /><br />
 * 
 * <b>USAGE:</b><br /><br />
 * <code>
 * 		import com.greensock.TweenLite; <br />
 * 		import com.greensock.plugins.TweenPlugin; <br />
 * 		import com.greensock.plugins.AutoAlphaPlugin; <br />
 * 		TweenPlugin.activate([AutoAlphaPlugin]); //activation is permanent in the SWF, so this line only needs to be run once.<br /><br />
 * 
 * 		TweenLite.to(mc, 2, {autoAlpha:0}); <br /><br />
 * </code>
 * 
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 */
	public class AutoAlphaPlugin extends TweenPlugin {
		/** @private **/
		public static const API:Number = 1.0; //If the API/Framework for plugins changes in the future, this number helps determine compatibility
		
		/** @private **/
		protected var _target:Object;
		/** @private **/
		protected var _ignoreVisible:Boolean;
		
		/** @private **/
		public function AutoAlphaPlugin() {
			super();
			this.propName = "autoAlpha";
			this.overwriteProps = ["alpha","visible"];
		}
		
		/** @private **/
		override public function onInitTween(target:Object, value:*, tween:TweenLite):Boolean {
			_target = target;
			addTween(target, "alpha", target.alpha, value, "alpha");
			return true;
		}
		
		/** @private **/
		override public function killProps(lookup:Object):void {
			super.killProps(lookup);
			_ignoreVisible = Boolean("visible" in lookup);
		}
		
		/** @private **/
		override public function set changeFactor(n:Number):void {
			updateTweens(n);
			if (!_ignoreVisible) {
				_target.visible = Boolean(_target.alpha != 0);
			}
		}
		
	}
}