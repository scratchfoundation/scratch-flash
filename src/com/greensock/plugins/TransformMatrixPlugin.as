/**
 * VERSION: 1.02
 * DATE: 2010-10-11
 * ACTIONSCRIPT VERSION: 3.0 
 * UPDATES AND DOCUMENTATION AT: http://www.GreenSock.com
 **/
package com.greensock.plugins {
	import com.greensock.*;
	
	import flash.geom.Matrix;
	import flash.geom.Transform;
/**
 * TransformMatrixPlugin allows you to tween a DisplayObject's transform.matrix values directly 
 * (<code>a, b, c, d, tx, and ty</code>) or use common properties like <code>x, y, scaleX, scaleY, 
 * skewX, skewY, rotation</code> and even <code>shortRotation</code>.
 * To skew without adjusting scale visually, use skewX2 and skewY2 instead of skewX and skewY. 
 * <br /><br />
 * 
 * transformMatrix tween will affect all of the DisplayObject's transform properties, so do not use
 * it in conjunction with regular x/y/scaleX/scaleY/rotation tweens concurrently.<br /><br />
 * 
 * <b>USAGE:</b><br /><br />
 * <code>
 * 		import com.greensock.TweenLite; <br />
 * 		import com.greensock.plugins.~~; <br />
 * 		TweenPlugin.activate([TransformMatrixPlugin]); //activation is permanent in the SWF, so this line only needs to be run once.<br /><br />
 * 
 * 		TweenLite.to(mc, 1, {transformMatrix:{x:50, y:300, scaleX:2, scaleY:2}}); <br /><br />
 * 		
 * 		//-OR-<br /><br />
 * 
 * 		TweenLite.to(mc, 1, {transformMatrix:{tx:50, ty:300, a:2, d:2}}); <br /><br />
 * 
 * </code>
 * 
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 */
	public class TransformMatrixPlugin extends TweenPlugin {
		/** @private **/
		public static const API:Number = 1.0; //If the API/Framework for plugins changes in the future, this number helps determine compatibility
		/** @private **/
		private static const _DEG2RAD:Number = Math.PI / 180;
		
		/** @private **/
		protected var _transform:Transform;
		/** @private **/
		protected var _matrix:Matrix;
		/** @private **/
		protected var _txStart:Number;
		/** @private **/
		protected var _txChange:Number;
		/** @private **/
		protected var _tyStart:Number;
		/** @private **/
		protected var _tyChange:Number;
		/** @private **/
		protected var _aStart:Number;
		/** @private **/
		protected var _aChange:Number;
		/** @private **/
		protected var _bStart:Number;
		/** @private **/
		protected var _bChange:Number;
		/** @private **/
		protected var _cStart:Number;
		/** @private **/
		protected var _cChange:Number;
		/** @private **/
		protected var _dStart:Number;
		/** @private **/
		protected var _dChange:Number;
		/** @private **/
		protected var _angleChange:Number = 0;
		
		/** @private **/
		public function TransformMatrixPlugin() {
			super();
			this.propName = "transformMatrix";
			this.overwriteProps = ["x","y","scaleX","scaleY","rotation","transformMatrix","transformAroundPoint","transformAroundCenter","shortRotation"];
		}
		
		/** @private **/
		override public function onInitTween(target:Object, value:*, tween:TweenLite):Boolean {
			_transform = target.transform as Transform;
			_matrix = _transform.matrix;
			var matrix:Matrix = _matrix.clone();
			_txStart = matrix.tx;
			_tyStart = matrix.ty;
			_aStart = matrix.a;
			_bStart = matrix.b;
			_cStart = matrix.c;
			_dStart = matrix.d;
			
			if ("x" in value) {
				_txChange = (typeof(value.x) == "number") ? value.x - _txStart : Number(value.x);
			} else if ("tx" in value) {
				_txChange = value.tx - _txStart;
			} else {
				_txChange = 0;
			}
			if ("y" in value) {
				_tyChange = (typeof(value.y) == "number") ? value.y - _tyStart : Number(value.y);
			} else if ("ty" in value) {
				_tyChange = value.ty - _tyStart;
			} else {
				_tyChange = 0;
			}
			_aChange = ("a" in value) ? value.a - _aStart : 0;
			_bChange = ("b" in value) ? value.b - _bStart : 0;
			_cChange = ("c" in value) ? value.c - _cStart : 0;
			_dChange = ("d" in value) ? value.d - _dStart : 0;
			
			if (("rotation" in value) || ("shortRotation" in value) || ("scale" in value && !(value is Matrix)) || ("scaleX" in value) || ("scaleY" in value) || ("skewX" in value) || ("skewY" in value) || ("skewX2" in value) || ("skewY2" in value)) {
				var ratioX:Number, ratioY:Number;
				var scaleX:Number = Math.sqrt(matrix.a * matrix.a + matrix.b * matrix.b); //Bugs in the Flex framework prevent DisplayObject.scaleX from working consistently, so we must determine it using the matrix.
				if (matrix.a < 0 && matrix.d > 0) {
					scaleX = -scaleX;
				}
				var scaleY:Number = Math.sqrt(matrix.c * matrix.c + matrix.d * matrix.d); //Bugs in the Flex framework prevent DisplayObject.scaleY from working consistently, so we must determine it using the matrix.
				if (matrix.d < 0 && matrix.a > 0) {
					scaleY = -scaleY;
				}
				var angle:Number = Math.atan2(matrix.b, matrix.a); //Bugs in the Flex framework prevent DisplayObject.rotation from working consistently, so we must determine it using the matrix
				if (matrix.a < 0 && matrix.d >= 0) {
					angle += (angle <= 0) ? Math.PI : -Math.PI;
				}
				var skewX:Number = Math.atan2(-_matrix.c, _matrix.d) - angle;
				
				var finalAngle:Number = angle;
				if ("shortRotation" in value) {
					var dif:Number = ((value.shortRotation * _DEG2RAD) - angle) % (Math.PI * 2);
					if (dif > Math.PI) {
						dif -= Math.PI * 2;
					} else if (dif < -Math.PI) {
						dif += Math.PI * 2;
					}
					finalAngle += dif;
				} else if ("rotation" in value) {
					finalAngle = (typeof(value.rotation) == "number") ? value.rotation * _DEG2RAD : Number(value.rotation) * _DEG2RAD + angle;
				}
				
				var finalSkewX:Number = ("skewX" in value) ? (typeof(value.skewX) == "number") ? Number(value.skewX) * _DEG2RAD : Number(value.skewX) * _DEG2RAD + skewX : 0;
				
				if ("skewY" in value) { //skewY is just a combination of rotation and skewX
					var skewY:Number = (typeof(value.skewY) == "number") ? value.skewY * _DEG2RAD : Number(value.skewY) * _DEG2RAD - skewX;
					finalAngle += skewY + skewX;
					finalSkewX -= skewY;
				}
				
				if (finalAngle != angle) {
					if (("rotation" in value) || ("shortRotation" in value)) {
						_angleChange = finalAngle - angle;
						finalAngle = angle; //to correctly affect the skewX calculations below
					} else {
						matrix.rotate(finalAngle - angle);
					}
				}
				
				if ("scale" in value) {
					ratioX = Number(value.scale) / scaleX;
					ratioY = Number(value.scale) / scaleY;
					if (typeof(value.scale) != "number") { //relative value
						ratioX += 1;
						ratioY += 1;
					}
				} else {
					if ("scaleX" in value) {
						ratioX = Number(value.scaleX) / scaleX;
						if (typeof(value.scaleX) != "number") { //relative value
							ratioX += 1;
						}
					}
					if ("scaleY" in value) {
						ratioY = Number(value.scaleY) / scaleY;
						if (typeof(value.scaleY) != "number") { //relative value
							ratioY += 1;
						}
					}
				}
				
				if (finalSkewX != skewX) {
					matrix.c = -scaleY * Math.sin(finalSkewX + finalAngle);
					matrix.d = scaleY * Math.cos(finalSkewX + finalAngle);
				}
				
				if ("skewX2" in value) {
					if (typeof(value.skewX2) == "number") {
						matrix.c = Math.tan(0 - (value.skewX2 * _DEG2RAD));
					} else {
						matrix.c += Math.tan(0 - (Number(value.skewX2) * _DEG2RAD));
					}
				}
				if ("skewY2" in value) {
					if (typeof(value.skewY2) == "number") {
						matrix.b = Math.tan(value.skewY2 * _DEG2RAD);
					} else {
						matrix.b += Math.tan(Number(value.skewY2) * _DEG2RAD);
					}
				}
				
				if (ratioX || ratioX == 0) { //faster than isNaN()
					matrix.a *= ratioX;
					matrix.b *= ratioX;
				}
				if (ratioY || ratioY == 0) {
					matrix.c *= ratioY;
					matrix.d *= ratioY;
				}
				_aChange = matrix.a - _aStart;
				_bChange = matrix.b - _bStart;
				_cChange = matrix.c - _cStart;
				_dChange = matrix.d - _dStart;
				
			}
			
			return true;
		}
		
		/** @private **/
		override public function set changeFactor(n:Number):void {
			_matrix.a = _aStart + (n * _aChange);
			_matrix.b = _bStart + (n * _bChange);
			_matrix.c = _cStart + (n * _cChange);
			_matrix.d = _dStart + (n * _dChange);
			if (_angleChange) {
				//about 3-4 times faster than _matrix.rotate(_angleChange * n);
				var cos:Number = Math.cos(_angleChange * n);
				var sin:Number = Math.sin(_angleChange * n);
				var a:Number = _matrix.a;
				var c:Number = _matrix.c;
				_matrix.a = a * cos - _matrix.b * sin;
				_matrix.b = a * sin + _matrix.b * cos;
				_matrix.c = c * cos - _matrix.d * sin;
				_matrix.d = c * sin + _matrix.d * cos;
			}
			_matrix.tx = _txStart + (n * _txChange);
			_matrix.ty = _tyStart + (n * _tyChange);
			_transform.matrix = _matrix;
		}

	}
}