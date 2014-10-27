/**
 * VERSION: 6.1
 * DATE: 2010-12-20
 * AS3 (AS2 is also available)
 * UPDATES AND DOCS AT: http://www.greensock.com/overwritemanager/
 **/
package com.greensock {
	import com.greensock.core.*;
	
/**
 * OverwriteManager resolves conflicts between tweens and controls if (and how) existing tweens of the same
 * target are overwritten. Think of it as a referee or traffic cop for tweens. For example, let's say you have
 * a button with <code>ROLL_OVER</code> and <code>ROLL_OUT</code> handlers that tween an object's alpha and the user rolls their mouse
 * over/out/over/out quickly. Most likely, you'd want each new tween to overwrite the other immediately so
 * that you don't end up with multiple tweens vying for control of the alpha property. That describes
 * the <code>ALL_IMMEDIATE</code> mode which is the default mode of TweenLite when it is not used in conjunction with
 * TweenMax, TimelineLite, or TimelineMax. This keeps things small and fast. However, it isn't ideal for 
 * setting up sequences because as soon as you create subsequent tweens of the same target in the sequence, 
 * the previous one gets overwritten. And what if you have a tween that is controling 3 properties and 
 * then you create another tween that only controls one of those properties? You may want the first tween 
 * to continue tweening the other 2 (non-overlapping) properties. This describes the <code>AUTO</code> mode which is 
 * the default whenever TweenMax, TimelineLite, or TimelineMax is used in your swf. OverwriteManager
 * offers quite a few other modes to choose from in fact:
 * 
 * <ul>
 * 		<li><b> NONE (0):</b> 
 * 					<ol>
 * 						<li><b>When:</b> Never</li>
 * 						<li><b>Finds:</b> Nothing</li>
 * 						<li><b>Kills:</b> Nothing</li>
 * 						<li><b>Performance:</b> Excellent</li>
 * 						<li><b>Good for:</b> When you know that your tweens won't conflict and you want maximum speed.</li>
 * 					</ol>
 * 		</li>
 * 				
 * 		<li><b> ALL_IMMEDIATE (1):</b> 
 * 					<ol>
 * 						<li><b>When:</b> Immediately when the tween is created.</li>
 * 						<li><b>Finds:</b> All tweens of the same target (regardless of timing or overlapping properties).</li>
 * 						<li><b>Kills:</b> Every tween found</li>
 * 						<li><b>Performance:</b> Excellent</li>
 * 						<li><b>Good for:</b> When you want the tween to take priority over all other tweens of the 
 * 											 same target, like on button rollovers/rollouts. However, this mode is 
 * 											 bad for setting up sequences.</li>
 * 					</ol>
 * 					This is the default mode for TweenLite unless TweenMax, TimelineLite, 
 * 					or TimelineMax are used in the SWF (in which case <code>AUTO</code> is the default mode).
 * 		</li>
 * 					
 * 		<li><b> AUTO (2):</b> 
 * 					<ol>
 * 						<li><b>When:</b> The first time the tween renders (you can <code>invalidate()</code> a tween to force it 
 * 										 to re-init and run its overwriting routine again next time it renders)</li>
 * 						<li><b>Finds:</b> Only tweens of the same target that are active (running). Tweens that haven't started yet are immune.</li>
 * 						<li><b>Kills:</b> Only individual overlapping tweening properties. If all tweening properties 
 * 										  have been overwritten, the entire tween will be killed as well.</li>
 * 						<li><b>Performance:</b> Very good when there aren't many overlapping tweens; fair when there are.</li>
 * 						<li><b>Good for:</b> Virtually all situations. This mode does the best job overall of handling 
 * 											 overwriting in an intuitive way and is excellent for sequencing. </li>
 * 					</ol>
 * 					This is the default mode when TweenMax, TimelineLite, or TimelineMax is used in your swf (those classes
 * 					automatically init() OverwriteManager in <code>AUTO</code> mode unless you have already initted OverwriteManager manually).
 * 		</li>
 * 					
 * 		<li><b> CONCURRENT (3):</b> 
 * 					<ol>
 * 						<li><b>When:</b> The first time the tween renders (you can <code>invalidate()</code> a tween to force it 
 * 										 to re-init and run its overwriting routine again next time it renders)</li>
 * 						<li><b>Finds:</b> Only tweens of the same target that are active (running). Tweens that haven't started yet are immune.</li>
 * 						<li><b>Kills:</b> Every tween found</li>
 * 						<li><b>Performance:</b> Very good</li>
 * 						<li><b>Good for:</b> When you want the target object to only be controled by one tween at a time. Good
 * 											 for sequencing although AUTO mode is typically better because it will only kill
 * 											 individual overlapping properties instead of entire tweens.</li>
 * 					</ol>
 * 		</li>
 * 				
 * 		<li><b> ALL_ONSTART (4):</b> 
 * 					<ol>
 * 						<li><b>When:</b> The first time the tween renders (you can <code>invalidate()</code> a tween to force it 
 * 										 to re-init and run its overwriting routine again next time it renders)</li>
 * 						<li><b>Finds:</b> All tweens of the same target (regardless of timing or overlapping properties).</li>
 * 						<li><b>Kills:</b> Every tween found</li>
 * 						<li><b>Performance:</b> Very good</li>
 * 						<li><b>Good for:</b> When you want a tween to take priority and wipe out all other tweens of the 
 * 											 same target even if they start later. This mode is rarely used.</li>
 * 					</ol>
 * 		</li>
 * 
 * 		<li><b> PREEXISTING (5):</b> 
 * 					<ol>
 * 						<li><b>When:</b> The first time the tween renders (you can <code>invalidate()</code> a tween to force it 
 * 										 to re-init and run its overwriting routine again next time it renders)</li>
 * 						<li><b>Finds:</b> Only the tweens of the same target that were created before this tween was created 
 * 										  (regardless of timing or overlapping properties). Virtually identical to <code>ALL_IMMEDIATE</code>
 * 										  except that <code>PREEXISTING</code> doesn't run its overwriting routines until it renders for the
 * 										  first time, meaning that if it has a delay, other tweens won't be overwritten until the delay expires.</li>
 * 						<li><b>Kills:</b> Every tween found</li>
 * 						<li><b>Performance:</b> Very good</li>
 * 						<li><b>Good for:</b> When the order in which your code runs plays a critical role, like when tweens
 * 											 that you create later should always take precidence over previously created ones
 * 											 regardless of when they're scheduled to run. If <code>ALL_IMMEDIATE</code> is great except
 * 											 that you want to wait on overwriting until the tween begins, <code>PREEXISTING</code> is perfect.</li>
 * 					</ol>
 * 		</li>
 * 	</ul>
 * 
 * With the exception of <code>ALL_IMMEDIATE</code> (which performs overwriting immediatly when the tween is created), 
 * all overwriting occurs when a tween renders for the first time. So if your tween has a delay of 1 second,
 * it will not overwrite any tweens until that point. <br /><br />
 * 
 * You can define a default overwriting mode for all tweens using the <code>OverwriteManager.init()</code> method, like:<br /><br /><code>
 * 
 * 		OverwriteManager.init(OverwriteManager.AUTO);<br /><br /></code>
 * 
 * If you want to override the default mode in a particular tween, just use the <code>overwrite</code> special 
 * property. You can use the static constant or the corresponding number. The following two lines produce 
 * the same results:<br /><br /><code>
 * 
 * 		TweenMax.to(mc, 1, {x:100, overwrite:OverwriteManager.PREXISTING});<br />
 * 		TweenMax.to(mc, 1, {x:100, overwrite:5});<br /><br /></code>
 * 
 * OverwriteManager is a separate, optional class for TweenLite primarily because of file size concerns. 
 * Without initting OverwriteManager, TweenLite can only recognize modes 0 and 1 (<code>NONE</code> and <code>ALL_IMMEDIATE</code>). 
 * However, TweenMax, TimelineLite, and TimelineMax automatically init() OverwriteManager in <code>AUTO</code> mode 
 * unless you have already initted OverwriteManager manually. You do not need to take any additional steps
 * to use AUTO mode if you're using any of those classes somewhere in your project. Keep in mind too that setting 
 * the default OverwriteManager mode will affect TweenLite and TweenMax tweens.<br /><br />
 * 		
 * 
 * <b>EXAMPLES:</b><br /><br /> 
 * 
 * 	To start OverwriteManager in <code>AUTO</code> mode (the default) and then do a simple TweenLite tween, simply do:<br /><br /><code>
 * 		
 * 		import com.greensock.OverwriteManager;<br />
 * 		import com.greensock.TweenLite;<br /><br />
 * 		
 * 		OverwriteManager.init(OverwriteManager.AUTO);<br />
 * 		TweenLite.to(mc, 2, {x:300});<br /><br /></code>
 * 		
 * 	You can also define overwrite behavior in individual tweens, like so:<br /><br /><code>
 * 	
 * 		import com.greensock.OverwriteManager;<br />
 * 		import com.greensock.TweenLite;<br /><br />
 * 		
 * 		OverwriteManager.init(2);<br />
 * 		TweenLite.to(mc, 2, {x:"300", y:"100"});<br />
 * 		TweenLite.to(mc, 1, {alpha:0.5, overwrite:1}); //or use the constant OverwriteManager.ALL_IMMEDIATE<br />
 * 		TweenLite.to(mc, 3, {x:200, rotation:30, overwrite:2}); //or use the constant OverwriteManager.AUTO<br /><br /></code>
 * 		
 * 		
 * 	OverwriteManager's mode can be changed anytime after init() is called, like.<br /><br /><code>
 * 		
 * 		OverwriteManager.mode = OverwriteManager.CONCURRENT;<br /><br /></code>
 * 
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 */	 
	final public class OverwriteManager {
		/** @private **/
		public static const version:Number = 6.1;
		/** Won't overwrite any other tweens **/
		public static const NONE:int 			= 0;
		/** Overwrites all existing tweens of the same target immediately when the tween is created **/
		public static const ALL_IMMEDIATE:int 	= 1;
		/** Only overwrites individual overlapping tweening properties in other tweens of the same target. TweenMax, TimelineLite, and TimelineMax automatically init() OverwriteManager in this mode if you haven't already called OverwriteManager.init(). **/
		public static const AUTO:int 			= 2;
		/** Overwrites tweens of the same target that are active when the tween renders for the first time. **/ 
		public static const CONCURRENT:int 		= 3;
		/** Overwrites all tweens of the same target (regardless of overlapping properties or timing) when the tween renders for the first time as opposed to ALL_IMMEDIATE which performs overwriting immediately when the tween is created. **/
		public static const ALL_ONSTART:int 	= 4;
		/** Overwrites tweens of the same target that existed before this tween regardless of their start/end time or active state or overlapping properties. **/
		public static const PREEXISTING:int 	= 5;
		/** The default overwrite mode for all TweenLite and TweenMax instances **/
		public static var mode:int;
		/** @private **/
		public static var enabled:Boolean;
		
		/** 
		 * Initializes OverwriteManager and sets the default management mode. Options include: 
		 * <ul>
		 * 		<li><b> NONE (0):</b> 
		 * 					<ol>
		 * 						<li><b>When:</b> Never</li>
		 * 						<li><b>Finds:</b> Nothing</li>
		 * 						<li><b>Kills:</b> Nothing</li>
		 * 						<li><b>Performance:</b> Excellent</li>
		 * 						<li><b>Good for:</b> When you know that your tweens won't conflict and you want maximum speed.</li>
		 * 					</ol>
		 * 		</li>
		 * 				
		 * 		<li><b> ALL_IMMEDIATE (1):</b> 
		 * 					<ol>
		 * 						<li><b>When:</b> Immediately when the tween is created.</li>
		 * 						<li><b>Finds:</b> All tweens of the same target (regardless of timing or overlapping properties).</li>
		 * 						<li><b>Kills:</b> Every tween found</li>
		 * 						<li><b>Performance:</b> Excellent</li>
		 * 						<li><b>Good for:</b> When you want the tween to take priority over all other tweens of the 
		 * 											 same target, like on button rollovers/rollouts. However, this mode is 
		 * 											 bad for setting up sequences.</li>
		 * 					</ol>
		 * 					This is the default mode for TweenLite unless TweenMax, TimelineLite, 
		 * 					or TimelineMax are used in the SWF (in which case <code>AUTO</code> is the default mode).
		 * 		</li>
		 * 					
		 * 		<li><b> AUTO (2):</b> 
		 * 					<ol>
		 * 						<li><b>When:</b> The first time the tween renders (you can <code>invalidate()</code> a tween to force it 
		 * 										 to re-init and run its overwriting routine again next time it renders)</li>
		 * 						<li><b>Finds:</b> Only tweens of the same target that are active (running). Tweens that haven't started yet are immune.</li>
		 * 						<li><b>Kills:</b> Only individual overlapping tweening properties. If all tweening properties 
		 * 										  have been overwritten, the entire tween will be killed as well.</li>
		 * 						<li><b>Performance:</b> Very good when there aren't many overlapping tweens; fair when there are.</li>
		 * 						<li><b>Good for:</b> Virtually all situations. This mode does the best job overall of handling 
		 * 											 overwriting in an intuitive way and is excellent for sequencing. </li>
		 * 					</ol>
		 * 					This is the default mode when TweenMax, TimelineLite, or TimelineMax is used in your swf (those classes
		 * 					automatically init() OverwriteManager in <code>AUTO</code> mode unless you have already initted OverwriteManager manually).
		 * 		</li>
		 * 					
		 * 		<li><b> CONCURRENT (3):</b> 
		 * 					<ol>
		 * 						<li><b>When:</b> The first time the tween renders (you can <code>invalidate()</code> a tween to force it 
		 * 										 to re-init and run its overwriting routine again next time it renders)</li>
		 * 						<li><b>Finds:</b> Only tweens of the same target that are active (running). Tweens that haven't started yet are immune.</li>
		 * 						<li><b>Kills:</b> Every tween found</li>
		 * 						<li><b>Performance:</b> Very good</li>
		 * 						<li><b>Good for:</b> When you want the target object to only be controled by one tween at a time. Good
		 * 											 for sequencing although AUTO mode is typically better because it will only kill
		 * 											 individual overlapping properties instead of entire tweens.</li>
		 * 					</ol>
		 * 		</li>
		 * 				
		 * 		<li><b> ALL_ONSTART (4):</b> 
		 * 					<ol>
		 * 						<li><b>When:</b> The first time the tween renders (you can <code>invalidate()</code> a tween to force it 
		 * 										 to re-init and run its overwriting routine again next time it renders)</li>
		 * 						<li><b>Finds:</b> All tweens of the same target (regardless of timing or overlapping properties).</li>
		 * 						<li><b>Kills:</b> Every tween found</li>
		 * 						<li><b>Performance:</b> Very good</li>
		 * 						<li><b>Good for:</b> When you want a tween to take priority and wipe out all other tweens of the 
		 * 											 same target even if they start later. This mode is rarely used.</li>
		 * 					</ol>
		 * 		</li>
		 * 
		 * 		<li><b> PREEXISTING (5):</b> 
		 * 					<ol>
		 * 						<li><b>When:</b> The first time the tween renders (you can <code>invalidate()</code> a tween to force it 
		 * 										 to re-init and run its overwriting routine again next time it renders)</li>
		 * 						<li><b>Finds:</b> Only the tweens of the same target that were created before this tween was created 
		 * 										  (regardless of timing or overlapping properties). Virtually identical to <code>ALL_IMMEDIATE</code>
		 * 										  except that <code>PREEXISTING</code> doesn't run its overwriting routines until it renders for the
		 * 										  first time, meaning that if it has a delay, other tweens won't be overwritten until the delay expires.</li>
		 * 						<li><b>Kills:</b> Every tween found</li>
		 * 						<li><b>Performance:</b> Very good</li>
		 * 						<li><b>Good for:</b> When the order in which your code runs plays a critical role, like when tweens
		 * 											 that you create later should always take precidence over previously created ones
		 * 											 regardless of when they're scheduled to run. If <code>ALL_IMMEDIATE</code> is great except
		 * 											 that you want to wait on overwriting until the tween begins, <code>PREEXISTING</code> is perfect.</li>
		 * 					</ol>
		 * 		</li>
		 * 	</ul>
		 * 
		 * @param defaultMode The default mode that OverwriteManager should use.
		 **/
		public static function init(defaultMode:int=2):int {
			if (TweenLite.version < 11.6) {
				throw new Error("Warning: Your TweenLite class needs to be updated to work with OverwriteManager (or you may need to clear your ASO files). Please download and install the latest version from http://www.tweenlite.com.");
			}
			TweenLite.overwriteManager = OverwriteManager;
			mode = defaultMode;
			enabled = true;
			return mode;
		}
		
		/** 
		 * @private 
		 * @return Boolean value indicating whether or not properties may have changed on the target when overwriting occurred. For example, when a motionBlur (plugin) is disabled, it swaps out a BitmapData for the target and may alter the alpha. We need to know this in order to determine whether or not the new tween should be re-initted() with the changed properties. 
		 **/
		public static function manageOverwrites(tween:TweenLite, props:Object, targetTweens:Array, mode:int):Boolean {
			var i:int, changed:Boolean, curTween:TweenLite;
			if (mode >= 4) {
				var l:int = targetTweens.length;
				for (i = 0; i < l; i++) {
					curTween = targetTweens[i];
					if (curTween != tween) {
						if (curTween.setEnabled(false, false)) {
							changed = true;
						}
					} else if (mode == 5) {
						break;
					}
				}
				return changed;
			}
			
			//NOTE: Add 0.0000000001 to overcome floating point errors that can cause the startTime to be VERY slightly off (when a tween's currentTime property is set for example)
			var startTime:Number = tween.cachedStartTime + 0.0000000001, overlaps:Array = [], cousins:Array = [], cCount:int = 0, oCount:int = 0;
			i = targetTweens.length;
			while (--i > -1) {
				curTween = targetTweens[i];
				if (curTween == tween || curTween.gc || (!curTween.initted && startTime - curTween.cachedStartTime <= 0.0000000002)) {
					//ignore
				} else if (curTween.timeline != tween.timeline) {
					if (!getGlobalPaused(curTween)) {
						cousins[cCount++] = curTween;
					}
				} else if (curTween.cachedStartTime <= startTime && curTween.cachedStartTime + curTween.totalDuration + 0.0000000001 > startTime && !curTween.cachedPaused && !(tween.cachedDuration == 0 && startTime - curTween.cachedStartTime <= 0.0000000002)) {
					overlaps[oCount++] = curTween;
				}
			}
			
			if (cCount != 0) { //tweens that are nested in other timelines may have various offsets and timeScales so we need to translate them to a global/root one to see how they compare.
				var combinedTimeScale:Number = tween.cachedTimeScale, combinedStartTime:Number = startTime, cousin:TweenCore, cousinStartTime:Number, timeline:SimpleTimeline;
				timeline = tween.timeline;
				while (timeline) {
					combinedTimeScale *= timeline.cachedTimeScale;
					combinedStartTime += timeline.cachedStartTime;
					timeline = timeline.timeline;
				}
				startTime = combinedTimeScale * combinedStartTime;
				i = cCount;
				while (--i > -1) {
					cousin = cousins[i];
					combinedTimeScale = cousin.cachedTimeScale;
					combinedStartTime = cousin.cachedStartTime;
					timeline = cousin.timeline;
					while (timeline) {
						combinedTimeScale *= timeline.cachedTimeScale;
						combinedStartTime += timeline.cachedStartTime;
						timeline = timeline.timeline;
					}
					cousinStartTime = combinedTimeScale * combinedStartTime;
					if (cousinStartTime <= startTime && (cousinStartTime + (cousin.totalDuration * combinedTimeScale) + 0.0000000001 > startTime || cousin.cachedDuration == 0)) {
						overlaps[oCount++] = cousin;
					}
				}
			}
			
			if (oCount == 0) {
				return changed;
			}
			
			i = oCount;
			if (mode == 2) {
				while (--i > -1) {
					curTween = overlaps[i];
					if (curTween.killVars(props)) {
						changed = true;
					}
					if (curTween.cachedPT1 == null && curTween.initted) {
						curTween.setEnabled(false, false); //if all property tweens have been overwritten, kill the tween.
					}
				}
			
			} else {
				while (--i > -1) {
					if (TweenLite(overlaps[i]).setEnabled(false, false)) { //flags for garbage collection
						changed = true;
					}
				}
			}
			return changed;
		}
		
		/** @private **/
		public static function getGlobalPaused(tween:TweenCore):Boolean {
			var paused:Boolean;
			while (tween) {
				if (tween.cachedPaused) {
					paused = true; //we don't just return true immediately here because of an odd bug in Flash that could (in EXTREMELY rare circumstances) throw an error. 
					break;
				}
				tween = tween.timeline;
			}
			return paused;
		}
		
	}
}