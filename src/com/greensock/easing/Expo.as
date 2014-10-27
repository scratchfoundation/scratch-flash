package com.greensock.easing {
	public class Expo {
		public static function easeIn(t:Number, b:Number, c:Number, d:Number):Number {
			return (t==0) ? b : c * Math.pow(2, 10 * (t/d - 1)) + b - c * 0.001;
		}
		public static function easeOut(t:Number, b:Number, c:Number, d:Number):Number {
			return (t==d) ? b+c : c * (-Math.pow(2, -10 * t/d) + 1) + b;
		}
		public static function easeInOut(t:Number, b:Number, c:Number, d:Number):Number {
			if (t==0) return b;
			if (t==d) return b+c;
			if ((t/=d*0.5) < 1) return c*0.5 * Math.pow(2, 10 * (t - 1)) + b;
			return c*0.5 * (-Math.pow(2, -10 * --t) + 2) + b;
		}
	}
}