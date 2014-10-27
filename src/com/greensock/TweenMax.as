/**
 * VERSION: 11.698
 * DATE: 2012-02-23
 * AS3 (AS2 version is also available)
 * UPDATES AND DOCS AT: http://www.greensock.com 
 **/
package com.greensock {
	import com.greensock.core.*;
	import com.greensock.events.TweenEvent;
	import com.greensock.plugins.*;
	
	import flash.display.*;
	import flash.events.*;
	import flash.utils.*;
/**
 * 	TweenMax extends the extremely lightweight, fast TweenLite engine, adding many useful features
 * 	like timeScale, event dispatching, updateTo(), yoyo, repeat, repeatDelay, rounding, and more. It also 
 * 	activates many extra plugins by default, making it extremely full-featured. Since TweenMax extends 
 * 	TweenLite, it can do ANYTHING TweenLite can do plus much more. The syntax is identical. With plenty 
 *  of other tweening engines to choose from, here's why you might want to consider TweenMax: 
 * 
 * <ul>
 * 		<li><b> SPEED </b>- TweenMax has been highly optimized for maximum performance. See some speed comparisons yourself at 
 * 			 <a href="http://www.greensock.com/tweening-speed-test/">http://www.greensock.com/tweening-speed-test/</a></li>
 * 
 * 	    <li><b> Feature set </b>- In addition to tweening ANY numeric property of ANY object, TweenMax can tween filters, 
 * 		  	hex colors, volume, tint, frames, saturation, contrast, hue, colorization, brightness, and even do 
 * 		  	bezier tweening, orientToBezier, round values, jump to any point in the tween with the <code>currentTime</code> 
 * 			or <code>currentProgress</code> property, automatically rotate in the shortest direction, plus LOTS more. 
 * 		 	Overwrite management is an important consideration for a tweening engine as well which is another area 
 * 		  	where the GreenSock Tweening Platform shines. You have options for AUTO overwriting or you can manually 
 * 		  	define how each tween will handle overlapping tweens of the same object.</li>
 * 		  
 * 		<li><b> Expandability </b>- With its plugin architecture, you can activate as many (or as few) features as your 
 * 		  	 project requires. Write your own plugin to handle particular special properties in custom ways. Minimize bloat, and
 * 		  	 maximize performance.</li>
 * 		  
 * 		<li><b> Sequencing, grouping, and management features </b>- TimelineLite and TimelineMax make it surprisingly 
 * 			 simple to create complex sequences or groups of tweens that you can control as a whole. play(), pause(), restart(), 
 * 			 or reverse(). You can even tween a timeline's <code>currentTime</code> or <code>currentProgress</code> property 
 * 			 to fastforward or rewind the entire timeline. Add labels, gotoAndPlay(), change the timeline's timeScale, nest 
 * 			 timelines within timelines, and lots more.</li>
 * 		  
 * 		<li><b> Ease of use </b>- Designers and Developers alike rave about how intuitive the platform is.</li>
 * 		
 * 		<li><b> Updates </b>- Frequent updates and feature additions make the GreenSock Tweening Platform reliable and robust.</li>
 * 		
 * 		<li><b> AS2 and AS3 </b>- Most other engines are only developed for AS2 or AS3 but not both.</li>
 * 	</ul>
 * 	         			
 * <b>SPECIAL PROPERTIES:</b><br /><br />
 * The following special properties can be defined in the <code>vars</code> parameter which can 
 * be either a generic Object or a <code><a href="data/TweenMaxVars.html">TweenMaxVars</a></code> instance:
 *  <ul>
 * 	 <li><b> delay : Number</b>				Amount of delay in seconds (or frames for frames-based tweens) before the tween should begin.</li>
 * 	
 * 	<li><b> useFrames : Boolean</b>			If useFrames is set to true, the tweens's timing mode will be based on frames. 
 * 											Otherwise, it will be based on seconds/time. NOTE: a tween's timing mode is 
 * 											always determined by its parent timeline. </li>
 * 	
 * 	<li><b> ease : Function</b>				Use any standard easing equation to control the rate of change. For example, 
 * 											Elastic.easeOut. The Default is Quad.easeOut.</li>
 * 	
 * 	<li><b> easeParams : Array</b>			An Array of extra parameters to feed the easing equation (beyond the standard first 4). 
 * 											This can be useful when using an ease like Elastic and want to control extra parameters 
 * 											like the amplitude and period.	Most easing equations, however, don't require extra parameters 
 * 											so you won't need to pass in any easeParams.</li>
 * 	
 * 	<li><b> onInit : Function</b>			A function that should be called just before the tween inits (renders for the first time).
 * 											Since onInit runs before the start/end values are recorded internally, it is a good place to run
 * 											code that affects the target's initial position or other tween-related properties. onStart, by
 * 											contrast, runs AFTER the tween inits and the start/end values are recorded internally. onStart
 * 											is called every time the tween begins which can happen more than once if the tween is restarted
 * 											multiple times.</li>
 * 	
 *  <li><b> onInitParams : Array</b>		An Array of parameters to pass the onInit function.</li>	
 * 
 *  <li><b> onStart : Function</b>			A function that should be called when the tween begins (when its currentTime is at 0 and 
 * 											changes to some other value which can happen more than once if the tween is restarted multiple times).</li>
 * 	
 * 	<li><b> onStartParams : Array</b>		An Array of parameters to pass the onStart function.</li>
 * 	
 * 	<li><b> onUpdate : Function</b>			A function that should be called every time the tween's time/position is updated 
 * 											(on every frame while the timeline is active)</li>
 * 	
 * 	<li><b> onUpdateParams : Array</b>		An Array of parameters to pass the onUpdate function</li>
 *  
 * 	<li><b> onComplete : Function</b>		A function that should be called when the tween has finished </li>
 * 	
 * 	<li><b> onCompleteParams : Array</b>	An Array of parameters to pass the onComplete function</li>
 * 	
 * 	<li><b> onReverseComplete : Function</b> A function that should be called when the tween has reached its starting point again after having been reversed. </li>
 * 	
 * 	<li><b> onReverseCompleteParams : Array</b> An Array of parameters to pass the onReverseComplete function.</li>
 *  
 * 	<li><b> onRepeat : Function</b>			A function that should be called every time the tween repeats </li>
 * 	
 * 	<li><b> onRepeatParams : Array</b>		An Array of parameters to pass the onRepeat function</li>
 * 	
 * 	<li><b> immediateRender : Boolean</b> Normally when you create a tween, it begins rendering on the very next frame (when 
 * 											the Flash Player dispatches an ENTER_FRAME event) unless you specify a <code>delay</code>. This 
 * 											allows you to insert tweens into timelines and perform other actions that may affect 
 * 											its timing. However, if you prefer to force the tween to render immediately when it is 
 * 											created, set <code>immediateRender</code> to true. Or to prevent a tween with a duration of zero from
 * 											rendering immediately, set this to false.</li>
 * 
 *  <li><b> paused : Boolean</b>			If true, the tween will be paused initially.</li>
 * 
 * 	<li><b> reversed : Boolean</b>			If true, the tween will be reversed initially. This does not swap the starting/ending
 * 											values in the tween - it literally changes its orientation/direction. Imagine the playhead
 * 											moving backwards instead of forwards. This does NOT force it to the very end and start 
 * 											playing backwards. It simply affects the orientation of the tween, so if reversed is set to 
 * 											true initially, it will appear not to play because it is already at the beginning. To cause it to
 * 											play backwards from the end, set reversed to true and then set the <code>currentProgress</code> 
 * 											property to 1 immediately after creating the tween (or set the currentTime to the duration). </li>
 * 	
 * 	<li><b> overwrite : int</b>			Controls how (and if) other tweens of the same target are overwritten by this tween. There are
 * 										several modes to choose from, and TweenMax automatically calls <code>OverwriteManager.init()</code> if you haven't
 * 										already manually dones so, which means that by default <code>AUTO</code> mode is used (please see 
 * 										<a href="http://www.greensock.com/overwritemanager/">http://www.greensock.com/overwritemanager/</a> 
 * 										for details and a full explanation of the various modes):
 * 										<ul>
 * 			  								<li>NONE (0) (or false) </li>
 * 											
 * 											<li>ALL_IMMEDIATE (1) (or true)</li>
 * 													
 * 											<li>AUTO (2) - this is the default mode for TweenMax.</li>
 * 												
 * 											<li>CONCURRENT (3)</li>
 * 												
 * 											<li>ALL_ONSTART (4)</li>
 * 												
 * 											<li>PREEXISTING (5)</li>
 * 
 * 										</ul></li>
 * 	
 * 	<li><b> repeat : int</b>					Number of times that the tween should repeat. To repeat indefinitely, use -1.</li>
 * 	
 * 	<li><b> repeatDelay : Number</b>			Amount of time in seconds (or frames for frames-based tween) between repeats.</li>
 * 	
 * 	<li><b> yoyo : Boolean</b> 					Works in conjunction with the repeat property, determining the behavior of each 
 * 												cycle. When yoyo is true, the tween will go back and forth, appearing to reverse 
 * 												every other cycle (this has no affect on the "reversed" property though). So if repeat is
 * 												2 and yoyo is false, it will look like: start - 1 - 2 - 3 - 1 - 2 - 3 - 1 - 2 - 3 - end. But 
 * 												if repeat is 2 and yoyo is true, it will look like: start - 1 - 2 - 3 - 3 - 2 - 1 - 1 - 2 - 3 - end. </li>
 * 									
 * 	<li><b> onStartListener : Function</b>		A function to which the TweenMax instance should dispatch a TweenEvent when it begins.
 * 	  											This is the same as doing <code>myTween.addEventListener(TweenEvent.START, myFunction);</code></li>
 * 	
 * 	<li><b> onUpdateListener : Function</b>		A function to which the TweenMax instance should dispatch a TweenEvent every time it 
 * 												updates values.	This is the same as doing <code>myTween.addEventListener(TweenEvent.UPDATE, myFunction);</code></li>
 * 	  
 * 	<li><b> onCompleteListener : Function</b>	A function to which the TweenMax instance should dispatch a TweenEvent when it completes.
 * 	  											This is the same as doing <code>myTween.addEventListener(TweenEvent.COMPLETE, myFunction);</code></li>
 * 
 *  <li><b> onReverseCompleteListener : Function</b> A function to which the TweenMax instance should dispatch a TweenEvent when it completes
 * 												in the reverse direction. This is the same as doing <code>myTween.addEventListener(TweenEvent.REVERSE_COMPLETE, myFunction);</code></li>
 * 
 *  <li><b> onRepeatListener : Function</b>		A function to which the TweenMax instance should dispatch a TweenEvent when it repeats.
 * 	  											This is the same as doing <code>myTween.addEventListener(TweenEvent.REPEAT, myFunction);</code></li>
 * 	
 * 	<li><b> startAt : Object</b>				Allows you to define the starting values for each property. Typically, TweenMax uses the current
 * 												value (whatever it happens to be at the time the tween begins) as the start value, but startAt
 * 												allows you to override that behavior. Simply pass an object in with whatever properties you'd like
 * 												to set just before the tween begins. For example, if mc.x is currently 100, and you'd like to 
 * 												tween it from 0 to 500, do <code>TweenMax.to(mc, 2, {x:500, startAt:{x:0}});</code> </li>
 * </ul>
 * 
 * <b>Note:</b> Using a <code><a href="data/TweenMaxVars.html">TweenMaxVars</a></code> instance 
 * instead of a generic Object to define your <code>vars</code> is a bit more verbose but provides 
 * code hinting and improved debugging because it enforces strict data typing. Use whichever one you prefer.<br /><br />
 * 
 * <b>PLUGINS: </b><br /><br />
 * 
 * 	There are many plugins that add capabilities through other special properties. Adding the capabilities 
 * 	is as simple as activating the plugin with a single line of code, like <code>TweenPlugin.activate([SetSizePlugin]);</code>
 * 	Get information about all the plugins at <a href="http://www.TweenMax.com">http://www.TweenMax.com</a>. The 
 *  following plugins are activated by default in TweenMax (you can easily prevent them from activating, thus 
 *  saving file size, by commenting out the associated activation lines towards the top of the class):
 * 	
 * <ul>
 * 	  <li><b> autoAlpha : Number</b> - Use it instead of the alpha property to gain the additional feature of toggling 
 * 						   			   the visible property to false when alpha reaches 0. It will also toggle visible 
 * 						   			   to true before the tween starts if the value of autoAlpha is greater than zero.</li>
 * 						   
 * 	  <li><b> visible : Boolean</b> - To set a DisplayObject's "visible" property at the end of the tween, use this special property.</li>
 * 	  
 * 	  <li><b> volume : Number</b> - Tweens the volume of an object with a soundTransform property (MovieClip/SoundChannel/NetStream, etc.)</li>
 * 	  
 * 	  <li><b> tint : Number</b> - To change a DisplayObject's tint/color, set this to the hex value of the tint you'd like
 * 					  			  to end up at(or begin at if you're using TweenMax.from()). An example hex value would be 0xFF0000.</li>
 * 					  
 * 	  <li><b> removeTint : Boolean</b> - If you'd like to remove the tint that's applied to a DisplayObject, pass true for this special property.</li>
 * 	  
 * 	  <li><b> frame : Number</b> - Use this to tween a MovieClip to a particular frame.</li>
 * 	  
 * 	  <li><b> bezier : Array</b> - Bezier tweening allows you to tween in a non-linear way. For example, you may want to tween
 * 					  			  a MovieClip's position from the origin (0,0) 500 pixels to the right (500,0) but curve downwards
 *  				   			  through the middle of the tween. Simply pass as many objects in the bezier array as you'd like, 
 * 					   			  one for each "control point" (see documentation on Flash's curveTo() drawing method for more
 * 					   			  about how control points work). In this example, let's say the control point would be at x/y coordinates
 * 					   			  250,50. Just make sure your my_mc is at coordinates 0,0 and then do: 
 * 					   			  <code>TweenMax.to(my_mc, 3, {bezier:[{x:250, y:50}, {x:500, y:0}]});</code></li>
 * 					   
 * 	  <li><b> bezierThrough : Array</b> - Identical to bezier except that instead of passing bezier control point values, you
 * 							  			  pass points through which the bezier values should move. This can be more intuitive
 * 							  			  than using control points.</li>
 * 							  
 * 	  <li><b> orientToBezier : Array (or Boolean)</b> - A common effect that designers/developers want is for a MovieClip/Sprite to 
 * 	  						orient itself in the direction of a Bezier path (alter its rotation). orientToBezier
 * 							makes it easy. In order to alter a rotation property accurately, TweenMax needs 4 pieces
 * 							of information: 
 * 							<ol>
 * 								<li> Position property 1 (typically "x")</li>
 * 								<li> Position property 2 (typically "y")</li>
 * 								<li> Rotational property (typically "rotation")</li>
 * 								<li> Number of degrees to add (optional - makes it easy to orient your MovieClip properly)</li>
 *							</ol>
 * 							The orientToBezier property should be an Array containing one Array for each set of these values. 
 * 							For maximum flexibility, you can pass in any number of arrays inside the container array, one 
 * 							for each rotational property. This can be convenient when working in 3D because you can rotate
 * 							on multiple axis. If you're doing a standard 2D x/y tween on a bezier, you can simply pass 
 * 							in a boolean value of true and TweenMax will use a typical setup, <code>[["x", "y", "rotation", 0]]</code>. 
 * 							Hint: Don't forget the container Array (notice the double outer brackets)</li>
 * 							
 * 	  <li><b> hexColors : Object</b> - Although hex colors are technically numbers, if you try to tween them conventionally,
 * 				 you'll notice that they don't tween smoothly. To tween them properly, the red, green, and 
 * 				 blue components must be extracted and tweened independently. TweenMax makes it easy. To tween
 * 				 a property of your object that's a hex color to another hex color, use this special hexColors 
 * 				 property of TweenMax. It must be an OBJECT with properties named the same as your object's 
 * 				 hex color properties. For example, if your my_obj object has a "myHexColor" property that you'd like
 * 				 to tween to red (0xFF0000) over the course of 2 seconds, do: <br />
 * 				 <code>TweenMax.to(my_obj, 2, {hexColors:{myHexColor:0xFF0000}});</code><br />
 * 				 You can pass in any number of hexColor properties.</li>
 * 				 
 * 	  <li><b> shortRotation : Object</b> - To tween the rotation property of the target object in the shortest direction, use "shortRotation" 
 * 	  						   instead of "rotation" as the property. For example, if <code>myObject.rotation</code> is currently 170 degrees 
 * 	  						   and you want to tween it to -170 degrees, a normal rotation tween would travel a total of 340 degrees 
 * 	  						   in the counter-clockwise direction, but if you use shortRotation, it would travel 20 degrees in the 
 * 	  						   clockwise direction instead.</li>
 * 	  					   
 * 	  <li><b> roundProps : Array</b> - If you'd like the inbetween values in a tween to always get rounded to the nearest integer, use the roundProps
 * 	  					   special property. Just pass in an Array containing the property names that you'd like rounded. For example,
 * 	  					   if you're tweening the x, y, and alpha properties of mc and you want to round the x and y values (not alpha)
 * 	  					   every time the tween is rendered, you'd do: <code>TweenMax.to(mc, 2, {x:300, y:200, alpha:0.5, roundProps:["x","y"]});</code></li>
 * 	  					   
 * 	  <li><b> blurFilter : Object</b> - To apply a BlurFilter, pass an object with one or more of the following properties:
 * 	  									<code>blurX, blurY, quality, remove, addFilter, index</code></li>
 * 	  						
 * 	  <li><b> glowFilter : Object</b> - To apply a GlowFilter, pass an object with one or more of the following properties:
 * 	  								<code>alpha, blurX, blurY, color, strength, quality, inner, knockout, remove, addFilter, index</code></li>
 * 	  						
 * 	  <li><b> colorMatrixFilter : Object</b> - To apply a ColorMatrixFilter, pass an object with one or more of the following properties:
 * 								   <code>colorize, amount, contrast, brightness, saturation, hue, threshold, relative, matrix, remove, addFilter, index</code></li>
 * 								   
 * 	  <li><b> dropShadowFilter : Object</b> - To apply a DropShadowFilter, pass an object with one or more of the following properties:
 * 								  			  <code>alpha, angle, blurX, blurY, color, distance, strength, quality, remove, addFilter, index</code></li>
 * 								  
 * 	  <li><b> bevelFilter : Object</b> - To apply a BevelFilter, pass an object with one or more of the following properties:
 * 							 			 <code>angle, blurX, blurY, distance, highlightAlpha, highlightColor, shadowAlpha, shadowColor, strength, quality, remove, addFilter, index</code></li>
 * 	</ul>
 * 	
 * 	
 * <b>EXAMPLES:</b><br /><br /> 
 * 	
 * 	Please see <a href="http://www.tweenmax.com">http://www.tweenmax.com</a> for examples, tutorials, and interactive demos. <br /><br />
 * 
 * <b>NOTES / TIPS:</b>
 * <ul>
 * 	<li> Passing values as Strings will make the tween relative to the current value. For example, if you do
 * 	  <code>TweenMax.to(mc, 2, {x:"-20"});</code> it'll move the mc.x to the left 20 pixels which is the same as doing
 * 	  <code>TweenMax.to(mc, 2, {x:mc.x - 20});</code> You could also cast it like: <code>TweenMax.to(mc, 2, {x:String(myVariable)});</code></li>
 * 	  
 * 	<li> If you prefer, instead of using the onCompleteListener, onInitListener, onStartListener, and onUpdateListener special properties, 
 * 	  you can set up listeners the typical way, like:<br /><code>
 * 	  var myTween:TweenMax = new TweenMax(my_mc, 2, {x:200});<br />
 * 	  myTween.addEventListener(TweenEvent.COMPLETE, myFunction);</code></li>
 * 	  
 * 	<li> You can kill all tweens of a particular object anytime with the <code>TweenMax.killTweensOf(myObject); </code></li>
 * 	  
 * 	<li> You can kill all delayedCalls to a particular function using <code>TweenMax.killDelayedCallsTo(myFunction);</code>
 * 	  This can be helpful if you want to preempt a call.</li>
 * 	  
 * 	<li> Use the <code>TweenMax.from()</code> method to animate things into place. For example, if you have things set up on 
 * 	  the stage in the spot where they should end up, and you just want to animate them into place, you can 
 * 	  pass in the beginning x and/or y and/or alpha (or whatever properties you want).</li>
 * 
 * 	<li> If you find this class useful, please consider joining Club GreenSock which not only helps to sustain
 * 	  ongoing development, but also gets you bonus plugins, classes and other benefits that are ONLY available 
 * 	  to members. Learn more at <a href="http://www.greensock.com/club/">http://www.greensock.com/club/</a></li>
 * 	</ul>
 * 	  
 * <b>Copyright 2012, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 */
	public class TweenMax extends TweenLite implements IEventDispatcher {
		/** @private **/
		public static const version:Number = 11.698;
		
		TweenPlugin.activate([
			
			
			//ACTIVATE (OR DEACTIVATE) PLUGINS HERE...
			
			AutoAlphaPlugin,			//tweens alpha and then toggles "visible" to false if/when alpha is zero
			EndArrayPlugin,				//tweens numbers in an Array
			FramePlugin,				//tweens MovieClip frames
			RemoveTintPlugin,			//allows you to remove a tint
			TintPlugin,					//tweens tints
			VisiblePlugin,				//tweens a target's "visible" property
			VolumePlugin,				//tweens the volume of a MovieClip or SoundChannel or anything with a "soundTransform" property
			
			BevelFilterPlugin,			//tweens BevelFilters
			BezierPlugin,				//enables bezier tweening
			BezierThroughPlugin,		//enables bezierThrough tweening
			BlurFilterPlugin,			//tweens BlurFilters
			ColorMatrixFilterPlugin,	//tweens ColorMatrixFilters (including hue, saturation, colorize, contrast, brightness, and threshold)
			ColorTransformPlugin,		//tweens advanced color properties like exposure, brightness, tintAmount, redOffset, redMultiplier, etc.
			DropShadowFilterPlugin,		//tweens DropShadowFilters
			FrameLabelPlugin,			//tweens a MovieClip to particular label
			GlowFilterPlugin,			//tweens GlowFilters
			HexColorsPlugin,			//tweens hex colors
			RoundPropsPlugin,			//enables the roundProps special property for rounding values (ONLY for TweenMax!)
			ShortRotationPlugin,		//tweens rotation values in the shortest direction
			
			//QuaternionsPlugin,			//tweens 3D Quaternions
			//ScalePlugin,				//Tweens both the _xscale and _yscale properties
			//ScrollRectPlugin,			//tweens the scrollRect property of a DisplayObject
			//SetSizePlugin,				//tweens the width/height of components via setSize()
			//SetActualSizePlugin,		//tweens the width/height of components via setActualSize()
			//TransformMatrixPlugin,		//Tweens the transform.matrix property of any DisplayObject
				
			//DynamicPropsPlugin,			//tweens to dynamic end values. You associate the property with a particular function that returns the target end value **Club GreenSock membership benefit**
			//MotionBlurPlugin,			//applies a directional blur to a DisplayObject based on the velocity and angle of movement. **Club GreenSock membership benefit**
			//Physics2DPlugin,			//allows you to apply basic physics in 2D space, like velocity, angle, gravity, friction, acceleration, and accelerationAngle. **Club GreenSock membership benefit**
			//PhysicsPropsPlugin,			//allows you to apply basic physics to any property using forces like velocity, acceleration, and/or friction. **Club GreenSock membership benefit**
			//TransformAroundCenterPlugin,//tweens the scale and/or rotation of DisplayObjects using the DisplayObject's center as the registration point **Club GreenSock membership benefit**
			//TransformAroundPointPlugin,	//tweens the scale and/or rotation of DisplayObjects around a particular point (like a custom registration point) **Club GreenSock membership benefit**
			
			
			{}]); //activated in static var instead of constructor because otherwise if there's a from() tween, TweenLite's constructor would get called first and initTweenVals() would run before the plugins were activated.
		
		
		/** @private Just to make sure OverwriteManager is activated. **/
		private static var _overwriteMode:int = (OverwriteManager.enabled) ? OverwriteManager.mode : OverwriteManager.init(2);
		
		/**
		 * Kills all the tweens of a particular object, optionally completing them first.
		 * 
		 * @param target Object whose tweens should be immediately killed
		 * @param complete Indicates whether or not the tweens should be forced to completion before being killed.
		 */
		public static var killTweensOf:Function = TweenLite.killTweensOf;
		/** @private **/
		public static var killDelayedCallsTo:Function = TweenLite.killTweensOf;
		/** @private **/
		protected var _dispatcher:EventDispatcher;
		/** @private **/
		protected var _hasUpdateListener:Boolean;
		/** @private **/
		protected var _repeat:int = 0;
		/** @private **/
		protected var _repeatDelay:Number = 0;
		/** @private **/
		protected var _cyclesComplete:int = 0;
		/** @private Indicates the strength of the fast ease - only used for eases that are optimized to make use of the internal code in the render() loop (ones that are activated with FastEase.activate()) **/
		protected var _easePower:int;
		/** @private 0 = standard function, 1 = optimized easeIn, 2 = optimized easeOut, 3 = optimized easeInOut. Only used for eases that are optimized to make use of the internal code in the render() loop (ones that are activated with FastEase.activate()) **/
		protected var _easeType:int; 
		
		
		/** 
		 * Works in conjunction with the repeat property, determining the behavior of each cycle; when yoyo is true, 
		 * the tween will go back and forth, appearing to reverse every other cycle (this has no affect on the "reversed" 
		 * property though). So if repeat is 2 and yoyo is false, it will look like: start - 1 - 2 - 3 - 1 - 2 - 3 - 1 - 2 - 3 - end. 
		 * But if repeat is 2 and yoyo is true, it will look like: start - 1 - 2 - 3 - 3 - 2 - 1 - 1 - 2 - 3 - end.  
		 **/
		public var yoyo:Boolean;
		
		/**
		 * Constructor
		 *  
		 * @param target Target object whose properties this tween affects. This can be ANY object, not just a DisplayObject. 
		 * @param duration Duration in seconds (or in frames if the tween's timing mode is frames-based)
		 * @param vars An object containing the end values of the properties you're tweening. For example, to tween to x=100, y=100, you could pass {x:100, y:100}. It can also contain special properties like "onComplete", "ease", "delay", etc.
		 */
		public function TweenMax(target:Object, duration:Number, vars:Object) {
			super(target, duration, vars);
			if (TweenLite.version < 11.2) {
				throw new Error("TweenMax error! Please update your TweenLite class or try deleting your ASO files. TweenMax requires a more recent version. Download updates at http://www.TweenMax.com.");
			}
			this.yoyo = Boolean(this.vars.yoyo);
			_repeat = uint(this.vars.repeat);
			_repeatDelay = (this.vars.repeatDelay) ? Number(this.vars.repeatDelay) : 0;
			this.cacheIsDirty = true; //ensures that if there is any repeat, the totalDuration will get recalculated to accurately report it.

			if (this.vars.onCompleteListener || this.vars.onInitListener || this.vars.onUpdateListener || this.vars.onStartListener || this.vars.onRepeatListener || this.vars.onReverseCompleteListener) {
				initDispatcher();
				if (duration == 0 && _delay == 0) {
					_dispatcher.dispatchEvent(new TweenEvent(TweenEvent.UPDATE));
					_dispatcher.dispatchEvent(new TweenEvent(TweenEvent.COMPLETE));
				}
			}
			if (this.vars.timeScale && !(this.target is TweenCore)) {
				this.cachedTimeScale = this.vars.timeScale;
			}
		}
		
		/**
		 * @private
		 * Initializes the property tweens, determining their start values and amount of change. 
		 * Also triggers overwriting if necessary and sets the _hasUpdate variable.
		 */
		override protected function init():void {
			if (this.vars.startAt) {
				this.vars.startAt.overwrite = 0;
				this.vars.startAt.immediateRender = true;
				var startTween:TweenMax = new TweenMax(this.target, 0, this.vars.startAt);
			}
			if (_dispatcher) {
				_dispatcher.dispatchEvent(new TweenEvent(TweenEvent.INIT));
			}
			super.init();
			if (_ease in fastEaseLookup) {
				_easeType = fastEaseLookup[_ease][0];
				_easePower = fastEaseLookup[_ease][1];
			}
		}
	
		/** @inheritDoc **/
		override public function invalidate():void {
			this.yoyo = Boolean(this.vars.yoyo == true);
			_repeat = (this.vars.repeat) ? Number(this.vars.repeat) : 0;
			_repeatDelay = (this.vars.repeatDelay) ? Number(this.vars.repeatDelay) : 0;
			_hasUpdateListener = false;
			if (this.vars.onCompleteListener != null || this.vars.onUpdateListener != null || this.vars.onStartListener != null) {			
				initDispatcher();
			}
			setDirtyCache(true);
			super.invalidate();
		}
		
		/**
		 * Updates tweening values on the fly so that they appear to seamlessly change course even if the tween is in-progress.
		 * Think of it as dynamically updating the <code>vars</code> object that you passed in to the tween when it was originally
		 * created. You do <b>NOT</b> need to redefine all of the <code>vars</code> values - only the ones that you want
		 * to update. You can even define new properties that you didn't define in the original <code>vars</code> object. 
		 * If the <code>resetDuration</code> parameter is <code>true</code> and the tween has already started (or finished), 
		 * <code>updateTo()</code> will restart the tween. Otherwise, the tween's timing will be honored. And if
		 * <code>resetDuration</code> is <code>false</code> and the tween is in-progress, the starting values of each 
		 * property will be adjusted so that the tween appears to seamlessly redirect to the new destination values. 
		 * For example:<br /><br /><code>
		 * 
		 * //create the tween <br />
		 * var tween:TweenMax = new TweenMax(mc, 2, {x:100, y:200, alpha:0.5});<br /><br />
		 * 
		 * //then later, update the destination x and y values, restarting the tween<br />
		 * tween.updateTo({x:300, y:0}, true);<br /><br />
		 * 
		 * //or to update the values mid-tween while keeping the end time the same (don't restart the tween), do this:<br />
		 * tween.updateTo({x:300, y:0}, false);<br /><br /></code>
		 * 
		 * Note: If you plan to constantly update values, please look into using the <code>DynamicPropsPlugin</code>.
		 * 
		 * @param vars Object containing properties with the end values that should be udpated. You do <b>NOT</b> need to redefine all of the original <code>vars</code> values - only the ones that should be updated (although if you change a plugin value, you will need to fully define it). For example, to update the destination <code>x</code> value to 300 and the destination <code>y</code> value to 500, pass: <code>{x:300, y:500}</code>.
		 * @param resetDuration If the tween has already started (or finished) and <code>resetDuration</code> is true, the tween will restart. If <code>resetDuration</code> is false, the tween's timing will be honored (no restart) and each tweening property's starting value will be adjusted so that it appears to seamlessly redirect to the new destination value.
		 **/
		public function updateTo(vars:Object, resetDuration:Boolean=false):void {
			var curRatio:Number = this.ratio;
			if (resetDuration && this.timeline != null && this.cachedStartTime < this.timeline.cachedTime) {
				this.cachedStartTime = this.timeline.cachedTime;
				this.setDirtyCache(false);
				if (this.gc) {
					this.setEnabled(true, false);
				} else {
					this.timeline.insert(this, this.cachedStartTime - _delay); //ensures that any necessary re-sequencing of TweenCores in the timeline occurs to make sure the rendering order is correct.
				}
			}
			for (var p:String in vars) {
				this.vars[p] = vars[p];
			}
			if (this.initted) {
				if (resetDuration) {
					this.initted = false;
				} else {
					if (_notifyPluginsOfEnabled && this.cachedPT1) {
						onPluginEvent("onDisable", this); //in case a plugin like MotionBlur must perform some cleanup tasks
					}
					if (this.cachedTime / this.cachedDuration > 0.998) { //if the tween has finished (or come extremely close to finishing), we just need to rewind it to 0 and then render it again at the end which forces it to re-initialize (parsing the new vars). We allow tweens that are close to finishing (but haven't quite finished) to work this way too because otherwise, the values are so small when determining where to project the starting values that binary math issues creep in and can make the tween appear to render incorrectly when run backwards. 
						var prevTime:Number = this.cachedTime;
						this.renderTime(0, true, false);
						this.initted = false;
						this.renderTime(prevTime, true, false);
					} else if (this.cachedTime > 0) {
						this.initted = false;
						init();
						var inv:Number = 1 / (1 - curRatio);
						var pt:PropTween = this.cachedPT1, endValue:Number;
						while (pt) {
							endValue = pt.start + pt.change; 
							pt.change *= inv;
							pt.start = endValue - pt.change;
							pt = pt.nextNode;
						}
					}
				}
			}
		}
		
		/**
		 * Adjusts a destination value on the fly, optionally adjusting the start values so that it appears to redirect seamlessly
		 * without skipping/jerking (<b>this method has been deprecated in favor of <code>updateTo()</code></b>). 
		 * If you plan to constantly update values, please look into using the DynamicPropsPlugin.
		 * 
		 * @param property Name of the property that should be updated. For example, "x".
		 * @param value The new destination value
		 * @param adjustStartValues If true, the property's start value will be adjusted to make the tween appear to seamlessly/smoothly redirect without any skipping/jerking. Beware that if start values are adjusted, reversing the tween will not make it travel back to the original starting value.
		 **/
		public function setDestination(property:String, value:*, adjustStartValues:Boolean=true):void {
			var vars:Object = {};
			vars[property] = value;
			updateTo(vars, !adjustStartValues);
		}
		
		
		/**
		 * Allows particular properties of the tween to be killed, much like the killVars() method
		 * except that killProperties() accepts an Array of property names.
		 * 
		 * @param names An Array of property names whose tweens should be killed immediately.
		 */
		public function killProperties(names:Array):void {
			var v:Object = {}, i:int = names.length;
			while (--i > -1) {
				v[names[i]] = true;
			}
			killVars(v);
		}
		
		/**
		 * @private
		 * Renders the tween at a particular time (or frame number for frames-based tweens). 
		 * The time is based simply on the overall duration. For example, if a tween's duration
		 * is 3, <code>renderTime(1.5)</code> would render it at the halfway finished point.
		 * 
		 * @param time time (or frame number for frames-based tweens) to render.
		 * @param suppressEvents If true, no events or callbacks will be triggered for this render (like onComplete, onUpdate, onReverseComplete, etc.)
		 * @param force Normally the tween will skip rendering if the time matches the cachedTotalTime (to improve performance), but if force is true, it forces a render. This is primarily used internally for tweens with durations of zero in TimelineLite/Max instances.
		 */
		override public function renderTime(time:Number, suppressEvents:Boolean=false, force:Boolean=false):void {
			var totalDur:Number = (this.cacheIsDirty) ? this.totalDuration : this.cachedTotalDuration, prevTime:Number = this.cachedTime, prevTotalTime:Number = this.cachedTotalTime, isComplete:Boolean, repeated:Boolean, setRatio:Boolean;
			if (time >= totalDur) {
				this.cachedTotalTime = totalDur;
				this.cachedTime = this.cachedDuration;
				this.ratio = 1;
				isComplete = !this.cachedReversed;
				if (this.cachedDuration == 0) { //zero-duration tweens are tricky because we must discern the momentum/direction of time in order to determine whether the starting values should be rendered or the ending values. If the "playhead" of its timeline goes past the zero-duration tween in the forward direction or lands directly on it, the end values should be rendered, but if the timeline's "playhead" moves past it in the backward direction (from a postitive time to a negative time), the starting values must be rendered.
					if ((time == 0 || _rawPrevTime < 0) && _rawPrevTime != time) {
						force = true;
					}		
					_rawPrevTime = time;
				}
				
			} else if (time <= 0) {
				if (time < 0) {
					this.active = false;
					if (this.cachedDuration == 0) { //zero-duration tweens are tricky because we must discern the momentum/direction of time in order to determine whether the starting values should be rendered or the ending values. If the "playhead" of its timeline goes past the zero-duration tween in the forward direction or lands directly on it, the end values should be rendered, but if the timeline's "playhead" moves past it in the backward direction (from a postitive time to a negative time), the starting values must be rendered.
						if (_rawPrevTime >= 0) {
							force = true;
							isComplete = (_rawPrevTime > 0);
						}
						_rawPrevTime = time;
					}
				} else if (time == 0 && !this.initted) { //if we render the very beginning (time == 0) of a TweenMax.fromTo(), we must force the render (normal tweens wouldn't need to render at a time of 0 when the prevTime was also 0). This is also mandatory to make sure overwriting kicks in immediately.
					force = true;
				}
				this.cachedTotalTime = this.cachedTime = this.ratio = 0;
				if (this.cachedReversed && prevTotalTime != 0) {
					isComplete = true;
				}
			} else {
				this.cachedTotalTime = this.cachedTime = time;
				setRatio = true;
			}
			
			if (_repeat != 0) {
				
				var cycleDuration:Number = this.cachedDuration + _repeatDelay;
				var prevCycles:int = _cyclesComplete;
				if ((_cyclesComplete = (this.cachedTotalTime / cycleDuration) >> 0) == (this.cachedTotalTime / cycleDuration) && _cyclesComplete != 0) {
					_cyclesComplete--; //otherwise when rendered exactly at the end time, it will act as though it is repeating (at the beginning)
				}
				repeated = Boolean(prevCycles != _cyclesComplete);
				
				if (isComplete) {
					if (this.yoyo && _repeat % 2) {
						this.cachedTime = this.ratio = 0;
					}
				} else if (time > 0) {
					this.cachedTime = this.cachedTotalTime - (_cyclesComplete * cycleDuration); //originally this.cachedTotalTime % cycleDuration but floating point errors caused problems, so I normalized it. (4 % 0.8 should be 0 but Flash reports it as 0.79999999!)

					if (this.yoyo && _cyclesComplete % 2) {
						this.cachedTime = this.cachedDuration - this.cachedTime;
					} else if (this.cachedTime >= this.cachedDuration) {
						this.cachedTime = this.cachedDuration;
						this.ratio = 1;
						setRatio = false;
					}
					
					if (this.cachedTime <= 0) {
						this.cachedTime = this.ratio = 0;
						setRatio = false;
					}
				} else {
					_cyclesComplete = 0;
				}
				
			}
			
			if (prevTime == this.cachedTime && !force) {
				return;
			} else if (!this.initted) {
				init();
			}
			if (!this.active && !this.cachedPaused) {
				this.active = true;  //so that if the user renders a tween (as opposed to the timeline rendering it), the timeline is forced to re-render and align it with the proper time/frame on the next rendering cycle. Maybe the tween already finished but the user manually re-renders it as halfway done.
			}
			
			if (setRatio) {
				//if the ease is optimized, process it inline (function calls are expensive performance-wise)...
				if (_easeType) {
					var power:int = _easePower;
					var val:Number = this.cachedTime / this.cachedDuration;
					if (_easeType == 2) { 			//easeOut
						this.ratio = val = 1 - val;
						while (--power > -1) {
							this.ratio = val * this.ratio;
						}
						this.ratio = 1 - this.ratio;
					} else if (_easeType == 1) { 	//easeIn
						this.ratio = val;
						while (--power > -1) {
							this.ratio = val * this.ratio;
						}
					} else {						//easeInOut
						if (val < 0.5) {
							this.ratio = val = val * 2;
							while (--power > -1) {
								this.ratio = val * this.ratio;
							}
							this.ratio = this.ratio * 0.5;
						} else {
							this.ratio = val = (1 - val) * 2;
							while (--power > -1) {
								this.ratio = val * this.ratio;
							}
							this.ratio = 1 - (0.5 * this.ratio);
						}
					}
				
				} else {
					this.ratio = _ease(this.cachedTime, 0, 1, this.cachedDuration);
				}
			}
			
			if (prevTotalTime == 0 && (this.cachedTotalTime != 0 || this.cachedDuration == 0) && !suppressEvents) {
				if (this.vars.onStart) {
					this.vars.onStart.apply(null, this.vars.onStartParams);
				}
				if (_dispatcher) {
					_dispatcher.dispatchEvent(new TweenEvent(TweenEvent.START));
				}
			}
			
			var pt:PropTween = this.cachedPT1;
			while (pt) {
				pt.target[pt.property] = pt.start + (this.ratio * pt.change);
				pt = pt.nextNode;
			}
			if (_hasUpdate && !suppressEvents) {
				this.vars.onUpdate.apply(null, this.vars.onUpdateParams);
			}
			if (_hasUpdateListener && !suppressEvents) {
				_dispatcher.dispatchEvent(new TweenEvent(TweenEvent.UPDATE));
			}
			if (repeated && !suppressEvents && !this.gc) { 
				if (this.vars.onRepeat) {
					this.vars.onRepeat.apply(null, this.vars.onRepeatParams);
				}
				if (_dispatcher) {
					_dispatcher.dispatchEvent(new TweenEvent(TweenEvent.REPEAT));
				}
			}
			if (isComplete && !this.gc) { //check gc because there's a chance that kill() could be called in an onUpdate
				if (_hasPlugins && this.cachedPT1) {
					onPluginEvent("onComplete", this);
				}
				complete(true, suppressEvents);
			}
		}
		
		/**
		 * Forces the tween to completion.
		 * 
		 * @param skipRender to skip rendering the final state of the tween, set skipRender to true. 
		 * @param suppressEvents If true, no events or callbacks will be triggered for this render (like onComplete, onUpdate, onReverseComplete, etc.)
		 */
		override public function complete(skipRender:Boolean=false, suppressEvents:Boolean=false):void {
			super.complete(skipRender, suppressEvents);
			if (!suppressEvents && _dispatcher) {
				if (this.cachedTotalTime == this.cachedTotalDuration && !this.cachedReversed) {
					_dispatcher.dispatchEvent(new TweenEvent(TweenEvent.COMPLETE));
				} else if (this.cachedReversed && this.cachedTotalTime == 0) {
					_dispatcher.dispatchEvent(new TweenEvent(TweenEvent.REVERSE_COMPLETE));
				} 
			}
		}
		
		
//---- EVENT DISPATCHING ----------------------------------------------------------------------------------------------------------
		
		/**
		 * @private
		 * Initializes Event dispatching functionality
		 */
		protected function initDispatcher():void {
			if (_dispatcher == null) {
				_dispatcher = new EventDispatcher(this);
			}
			if (this.vars.onInitListener is Function) {
				_dispatcher.addEventListener(TweenEvent.INIT, this.vars.onInitListener, false, 0, true);
			}
			if (this.vars.onStartListener is Function) {
				_dispatcher.addEventListener(TweenEvent.START, this.vars.onStartListener, false, 0, true);
			}
			if (this.vars.onUpdateListener is Function) {
				_dispatcher.addEventListener(TweenEvent.UPDATE, this.vars.onUpdateListener, false, 0, true);
				_hasUpdateListener = true;
			}
			if (this.vars.onCompleteListener is Function) {
				_dispatcher.addEventListener(TweenEvent.COMPLETE, this.vars.onCompleteListener, false, 0, true);
			}
			if (this.vars.onRepeatListener is Function) {
				_dispatcher.addEventListener(TweenEvent.REPEAT, this.vars.onRepeatListener, false, 0, true);
			}
			if (this.vars.onReverseCompleteListener is Function) {
				_dispatcher.addEventListener(TweenEvent.REVERSE_COMPLETE, this.vars.onReverseCompleteListener, false, 0, true);
			}
		}
		/** @private **/
		public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void {
			if (_dispatcher == null) {
				initDispatcher();
			}
			if (type == TweenEvent.UPDATE) {
				_hasUpdateListener = true;
			}
			_dispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		/** @private **/
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void {
			if (_dispatcher) {
				_dispatcher.removeEventListener(type, listener, useCapture);
			}
		}
		/** @private **/
		public function hasEventListener(type:String):Boolean {
			return (_dispatcher == null) ? false : _dispatcher.hasEventListener(type);
		}
		/** @private **/
		public function willTrigger(type:String):Boolean {
			return (_dispatcher == null) ? false : _dispatcher.willTrigger(type);
		}
		/** @private **/
		public function dispatchEvent(e:Event):Boolean {
			return (_dispatcher == null) ? false : _dispatcher.dispatchEvent(e);
		}
		
		
//---- STATIC FUNCTIONS -----------------------------------------------------------------------------------------------------------
		
		/**
		 * Static method for creating a TweenMax instance. This can be more intuitive for some developers 
		 * and shields them from potential garbage collection issues that could arise when assigning a
		 * tween instance to a variable that persists. The following lines of code produce exactly 
		 * the same result: <br /><br /><code>
		 * 
		 * 		var myTween:TweenMax = new TweenMax(mc, 1, {x:100}); <br />
		 * 		TweenMax.to(mc, 1, {x:100}); <br />
		 * 		var myTween:TweenMax = TweenMax.to(mc, 1, {x:100}); <br /><br /></code>
		 * 
		 * @param target Target object whose properties this tween affects. This can be ANY object, not just a DisplayObject. 
		 * @param duration Duration in seconds (or in frames for frames-based tweens)
		 * @param vars An object containing the end values of the properties you're tweening. For example, to tween to x=100, y=100, you could pass {x:100, y:100}. It can also contain special properties like "onComplete", "ease", "delay", etc.
		 * @return TweenMax instance
		 */
		public static function to(target:Object, duration:Number, vars:Object):TweenMax {
			return new TweenMax(target, duration, vars);
		}
		
		/**
		 * Static method for creating a TweenMax instance that tweens in the opposite direction
		 * compared to a <code>TweenMax.to()</code> tween. In other words, you define the START values in the 
		 * vars object instead of the end values, and the tween will use the current values as 
		 * the end values. This can be very useful for animating things into place on the stage
		 * because you can build them in their end positions and do some simple <code>TweenMax.from()</code>
		 * calls to animate them into place. <b>NOTE:</b> By default, <code>immediateRender</code>
		 * is <code>true</code> for from() tweens, meaning that they immediately render their starting state 
		 * regardless of any delay that is specified. You can override this behavior by passing 
		 * <code>immediateRender:false</code> in the <code>vars</code> object so that it will wait to 
		 * render until the tween actually begins (often the desired behavior when inserting into timelines). 
		 * To illustrate the default behavior, the following code will immediately set the <code>alpha</code> of <code>mc</code> 
		 * to 0 and then wait 2 seconds before tweening the <code>alpha</code> back to 1 over the course 
		 * of 1.5 seconds:<br /><br /><code>
		 * 
		 * TweenMax.from(mc, 1.5, {alpha:0, delay:2});</code>
		 * 
		 * @param target Target object whose properties this tween affects. This can be ANY object, not just a DisplayObject. 
		 * @param duration Duration in seconds (or in frames for frames-based tweens)
		 * @param vars An object containing the start values of the properties you're tweening. For example, to tween from x=100, y=100, you could pass {x:100, y:100}. It can also contain special properties like "onComplete", "ease", "delay", etc.
		 * @return TweenMax instance
		 */
		public static function from(target:Object, duration:Number, vars:Object):TweenMax {
			if (vars.isGSVars) {  //to accommodate TweenMaxVars instances for strong data typing and code hinting
				vars = vars.vars;
			}
			vars.runBackwards = true;
			if (!("immediateRender" in vars)) {
				vars.immediateRender = true;
			}
			return new TweenMax(target, duration, vars);
		}
		
		/**
		 * Static method for creating a TweenMax instance that tweens from a particular set of
		 * values to another set of values, as opposed to a normal to() or from() tween which are 
		 * based on the target's current values. <b>NOTE</b>: Only put starting values
		 * in the fromVars parameter - all special properties for the tween (like onComplete, onUpdate, delay, etc.) belong
		 * in the toVars parameter. 
		 * 
		 * @param target Target object whose properties this tween affects. This can be ANY object, not just a DisplayObject. 
		 * @param duration Duration in seconds (or in frames for frames-based tweens)
		 * @param fromVars An object containing the starting values of the properties you're tweening. For example, to tween from x=0, y=0, you could pass {x:0, y:0}. Only put starting values in the fromVars parameter - all special properties for the tween (like onComplete, onUpdate, delay, etc.) belong in the toVars parameter. 
		 * @param toVars An object containing the ending values of the properties you're tweening. For example, to tween to x=100, y=100, you could pass {x:100, y:100}. It can also contain special properties like "onComplete", "ease", "delay", etc.
		 * @return TweenMax instance
		 */
		public static function fromTo(target:Object, duration:Number, fromVars:Object, toVars:Object):TweenMax {
			if (toVars.isGSVars) {  //to accommodate TweenMaxVars instances for strong data typing and code hinting
				toVars = toVars.vars;
			}
			if (fromVars.isGSVars) {  //to accommodate TweenMaxVars instances for strong data typing and code hinting
				fromVars = fromVars.vars;
			}
			toVars.startAt = fromVars;
			if (fromVars.immediateRender) {
				toVars.immediateRender = true;
			}
			return new TweenMax(target, duration, toVars);
		}
		
		/**
		 * Tween multiple objects to the same end values. The "stagger" parameter 
		 * staggers the start time of each tween. For example, you might want to have 5 MovieClips move down 
		 * 100 pixels while fading out, and stagger the start times slightly by 0.2 seconds:  <br /><br /><code>
		 * 
		 * TweenMax.allTo([mc1, mc2, mc3, mc4, mc5], 1, {y:"100", alpha:0}, 0.2); <br /><br /></code>
		 * 
		 * Note: You can easily add a group of tweens to a TimelineLite/Max instance using allTo() in conjunction with the 
		 * insertMultipe() method of a timeline, like:<br /><br />
		 * <code>myTimeline.insertMultiple(TweenMax.allTo([mc1, mc2, mc3], 1, {alpha:0, y:"100"}, 0.1));</code>
		 * 
		 * @param targets An Array of objects to tween.
		 * @param duration Duration in seconds (or frames for frames-based tweens) of the tween
		 * @param vars An object containing the end values of all the properties you'd like to have tweened (or if you're using the TweenMax.allFrom() method, these variables would define the BEGINNING values).
		 * @param stagger Staggers the start time of each tween. For example, you might want to have 5 MovieClips move down 100 pixels while fading out, and stagger the start times slightly by 0.2 seconds, you could do: <code>TweenMax.allTo([mc1, mc2, mc3, mc4, mc5], 1, {y:"100", alpha:0}, 0.2)</code>.
		 * @param onCompleteAll A function to call when all of the tweens have completed.
		 * @param onCompleteAllParams An Array of parameters to pass the onCompleteAll function when all the tweens have completed.
		 * @return Array of TweenMax tweens
		 */
		public static function allTo(targets:Array, duration:Number, vars:Object, stagger:Number=0, onCompleteAll:Function=null, onCompleteAllParams:Array=null):Array {
			var i:int, varsDup:Object, p:String;
			var l:int = targets.length;
			var a:Array = [];
			if (vars.isGSVars) { //to accommodate TweenMaxVars instances for strong data typing and code hinting
				vars = vars.vars;
			}
			var curDelay:Number = ("delay" in vars) ? Number(vars.delay) : 0;
			var onCompleteProxy:Function = vars.onComplete;
			var onCompleteParamsProxy:Array = vars.onCompleteParams;
			var lastIndex:int = l - 1;
			for (i = 0; i < l; i += 1) {
				varsDup = {};
				for (p in vars) {
					varsDup[p] = vars[p];
				}
				varsDup.delay = curDelay;
				if (i == lastIndex && onCompleteAll != null) {
					varsDup.onComplete = function():void {
						if (onCompleteProxy != null) {
							onCompleteProxy.apply(null, onCompleteParamsProxy);
						}
						onCompleteAll.apply(null, onCompleteAllParams);
					}
				}
				a[i] = new TweenMax(targets[i], duration, varsDup);
				curDelay += stagger;
			}
			return a;
		}
		
		/**
		 * Exactly the same as TweenMax.allTo(), but instead of tweening the properties from where they're 
		 * at currently to whatever you define, this tweens them the opposite way - from where you define TO 
		 * where ever they are when the tweens begin. This is useful when things are set up on the stage the way they should 
		 * end up and you just want to tween them into place. <b>NOTE:</b> By default, <code>immediateRender</code>
		 * is <code>true</code> for allFrom() tweens, meaning that they immediately render their starting state 
		 * regardless of any delay or stagger that is specified. You can override this behavior by passing 
		 * <code>immediateRender:false</code> in the <code>vars</code> object so that each tween will wait to render until
		 * any delay/stagger has passed (often the desired behavior when inserting into timelines). To illustrate
		 * the default behavior, the following code will immediately set the <code>alpha</code> of <code>mc1</code>, 
		 * <code>mc2</code>, and <code>mc3</code> to 0 and then wait 2 seconds before tweening each <code>alpha</code> 
		 * back to 1 over the course of 1.5 seconds with 0.1 seconds lapsing between the start times of each:<br /><br /><code>
		 * 
		 * TweenMax.allFrom([mc1, mc2, mc3], 1.5, {alpha:0, delay:2}, 0.1);</code>
		 * 
		 * @param targets An Array of objects to tween.
		 * @param duration Duration (in seconds) of the tween (or in frames for frames-based tweens)
		 * @param vars An object containing the start values of all the properties you'd like to have tweened.
		 * @param stagger Staggers the start time of each tween. For example, you might want to have 5 MovieClips move down 100 pixels while fading from alpha:0, and stagger the start times slightly by 0.2 seconds, you could do: <code>TweenMax.allFromTo([mc1, mc2, mc3, mc4, mc5], 1, {y:"-100", alpha:0}, 0.2)</code>.
		 * @param onCompleteAll A function to call when all of the tweens have completed.
		 * @param onCompleteAllParams An Array of parameters to pass the onCompleteAll function when all the tweens have completed.
		 * @return Array of TweenMax instances
		 */
		public static function allFrom(targets:Array, duration:Number, vars:Object, stagger:Number=0, onCompleteAll:Function=null, onCompleteAllParams:Array=null):Array {
			if (vars.isGSVars) {  //to accommodate TweenMaxVars instances for strong data typing and code hinting
				vars = vars.vars;
			}
			vars.runBackwards = true;
			if (!("immediateRender" in vars)) {
				vars.immediateRender = true;
			}
			return allTo(targets, duration, vars, stagger, onCompleteAll, onCompleteAllParams);
		}
		
		/**
		 * Tweens multiple targets from a common set of starting values to a common set of ending values; exactly the same 
		 * as TweenMax.allTo(), but adds the ability to define the starting values. <b>NOTE</b>: Only put starting values
		 * in the fromVars parameter - all special properties for the tween (like onComplete, onUpdate, delay, etc.) belong
		 * in the toVars parameter. 
		 * 
		 * @param targets An Array of objects to tween.
		 * @param duration Duration (in seconds) of the tween (or in frames for frames-based tweens)
		 * @param fromVars An object containing the starting values of all the properties you'd like to have tweened.
		 * @param toVars An object containing the ending values of all the properties you'd like to have tweened.
		 * @param stagger Staggers the start time of each tween. For example, you might want to have 5 MovieClips move down from y:0 to y:100 while fading from alpha:0 to alpha:1, and stagger the start times slightly by 0.2 seconds, you could do: <code>TweenMax.allFromTo([mc1, mc2, mc3, mc4, mc5], 1, {y:0, alpha:0}, {y:100, alpha:1}, 0.2)</code>.
		 * @param onCompleteAll A function to call when all of the tweens have completed.
		 * @param onCompleteAllParams An Array of parameters to pass the onCompleteAll function when all the tweens have completed.
		 * @return Array of TweenMax instances
		 */
		public static function allFromTo(targets:Array, duration:Number, fromVars:Object, toVars:Object, stagger:Number=0, onCompleteAll:Function=null, onCompleteAllParams:Array=null):Array {
			if (toVars.isGSVars) {  //to accommodate TweenMaxVars instances for strong data typing and code hinting
				toVars = toVars.vars;
			}
			if (fromVars.isGSVars) {  //to accommodate TweenMaxVars instances for strong data typing and code hinting
				fromVars = fromVars.vars;
			}
			toVars.startAt = fromVars;
			if (fromVars.immediateRender) {
				toVars.immediateRender = true;
			}
			return allTo(targets, duration, toVars, stagger, onCompleteAll, onCompleteAllParams);
		}		
		
		/**
		 * Provides a simple way to call a function after a set amount of time (or frames). You can
		 * optionally pass any number of parameters to the function too. For example: <br /><br /><code>
		 * 
		 * 		TweenMax.delayedCall(1, myFunction, ["param1", 2]);<br />
		 * 		function myFunction(param1:String, param2:Number):void {<br />
		 *  		   trace("called myFunction and passed params: " + param1 + ", " + param2);<br />
		 * 		}<br /><br /></code>
		 * 
		 * @param delay Delay in seconds (or frames if useFrames is true) before the function should be called
		 * @param onComplete Function to call
		 * @param onCompleteParams An Array of parameters to pass the function.
		 * @return TweenMax instance
		 */
		public static function delayedCall(delay:Number, onComplete:Function, onCompleteParams:Array=null, useFrames:Boolean=false):TweenMax {
			return new TweenMax(onComplete, 0, {delay:delay, onComplete:onComplete, onCompleteParams:onCompleteParams, immediateRender:false, useFrames:useFrames, overwrite:0});
		}
		
		/**
		 * Gets all the tweens of a particular object.
		 *  
		 * @param target The target object whose tweens you want returned
		 * @return Array of tweens (could be TweenLite and/or TweenMax instances)
		 */
		public static function getTweensOf(target:Object):Array {
			var a:Array = masterList[target];
			var toReturn:Array = [];
			if (a) {
				var i:int = a.length;
				var cnt:int = 0;
				while (--i > -1) {
					if (!TweenLite(a[i]).gc) {
						toReturn[cnt++] = a[i];
					}
				}
			}
			return toReturn;
		}
		
		/**
		 * Determines whether or not a particular object is actively tweening. If a tween
		 * is paused or hasn't started yet, it doesn't count as active.
		 * 
		 * @param target Target object whose tweens you're checking
		 * @return Boolean value indicating whether or not any active tweens were found
		 */
		public static function isTweening(target:Object):Boolean {
			var a:Array = getTweensOf(target);
			var i:int = a.length;
			var tween:TweenLite;
			while (--i > -1) {
				tween = a[i];
				if ((tween.active || (tween.cachedStartTime == tween.timeline.cachedTime && tween.timeline.active))) {
					return true;
				}
			}
			return false;
		}
		
		/**
		 * Returns all tweens that are in the masterList. Tweens are automatically removed from the
		 * masterList when they complete and are not attached to a timeline that has 
		 * autoRemoveChildren set to true.
		 * 
		 * @return Array of TweenLite and/or TweenMax instances
		 */
		public static function getAllTweens():Array {
			var ml:Dictionary = masterList; //speeds things up slightly
			var cnt:int = 0;
			var toReturn:Array = [], a:Array, i:int;
			for each (a in ml) {
				i = a.length;
				while (--i > -1) {
					if (!TweenLite(a[i]).gc) {
						toReturn[cnt++] = a[i];
					}
				}
			}
			return toReturn;
		}
		
		/**
		 * Kills all tweens and/or delayedCalls/callbacks, optionally forcing them to completion first. The 
		 * various parameters provide a way to distinguish between delayedCalls and tweens, so if you want to 
		 * kill EVERYTHING (tweens and delayedCalls), you'd do:<br /><br /><code>
		 * 
		 * TweenMax.killAll(false, true, true);<br /><br /></code>
		 * 
		 * But if you want to kill only the tweens but allow the delayedCalls to continue, you'd do:<br /><br /><code>
		 * 
		 * TweenMax.killAll(false, true, false);<br /><br /></code>
		 * 
		 * And if you want to kill only the delayedCalls but not the tweens, you'd do:<br /><br /><code>
		 * 
		 * TweenMax.killAll(false, false, true);<br /></code>
		 *  
		 * @param complete Determines whether or not the tweens/delayedCalls/callbacks should be forced to completion before being killed.
		 * @param tweens If true, all tweens will be killed
		 * @param delayedCalls If true, all delayedCalls will be killed. TimelineMax callbacks are treated the same as delayedCalls.
		 */
		public static function killAll(complete:Boolean=false, tweens:Boolean=true, delayedCalls:Boolean=true):void {
			var a:Array = getAllTweens();
			var isDC:Boolean;  //is delayedCall
			var i:int = a.length;
			while (--i > -1) {
				isDC = (a[i].target == a[i].vars.onComplete);
				if (isDC == delayedCalls || isDC != tweens) {
					if (complete) {
						a[i].complete(false);
					} else {
						a[i].setEnabled(false, false);
					}
				}
			}
		}
		
		/**
		 * Kills all tweens of the children of a particular DisplayObjectContainer, optionally forcing them to completion first.
		 * 
		 * @param parent The DisplayObjectContainer whose children should no longer be affected by any tweens. 
		 * @param complete Determines whether or not the tweens should be forced to completion before being killed.
		 */
		public static function killChildTweensOf(parent:DisplayObjectContainer, complete:Boolean=false):void {
			var a:Array = getAllTweens();
			var curTarget:Object, curParent:DisplayObjectContainer;
			var i:int = a.length;
			while (--i > -1) {
				curTarget = a[i].target;
				if (curTarget is DisplayObject) {
					curParent = curTarget.parent;
					while (curParent) {
						if (curParent == parent) {
							if (complete) {
								a[i].complete(false);
							} else {
								a[i].setEnabled(false, false);
							}
						}
						curParent = curParent.parent;
					}
				}
			}
		}
		
		/**
		 * Pauses all tweens and/or delayedCalls/callbacks.
		 * 
		 * @param tweens If true, all tweens will be paused.
		 * @param delayedCalls If true, all delayedCalls will be paused. TimelineMax callbacks are treated the same as delayedCalls.
		 */
		public static function pauseAll(tweens:Boolean=true, delayedCalls:Boolean=true):void {
			changePause(true, tweens, delayedCalls);
		}
		
		/**
		 * Resumes all paused tweens and/or delayedCalls/callbacks.
		 * 
		 * @param tweens If true, all tweens will be resumed.
		 * @param delayedCalls If true, all delayedCalls will be resumed. TimelineMax callbacks are treated the same as delayedCalls.
		 */
		public static function resumeAll(tweens:Boolean=true, delayedCalls:Boolean=true):void {
			changePause(false, tweens, delayedCalls);
		}
		
		/**
		 * @private
		 * Changes the paused state of all tweens and/or delayedCalls/callbacks
		 * 
		 * @param pause Desired paused state
		 * @param tweens If true, all tweens will be affected.
		 * @param delayedCalls If true, all delayedCalls will be affected. TimelineMax callbacks are treated the same as delayedCalls.
		 */
		private static function changePause(pause:Boolean, tweens:Boolean=true, delayedCalls:Boolean=false):void {
			var a:Array = getAllTweens();
			var isDC:Boolean; //is delayedCall 
			var i:int = a.length;
			while (--i > -1) {
				isDC = (TweenLite(a[i]).target == TweenLite(a[i]).vars.onComplete);
				if (isDC == delayedCalls || isDC != tweens) {
					TweenCore(a[i]).paused = pause;
				}
			}
		}
		
	
//---- GETTERS / SETTERS ----------------------------------------------------------------------------------------------------------
		
		
		/** 
		 * Value between 0 and 1 indicating the progress of the tween according to its <code>duration</code> 
 		 * where 0 is at the beginning, 0.5 is halfway finished, and 1 is finished. <code>totalProgress</code>, 
 		 * by contrast, describes the overall progress according to the tween's <code>totalDuration</code> 
 		 * which includes repeats and repeatDelays (if there are any). For example, if a TweenMax instance 
		 * is set to repeat once, at the end of the first cycle <code>totalProgress</code> would only be 0.5 
		 * whereas <code>currentProgress</code> would be 1. If you tracked both properties over the course of the 
		 * tween, you'd see <code>currentProgress</code> go from 0 to 1 twice (once for each cycle) in the same
		 * time it takes the <code>totalProgress</code> property to go from 0 to 1 once.
		 **/
		public function get currentProgress():Number {
			return this.cachedTime / this.duration;
		}
		
		public function set currentProgress(n:Number):void {
			if (_cyclesComplete == 0) {
				setTotalTime(this.duration * n, false);
			} else {
				setTotalTime(this.duration * n + (_cyclesComplete * this.cachedDuration), false);
			}
		}
		
		/** 
		 * Value between 0 and 1 indicating the overall progress of the tween according to its <code>totalDuration</code>
 		 * where 0 is at the beginning, 0.5 is halfway finished, and 1 is finished. <code>currentProgress</code>, 
 		 * by contrast, describes the progress according to the tween's <code>duration</code> which does not
 		 * include repeats and repeatDelays. For example, if a TweenMax instance is set to repeat 
 		 * once, at the end of the first cycle <code>totalProgress</code> would only be 0.5 
		 * whereas <code>currentProgress</code> would be 1. If you tracked both properties over the course of the 
		 * tween, you'd see <code>currentProgress</code> go from 0 to 1 twice (once for each cycle) in the same
		 * time it takes the <code>totalProgress</code> property to go from 0 to 1 once.
		 **/
		public function get totalProgress():Number {
			return this.cachedTotalTime / this.totalDuration;
		}
		
		public function set totalProgress(n:Number):void {
			setTotalTime(this.totalDuration * n, false);
		}
		
		/**
		 * Most recently rendered time (or frame for frames-based timelines) according to the tween's 
		 * duration. <code>totalTime</code>, by contrast, is based on the <code>totalDuration</code> which includes repeats and repeatDelays.
		 * For example, if a TweenMax instance has a duration of 5 a repeat of 1 (meaning its 
		 * <code>totalDuration</code> is 10), at the end of the second cycle, <code>currentTime</code> would be 5 whereas <code>totalTime</code> 
		 * would be 10. If you tracked both properties over the course of the tween, you'd see <code>currentTime</code> 
		 * go from 0 to 5 twice (one for each cycle) in the same time it takes <code>totalTime</code> go from 0 to 10.
		 */
		override public function set currentTime(n:Number):void {
			if (_cyclesComplete == 0) {
				//no change needed
			} else if (this.yoyo && (_cyclesComplete % 2 == 1)) {
				n = (this.duration - n) + (_cyclesComplete * (this.cachedDuration + _repeatDelay));
			} else {
				n += (_cyclesComplete * (this.duration + _repeatDelay));
			}
			setTotalTime(n, false);
		}
		
		/**
		 * Duration of the tween in seconds (or frames for frames-based timelines) including any repeats
		 * or repeatDelays. <code>duration</code>, by contrast, does NOT include repeats and repeatDelays. 
		 **/
		override public function get totalDuration():Number {
			if (this.cacheIsDirty) {
				//instead of Infinity, we use 999999999999 so that we can accommodate reverses
				this.cachedTotalDuration = (_repeat == -1) ? 999999999999 : this.cachedDuration * (_repeat + 1) + (_repeatDelay * _repeat); 
				this.cacheIsDirty = false;
			}
			return this.cachedTotalDuration;
		}
		
		override public function set totalDuration(n:Number):void {
			if (_repeat == -1) {
				return;
			}
			this.duration = (n - (_repeat * _repeatDelay)) / (_repeat + 1);
		}
		
		/** Multiplier affecting the speed of the timeline where 1 is normal speed, 0.5 is half-speed, 2 is double speed, etc. **/
		public function get timeScale():Number {
			return this.cachedTimeScale;
		}
		
		public function set timeScale(n:Number):void {
			if (n == 0) { //can't allow zero because it'll throw the math off
				n = 0.0001;
			}
			var tlTime:Number = (this.cachedPauseTime || this.cachedPauseTime == 0) ? this.cachedPauseTime : this.timeline.cachedTotalTime;
			this.cachedStartTime = tlTime - ((tlTime - this.cachedStartTime) * this.cachedTimeScale / n);
			this.cachedTimeScale = n;
			setDirtyCache(false);
		}
		
		/** Number of times that the tween should repeat; -1 repeats indefinitely. **/
		public function get repeat():int {
			return _repeat;
		}
		
		public function set repeat(n:int):void {
			_repeat = n;
			setDirtyCache(true);
		}
		
		/** Amount of time in seconds (or frames for frames-based tweens) between repeats **/
		public function get repeatDelay():Number {
			return _repeatDelay;
		}
		
		public function set repeatDelay(n:Number):void {
			_repeatDelay = n;
			setDirtyCache(true);
		}
		
		/** Multiplier describing the speed of the root timelines where 1 is normal speed, 0.5 is half-speed, 2 is double speed, etc. The lowest globalTimeScale possible is 0.0001. **/
		public static function get globalTimeScale():Number {
			return (TweenLite.rootTimeline == null) ? 1 : TweenLite.rootTimeline.cachedTimeScale;
		}
		
		public static function set globalTimeScale(n:Number):void {
			if (n == 0) { //can't allow zero because it'll throw the math off
				n = 0.0001;
			}
			if (TweenLite.rootTimeline == null) {
				TweenLite.to({}, 0, {}); //forces initialization in case globalTimeScale is set before any tweens are created.
			}
			var tl:SimpleTimeline = TweenLite.rootTimeline;
			var curTime:Number = (getTimer() * 0.001)
			tl.cachedStartTime = curTime - ((curTime - tl.cachedStartTime) * tl.cachedTimeScale / n);
			tl = TweenLite.rootFramesTimeline;
			curTime = TweenLite.rootFrame;
			tl.cachedStartTime = curTime - ((curTime - tl.cachedStartTime) * tl.cachedTimeScale / n);
			TweenLite.rootFramesTimeline.cachedTimeScale = TweenLite.rootTimeline.cachedTimeScale = n;
		}
		
		
	}
}