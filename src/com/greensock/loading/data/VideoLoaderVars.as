/**
 * VERSION: 1.24
 * DATE: 2011-11-03
 * AS3
 * UPDATES AND DOCS AT: http://www.greensock.com/loadermax/
 **/
package com.greensock.loading.data {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
/**
 * Can be used instead of a generic Object to define the <code>vars</code> parameter of a VideoLoader's constructor. <br /><br />	
 * 
 * There are 2 primary benefits of using a VideoLoaderVars instance to define your VideoLoader variables:
 *  <ol>
 *		<li> In most code editors, code hinting will be activated which helps remind you which special properties are available in VideoLoader</li>
 *		<li> It enables strict data typing for improved debugging (ensuring, for example, that you don't define a Boolean value for <code>onComplete</code> where a Function is expected).</li>
 *  </ol><br />
 * 
 * The down side, of course, is that the code is more verbose and the VideoLoaderVars class adds slightly more kb to your swf.
 *
 * <b>USAGE:</b><br /><br />
 * Note that each method returns the VideoLoaderVars instance, so you can reduce the lines of code by method chaining (see example below).<br /><br />
 *	
 * <b>Without VideoLoaderVars:</b><br /><code>
 * new VideoLoader("video.flv", {name:"video", estimatedBytes:111500, container:this, width:200, height:100, onComplete:completeHandler, onProgress:progressHandler})</code><br /><br />
 * 
 * <b>With VideoLoaderVars</b><br /><code>
 * new VideoLoader("video.flv", new VideoLoaderVars().name("video").estimatedBytes(111500).container(this).width(200).height(100).onComplete(completeHandler).onProgress(progressHandler))</code><br /><br />
 * 
 * <b>NOTES:</b><br />
 * <ul>
 *	<li> To get the generic vars object that VideoLoaderVars builds internally, simply access its "vars" property.
 * 		 In fact, if you want maximum backwards compatibility, you can tack ".vars" onto the end of your chain like this:<br /><code>
 * 		 new VideoLoader("video.flv", new VideoLoaderVars().name("video").estimatedBytes(111500).vars);</code></li>
 *	<li> Using VideoLoaderVars is completely optional. If you prefer the shorter synatax with the generic Object, feel
 * 		 free to use it. The purpose of this class is simply to enable code hinting and to allow for strict data typing.</li>
 * </ul>
 * 
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 */	 
	public class VideoLoaderVars {
		/** @private **/
		public static const version:Number = 1.23;
		
		/** @private **/
		protected var _vars:Object;
		
		/**
		 * Constructor 
		 * @param vars A generic Object containing properties that you'd like to add to this VideoLoaderVars instance.
		 */
		public function VideoLoaderVars(vars:Object=null) {
			_vars = {};
			if (vars != null) {
				for (var p:String in vars) {
					_vars[p] = vars[p];
				}
			}
		}
		
		/** @private **/
		protected function _set(property:String, value:*):VideoLoaderVars {
			if (value == null) {
				delete _vars[property]; //in case it was previously set
			} else {
				_vars[property] = value;
			}
			return this;
		}
		
		/**
		 * Adds a dynamic property to the vars object containing any value you want. This can be useful 
		 * in situations where you need to associate certain data with a particular loader. Just make sure
		 * that the property name is a valid variable name (starts with a letter or underscore, no special characters, etc.)
		 * and that it doesn't use a reserved property name like "name" or "onComplete", etc. 
		 * 
		 * For example, to set an "index" property to 5, do:
		 * 
		 * <code>prop("index", 5);</code>
		 * 
		 * @param property Property name
		 * @param value Value
		 */
		public function prop(property:String, value:*):VideoLoaderVars {
			return _set(property, value);
		}
		
		
//---- LOADERCORE PROPERTIES -----------------------------------------------------------------
		
		/** When <code>autoDispose</code> is <code>true</code>, the loader will be disposed immediately after it completes (it calls the <code>dispose()</code> method internally after dispatching its <code>COMPLETE</code> event). This will remove any listeners that were defined in the vars object (like onComplete, onProgress, onError, onInit). Once a loader is disposed, it can no longer be found with <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> - it is essentially destroyed but its content is not unloaded (you must call <code>unload()</code> or <code>dispose(true)</code> to unload its content). The default <code>autoDispose</code> value is <code>false</code>.**/
		public function autoDispose(value:Boolean):VideoLoaderVars {
			return _set("autoDispose", value);
		}
		
		/** A name that is used to identify the loader instance. This name can be fed to the <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> methods or traced at any time. Each loader's name should be unique. If you don't define one, a unique name will be created automatically, like "loader21". **/
		public function name(value:String):VideoLoaderVars {
			return _set("name", value);
		}
		
		/** A handler function for <code>LoaderEvent.CANCEL</code> events which are dispatched when loading is aborted due to either a failure or because another loader was prioritized or <code>cancel()</code> was manually called. Make sure your onCancel function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onCancel(value:Function):VideoLoaderVars {
			return _set("onCancel", value);
		}
		
		/** A handler function for <code>LoaderEvent.COMPLETE</code> events which are dispatched when the loader has finished loading successfully. Make sure your onComplete function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onComplete(value:Function):VideoLoaderVars {
			return _set("onComplete", value);
		}
		
		/** A handler function for <code>LoaderEvent.ERROR</code> events which are dispatched whenever the loader experiences an error (typically an IO_ERROR or SECURITY_ERROR). An error doesn't necessarily mean the loader failed, however - to listen for when a loader fails, use the <code>onFail</code> special property. Make sure your onError function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onError(value:Function):VideoLoaderVars {
			return _set("onError", value);
		}
		
		/** A handler function for <code>LoaderEvent.FAIL</code> events which are dispatched whenever the loader fails and its <code>status</code> changes to <code>LoaderStatus.FAILED</code>. Make sure your onFail function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onFail(value:Function):VideoLoaderVars {
			return _set("onFail", value);
		}
		
		/** A handler function for <code>LoaderEvent.HTTP_STATUS</code> events. Make sure your onHTTPStatus function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). You can determine the httpStatus code using the LoaderEvent's <code>target.httpStatus</code> (LoaderItems keep track of their <code>httpStatus</code> when possible, although certain environments prevent Flash from getting httpStatus information).**/
		public function onHTTPStatus(value:Function):VideoLoaderVars {
			return _set("onHTTPStatus", value);
		}
		
		/** A handler function for <code>LoaderEvent.INIT</code> events which will be called when the video's metaData has been received and the video is placed into the <code>ContentDisplay</code>. Make sure your onInit function accepts a single parameter of type <code>LoaderEvent</code> (com.greensock.events.LoaderEvent). **/
		public function onInit(value:Function):VideoLoaderVars {
			return _set("onInit", value);
		}
		
		/** A handler function for <code>LoaderEvent.IO_ERROR</code> events which will also call the onError handler, so you can use that as more of a catch-all whereas <code>onIOError</code> is specifically for LoaderEvent.IO_ERROR events. Make sure your onIOError function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onIOError(value:Function):VideoLoaderVars {
			return _set("onIOError", value);
		}
		
		/** A handler function for <code>LoaderEvent.OPEN</code> events which are dispatched when the loader begins loading. Make sure your onOpen function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).**/
		public function onOpen(value:Function):VideoLoaderVars {
			return _set("onOpen", value);
		}
		
		/** A handler function for <code>LoaderEvent.PROGRESS</code> events which are dispatched whenever the <code>bytesLoaded</code> changes. Make sure your onProgress function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). You can use the LoaderEvent's <code>target.progress</code> to get the loader's progress value or use its <code>target.bytesLoaded</code> and <code>target.bytesTotal</code>.**/
		public function onProgress(value:Function):VideoLoaderVars {
			return _set("onProgress", value);
		}
		
		/** LoaderMax supports <i>subloading</i>, where an object can be factored into a parent's loading progress. If you want LoaderMax to require this loader as part of its parent SWFLoader's progress, you must set the <code>requireWithRoot</code> property to your swf's <code>root</code>. For example, <code>vars.requireWithRoot = this.root;</code>. **/
		public function requireWithRoot(value:DisplayObject):VideoLoaderVars {
			return _set("requireWithRoot", value);
		}
		
		
//---- LOADERITEM PROPERTIES -------------------------------------------------------------	
		
		/** If you define an <code>alternateURL</code>, the loader will initially try to load from its original <code>url</code> and if it fails, it will automatically (and permanently) change the loader's <code>url</code> to the <code>alternateURL</code> and try again. Think of it as a fallback or backup <code>url</code>. It is perfectly acceptable to use the same <code>alternateURL</code> for multiple loaders (maybe a default image for various ImageLoaders for example). **/
		public function alternateURL(value:String):VideoLoaderVars {
			return _set("alternateURL", value);
		}
		
		/** Initially, the loader's <code>bytesTotal</code> is set to the <code>estimatedBytes</code> value (or <code>LoaderMax.defaultEstimatedBytes</code> if one isn't defined). Then, when the loader begins loading and it can accurately determine the bytesTotal, it will do so. Setting <code>estimatedBytes</code> is optional, but the more accurate the value, the more accurate your loaders' overall progress will be initially. If the loader is inserted into a LoaderMax instance (for queue management), its <code>auditSize</code> feature can attempt to automatically determine the <code>bytesTotal</code> at runtime (there is a slight performance penalty for this, however - see LoaderMax's documentation for details). **/
		public function estimatedBytes(value:uint):VideoLoaderVars {
			return _set("estimatedBytes", value);
		}
		
		/** If <code>true</code>, a "gsCacheBusterID" parameter will be appended to the url with a random set of numbers to prevent caching (don't worry, this info is ignored when you <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> by <code>url</code> or when you're running locally). **/
		public function noCache(value:Boolean):VideoLoaderVars {
			return _set("noCache", value);
		}
		
		/** Normally, the URL will be parsed and any variables in the query string (like "?name=test&amp;state=il&amp;gender=m") will be placed into a URLVariables object which is added to the URLRequest. This avoids a few bugs in Flash, but if you need to keep the entire URL intact (no parsing into URLVariables), set <code>allowMalformedURL:true</code>. For example, if your URL has duplicate variables in the query string like <code>http://www.greensock.com/?c=S&amp;c=SE&amp;c=SW</code>, it is technically considered a malformed URL and a URLVariables object can't properly contain all the duplicates, so in this case you'd want to set <code>allowMalformedURL</code> to <code>true</code>. **/
		public function allowMalformedURL(value:Boolean):VideoLoaderVars {
			return _set("allowMalformedURL", value);
		}
		
		
//---- DISPLAYOBJECTLOADER PROPERTIES ------------------------------------------------------------
		
		/** Sets the <code>ContentDisplay</code>'s <code>alpha</code> property. **/
		public function alpha(value:Number):VideoLoaderVars {
			return _set("alpha", value);
		}
		
		/** Controls the alpha of the rectangle that is drawn when a <code>width</code> and <code>height</code> are defined. **/
		public function bgAlpha(value:Number):VideoLoaderVars {
			return _set("bgAlpha", value);
		}
		
		/** When a <code>width</code> and <code>height</code> are defined, a rectangle will be drawn inside the <code>ContentDisplay</code> Sprite immediately in order to ease the development process. It is transparent by default, but you may define a <code>bgColor</code> if you prefer. **/
		public function bgColor(value:uint):VideoLoaderVars {
			return _set("bgColor", value);
		}
		
		/** Sets the <code>ContentDisplay</code>'s <code>blendMode</code> property. **/
		public function blendMode(value:String):VideoLoaderVars {
			return _set("blendMode", value);
		}
		
		/** If <code>true</code>, the registration point will be placed in the center of the ContentDisplay which can be useful if, for example, you want to animate its scale and have it grow/shrink from its center. **/
		public function centerRegistration(value:Boolean):VideoLoaderVars {
			return _set("centerRegistration", value);
		}
		
		/** A DisplayObjectContainer into which the <code>ContentDisplay</code> Sprite should be added immediately. **/
		public function container(value:DisplayObjectContainer):VideoLoaderVars {
			return _set("container", value);
		}
		
		/** When a <code>width</code> and <code>height</code> are defined, setting <code>crop</code> to <code>true</code> will cause the image to be cropped within that area (by applying a <code>scrollRect</code> for maximum performance). This is typically useful when the <code>scaleMode</code> is <code>"proportionalOutside"</code> or <code>"none"</code> so that any parts of the image that exceed the dimensions defined by <code>width</code> and <code>height</code> are visually chopped off. Use the <code>hAlign</code> and <code>vAlign</code> special properties to control the vertical and horizontal alignment within the cropped area. **/
		public function crop(value:Boolean):VideoLoaderVars {
			return _set("crop", value);
		}
		
		/** 
		 * When a <code>width</code> and <code>height</code> is defined, the <code>hAlign</code> determines how the image is horizontally aligned within that area. The following values are recognized (you may use the <code>com.greensock.layout.AlignMode</code> constants if you prefer):
		 * <ul>
		 * 		<li><code>"center"</code> (the default) - The image will be centered horizontally in the area</li>
		 * 		<li><code>"left"</code> - The image will be aligned with the left side of the area</li>
		 * 		<li><code>"right"</code> - The image will be aligned with the right side of the area</li>
		 * </ul>
		 **/
		public function hAlign(value:String):VideoLoaderVars {
			return _set("hAlign", value);
		}
		
		/** Sets the <code>ContentDisplay</code>'s <code>height</code> property (applied before rotation, scaleX, and scaleY). **/
		public function height(value:Number):VideoLoaderVars {
			return _set("height", value);
		}
		
		/** A handler function for <code>LoaderEvent.SECURITY_ERROR</code> events which onError handles as well, so you can use that as more of a catch-all whereas onSecurityError is specifically for SECURITY_ERROR events. Make sure your onSecurityError function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onSecurityError(value:Function):VideoLoaderVars {
			return _set("onSecurityError", value);
		}
		
		/** Sets the <code>ContentDisplay</code>'s <code>rotation</code> property. **/
		public function rotation(value:Number):VideoLoaderVars {
			return _set("rotation", value);
		}
		
		/** Sets the <code>ContentDisplay</code>'s <code>rotationX</code> property. **/
		public function rotationX(value:Number):VideoLoaderVars {
			return _set("rotationX", value);
		}
		
		/** Sets the <code>ContentDisplay</code>'s <code>rotationY</code> property. **/
		public function rotationY(value:Number):VideoLoaderVars {
			return _set("rotationY", value);
		}
		
		/** Sets the <code>ContentDisplay</code>'s <code>rotationZ</code> property. **/
		public function rotationZ(value:Number):VideoLoaderVars {
			return _set("rotationZ", value);
		}
		
		/** 
		 * When a <code>width</code> and <code>height</code> are defined, the <code>scaleMode</code> controls how the loaded image will be scaled to fit the area. The following values are recognized (you may use the <code>com.greensock.layout.ScaleMode</code> constants if you prefer):
		 * <ul>
		 *	  <li><code>"stretch"</code> (the default) - The image will fill the width/height exactly. </li>
		 *	  <li><code>"proportionalInside"</code> - The image will be scaled proportionally to fit inside the area defined by the width/height</li>
		 *	  <li><code>"proportionalOutside"</code> - The image will be scaled proportionally to completely fill the area, allowing portions of it to exceed the bounds defined by the width/height. </li>
		 *	  <li><code>"widthOnly"</code> - Only the width of the image will be adjusted to fit.</li>
		 *	  <li><code>"heightOnly"</code> - Only the height of the image will be adjusted to fit.</li>
		 *	  <li><code>"none"</code> - No scaling of the image will occur. </li>
		 * </ul> 
		 **/
		public function scaleMode(value:String):VideoLoaderVars {
			return _set("scaleMode", value);
		}
		
		/** Sets the <code>ContentDisplay</code>'s <code>scaleX</code> property. **/
		public function scaleX(value:Number):VideoLoaderVars {
			return _set("scaleX", value);
		}
		
		/** Sets the <code>ContentDisplay</code>'s <code>scaleY</code> property. **/
		public function scaleY(value:Number):VideoLoaderVars {
			return _set("scaleY", value);
		}
		
		/** 
		 * When a <code>width</code> and <code>height</code> is defined, the <code>vAlign</code> determines how the image is vertically aligned within that area. The following values are recognized (you may use the <code>com.greensock.layout.AlignMode</code> constants if you prefer):
		 * <ul>
		 * 		<li><code>"center"</code> (the default) - The image will be centered vertically in the area</li>
		 * 		<li><code>"top"</code> - The image will be aligned with the top of the area</li>
		 * 		<li><code>"bottom"</code> - The image will be aligned with the bottom of the area</li>
		 * </ul> 
		 **/
		public function vAlign(value:String):VideoLoaderVars {
			return _set("vAlign", value);
		}
		
		/** Sets the <code>ContentDisplay</code>'s <code>visible</code> property. **/
		public function visible(value:Boolean):VideoLoaderVars {
			return _set("visible", value);
		}
		
		/** Sets the <code>ContentDisplay</code>'s <code>width</code> property (applied before rotation, scaleX, and scaleY). **/
		public function width(value:Number):VideoLoaderVars {
			return _set("width", value);
		}
		
		/** Sets the <code>ContentDisplay</code>'s <code>x</code> property (for positioning on the stage). **/
		public function x(value:Number):VideoLoaderVars {
			return _set("x", value);
		}
		
		/** Sets the <code>ContentDisplay</code>'s <code>y</code> property (for positioning on the stage). **/
		public function y(value:Number):VideoLoaderVars {
			return _set("y", value);
		}
		
		/** Sets the <code>ContentDisplay</code>'s <code>z</code> property (for positioning on the stage). **/
		public function z(value:Number):VideoLoaderVars {
			return _set("z", value);
		}
		
		
//---- VIDEOLOADER PROPERTIES ------------------------------------------------------------
		
		
		/** If the buffer becomes empty during playback and <code>autoAdjustBuffer</code> is <code>true</code> (the default), it will automatically attempt to adjust the NetStream's <code>bufferTime</code> based on the rate at which the video has been loading, estimating what it needs to be in order to play the rest of the video without emptying the buffer again. This can prevent the annoying problem of video playback start/stopping/starting/stopping on a system tht doesn't have enough bandwidth to adequately buffer the video. You may also set the <code>bufferTime</code> in the constructor's <code>vars</code> parameter to set the initial value. **/
		public function autoAdjustBuffer(value:Boolean):VideoLoaderVars {
			return _set("autoAdjustBuffer", value);
		}
		
		/** If <code>true</code>, the NetStream will only be attached to the Video object (the <code>rawContent</code>) when it is in the display list (on the stage). This conserves memory but it can cause a very brief rendering delay when the content is initially added to the stage (often imperceptible). Also, if you add it to the stage when the <code>videoTime</code> is <i>after</i> its last encoded keyframe, it will render at that last keyframe. **/
		public function autoDetachNetStream(value:Boolean):VideoLoaderVars {
			return _set("autoDetachNetStream", value);
		}
		
		/** By default, the video will begin playing as soon as it has been adequately buffered, but to prevent it from playing initially, set <code>autoPlay</code> to <code>false</code>. **/
		public function autoPlay(value:Boolean):VideoLoaderVars {
			return _set("autoPlay", value);
		}
		
		/** When <code>true</code>, the loader will report its progress only in terms of the video's buffer which can be very convenient if, for example, you want to display loading progress for the video's buffer or tuck it into a LoaderMax with other loaders and allow the LoaderMax to dispatch its <code>COMPLETE</code> event when the buffer is full instead of waiting for the whole file to download. When <code>bufferMode</code> is <code>true</code>, the VideoLoader will dispatch its <code>COMPLETE</code> event when the buffer is full as opposed to waiting for the entire video to load. You can toggle the <code>bufferMode</code> anytime. Please read the full <code>bufferMode</code> property ASDoc description below for details about how it affects things like <code>bytesTotal</code>.**/
		public function bufferMode(value:Boolean):VideoLoaderVars {
			return _set("bufferMode", value);
		}
		
		/** The amount of time (in seconds) that should be buffered before the video can begin playing (set <code>autoPlay</code> to <code>false</code> to pause the video initially).**/
		public function bufferTime(value:Number):VideoLoaderVars {
			return _set("bufferTime", value);
		}
		
		/** If <code>true</code>, the VideoLoader will check for a crossdomain.xml file on the remote host (only useful when loading videos from other domains - see Adobe's docs for details about NetStream's <code>checkPolicyFile</code> property). **/
		public function checkPolicyFile(value:Boolean):VideoLoaderVars {
			return _set("checkPolicyFile", value);
		}
		
		/** Indicates the type of filter applied to decoded video as part of post-processing. The default value is 0, which lets the video compressor apply a deblocking filter as needed. See Adobe's <code>flash.media.Video</code> class docs for details. **/
		public function deblocking(value:int):VideoLoaderVars {
			return _set("deblocking", value);
		}
		
		/** Estimated duration of the video in seconds. VideoLoader will only use this value until it receives the necessary metaData from the video in order to accurately determine the video's duration. You do not need to specify an <code>estimatedDuration</code>, but doing so can help make the playProgress and some other values more accurate (until the metaData has loaded). It can also make the <code>progress/bytesLoaded/bytesTotal</code> more accurate when a <code>estimatedDuration</code> is defined, particularly in <code>bufferMode</code>.**/
		public function estimatedDuration(value:Number):VideoLoaderVars {
			return _set("estimatedDuration", value);
		}
		
		/** Number of times that the video should repeat. To repeat indefinitely, use -1. Default is 0. **/
		public function repeat(value:int):VideoLoaderVars {
			return _set("repeat", value);
		}
		
		/** When <code>smoothing</code> is <code>true</code> (the default), smoothing will be enabled for the video which typically leads to better scaling results. **/
		public function smoothing(value:Boolean):VideoLoaderVars {
			return _set("smoothing", value);
		}
		
		/** A value between 0 and 1 indicating the volume at which the video should play (default is 1).**/
		public function volume(value:Number):VideoLoaderVars {
			return _set("volume", value);
		}
		
		
//---- GETTERS / SETTERS -----------------------------------------------------------------
		
		/** The generic Object populated by all of the method calls in the VideoLoaderVars instance. This is the raw data that gets passed to the loader. **/
		public function get vars():Object {
			return _vars;
		}
		
		/** @private **/
		public function get isGSVars():Boolean {
			return true;
		}
		
	}
}