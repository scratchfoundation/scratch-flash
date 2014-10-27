/**
 * VERSION: 2.1
 * DATE: 2009-09-12
 * AS3
 * UPDATES AND DOCS AT: http://www.greensock.com
 **/
package com.greensock.core {
/**
 * @private
 * Stores information about an individual property tween. There is no reason to use this class directly - TweenLite, TweenMax, and some plugins use it internally.<br /><br />
 * 
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 */	
	final public class PropTween {
		/** Target object **/
		public var target:Object;
		/** Name of the property that is being tweened **/
		public var property:String;
		/** Starting value  **/
		public var start:Number;
		/** Amount to change (basically, the difference between the starting value and ending value) **/
		public var change:Number;
		/** Alias to associate with the PropTween which is typically the same as the property, but can be different, particularly for plugins. **/
		public var name:String;
		/** Priority in the rendering queue. The lower the value the later it will be tweened. Typically all PropTweens get a priority of 0, but some plugins must be rendered later (or earlier) **/
		public var priority:int;
		/** If the target of the PropTween is a TweenPlugin, isPlugin should be true. **/
		public var isPlugin:Boolean;
		/** Next PropTween in the linked list **/
		public var nextNode:PropTween;
		/** Previous PropTween in the linked list **/
		public var prevNode:PropTween;
		
		/**
		 * Constructor
		 * 
		 * @param target Target object
		 * @param property Name of the property that is being tweened
		 * @param start Starting value
		 * @param change Amount to change (basically, the difference between the starting value and ending value)
		 * @param name Alias to associate with the PropTween which is typically the same as the property, but can be different, particularly for plugins.
		 * @param isPlugin If the target of the PropTween is a TweenPlugin, isPlugin should be true.
		 * @param nextNode Next PropTween in the linked list
		 * @param priority Priority in the rendering queue. The lower the value the later it will be tweened. Typically all PropTweens get a priority of 0, but some plugins must be rendered later (or earlier)
		 */
		public function PropTween(target:Object, property:String, start:Number, change:Number, name:String, isPlugin:Boolean, nextNode:PropTween=null, priority:int=0) {
			this.target = target;
			this.property = property;
			this.start = start;
			this.change = change;
			this.name = name;
			this.isPlugin = isPlugin;
			if (nextNode) {
				nextNode.prevNode = this;
				this.nextNode = nextNode;
			}
			this.priority = priority;
		}
	}
}