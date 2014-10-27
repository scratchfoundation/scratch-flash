/**
 * VERSION: 0.5
 * DATE: 2010-11-30
 * AS3
 * UPDATES AND DOCS AT: http://www.greensock.com/
 **/
package com.greensock.easing {
/**
 * Most easing equations give a smooth, gradual transition between the start and end values, but SteppedEase provides
 * an easy way to define a specific number of steps that the transition should take. For example, if mc.x is 0 and you 
 * want to tween it to 100 with 5 steps (20, 40, 60, 80, and 100) over the course of 2 seconds, you'd do:<br /><br /><code>
 * 
 * TweenLite.to(mc, 2, {x:100, ease:SteppedEase.create(5)});<br /><br /></code>
 * 
 * <b>EXAMPLE CODE</b><br /><br /><code>
 * import com.greensock.TweenLite;<br />
 * import com.greensock.easing.SteppedEase;<br /><br />
 * 
 * TweenLite.to(mc, 2, {x:100, ease:SteppedEase.create(5)});<br /><br />
 * 
 * //or create an instance directly<br />
 * var steppedEase:SteppedEase = new SteppedEase(5);<br />
 * TweenLite.to(mc, 3, {y:300, ease:steppedEase.ease});
 * </code><br /><br />
 * 
 * Note: SteppedEase is optimized for use with the GreenSock tweenining platform, so it isn't intended to be used with other engines. 
 * Specifically, its easing equation always returns values between 0 and 1.<br /><br />
 * 
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 */	 
	public class SteppedEase {
		/** @private **/
		private var _steps:int;
		/** @private **/
		private var _stepAmount:Number;
		
		/**
		 * Constructor
		 * 
		 * @param steps Number of steps between the start and the end values. 
		 */
		public function SteppedEase(steps:int) {
			_stepAmount = 1 / steps;
			_steps = steps + 1;
		}
		
		/**
		 * This static function provides a quick way to create a SteppedEase and immediately reference its ease function 
		 * in a tween, like:<br /><br /><code>
		 * 
		 * TweenLite.to(mc, 2, {x:100, ease:SteppedEase.create(5)});<br />
		 * </code>
		 * 
		 * @param steps Number of steps between the start and the end values. 
		 * @return The easing function that can be plugged into a tween
		 */
		public static function create(steps:int):Function {
			var se:SteppedEase = new SteppedEase(steps);
			return se.ease;
		}
		
		/**
		 * Easing function that interpolates values. 
		 * 
		 * @param t time
		 * @param b start (should always be 0)
		 * @param c change (should always be 1)
		 * @param d duration
		 * @return Result of the ease
		 */
		public function ease(t:Number, b:Number, c:Number, d:Number):Number {
			var ratio:Number = t / d;
			if (ratio < 0) {
				ratio = 0;
			} else if (ratio >= 1) {
				ratio = 0.999999999;
			}
			return ((_steps * ratio) >> 0) * _stepAmount;
		}
		
		/** Number of steps between the start and the end values. **/
		public function get steps():int {
			return _steps - 1;
		}

	}
}
