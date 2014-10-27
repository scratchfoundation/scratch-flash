/**
 * VERSION: 1.1
 * DATE: 2010-09-16
 * ACTIONSCRIPT VERSION: 3.0 
 * UPDATES AND DOCUMENTATION AT: http://www.GreenSock.com
 **/
package com.greensock.plugins {
	import flash.media.SoundTransform;
	import com.greensock.*;
	import com.greensock.plugins.*;
/**
 * Tweens the volume of an object with a soundTransform property (MovieClip/SoundChannel/NetStream, etc.). <br /><br />
 * 
 * <b>USAGE:</b><br /><br />
 * <code>
 * 		import com.greensock.TweenLite; <br />
 * 		import com.greensock.plugins.TweenPlugin; <br />
 * 		import com.greensock.plugins.VolumePlugin; <br />
 * 		TweenPlugin.activate([VolumePlugin]); //activation is permanent in the SWF, so this line only needs to be run once.<br /><br />
 * 
 * 		TweenLite.to(mc, 1, {volume:0}); <br /><br />
 * </code>
 * 
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 */
	public class VolumePlugin extends TweenPlugin {
		/** @private **/
		public static const API:Number = 1.0; //If the API/Framework for plugins changes in the future, this number helps determine compatibility
		
		/** @private **/
		protected var _target:Object;
		/** @private **/
		protected var _st:SoundTransform;
		
		/** @private **/
		public function VolumePlugin() {
			super();
			this.propName = "volume";
			this.overwriteProps = ["volume"];
		}
		
		/** @private **/
		override public function onInitTween(target:Object, value:*, tween:TweenLite):Boolean {
			if (isNaN(value) || target.hasOwnProperty("volume") || !target.hasOwnProperty("soundTransform")) {
				return false;
			}
			_target = target;
			_st = _target.soundTransform;
			addTween(_st, "volume", _st.volume, value, "volume");
			return true;
		}
		
		/** @private **/
		override public function set changeFactor(n:Number):void {
			updateTweens(n);
			_target.soundTransform = _st;
		}
		
	}
}