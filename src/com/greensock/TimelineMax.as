/**
 * VERSION: 1.698
 * DATE: 2012-03-29
 * AS3 (AS2 version is also available)
 * UPDATES AND DOCS AT: http://www.greensock.com/timelinemax/
 **/
package com.greensock {
	import com.greensock.core.*;
	import com.greensock.OverwriteManager;
	import com.greensock.events.TweenEvent;
	
	import flash.events.*;
/**
 * 	TimelineMax extends TimelineLite, offering exactly the same functionality plus useful 
 *  (but non-essential) features like AS3 event dispatching, repeat, repeatDelay, yoyo, 
 *  currentLabel, addCallback(), removeCallback(), tweenTo(), tweenFromTo(), getLabelAfter(), getLabelBefore(),
 * 	and getActive() (and probably more in the future). It is the ultimate sequencing tool. 
 *  Think of a TimelineMax instance like a virtual MovieClip timeline or a container where 
 *  you place tweens (or other timelines) over the course of time. You can:
 * 	
 * <ul>
 * 		<li> build sequences easily by adding tweens with the append(), prepend(), insert(), appendMultiple(), 
 * 			prependMultiple(), and insertMultiple() methods. Tweens can overlap as much as you want and you have 
 * 			complete control over where they get placed on the timeline.</li>
 * 
 * 		<li> add labels, play(), stop(), gotoAndPlay(), gotoAndStop(), restart(), tweenTo() and even reverse()! </li>
 * 		
 * 		<li> nest timelines within timelines as deeply as you want.</li>
 * 		
 * 		<li> set the progress of the timeline using its <code>currentProgress</code> property. For example, to skip to
 * 		  the halfway point, set <code>myTimeline.currentProgress = 0.5</code>.</li>
 * 		  
 * 		<li> tween the <code>currentTime</code>, <code>totalTime</code>, <code>currentProgress</code>, or <code>totalProgress</code> 
 * 		 property to fastforward/rewind the timeline. You could 
 * 		  even attach a slider to one of these properties to give the user the ability to drag 
 * 		  forwards/backwards through the whole timeline.</li>
 * 		  
 * 		<li> add onStart, onUpdate, onComplete, onReverseComplete, and/or onRepeat callbacks using the 
 * 		  constructor's <code>vars</code> object.</li>
 * 		
 * 		<li> speed up or slow down the entire timeline with its <code>timeScale</code> property. You can even tween
 * 		  this property to gradually speed up or slow down the timeline.</li>
 * 		  
 * 		<li> use the insertMultiple(), appendMultiple(), or prependMultiple() methods to create 
 * 			complex sequences including various alignment modes and staggering capabilities.  
 * 			Works great in conjunction with TweenMax.allTo() too. </li>
 * 		  
 * 		<li> base the timing on frames instead of seconds if you prefer. Please note, however, that
 * 		  the timeline's timing mode dictates its childrens' timing mode as well. </li>
 * 		
 * 		<li> kill the tweens of a particular object inside the timeline with killTweensOf() or get the tweens of an object
 * 		  with getTweensOf() or get all the tweens/timelines in the timeline with getChildren()</li>
 * 		  
 * 		<li> set the timeline to repeat any number of times or indefinitely. You can even set a delay
 * 		  between each repeat cycle and/or cause the repeat cycles to yoyo, appearing to reverse
 * 		  every other cycle. </li>
 * 		
 * 		<li> listen for START, UPDATE, REPEAT, REVERSE_COMPLETE, and COMPLETE events.</li>
 * 		
 * 		<li> get the active tweens in the timeline with getActive().</li>
 * 
 * 		<li> add callbacks (function calls) anywhere in the timeline that call a function of your choosing when 
 * 			the "virtual playhead" passes a particular spot.</li>
 * 		
 * 		<li> Get the <code>currentLabel</code> or find labels at various positions in the timeline
 * 			using getLabelAfter() and getLabelBefore()</li>
 * 	</ul>
 * 	
 * <b>EXAMPLE:</b><br /><br /><code>
 * 		
 * 		import com.greensock.~~;<br /><br />
 * 		
 * 		//create the timeline and add an onComplete call to myFunction when the timeline completes<br />
 * 		var myTimeline:TimelineMax = new TimelineMax({onComplete:myFunction});<br /><br />
 * 		
 * 		//add a tween<br />
 * 		myTimeline.append(new TweenLite(mc, 1, {x:200, y:100}));<br /><br />
 * 		
 * 		//add another tween at the end of the timeline (makes sequencing easy)<br />
 * 		myTimeline.append(new TweenLite(mc, 0.5, {alpha:0}));<br /><br />
 * 		
 * 		//repeat the entire timeline twice<br />
 * 		myTimeline.repeat = 2;<br /><br />
 * 		
 * 		//delay the repeat by 0.5 seconds each time.<br />
 * 		myTimeline.repeatDelay = 0.5;<br /><br />
 * 		
 * 		//pause the timeline (stop() works too)<br />
 * 		myTimeline.pause();<br /><br />
 * 		
 * 		//reverse it anytime...<br />
 * 		myTimeline.reverse();<br /><br />
 * 		
 * 		//Add a "spin" label 3-seconds into the timeline.<br />
 * 		myTimeline.addLabel("spin", 3);<br /><br />
 * 		
 * 		//insert a rotation tween at the "spin" label (you could also define the insert point as the time instead of a label)<br />
 * 		myTimeline.insert(new TweenLite(mc, 2, {rotation:"360"}), "spin"); <br /><br />
 * 		
 * 		//go to the "spin" label and play the timeline from there...<br />
 * 		myTimeline.gotoAndPlay("spin");<br /><br />
 * 
 * 		//call myCallbackwhen the "virtual playhead" travels past the 1.5-second point.
 * 		myTimeline.addCallback(myCallback, 1.5);
 * 		
 * 		//add a tween to the beginning of the timeline, pushing all the other existing tweens back in time<br />
 * 		myTimeline.prepend(new TweenMax(mc, 1, {tint:0xFF0000}));<br /><br />
 * 		
 * 		//nest another TimelineMax inside your timeline...<br />
 * 		var nestedTimeline:TimelineMax = new TimelineMax();<br />
 * 		nestedTimeline.append(new TweenLite(mc2, 1, {x:200}));<br />
 * 		myTimeline.append(nestedTimeline);<br /><br /></code>
 * 		
 * 		
 * 	<code>insertMultiple()</code> and <code>appendMultiple()</code> provide some very powerful sequencing tools as well, 
 *  allowing you to add an Array of tweens/timelines and optionally align them with <code>SEQUENCE</code> or <code>START</code> 
 *  modes, and even stagger them if you want. For example, to insert 3 tweens into the timeline, aligning their start times but 
 *  staggering them by 0.2 seconds, <br /><br /><code>
 * 	
 * 		myTimeline.insertMultiple([new TweenLite(mc, 1, {y:"100"}),
 * 								   new TweenLite(mc2, 1, {x:120}),
 * 								   new TweenLite(mc3, 1, {alpha:0.5})], 
 * 								   0, 
 * 								   TweenAlign.START, 
 * 								   0.2);</code><br /><br />
 * 								   
 * 	You can use the constructor's <code>vars</code> object to do all the setup too, like:<br /><br /><code>
 * 	
 * 		var myTimeline:TimelineMax = new TimelineMax({tweens:[new TweenLite(mc1, 1, {y:"100"}), TweenMax.to(mc2, 1, {tint:0xFF0000})], align:TweenAlign.SEQUENCE, onComplete:myFunction, repeat:2, repeatDelay:1});</code><br /><br />
 * 	
 * 	If that confuses you, don't worry. Just use the <code>append()</code>, <code>insert()</code>, and <code>prepend()</code> methods to build your
 * 	sequence. But power users will likely appreciate the quick, compact way they can set up sequences now. <br /><br />
 *  
 *
 * <b>NOTES:</b>
 * <ul>
 * 	<li> TimelineMax automatically inits the OverwriteManager class to prevent unexpected overwriting behavior in sequences.
 * 	  The default mode is <code>AUTO</code>, but you can set it to whatever you want with <code>OverwriteManager.init()</code>
 * 	 (see <a href="http://www.greensock.com/overwritemanager/">http://www.greensock.com/overwritemanager/</a>)</li>
 * 	<li> TimelineMax adds about 4.9k to your SWF (not including OverwriteManager).</li>
 * </ul>
 * 
 * <b>Copyright 2012, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 **/
	public class TimelineMax extends TimelineLite implements IEventDispatcher {
		/** @private **/
		public static const version:Number = 1.698;
		
		/** @private **/
		protected var _repeat:int;
		/** @private **/
		protected var _repeatDelay:Number;
		/** @private **/
		protected var _cyclesComplete:int;
		/** @private **/
		protected var _dispatcher:EventDispatcher;
		/** @private **/
		protected var _hasUpdateListener:Boolean;
		
		/** 
		 * Works in conjunction with the repeat property, determining the behavior of each cycle; when <code>yoyo</code> is true, 
		 * the timeline will go back and forth, appearing to reverse every other cycle (this has no affect on the <code>reversed</code> property though). 
		 * So if repeat is 2 and <code>yoyo</code> is false, it will look like: start - 1 - 2 - 3 - 1 - 2 - 3 - 1 - 2 - 3 - end. 
		 * But if repeat is 2 and <code>yoyo</code> is true, it will look like: start - 1 - 2 - 3 - 3 - 2 - 1 - 1 - 2 - 3 - end.  
		 **/
		 public var yoyo:Boolean;
		
		/**
		 * Constructor. <br /><br />
		 * 
		 * <b>SPECIAL PROPERTIES</b><br />
		 * The following special properties may be passed in via the constructor's vars parameter, like
		 * <code>new TimelineMax({paused:true, onComplete:myFunction, repeat:2, yoyo:true})</code> 
		 * 
		 * <ul>
		 * 	<li><b> delay : Number</b>				Amount of delay in seconds (or frames for frames-based timelines) before the timeline should begin.</li>
		 * 								
		 * 	<li><b> useFrames : Boolean</b>			If <code>useFrames</code> is set to true, the timeline's timing mode will be based on frames. 
		 * 											Otherwise, it will be based on seconds/time. NOTE: a TimelineLite's timing mode is 
		 * 											always determined by its parent timeline. </li>
		 * 
		 *  <li><b> paused : Boolean</b> 			Sets the initial paused state of the timeline (by default, timelines automatically begin playing immediately)</li>
		 * 
		 * 	<li><b> reversed : Boolean</b>			If true, the timeline will be reversed initially. This does NOT force it to the very end and start 
		 * 											playing backwards. It simply affects the orientation of the timeline, so if <code>reversed</code> is set to 
		 * 											true initially, it will appear not to play because it is already at the beginning. To cause it to
		 * 											play backwards from the end, set reversed to true and then set the <code>currentProgress</code> property to 1 immediately
		 * 											after creating the timeline.</li>
		 * 									
		 * 	<li><b> tweens : Array</b>				To immediately insert several tweens into the timeline, use the <code>tweens</code> special property
		 * 											to pass in an Array of TweenLite/TweenMax/TimelineLite/TimelineMax instances. You can use this in conjunction
		 * 											with the <code>align</code> and <code>stagger</code> special properties to set up complex sequences with minimal code.
		 * 											These values simply get passed to the <code>insertMultiple()</code> method.</li>
		 * 	
		 * 	<li><b> align : String</b>				Only used in conjunction with the <code>tweens</code> special property when multiple tweens are
		 * 											to be inserted immediately through the constructor. The value simply gets passed to the 
		 * 											<code>insertMultiple()</code> method. The default is <code>TweenAlign.NORMAL</code>. Options are:
		 * 											<ul>
		 * 												<li><b> TweenAlign.SEQUENCE:</b> aligns the tweens one-after-the-other in a sequence</li>
		 * 												<li><b> TweenAlign.START:</b> aligns the start times of all of the tweens (ignores delays)</li>
		 * 												<li><b> TweenAlign.NORMAL:</b> aligns the start times of all the tweens (honors delays)</li>
		 * 											</ul>The <code>align</code> special property does <b>not</b> force all child tweens/timelines to maintain
		 * 											relative positioning, so for example, if you use TweenAlign.SEQUENCE and then later change the duration
		 * 											of one of the nested tweens, it does <b>not</b> force all subsequent timelines to change their position
		 * 											on the timeline. The <code>align</code> special property only affects the alignment of the tweens that are
		 * 											initially placed into the timeline through the <code>tweens</code> special property of the <code>vars</code> object.</li>
		 * 										
		 * 	<li><b> stagger : Number</b>			Only used in conjunction with the <code>tweens</code> special property when multiple tweens are
		 * 											to be inserted immediately. It staggers the tweens by a set amount of time (in seconds) (or
		 * 											in frames if <code>useFrames</code> is true). For example, if the stagger value is 0.5 and the <code>align</code> 
		 * 											property is set to <code>TweenAlign.START</code>, the second tween will start 0.5 seconds after the first one 
		 * 											starts, then 0.5 seconds later the third one will start, etc. If the align property is 
		 * 											<code>TweenAlign.SEQUENCE</code>, there would be 0.5 seconds added between each tween. This value simply gets 
		 * 											passed to the <code>insertMultiple()</code> method. Default is 0.</li>
		 * 	
		 * 	<li><b> onStart : Function</b>			A function that should be called when the timeline begins (the <code>currentProgress</code> won't necessarily
		 * 											be zero when onStart is called. For example, if the timeline is created and then its <code>currentProgress</code>
		 * 											property is immediately set to 0.5 or if its <code>currentTime</code> property is set to something other than zero,
		 * 											onStart will still get fired because it is the first time the timeline is getting rendered.)</li>
		 * 	
		 * 	<li><b> onStartParams : Array</b>		An Array of parameters to pass the onStart function.</li>
		 * 	
		 * 	<li><b> onUpdate : Function</b>			A function that should be called every time the timeline's time/position is updated 
		 * 											(on every frame while the timeline is active)</li>
		 * 	
		 * 	<li><b> onUpdateParams : Array</b>		An Array of parameters to pass the onUpdate function</li>
		 * 	
		 * 	<li><b> onComplete : Function</b>		A function that should be called when the timeline has finished </li>
		 * 	
		 * 	<li><b> onCompleteParams : Array</b>	An Array of parameters to pass the onComplete function</li>
		 * 	
		 * 	<li><b> onReverseComplete : Function</b> A function that should be called when the timeline has reached its starting point again after having been reversed </li>
		 * 	
		 * 	<li><b> onReverseCompleteParams : Array</b> An Array of parameters to pass the onReverseComplete functions</li>
		 *  
		 * 	<li><b> onRepeat : Function</b>			A function that should be called every time the timeline repeats </li>
		 * 	
		 * 	<li><b> onRepeatParams : Array</b>		An Array of parameters to pass the onRepeat function</li>
		 * 	
		 * 	<li><b> autoRemoveChildren : Boolean</b> If autoRemoveChildren is set to true, as soon as child tweens/timelines complete,
		 * 											they will automatically get killed/removed. This is normally undesireable because
		 * 											it prevents going backwards in time (like if you want to reverse() or set the 
		 * 											<code>currentProgress</code> value to a lower value, etc.). It can, however, improve speed and memory
		 * 											management. TweenLite's root timelines use <code>autoRemoveChildren:true</code>.</li>
		 * 
		 * 	<li><b> repeat : int</b>				Number of times that the timeline should repeat. To repeat indefinitely, use -1.</li>
		 * 	
		 * 	<li><b> repeatDelay : Number</b>		Amount of time in seconds (or frames for frames-based timelines) between repeats.</li>
		 * 	
		 * 	<li><b> yoyo : Boolean</b> 				Works in conjunction with the repeat property, determining the behavior of each 
		 * 											cycle. When <code>yoyo</code> is true, the timeline will go back and forth, appearing to reverse 
		 * 											every other cycle (this has no affect on the <code>reversed</code> property though). So if repeat is
		 * 											2 and yoyo is false, it will look like: start - 1 - 2 - 3 - 1 - 2 - 3 - 1 - 2 - 3 - end. But 
		 * 											if repeat is 2 and yoyo is true, it will look like: start - 1 - 2 - 3 - 3 - 2 - 1 - 1 - 2 - 3 - end. </li>
		 * 									
		 * 	<li><b> onStartListener : Function</b>	A function to which the TimelineMax instance should dispatch a TweenEvent when it begins.
		 * 	  										This is the same as doing <code>myTimeline.addEventListener(TweenEvent.START, myFunction);</code></li>
		 * 	
		 * 	<li><b> onUpdateListener : Function</b>	A function to which the TimelineMax instance should dispatch a TweenEvent every time it 
		 * 											updates values.	This is the same as doing <code>myTimeline.addEventListener(TweenEvent.UPDATE, myFunction);</code></li>
		 * 	  
		 * 	<li><b> onCompleteListener : Function</b>	A function to which the TimelineMax instance should dispatch a TweenEvent when it completes.
		 * 	  											This is the same as doing <code>myTimeline.addEventListener(TweenEvent.COMPLETE, myFunction);</code></li>
		 * 	</ul>
		 * 
		 * @param vars optionally pass in special properties like useFrames, onComplete, onCompleteParams, onUpdate, onUpdateParams, onStart, onStartParams, tweens, align, stagger, delay, autoRemoveChildren, onCompleteListener, onStartListener, onUpdateListener, repeat, repeatDelay, and/or yoyo.
		 */
		public function TimelineMax(vars:Object=null) {
			super(vars);
			_repeat = (this.vars.repeat) ? Number(this.vars.repeat) : 0;
			_repeatDelay = (this.vars.repeatDelay) ? Number(this.vars.repeatDelay) : 0;
			_cyclesComplete = 0;
			this.yoyo = Boolean(this.vars.yoyo == true);
			this.cacheIsDirty = true;
			if (this.vars.onCompleteListener != null || this.vars.onUpdateListener != null || this.vars.onStartListener != null || this.vars.onRepeatListener != null || this.vars.onReverseCompleteListener != null) {
				initDispatcher();
			}
		}
		
		/**
		 * If you want a function to be called at a particular time or label, use addCallback. When you add
		 * a callback, it is technically considered a zero-duration tween, so if you getChildren() there will be
		 * a tween returned for each callback. You can discern a callback from other tweens by the fact that
		 * their target is a function and the duration is zero. 
		 * 
		 * @param function the function to be called
		 * @param timeOrLabel the time in seconds (or frames for frames-based timelines) or label at which the callback should be inserted. For example, myTimeline.addCallback(myFunction, 3) would call myFunction() 3-seconds into the timeline, and myTimeline.addCallback(myFunction, "myLabel") would call it at the "myLabel" label.
		 * @param params an Array of parameters to pass the callback
		 * @return TweenLite instance
		 */
		public function addCallback(callback:Function, timeOrLabel:*, params:Array=null):TweenLite {
			var cb:TweenLite = new TweenLite(callback, 0, {onComplete:callback, onCompleteParams:params, overwrite:0, immediateRender:false});
			insert(cb, timeOrLabel);
			return cb;
		}
		
		/**
		 * Removes a callback from a particular time or label. If timeOrLabel is null, all callbacks of that
		 * particular function are removed from the timeline.
		 * 
		 * @param function callback function to be removed
		 * @param timeOrLabel the time in seconds (or frames for frames-based timelines) or label from which the callback should be removed. For example, <code>myTimeline.removeCallback(myFunction, 3)</code> would remove the callback from 3-seconds into the timeline, and <code>myTimeline.removeCallback(myFunction, "myLabel")</code> would remove it from the "myLabel" label, and <code>myTimeline.removeCallback(myFunction, null)</code> would remove ALL callbacks of that function regardless of where they are on the timeline.
		 * @return true if any callbacks were successfully found and removed. false otherwise.
		 */
		public function removeCallback(callback:Function, timeOrLabel:*=null):Boolean {
			if (timeOrLabel == null) {
				return killTweensOf(callback, false);
			} else {
				if (typeof(timeOrLabel) == "string") {
					if (!(timeOrLabel in _labels)) {
						return false;
					}
					timeOrLabel = _labels[timeOrLabel];
				}
				var a:Array = getTweensOf(callback, false), success:Boolean;
				var i:int = a.length;
				while (--i > -1) {
					if (a[i].cachedStartTime == timeOrLabel) {
						remove(a[i] as TweenCore);
						success = true;
					}
				}
				return success;
			}
		}
		
		/**
		 * Creates a linear tween that essentially scrubs the playhead to a particular time or label and then stops. For 
		 * example, to make the TimelineMax play to the "myLabel2" label, simply do: <br /><br /><code>
		 * 
		 * myTimeline.tweenTo("myLabel2"); <br /><br /></code>
		 * 
		 * If you want advanced control over the tween, like adding an onComplete or changing the ease or adding a delay, 
		 * just pass in a vars object with the appropriate properties. For example, to tween to the 5-second point on the 
		 * timeline and then call a function named <code>myFunction</code> and pass in a parameter that's references this 
		 * TimelineMax and use a Strong.easeOut ease, you'd do: <br /><br /><code>
		 * 
		 * myTimeline.tweenTo(5, {onComplete:myFunction, onCompleteParams:[myTimeline], ease:Strong.easeOut});<br /><br /></code>
		 * 
		 * Remember, this method simply creates a TweenLite instance that tweens the <code>currentTime</code> property of your timeline. 
		 * So you can store a reference to that tween if you want, and you can kill() it anytime. Also note that <code>tweenTo()</code>
		 * does <b>NOT</b> affect the timeline's <code>reversed</code> property. So if your timeline is oriented normally
		 * (not reversed) and you tween to a time/label that precedes the current time, it will appear to go backwards
		 * but the <code>reversed</code> property will <b>not</b> change to <code>true</code>. Also note that <code>tweenTo()</code>
		 * pauses the timeline immediately before tweening its <code>currentTime</code> property, and it stays paused after the tween completes.
		 * If you need to resume playback, you could always use an onComplete to call the <code>resume()</code> method.<br /><br />
		 * 
		 * If you plan to sequence multiple playhead tweens one-after-the-other, it is typically better to use 
		 * <code>tweenFromTo()</code> so that you can define the starting point and ending point, allowing the 
		 * duration to be accurately determined immediately. 
		 * 
		 * @see #tweenFromTo()
		 * @param timeOrLabel The destination time in seconds (or frame if the timeline is frames-based) or label to which the timeline should play. For example, myTimeline.tweenTo(5) would play from wherever the timeline is currently to the 5-second point whereas myTimeline.tweenTo("myLabel") would play to wherever "myLabel" is on the timeline.
		 * @param vars An optional vars object that will be passed to the TweenLite instance. This allows you to define an onComplete, ease, delay, or any other TweenLite special property. onInit is the only special property that is not available (tweenTo() sets it internally)
		 * @return TweenLite instance that handles tweening the timeline to the desired time/label.
		 */
		public function tweenTo(timeOrLabel:*, vars:Object=null):TweenLite {
			var varsCopy:Object = {ease:easeNone, overwrite:2, useFrames:this.useFrames, immediateRender:false};
			for (var p:String in vars) {
				varsCopy[p] = vars[p];
			}
			varsCopy.onInit = onInitTweenTo;
			varsCopy.onInitParams = [null, this, NaN];
			varsCopy.currentTime = parseTimeOrLabel(timeOrLabel);
			var tl:TweenLite = new TweenLite(this, (Math.abs(Number(varsCopy.currentTime) - this.cachedTime) / this.cachedTimeScale) || 0.001, varsCopy);
			tl.vars.onInitParams[0] = tl;
			return tl;
		}
		
		/**
		 * Creates a linear tween that essentially scrubs the playhead from a particular time or label to another 
		 * time or label and then stops. If you plan to sequence multiple playhead tweens one-after-the-other, 
		 * <code>tweenFromTo()</code> is better to use than <code>tweenTo()</code> because it allows the duration 
		 * to be determined immediately, ensuring that subsequent tweens that are appended to a sequence are 
		 * positioned appropriately. For example, to make the TimelineMax play from the label "myLabel1" to the "myLabel2" 
		 * label, and then from "myLabel2" back to the beginning (a time of 0), simply do: <br /><br /><code>
		 * 
		 * var playheadTweens:TimelineMax = new TimelineMax(); <br />
		 * playheadTweens.append( myTimeline.tweenFromTo("myLabel1", "myLabel2") );<br />
		 * playheadTweens.append( myTimeline.tweenFromTo("myLabel2", 0); <br /><br /></code>
		 * 
		 * If you want advanced control over the tween, like adding an onComplete or changing the ease or adding a delay, 
		 * just pass in a vars object with the appropriate properties. For example, to tween from the start (0) to the 
		 * 5-second point on the timeline and then call a function named <code>myFunction</code> and pass in a parameter 
		 * that's references this TimelineMax and use a Strong.easeOut ease, you'd do: <br /><br /><code>
		 * 
		 * myTimeline.tweenFromTo(0, 5, {onComplete:myFunction, onCompleteParams:[myTimeline], ease:Strong.easeOut});<br /><br /></code>
		 * 
		 * Remember, this method simply creates a TweenLite instance that tweens the <code>currentTime</code> property of your timeline. 
		 * So you can store a reference to that tween if you want, and you can <code>kill()</code> it anytime. Also note that <code>tweenFromTo()</code>
		 * does <b>NOT</b> affect the timeline's <code>reversed</code> property. So if your timeline is oriented normally
		 * (not reversed) and you tween to a time/label that precedes the current time, it will appear to go backwards
		 * but the <code>reversed</code> property will <b>not</b> change to <code>true</code>. Also note that <code>tweenFromTo()</code>
		 * pauses the timeline immediately before tweening its <code>currentTime</code> property, and it stays paused after the tween completes.
		 * If you need to resume playback, you could always use an onComplete to call the <code>resume()</code> method.
		 * 
		 * @see #tweenTo()
		 * @param fromTimeOrLabel The beginning time in seconds (or frame if the timeline is frames-based) or label from which the timeline should play. For example, <code>myTimeline.tweenTo(0, 5)</code> would play from 0 (the beginning) to the 5-second point whereas <code>myTimeline.tweenFromTo("myLabel1", "myLabel2")</code> would play from "myLabel1" to "myLabel2".
		 * @param toTimeOrLabel The destination time in seconds (or frame if the timeline is frames-based) or label to which the timeline should play. For example, <code>myTimeline.tweenTo(0, 5)</code> would play from 0 (the beginning) to the 5-second point whereas <code>myTimeline.tweenFromTo("myLabel1", "myLabel2")</code> would play from "myLabel1" to "myLabel2".
		 * @param vars An optional vars object that will be passed to the TweenLite instance. This allows you to define an onComplete, ease, delay, or any other TweenLite special property. onInit is the only special property that is not available (<code>tweenFromTo()</code> sets it internally)
		 * @return TweenLite instance that handles tweening the timeline between the desired times/labels.
		 */
		public function tweenFromTo(fromTimeOrLabel:*, toTimeOrLabel:*, vars:Object=null):TweenLite {
			var tl:TweenLite = tweenTo(toTimeOrLabel, vars);
			tl.vars.onInitParams[2] = parseTimeOrLabel(fromTimeOrLabel);
			tl.duration = Math.abs(Number(tl.vars.currentTime) - tl.vars.onInitParams[2]) / this.cachedTimeScale;
			return tl;
		}
		
		/** @private **/
		private static function onInitTweenTo(tween:TweenLite, timeline:TimelineMax, fromTime:Number):void {
			timeline.paused = true;
			if (!isNaN(fromTime)) {
				timeline.currentTime = fromTime;
			}
			if (tween.vars.currentTime != timeline.currentTime) { //don't make the duration zero - if it's supposed to be zero, don't worry because it's already initting the tween and will complete immediately, effectively making the duration zero anyway. If we make duration zero, the tween won't run at all.
				tween.duration = Math.abs(Number(tween.vars.currentTime) - timeline.currentTime) / timeline.cachedTimeScale;
			}
		}
		
		/** @private **/
		private static function easeNone(t:Number, b:Number, c:Number, d:Number):Number {
			return t / d;
		}
		
		
		/** @private **/
		override public function renderTime(time:Number, suppressEvents:Boolean=false, force:Boolean=false):void {
			if (this.gc) {
				this.setEnabled(true, false);
			} else if (!this.active && !this.cachedPaused) {
				this.active = true; //so that if the user renders a tween (as opposed to the timeline rendering it), the timeline is forced to re-render and align it with the proper time/frame on the next rendering cycle. Maybe the tween already finished but the user manually re-renders it as halfway done.
			}
			var totalDur:Number = (this.cacheIsDirty) ? this.totalDuration : this.cachedTotalDuration, prevTime:Number = this.cachedTime, prevTotalTime:Number = this.cachedTotalTime, prevStart:Number = this.cachedStartTime, prevTimeScale:Number = this.cachedTimeScale, tween:TweenCore, isComplete:Boolean, rendered:Boolean, repeated:Boolean, next:TweenCore, dur:Number, prevPaused:Boolean = this.cachedPaused;
			if (time >= totalDur) {
				if ((prevTotalTime != totalDur || this.cachedDuration == 0) && _rawPrevTime != time) {
					this.cachedTotalTime = totalDur;
					if (!this.cachedReversed && this.yoyo && _repeat % 2 != 0) {
						this.cachedTime = 0;
						forceChildrenToBeginning(0, suppressEvents);
					} else {
						this.cachedTime = this.cachedDuration;
						forceChildrenToEnd(this.cachedDuration, suppressEvents);
					}
					isComplete = !this.hasPausedChild() && !this.cachedReversed;
					rendered = true;
					if (this.cachedDuration == 0 && isComplete && (time == 0 || _rawPrevTime < 0)) { //In order to accommodate zero-duration timelines, we must discern the momentum/direction of time in order to render values properly when the "playhead" goes past 0 in the forward direction or lands directly on it, and also when it moves past it in the backward direction (from a postitive time to a negative time).
						force = true;
					}
				}
				
			} else if (time <= 0) {
				if (time < 0) {
					this.active = false; 
					if (this.cachedDuration == 0 && _rawPrevTime > 0) { //In order to accommodate zero-duration timelines, we must discern the momentum/direction of time in order to render values properly when the "playhead" goes past 0 in the forward direction or lands directly on it, and also when it moves past it in the backward direction (from a postitive time to a negative time).
						force = true;
						isComplete = true;
					}
				} else if (time == 0 && !this.initted) {
					force = true;
				}
				if (prevTotalTime != 0 && _rawPrevTime != time) {
					this.cachedTotalTime = 0;
					this.cachedTime = 0;
					forceChildrenToBeginning(0, suppressEvents);
					rendered = true;
					if (this.cachedReversed) {
						isComplete = true;
					}
				}
			} else {
				this.cachedTotalTime = this.cachedTime = time;
			}
			_rawPrevTime = time;
			
			if (_repeat != 0) {
				var cycleDuration:Number = this.cachedDuration + _repeatDelay;
				var prevCycles:int = _cyclesComplete;
				if ((_cyclesComplete = (this.cachedTotalTime / cycleDuration) >> 0) == (this.cachedTotalTime / cycleDuration) && _cyclesComplete != 0) {
					_cyclesComplete--; //otherwise when rendered exactly at the end time, it will act as though it is repeating (at the beginning)
				}
				repeated = Boolean(prevCycles != _cyclesComplete);
				
				if (isComplete) {
					if (this.yoyo && _repeat % 2) {
						this.cachedTime = 0;
					}
				} else if (time > 0) {
					this.cachedTime = this.cachedTotalTime - (_cyclesComplete * cycleDuration); //originally this.cachedTotalTime % cycleDuration but floating point errors caused problems, so I normalized it. (4 % 0.8 should be 0 but Flash reports it as 0.79999999!)
					
					if (this.yoyo && _cyclesComplete % 2) {
						this.cachedTime = this.cachedDuration - this.cachedTime;
					} else if (this.cachedTime >= this.cachedDuration) {
						this.cachedTime = this.cachedDuration;
					}
					if (this.cachedTime < 0) {
						this.cachedTime = 0;
					}
				} else {
					_cyclesComplete = 0;
				}
				
				if (repeated && !isComplete && (this.cachedTotalTime != prevTotalTime || force)) {
					
					/*
					  make sure children at the end/beginning of the timeline are rendered properly. If, for example, 
					  a 3-second long timeline rendered at 2.9 seconds previously, and now renders at 3.2 seconds (which
					  would get transated to 2.8 seconds if the timeline yoyos or 0.2 seconds if it just repeats), there
					  could be a callback or a short tween that's at 2.95 or 3 seconds in which wouldn't render. So 
					  we need to push the timeline to the end (and/or beginning depending on its yoyo value).
					*/
					
					var forward:Boolean = Boolean(!this.yoyo || (_cyclesComplete % 2 == 0));
					var prevForward:Boolean = Boolean(!this.yoyo || (prevCycles % 2 == 0));
					var wrap:Boolean = Boolean(forward == prevForward);
					if (prevCycles > _cyclesComplete) {
						prevForward = !prevForward;
					}
					
					if (prevForward) {
						prevTime = forceChildrenToEnd(this.cachedDuration, suppressEvents);
						if (wrap) {
							prevTime = forceChildrenToBeginning(0, true);
						}
					} else {
						prevTime = forceChildrenToBeginning(0, suppressEvents);
						if (wrap) {
							prevTime = forceChildrenToEnd(this.cachedDuration, true);
						}
					}
					rendered = false;
				}
				
			}
			
			if (this.cachedTime == prevTime && !force) {
				return;
			} else if (!this.initted) {
				this.initted = true;
			}
			
			if (prevTotalTime == 0 && this.cachedTotalTime != 0 && !suppressEvents) {
				if (this.vars.onStart) {
					this.vars.onStart.apply(null, this.vars.onStartParams);
				}
				if (_dispatcher) {
					_dispatcher.dispatchEvent(new TweenEvent(TweenEvent.START));
				}
			}
			
			if (rendered) {
				//already rendered, so ignore
			} else if (this.cachedTime > prevTime) {
				tween = _firstChild;
				while (tween) {
					next = tween.nextNode; //record it here because the value could change after rendering...
					if (this.cachedPaused && !prevPaused) { //in case a tween pauses the timeline when rendering
						break;
					} else if (tween.active || (!tween.cachedPaused && tween.cachedStartTime <= this.cachedTime && !tween.gc)) {
						
						if (!tween.cachedReversed) {
							tween.renderTime((this.cachedTime - tween.cachedStartTime) * tween.cachedTimeScale, suppressEvents, false);
						} else {
							dur = (tween.cacheIsDirty) ? tween.totalDuration : tween.cachedTotalDuration;
							tween.renderTime(dur - ((this.cachedTime - tween.cachedStartTime) * tween.cachedTimeScale), suppressEvents, false);
						}
						
					}
					
					tween = next;
				}
			} else {
				tween = _lastChild;
				while (tween) {
					next = tween.prevNode; //record it here because the value could change after rendering...
					if (this.cachedPaused && !prevPaused) { //in case a tween pauses the timeline when rendering
						break;
					} else if (tween.active || (!tween.cachedPaused && tween.cachedStartTime <= prevTime && !tween.gc)) {
						
						if (!tween.cachedReversed) {
							tween.renderTime((this.cachedTime - tween.cachedStartTime) * tween.cachedTimeScale, suppressEvents, false);
						} else {
							dur = (tween.cacheIsDirty) ? tween.totalDuration : tween.cachedTotalDuration;
							tween.renderTime(dur - ((this.cachedTime - tween.cachedStartTime) * tween.cachedTimeScale), suppressEvents, false);
						}
						
					} 
					
					tween = next;
				}
			}
			if (_hasUpdate && !suppressEvents) {
				this.vars.onUpdate.apply(null, this.vars.onUpdateParams);
			}
			if (_hasUpdateListener && !suppressEvents) {
				_dispatcher.dispatchEvent(new TweenEvent(TweenEvent.UPDATE));
			}
			if (repeated && !suppressEvents) {
				if (this.vars.onRepeat) {
					this.vars.onRepeat.apply(null, this.vars.onRepeatParams);
				}
				if (_dispatcher) {
					_dispatcher.dispatchEvent(new TweenEvent(TweenEvent.REPEAT));
				}
			}
			if (isComplete && (prevStart == this.cachedStartTime || prevTimeScale != this.cachedTimeScale) && (totalDur >= this.totalDuration || this.cachedTime == 0)) { //if one of the tweens that was rendered altered this timeline's startTime (like if an onComplete reversed the timeline) or if it added more tweens to the timeline, we shouldn't run complete() because it probably isn't complete. If it is, don't worry, because whatever call altered the startTime would have called complete() if it was necessary at the new time. The only exception is the timeScale property.
				complete(true, suppressEvents);
			}
		}
		
		/**
		 * Forces the timeline to completion.
		 * 
		 * @param skipRender to skip rendering the final state of the timeline, set skipRender to true. 
		 * @param suppressEvents If true, no events or callbacks will be triggered for this render (like onComplete, onUpdate, onReverseComplete, etc.)
		 */
		override public function complete(skipRender:Boolean=false, suppressEvents:Boolean=false):void {
			super.complete(skipRender, suppressEvents);
			if (_dispatcher && !suppressEvents) {
				if (this.cachedReversed && this.cachedTotalTime == 0 && this.cachedDuration != 0) {
					_dispatcher.dispatchEvent(new TweenEvent(TweenEvent.REVERSE_COMPLETE));
				} else {
					_dispatcher.dispatchEvent(new TweenEvent(TweenEvent.COMPLETE));
				}
			}
		}
		
		/**
		 * Returns the tweens/timelines that are currently active in the timeline.
		 * 
		 * @param nested determines whether or not tweens and/or timelines that are inside nested timelines should be returned. If you only want the "top level" tweens/timelines, set this to false.
		 * @param tweens determines whether or not tweens (TweenLite and TweenMax instances) should be included in the results
		 * @param timelines determines whether or not timelines (TimelineLite and TimelineMax instances) should be included in the results
		 * @return an Array of active tweens/timelines
		 */
		public function getActive(nested:Boolean=true, tweens:Boolean=true, timelines:Boolean=false):Array {
			var a:Array = [], all:Array = getChildren(nested, tweens, timelines), i:int, tween:TweenCore;
			var l:int = all.length;
			var cnt:int = 0;
			for (i = 0; i < l; i += 1) {
				tween = all[i];
				//note: we cannot just check tween.active because timelines that contain paused children will continue to have "active" set to true even after the playhead passes their end point (technically a timeline can only be considered complete after all of its children have completed too, but paused tweens are...well...just waiting and until they're unpaused we don't know where their end point will be).
				if (!tween.cachedPaused && tween.timeline.cachedTotalTime >= tween.cachedStartTime && tween.timeline.cachedTotalTime < tween.cachedStartTime + tween.cachedTotalDuration / tween.cachedTimeScale && !OverwriteManager.getGlobalPaused(tween.timeline)) {
					a[cnt++] = all[i];
				}
			}
			return a;
		}
		
		/** @inheritDoc **/
		override public function invalidate():void {
			_repeat = (this.vars.repeat) ? Number(this.vars.repeat) : 0;
			_repeatDelay = (this.vars.repeatDelay) ? Number(this.vars.repeatDelay) : 0;
			this.yoyo = Boolean(this.vars.yoyo == true);
			if (this.vars.onCompleteListener != null || this.vars.onUpdateListener != null || this.vars.onStartListener != null || this.vars.onRepeatListener != null || this.vars.onReverseCompleteListener != null) {
				initDispatcher();
			}
			setDirtyCache(true);
			super.invalidate();
		}
		
		/**
		 * Returns the next label (if any) that occurs AFTER the time parameter. It makes no difference
		 * if the timeline is reversed. A label that is positioned exactly at the same time as the <code>time</code>
		 * parameter will be ignored. 
		 * 
		 * @param time Time after which the label is searched for. If you do not pass a time in, the currentTime will be used. 
		 * @return Name of the label that is after the time passed to getLabelAfter()
		 */
		public function getLabelAfter(time:Number=NaN):String {
			if (!time && time != 0) { //faster than isNan()
				time = this.cachedTime;
			}
			var labels:Array = getLabelsArray();
			var l:int = labels.length;
			for (var i:int = 0; i < l; i += 1) {
				if (labels[i].time > time) {
					return labels[i].name;
				}
			}
			return null;
		}
		
		/**
		 * Returns the previous label (if any) that occurs BEFORE the time parameter. It makes no difference
		 * if the timeline is reversed. A label that is positioned exactly at the same time as the <code>time</code>
		 * parameter will be ignored. 
		 * 
		 * @param time Time before which the label is searched for. If you do not pass a time in, the currentTime will be used. 
		 * @return Name of the label that is before the time passed to getLabelBefore()
		 */
		public function getLabelBefore(time:Number=NaN):String {
			if (!time && time != 0) { //faster than isNan()
				time = this.cachedTime;
			}
			var labels:Array = getLabelsArray();
			var i:int = labels.length;
			while (--i > -1) {
				if (labels[i].time < time) {
					return labels[i].name;
				}
			}
			return null;
		}
		
		/** @private Returns an Array of label objects, each with a "time" and "name" property, in the order that they occur in the timeline. **/
		protected function getLabelsArray():Array {
			var a:Array = [];
			for (var p:String in _labels) {
				a[a.length] = {time:_labels[p], name:p};
			}
			a.sortOn("time", Array.NUMERIC);
			return a;
		}
		

//---- EVENT DISPATCHING ----------------------------------------------------------------------------------------------------------
		
		/** @private **/
		protected function initDispatcher():void {
			if (_dispatcher == null) {
				_dispatcher = new EventDispatcher(this);
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
			if (_dispatcher != null) {
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
		
		
//---- GETTERS / SETTERS -------------------------------------------------------------------------------------------------------
		
		/** @inheritDoc **/
		override public function set currentProgress(n:Number):void {
			this.currentTime = this.duration * n;
		}
		
		/** 
		 * Value between 0 and 1 indicating the overall progress of the timeline according to its <code>totalDuration</code> 
 		 * where 0 is at the beginning, 0.5 is halfway finished, and 1 is finished. <code>currentProgress</code>, 
 		 * by contrast, describes the progress according to the timeline's duration which does not
 		 * include repeats and repeatDelays. For example, if a TimelineMax instance is set 
 		 * to repeat once, at the end of the first cycle <code>totalProgress</code> would only be 0.5 
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
		 * Duration of the timeline in seconds (or frames for frames-based timelines) including any repeats
		 * or repeatDelays. "duration", by contrast, does NOT include repeats and repeatDelays.
		 **/
		override public function get totalDuration():Number {
			if (this.cacheIsDirty) {
				var temp:Number = super.totalDuration; //just forces refresh
				//Instead of Infinity, we use 999999999999 so that we can accommodate reverses.
				this.cachedTotalDuration = (_repeat == -1) ? 999999999999 : this.cachedDuration * (_repeat + 1) + (_repeatDelay * _repeat);
			}
			return this.cachedTotalDuration;
		}
		
		/** @private **/
		override public function set currentTime(n:Number):void {
			if (_cyclesComplete == 0) {
				setTotalTime(n, false);
			} else if (this.yoyo && (_cyclesComplete % 2 == 1)) {
				setTotalTime((this.duration - n) + (_cyclesComplete * (this.cachedDuration + _repeatDelay)), false);
			} else {
				setTotalTime(n + (_cyclesComplete * (this.duration + _repeatDelay)), false);
			}
		}
		
		/** Number of times that the timeline should repeat; -1 repeats indefinitely. **/
		public function get repeat():int {
			return _repeat;
		}
		
		public function set repeat(n:int):void {
			_repeat = n;
			setDirtyCache(true);
		}
		
		/** Amount of time in seconds (or frames for frames-based timelines) between repeats **/
		public function get repeatDelay():Number {
			return _repeatDelay;
		}
		
		public function set repeatDelay(n:Number):void {
			_repeatDelay = n;
			setDirtyCache(true);
		}
		
		/** The closest label that is at or before the current time. **/
		public function get currentLabel():String {
			return getLabelBefore(this.cachedTime + 0.00000001);
		}
		
	}
}