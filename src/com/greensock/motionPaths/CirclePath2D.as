/**
 * VERSION: 0.4 (beta)
 * DATE: 2010-12-22
 * AS3
 * UPDATES AND DOCS AT: http://www.GreenSock.com
 **/
package com.greensock.motionPaths {
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.geom.Matrix;

/**
 * A CirclePath2D defines a circular path on which a PathFollower can be placed, making it simple to tween objects
 * along a circle or oval (make an oval by altering the width/height/scaleX/scaleY properties). A PathFollower's 
 * position along the path is described using its <code>progress</code> property, a value between 0 and 1 where 
 * 0 is at the beginning of the path, 0.5 is in the middle, and 1 is at the very end of the path. So to tween a 
 * PathFollower along the path, you can simply tween its <code>progress</code> property. To tween ALL of the 
 * followers on the path at once, you can tween the CirclePath2D's <code>progress</code> property. PathFollowers 
 * automatically wrap so that if the <code>progress</code> value exceeds 1 or drops below 0, it shows up on 
 * the other end of the path.<br /><br />
 *  
 * Since CirclePath2D extends the Shape class, you can add an instance to the display list to see a line representation
 * of the path drawn which can be helpful especially during the production phase. Use <code>lineStyle()</code> 
 * to adjust the color, thickness, and other attributes of the line that is drawn (or set the CirclePath2D's 
 * <code>visible</code> property to false or don't add it to the display list if you don't want to see the line 
 * at all). You can also adjust all of its properties like <code>radius, scaleX, scaleY, rotation, width, height, x,</code> 
 * and <code>y</code>. That means you can tween those values as well to achieve very dynamic, complex effects with ease.<br /><br />
 * 
 * @example Example AS3 code:<listing version="3.0">
import com.greensock.~~;
import com.greensock.plugins.~~;
import com.greensock.motionPaths.~~;
TweenPlugin.activate([CirclePath2DPlugin]); //only needed once in your swf, and only if you plan to use the CirclePath2D tweening feature for convenience

//create a circle motion path at coordinates x:150, y:150 with a radius of 100
var circle:CirclePath2D = new CirclePath2D(150, 150, 100);

//tween mc along the path from the bottom (90 degrees) to 315 degrees in the counter-clockwise direction and make an extra revolution
TweenLite.to(mc, 3, {circlePath2D:{path:circle, startAngle:90, endAngle:315, direction:Direction.COUNTER_CLOCKWISE, extraRevolutions:1}});

//tween the circle's rotation, scaleX, scaleY, x, and y properties:
TweenLite.to(circle, 3, {rotation:180, scaleX:0.5, scaleY:2, x:250, y:200});

//show the path visually by adding it to the display list (optional)
this.addChild(circle);


//--- Instead of using the plugin, you could manually manage followers and tween their "progress" property...
 
//make the MovieClip "mc2" follow the circle and start at a position of 90 degrees (this returns a PathFollower instance)
var follower:PathFollower = circle.addFollower(mc2, circle.angleToProgress(90));

//tween the follower clockwise along the path to 315 degrees
TweenLite.to(follower, 2, {progress:circle.followerTween(follower, 315, Direction.CLOCKWISE)});

//tween the follower counter-clockwise to 200 degrees and add an extra revolution
TweenLite.to(follower, 2, {progress:circle.followerTween(follower, 200, Direction.COUNTER_CLOCKWISE, 1)});
</listing>
 * 
 * <b>NOTES</b><br />
 * <ul>
 * 		<li>All followers's positions are automatically updated when you alter the MotionPath that they're following.</li>
 * 		<li>To tween all followers along the path at once, simply tween the MotionPath's <code>progress</code> 
 * 			property which will provide better performance than tweening each follower independently.</li>
 * </ul>
 * 
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 */	
	public class CirclePath2D extends MotionPath {		
		/** @private **/
		protected var _radius:Number;
		
		/**
		 * Constructor
		 * 
		 * @param x The x coordinate of the origin (center) of the circle
		 * @param y The y coordinate of the origin (center) of the circle
		 * @param radius The radius of the circle
		 */
		public function CirclePath2D(x:Number, y:Number, radius:Number) {
			super();
			_radius = radius;
			super.x = x;
			super.y = y;
		}
		
		/** @inheritDoc**/
		override public function update(event:Event=null):void {
			var angle:Number, px:Number, py:Number;
			var m:Matrix = this.transform.matrix;
			var a:Number = m.a, b:Number = m.b, c:Number = m.c, d:Number = m.d, tx:Number = m.tx, ty:Number = m.ty;
			var f:PathFollower = _rootFollower;
			while (f) {
				angle = f.cachedProgress * Math.PI * 2;
				px = Math.cos(angle) * _radius;
				py = Math.sin(angle) * _radius;
				f.target.x = px * a + py * c + tx;
				f.target.y = px * b + py * d + ty;
				
				if (f.autoRotate) {
					angle += Math.PI / 2;
					px = Math.cos(angle) * _radius;
					py = Math.sin(angle) * _radius;
					f.target.rotation = Math.atan2(px * m.b + py * m.d, px * m.a + py * m.c) * _RAD2DEG + f.rotationOffset;
				}
				
				f = f.cachedNext;
			}
			if (_redrawLine) {
				var g:Graphics = this.graphics;
				g.clear();
				g.lineStyle(_thickness, _color, _lineAlpha, _pixelHinting, _scaleMode, _caps, _joints, _miterLimit);
				g.drawCircle(0, 0, _radius);
				_redrawLine = false;
			}
		}
		
		/** @inheritDoc **/
		override public function renderObjectAt(target:Object, progress:Number, autoRotate:Boolean=false, rotationOffset:Number=0):void {
			var angle:Number = progress * Math.PI * 2;
			var m:Matrix = this.transform.matrix;
			var px:Number = Math.cos(angle) * _radius;
			var py:Number = Math.sin(angle) * _radius;
			target.x = px * m.a + py * m.c + m.tx;
			target.y = px * m.b + py * m.d + m.ty;
			
			if (autoRotate) {
				angle += Math.PI / 2;
				px = Math.cos(angle) * _radius;
				py = Math.sin(angle) * _radius;
				target.rotation = Math.atan2(px * m.b + py * m.d, px * m.a + py * m.c) * _RAD2DEG + rotationOffset;
			}
		}
		
		
		/**
		 * Translates an angle (in degrees or radians) to the associated progress value 
		 * on the CirclePath2D. For example, to position <code>mc</code> on the CirclePath2D at 90 degrees
		 * (bottom), you'd do:<br /><br /><code>
		 * 
		 * var follower:PathFollower = myCircle.addFollower(mc, myCircle.angleToProgress(90));<br />
		 * 
		 * </code>
		 * 
		 * @param angle The angle whose progress value you want to determine
		 * @param useRadians If you prefer to define the angle in radians instead of degrees, set this to true (it is false by default)
		 * @return The progress value associated with the angle
		 */
		public function angleToProgress(angle:Number, useRadians:Boolean=false):Number {
			var revolution:Number = useRadians ? Math.PI * 2 : 360;
			if (angle < 0) {
				angle += (int(-angle / revolution) + 1) * revolution;
			} else if (angle > revolution) {
				angle -= int(angle / revolution) * revolution;
			}
			return angle / revolution;
		}
		
		/**
		 * Translates a progress value (typically between 0 and 1 where 0 is the beginning of the path, 
		 * 0.5 is in the middle, and 1 is at the end) to the associated angle on the CirclePath2D. 
		 * For example, to find out what angle a particular PathFollower is at, you'd do:<br /><br /><code>
		 * 
		 * var angle:Number = myCircle.progressToAngle(myFollower.progress, false);<br />
		 * 
		 * </code>
		 * 
		 * @param progress The progress value to translate into an angle
		 * @param useRadians If you prefer that the angle be described in radians instead of degrees, set this to true (it is false by default)
		 * @return The angle (in degrees or radians depending on the useRadians value) associated with the progress value.
		 */
		public function progressToAngle(progress:Number, useRadians:Boolean=false):Number {
			var revolution:Number = useRadians ? Math.PI * 2 : 360;
			return progress * revolution;
		}
		
		/**
		 * Simplifies tweening by determining a relative change in the progress value of a follower based on the 
		 * endAngle, direction, and extraRevolutions that you define. For example, to tween <code>myFollower</code>
		 * from wherever it is currently to the position at 315 degrees, moving in the COUNTER_CLOCKWISE direction 
		 * and going 2 extra revolutions, you could do:<br /><br /><code>
		 * 
		 * TweenLite.to(myFollower, 2, {progress:myCircle.followerTween(myFollower, 315, Direction.COUNTER_CLOCKWISE, 2)});
		 * </code>
		 * 
		 * @param follower The PathFollower (or its associated target) that will be tweened (determines the start angle)
		 * @param endAngle The destination (end) angle
		 * @param direction The direction in which to travel - options are <code>Direction.CLOCKWISE</code> ("clockwise"), <code>Direction.COUNTER_CLOCKWISE</code> ("counterClockwise"), or <code>Direction.SHORTEST</code> ("shortest").
		 * @param extraRevolutions If instead of going directly to the endAngle, you want the target to travel one or more extra revolutions around the path before going to the endAngle, define that number of revolutions here.
		 * @param useRadians If you prefer to define the angle in radians instead of degrees, set this to true (it is false by default)
		 * @return A String representing the amount of change in the <code>progress</code> value (feel free to cast it as a Number if you want, but it returns a String because TweenLite/Max/Nano recognize Strings as relative values.
		 */
		public function followerTween(follower:*, endAngle:Number, direction:String="clockwise", extraRevolutions:uint=0, useRadians:Boolean=false):String {
			var revolution:Number = useRadians ? Math.PI * 2 : 360;
			return String(anglesToProgressChange(getFollower(follower).progress * revolution, endAngle, direction, extraRevolutions, useRadians));
		}
		
		/**
		 * Returns the amount of <code>progress</code> change between two angles on the CirclePath2D, allowing special 
		 * parameters like direction and extraRevolutions. 
		 * 
		 * @param startAngle The starting angle
		 * @param endAngle The ending angle
		 * @param direction The direction in which to travel - options are <code>Direction.CLOCKWISE</code> ("clockwise"), <code>Direction.COUNTER_CLOCKWISE</code> ("counterClockwise"), or <code>Direction.SHORTEST</code> ("shortest").
		 * @param extraRevolutions If instead of going directly to the endAngle, you want the target to travel one or more extra revolutions around the path before going to the endAngle, define that number of revolutions here.
		 * @param useRadians If you prefer to define the angle in radians instead of degrees, set this to true (it is false by default)
		 * @return A Number representing the amount of change in the <code>progress</code> value.
		 */
		public function anglesToProgressChange(startAngle:Number, endAngle:Number, direction:String="clockwise", extraRevolutions:uint=0, useRadians:Boolean=false):Number {
			var revolution:Number = useRadians ? Math.PI * 2 : 360;
			var dif:Number = endAngle - startAngle;
			if (dif < 0 && direction == "clockwise") {
				dif += (int(-dif / revolution) + 1) * revolution;
			} else if (dif > 0 && direction == "counterClockwise") {
				dif -= (int(dif / revolution) + 1) * revolution;
			} else if (direction == "shortest") {
				dif = dif % revolution;
				if (dif != dif % (revolution * 0.5)) {
					dif = (dif < 0) ? dif + revolution : dif - revolution;
				}
			}
			if (dif < 0) {
				dif -= extraRevolutions * revolution;
			} else {
				dif += extraRevolutions * revolution;
			}
			return dif / revolution;
		}
		
		/** radius of the circle (does not factor in any transformations like scaleX/scaleY) **/
		public function get radius():Number {
			return _radius;
		}
		public function set radius(value:Number):void {
			_radius = value;
			_redrawLine = true;
			update();
		}
		
		
	}
}