/**
 * VERSION: 1.7
 * DATE: 2011-09-15
 * AS3
 * UPDATES AND DOCS AT: http://www.TweenMax.com
 **/
package com.greensock.plugins {
	import com.greensock.*;
	
	import flash.display.*;
	import flash.geom.ColorTransform;
/**
 * Ever wanted to tween ColorTransform properties of a DisplayObject to do advanced effects like overexposing, altering
 * the brightness or setting the percent/amount of tint? Or maybe tween individual ColorTransform 
 * properties like redMultiplier, redOffset, blueMultiplier, blueOffset, etc. ColorTransformPlugin gives you an easy way to 
 * do just that. <br /><br />
 * 
 * <b>PROPERTIES:</b><br />
 * <ul>
 * 		<li><code> tint (or color) : uint</code> - Color of the tint. Use a hex value, like 0xFF0000 for red.</li>
 * 		<li><code> tintAmount : Number</code> - Number between 0 and 1. Works with the "tint" property and indicats how much of an effect the tint should have. 0 makes the tint invisible, 0.5 is halfway tinted, and 1 is completely tinted.</li>
 * 		<li><code> brightness : Number</code> - Number between 0 and 2 where 1 is normal brightness, 0 is completely dark/black, and 2 is completely bright/white</li>
 * 		<li><code> exposure : Number</code> - Number between 0 and 2 where 1 is normal exposure, 0, is completely underexposed, and 2 is completely overexposed. Overexposing an object is different then changing the brightness - it seems to almost bleach the image and looks more dynamic and interesting (subjectively speaking).</li> 
 * 		<li><code> redOffset : Number</code></li>
 * 		<li><code> greenOffset : Number</code></li>
 * 		<li><code> blueOffset : Number</code></li>
 * 		<li><code> alphaOffset : Number</code></li>
 * 		<li><code> redMultiplier : Number</code></li>
 * 		<li><code> greenMultiplier : Number</code></li>
 * 		<li><code> blueMultiplier : Number</code></li>
 * 		<li><code> alphaMultiplier : Number</code> </li>
 * </ul><br /><br />
 * 
 * <b>USAGE:</b><br /><br />
 * <code>
 * 		import com.greensock.TweenLite; <br />
 * 		import com.greensock.plugins.TweenPlugin; <br />
 * 		import com.greensock.plugins.ColorTransformPlugin; <br />
 * 		TweenPlugin.activate([ColorTransformPlugin]); //activation is permanent in the SWF, so this line only needs to be run once.<br /><br />
 * 
 * 		TweenLite.to(mc, 1, {colorTransform:{tint:0xFF0000, tintAmount:0.5}}); <br /><br />
 * </code>
 * 
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 */
	public class ColorTransformPlugin extends TintPlugin {
		/** @private **/
		public static const API:Number = 1.0; //If the API/Framework for plugins changes in the future, this number helps determine compatibility
		
		/** @private **/
		public function ColorTransformPlugin() {
			super();
			this.propName = "colorTransform"; 
		}
		
		/** @private **/
		override public function onInitTween(target:Object, value:*, tween:TweenLite):Boolean {
			var start:ColorTransform, end:ColorTransform = new ColorTransform();
			if (target is DisplayObject) {
				_transform = DisplayObject(target).transform;
				start = _transform.colorTransform;
			} else if (target is ColorTransform) {
				start = target as ColorTransform;
			} else {
				return false;
			}
			end.concat(start);
			for (var p:String in value) {
				if (p == "tint" || p == "color") {
					if (value[p] != null) {
						end.color = int(value[p]);
					}
				} else if (p == "tintAmount" || p == "exposure" || p == "brightness") {
					//handle this later...
				} else {
					end[p] = value[p];
				}
			}
			
			if (!isNaN(value.tintAmount)) {
				var ratio:Number = value.tintAmount / (1 - ((end.redMultiplier + end.greenMultiplier + end.blueMultiplier) / 3));
				end.redOffset *= ratio;
				end.greenOffset *= ratio;
				end.blueOffset *= ratio;
				end.redMultiplier = end.greenMultiplier = end.blueMultiplier = 1 - value.tintAmount;
			} else if (!isNaN(value.exposure)) {
				end.redOffset = end.greenOffset = end.blueOffset = 255 * (value.exposure - 1);
				end.redMultiplier = end.greenMultiplier = end.blueMultiplier = 1;
			} else if (!isNaN(value.brightness)) {
				end.redOffset = end.greenOffset = end.blueOffset = Math.max(0, (value.brightness - 1) * 255);
				end.redMultiplier = end.greenMultiplier = end.blueMultiplier = 1 - Math.abs(value.brightness - 1);
			}
			
			init(start, end);
			
			return true;
		}
		
	}
}