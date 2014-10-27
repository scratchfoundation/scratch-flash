/**
 * VERSION: 0.7
 * DATE: 2011-11-29
 * AS3
 * UPDATES AND DOCS AT: http://www.greensock.com/roughease/
 **/
package com.greensock.easing {
/**
 * Most easing equations give a smooth, gradual transition between the start and end values, but RoughEase provides
 * an easy way to get a rough, jagged effect instead. You can define an ease that it will use as a template (like a
 * general guide - Linear.easeNone is the default) and then it will randomly plot points that wander from that template. 
 * The strength parameter controls how far from the template ease the points are allowed to go (a small number like
 * 0.1 keeps it very close to the template ease whereas a larger number like 2 creates much larger jumps). You can
 * also control the number of points in the ease, making it jerk more or less frequently. And lastly, you can associate
 * a name with each RoughEase instance and retrieve it later like RoughEase.byName("myEaseName"). Since creating 
 * the initial RoughEase is the most processor-intensive part, it's a good idea to reuse instances if/when you can.<br /><br />
 * 
 * <b>EXAMPLE CODE</b><br /><br /><code>
 * import com.greensock.TweenLite;<br />
 * import com.greensock.easing.RoughEase;<br /><br />
 * 
 * TweenLite.from(mc, 3, {alpha:0, ease:RoughEase.create(1, 15)});<br /><br />
 * 
 * //or create an instance directly<br />
 * var rough:RoughEase = new RoughEase(1.5, 30, true, Strong.easeOut, "none", true, "superRoughEase");<br />
 * TweenLite.to(mc, 3, {y:300, ease:rough.ease});<br /><br />
 * 
 * //and later, you can find the ease by name like:<br />
 * TweenLite.to(mc, 3, {y:300, ease:RoughEase.byName("superRoughEase")});
 * </code><br /><br />
 * 
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 */	 
	public class RoughEase {		
		/** @private **/
		private static var _lookup:Object = {}; //keeps track of all named instances so we can find them in byName().
		/** @private **/
		private static var _count:uint = 0;
		
		/** @private **/
		private var _name:String;
		/** @private **/
		private var _first:EasePoint;
		/** @private **/
		private var _last:EasePoint;
		
		/**
		 * Constructor
		 * 
		 * @param strength amount of variance from the templateEase (Linear.easeNone by default) that each random point can be placed. A low number like 0.1 will hug very closely to the templateEase whereas a larger number like 2 will allow the values to wander further away from the templateEase.
		 * @param points quantity of random points to plot in the ease. A larger number will cause more (and quicker) flickering.
		 * @param restrictMaxAndMin If true, the ease will prevent random points from exceeding the end value or dropping below the starting value. For example, if you're tweening the x property from 0 to 100, the RoughEase would force all random points to stay between 0 and 100 if restrictMaxAndMin is true, but if it is false, a x could potentially jump above 100 or below 0 at some point during the tween (it would always end at 100 though).
		 * @param templateEase an easing equation that should be used as a template or guide. Then random points are plotted at a certain distance away from the templateEase (based on the strength parameter). The default is Linear.easeNone.
		 * @param taper to make the strength of the roughness taper towards the end or beginning or both, use "out", "in", or "both" respectively here (default is "none").
		 * @param randomize to randomize the placement of the points, set randomize to true (otherwise the points will zig-zag evenly across the ease)
		 * @param name a name to associate with the ease so that you can use RoughEase.byName() to look it up later. Of course you should always make sure you use a unique name for each ease (if you leave it blank, a name will automatically be generated). 
		 */
		public function RoughEase(strength:Number=1, points:uint=20, restrictMaxAndMin:Boolean=false, templateEase:Function=null, taper:String="none", randomize:Boolean=true, name:String="") {
			if (name == "") {
				_name = "roughEase" + (_count++);
			} else {
				_name = name;
				_lookup[_name] = this; //only store it if a name is defined. This way, unnamed eases can be garbage collected without needing a dispose() call. 
			}
			if (taper == "" || taper == null) {
				taper = "none";
			}
			var a:Array = [];
			var cnt:int = 0;
			strength *= 0.4; 
			var x:Number, y:Number, bump:Number, invX:Number, obj:Object;
			var i:int = points;
			while (--i > -1) {
				x = randomize ? Math.random() : (1 / points) * i;
				y = (templateEase != null) ? templateEase(x, 0, 1, 1) : x;
				if (taper == "none") {
					bump = strength;
				} else if (taper == "out") {
					invX = 1 - x;
					bump = invX * invX * strength;
				} else if (taper == "in") {
					bump = x * x * strength;
				} else if (x < 0.5) { 	//"both" (start)
					invX = x * 2;
					bump = invX * invX * 0.5 * strength;
				} else {				//"both" (end)
					invX = (1 - x) * 2;
					bump = invX * invX * 0.5 * strength;
				}
				if (randomize) {
					y += (Math.random() * bump) - (bump * 0.5);
				} else if (i % 2) {
					y += bump * 0.5;
				} else {
					y -= bump * 0.5;
				}
				if (restrictMaxAndMin) {
					if (y > 1) {
						y = 1;
					} else if (y < 0) {
						y = 0;
					}
				}
				a[cnt++] = {x:x, y:y};
			}
			a.sortOn("x", Array.NUMERIC);
			
			_first = _last = new EasePoint(1, 1, null);
			
			i = points;
			while (--i > -1) {
				obj = a[i];
				_first = new EasePoint(obj.x, obj.y, _first);
			}
			
			_first = new EasePoint(0, 0, (_first.time != 0) ? _first : _first.next);
			
		}
		
		/**
		 * This static function provides a quick way to create a RoughEase and immediately reference its ease function 
		 * in a tween, like:<br /><br /><code>
		 * 
		 * TweenLite.from(mc, 2, {alpha:0, ease:RoughEase.create(1.5, 15)});<br />
		 * </code>
		 * 
		 * @param strength amount of variance from the templateEase (Linear.easeNone by default) that each random point can be placed. A low number like 0.1 will hug very closely to the templateEase whereas a larger number like 2 will allow the values to wander further away from the templateEase.
		 * @param points quantity of random points to plot in the ease. A larger number will cause more (and quicker) flickering.
		 * @param restrictMaxAndMin If true, the ease will prevent random points from exceeding the end value or dropping below the starting value. For example, if you're tweening the x property from 0 to 100, the RoughEase would force all random points to stay between 0 and 100 if restrictMaxAndMin is true, but if it is false, a x could potentially jump above 100 or below 0 at some point during the tween (it would always end at 100 though).
		 * @param templateEase an easing equation that should be used as a template or guide. Then random points are plotted at a certain distance away from the templateEase (based on the strength parameter). The default is Linear.easeNone.
		 * @param taper to make the strength of the roughness taper towards the end or beginning or both, use "out", "in", or "both" respectively here (default is "none").
		 * @param randomize to randomize the placement of the points, set randomize to true (otherwise the points will zig-zag evenly across the ease)
		 * @param name a name to associate with the ease so that you can use RoughEase.byName() to look it up later. Of course you should always make sure you use a unique name for each ease (if you leave it blank, a name will automatically be generated). 
		 * @return easing function
		 */
		public static function create(strength:Number=1, points:uint=20, restrictMaxAndMin:Boolean=false, templateEase:Function=null, taper:String="none", randomize:Boolean=true, name:String=""):Function {
			var re:RoughEase = new RoughEase(strength, points, restrictMaxAndMin, templateEase, taper, randomize, name);
			return re.ease;
		}
		
		/**
		 * Provides a quick way to look up a RoughEase by its name.
		 * 
		 * @param name the name of the RoughEase
		 * @return easing function from the RoughEase associated with the name
		 */
		public static function byName(name:String):Function {
			return _lookup[name].ease;
		}
		
		/**
		 * Easing function that interpolates the numbers
		 * 
		 * @param t time
		 * @param b start
		 * @param c change
		 * @param d duration
		 * @return Result of the ease
		 */
		public function ease(t:Number, b:Number, c:Number, d:Number):Number {
			var time:Number = t / d;
			var p:EasePoint;
			if (time < 0.5) {
				p = _first;
				while (p.time <= time) {
					p = p.next;
				}
				p = p.prev;
			} else {
				p = _last;
				while (p.time >= time) {
					p = p.prev;
				}
			}
			
			return b + (p.value + ((time - p.time) / p.gap) * p.change) * c;
		}
		
		/** Disposes the RoughEase so that it is no longer stored for easy lookups by name with <code>byName()</code>, releasing it for garbage collection. **/
		public function dispose():void {
			delete _lookup[_name];
		}
		
		/** name of the RoughEase instance **/
		public function get name():String {
			return _name;
		}
		
		public function set name(value:String):void {
			delete _lookup[_name];
			_name = value;
			_lookup[_name] = this;
		}

	}
}

internal class EasePoint {
	public var time:Number;
	public var gap:Number;
	public var value:Number;
	public var change:Number;
	public var next:EasePoint;
	public var prev:EasePoint;
	
	public function EasePoint(time:Number, value:Number, next:EasePoint) {
		this.time = time;
		this.value = value;
		if (next) {
			this.next = next;
			next.prev = this;
			this.change = next.value - value;
			this.gap = next.time - time;
		}
	}
}