/**
 * VERSION: 1.12
 * DATE: 10/2/2009
 * ACTIONSCRIPT VERSION: 3.0 
 * UPDATES AND DOCUMENTATION AT: http://www.TweenMax.com
 **/
package com.greensock.plugins {
	import com.greensock.*;
/**
 * Identical to bezier except that instead of defining bezier control point values, you
 * define points through which the bezier values should move. This can be more intuitive
 * than using control points. Simply pass as many objects in the bezier Array as you'd like, 
 * one for each point through which the values should travel. For example, if you want the
 * curved motion path to travel through the coordinates x:250, y:100 and x:50, y:200 and then
 * end up at 500, 100, you'd do: <br /><br />
 * 
 * <code>TweenLite.to(mc, 2, {bezierThrough:[{x:250, y:100}, {x:50, y:200}, {x:500, y:200}]});</code><br /><br />
 * 
 * Keep in mind that you can bezierThrough tween ANY properties, not just x/y. <br /><br />
 * 
 * Also, if you'd like to rotate the target in the direction of the bezier path, 
 * use the orientToBezier special property. In order to alter a rotation property accurately, 
 * TweenLite/Max needs 5 pieces of information: 
 * <ol>
 * 		<li> Position property 1 (typically <code>"x"</code>)</li>
 * 		<li> Position property 2 (typically <code>"y"</code>)</li>
 * 		<li> Rotational property (typically <code>"rotation"</code>)</li>
 * 		<li> Number of degrees to add (optional - makes it easy to orient your MovieClip properly)</li>
 * 		<li> Tolerance (default is 0.01, but increase this if the rotation seems to jitter during the tween)</li>
 * </ol><br />
 * 
 * The orientToBezier property should be an Array containing one Array for each set of these values. 
 * For maximum flexibility, you can pass in any number of arrays inside the container array, one 
 * for each rotational property. This can be convenient when working in 3D because you can rotate
 * on multiple axis. If you're doing a standard 2D x/y tween on a bezier, you can simply pass 
 * in a boolean value of true and TweenLite/Max will use a typical setup, <code>[["x", "y", "rotation", 0, 0.01]]</code>. 
 * Hint: Don't forget the container Array (notice the double outer brackets) <br /><br />
 * 
 * <b>USAGE:</b><br /><br />
 * <code>
 * 		import com.greensock.TweenLite; <br />
 * 		import com.greensock.plugins.TweenPlugin; <br />
 * 		import com.greensock.plugins.BezierThroughPlugin; <br />
 * 		TweenPlugin.activate([BezierThroughPlugin]); //activation is permanent in the SWF, so this line only needs to be run once.<br /><br />
 * 
 * 		TweenLite.to(mc, 2, {bezierThrough:[{x:250, y:100}, {x:50, y:200}, {x:500, y:200}]}); <br /><br />
 * </code>
 * 
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 */
	public class BezierThroughPlugin extends BezierPlugin {
		/** @private **/
		public static const API:Number = 1.0; //If the API/Framework for plugins changes in the future, this number helps determine compatibility
		
		/** @private **/
		public function BezierThroughPlugin() {
			super();
			this.propName = "bezierThrough"; //name of the special property that the plugin should intercept/manage
		}
		
		/** @private **/
		override public function onInitTween(target:Object, value:*, tween:TweenLite):Boolean {
			if (!(value is Array)) {
				return false;
			}
			init(tween, value as Array, true);
			return true;	
		}
		
	}
}