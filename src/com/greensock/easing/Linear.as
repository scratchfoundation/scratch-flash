package com.greensock.easing {
	
	public class Linear {
		public static const power:uint = 0;
		
		public static function easeNone (t:Number, b:Number, c:Number, d:Number):Number {
			return c*t/d + b;
		}
		public static function easeIn (t:Number, b:Number, c:Number, d:Number):Number {
			return c*t/d + b;
		}
		public static function easeOut (t:Number, b:Number, c:Number, d:Number):Number {
			return c*t/d + b;
		}
		public static function easeInOut (t:Number, b:Number, c:Number, d:Number):Number {
			return c*t/d + b;
		}
	}
}