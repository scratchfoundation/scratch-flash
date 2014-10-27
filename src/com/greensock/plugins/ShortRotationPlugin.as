/**
 * VERSION: 1.3
 * DATE: 2011-08-02
 * AS3 
 * UPDATES AND DOCS AT: http://www.TweenMax.com
 **/
package com.greensock.plugins {
	import com.greensock.*;
/**
 * To tween any rotation property of the target object in the shortest direction, use "shortRotation" 
 * For example, if <code>myObject.rotation</code> is currently 170 degrees and you want to tween it to -170 degrees, 
 * a normal rotation tween would travel a total of 340 degrees in the counter-clockwise direction, 
 * but if you use shortRotation, it would travel 20 degrees in the clockwise direction instead. You 
 * can define any number of rotation properties in the shortRotation object which makes 3D tweening
 * easier, like:<br /><br /><code> 
 * 		
 * 		TweenMax.to(mc, 2, {shortRotation:{rotationX:-170, rotationY:35, rotationZ:200}}); <br /><br /></code>
 * 
 * Normally shortRotation is defined in degrees, but if you prefer to have it work with radians instead,
 * simply set the <code>useRadians</code> special property to <code>true</code> like:<br /><br /><code>
 * 
 * 		TweenMax.to(myCustomObject, 2, {shortRotation:{customRotationProperty:Math.PI, useRadians:true}});</code><br /><br />
 * 
 * <b>USAGE:</b><br /><br />
 * <code>
 * 		import com.greensock.TweenLite; <br />
 * 		import com.greensock.plugins.TweenPlugin; <br />
 * 		import com.greensock.plugins.ShortRotationPlugin; <br />
 * 		TweenPlugin.activate([ShortRotationPlugin]); //activation is permanent in the SWF, so this line only needs to be run once.<br /><br />
 * 
 * 		TweenLite.to(mc, 1, {shortRotation:{rotation:-170}});<br /><br />
	
 * 		//or for a 3D tween with multiple rotation values...<br />
 * 		TweenLite.to(mc, 1, {shortRotation:{rotationX:-170, rotationY:35, rotationZ:10}}); <br /><br />
 * </code>
 * 
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 */
	public class ShortRotationPlugin extends TweenPlugin {
		/** @private **/
		public static const API:Number = 1.0; //If the API/Framework for plugins changes in the future, this number helps determine compatibility
		
		/** @private **/
		public function ShortRotationPlugin() {
			super();
			this.propName = "shortRotation";
			this.overwriteProps = [];
		}
		
		/** @private **/
		override public function onInitTween(target:Object, value:*, tween:TweenLite):Boolean {
			if (typeof(value) == "number") {
				return false;
			}
			var useRadians:Boolean = Boolean(value.useRadians == true); 
			for (var p:String in value) {
				if (p != "useRadians") {
					initRotation(target, p, target[p], (typeof(value[p]) == "number") ? Number(value[p]) : target[p] + Number(value[p]), useRadians);
				}
			}
			return true;
		}
		
		/** @private **/
		public function initRotation(target:Object, propName:String, start:Number, end:Number, useRadians:Boolean=false):void {
			var cap:Number = useRadians ? Math.PI * 2 : 360;
			var dif:Number = (end - start) % cap;
			if (dif != dif % (cap / 2)) {
				dif = (dif < 0) ? dif + cap : dif - cap;
			}
			addTween(target, propName, start, start + dif, propName);
			this.overwriteProps[this.overwriteProps.length] = propName;
		}	

	}
}