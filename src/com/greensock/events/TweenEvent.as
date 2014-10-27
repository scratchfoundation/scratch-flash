package com.greensock.events {
	import flash.events.Event;
/**
 * Used for dispatching events from the GreenSock Tweening Platform. <br /><br />
 * 	  
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 */
	public class TweenEvent extends Event {
		/** @private **/
		public static const VERSION:Number = 1.1;
		public static const START:String = "start";
		public static const UPDATE:String = "change";
		public static const COMPLETE:String = "complete";
		public static const REVERSE_COMPLETE:String = "reverseComplete";
		public static const REPEAT:String = "repeat";
		public static const INIT:String = "init";
		
		public function TweenEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) {
			super(type, bubbles, cancelable);
		}
		
		public override function clone():Event {
			return new TweenEvent(this.type, this.bubbles, this.cancelable);
		}
	
	}
	
}