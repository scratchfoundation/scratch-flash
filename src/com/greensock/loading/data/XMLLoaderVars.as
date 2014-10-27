/**
 * VERSION: 1.22
 * DATE: 2011-04-20
 * AS3
 * UPDATES AND DOCS AT: http://www.greensock.com/loadermax/
 **/
package com.greensock.loading.data {
	import flash.display.DisplayObject;
/**
 * Can be used instead of a generic Object to define the <code>vars</code> parameter of a XMLLoader's constructor. <br /><br />	
 * 
 * There are 2 primary benefits of using a XMLLoaderVars instance to define your XMLLoader variables:
 *  <ol>
 *		<li> In most code editors, code hinting will be activated which helps remind you which special properties are available in XMLLoader</li>
 *		<li> It enables strict data typing for improved debugging (ensuring, for example, that you don't define a Boolean value for <code>onComplete</code> where a Function is expected).</li>
 *  </ol><br />
 * 
 * The down side, of course, is that the code is more verbose and the XMLLoaderVars class adds slightly more kb to your swf.
 *
 * <b>USAGE:</b><br /><br />
 * Note that each method returns the XMLLoaderVars instance, so you can reduce the lines of code by method chaining (see example below).<br /><br />
 *	
 * <b>Without XMLLoaderVars:</b><br /><code>
 * new XMLLoader("data.xml", {name:"css", estimatedBytes:1500, onComplete:completeHandler, onProgress:progressHandler})</code><br /><br />
 * 
 * <b>With XMLLoaderVars</b><br /><code>
 * new XMLLoader("data.xml", new XMLLoaderVars().name("data").estimatedBytes(1500).onComplete(completeHandler).onProgress(progressHandler))</code><br /><br />
 * 
 * <b>NOTES:</b><br />
 * <ul>
 *	<li> To get the generic vars object that XMLLoaderVars builds internally, simply access its "vars" property.
 * 		 In fact, if you want maximum backwards compatibility, you can tack ".vars" onto the end of your chain like this:<br /><code>
 * 		 new XMLLoader("data.xml", new XMLLoaderVars().name("data").estimatedBytes(1500).onComplete(completeHandler).vars)</code></li>
 *	<li> Using XMLLoaderVars is completely optional. If you prefer the shorter synatax with the generic Object, feel
 * 		 free to use it. The purpose of this class is simply to enable code hinting and to allow for strict data typing.</li>
 * </ul>
 * 
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 */	 
	public class XMLLoaderVars {
		/** @private **/
		public static const version:Number = 1.22;
		
		/** @private **/
		protected var _vars:Object;
		
		/**
		 * Constructor 
		 * @param vars A generic Object containing properties that you'd like to add to this XMLLoaderVars instance.
		 */
		public function XMLLoaderVars(vars:Object=null) {
			_vars = {};
			if (vars != null) {
				for (var p:String in vars) {
					_vars[p] = vars[p];
				}
			}
		}
		
		/** @private **/
		protected function _set(property:String, value:*):XMLLoaderVars {
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
		public function prop(property:String, value:*):XMLLoaderVars {
			return _set(property, value);
		}
		
		
//---- LOADERCORE PROPERTIES -----------------------------------------------------------------
		
		/** When <code>autoDispose</code> is <code>true</code>, the loader will be disposed immediately after it completes (it calls the <code>dispose()</code> method internally after dispatching its <code>COMPLETE</code> event). This will remove any listeners that were defined in the vars object (like onComplete, onProgress, onError, onInit). Once a loader is disposed, it can no longer be found with <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> - it is essentially destroyed but its content is not unloaded (you must call <code>unload()</code> or <code>dispose(true)</code> to unload its content). The default <code>autoDispose</code> value is <code>false</code>.**/
		public function autoDispose(value:Boolean):XMLLoaderVars {
			return _set("autoDispose", value);
		}
		
		/** A name that is used to identify the loader instance. This name can be fed to the <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> methods or traced at any time. Each loader's name should be unique. If you don't define one, a unique name will be created automatically, like "loader21". **/
		public function name(value:String):XMLLoaderVars {
			return _set("name", value);
		}
		
		/** A handler function for <code>LoaderEvent.CANCEL</code> events which are dispatched when loading is aborted due to either a failure or because another loader was prioritized or <code>cancel()</code> was manually called. Make sure your onCancel function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onCancel(value:Function):XMLLoaderVars {
			return _set("onCancel", value);
		}
		
		/** A handler function for <code>LoaderEvent.COMPLETE</code> events which are dispatched when the loader has finished loading successfully. Make sure your onComplete function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onComplete(value:Function):XMLLoaderVars {
			return _set("onComplete", value);
		}
		
		/** A handler function for <code>LoaderEvent.ERROR</code> events which are dispatched whenever the loader experiences an error (typically an IO_ERROR or SECURITY_ERROR). An error doesn't necessarily mean the loader failed, however - to listen for when a loader fails, use the <code>onFail</code> special property. Make sure your onError function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onError(value:Function):XMLLoaderVars {
			return _set("onError", value);
		}
		
		/** A handler function for <code>LoaderEvent.FAIL</code> events which are dispatched whenever the loader fails and its <code>status</code> changes to <code>LoaderStatus.FAILED</code>. Make sure your onFail function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onFail(value:Function):XMLLoaderVars {
			return _set("onFail", value);
		}
		
		/** A handler function for <code>LoaderEvent.HTTP_STATUS</code> events. Make sure your onHTTPStatus function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). You can determine the httpStatus code using the LoaderEvent's <code>target.httpStatus</code> (LoaderItems keep track of their <code>httpStatus</code> when possible, although certain environments prevent Flash from getting httpStatus information).**/
		public function onHTTPStatus(value:Function):XMLLoaderVars {
			return _set("onHTTPStatus", value);
		}
		
		/** A handler function for <code>LoaderEvent.IO_ERROR</code> events which will also call the onError handler, so you can use that as more of a catch-all whereas <code>onIOError</code> is specifically for LoaderEvent.IO_ERROR events. Make sure your onIOError function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onIOError(value:Function):XMLLoaderVars {
			return _set("onIOError", value);
		}
		
		/** A handler function for <code>LoaderEvent.OPEN</code> events which are dispatched when the loader begins loading. Make sure your onOpen function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).**/
		public function onOpen(value:Function):XMLLoaderVars {
			return _set("onOpen", value);
		}
		
		/** A handler function for <code>LoaderEvent.PROGRESS</code> events which are dispatched whenever the <code>bytesLoaded</code> changes. Make sure your onProgress function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). You can use the LoaderEvent's <code>target.progress</code> to get the loader's progress value or use its <code>target.bytesLoaded</code> and <code>target.bytesTotal</code>.**/
		public function onProgress(value:Function):XMLLoaderVars {
			return _set("onProgress", value);
		}
		
		/** LoaderMax supports <i>subloading</i>, where an object can be factored into a parent's loading progress. If you want LoaderMax to require this loader as part of its parent SWFLoader's progress, you must set the <code>requireWithRoot</code> property to your swf's <code>root</code>. For example, <code>vars.requireWithRoot = this.root;</code>. **/
		public function requireWithRoot(value:DisplayObject):XMLLoaderVars {
			return _set("requireWithRoot", value);
		}
		
		
//---- LOADERITEM PROPERTIES -------------------------------------------------------------	
		
		/** If you define an <code>alternateURL</code>, the loader will initially try to load from its original <code>url</code> and if it fails, it will automatically (and permanently) change the loader's <code>url</code> to the <code>alternateURL</code> and try again. Think of it as a fallback or backup <code>url</code>. It is perfectly acceptable to use the same <code>alternateURL</code> for multiple loaders (maybe a default image for various ImageLoaders for example). **/
		public function alternateURL(value:String):XMLLoaderVars {
			return _set("alternateURL", value);
		}
		
		/** Initially, the loader's <code>bytesTotal</code> is set to the <code>estimatedBytes</code> value (or <code>LoaderMax.defaultEstimatedBytes</code> if one isn't defined). Then, when the loader begins loading and it can accurately determine the bytesTotal, it will do so. Setting <code>estimatedBytes</code> is optional, but the more accurate the value, the more accurate your loaders' overall progress will be initially. If the loader is inserted into a LoaderMax instance (for queue management), its <code>auditSize</code> feature can attempt to automatically determine the <code>bytesTotal</code> at runtime (there is a slight performance penalty for this, however - see LoaderMax's documentation for details). **/
		public function estimatedBytes(value:uint):XMLLoaderVars {
			return _set("estimatedBytes", value);
		}
		
		/** If <code>true</code>, a "gsCacheBusterID" parameter will be appended to the url with a random set of numbers to prevent caching (don't worry, this info is ignored when you <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> by <code>url</code> or when you're running locally). **/
		public function noCache(value:Boolean):XMLLoaderVars {
			return _set("noCache", value);
		}
		
		/** Normally, the URL will be parsed and any variables in the query string (like "?name=test&amp;state=il&amp;gender=m") will be placed into a URLVariables object which is added to the URLRequest. This avoids a few bugs in Flash, but if you need to keep the entire URL intact (no parsing into URLVariables), set <code>allowMalformedURL:true</code>. For example, if your URL has duplicate variables in the query string like <code>http://www.greensock.com/?c=S&amp;c=SE&amp;c=SW</code>, it is technically considered a malformed URL and a URLVariables object can't properly contain all the duplicates, so in this case you'd want to set <code>allowMalformedURL</code> to <code>true</code>. **/
		public function allowMalformedURL(value:Boolean):XMLLoaderVars {
			return _set("allowMalformedURL", value);
		}

		
//---- XMLLOADER PROPERTIES --------------------------------------------------------------
		
		/** By default, the XMLLoader will automatically look for LoaderMax-related nodes like <code>&lt;LoaderMax&gt;, &lt;ImageLoader&gt;, &lt;SWFLoader&gt;, &lt;XMLLoader&gt;, &lt;MP3Loader&gt;, &lt;DataLoader&gt;</code>, and <code>&lt;XMLLoader&gt;</code> inside the XML when it inits. If it finds any that have a <code>load="true"</code> attribute, it will begin loading them and integrate their progress into the XMLLoader's overall progress. Its <code>COMPLETE</code> event won't fire until all of these loaders have completed as well. If you prefer NOT to integrate the dynamically-created loader instances into the XMLLoader's overall <code>progress</code>, set <code>integrateProgress</code> to <code>false</code>. **/
		public function integrateProgress(value:Boolean):XMLLoaderVars {
			return _set("integrateProgress", value);
		}
		
		/** Maximum number of simultaneous connections that should be used while loading child loaders that were parsed from the XML and had their "load" attribute set to "true" (like &lt;ImageLoader url="1.jpg" load="true" /&gt;). A higher number will generally result in faster overall load times for the group. The default is 2. Sometimes there are limits imposed by the Flash Player itself or the browser or the user's system, but LoaderMax will do its best to honor the <code>maxConnections</code> you define. **/
		public function maxConnections(value:uint):XMLLoaderVars {
			return _set("maxConnections", value);
		}
		
		/** A handler function for <code>LoaderEvent.CHILD_OPEN</code> events which are dispatched each time any nested LoaderMax-related loaders that were defined in the XML begins loading. Make sure your onChildOpen function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onChildOpen(value:Function):XMLLoaderVars {
			return _set("onChildOpen", value);
		}
		
		/** A handler function for <code>LoaderEvent.CHILD_PROGRESS</code> events which are dispatched each time any nested LoaderMax-related loaders that were defined in the XML dispatches a <code>PROGRESS</code> event. To listen for changes in the XMLLoader's overall progress, use the <code>onProgress</code> special property instead. You can use the LoaderEvent's <code>target.progress</code> to get the child loader's progress value or use its <code>target.bytesLoaded</code> and <code>target.bytesTotal</code>. The LoaderEvent's <code>currentTarget</code> refers to the XMLLoader, so you can check its overall progress with the LoaderEvent's <code>currentTarget.progress</code>. Make sure your onChildProgress function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onChildProgress(value:Function):XMLLoaderVars {
			return _set("onChildProgress", value);
		}
		
		/** A handler function for <code>LoaderEvent.CHILD_COMPLETE</code> events which are dispatched each time any nested LoaderMax-related loaders that were defined in the XML finishes loading successfully. Make sure your onChildComplete function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onChildComplete(value:Function):XMLLoaderVars {
			return _set("onChildComplete", value);
		}
		
		/** A handler function for <code>LoaderEvent.CHILD_CANCEL</code> events which are dispatched each time loading is aborted on any nested LoaderMax-related loaders that were defined in the XML due to either an error or because another loader was prioritized in the queue or because <code>cancel()</code> was manually called on the child loader. Make sure your onChildCancel function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onChildCancel(value:Function):XMLLoaderVars {
			return _set("onChildCancel", value);
		}
		
		/** A handler function for <code>LoaderEvent.CHILD_FAIL</code> events which are dispatched each time any nested LoaderMax-related loaders that were defined in the XML fails (and its <code>status</code> chances to <code>LoaderStatus.FAILED</code>). Make sure your onChildFail function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onChildFail(value:Function):XMLLoaderVars {
			return _set("onChildFail", value);
		}
		
		/** A handler function for <code>LoaderEvent.INIT</code> events which are dispatched when the XML finishes loading and its contents are parsed (creating any dynamic XML-driven loader instances necessary). If any dynamic loaders are created and have a <code>load="true"</code> attribute, they will begin loading at this point and the XMLLoader's <code>COMPLETE</code> will not be dispatched until the loaders have completed as well. **/
		public function onInit(value:Function):XMLLoaderVars {
			return _set("onInit", value);
		}
		
		/** A handler function for <code>XMLLoader.RAW_LOAD</code> events which are dispatched when the loader finishes loading the XML but has <b>NOT</b> parsed the XML yet. This can be useful in rare situations when you want to alter the XML before it is parsed by XMLLoader (for identifying LoaderMax-related nodes like <code>&lt;ImageLoader&gt;</code>, etc.). Make sure your onRawLoad function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>) **/
		public function onRawLoad(value:Function):XMLLoaderVars {
			return _set("onRawLoad", value);
		}
		
		/** A String that should be prepended to all parsed LoaderMax-related loader URLs (from nodes like &lt;ImageLoader&gt;, &lt;XMLLoader&gt;, etc.) as soon as the XML has been parsed. For example, if your XML has the following node: <code>&lt;ImageLoader url="1.jpg" /&gt;</code> and <code>prependURLs</code> is set to "../images/", then the ImageLoader's url will end up being "../images/1.jpg". <code>prependURLs</code> affects ALL parsed loaders in the XML. However, if you have an <code>&lt;XMLLoader&gt;</code> node inside your XML that also loads another XML doc and you'd like to recursively prepend all of the URLs in this loader's XML as well as the subloading one and all of its children, use <code>recursivePrependURLs</code> instead of <code>prependURLs</code>. **/
		public function prependURLs(value:String):XMLLoaderVars {
			return _set("prependURLs", value);
		}
		
		/** A String that should be recursively prepended to all parsed LoaderMax-related loader URLs (from nodes like &lt;ImageLoader&gt;, &lt;XMLLoader&gt;, etc.). The functionality is identical to <code>prependURLs</code> except that it is recursive, affecting all parsed loaders in subloaded XMLLoaders (other XML files that this one loads too). For example, if your XML has the following node: <code>&lt;XMLLoader url="doc2.xml" /&gt;</code> and <code>recursivePrependURLs</code> is set to "../xml/", then the nested XMLLoader's URL will end up being "../xml/doc2.xml". Since it is recursive, parsed loaders inside doc2.xml <i>and</i> any other XML files that it loads will <i>all</i> have their URLs prepended. So if you load doc1.xml which loads doc2.xml which loads doc3.xml (due to <code>&lt;XMLLoader&gt;</code> nodes discovered in each XML file), <code>recursivePrependURLs</code> will affect all of the parsed LoaderMax-related URLs in all 3 documents. If you'd prefer to <i>only</i> have the URLs affected that are in the XML file that this XMLLoader is loading, use <code>prependURLs</code> instead of <code>recursivePrependURLs</code>. **/
		public function recursivePrependURLs(value:String):XMLLoaderVars {
			return _set("recursivePrependURLs", value);
		}
		
		/** By default, XMLLoader will parse any LoaderMax-related loaders in the XML and load any that have their "load" attribute set to "true" and then if any fail to load, they will simply be skipped. But if you prefer to have the XMLLoader fail immediately if one of the parsed loaders fails to load, set <code>skipFailed</code> to <code>false</code> (it is <code>true</code> by default). **/
		public function skipFailed(value:Boolean):XMLLoaderVars {
			return _set("skipFailed", value);
		}
		
		
//---- GETTERS / SETTERS -----------------------------------------------------------------
		
		/** The generic Object populated by all of the method calls in the XMLLoaderVars instance. This is the raw data that gets passed to the loader. **/
		public function get vars():Object {
			return _vars;
		}
		
		/** @private **/
		public function get isGSVars():Boolean {
			return true;
		}
		
	}
}