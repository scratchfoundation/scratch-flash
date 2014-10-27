/**
 * VERSION: 2.0
 * DATE: 8/18/2009
 * ACTIONSCRIPT VERSION: 3.0 
 * UPDATES AND DOCUMENTATION AT: http://www.TweenMax.com
 **/
package com.greensock.plugins {
	import com.greensock.*;
	
	import flash.filters.ColorMatrixFilter;
/**
 * ColorMatrixFilter tweening offers an easy way to tween a DisplayObject's saturation, hue, contrast,
 * brightness, and colorization. The following properties are available (you only need to define the ones you want to tween):
 * <ul>
 * 		<li><code> colorize : uint </code> (colorizing a DisplayObject makes it look as though you're seeing it through a colored piece of glass whereas tinting it makes every pixel exactly that color. You can control the amount of colorization using the "amount" value where 1 is full strength, 0.5 is half-strength, and 0 has no colorization effect.)</li>
 * 		<li><code> amount : Number [1] </code> (only used in conjunction with "colorize")</li>
 * 		<li><code> contrast : Number </code> (1 is normal contrast, 0 has no contrast, and 2 is double the normal contrast, etc.)</li>
 * 		<li><code> saturation : Number </code> (1 is normal saturation, 0 makes the DisplayObject look black and white, and 2 would be double the normal saturation)</li>
 * 		<li><code> hue : Number </code> (changes the hue of every pixel. Think of it as degrees, so 180 would be rotating the hue to be exactly opposite as normal, 360 would be the same as 0, etc.)</li>
 * 		<li><code> brightness : Number </code> (1 is normal brightness, 0 is much darker than normal, and 2 is twice the normal brightness, etc.)</li>
 * 		<li><code> threshold : Number </code> (number from 0 to 255 that controls the threshold of where the pixels turn white or black)</li>
 * 		<li><code> matrix : Array </code> (If you already have a matrix from a ColorMatrixFilter that you want to tween to, pass it in with the "matrix" property. This makes it possible to match effects created in the Flash IDE.)</li>
 * 		<li><code> index : Number </code> (only necessary if you already have a filter applied and you want to target it with the tween.)</li>
 * 		<li><code> addFilter : Boolean [false] </code></li>
 * 		<li><code> remove : Boolean [false] </code> (Set remove to true if you want the filter to be removed when the tween completes.)</li>
 * </ul>
 * HINT: If you'd like to match the ColorMatrixFilter values you created in the Flash IDE on a particular object, you can get its matrix like this:<br /><br /><code>
 * 
 * 	import flash.display.DisplayObject; <br />
 * 	import flash.filters.ColorMatrixFilter; <br /><br />
 * 	
 * 	function getColorMatrix(mc:DisplayObject):Array { <br />
 * 	   var f:Array = mc.filters, i:uint; <br />
 * 	   for (i = 0; i &lt; f.length; i++) { <br />
 * 	      if (f[i] is ColorMatrixFilter) { <br />
 * 	         return f[i].matrix; <br />
 * 	      } <br />
 * 	   } <br />
 * 	   return null; <br />
 * 	} <br /><br />
 * 	 
 * 	var myOriginalMatrix:Array = getColorMatrix(my_mc); //store it so you can tween back to it anytime like TweenMax.to(my_mc, 1, {colorMatrixFilter:{matrix:myOriginalMatrix}});
 * </code>
 * <br /><br />
 * 
 * <b>USAGE:</b><br /><br />
 * <code>
 * 		import com.greensock.TweenLite; <br />
 * 		import com.greensock.plugins.TweenPlugin; <br />
 * 		import com.greensock.plugins.ColorMatrixFilterPlugin; <br />
 * 		TweenPlugin.activate([ColorMatrixFilterPlugin]); //activation is permanent in the SWF, so this line only needs to be run once.<br /><br />
 * 
 * 		TweenLite.to(mc, 1, {colorMatrixFilter:{colorize:0xFF0000}}); <br /><br />
 * </code>
 * 
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 */
	public class ColorMatrixFilterPlugin extends FilterPlugin {
		/** @private **/
		public static const API:Number = 1.0; //If the API/Framework for plugins changes in the future, this number helps determine compatibility
		/** @private **/
		private static var _propNames:Array = [];
		
		/** @private **/
		protected static var _idMatrix:Array = [1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0];
		/** @private **/
		protected static var _lumR:Number = 0.212671; //Red constant - used for a few color matrix filter functions
		/** @private **/
		protected static var _lumG:Number = 0.715160; //Green constant - used for a few color matrix filter functions
		/** @private **/
		protected static var _lumB:Number = 0.072169; //Blue constant - used for a few color matrix filter functions
		
		/** @private **/
		protected var _matrix:Array;
		/** @private **/
		protected var _matrixTween:EndArrayPlugin;
		
		/** @private **/
		public function ColorMatrixFilterPlugin() {
			super();
			this.propName = "colorMatrixFilter";
			this.overwriteProps = ["colorMatrixFilter"];
		}
		
		/** @private **/
		override public function onInitTween(target:Object, value:*, tween:TweenLite):Boolean {
			_target = target;
			_type = ColorMatrixFilter;
			var cmf:Object = value;
			initFilter({remove:value.remove, index:value.index, addFilter:value.addFilter}, new ColorMatrixFilter(_idMatrix.slice()), _propNames);
			_matrix = ColorMatrixFilter(_filter).matrix;
			var endMatrix:Array = [];
			if (cmf.matrix != null && (cmf.matrix is Array)) {
				endMatrix = cmf.matrix;
			} else {
				if (cmf.relative == true) {
					endMatrix = _matrix.slice();
				} else {
					endMatrix = _idMatrix.slice();
				}
				endMatrix = setBrightness(endMatrix, cmf.brightness);
				endMatrix = setContrast(endMatrix, cmf.contrast);
				endMatrix = setHue(endMatrix, cmf.hue);
				endMatrix = setSaturation(endMatrix, cmf.saturation);
				endMatrix = setThreshold(endMatrix, cmf.threshold);
				if (!isNaN(cmf.colorize)) {
					endMatrix = colorize(endMatrix, cmf.colorize, cmf.amount);
				}
			}
			_matrixTween = new EndArrayPlugin();
			_matrixTween.init(_matrix, endMatrix);
			return true;
		}
		
		/** @private **/
		override public function set changeFactor(n:Number):void {
			_matrixTween.changeFactor = n;
			ColorMatrixFilter(_filter).matrix = _matrix;
			super.changeFactor = n;
		}
		
		
//---- MATRIX OPERATIONS --------------------------------------------------------------------------------
		
		/** @private **/
		public static function colorize(m:Array, color:Number, amount:Number = 1):Array {
			if (isNaN(color)) {
				return m;
			} else if (isNaN(amount)) {
				amount = 1;
			}
			var r:Number = ((color >> 16) & 0xff) / 255;
			var g:Number = ((color >> 8)  & 0xff) / 255;
			var b:Number = (color         & 0xff) / 255;
			var inv:Number = 1 - amount;
			var temp:Array =  [inv + amount * r * _lumR, amount * r * _lumG,       amount * r * _lumB,       0, 0,
							  amount * g * _lumR,        inv + amount * g * _lumG, amount * g * _lumB,       0, 0,
							  amount * b * _lumR,        amount * b * _lumG,       inv + amount * b * _lumB, 0, 0,
							  0, 				          0, 					     0, 					    1, 0];		
			return applyMatrix(temp, m);
		}
		
		/** @private **/
		public static function setThreshold(m:Array, n:Number):Array {
			if (isNaN(n)) {
				return m;
			}
			var temp:Array = [_lumR * 256, _lumG * 256, _lumB * 256, 0,  -256 * n, 
						_lumR * 256, _lumG * 256, _lumB * 256, 0,  -256 * n, 
						_lumR * 256, _lumG * 256, _lumB * 256, 0,  -256 * n, 
						0,           0,           0,           1,  0]; 
			return applyMatrix(temp, m);
		}
		
		/** @private **/
		public static function setHue(m:Array, n:Number):Array {
			if (isNaN(n)) {
				return m;
			}
			n *= Math.PI / 180;
			var c:Number = Math.cos(n);
			var s:Number = Math.sin(n);
			var temp:Array = [(_lumR + (c * (1 - _lumR))) + (s * (-_lumR)), (_lumG + (c * (-_lumG))) + (s * (-_lumG)), (_lumB + (c * (-_lumB))) + (s * (1 - _lumB)), 0, 0, (_lumR + (c * (-_lumR))) + (s * 0.143), (_lumG + (c * (1 - _lumG))) + (s * 0.14), (_lumB + (c * (-_lumB))) + (s * -0.283), 0, 0, (_lumR + (c * (-_lumR))) + (s * (-(1 - _lumR))), (_lumG + (c * (-_lumG))) + (s * _lumG), (_lumB + (c * (1 - _lumB))) + (s * _lumB), 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1];
			return applyMatrix(temp, m);
		}
		
		/** @private **/
		public static function setBrightness(m:Array, n:Number):Array {
			if (isNaN(n)) {
				return m;
			}
			n = (n * 100) - 100;
			return applyMatrix([1,0,0,0,n,
								0,1,0,0,n,
								0,0,1,0,n,
								0,0,0,1,0,
								0,0,0,0,1], m);
		}
		
		/** @private **/
		public static function setSaturation(m:Array, n:Number):Array {
			if (isNaN(n)) {
				return m;
			}
			var inv:Number = 1 - n;
			var r:Number = inv * _lumR;
			var g:Number = inv * _lumG;
			var b:Number = inv * _lumB;
			var temp:Array = [r + n, g     , b     , 0, 0,
							  r     , g + n, b     , 0, 0,
							  r     , g     , b + n, 0, 0,
							  0     , 0     , 0     , 1, 0];
			return applyMatrix(temp, m);
		}
		
		/** @private **/
		public static function setContrast(m:Array, n:Number):Array {
			if (isNaN(n)) {
				return m;
			}
			n += 0.01;
			var temp:Array =  [n,0,0,0,128 * (1 - n),
							   0,n,0,0,128 * (1 - n),
							   0,0,n,0,128 * (1 - n),
							   0,0,0,1,0];
			return applyMatrix(temp, m);
		}
		
		/** @private **/
		public static function applyMatrix(m:Array, m2:Array):Array {
			if (!(m is Array) || !(m2 is Array)) {
				return m2;
			}
			var temp:Array = [], i:int = 0, z:int = 0, y:int, x:int;
			for (y = 0; y < 4; y += 1) {
				for (x = 0; x < 5; x += 1) {
					if (x == 4) {
						z = m[i + 4];
					} else {
						z = 0;
					}
					temp[i + x] = m[i]   * m2[x]      + 
								  m[i+1] * m2[x + 5]  + 
								  m[i+2] * m2[x + 10] + 
								  m[i+3] * m2[x + 15] +
								  z;
				}
				i += 5;
			}
			return temp;
		}
		
	}
}