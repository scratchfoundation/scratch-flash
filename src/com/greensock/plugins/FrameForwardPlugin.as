/**
 * VERSION: 0.1
 * DATE: 2010-04-17
 * ACTIONSCRIPT VERSION: 3.0 
 * UPDATES AND DOCUMENTATION AT: http://www.TweenMax.com
 **/
package com.greensock.plugins {
	import com.greensock.*;
	
	import flash.display.*;
/**
 * Tweens a MovieClip forward to a particular frame number, wrapping it if/when it reaches the end
 * of the timeline. For example, if your MovieClip has 20 frames total and it is currently at frame 10
 * and you want tween to frame 5, a normal frame tween would go backwards from 10 to 5, but a frameForward
 * would go from 10 to 20 (the end) and wrap to the beginning and continue tweening from 1 to 5. <br /><br />
 * 
 * <b>USAGE:</b><br /><br />
 * <code>
 * 		import com.greensock.TweenLite; <br />
 * 		import com.greensock.plugins.~~; <br />
 * 		TweenPlugin.activate([FrameForwardPlugin]); //activation is permanent in the SWF, so this line only needs to be run once.<br /><br />
 * 
 * 		TweenLite.to(mc, 1, {frameForward:5}); <br /><br />
 * </code>
 * 
 * Note: When tweening the frames of a MovieClip, any audio that is embedded on the MovieClip's timeline (as "stream") will not be played. 
 * Doing so would be impossible because the tween might speed up or slow down the MovieClip to any degree.<br /><br />
 * 
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 */
	public class FrameForwardPlugin extends TweenPlugin {
		/** @private **/
		public static const API:Number = 1.0; //If the API/Framework for plugins changes in the future, this number helps determine compatibility
		
		/** @private **/
		protected var _start:int;
		/** @private **/
		protected var _change:int;
		/** @private **/
		protected var _max:uint;
		/** @private **/
		protected var _target:MovieClip;
		/** @private Allows FrameBackwardPlugin to extend this class and only use an extremely small amount of kb (because the functionality is combined here) **/
		protected var _backward:Boolean;
		
		/** @private **/
		public function FrameForwardPlugin() {
			super();
			this.propName = "frameForward";
			this.overwriteProps = ["frame","frameLabel","frameForward","frameBackward"];
			this.round = true;
		}
		
		/** @private **/
		override public function onInitTween(target:Object, value:*, tween:TweenLite):Boolean {
			if (!(target is MovieClip) || isNaN(value)) {
				return false;
			}
			_target = target as MovieClip;
			_start = _target.currentFrame;
			_max = _target.totalFrames;
			_change = (typeof(value) == "number") ? Number(value) - _start : Number(value);
			if (!_backward && _change < 0) {
				_change += _max;
			} else if (_backward && _change > 0) {
				_change -= _max;
			}
			return true;
		}
		
		/** @private **/
		override public function set changeFactor(n:Number):void {
			var frame:Number = (_start + (_change * n)) % _max;
			if (frame < 0.5 && frame >= -0.5) {
				frame = _max;
			} else if (frame < 0) {
				frame += _max;
			}
			_target.gotoAndStop( int(frame + 0.5) );
		}

	}
}