/**
 * VERSION: 0.5
 * DATE: 2011-01-12
 * AS3
 * UPDATES AND DOCS AT: http://www.greensock.com
 **/
package com.greensock.motionPaths {
/**
 * A PathFollower is used to associate a particular target object (like a MovieClip, Point, Sprite, etc.) 
 * with a MotionPath and it offers a tweenable <code>progress</code> property that manages positioning
 * the target on the path accordingly. The <code>progress</code> property is a value between
 * 0 and 1 where 0 is at the beginning of the path, 0.5 is in the middle, and 1 is at the end. 
 * When the follower's <code>autoRotate</code> property is <code>true</code>, the target will be
 * rotated in relation to the path that it is following. <br /><br />
 * 
 * @example Example AS3 code:<listing version="3.0">
import com.greensock.~~;
import com.greensock.motionPaths.~~;

//create a circle motion path at coordinates x:150, y:150 with a radius of 100
var circle:Circle2D = new Circle2D(150, 150, 100);

//make the MovieClip "mc" follow the circle and start at a position of 90 degrees (this returns a PathFollower instance)
var follower:PathFollower = circle.addFollower(mc, circle.angleToProgress(90), true);

//tween the follower clockwise along the path to 315 degrees
TweenLite.to(follower, 2, {progress:circle.followerTween(follower, 315, Direction.CLOCKWISE)});

//tween the follower counter-clockwise to 200 degrees and add an extra revolution
TweenLite.to(follower, 2, {progress:circle.followerTween(follower, 200, Direction.COUNTER_CLOCKWISE, 1)});
</listing>
 * 
 * <b>NOTES</b><br />
 * <ul>
 * 		<li>All followers are automatically updated when you alter the MotionPath that they're following.</li>
 * 		<li>To tween all followers along the path at once, simply tween the MotionPath's <code>progress</code> 
 * 			property which will provide better performance than tweening each follower independently.</li>
 * </ul>
 * 
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 */	
	public class PathFollower {
		/** The target object associated with the PathFollower (like a Sprite, MovieClip, Point, etc.). The object must have x and y properties. **/
		public var target:Object;
		
		/** @private **/
		public var cachedProgress:Number;
		/** @private not re-interpolated between 0 and 1. We store this value and cachedProgress instead of calculating one of them on the fly in order to maximize rendering performance. **/
		public var cachedRawProgress:Number;
		/** @private **/
		public var cachedNext:PathFollower;
		/** @private **/
		public var cachedPrev:PathFollower;
		
		/** The MotionPath instance that this PathFollower should follow **/
		public var path:MotionPath;
		/** When <code>autoRotate</code> is <code>true</code>, the follower will automatically be rotated so that it is oriented to the angle of the path that it is following. To offset this value (like to always add 90 degrees for example), use the <code>rotationOffset</code> property. **/
		public var autoRotate:Boolean;
		/** When <code>autoRotate</code> is <code>true</code>, this value will always be added to the resulting <code>rotation</code> of the target. **/
		public var rotationOffset:Number;
		
		/**
		 * Constructor
		 * 
		 * @param target The target object associated with the PathFollower (like a Sprite, MovieClip, Point, etc.). The object must have x and y properties. 
		 * @param autoRotate When <code>autoRotate</code> is <code>true</code>, the follower will automatically be rotated so that it is oriented to the angle of the path that it is following. To offset this value (like to always add 90 degrees for example), use the <code>rotationOffset</code> property.
		 * @param rotationOffset When <code>autoRotate</code> is <code>true</code>, this value will always be added to the resulting <code>rotation</code> of the target.
		 */
		public function PathFollower(target:Object, autoRotate:Boolean=false, rotationOffset:Number=0) {
			this.target = target;
			this.autoRotate = autoRotate;
			this.rotationOffset = rotationOffset;
			this.cachedProgress = this.cachedRawProgress = 0;
		}
		
		/** 
		 * Identical to <code>progress</code> except that the value doesn't get re-interpolated between 0 and 1.
		 * <code>rawProgress</code> (and <code>progress</code>) indicates the follower's position along the motion path. 
		 * For example, to place the object on the path at the halfway point, you could set its <code>rawProgress</code> 
		 * to 0.5. You can tween to values that are greater than 1 or less than 0. For example, setting <code>rawProgress</code> 
		 * to 1.2 also sets <code>progress</code> to 0.2 and setting <code>rawProgress</code> to -0.2 is the 
		 * same as setting <code>progress</code> to 0.8. If your goal is to tween the PathFollower around a Circle2D twice 
		 * completely, you could just add 2 to the <code>rawProgress</code> value or use a relative value in the tween, like: <br /><br /><code>
		 * 
		 * TweenLite.to(myFollower, 5, {rawProgress:"2"}); //or myFollower.rawProgress + 2
		 * 
		 * </code><br /><br />
		 * 
		 * Since <code>rawProgress</code> doesn't re-interpolate values to always fitting between 0 and 1, it
		 * can be useful if you need to find out how many times the PathFollower has wrapped.
		 * 
		 * @see #progress
		 **/
		public function get rawProgress():Number {
			return this.cachedRawProgress;
		}
		public function set rawProgress(value:Number):void {
			this.progress = value;
		}
		
		/** 
		 * A value between 0 and 1 that indicates the follower's position along the motion path. For example,
		 * to place the object on the path at the halfway point, you would set its <code>progress</code> to 0.5.
		 * You can tween to values that are greater than 1 or less than 0 but the values are simply wrapped. 
		 * So, for example, setting <code>progress</code> to 1.2 is the same as setting it to 0.2 and -0.2 is the 
		 * same as 0.8. If your goal is to tween the PathFollower around a Circle2D twice completely, you could just 
		 * add 2 to the <code>progress</code> value or use a relative value in the tween, like: <br /><br /><code>
		 * 
		 * TweenLite.to(myFollower, 5, {progress:"2"}); //or myFollower.progress + 2</code><br /><br />
		 * 
		 * <code>progress</code> is identical to <code>rawProgress</code> except that <code>rawProgress</code> 
		 * does not get re-interpolated between 0 and 1. For example, if <code>rawProgress</code> 
		 * is set to -3.4, <code>progress</code> would be 0.6. <code>rawProgress</code> can be useful if 
		 * you need to find out how many times the PathFollower has wrapped.
		 * 
		 * Also note that if you set <code>progress</code> to any value <i>outside</i> of the 0-1 range, 
		 * <code>rawProgress</code> will be set to that exact value. If <code>progress</code> is
		 * set to a value <i>within</i> the typical 0-1 range, it will only affect the decimal value of 
		 * <code>rawProgress</code>. For example, if <code>rawProgress</code> is 3.4 and then you 
		 * set <code>progress</code> to 0.1, <code>rawProgress</code> will end up at 3.1 (notice
		 * the "3" integer was kept). But if <code>progress</code> was instead set to 5.1, since
		 * it exceeds the 0-1 range, <code>rawProgress</code> would become 5.1. This behavior was 
		 * adopted in order to deal most effectively with wrapping situations. For example, if 
		 * <code>rawProgress</code> was tweened to 3.4 and then later you wanted to fine-tune
		 * where things were positioned by tweening <code>progress</code> to 0.8, it still may be
		 * important to be able to determine how many loops/wraps occurred, so <code>rawProgress</code>
		 * should be 3.8, not reset to 0.8. Feel free to use <code>rawProgress</code> exclusively if you 
		 * prefer to avoid any of the re-interpolation that occurs with <code>progress</code>.
		 * 
		 * @see #rawProgress
		 **/
		public function get progress():Number {
			return this.cachedProgress;
		}
		public function set progress(value:Number):void {
			if (value > 1) {
				this.cachedRawProgress = value;
				this.cachedProgress = value - int(value);
				if (this.cachedProgress == 0) {
					this.cachedProgress = 1;
				}
			} else if (value < 0) {
				this.cachedRawProgress = value;
				this.cachedProgress = value - (int(value) - 1);
			} else {
				this.cachedRawProgress = int(this.cachedRawProgress) + value;
				this.cachedProgress = value;
			}
			if (this.path) {
				this.path.renderObjectAt(this.target, this.cachedProgress, this.autoRotate, this.rotationOffset);
			}
		}
		
	}
}