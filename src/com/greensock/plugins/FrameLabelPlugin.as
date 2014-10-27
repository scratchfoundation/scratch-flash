/**
 * VERSION: 1.03
 * DATE: 10/2/2009
 * ACTIONSCRIPT VERSION: 3.0 
 * UPDATES AND DOCUMENTATION AT: http://www.TweenMax.com
 **/
package com.greensock.plugins {
	import com.greensock.*;
	
	import flash.display.*;
/**
 * Tweens a MovieClip to a particular frame label. <br /><br />
 * 
 * <b>USAGE:</b><br /><br />
 * <code>
 * 		import com.greensock.TweenLite; <br />
 * 		import com.greensock.plugins.TweenPlugin; <br />
 * 		import com.greensock.plugins.FrameLabelPlugin; <br />
 * 		TweenPlugin.activate([FrameLabelPlugin]); //activation is permanent in the SWF, so this line only needs to be run once.<br /><br />
 * 
 * 		TweenLite.to(mc, 1, {frameLabel:"myLabel"}); <br /><br />
 * </code>
 * 
 * Note: When tweening the frames of a MovieClip, any audio that is embedded on the MovieClip's timeline (as "stream") will not be played. 
 * Doing so would be impossible because the tween might speed up or slow down the MovieClip to any degree.<br /><br />
 * 
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 */
	public class FrameLabelPlugin extends FramePlugin {
		/** @private **/
		public static const API:Number = 1.0; //If the API/Framework for plugins changes in the future, this number helps determine compatibility
		
		/** @private **/
		public function FrameLabelPlugin() {
			super();
			this.propName = "frameLabel";
		}
		
		/** @private **/
		override public function onInitTween(target:Object, value:*, tween:TweenLite):Boolean {
			if (!tween.target is MovieClip) {
				return false;
			}
			_target = target as MovieClip;
			this.frame = _target.currentFrame;
			var labels:Array = _target.currentLabels, label:String = value, endFrame:int = _target.currentFrame;
			var i:int = labels.length;
			while (i--) {
				if (labels[i].name == label) {
					endFrame = labels[i].frame;
					break;
				}
			}
			if (this.frame != endFrame) {
				addTween(this, "frame", this.frame, endFrame, "frame");
			}
			return true;
		}
		

	}
}