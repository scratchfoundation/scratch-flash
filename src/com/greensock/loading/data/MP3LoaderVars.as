/**
 * VERSION: 1.2
 * DATE: 2011-03-23
 * AS3
 * UPDATES AND DOCS AT: http://www.greensock.com/loadermax/
 **/
package com.greensock.loading.data {
	import flash.display.DisplayObject;
	import flash.media.SoundLoaderContext;
/**
 * Can be used instead of a generic Object to define the <code>vars</code> parameter of a MP3Loader's constructor. <br /><br />	
 * 
 * There are 2 primary benefits of using a MP3LoaderVars instance to define your MP3Loader variables:
 *  <ol>
 *		<li> In most code editors, code hinting will be activated which helps remind you which special properties are available in MP3Loader</li>
 *		<li> It enables strict data typing for improved debugging (ensuring, for example, that you don't define a Boolean value for <code>onComplete</code> where a Function is expected).</li>
 *  </ol><br />
 * 
 * The down side, of course, is that the code is more verbose and the MP3LoaderVars class adds slightly more kb to your swf.
 *
 * <b>USAGE:</b><br /><br />
 * Note that each method returns the MP3LoaderVars instance, so you can reduce the lines of code by method chaining (see example below).<br /><br />
 *	
 * <b>Without MP3LoaderVars:</b><br /><code>
 * new MP3Loader("audio.mp3", {name:"audio", estimatedBytes:11500, autoPlay:false, onComplete:completeHandler, onProgress:progressHandler})</code><br /><br />
 * 
 * <b>With MP3LoaderVars</b><br /><code>
 * new MP3Loader("audio.mp3", new MP3LoaderVars().name("audio").estimatedBytes(11500).autoPlay(false).onComplete(completeHandler).onProgress(progressHandler))</code><br /><br />
 * 
 * <b>NOTES:</b><br />
 * <ul>
 *	<li> To get the generic vars object that MP3LoaderVars builds internally, simply access its "vars" property.
 * 		 In fact, if you want maximum backwards compatibility, you can tack ".vars" onto the end of your chain like this:<br /><code>
 * 		 new MP3Loader("audio.mp3", new MP3LoaderVars().name("mp3").estimatedBytes(11500).autoPlay(false).vars);</code></li>
 *	<li> Using MP3LoaderVars is completely optional. If you prefer the shorter synatax with the generic Object, feel
 * 		 free to use it. The purpose of this class is simply to enable code hinting and to allow for strict data typing.</li>
 * </ul>
 * 
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 **/
	public class MP3LoaderVars {
		/** @private **/
		public static const version:Number = 1.2;
		
		/** @private **/
		protected var _vars:Object;
		
		/**
		 * Constructor 
		 * @param vars A generic Object containing properties that you'd like to add to this MP3LoaderVars instance.
		 */
		public function MP3LoaderVars(vars:Object=null) {
			_vars = {};
			if (vars != null) {
				for (var p:String in vars) {
					_vars[p] = vars[p];
				}
			}
		}
		
		/** @private **/
		protected function _set(property:String, value:*):MP3LoaderVars {
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
		public function prop(property:String, value:*):MP3LoaderVars {
			return _set(property, value);
		}
		
		
//---- LOADERCORE PROPERTIES -----------------------------------------------------------------
		
		/** When <code>autoDispose</code> is <code>true</code>, the loader will be disposed immediately after it completes (it calls the <code>dispose()</code> method internally after dispatching its <code>COMPLETE</code> event). This will remove any listeners that were defined in the vars object (like onComplete, onProgress, onError, onInit). Once a loader is disposed, it can no longer be found with <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> - it is essentially destroyed but its content is not unloaded (you must call <code>unload()</code> or <code>dispose(true)</code> to unload its content). The default <code>autoDispose</code> value is <code>false</code>.**/
		public function autoDispose(value:Boolean):MP3LoaderVars {
			return _set("autoDispose", value);
		}
		
		/** A name that is used to identify the loader instance. This name can be fed to the <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> methods or traced at any time. Each loader's name should be unique. If you don't define one, a unique name will be created automatically, like "loader21". **/
		public function name(value:String):MP3LoaderVars {
			return _set("name", value);
		}
		
		/** A handler function for <code>LoaderEvent.CANCEL</code> events which are dispatched when loading is aborted due to either a failure or because another loader was prioritized or <code>cancel()</code> was manually called. Make sure your onCancel function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onCancel(value:Function):MP3LoaderVars {
			return _set("onCancel", value);
		}
		
		/** A handler function for <code>LoaderEvent.COMPLETE</code> events which are dispatched when the loader has finished loading successfully. Make sure your onComplete function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onComplete(value:Function):MP3LoaderVars {
			return _set("onComplete", value);
		}
		
		/** A handler function for <code>LoaderEvent.ERROR</code> events which are dispatched whenever the loader experiences an error (typically an IO_ERROR or SECURITY_ERROR). An error doesn't necessarily mean the loader failed, however - to listen for when a loader fails, use the <code>onFail</code> special property. Make sure your onError function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onError(value:Function):MP3LoaderVars {
			return _set("onError", value);
		}
		
		/** A handler function for <code>LoaderEvent.FAIL</code> events which are dispatched whenever the loader fails and its <code>status</code> changes to <code>LoaderStatus.FAILED</code>. Make sure your onFail function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onFail(value:Function):MP3LoaderVars {
			return _set("onFail", value);
		}
		
		/** A handler function for <code>LoaderEvent.HTTP_STATUS</code> events. Make sure your onHTTPStatus function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). You can determine the httpStatus code using the LoaderEvent's <code>target.httpStatus</code> (LoaderItems keep track of their <code>httpStatus</code> when possible, although certain environments prevent Flash from getting httpStatus information).**/
		public function onHTTPStatus(value:Function):MP3LoaderVars {
			return _set("onHTTPStatus", value);
		}
		
		/** A handler function for <code>LoaderEvent.IO_ERROR</code> events which will also call the onError handler, so you can use that as more of a catch-all whereas <code>onIOError</code> is specifically for LoaderEvent.IO_ERROR events. Make sure your onIOError function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onIOError(value:Function):MP3LoaderVars {
			return _set("onIOError", value);
		}
		
		/** A handler function for <code>LoaderEvent.OPEN</code> events which are dispatched when the loader begins loading. Make sure your onOpen function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).**/
		public function onOpen(value:Function):MP3LoaderVars {
			return _set("onOpen", value);
		}
		
		/** A handler function for <code>LoaderEvent.PROGRESS</code> events which are dispatched whenever the <code>bytesLoaded</code> changes. Make sure your onProgress function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). You can use the LoaderEvent's <code>target.progress</code> to get the loader's progress value or use its <code>target.bytesLoaded</code> and <code>target.bytesTotal</code>.**/
		public function onProgress(value:Function):MP3LoaderVars {
			return _set("onProgress", value);
		}
		
		/** LoaderMax supports <i>subloading</i>, where an object can be factored into a parent's loading progress. If you want LoaderMax to require this loader as part of its parent SWFLoader's progress, you must set the <code>requireWithRoot</code> property to your swf's <code>root</code>. For example, <code>vars.requireWithRoot = this.root;</code>. **/
		public function requireWithRoot(value:DisplayObject):MP3LoaderVars {
			return _set("requireWithRoot", value);
		}
		
		
//---- LOADERITEM PROPERTIES -------------------------------------------------------------	
		
		/** If you define an <code>alternateURL</code>, the loader will initially try to load from its original <code>url</code> and if it fails, it will automatically (and permanently) change the loader's <code>url</code> to the <code>alternateURL</code> and try again. Think of it as a fallback or backup <code>url</code>. It is perfectly acceptable to use the same <code>alternateURL</code> for multiple loaders (maybe a default image for various ImageLoaders for example). **/
		public function alternateURL(value:String):MP3LoaderVars {
			return _set("alternateURL", value);
		}
		
		/** Initially, the loader's <code>bytesTotal</code> is set to the <code>estimatedBytes</code> value (or <code>LoaderMax.defaultEstimatedBytes</code> if one isn't defined). Then, when the loader begins loading and it can accurately determine the bytesTotal, it will do so. Setting <code>estimatedBytes</code> is optional, but the more accurate the value, the more accurate your loaders' overall progress will be initially. If the loader is inserted into a LoaderMax instance (for queue management), its <code>auditSize</code> feature can attempt to automatically determine the <code>bytesTotal</code> at runtime (there is a slight performance penalty for this, however - see LoaderMax's documentation for details). **/
		public function estimatedBytes(value:uint):MP3LoaderVars {
			return _set("estimatedBytes", value);
		}
		
		/** If <code>true</code>, a "gsCacheBusterID" parameter will be appended to the url with a random set of numbers to prevent caching (don't worry, this info is ignored when you <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> by <code>url</code> or when you're running locally). **/
		public function noCache(value:Boolean):MP3LoaderVars {
			return _set("noCache", value);
		}
		
		/** Normally, the URL will be parsed and any variables in the query string (like "?name=test&amp;state=il&amp;gender=m") will be placed into a URLVariables object which is added to the URLRequest. This avoids a few bugs in Flash, but if you need to keep the entire URL intact (no parsing into URLVariables), set <code>allowMalformedURL:true</code>. For example, if your URL has duplicate variables in the query string like <code>http://www.greensock.com/?c=S&amp;c=SE&amp;c=SW</code>, it is technically considered a malformed URL and a URLVariables object can't properly contain all the duplicates, so in this case you'd want to set <code>allowMalformedURL</code> to <code>true</code>. **/
		public function allowMalformedURL(value:Boolean):MP3LoaderVars {
			return _set("allowMalformedURL", value);
		}
		
		
//---- MP3LOADER PROPERTIES --------------------------------------------------------------
		
		/** By default the MP3 will begin playing immediately when enough of the file has buffered, but to prevent it from autoPlaying, set <code>autoPlay</code> to <code>false</code>. **/
		public function autoPlay(value:Boolean):MP3LoaderVars {
			return _set("autoPlay", value);
		}
		
		/** Number of times that the mp3 should repeat. To repeat indefinitely, use -1. Default is 0. **/
		public function repeat(value:int):MP3LoaderVars {
			return _set("repeat", value);
		}
		
		/** A value between 0 and 1 indicating the volume at which the sound should play when the MP3Loader's controls are used to play the sound, like <code>playSound()</code> or when <code>autoPlay</code> is <code>true</code> (default volume is 1). **/
		public function volume(value:Number):MP3LoaderVars {
			return _set("volume", value);
		}
		
		/** To control things like the buffer time and whether or not a policy file is checked, define a <code>SoundLoaderContext</code> object. The default context is null. See Adobe's SoundLoaderContext documentation for details. **/
		public function context(value:SoundLoaderContext):MP3LoaderVars {
			return _set("context", value);
		}
		
		/** The minimum number of <code>bytesLoaded</code> to wait for before the <code>LoaderEvent.INIT</code> event is dispatched - the higher the number the more accurate the <code>duration</code> estimate will be when the INIT event is dispatched (the default value is 102400 which is 100k). The MP3's duration cannot be determined with 100% accuracy until it has completely loaded, but it is estimated with more and more accuracy as the file loads. **/
		public function initThreshold(value:uint):MP3LoaderVars {
			return _set("initThreshold", value);
		}
		
		
//---- GETTERS / SETTERS -----------------------------------------------------------------
		
		/** The generic Object populated by all of the method calls in the MP3LoaderVars instance. This is the raw data that gets passed to the loader. **/
		public function get vars():Object {
			return _vars;
		}
		
		/** @private **/
		public function get isGSVars():Boolean {
			return true;
		}
		
		
	}
}