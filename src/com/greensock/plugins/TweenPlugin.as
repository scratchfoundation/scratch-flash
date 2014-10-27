/**
 * VERSION: 1.4
 * DATE: 2010-12-16
 * AS3
 * UPDATES AND DOCS AT: http://www.TweenMax.com
 **/
package com.greensock.plugins {
	import com.greensock.*;
	import com.greensock.core.*;
/**
 * TweenPlugin is the base class for all TweenLite/TweenMax plugins. <br /><br />
 * 	
 * <b>USAGE:</b><br />
 * 
 * 	To create your own plugin, extend TweenPlugin and override whichever methods you need. Typically,
 * 	you only need to override onInitTween() and the changeFactor setter. I'd recommend looking at a
 *  simple plugin like FramePlugin or ScalePlugin and using it as a template of sorts. There are a few 
 *  key concepts to keep in mind:
 * 	<ol>
 * 		<li> In the constructor, set this.propName to whatever special property you want your plugin to handle. </li>
 * 		
 * 		<li> When a tween that uses your plugin initializes its tween values (normally when it starts), a new instance 
 * 		  of your plugin will be created and the onInitTween() method will be called. That's where you'll want to 
 * 		  store any initial values and prepare for the tween. onInitTween() should return a Boolean value that 
 * 		  essentially indicates whether or not the plugin initted successfully. If you return false, TweenLite/Max 
 * 		  will just use a normal tween for the value, ignoring the plugin for that particular tween.</li>
 * 		  
 * 		<li> The changeFactor setter will be updated on every frame during the course of the tween with a multiplier
 * 		  that describes the amount of change based on how far along the tween is and the ease applied. It will be 
 * 		  zero at the beginning of the tween and 1 at the end, but inbetween it could be any value based on the 
 * 		  ease applied (for example, an Elastic.easeOut tween would cause the value to shoot past 1 and back again before 
 * 		  the end of the tween). So if the tween uses the Linear.easeNone easing equation, when it's halfway finished,
 * 		  the changeFactor will be 0.5. </li>
 * 		  
 * 		<li> The overwriteProps is an Array that should contain the properties that your plugin should overwrite
 * 		  when OverwriteManager's mode is AUTO and a tween of the same object is created. For example, the 
 * 		  autoAlpha plugin controls the "visible" and "alpha" properties of an object, so if another tween 
 * 		  is created that controls the alpha of the target object, your plugin's killProps() will be called 
 * 		  which should handle killing the "alpha" part of the tween. It is your responsibility to populate
 * 		  (and depopulate) the overwriteProps Array. Failure to do so properly can cause odd overwriting behavior.</li>
 * 		  
 * 		<li> Note that there's a "round" property that indicates whether or not values in your plugin should be
 * 		  rounded to the nearest integer (compatible with TweenMax only). If you use the _tweens Array, populating
 * 		  it through the addTween() method, rounding will happen automatically (if necessary) in the 
 * 		  updateTweens() method, but if you don't use addTween() and prefer to manually calculate tween values
 * 		  in your changeFactor setter, just remember to accommodate the "round" flag if it makes sense in your plugin.</li>
 * 		  
 * 		<li> If you need to run a block of code when the tween has finished, point the onComplete property to a
 * 		  method you created inside your plugin.</li>
 * 
 * 		<li> If you need to run a function when the tween gets disabled, point the onDisable property to a
 * 		  method you created inside your plugin. Same for onEnable if you need to run code when a tween is
 * 		  enabled. (A tween gets disabled when it gets overwritten or finishes or when its timeline gets disabled)</li>
 * 		
 * 		<li> Please use the same naming convention as the rest of the plugins, like MySpecialPropertyNamePlugin.</li>
 * 		
 * 		<li> IMPORTANT: The plugin framework is brand new, so there is a chance that it will change slightly over time and 
 * 		  you may need to adjust your custom plugins if the framework changes. I'll try to minimize the changes,
 * 		  but I'd highly recommend getting a membership to Club GreenSock to make sure you get update notifications.
 * 		  See http://blog.greensock.com/club/ for details.</li>
 * </ol>
 * 
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 */
	public class TweenPlugin {
		public static const VERSION:Number = 1.4;
		/** @private If the API/Framework for plugins changes in the future, this number helps determine compatibility **/
		public static const API:Number = 1.0; 
		
		/** @private Name of the special property that the plugin should intercept/handle **/
		public var propName:String;
		
		/**
		 * @private 
		 * Array containing the names of the properties that should be overwritten in OverwriteManager's 
		 * AUTO mode. Typically the only value in this Array is the propName, but there are cases when it may 
		 * be different. For example, a bezier tween's propName is "bezier" but it can manage many different properties 
		 * like x, y, etc. depending on what's passed in to the tween.
		 */
		public var overwriteProps:Array;
		
		/** @private If the values should be rounded to the nearest integer, set this to true. **/
		public var round:Boolean;
		
		/** @private Priority level in the render queue **/
		public var priority:int = 0;
		
		/** @private if the plugin actively changes properties of the target when it gets disabled (like the MotionBlurPlugin swaps out a temporary BitmapData for the target), activeDisplay should be true. Otherwise it should be false (it is much more common for it to be false). This is important because if it gets overwritten by another tween, that tween may init() with stale values - if activeDisable is true, it will force the new tween to re-init() when this plugin is overwritten (if ever). **/
		public var activeDisable:Boolean;
		
		/** @private Called when the tween has finished initting all of the properties in the vars object (useful for things like roundProps which must wait for everything else to init). IMPORTANT: in order for the onInitAllProps to get called properly, you MUST set the TweenPlugin's "priority" property to a non-zero value (this is for optimization and file size purposes) **/
		public var onInitAllProps:Function;
		
		/** @private Called when the tween is complete. **/
		public var onComplete:Function;
		
		/** @private Called when the tween gets re-enabled after having been initted. Like if it finishes and then gets restarted later. **/
		public var onEnable:Function;
		
		/** @private Called either when the plugin gets overwritten or when its parent tween gets killed/disabled. **/
		public var onDisable:Function;
		
		/** @private **/
		protected var _tweens:Array = [];
		/** @private **/
		protected var _changeFactor:Number = 0;
		
		
		public function TweenPlugin() {
			//constructor
		}
		
		/**
		 * @private 
		 * Gets called when any tween of the special property begins. Store any initial values
		 * and/or variables that will be used in the "changeFactor" setter when this method runs. 
		 * 
		 * @param target target object of the TweenLite instance using this plugin
		 * @param value The value that is passed in through the special property in the tween. 
		 * @param tween The TweenLite or TweenMax instance using this plugin.
		 * @return If the initialization failed, it returns false. Otherwise true. It may fail if, for example, the plugin requires that the target be a DisplayObject or has some other unmet criteria in which case the plugin is skipped and a normal property tween is used inside TweenLite
		 */
		public function onInitTween(target:Object, value:*, tween:TweenLite):Boolean {
			addTween(target, this.propName, target[this.propName], value, this.propName);
			return true;
		}
		
		/**
		 * @private 
		 * Offers a simple way to add tweening values to the plugin. You don't need to use this,
		 * but it is convenient because the tweens get updated in the updateTweens() method which also 
		 * handles rounding. killProps() nicely integrates with most tweens added via addTween() as well,
		 * but if you prefer to handle this manually in your plugin, you're welcome to.
		 *  
		 * @param object target object whose property you'd like to tween. (i.e. myClip)
		 * @param propName the property name that should be tweened. (i.e. "x")
		 * @param start starting value
		 * @param end end value (can be either numeric or a string value. If it's a string, it will be interpreted as relative to the starting value)
		 * @param overwriteProp name of the property that should be associated with the tween for overwriting purposes. Normally, it's the same as propName, but not always. For example, you may tween the "changeFactor" property of a VisiblePlugin, but the property that it's actually controling in the end is "visible", so if a new overlapping tween of the target object is created that affects its "visible" property, this allows the plugin to kill the appropriate tween(s) when killProps() is called. 
		 */
		protected function addTween(object:Object, propName:String, start:Number, end:*, overwriteProp:String=null):void {
			if (end != null) {
				var change:Number = (typeof(end) == "number") ? Number(end) - start : Number(end);
				if (change != 0) { //don't tween values that aren't changing! It's a waste of CPU cycles
					_tweens[_tweens.length] = new PropTween(object, propName, start, change, overwriteProp || propName, false);
				}
			}
		}
		
		/**
		 * @private 
		 * Updates all the tweens in the _tweens Array. 
		 *  
		 * @param changeFactor Multiplier describing the amount of change that should be applied. It will be zero at the beginning of the tween and 1 at the end, but inbetween it could be any value based on the ease applied (for example, an Elastic tween would cause the value to shoot past 1 and back again before the end of the tween) 
		 */
		protected function updateTweens(changeFactor:Number):void {
			var i:int = _tweens.length, pt:PropTween;
			if (this.round) {
				var val:Number;
				while (--i > -1) {
					pt = _tweens[i];
					val = pt.start + (pt.change * changeFactor);
					if (val > 0) {
						pt.target[pt.property] = (val + 0.5) >> 0; //4 times as fast as Math.round()
					} else {
						pt.target[pt.property] = (val - 0.5) >> 0; //4 times as fast as Math.round()
					}
				}
				
			} else {
				while (--i > -1) {
					pt = _tweens[i];
					pt.target[pt.property] = pt.start + (pt.change * changeFactor);
				}
			}
		}
		
		/**
		 * @private 
		 * In most cases, your custom updating code should go here. The changeFactor value describes the amount 
		 * of change based on how far along the tween is and the ease applied. It will be zero at the beginning
		 * of the tween and 1 at the end, but inbetween it could be any value based on the ease applied (for example, 
		 * an Elastic tween would cause the value to shoot past 1 and back again before the end of the tween) 
		 * This value gets updated on every frame during the course of the tween.
		 * 
		 * @param n Multiplier describing the amount of change that should be applied. It will be zero at the beginning of the tween and 1 at the end, but inbetween it could be any value based on the ease applied (for example, an Elastic tween would cause the value to shoot past 1 and back again before the end of the tween) 
		 */
		public function get changeFactor():Number {
			return _changeFactor;
		}
		public function set changeFactor(n:Number):void {
			updateTweens(n);
			_changeFactor = n;
		}
		
		/**
		 * @private 
		 * Gets called on plugins that have multiple overwritable properties by OverwriteManager when 
		 * in AUTO mode. Basically, it instructs the plugin to overwrite certain properties. For example,
		 * if a bezier tween is affecting x, y, and width, and then a new tween is created while the 
		 * bezier tween is in progress, and the new tween affects the "x" property, we need a way
		 * to kill just the "x" part of the bezier tween. 
		 * 
		 * @param lookup An object containing properties that should be overwritten. We don't pass in an Array because looking up properties on the object is usually faster because it gives us random access. So to overwrite the "x" and "y" properties, a {x:true, y:true} object would be passed in. 
		 */
		public function killProps(lookup:Object):void {
			var i:int = this.overwriteProps.length;
			while (--i > -1) {
				if (this.overwriteProps[i] in lookup) {
					this.overwriteProps.splice(i, 1);
				}
			}
			i = _tweens.length;
			while (--i > -1) {
				if (PropTween(_tweens[i]).name in lookup) {
					_tweens.splice(i, 1);
				}
			}
		}
		
		/**
		 * @private
		 * This method is called inside TweenLite after significant events occur, like when a tween
		 * has finished initializing, when it has completed, and when its "enabled" property changes.
		 * For example, the MotionBlurPlugin must run after normal x/y/alpha PropTweens are rendered,
		 * so the "init" event reorders the PropTweens linked list in order of priority. Some plugins
		 * need to do things when a tween completes or when it gets disabled. Again, this 
		 * method is only for internal use inside TweenLite. It is separated into
		 * this static method in order to minimize file size inside TweenLite.
		 * 
		 * @param type The type of event "onInitAllProps", "onComplete", "onEnable", or "onDisable"
		 * @param tween The TweenLite/Max instance to which the event pertains
		 * @return A Boolean value indicating whether or not properties of the tween's target may have changed as a result of the event
		 */
		private static function onTweenEvent(type:String, tween:TweenLite):Boolean {
			var pt:PropTween = tween.cachedPT1, changed:Boolean;
			if (type == "onInitAllProps") {
				//sorts the PropTween linked list in order of priority because some plugins need to render earlier/later than others, like MotionBlurPlugin applies its effects after all x/y/alpha tweens have rendered on each frame.
				var tweens:Array = [];
				var i:int = 0;
				while (pt) {
					tweens[i++] = pt;
					pt = pt.nextNode;
				}
				tweens.sortOn("priority", Array.NUMERIC | Array.DESCENDING);
				while (--i > -1) {
					PropTween(tweens[i]).nextNode = tweens[i + 1];
					PropTween(tweens[i]).prevNode = tweens[i - 1];
				}
				pt = tween.cachedPT1 = tweens[0];
			} 
			while (pt) {
				if (pt.isPlugin && pt.target[type]) {
					if (pt.target.activeDisable) {
						changed = true;
					}
					pt.target[type]();
				}
				pt = pt.nextNode;
			}
			return changed;
		}
		
		/**
		 * @private 
		 * Handles integrating the plugin into the GreenSock tweening platform. 
		 * 
		 * @param plugin An Array of Plugin classes (that all extend TweenPlugin) to be activated. For example, TweenPlugin.activate([FrameLabelPlugin, ShortRotationPlugin, TintPlugin]);
		 */
		public static function activate(plugins:Array):Boolean {
			TweenLite.onPluginEvent = TweenPlugin.onTweenEvent;
			var i:int = plugins.length, instance:Object;
			while (i--) {
				if (plugins[i].hasOwnProperty("API")) {
					instance = new (plugins[i] as Class)();
					TweenLite.plugins[instance.propName] = plugins[i];
				}
			}
			return true;
		}
		
	}
}