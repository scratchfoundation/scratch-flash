/**
 * VERSION: 1.02
 * DATE: 10/2/2009
 * ACTIONSCRIPT VERSION: 3.0 
 * UPDATES AND DOCUMENTATION AT: http://www.TweenMax.com
 **/
package com.greensock.plugins {
	import com.greensock.*;
/**
 * Performs SLERP interpolation between 2 Quaternions. Each Quaternion should have x, y, z, and w properties.
 * Simply pass in an Object containing properties that correspond to your object's quaternion properties. 
 * For example, if your myCamera3D has an "orientation" property that's a Quaternion and you want to 
 * tween its values to x:1, y:0.5, z:0.25, w:0.5, you could do:<br /><br /><code>
 * 
 * 	TweenLite.to(myCamera3D, 2, {quaternions:{orientation:new Quaternion(1, 0.5, 0.25, 0.5)}});<br /><br /></code>
 * 	
 * You can define as many quaternion properties as you want.<br /><br />
 * 
 * <b>USAGE:</b><br /><br />
 * <code>
 * 		import com.greensock.TweenLite; <br />
 * 		import com.greensock.plugins.TweenPlugin; <br />
 * 		import com.greensock.plugins.QuaternionsPlugin; <br />
 * 		TweenPlugin.activate([QuaternionsPlugin]); //activation is permanent in the SWF, so this line only needs to be run once.<br /><br />
 * 
 * 		TweenLite.to(myCamera3D, 2, {quaternions:{orientation:new Quaternion(1, 0.5, 0.25, 0.5)}}); <br /><br />
 * </code>
 * 
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 */
	public class QuaternionsPlugin extends TweenPlugin {
		/** @private **/
		public static const API:Number = 1.0; //If the API/Framework for plugins changes in the future, this number helps determine compatibility
		
		/** @private **/
		protected static const _RAD2DEG:Number = 180 / Math.PI; //precalculate for speed
		
		/** @private **/
		protected var _target:Object;
		/** @private **/
		protected var _quaternions:Array = [];
		
		/** @private **/
		public function QuaternionsPlugin() {
			super();
			this.propName = "quaternions"; //name of the special property that the plugin should intercept/manage
			this.overwriteProps = [];
		}
		
		/** @private **/
		override public function onInitTween(target:Object, value:*, tween:TweenLite):Boolean {
			if (value == null) {
				return false;
			}
			for (var p:String in value) {
				initQuaternion(target[p], value[p], p);
			}
			return true;	
		}
		
		/** @private **/
		public function initQuaternion(start:Object, end:Object, propName:String):void {
			var angle:Number, q1:Object, q2:Object, x1:Number, x2:Number, y1:Number, y2:Number, z1:Number, z2:Number, w1:Number, w2:Number, theta:Number;
			q1 = start;
			q2 = end;
			x1 = q1.x; x2 = q2.x;
			y1 = q1.y; y2 = q2.y;
			z1 = q1.z; z2 = q2.z;
			w1 = q1.w; w2 = q2.w;
			angle = x1 * x2 + y1 * y2 + z1 * z2 + w1 * w2;
			if (angle < 0) {
				x1 *= -1;
				y1 *= -1;
				z1 *= -1;
				w1 *= -1;
				angle *= -1;
			}
			if ((angle + 1) < 0.000001) {
				y2 = -y1;
				x2 = x1;
				w2 = -w1;
				z2 = z1;
			}
			theta = Math.acos(angle);
			_quaternions[_quaternions.length] = [q1, propName, x1, x2, y1, y2, z1, z2, w1, w2, angle, theta, 1 / Math.sin(theta)];
			this.overwriteProps[this.overwriteProps.length] = propName;
		}
		
		/** @private **/
		override public function killProps(lookup:Object):void {
			for (var i:int = _quaternions.length - 1; i > -1; i--) {
				if (lookup[_quaternions[i][1]] != undefined) {
					_quaternions.splice(i, 1);
				}
			}
			super.killProps(lookup);
		}	
		
		/** @private **/
		override public function set changeFactor(n:Number):void {
			var i:int, q:Array, scale:Number, invScale:Number;
			for (i = _quaternions.length - 1; i > -1; i--) {
				q = _quaternions[i];
				if ((q[10] + 1) > 0.000001) {
					 if ((1 - q[10]) >= 0.000001) {
						scale = Math.sin(q[11] * (1 - n)) * q[12];
						invScale = Math.sin(q[11] * n) * q[12];
					 } else {
						scale = 1 - n;
						invScale = n;
					 }
				} else {
					scale = Math.sin(Math.PI * (0.5 - n));
					invScale = Math.sin(Math.PI * n);
				}
				q[0].x = scale * q[2] + invScale * q[3];
				q[0].y = scale * q[4] + invScale * q[5];
				q[0].z = scale * q[6] + invScale * q[7];
				q[0].w = scale * q[8] + invScale * q[9];
			}
			/*
			Array access is faster (though less readable). Here is the key:
			0 - target
			1 = propName
			2 = x1
			3 = x2
			4 = y1
			5 = y2
			6 = z1
			7 = z2
			8 = w1
			9 = w2
			10 = angle
			11 = theta
			12 = invTheta
			*/
		}
		

	}
}