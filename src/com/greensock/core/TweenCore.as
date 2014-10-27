/**
 * VERSION: 1.693
 * DATE: 2011-11-07
 * AS3 (AS2 version is also available)
 * UPDATES AND DOCS AT: http://www.greensock.com
 **/
package com.greensock.core {
	import com.greensock.*;
/**
 * TweenCore is the base class for all TweenLite, TweenMax, TimelineLite, and TimelineMax classes and 
 * provides core functionality and properties. There is no reason to use this class directly.<br /><br />
 * 
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 */
	public class TweenCore {
		/** @private **/
		public static const version:Number = 1.693;
		
		/** @private **/
		protected static var _classInitted:Boolean;
		
		/** @private Delay in seconds (or frames for frames-based tweens/timelines) **/
		protected var _delay:Number; 
		/** @private Has onUpdate. Tracking this as a Boolean value is faster than checking this.vars.onUpdate != null. **/
		protected var _hasUpdate:Boolean;
		/** @private Primarily used for zero-duration tweens to determine the direction/momentum of time which controls whether the starting or ending values should be rendered. For example, if a zero-duration tween renders and then its timeline reverses and goes back before the startTime, the zero-duration tween must render the starting values. Otherwise, if the render time is zero or later, it should always render the ending values. **/
		protected var _rawPrevTime:Number = -1;
		
		/** Stores variables (things like alpha, y or whatever we're tweening as well as special properties like "onComplete"). **/
		public var vars:Object; 
		/** @private The tween has begun and is now active **/
		public var active:Boolean; 
		/** @private Flagged for garbage collection **/
		public var gc:Boolean; 
		/** @private Indicates whether or not init() has been called (where all the tween property start/end value information is recorded) **/
		public var initted:Boolean; 
		 /** The parent timeline on which the tween/timeline is placed. By default, it uses the TweenLite.rootTimeline (or TweenLite.rootFramesTimeline for frames-based tweens/timelines). **/
		public var timeline:SimpleTimeline;
		/** @private Start time in seconds (or frames for frames-based tweens/timelines), according to its position on its parent timeline **/
		public var cachedStartTime:Number; 
		/** @private The last rendered currentTime of this TweenCore. If a tween is going to repeat, its cachedTime will reset even though the cachedTotalTime continues linearly (or if it yoyos, the cachedTime may go forwards and backwards several times over the course of the tween). The cachedTime reflects the tween's "local" (which can never exceed the duration) time whereas the cachedTotalTime reflects the overall time. These will always match if the tween doesn't repeat/yoyo.**/
		public var cachedTime:Number; 
		/** @private The last rendered totalTime of this TweenCore. It is prefaced with "cached" because using a public property like this is faster than using the getter which is essentially a function call. If you want to update the value, you should always use the normal property, like myTween.totalTime = 0.5.**/
		public var cachedTotalTime:Number; 
		/** @private Prefaced with "cached" because using a public property like this is faster than using the getter which is essentially a function call. If you want to update the value, you should always use the normal property, like myTween.duration = 0.5.**/
		public var cachedDuration:Number; 
		/** @private Prefaced with "cached" because using a public property like this is faster than using the getter which is essentially a function call. If you want to update the value, you should always use the normal property, like myTween.totalDuration = 0.5.**/
		public var cachedTotalDuration:Number; 
		/** @private timeScale allows you to slow down or speed up a tween/timeline. 1 = normal speed, 0.5 = half speed, 2 = double speed, etc. It is prefaced with "cached" because using a public property like this is faster than using the getter which is essentially a function call. If you want to update the value, you should always use the normal property, like myTween.timeScale = 2**/
		public var cachedTimeScale:Number;
		/** @private parent timeline's rawTime at which the tween/timeline was paused (so that we can place it at the appropriate time when it is unpaused). NaN when the tween/timeline isn't paused. **/
		public var cachedPauseTime:Number;
		/** @private Indicates whether or not the tween is reversed. **/ 
		public var cachedReversed:Boolean;
		/** @private Next TweenCore object in the linked list.**/
		public var nextNode:TweenCore; 
		/** @private Previous TweenCore object in the linked list**/
		public var prevNode:TweenCore; 
		/** @private When a TweenCore has been removed from its timeline, it is considered an orphan. When it it added to a timeline, it is no longer an orphan. We don't just set its "timeline" property to null because we need to always keep track of the timeline in case the TweenCore is enabled again by restart() or basically any operation that would cause it to become active again. "cachedGC" is different in that a TweenCore could be eligible for gc yet not removed from its timeline, like when a TimelineLite completes for example. **/
		public var cachedOrphan:Boolean;
		/** @private Indicates that the duration or totalDuration may need refreshing (like if a TimelineLite's child had a change in duration or startTime). This is another performance booster because if the cache isn't dirty, we can quickly read from the cachedDuration and/or cachedTotalDuration **/
		public var cacheIsDirty:Boolean; 
		/** @private Quicker way to read the paused property. It is public for speed purposes. When setting the paused state, always use the regular "paused" property.**/
		public var cachedPaused:Boolean; 
		/** Place to store any data you want.**/
		public var data:*; 
		
		public function TweenCore(duration:Number=0, vars:Object=null) {
			this.vars = (vars != null) ? vars : {};
			if (this.vars.isGSVars) {
				this.vars = this.vars.vars;
			}
			this.cachedDuration = this.cachedTotalDuration = duration;
			_delay = (this.vars.delay) ? Number(this.vars.delay) : 0;
			this.cachedTimeScale = (this.vars.timeScale) ? Number(this.vars.timeScale) : 1;
			this.active = Boolean(duration == 0 && _delay == 0 && this.vars.immediateRender != false);
			this.cachedTotalTime = this.cachedTime = 0;
			this.data = this.vars.data;
			
			if (!_classInitted) {
				if (isNaN(TweenLite.rootFrame)) {
					TweenLite.initClass();
					_classInitted = true;
				} else {
					return;
				}
			}
			
			var tl:SimpleTimeline = (this.vars.timeline is SimpleTimeline) ? this.vars.timeline : (this.vars.useFrames) ? TweenLite.rootFramesTimeline : TweenLite.rootTimeline;
			tl.insert(this, tl.cachedTotalTime);
			if (this.vars.reversed) {
				this.cachedReversed = true;
			}
			if (this.vars.paused) {
				this.paused = true;
			}
		}
		
		/** Starts playing forward from the current position. (essentially unpauses and makes sure that it is not reversed) **/
		public function play():void {
			this.reversed = false;
			this.paused = false;
		}
		
		/** Pauses the tween/timeline **/
		public function pause():void {
			this.paused = true;
		}
		
		/** Starts playing from the current position without altering direction (forward or reversed). **/
		public function resume():void {
			this.paused = false;
		}
		
		/**
		 * Restarts and begins playing forward.
		 * 
		 * @param includeDelay Determines whether or not the delay (if any) is honored in the restart()
		 * @param suppressEvents If true, no events or callbacks will be triggered as the "virtual playhead" moves to the new position (onComplete, onUpdate, onReverseComplete, etc. of this tween/timeline and any of its child tweens/timelines won't be triggered, nor will any of the associated events be dispatched) 
		 */
		public function restart(includeDelay:Boolean=false, suppressEvents:Boolean=true):void {
			this.reversed = false;
			this.paused = false;
			this.setTotalTime((includeDelay) ? -_delay : 0, suppressEvents);
		}
		
		/**
		 * Reverses smoothly, adjusting the startTime to avoid any skipping. After being reversed,
		 * it will play backwards, exactly opposite from its forward orientation, meaning that, for example, a
		 * tween's easing equation will appear reversed as well. If a tween/timeline plays for 2 seconds and gets
		 * reversed, it will play for another 2 seconds to return to the beginning.
		 * 
		 * @param forceResume If true, it will resume() immediately upon reversing. Otherwise its paused state will remain unchanged.
		 */
		public function reverse(forceResume:Boolean=true):void {
			this.reversed = true;
			if (forceResume) {
				this.paused = false;
			} else if (this.gc) {
				this.setEnabled(true, false);
			}
		}
		
		/**
		 * @private
		 * Renders the tween/timeline at a particular time (or frame number for frames-based tweens)
		 * WITHOUT changing its startTime. For example, if a tween's duration
		 * is 3, <code>renderTime(1.5)</code> would render it at the halfway finished point.
		 * 
		 * @param time time in seconds (or frame number for frames-based tweens/timelines) to render.
		 * @param suppressEvents If true, no events or callbacks will be triggered for this render (like onComplete, onUpdate, onReverseComplete, etc.)
		 * @param force Normally the tween will skip rendering if the time matches the cachedTotalTime (to improve performance), but if force is true, it forces a render. This is primarily used internally for tweens with durations of zero in TimelineLite/Max instances.
		 */
		public function renderTime(time:Number, suppressEvents:Boolean=false, force:Boolean=false):void {
			
		}
		
		/**
		 * Forces the tween/timeline to completion.
		 * 
		 * @param skipRender to skip rendering the final state of the tween, set skipRender to true. 
		 * @param suppressEvents If true, no events or callbacks will be triggered for this render (like onComplete, onUpdate, onReverseComplete, etc.)
		 */
		public function complete(skipRender:Boolean=false, suppressEvents:Boolean=false):void {
			if (!skipRender) {
				renderTime(this.totalDuration, suppressEvents, false); //just to force the final render
				return; //renderTime() will call complete() again, so just return here.
			}
			if (this.timeline.autoRemoveChildren) {
				this.setEnabled(false, false);
			} else {
				this.active = false;
			}
			if (!suppressEvents) {
				if (this.vars.onComplete && this.cachedTotalTime >= this.cachedTotalDuration && !this.cachedReversed) { //note: remember that tweens can have a duration of zero in which case their cachedTime and cachedDuration would always match. Also, TimelineLite/Max instances with autoRemoveChildren may have a cachedTotalTime that exceeds cachedTotalDuration because the children were removed after the last render.
					this.vars.onComplete.apply(null, this.vars.onCompleteParams);
				} else if (this.cachedReversed && this.cachedTotalTime == 0 && this.vars.onReverseComplete) {
					this.vars.onReverseComplete.apply(null, this.vars.onReverseCompleteParams);
				}
			}
		}
		
		/** 
		 * Clears any initialization data (like starting values in tweens) which can be useful if, for example, 
		 * you want to restart it without reverting to any previously recorded starting values. When you invalidate() 
		 * a tween/timeline, it will be re-initialized the next time it renders and its <code>vars</code> object will be re-parsed. 
		 * The timing of the tween/timeline (duration, startTime, delay) will NOT be affected. Another example would be if you
		 * have a <code>TweenMax(mc, 1, {x:100, y:100})</code> that ran when mc.x and mc.y were initially at 0, but now mc.x 
		 * and mc.y are 200 and you want them tween to 100 again, you could simply <code>invalidate()</code> the tween and 
		 * <code>restart()</code> it. Without invalidating first, restarting it would cause the values jump back to 0 immediately 
		 * (where they started when the tween originally began). When you invalidate a timeline, it automatically invalidates 
		 * all of its children.
		 **/
		public function invalidate():void {
			
		}
		
		/**
		 * @private
		 * If a tween/timeline is enabled, it is eligible to be rendered (unless it is paused). Setting enabled to
		 * false essentially removes it from its parent timeline and stops protecting it from garbage collection.
		 * 
		 * @param enabled Enabled state of the tween/timeline
		 * @param ignoreTimeline By default, the tween/timeline will remove itself from its parent timeline when it is disabled, and add itself when it is enabled, but this parameter allows you to override that behavior.
		 * @return Boolean value indicating whether or not important properties may have changed when the TweenCore was enabled/disabled. For example, when a motionBlur (plugin) is disabled, it swaps out a BitmapData for the target and may alter the alpha. We need to know this in order to determine whether or not a new tween that is overwriting this one should be re-initted() with the changed properties. 
		 **/
		public function setEnabled(enabled:Boolean, ignoreTimeline:Boolean=false):Boolean {
			this.gc = !enabled;
			if (enabled) {
				this.active = Boolean(!this.cachedPaused && this.cachedTotalTime > 0 && this.cachedTotalTime < this.cachedTotalDuration);
				if (!ignoreTimeline && this.cachedOrphan) {
					this.timeline.insert(this, this.cachedStartTime - _delay);
				}
			} else {
				this.active = false;
				if (!ignoreTimeline && !this.cachedOrphan) {
					this.timeline.remove(this, true);
				}
			}
			return false;
		}
		
		/** Kills the tween/timeline, stopping it immediately. **/
		public function kill():void {
			setEnabled(false, false);
		}
		
		/**
		 * @private
		 * Sets the cacheIsDirty property of all anscestor timelines (and optionally this tween/timeline too). Setting
		 * the cacheIsDirty property to true forces any necessary recalculation of its cachedDuration and cachedTotalDuration 
		 * properties and sorts the affected timelines' children TweenCores so that they're in the proper order 
		 * next time the duration or totalDuration is requested. We don't just recalculate them immediately because 
		 * it can be much faster to do it this way.
		 * 
		 * @param includeSelf indicates whether or not this tween's cacheIsDirty property should be affected.
		 */
		protected function setDirtyCache(includeSelf:Boolean=true):void {
			var tween:TweenCore = (includeSelf) ? this : this.timeline;
			while (tween) {
				tween.cacheIsDirty = true;
				tween = tween.timeline;
			}
		}
		
		/**
		 * @private
		 * Sort of like placing the local "playhead" at a particular totalTime and then aligning it with
		 * the parent timeline's "playhead" so that rendering continues from that point smoothly. This 
		 * changes the cachedStartTime.
		 * 
		 * @param time Time that should be rendered (includes any repeats and repeatDelays for TimelineMax)
		 * @param suppressEvents If true, no events or callbacks will be triggered for this render (like onComplete, onUpdate, onReverseComplete, etc.)
		 **/
		protected function setTotalTime(time:Number, suppressEvents:Boolean=false):void {
			if (this.timeline) {
				var tlTime:Number = (this.cachedPaused) ? this.cachedPauseTime : this.timeline.cachedTotalTime;
				if (this.cachedReversed) {
					var dur:Number = (this.cacheIsDirty) ? this.totalDuration : this.cachedTotalDuration;
					this.cachedStartTime = tlTime - ((dur - time) / this.cachedTimeScale);
				} else {
					this.cachedStartTime = tlTime - (time / this.cachedTimeScale);
				}
				if (!this.timeline.cacheIsDirty) { //for performance improvement. If the parent's cache is already dirty, it already took care of marking the anscestors as dirty too, so skip the function call here.
					setDirtyCache(false);
				}
				if (this.cachedTotalTime != time) {
					renderTime(time, suppressEvents, false);
				}
			}
		}
		
		
//---- GETTERS / SETTERS ------------------------------------------------------------
		
		/** 
		 * Length of time in seconds (or frames for frames-based tweens/timelines) before the tween should begin. 
		 * The tween's starting values are not determined until after the delay has expired (except in from() tweens) 
		 **/
		public function get delay():Number {
			return _delay;
		}
		
		public function set delay(n:Number):void {
			this.startTime += n - _delay;
			_delay = n;
		}
		
		/**
		 * Duration of the tween in seconds (or frames for frames-based tweens/timelines) not including any repeats
		 * or repeatDelays. <code>totalDuration</code>, by contrast, does include repeats and repeatDelays. If you alter
		 * the <code>duration</code> of a tween while it is in-progress (active), its <code>startTime</code> will automatically 
		 * be adjusted in order to make the transition smoothly (without a sudden skip). 
		 **/
		public function get duration():Number {
			return this.cachedDuration;
		}
		
		public function set duration(n:Number):void {
			var ratio:Number = n / this.cachedDuration;
			this.cachedDuration = this.cachedTotalDuration = n;
			setDirtyCache(true); //true in case it's a TweenMax or TimelineMax that has a repeat - we'll need to refresh the totalDuration. 
			if (this.active && !this.cachedPaused && n != 0) {
				this.setTotalTime(this.cachedTotalTime * ratio, true);
			}
		}
		
		/**
		 * Duration of the tween in seconds (or frames for frames-based tweens/timelines) including any repeats
		 * or repeatDelays (which are only available on TweenMax and TimelineMax). <code>duration</code>, by contrast, does 
		 * <b>NOT</b> include repeats and repeatDelays. So if a TweenMax's <code>duration</code> is 1 and it has a repeat of 2, 
		 * the <code>totalDuration</code> would be 3.
		 **/ 
		public function get totalDuration():Number {
			return this.cachedTotalDuration;
		}
		
		public function set totalDuration(n:Number):void {
			this.duration = n;
		}
		
		/**
		 * Most recently rendered time (or frame for frames-based tweens/timelines) according to its 
		 * <code>duration</code>. <code>totalTime</code>, by contrast, is based on its <code>totalDuration</code> 
		 * which includes repeats and repeatDelays. Since TweenLite and TimelineLite don't offer 
		 * <code>repeat</code> and <code>repeatDelay</code> functionality, <code>currentTime</code> 
		 * and <code>totalTime</code> will always be the same but in TweenMax or TimelineMax, they 
		 * could be different. For example, if a TimelineMax instance has a duration 
		 * of 5 a repeat of 1 (meaning its <code>totalDuration</code> is 10), at the end of the second cycle, 
		 * <code>currentTime</code> would be 5 whereas <code>totalTime</code> would be 10. If you tracked both
		 * properties over the course of the tween, you'd see <code>currentTime</code> go from 0 to 5 twice (one for each
		 * cycle) in the same time it takes <code>totalTime</code> go from 0 to 10.
		 **/
		public function get currentTime():Number {
			return this.cachedTime;
		}
		
		public function set currentTime(n:Number):void {
			setTotalTime(n, false);
		}
		
		/**
		 * Most recently rendered time (or frame for frames-based tweens/timelines) according to its 
		 * <code>totalDuration</code>. <code>currentTime</code>, by contrast, is based on its <code>duration</code> 
		 * which does NOT include repeats and repeatDelays. Since TweenLite and TimelineLite don't offer 
		 * <code>repeat</code> and <code>repeatDelay</code> functionality, <code>currentTime</code> 
		 * and <code>totalTime</code> will always be the same but in TweenMax or TimelineMax, they 
		 * could be different. For example, if a TimelineMax instance has a duration 
		 * of 5 a repeat of 1 (meaning its <code>totalDuration</code> is 10), at the end of the second cycle, 
		 * <code>currentTime</code> would be 5 whereas <code>totalTime</code> would be 10. If you tracked both
		 * properties over the course of the tween, you'd see <code>currentTime</code> go from 0 to 5 twice (one for each
		 * cycle) in the same time it takes <code>totalTime</code> go from 0 to 10.
		 **/
		public function get totalTime():Number {
			return this.cachedTotalTime;
		}
		
		public function set totalTime(n:Number):void {
			setTotalTime(n, false);
		}
		
		/** Start time in seconds (or frames for frames-based tweens/timelines), according to its position on its parent timeline **/
		public function get startTime():Number {
			return this.cachedStartTime;
		}
		
		public function set startTime(n:Number):void {
			if (this.timeline != null && (n != this.cachedStartTime || this.gc)) {
				this.timeline.insert(this, n - _delay); //ensures that any necessary re-sequencing of TweenCores in the timeline occurs to make sure the rendering order is correct.
			} else {
				this.cachedStartTime = n;
			}
		}
		
		/** Indicates the reversed state of the tween/timeline. This value is not affected by <code>yoyo</code> repeats and it does not take into account the reversed state of anscestor timelines. So for example, a tween that is not reversed might appear reversed if its parent timeline (or any ancenstor timeline) is reversed. **/
		public function get reversed():Boolean {
			return this.cachedReversed;
		}
		
		public function set reversed(b:Boolean):void {
			if (b != this.cachedReversed) {
				this.cachedReversed = b;
				setTotalTime(this.cachedTotalTime, true);
			}
		}
		
		/** Indicates the paused state of the tween/timeline. This does not take into account anscestor timelines. So for example, a tween that is not paused might appear paused if its parent timeline (or any ancenstor timeline) is paused. **/
		public function get paused():Boolean {
			return this.cachedPaused;
		}
		
		public function set paused(b:Boolean):void {
			if (b != this.cachedPaused && this.timeline) {
				if (b) {
					this.cachedPauseTime = this.timeline.rawTime;
				} else {
					this.cachedStartTime += this.timeline.rawTime - this.cachedPauseTime;
					this.cachedPauseTime = NaN;
					setDirtyCache(false);
				}
				this.cachedPaused = b;
				this.active = Boolean(!this.cachedPaused && this.cachedTotalTime > 0 && this.cachedTotalTime < this.cachedTotalDuration);
			}
			if (!b && this.gc) {
				this.setEnabled(true, false);
			}
		}

	}
}