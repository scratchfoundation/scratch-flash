/**
 * VERSION: 1.23
 * DATE: 2011-07-30
 * AS3
 * UPDATES AND DOCS AT: http://www.greensock.com/loadermax/
 **/
package com.greensock.loading.data {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.system.LoaderContext;
/**
 * Can be used instead of a generic object to define the <code>vars</code> parameter of an SWFLoader's constructor. <br /><br />	
 * 
 * There are 2 primary benefits of using a SWFLoaderVars instance to define your SWFLoader variables:
 *  <ol>
 *		<li> In most code editors, code hinting will be activated which helps remind you which special properties are available in SWFLoader</li>
 *		<li> It enables strict data typing for improved debugging (ensuring, for example, that you don't define a Boolean value for <code>onComplete</code> where a Function is expected).</li>
 *  </ol>
 *
 * <b>USAGE:</b><br />
 * Note that each method returns the SWFLoaderVars instance, so you can reduce the lines of code by method chaining (see example below).<br /><br />
 *	
 * <b>Without SWFLoaderVars:</b><br /><code>
 * new SWFLoader("child.swf", {name:"swf", estimatedBytes:11500, container:this, width:400, height:300, onComplete:completeHandler, onProgress:progressHandler})<br /><br /></code>
 * 
 * <b>With SWFLoaderVars</b><br /><code>
 * new SWFLoader("photo1.jpg", new SWFLoaderVars().name("swf").estimatedBytes(11500).container(this).width(400).height(300).onComplete(completeHandler).onProgress(progressHandler))<br /><br /></code>
 *		
 * <b>NOTES:</b><br />
 * <ul>
 *	<li> To get the generic vars object that SWFLoaderVars builds internally, simply access its "vars" property.
 * 		 In fact, if you want maximum backwards compatibility, you can tack ".vars" onto the end of your chain like this:<br /><code>
 * 		 new SWFLoader("child.swf", new SWFLoaderVars().name("swf").estimatedBytes(11500).vars);</code></li>
 *	<li> Using SWFLoaderVars is completely optional. If you prefer the shorter synatax with the generic Object, feel
 * 		 free to use it. The purpose of this class is simply to enable code hinting and to allow for strict data typing.</li>
 * </ul>
 * 
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 */	 
	public class SWFLoaderVars {
		/** @private **/
		public static const version:Number = 1.23;
		
		/** @private **/
		protected var _vars:Object;
		
		/**
		 * Constructor 
		 * 
		 * @param vars A generic Object containing properties that you'd like to add to this SWFLoaderVars instance.
		 */
		public function SWFLoaderVars(vars:Object=null) {
			_vars = {};
			if (vars != null) {
				for (var p:String in vars) {
					_vars[p] = vars[p];
				}
			}
		}
		
		/** @private **/
		protected function _set(property:String, value:*):SWFLoaderVars {
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
		public function prop(property:String, value:*):SWFLoaderVars {
			return _set(property, value);
		}

		
//---- LOADERCORE PROPERTIES -----------------------------------------------------------------
		
		/** When <code>autoDispose</code> is <code>true</code>, the loader will be disposed immediately after it completes (it calls the <code>dispose()</code> method internally after dispatching its <code>COMPLETE</code> event). This will remove any listeners that were defined in the vars object (like onComplete, onProgress, onError, onInit). Once a loader is disposed, it can no longer be found with <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> - it is essentially destroyed but its content is not unloaded (you must call <code>unload()</code> or <code>dispose(true)</code> to unload its content). The default <code>autoDispose</code> value is <code>false</code>.**/
		public function autoDispose(value:Boolean):SWFLoaderVars {
			return _set("autoDispose", value);
		}
		
		/** A name that is used to identify the loader instance. This name can be fed to the <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> methods or traced at any time. Each loader's name should be unique. If you don't define one, a unique name will be created automatically, like "loader21". **/
		public function name(value:String):SWFLoaderVars {
			return _set("name", value);
		}
		
		/** A handler function for <code>LoaderEvent.CANCEL</code> events which are dispatched when loading is aborted due to either a failure or because another loader was prioritized or <code>cancel()</code> was manually called. Make sure your onCancel function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onCancel(value:Function):SWFLoaderVars {
			return _set("onCancel", value);
		}
		
		/** A handler function for <code>LoaderEvent.COMPLETE</code> events which are dispatched when the loader has finished loading successfully. Make sure your onComplete function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onComplete(value:Function):SWFLoaderVars {
			return _set("onComplete", value);
		}
		
		/** A handler function for <code>LoaderEvent.ERROR</code> events which are dispatched whenever the loader experiences an error (typically an IO_ERROR or SECURITY_ERROR). An error doesn't necessarily mean the loader failed, however - to listen for when a loader fails, use the <code>onFail</code> special property. Make sure your onError function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onError(value:Function):SWFLoaderVars {
			return _set("onError", value);
		}
		
		/** A handler function for <code>LoaderEvent.FAIL</code> events which are dispatched whenever the loader fails and its <code>status</code> changes to <code>LoaderStatus.FAILED</code>. Make sure your onFail function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onFail(value:Function):SWFLoaderVars {
			return _set("onFail", value);
		}
		
		/** A handler function for <code>LoaderEvent.HTTP_STATUS</code> events. Make sure your onHTTPStatus function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). You can determine the httpStatus code using the LoaderEvent's <code>target.httpStatus</code> (LoaderItems keep track of their <code>httpStatus</code> when possible, although certain environments prevent Flash from getting httpStatus information).**/
		public function onHTTPStatus(value:Function):SWFLoaderVars {
			return _set("onHTTPStatus", value);
		}
		
		/** A handler function for <code>LoaderEvent.IO_ERROR</code> events which will also call the onError handler, so you can use that as more of a catch-all whereas <code>onIOError</code> is specifically for LoaderEvent.IO_ERROR events. Make sure your onIOError function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onIOError(value:Function):SWFLoaderVars {
			return _set("onIOError", value);
		}
		
		/** A handler function for <code>LoaderEvent.OPEN</code> events which are dispatched when the loader begins loading. Make sure your onOpen function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).**/
		public function onOpen(value:Function):SWFLoaderVars {
			return _set("onOpen", value);
		}
		
		/** A handler function for <code>LoaderEvent.PROGRESS</code> events which are dispatched whenever the <code>bytesLoaded</code> changes. Make sure your onProgress function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). You can use the LoaderEvent's <code>target.progress</code> to get the loader's progress value or use its <code>target.bytesLoaded</code> and <code>target.bytesTotal</code>.**/
		public function onProgress(value:Function):SWFLoaderVars {
			return _set("onProgress", value);
		}
		
		/** LoaderMax supports <i>subloading</i>, where an object can be factored into a parent's loading progress. If you want LoaderMax to require this loader as part of its parent SWFLoader's progress, you must set the <code>requireWithRoot</code> property to your swf's <code>root</code>. For example, <code>vars.requireWithRoot = this.root;</code>. **/
		public function requireWithRoot(value:DisplayObject):SWFLoaderVars {
			return _set("requireWithRoot", value);
		}
		
		
//---- LOADERITEM PROPERTIES -------------------------------------------------------------	
		
		/** If you define an <code>alternateURL</code>, the loader will initially try to load from its original <code>url</code> and if it fails, it will automatically (and permanently) change the loader's <code>url</code> to the <code>alternateURL</code> and try again. Think of it as a fallback or backup <code>url</code>. It is perfectly acceptable to use the same <code>alternateURL</code> for multiple loaders (maybe a default image for various SWFLoaders for example). **/
		public function alternateURL(value:String):SWFLoaderVars {
			return _set("alternateURL", value);
		}
		
		/** Initially, the loader's <code>bytesTotal</code> is set to the <code>estimatedBytes</code> value (or <code>LoaderMax.defaultEstimatedBytes</code> if one isn't defined). Then, when the loader begins loading and it can accurately determine the bytesTotal, it will do so. Setting <code>estimatedBytes</code> is optional, but the more accurate the value, the more accurate your loaders' overall progress will be initially. If the loader is inserted into a LoaderMax instance (for queue management), its <code>auditSize</code> feature can attempt to automatically determine the <code>bytesTotal</code> at runtime (there is a slight performance penalty for this, however - see LoaderMax's documentation for details). **/
		public function estimatedBytes(value:uint):SWFLoaderVars {
			return _set("estimatedBytes", value);
		}
		
		/** If <code>true</code>, a "gsCacheBusterID" parameter will be appended to the url with a random set of numbers to prevent caching (don't worry, this info is ignored when you <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> by <code>url</code> or when you're running locally). **/
		public function noCache(value:Boolean):SWFLoaderVars {
			return _set("noCache", value);
		}
		
		/** Normally, the URL will be parsed and any variables in the query string (like "?name=test&amp;state=il&amp;gender=m") will be placed into a URLVariables object which is added to the URLRequest. This avoids a few bugs in Flash, but if you need to keep the entire URL intact (no parsing into URLVariables), set <code>allowMalformedURL:true</code>. For example, if your URL has duplicate variables in the query string like <code>http://www.greensock.com/?c=S&amp;c=SE&amp;c=SW</code>, it is technically considered a malformed URL and a URLVariables object can't properly contain all the duplicates, so in this case you'd want to set <code>allowMalformedURL</code> to <code>true</code>. **/
		public function allowMalformedURL(value:Boolean):SWFLoaderVars {
			return _set("allowMalformedURL", value);
		}
		
		
//---- DISPLAYOBJECTLOADER PROPERTIES ------------------------------------------------------------
		
		/** Sets the <code>ContentDisplay</code>'s <code>alpha</code> property. **/
		public function alpha(value:Number):SWFLoaderVars {
			return _set("alpha", value);
		}
		
		/** Controls the alpha of the rectangle that is drawn when a <code>width</code> and <code>height</code> are defined. **/
		public function bgAlpha(value:Number):SWFLoaderVars {
			return _set("bgAlpha", value);
		}
		
		/** When a <code>width</code> and <code>height</code> are defined, a rectangle will be drawn inside the <code>ContentDisplay</code> Sprite immediately in order to ease the development process. It is transparent by default, but you may define a <code>bgColor</code> if you prefer. **/
		public function bgColor(value:uint):SWFLoaderVars {
			return _set("bgColor", value);
		}
		
		/** Sets the <code>ContentDisplay</code>'s <code>blendMode</code> property. **/
		public function blendMode(value:String):SWFLoaderVars {
			return _set("blendMode", value);
		}
		
		/** If <code>true</code>, the registration point will be placed in the center of the ContentDisplay which can be useful if, for example, you want to animate its scale and have it grow/shrink from its center. **/
		public function centerRegistration(value:Boolean):SWFLoaderVars {
			return _set("centerRegistration", value);
		}
		
		/** A DisplayObjectContainer into which the <code>ContentDisplay</code> Sprite should be added immediately. **/
		public function container(value:DisplayObjectContainer):SWFLoaderVars {
			return _set("container", value);
		}
		
		/** To control whether or not a policy file is checked (which is required if you're loading an image from another domain and you want to use it in BitmapData operations), define a <code>LoaderContext</code> object. By default, the policy file <strong>will</strong> be checked when running remotely, so make sure the appropriate crossdomain.xml file is in place. See Adobe's <code>LoaderContext</code> documentation for details and precautions.  **/
		public function context(value:LoaderContext):SWFLoaderVars {
			return _set("context", value);
		}
		
		/** When a <code>width</code> and <code>height</code> are defined, setting <code>crop</code> to <code>true</code> will cause the image to be cropped within that area (by applying a <code>scrollRect</code> for maximum performance). This is typically useful when the <code>scaleMode</code> is <code>"proportionalOutside"</code> or <code>"none"</code> so that any parts of the image that exceed the dimensions defined by <code>width</code> and <code>height</code> are visually chopped off. Use the <code>hAlign</code> and <code>vAlign</code> special properties to control the vertical and horizontal alignment within the cropped area. **/
		public function crop(value:Boolean):SWFLoaderVars {
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
		public function hAlign(value:String):SWFLoaderVars {
			return _set("hAlign", value);
		}
		
		/** Sets the <code>ContentDisplay</code>'s <code>height</code> property (applied before rotation, scaleX, and scaleY). **/
		public function height(value:Number):SWFLoaderVars {
			return _set("height", value);
		}
		
		/** A handler function for <code>LoaderEvent.SECURITY_ERROR</code> events which onError handles as well, so you can use that as more of a catch-all whereas onSecurityError is specifically for SECURITY_ERROR events. Make sure your onSecurityError function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onSecurityError(value:Function):SWFLoaderVars {
			return _set("onSecurityError", value);
		}
		
		/** Sets the <code>ContentDisplay</code>'s <code>rotation</code> property. **/
		public function rotation(value:Number):SWFLoaderVars {
			return _set("rotation", value);
		}
		
		/** Sets the <code>ContentDisplay</code>'s <code>rotationX</code> property. **/
		public function rotationX(value:Number):SWFLoaderVars {
			return _set("rotationX", value);
		}
		
		/** Sets the <code>ContentDisplay</code>'s <code>rotationY</code> property. **/
		public function rotationY(value:Number):SWFLoaderVars {
			return _set("rotationY", value);
		}
		
		/** Sets the <code>ContentDisplay</code>'s <code>rotationZ</code> property. **/
		public function rotationZ(value:Number):SWFLoaderVars {
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
		public function scaleMode(value:String):SWFLoaderVars {
			return _set("scaleMode", value);
		}
		
		/** Sets the <code>ContentDisplay</code>'s <code>scaleX</code> property. **/
		public function scaleX(value:Number):SWFLoaderVars {
			return _set("scaleX", value);
		}
		
		/** Sets the <code>ContentDisplay</code>'s <code>scaleY</code> property. **/
		public function scaleY(value:Number):SWFLoaderVars {
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
		public function vAlign(value:String):SWFLoaderVars {
			return _set("vAlign", value);
		}
		
		/** Sets the <code>ContentDisplay</code>'s <code>visible</code> property. **/
		public function visible(value:Boolean):SWFLoaderVars {
			return _set("visible", value);
		}
		
		/** Sets the <code>ContentDisplay</code>'s <code>width</code> property (applied before rotation, scaleX, and scaleY). **/
		public function width(value:Number):SWFLoaderVars {
			return _set("width", value);
		}
		
		/** Sets the <code>ContentDisplay</code>'s <code>x</code> property (for positioning on the stage). **/
		public function x(value:Number):SWFLoaderVars {
			return _set("x", value);
		}
		
		/** Sets the <code>ContentDisplay</code>'s <code>y</code> property (for positioning on the stage). **/
		public function y(value:Number):SWFLoaderVars {
			return _set("y", value);
		}
		
		/** Sets the <code>ContentDisplay</code>'s <code>z</code> property (for positioning on the stage). **/
		public function z(value:Number):SWFLoaderVars {
			return _set("z", value);
		}
		
		
//---- SWFLOADER PROPERTIES ------------------------------------------------------------
		
		/** If <code>autoPlay</code> is <code>true</code> (the default), the swf will begin playing immediately when the <code>INIT</code> event fires. To prevent this behavior, set <code>autoPlay</code> to <code>false</code> which will also mute the swf until the SWFLoader completes. This only calls <code>stop()</code> on the main timeline but it does not prevent scripted animations. **/
		public function autoPlay(value:Boolean):SWFLoaderVars {
			return _set("autoPlay", value);
		}
		/** By default, a SWFLoader instance will automatically look for LoaderMax loaders in the swf when it initializes. Every loader found with a <code>requireWithRoot</code> parameter set to that swf's <code>root</code> will be integrated into the SWFLoader's overall progress. The SWFLoader's <code>COMPLETE</code> event won't fire until all such loaders are also complete. If you prefer NOT to integrate the subloading loaders into the SWFLoader's overall progress, set <code>integrateProgress</code> to <code>false</code>. **/
		public function integrateProgress(value:Boolean):SWFLoaderVars {
			return _set("integrateProgress", value);
		}
		/** A handler function for <code>LoaderEvent.INIT</code> events which are called when the swf has streamed enough of its content to render the first frame and determine if there are any required LoaderMax-related loaders recognized. It also adds the swf to the ContentDisplay Sprite at this point. Make sure your onInit function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onInit(value:Function):SWFLoaderVars {
			return _set("onInit", value);
		}
		/** A handler function for <code>LoaderEvent.CHILD_OPEN</code> events which are dispatched each time any nested LoaderMax-related loaders (active ones that the SWFLoader found inside the subloading swf that had their <code>requireWithRoot</code> set to its <code>root</code>) begins loading. Make sure your onChildOpen function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).**/
		public function onChildOpen(value:Function):SWFLoaderVars {
			return _set("onChildOpen", value);
		}
		/** A handler function for <code>LoaderEvent.CHILD_PROGRESS</code> events which are dispatched each time any nested LoaderMax-related loaders (active ones that the SWFLoader found inside the subloading swf that had their <code>requireWithRoot</code> set to its <code>root</code>) dispatches a <code>PROGRESS</code> event. To listen for changes in the SWFLoader's overall progress, use the <code>onProgress</code> special property instead. You can use the LoaderEvent's <code>target.progress</code> to get the child loader's progress value or use its <code>target.bytesLoaded</code> and <code>target.bytesTotal</code>. The LoaderEvent's <code>currentTarget</code> refers to the SWFLoader, so you can check its overall progress with the LoaderEvent's <code>currentTarget.progress</code>. Make sure your onChildProgress function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).**/
		public function onChildProgress(value:Function):SWFLoaderVars {
			return _set("onChildProgress", value);
		}
		/** A handler function for <code>LoaderEvent.CHILD_COMPLETE</code> events which are dispatched each time any nested LoaderMax-related loaders (active ones that the SWFLoader found inside the subloading swf that had their <code>requireWithRoot</code> set to its <code>root</code>) finishes loading successfully. Make sure your onChildComplete function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onChildComplete(value:Function):SWFLoaderVars {
			return _set("onChildComplete", value);
		}
		/** A handler function for <code>LoaderEvent.CHILD_CANCEL</code> events which are dispatched each time loading is aborted on any nested LoaderMax-related loaders (active ones that the SWFLoader found inside the subloading swf that had their <code>requireWithRoot</code> set to its <code>root</code>) due to either an error or because another loader was prioritized in the queue or because <code>cancel()</code> was manually called on the child loader. Make sure your onChildCancel function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onChildCancel(value:Function):SWFLoaderVars {
			return _set("onChildCancel", value);
		}
		/** A handler function for <code>LoaderEvent.CHILD_FAIL</code> events which are dispatched each time any nested LoaderMax-related loaders (active ones that the SWFLoader found inside the subloading swf that had their <code>requireWithRoot</code> set to its <code>root</code>) fails (and its <code>status</code> chances to <code>LoaderStatus.FAILED</code>). Make sure your onChildFail function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).**/
		public function onChildFail(value:Function):SWFLoaderVars {
			return _set("onChildFail", value);
		}
		/** A handler function for <code>LoaderEvent.UNCAUGHT_ERROR</code> events which are dispatched when the subloaded swf encounters an UncaughtErrorEvent meaning an Error was thrown outside of a try...catch statement. This can be useful when subloading swfs from a 3rd party that may contain errors. However, UNCAUGHT_ERROR events will only be dispatched if the parent swf is published for Flash Player 10.1 or later! See SWFLoader's <code>suppressUncaughtErrors</code> special property if you'd like to have it automatically suppress these errors. The original UncaughtErrorEvent is stored in the LoaderEvent's <code>data</code> property. So, for example, if you'd like to call <code>preventDefault()</code> on that UncaughtErrorEvent, you'd do <code>myLoaderEvent.data.preventDefault()</code>. **/
		public function onUncaughtError(value:Function):SWFLoaderVars {
			return _set("onUncaughtError", value);
		}
		
		/** If <code>true</code>, the SWFLoader will suppress the <code>REMOVED_FROM_STAGE</code> and <code>ADDED_TO_STAGE</code> events that are normally dispatched when the subloaded swf is reparented into the ContentDisplay (this always happens in Flash when any DisplayObject that's in the display list gets reparented - SWFLoader just circumvents it by default initially to avoid common problems that could arise if the child swf is coded a certain way). For example, if your subloaded swf has this code: <code>addEventListener(Event.REMOVED_FROM_STAGE, disposeEverything)</code> and you set <code>suppressInitReparentEvents</code> to <code>false</code>, <code>disposeEverything()</code> would get called as soon as the swf inits (assuming the ContentDisplay is in the display list). **/
		public function suppressInitReparentEvents(value:Boolean):SWFLoaderVars {
			return _set("suppressInitReparentEvents", value);
		}
		/** To automatically suppress uncaught errors in the subloaded swf (errors that are thrown outside of a try...catch statement), set <code>suppressUncaughtErrors</code> to <code>true</code>, but please note that this will ONLY work if the parent swf is published to Flash Player 10.1 or later. Suppressing the UncaughtErrorEvent simply means calling its <code>preventDefault()</code> and <code>stopImmediatePropagation()</code> methods as well as preventing it from bubbling up to its parent LoaderMax/SWFLoader anscestors. If you'd rather listen for these events so that you can handle them yourself, listen for the <code>LoaderEvent.UNCAUGHT_ERROR</code> event. The original UncaughtErrorEvent instance will be stored in the LoaderEvent's <code>data</code> property. **/
		public function suppressUncaughtErrors(value:Boolean):SWFLoaderVars {
			return _set("suppressUncaughtErrors", value);
		}
		

//---- GETTERS / SETTERS -----------------------------------------------------------------
		
		/** The generic Object populated by all of the method calls in the SWFLoaderVars instance. This is the raw data that gets passed to the loader. **/
		public function get vars():Object {
			return _vars;
		}
		
		/** @private **/
		public function get isGSVars():Boolean {
			return true;
		}
		
	}
}