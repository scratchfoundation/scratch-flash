/**
 * VERSION: 1.0
 * DATE: 10/22/2009
 * ACTIONSCRIPT VERSION: 3.0 
 * UPDATES AND DOCUMENTATION AT: http://www.TweenMax.com
 **/
package com.greensock.plugins {
	import com.greensock.*;
	
	import flash.media.SoundTransform;
/**
 * Tweens properties of an object's soundTransform property (like the volume, pan, leftToRight, etc. of a MovieClip/SoundChannel/NetStream). <br /><br />
 * 
 * <b>USAGE:</b><br /><br />
 * <code>
 * 		import com.greensock.TweenLite; <br />
 * 		import com.greensock.plugins.TweenPlugin; <br />
 * 		import com.greensock.plugins.SoundTransformPlugin; <br />
 * 		TweenPlugin.activate([SoundTransformPlugin]); //activation is permanent in the SWF, so this line only needs to be run once.<br /><br />
 * 
 * 		TweenLite.to(mc, 1, {soundTransform:{volume:0.2, pan:0.5}}); <br /><br />
 * </code>
 * 
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 */
	public class SoundTransformPlugin extends TweenPlugin {
		/** @private **/
		public static const API:Number = 1.0; //If the API/Framework for plugins changes in the future, this number helps determine compatibility
		
		/** @private **/
		protected var _target:Object;
		/** @private **/
		protected var _st:SoundTransform;
		
		/** @private **/
		public function SoundTransformPlugin() {
			super();
			this.propName = "soundTransform";
			this.overwriteProps = ["soundTransform","volume"];
		}
		
		/** @private **/
		override public function onInitTween(target:Object, value:*, tween:TweenLite):Boolean {
			if (!target.hasOwnProperty("soundTransform")) {
				return false;
			}
			_target = target;
			_st = _target.soundTransform;
			for (var p:String in value) {
				addTween(_st, p, _st[p], value[p], p);
			}
			return true;
		}
		
		/** @private **/
		override public function set changeFactor(n:Number):void {
			updateTweens(n);
			_target.soundTransform = _st;
		}
		
	}
}