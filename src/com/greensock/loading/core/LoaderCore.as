/**
 * VERSION: 1.8993
 * DATE: 2012-02-24
 * AS3
 * UPDATES AND DOCS AT: http://www.greensock.com/loadermax/
 **/
package com.greensock.loading.core {
	import com.greensock.events.LoaderEvent;
	import com.greensock.loading.LoaderMax;
	import com.greensock.loading.LoaderStatus;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.ProgressEvent;
	import flash.net.LocalConnection;
	import flash.system.Capabilities;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	/** Dispatched when the loader starts loading. **/
	[Event(name="open", 	type="com.greensock.events.LoaderEvent")]
	/** Dispatched each time the <code>bytesLoaded</code> value changes while loading (indicating progress). **/
	[Event(name="progress", type="com.greensock.events.LoaderEvent")]
	/** Dispatched when the loader completes. **/
	[Event(name="complete", type="com.greensock.events.LoaderEvent")]
	/** Dispatched when the loader is canceled while loading which can occur either because of a failure or when a sibling loader is prioritized in a LoaderMax queue. **/
	[Event(name="cancel", 	type="com.greensock.events.LoaderEvent")]
	/** Dispatched when the loader fails. **/
	[Event(name="fail", 	type="com.greensock.events.LoaderEvent")]
	/** Dispatched when the loader experiences some type of error, like a SECURITY_ERROR or IO_ERROR. **/
	[Event(name="error", 	type="com.greensock.events.LoaderEvent")]
	/** Dispatched when the loader unloads (which happens when either <code>unload()</code> or <code>dispose(true)</code> is called or if a loader is canceled while in the process of loading). **/
	[Event(name="unload", 	type="com.greensock.events.LoaderEvent")]
/**
 * Serves as the base class for GreenSock loading tools like <code>LoaderMax, ImageLoader, XMLLoader, SWFLoader</code>, etc. 
 * There is no reason to use this class on its own. Please see the documentation for the other classes.
 * <br /><br />
 * 
 * <b>Copyright 2012, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 */	
	public class LoaderCore extends EventDispatcher {
		/** @private **/
		public static const version:Number = 1.87;
		
		/** @private **/
		protected static var _loaderCount:uint = 0;
		/** @private **/
		protected static var _rootLookup:Dictionary = new Dictionary(false);
		/** @private **/
		protected static var _isLocal:Boolean;
		/** @private **/
		protected static var _globalRootLoader:LoaderMax;
		/** @private **/
		protected static var _listenerTypes:Object = {onOpen:"open", 
													  onInit:"init", 
													  onComplete:"complete", 
													  onProgress:"progress", 
													  onCancel:"cancel",
													  onFail:"fail",
													  onError:"error", 
													  onSecurityError:"securityError", 
													  onHTTPStatus:"httpStatus", 
													  onIOError:"ioError", 
													  onScriptAccessDenied:"scriptAccessDenied", 
													  onChildOpen:"childOpen", 
													  onChildCancel:"childCancel",
													  onChildComplete:"childComplete", 
													  onChildProgress:"childProgress",
													  onChildFail:"childFail",
													  onRawLoad:"rawLoad",
													  onUncaughtError:"uncaughtError"};
		/** @private **/
		protected static var _types:Object = {};
		/** @private **/
		protected static var _extensions:Object = {};
		
		/** @private **/
		protected var _cachedBytesLoaded:uint;
		/** @private **/
		protected var _cachedBytesTotal:uint;
		/** @private **/
		protected var _status:int;
		/** @private **/
		protected var _prePauseStatus:int;
		/** @private **/
		protected var _dispatchProgress:Boolean;
		/** @private **/
		protected var _rootLoader:LoaderMax;
		/** @private **/
		protected var _cacheIsDirty:Boolean;
		/** @private **/
		protected var _auditedSize:Boolean;
		/** @private **/
		protected var _dispatchChildProgress:Boolean;
		/** @private **/
		protected var _type:String;
		/** @private used to store timing information. When the loader begins loading, the startTime is stored here. When it completes or fails, it is set to the total elapsed time between when it started and ended. We reuse this variable like this in order to minimize size. **/
		protected var _time:uint;
		/** @private **/
		protected var _content:*;
		
		/** An object containing optional configuration details, typically passed through a constructor parameter. For example: <code>new SWFLoader("assets/file.swf", {name:"swf1", container:this, autoPlay:true, noCache:true})</code>. See the constructor's documentation for details about what special properties are recognized. **/
		public var vars:Object;
		/** A name that you use to identify the loader instance. This name can be fed to the <code>getLoader()</code> or <code>getContent()</code> methods or traced at any time. Each loader's name should be unique. If you don't define one, a unique name will be created automatically, like "loader21". **/
		public var name:String;
		/** When <code>autoDispose</code> is <code>true</code>, the loader will be disposed immediately after it completes (it calls the <code>dispose()</code> method internally after dispatching its <code>COMPLETE</code> event). This will remove any listeners that were defined in the vars object (like onComplete, onProgress, onError, onInit). Once a loader is disposed, it can no longer be found with <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> - it is essentially destroyed but its content is <strong>not</strong> unloaded (you must call <code>unload()</code> or <code>dispose(true)</code> to unload its content). The default <code>autoDispose</code> value is <code>false</code>. **/
		public var autoDispose:Boolean;
		
		/**
		 * Constructor
		 * 
		 * @param vars An object containing optional parameters like <code>estimatedBytes, name, autoDispose, onComplete, onProgress, onError</code>, etc. For example, <code>{estimatedBytes:2400, name:"myImage1", onComplete:completeHandler}</code>.
		 */
		public function LoaderCore(vars:Object=null) {
			this.vars = (vars != null) ? vars : {};
			if (this.vars.isGSVars) {
				this.vars = this.vars.vars;
			}
			this.name = (this.vars.name != undefined && String(this.vars.name) != "") ? this.vars.name : "loader" + (_loaderCount++);
			_cachedBytesLoaded = 0;
			_cachedBytesTotal = (uint(this.vars.estimatedBytes) != 0) ? uint(this.vars.estimatedBytes) : LoaderMax.defaultEstimatedBytes;
			this.autoDispose = Boolean(this.vars.autoDispose == true);
			_status = (this.vars.paused == true) ? LoaderStatus.PAUSED : LoaderStatus.READY;
			_auditedSize = Boolean(uint(this.vars.estimatedBytes) != 0 && this.vars.auditSize != true);
			
			if (_globalRootLoader == null) {
				if (this.vars.__isRoot == true) {
					return;
				}
				_globalRootLoader = new LoaderMax({name:"root", __isRoot:true});
				_isLocal = Boolean(Capabilities.playerType == "Desktop" || (new LocalConnection( ).domain == "localhost")); //alt method (Capabilities.playerType != "ActiveX" && Capabilities.playerType != "PlugIn") doesn't work when testing locally in an html wrapper
			}
			
			_rootLoader = (this.vars.requireWithRoot is DisplayObject) ? _rootLookup[this.vars.requireWithRoot] : _globalRootLoader;
			
			if (_rootLoader == null) {
				_rootLookup[this.vars.requireWithRoot] = _rootLoader = new LoaderMax();
				_rootLoader.name = "subloaded_swf_" + ((this.vars.requireWithRoot.loaderInfo != null) ? this.vars.requireWithRoot.loaderInfo.url : String(_loaderCount));
				_rootLoader.skipFailed = false;
			}
			
			for (var p:String in _listenerTypes) {
				if (p in this.vars && this.vars[p] is Function) {
					this.addEventListener(_listenerTypes[p], this.vars[p], false, 0, true);
				}
			}
			
			_rootLoader.append(this);
		}
		
		/**
		 * Loads the loader's content, optionally flushing any previously loaded content first. For example, 
		 * a LoaderMax may have already loaded 4 out of the 10 loaders in its queue but if you want it to
		 * flush the data and start again, set the <code>flushContent</code> parameter to <code>true</code> (it is 
		 * <code>false</code> by default). 
		 * 
		 * @param flushContent If <code>true</code>, any previously loaded content in the loader will be flushed so that it loads again from the beginning. For example, a LoaderMax may have already loaded 4 out of the 10 loaders in its queue but if you want it to flush the data and start again, set the <code>flushContent</code> parameter to <code>true</code> (it is <code>false</code> by default). 
		 */
		public function load(flushContent:Boolean=false):void {
			var time:uint = getTimer();
			if (this.status == LoaderStatus.PAUSED) { //use this.status instead of _status so that LoaderMax instances have a chance to do their magic in the getter and make sure their status is calibrated properly in case any of its children changed status after the LoaderMax completed (maybe they were manually loaded or failed, etc.).
				_status = (_prePauseStatus <= LoaderStatus.LOADING) ? LoaderStatus.READY : _prePauseStatus;
				if (_status == LoaderStatus.READY && this is LoaderMax) {
					time -= _time; //when a LoaderMax is resumed, we should offset the start time.
				}
			}
			if (flushContent || _status == LoaderStatus.FAILED) {
				_dump(1, LoaderStatus.READY);
			}
			
			if (_status == LoaderStatus.READY) {
				_status = LoaderStatus.LOADING;
				_time = time;
				_load();
				if (this.progress < 1) { //in some cases, an OPEN event should be dispatched, like if load() is called on an empty LoaderMax, it will just dispatch a PROGRESS and COMPLETE event right away. It wouldn't make sense to dispatch an OPEN event right after that.
					dispatchEvent(new LoaderEvent(LoaderEvent.OPEN, this));
				}
			} else if (_status == LoaderStatus.COMPLETED) {
				_completeHandler(null);
			}
		}
		
		/** @private Only called when load() was called and the _status was LoaderStatus.READY - we use this internally to make it simpler to extend (the conditional logic stays in the main <code>load()</code> method). **/
		protected function _load():void {
			//override in subclasses
		}
		
		/** Pauses the loader immediately. This is the same as setting the <code>paused</code> property to <code>true</code>. Some loaders may not stop loading immediately in order to work around some garbage collection issues in the Flash Player, but they will stop as soon as possible after calling <code>pause()</code>. **/
		public function pause():void {
			this.paused = true;
		}
		
		/** Unpauses the loader and resumes loading immediately. **/ 
		public function resume():void {
			this.paused = false;
			load(false);
		}
		
		/** 
		 * If the loader is currently loading (<code>status</code> is <code>LoaderStatus.LOADING</code>), it will be canceled 
		 * immediately and its status will change to <code>LoaderStatus.READY</code>. This does <strong>NOT</strong> pause the 
		 * loader - it simply halts the progress and it remains eligible for loading by any of its parent LoaderMax instances. 
		 * A paused loader, however, cannot be loaded by any of its parent LoaderMax instances until you unpause it (by either 
		 * calling <code>resume()</code> or setting its <code>paused</code> property to false). 
		 * @see #unload()
		 * @see #dispose()
		 **/
		public function cancel():void {
			if (_status == LoaderStatus.LOADING) {
				_dump(0, LoaderStatus.READY);
			}
		}
		
		/** 
		 * @private 
		 * Cancels, unloads, and/or disposes of the loader depending on the <code>scrubLevel</code>. This consolidates
		 * the actions into a single function to conserve file size and because many of the same tasks must 
		 * be performed regardless of the scrubLevel, so this eliminates redundant code.
		 * 
		 * @param scrubLevel 0 = cancel, 1 = unload, 2 = dispose, 3 = flush (like unload and dispose, but in the case of ImageLoaders, SWFLoaders, and VideoLoaders, it also removes the ContentDisplay from the display list)
		 * @param newStatus The new LoaderStatus to which the loader should be set. 
		 * @param suppressEvents To prevent events from being dispatched (like CANCEL or DISPOSE or PROGRESS), set <code>suppressEvents</code> to <code>true</code>. 
		 **/
		protected function _dump(scrubLevel:int=0, newStatus:int=0, suppressEvents:Boolean=false):void {
			_content = null;
			var isLoading:Boolean = Boolean(_status == LoaderStatus.LOADING);
			if (_status == LoaderStatus.PAUSED && newStatus != LoaderStatus.PAUSED && newStatus != LoaderStatus.FAILED) {
				_prePauseStatus = newStatus;
			} else if (_status != LoaderStatus.DISPOSED) {
				_status = newStatus;
			}
			if (isLoading) {
				_time = getTimer() - _time;
			}
			_cachedBytesLoaded = 0;
			if (_status < LoaderStatus.FAILED) {
				if (this is LoaderMax) {
					_calculateProgress();
				}
				if (_dispatchProgress && !suppressEvents) {
					dispatchEvent(new LoaderEvent(LoaderEvent.PROGRESS, this));
				}
			}
			if (!suppressEvents) {
				if (isLoading) {
					dispatchEvent(new LoaderEvent(LoaderEvent.CANCEL, this));
				}
				if (scrubLevel != 2) {
					dispatchEvent(new LoaderEvent(LoaderEvent.UNLOAD, this));
				}
			}
			if (newStatus == LoaderStatus.DISPOSED) {
				if (!suppressEvents) {
					dispatchEvent(new Event("dispose"));
				}
				for (var p:String in _listenerTypes) {
					if (p in this.vars && this.vars[p] is Function) {
						this.removeEventListener(_listenerTypes[p], this.vars[p]);
					}
				}
			}
		}
		
		/** 
		 * Removes any content that was loaded and sets <code>bytesLoaded</code> back to zero. When you
		 * <code>unload()</code> a LoaderMax instance, it will also call <code>unload()</code> on all of its 
		 * children as well. If the loader is in the process of loading, it will automatically be canceled.
		 * 
		 * @see #dispose()
		 **/
		public function unload():void {
			_dump(1, LoaderStatus.READY);
		}
		
		/** 
		 * Disposes of the loader and releases it internally for garbage collection. If it is in the process of loading, it will also 
		 * be cancelled immediately. By default, <code>dispose()</code> <strong>does NOT unload its content</strong>, but
		 * you may set the <code>flushContent</code> parameter to <code>true</code> in order to flush/unload the <code>content</code> as well
		 * (in the case of ImageLoaders, SWFLoaders, and VideoLoaders, this will also destroy its ContentDisplay Sprite, removing it
		 * from the display list if necessary). When a loader is disposed, all of the listeners that were added through the 
		 * <code>vars</code> object (like <code>{onComplete:completeHandler, onProgress:progressHandler}</code>) are removed. 
		 * If you manually added listeners, though, you should remove those yourself.
		 * 
		 * @param flushContent If <code>true</code>, the loader's <code>content</code> will be unloaded as well (<code>flushContent</code> is <code>false</code> by default). In the case of ImageLoaders, SWFLoaders, and VideoLoaders, their ContentDisplay will also be removed from the display list if necessary when <code>flushContent</code> is <code>true</code>.
		 * @see #unload()
		 **/
		public function dispose(flushContent:Boolean=false):void {
			_dump((flushContent ? 3 : 2), LoaderStatus.DISPOSED);
		}
		
		/** 
		 * Immediately prioritizes the loader inside any LoaderMax instances that contain it,
		 * forcing it to the top position in their queue and optionally calls <code>load()</code>
		 * immediately as well. If one of its parent LoaderMax instances is currently loading a 
		 * different loader, that one will be temporarily cancelled. <br /><br />
		 * 
		 * By contrast, when <code>load()</code> is called, it doesn't change the loader's position/index 
		 * in any LoaderMax queues. For example, if a LoaderMax is working on loading the first object in 
		 * its queue, you can call load() on the 20th item and it will honor your request without 
		 * changing its index in the queue. <code>prioritize()</code>, however, affects the position 
		 * in the queue and optionally loads it immediately as well.<br /><br />
		 * 
		 * So even if your LoaderMax hasn't begun loading yet, you could <code>prioritize(false)</code> 
		 * a loader and it will rise to the top of all LoaderMax instances to which it belongs, but not 
		 * start loading yet. If the goal is to load something immediately, you can just use the 
		 * <code>load()</code> method.<br /><br />
		 * 
		 * You may use the static <code>LoaderMax.prioritize()</code> method instead and simply pass 
		 * the name or url of the loader as the first parameter like:<br /><br /><code>
		 * 
		 * LoaderMax.prioritize("myLoaderName", true);</code><br /><br />
		 * 
		 * @param loadNow If <code>true</code> (the default), the loader will start loading immediately (otherwise it is simply placed at the top the queue in any LoaderMax instances to which it belongs).
		 * @see #load()
		 **/
		public function prioritize(loadNow:Boolean=true):void {
			dispatchEvent(new Event("prioritize"));
			if (loadNow && _status != LoaderStatus.COMPLETED && _status != LoaderStatus.LOADING) {
				load(false);
			} 
		}
		
		/** @inheritDoc **/
		override public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false):void {
			if (type == LoaderEvent.PROGRESS) {
				_dispatchProgress = true;
			} else if (type == LoaderEvent.CHILD_PROGRESS && this is LoaderMax) {
				_dispatchChildProgress = true;
			}
			super.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		/** @private **/
		protected function _calculateProgress():void {
			//override in subclasses if necessary
		}
		
		/**
		 * Attempts loading just enough of the content to accurately determine the <code>bytesTotal</code> 
		 * in order to improve the accuracy of the <code>progress</code> property. Once the 
		 * <code>bytesTotal</code> has been determined or the <code>auditSize()</code> attempt fails due
		 * to an error (typically IO_ERROR or SECURITY_ERROR), the <code>auditedSize</code> property will be 
		 * set to <code>true</code>. Auditing the size opens a URLStream that will be closed 
		 * as soon as a response is received.
		 **/
		public function auditSize():void {
			//override in subclasses
		}
		
		/** Returns information about the loader, like its type, its <code>name</code>, and its <code>url</code> (if it has one). **/
		override public function toString():String {
			return _type + " '" + this.name + "'" + ((this is LoaderItem) ? " (" + (this as LoaderItem).url + ")" : "");
		}
		
//---- STATIC METHODS ------------------------------------------------------------------------------------
		
		/** @private **/
		protected static function _activateClass(type:String, loaderClass:Class, extensions:String):Boolean {
			if (type != "") {
				_types[type.toLowerCase()] = loaderClass;
			}
			var a:Array = extensions.split(",");
			var i:int = a.length;
			while (--i > -1) {
				_extensions[a[i]] = loaderClass;
			}
			return true;
		}
		
		
//---- EVENT HANDLERS ------------------------------------------------------------------------------------
		
		/** @private **/
		protected function _progressHandler(event:Event):void {
			if (event is ProgressEvent) {
				_cachedBytesLoaded = (event as ProgressEvent).bytesLoaded;
				_cachedBytesTotal = (event as ProgressEvent).bytesTotal;
				if (!_auditedSize) {
					_auditedSize = true;
					dispatchEvent(new Event("auditedSize"));
				}
			}
			if (_dispatchProgress && _status == LoaderStatus.LOADING && _cachedBytesLoaded != _cachedBytesTotal) { 
				dispatchEvent(new LoaderEvent(LoaderEvent.PROGRESS, this));
			}
		}
		
		/** @private **/
		protected function _completeHandler(event:Event=null):void {
			_cachedBytesLoaded = _cachedBytesTotal;
			if (_status != LoaderStatus.COMPLETED) {
				dispatchEvent(new LoaderEvent(LoaderEvent.PROGRESS, this));
				_status = LoaderStatus.COMPLETED;
				_time = getTimer() - _time;
			}
			dispatchEvent(new LoaderEvent(LoaderEvent.COMPLETE, this));
			if (this.autoDispose) {
				dispose();
			}
		}
		
		/** @private **/
		protected function _errorHandler(event:Event):void {
			var target:Object = event.target; //trigger the LoaderEvent's target getter once first in order to ensure that it reports properly - see the notes in LoaderEvent.target for more details.
			target = (event is LoaderEvent && this.hasOwnProperty("getChildren")) ? event.target : this;
			var text:String = ""; 
			if (event.hasOwnProperty("error") && Object(event).error is Error) {
				text = Object(event).error.message;
			} else if (event.hasOwnProperty("text")) {
				text = Object(event).text;
			}
			if (event.type != LoaderEvent.ERROR && event.type != LoaderEvent.FAIL && this.hasEventListener(event.type)) {
				dispatchEvent(new LoaderEvent(event.type, target, text, event));
			}
			if (event.type != "uncaughtError") {
				trace("----\nError on " + this.toString() + ": " + text + "\n----");
				if (this.hasEventListener(LoaderEvent.ERROR)) {
					dispatchEvent(new LoaderEvent(LoaderEvent.ERROR, target, this.toString() + " > " + text, event));
				}
			}
		}
		
		/** @private **/
		protected function _failHandler(event:Event, dispatchError:Boolean=true):void {
			_dump(0, LoaderStatus.FAILED);
			if (dispatchError) {
				_errorHandler(event);
			} else {
				var target:Object = event.target; //trigger the LoaderEvent's target getter once first in order to ensure that it reports properly - see the notes in LoaderEvent.target for more details.
			}
			dispatchEvent(new LoaderEvent(LoaderEvent.FAIL, ((event is LoaderEvent && this.hasOwnProperty("getChildren")) ? event.target : this), this.toString() + " > " + (event as Object).text, event));
		}
		
		/** @private **/
		protected function _passThroughEvent(event:Event):void {
			var type:String = event.type;
			var target:Object = this;
			if (this.hasOwnProperty("getChildren")) {
				if (event is LoaderEvent) {
					target = event.target;
				}
				if (type == "complete") {
					type = "childComplete";
				} else if (type == "open") {
					type = "childOpen";
				} else if (type == "cancel") {
					type = "childCancel";
				} else if (type == "fail") {
					type = "childFail";
				}
			}
			if (this.hasEventListener(type)) {
				dispatchEvent(new LoaderEvent(type, target, (event.hasOwnProperty("text") ? Object(event).text : ""), (event is LoaderEvent && LoaderEvent(event).data != null) ? LoaderEvent(event).data : event));
			}
		}
		

//---- GETTERS / SETTERS -------------------------------------------------------------------------
		
		/** If a loader is paused, its progress will halt and any LoaderMax instances to which it belongs will either skip over it or stop when its position is reached in the queue (depending on whether or not the LoaderMax's <code>skipPaused</code> property is <code>true</code>). **/
		public function get paused():Boolean {
			return Boolean(_status == LoaderStatus.PAUSED);
		}
		public function set paused(value:Boolean):void {
			if (value && _status != LoaderStatus.PAUSED) {
				_prePauseStatus = _status;
				if (_status == LoaderStatus.LOADING) {
					_dump(0, LoaderStatus.PAUSED);
				}
				_status = LoaderStatus.PAUSED;
				
			} else if (!value && _status == LoaderStatus.PAUSED) {
				if (_prePauseStatus == LoaderStatus.LOADING) {
					load(false); //will change the _status for us inside load()
				} else {
					_status = _prePauseStatus || LoaderStatus.READY;
				}
			}
		}
		
		/** Integer code indicating the loader's status; options are <code>LoaderStatus.READY, LoaderStatus.LOADING, LoaderStatus.COMPLETED, LoaderStatus.PAUSED,</code> and <code>LoaderStatus.DISPOSED</code>. **/
		public function get status():int {
			return _status;
		}
		
		/** Bytes loaded **/
		public function get bytesLoaded():uint {
			if (_cacheIsDirty) {
				_calculateProgress();
			}
			return _cachedBytesLoaded;
		}
		
		/** Total bytes that are to be loaded by the loader. Initially, this value is set to the <code>estimatedBytes</code> if one was defined in the <code>vars</code> object via the constructor, or it defaults to <code>LoaderMax.defaultEstimatedBytes</code>. When the loader loads enough of the content to accurately determine the bytesTotal, it will do so automatically. **/
		public function get bytesTotal():uint {
			if (_cacheIsDirty) {
				_calculateProgress();
			}
			return _cachedBytesTotal;
		}
		
		/** A value between 0 and 1 indicating the overall progress of the loader. When nothing has loaded, it will be 0; when it is halfway loaded, <code>progress</code> will be 0.5, and when it is fully loaded it will be 1. **/
		public function get progress():Number {
			return (this.bytesTotal != 0) ? _cachedBytesLoaded / _cachedBytesTotal : (_status == LoaderStatus.COMPLETED) ? 1 : 0;
		}
		
		/** @private Every loader is associated with a root-level LoaderMax which will be the _globalQueue unless the loader had a <code>requireWithRoot</code> value passed into the constructor via the <code>vars</code> parameter. This enables us to chain things properly in subloaded swfs if, for example, a subloaded swf has LoaderMax instances of its own and we want the SWFLoader to accurately report its loading status based not only on the subloaded swf, but also the subloaded swf's LoaderMax instances. **/
		public function get rootLoader():LoaderMax {
			return _rootLoader;
		}
		
		/** 
		 * The content that was loaded by the loader which varies by the type of loader:
		 * <ul>
		 * 		<li><strong> ImageLoader </strong> - A <code>com.greensock.loading.display.ContentDisplay</code> (a Sprite) which contains the ImageLoader's <code>rawContent</code> (a <code>flash.display.Bitmap</code> unless script access was denied in which case <code>rawContent</code> will be a <code>flash.display.Loader</code> to avoid security errors). For Flex users, you can set <code>LoaderMax.defaultContentDisplay</code> to <code>FlexContentDisplay</code> in which case ImageLoaders, SWFLoaders, and VideoLoaders will return a <code>com.greensock.loading.display.FlexContentDisplay</code> instance instead.</li>
		 * 		<li><strong> SWFLoader </strong> - A <code>com.greensock.loading.display.ContentDisplay</code> (a Sprite) which contains the SWFLoader's <code>rawContent</code> (the swf's <code>root</code> DisplayObject unless script access was denied in which case <code>rawContent</code> will be a <code>flash.display.Loader</code> to avoid security errors). For Flex users, you can set <code>LoaderMax.defaultContentDisplay</code> to <code>FlexContentDisplay</code> in which case ImageLoaders, SWFLoaders, and VideoLoaders will return a <code>com.greensock.loading.display.FlexContentDisplay</code> instance instead.</li>
		 * 		<li><strong> VideoLoader </strong> - A <code>com.greensock.loading.display.ContentDisplay</code> (a Sprite) which contains the VideoLoader's <code>rawContent</code> (a Video object to which the NetStream was attached). For Flex users, you can set <code>LoaderMax.defaultContentDisplay</code> to <code>FlexContentDisplay</code> in which case ImageLoaders, SWFLoaders, and VideoLoaders will return a <code>com.greensock.loading.display.FlexContentDisplay</code> instance instead.</li>
		 * 		<li><strong> XMLLoader </strong> - XML</li>
		 * 		<li><strong> DataLoader </strong>
		 * 			<ul>
		 * 				<li><code>String</code> if the DataLoader's <code>format</code> vars property is <code>"text"</code> (the default).</li>
		 * 				<li><code>flash.utils.ByteArray</code> if the DataLoader's <code>format</code> vars property is <code>"binary"</code>.</li>
		 * 				<li><code>flash.net.URLVariables</code> if the DataLoader's <code>format</code> vars property is <code>"variables"</code>.</li>
		 * 			</ul></li>
		 * 		<li><strong> CSSLoader </strong> - <code>flash.text.StyleSheet</code></li>
		 * 		<li><strong> MP3Loader </strong> - <code>flash.media.Sound</code></li>
		 * 		<li><strong> LoaderMax </strong> - an array containing the content objects from each of its child loaders.</li>
		 * </ul> 
		 **/
		public function get content():* {
			return _content;
		}
		
		/** 
		 * Indicates whether or not the loader's <code>bytesTotal</code> value has been set by any of the following:
		 * <ul>
		 * 		<li>Defining an <code>estimatedBytes</code> in the <code>vars</code> object passed to the constructor</li>
		 * 		<li>Calling <code>auditSize()</code> and getting a response (an error is also considered a response)</li>
		 * 		<li>When a LoaderMax instance begins loading, it will automatically force a call to <code>auditSize()</code> for any of its children that don't have an <code>estimatedBytes</code> defined. You can disable this behavior by passing <code>auditSize:false</code> through the constructor's <code>vars</code> object.</li>
		 * </ul>
		 **/
		public function get auditedSize():Boolean {
			return _auditedSize;
		}
		
		/** 
		 * The number of seconds that elapsed between when the loader began and when it either completed, failed, 
		 * or was canceled. You may check a loader's <code>loadTime</code> anytime, not just after it completes. For
		 * example, you could access this value in an onProgress handler and you'd see it steadily increase as the loader
		 * loads and then when it completes, <code>loadTime</code> will stop increasing. LoaderMax instances ignore 
		 * any pauses when calculating this value, so if a LoaderMax begins loading and after 1 second it gets paused, 
		 * and then 10 seconds later it resumes and takes an additional 14 seconds to complete, its <code>loadTime</code> 
		 * would be 15, <strong>not</strong> 25.
		 **/
		public function get loadTime():Number {
			if (_status == LoaderStatus.READY) {
				return 0;
			} else if (_status == LoaderStatus.LOADING) {
				return (getTimer() - _time) / 1000;
			} else {
				return _time / 1000;
			}
		}
		
	}
}