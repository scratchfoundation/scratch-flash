/**
 * VERSION: 1.02
 * DATE: 10/2/2009
 * ACTIONSCRIPT VERSION: 3.0 
 * UPDATES AND DOCUMENTATION AT: http://www.TweenMax.com
 **/
package com.greensock.plugins {
	import flash.display.*;
	import flash.geom.Rectangle;
	
	import com.greensock.*;
/**
 * Tweens the scrollRect property of a DisplayObject. You can define any (or all) of the following
 * properties:
 * <code>
 * <ul>
 * 		<li> x : Number</li>
 * 		<li> y : Number</li>
 * 		<li> width : Number</li>
 * 		<li> height : Number</li>
 * 		<li> top : Number</li>
 * 		<li> bottom : Number</li>
 * 		<li> left : Number</li>
 * 		<li> right : Number</li>
 * </ul>
 * </code><br />
 * 
 * <b>USAGE:</b><br /><br />
 * <code>
 * 		import com.greensock.TweenLite; <br />
 * 		import com.greensock.plugins.TweenPlugin; <br />
 * 		import com.greensock.plugins.ScrollRectPlugin; <br />
 * 		TweenPlugin.activate([ScrollRectPlugin]); //activation is permanent in the SWF, so this line only needs to be run once.<br /><br />
 * 
 * 		TweenLite.to(mc, 1, {scrollRect:{x:50, y:300, width:100, height:100}}); <br /><br />
 * </code>
 * 
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 */
	public class ScrollRectPlugin extends TweenPlugin {
		/** @private **/
		public static const API:Number = 1.0; //If the API/Framework for plugins changes in the future, this number helps determine compatibility
		
		/** @private **/
		protected var _target:DisplayObject;
		/** @private **/
		protected var _rect:Rectangle;
		
		/** @private **/
		public function ScrollRectPlugin() {
			super();
			this.propName = "scrollRect";
			this.overwriteProps = ["scrollRect"];
		}
		
		/** @private **/
		override public function onInitTween(target:Object, value:*, tween:TweenLite):Boolean {
			if (!(target is DisplayObject)) {
				return false;
			}
			_target = target as DisplayObject;
			if (_target.scrollRect != null) {
				_rect = _target.scrollRect;
			} else {
				var r:Rectangle = _target.getBounds(_target);
				_rect = new Rectangle(0, 0, r.width + r.x, r.height + r.y);
			}
			for (var p:String in value) {
				addTween(_rect, p, _rect[p], value[p], p);
			}
			return true;
		}
		
		/** @private **/
		override public function set changeFactor(n:Number):void {
			updateTweens(n);
			_target.scrollRect = _rect;
		}

	}
}