/**
 * VERSION: 1.04
 * DATE: 2010-03-06
 * AS3
 * UPDATES AND DOCUMENTATION AT: http://blog.greensock.com/
 **/
 package com.greensock.layout {
/**
 * Provides constants for defining how objects should scale/stretch to fit within an area (like a <code>LiquidArea</code> or <code>AutoFitArea</code>). <br /><br /> 
 * 
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 */	
	public class ScaleMode {
		
		/** Stretches the object to fill the area completely in terms of both width and height. This mode does <b>NOT</b> concern itself with preserving the object's original aspect ratio (proportions). **/
		public static const STRETCH:String = "stretch";
		/** Stretches the object's width to fill the area horizontally, but does not affect its height **/
		public static const WIDTH_ONLY:String = "widthOnly";
		/** Stretches the object's height to fill the area vertically, but does not affect its width **/
		public static const HEIGHT_ONLY:String = "heightOnly";
		/** Scales the object proportionally to completely fill the area, allowing portions of it to exceed the bounds when its aspect ratio doesn't match the area's. For example, if the area is 100x50 and the DisplayObject is natively 200x200, it will scale it down to 100x100 meaning it will exceed the bounds of the area vertically. **/
		public static const PROPORTIONAL_OUTSIDE:String = "proportionalOutside";
		/** Scales the object proportionally to fit inside the area (its edges will never exceed the bounds of the area). For example, if the area is 100x50 and the DisplayObject is natively 200x200, it will scale it down to 50x50 meaning it will not fill the area horizontally, but it will vertically. **/
		public static const PROPORTIONAL_INSIDE:String = "proportionalInside";
		/** Does not scale the object at all **/
		public static const NONE:String = "none";
		
	}
}