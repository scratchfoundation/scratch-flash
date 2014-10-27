/**
 * VERSION: 1.2
 * DATE: 2011-04-26
 * AS3
 * UPDATES AND DOCS AT: http://www.greensock.com/loadermax/
 **/
package com.greensock.loading.data {
	import flash.display.DisplayObject;
/**
 * Can be used instead of a generic Object to define the <code>vars</code> parameter of a LoaderMax's constructor. <br /><br />	
 * 
 * There are 2 primary benefits of using a LoaderMaxVars instance to define your LoaderMax variables:
 *  <ol>
 *		<li> In most code editors, code hinting will be activated which helps remind you which special properties are available in LoaderMax</li>
 *		<li> It enables strict data typing for improved debugging (ensuring, for example, that you don't define a Boolean value for <code>onComplete</code> where a Function is expected).</li>
 *  </ol><br />
 * 
 * The down side, of course, is that the code is more verbose and the LoaderMaxVars class adds slightly more kb to your swf.
 *
 * <b>USAGE:</b><br /><br />
 * Note that each method returns the LoaderMaxVars instance, so you can reduce the lines of code by method chaining (see example below).<br /><br />
 *	
 * <b>Without LoaderMaxVars:</b><br /><code>
 * new LoaderMax({name:"queue", maxConnections:1, onComplete:completeHandler, onProgress:progressHandler});</code><br /><br />
 * 
 * <b>With LoaderMaxVars</b><br /><code>
 * new LoaderMax(new LoaderMaxVars().name("queue").maxConnections(1).onComplete(completeHandler).onProgress(progressHandler));</code><br /><br />
 * 
 * <b>NOTES:</b><br />
 * <ul>
 *	<li> To get the generic vars object that LoaderMaxVars builds internally, simply access its "vars" property.
 * 		 In fact, if you want maximum backwards compatibility, you can tack ".vars" onto the end of your chain like this:<br /><code>
 * 		 new LoaderMax(new LoaderMaxVars().name("queue").maxConnections(1).vars);</code></li>
 *	<li> Using LoaderMaxVars is completely optional. If you prefer the shorter synatax with the generic Object, feel
 * 		 free to use it. The purpose of this class is simply to enable code hinting and to allow for strict data typing.</li>
 * </ul>
 * 
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 */	 
	public class LoaderMaxVars {
		/** @private **/
		public static const version:Number = 1.1;
		
		/** @private **/
		protected var _vars:Object;
		
		/**
		 * Constructor 
		 * @param vars A generic Object containing properties that you'd like to add to this LoaderMaxVars instance.
		 */
		public function LoaderMaxVars(vars:Object=null) {
			_vars = {};
			if (vars != null) {
				for (var p:String in vars) {
					_vars[p] = vars[p];
				}
			}
		}
		
		/** @private **/
		protected function _set(property:String, value:*):LoaderMaxVars {
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
		public function prop(property:String, value:*):LoaderMaxVars {
			return _set(property, value);
		}
		
		
//---- LOADERCORE PROPERTIES -----------------------------------------------------------------
		
		/** When <code>autoDispose</code> is <code>true</code>, the loader will be disposed immediately after it completes (it calls the <code>dispose()</code> method internally after dispatching its <code>COMPLETE</code> event). This will remove any listeners that were defined in the vars object (like onComplete, onProgress, onError, onInit). Once a loader is disposed, it can no longer be found with <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> - it is essentially destroyed but its content is not unloaded (you must call <code>unload()</code> or <code>dispose(true)</code> to unload its content). The default <code>autoDispose</code> value is <code>false</code>.**/
		public function autoDispose(value:Boolean):LoaderMaxVars {
			return _set("autoDispose", value);
		}
		
		/** If <code>true</code>, the LoaderMax instance will automatically call <code>load()</code> whenever you insert()/append()/prepend() a new loader whose status is <code>LoaderStatus.READY</code>. This basically makes it easy to create a LoaderMax queue and dump stuff into it whenever you want something to load without having to check the LoaderMax's status and call <code>load()</code> manually if it's not already loading. **/
		public function autoLoad(value:Boolean):LoaderMaxVars {
			return _set("autoLoad", value);
		}
		
		/** A name that is used to identify the loader instance. This name can be fed to the <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> methods or traced at any time. Each loader's name should be unique. If you don't define one, a unique name will be created automatically, like "loader21". **/
		public function name(value:String):LoaderMaxVars {
			return _set("name", value);
		}
		
		/** A handler function for <code>LoaderEvent.CANCEL</code> events which are dispatched when loading is aborted due to either a failure or because another loader was prioritized or <code>cancel()</code> was manually called. Make sure your onCancel function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onCancel(value:Function):LoaderMaxVars {
			return _set("onCancel", value);
		}
		
		/** A handler function for <code>LoaderEvent.COMPLETE</code> events which are dispatched when the loader has finished loading successfully. Make sure your onComplete function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onComplete(value:Function):LoaderMaxVars {
			return _set("onComplete", value);
		}
		
		/** A handler function for <code>LoaderEvent.ERROR</code> events which are dispatched whenever the loader experiences an error (typically an IO_ERROR or SECURITY_ERROR). An error doesn't necessarily mean the loader failed, however - to listen for when a loader fails, use the <code>onFail</code> special property. Make sure your onError function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onError(value:Function):LoaderMaxVars {
			return _set("onError", value);
		}
		
		/** A handler function for <code>LoaderEvent.FAIL</code> events which are dispatched whenever the loader fails and its <code>status</code> changes to <code>LoaderStatus.FAILED</code>. Make sure your onFail function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onFail(value:Function):LoaderMaxVars {
			return _set("onFail", value);
		}
		
		/** A handler function for <code>LoaderEvent.HTTP_STATUS</code> events. Make sure your onHTTPStatus function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). You can determine the httpStatus code using the LoaderEvent's <code>target.httpStatus</code> (LoaderItems keep track of their <code>httpStatus</code> when possible, although certain environments prevent Flash from getting httpStatus information).**/
		public function onHTTPStatus(value:Function):LoaderMaxVars {
			return _set("onHTTPStatus", value);
		}
		
		/** A handler function for <code>LoaderEvent.IO_ERROR</code> events which will also call the onError handler, so you can use that as more of a catch-all whereas <code>onIOError</code> is specifically for LoaderEvent.IO_ERROR events. Make sure your onIOError function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onIOError(value:Function):LoaderMaxVars {
			return _set("onIOError", value);
		}
		
		/** A handler function for <code>LoaderEvent.OPEN</code> events which are dispatched when the loader begins loading. Make sure your onOpen function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).**/
		public function onOpen(value:Function):LoaderMaxVars {
			return _set("onOpen", value);
		}
		
		/** A handler function for <code>LoaderEvent.PROGRESS</code> events which are dispatched whenever the <code>bytesLoaded</code> changes. Make sure your onProgress function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). You can use the LoaderEvent's <code>target.progress</code> to get the loader's progress value or use its <code>target.bytesLoaded</code> and <code>target.bytesTotal</code>.**/
		public function onProgress(value:Function):LoaderMaxVars {
			return _set("onProgress", value);
		}
		
		/** LoaderMax supports <i>subloading</i>, where an object can be factored into a parent's loading progress. If you want LoaderMax to require this loader as part of its parent SWFLoader's progress, you must set the <code>requireWithRoot</code> property to your swf's <code>root</code>. For example, <code>vars.requireWithRoot = this.root;</code>. **/
		public function requireWithRoot(value:DisplayObject):LoaderMaxVars {
			return _set("requireWithRoot", value);
		}
		
		
//---- LOADERMAX PROPERTIES -------------------------------------------------------------
		
		/** By default, when the LoaderMax begins to load it quickly loops through its children and if it finds any that don't have an <code>estimatedBytes</code> defined, it will briefly open a URLStream in order to attempt to determine its <code>bytesTotal</code>, immediately closing the URLStream once the value has been determined. This causes a brief delay initially, but greatly improves the accuracy of the <code>progress</code> and <code>bytesTotal</code> values. Set <code>auditSize</code> to <code>false</code> to prevent the LoaderMax from auditing its childrens' size (it is <code>true</code> by default). For maximum performance, it is best to define an <code>estimatedBytes</code> value for as many loaders as possible to avoid the delay caused by audits. When the LoaderMax audits an XMLLoader, it cannot recognize loaders that will be created from the XML data nor can it recognize loaders inside subloaded swf files from a SWFLoader (it would take far too long to load sufficient data for that - audits should be as fast as possible). If you do not set an appropriate <code>estimatedSize</code> for XMLLoaders or SWFLoaders that contain LoaderMax loaders, you'll notice that the parent LoaderMax's <code>progress</code> and <code>bytesTotal</code> change when the nested loaders are recognized (this is normal). To control the default <code>auditSize</code> value, use the static <code>LoaderMax.defaultAuditSize</code> property. **/
		public function auditSize(value:Boolean):LoaderMaxVars {
			return _set("auditSize", value);
		}
		
		/** Maximum number of simultaneous connections that should be used while loading the LoaderMax queue. A higher number will generally result in faster overall load times for the group. The default is 2. This value is instance-based, not system-wide, so if you have two LoaderMax instances that both have a <code>maxConnections</code> value of 3 and they are both loading, there could be up to 6 connections at a time total. Sometimes there are limits imposed by the Flash Player itself or the browser or the user's system, but LoaderMax will do its best to honor the <code>maxConnections</code> you define. **/
		public function maxConnections(value:uint):LoaderMaxVars {
			return _set("maxConnections", value);
		}
		
		/** If <code>skipFailed</code> is <code>true</code> (the default), any failed loaders in the queue will be skipped. Otherwise, the LoaderMax will stop when it hits a failed loader and the LoaderMax's status will become <code>LoaderStatus.FAILED</code>. **/
		public function skipFailed(value:Boolean):LoaderMaxVars {
			return _set("skipFailed", value);
		}
		
		/** If <code>skipPaused</code> is <code>true</code> (the default), any paused loaders in the queue will be skipped. Otherwise, the LoaderMax will stop when it hits a paused loader and the LoaderMax's status will become <code>LoaderStatus.FAILED</code>. **/
		public function skipPaused(value:Boolean):LoaderMaxVars {
			return _set("skipPaused", value);
		}
		
		/** An array of loaders (ImageLoaders, SWFLoaders, XMLLoaders, MP3Loaders, other LoaderMax instances, etc.) that should be immediately inserted into the LoaderMax. **/
		public function loaders(value:Array):LoaderMaxVars {
			return _set("loaders", value);
		}

		/** A handler function for <code>LoaderEvent.CHILD_OPEN</code> events which are dispatched each time one of the loader's children (or any descendant) begins loading. Make sure your onChildOpen function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onChildOpen(value:Function):LoaderMaxVars {
			return _set("onChildOpen", value);
		}
		
		/** A handler function for <code>LoaderEvent.CHILD_PROGRESS</code> events which are dispatched each time one of the loader's children (or any descendant) dispatches a <code>PROGRESS</code> event. To listen for changes in the LoaderMax's overall progress, use the <code>onProgress</code> special property instead. You can use the LoaderEvent's <code>target.progress</code> to get the child loader's progress value or use its <code>target.bytesLoaded</code> and <code>target.bytesTotal</code>. The LoaderEvent's <code>currentTarget</code> refers to the LoaderMax, so you can check its overall progress with the LoaderEvent's <code>currentTarget.progress</code>. Make sure your onChildProgress function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onChildProgress(value:Function):LoaderMaxVars {
			return _set("onChildProgress", value);
		}
		
		/** A handler function for <code>LoaderEvent.CHILD_COMPLETE</code> events which are dispatched each time one of the loader's children (or any descendant) finishes loading successfully. Make sure your onChildComplete function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onChildComplete(value:Function):LoaderMaxVars {
			return _set("onChildComplete", value);
		}
		
		/** A handler function for <code>LoaderEvent.CHILD_CANCEL</code> events which are dispatched each time loading is aborted on one of the loader's children (or any descendant) due to either an error or because another loader was prioritized in the queue or because <code>cancel()</code> was manually called on the child loader. Make sure your onChildCancel function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onChildCancel(value:Function):LoaderMaxVars {
			return _set("onChildCancel", value);
		}
		
		/** A handler function for <code>LoaderEvent.CHILD_FAIL</code> events which are dispatched each time one of the loader's children (or any descendant) fails (and its <code>status</code> chances to <code>LoaderStatus.FAILED</code>). Make sure your onChildFail function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). **/
		public function onChildFail(value:Function):LoaderMaxVars {
			return _set("onChildFail", value);
		}
		
		/** A handler function for <code>LoaderEvent.SCRIPT_ACCESS_DENIED</code> events which are dispatched when one of the LoaderMax's children (or any descendant) is loaded from another domain and no crossdomain.xml is in place to grant full script access for things like smoothing or BitmapData manipulation. Make sure your function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).**/
		public function onScriptAccessDenied(value:Function):LoaderMaxVars {
			return _set("onScriptAccessDenied", value);
		}

		
//---- GETTERS / SETTERS -----------------------------------------------------------------
		
		/** The generic Object populated by all of the method calls in the LoaderMaxVars instance. This is the raw data that gets passed to the loader. **/
		public function get vars():Object {
			return _vars;
		}
		
		/** @private **/
		public function get isGSVars():Boolean {
			return true;
		}
		
		
	}
}