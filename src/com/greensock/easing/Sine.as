package com.greensock.easing {
	public class Sine {
		private static const _HALF_PI:Number = Math.PI * 0.5;
		
		public static function easeIn (t:Number, b:Number, c:Number, d:Number):Number {
			return -c * Math.cos(t/d * _HALF_PI) + c + b;
		}
		public static function easeOut (t:Number, b:Number, c:Number, d:Number):Number {
			return c * Math.sin(t/d * _HALF_PI) + b;
		}
		public static function easeInOut (t:Number, b:Number, c:Number, d:Number):Number {
			return -c*0.5 * (Math.cos(Math.PI*t/d) - 1) + b;
		}
	}
}