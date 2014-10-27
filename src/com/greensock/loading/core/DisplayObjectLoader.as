/**
 * VERSION: 1.898
 * DATE: 2012-01-19
 * AS3
 * UPDATES AND DOCS AT: http://www.greensock.com/loadermax/
 **/
package com.greensock.loading.core {
	import com.greensock.events.LoaderEvent;
	import com.greensock.loading.LoaderMax;
	import com.greensock.loading.LoaderStatus;
	import com.greensock.loading.display.ContentDisplay;
	
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.net.LocalConnection;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.Capabilities;
	import flash.system.LoaderContext;
	import flash.system.Security;
	import flash.system.SecurityDomain;

/**
 * Serves as the base class for SWFLoader and ImageLoader. There is no reason to use this class on its own. 
 * Please refer to the documentation for the other classes.
 * <br /><br />
 * 
 * <b>Copyright 2012, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 */	
	public class DisplayObjectLoader extends LoaderItem {
		/** By default, LoaderMax will automatically attempt to force garbage collection when a SWFLoader or ImageLoader is unloaded or cancelled but if you prefer to skip this measure, set defaultAutoForceGC to <code>false</code>. If garbage collection isn't forced, sometimes Flash doesn't completely unload swfs/images properly, particularly if there is audio embedded in the root timeline. **/
		public static var defaultAutoForceGC:Boolean = true;
		/** @private the Sprite to which the EVENT_LISTENER was attached for forcing garbage collection after 1 frame (improves performance especially when multiple loaders are disposed at one time). **/
		protected static var _gcDispatcher:Sprite;
		/** @private **/
		protected static var _gcCycles:uint = 0;
		/** @private **/
		protected var _loader:Loader;
		/** @private **/
		protected var _sprite:Sprite;
		/** @private **/
		protected var _context:LoaderContext;
		/** @private **/
		protected var _initted:Boolean;
		/** @private used by SWFLoader when the loader is canceled before the SWF ever had a chance to init which causes garbage collection issues. We slip into stealthMode at that point, wait for it to init, and then cancel the _loader's loading.**/
		protected var _stealthMode:Boolean;
		/** @private allows us to apply a LoaderContext to the file size audit (only if necessary - URLStream is better/faster/smaller and works great unless we run into security errors because of a missing crossdomain.xml file) **/
		protected var _fallbackAudit:Loader;
		
		/**
		 * Constructor
		 * 
		 * @param urlOrRequest The url (<code>String</code>) or <code>URLRequest</code> from which the loader should get its content
		 * @param vars An object containing optional parameters like <code>estimatedBytes, name, autoDispose, onComplete, onProgress, onError</code>, etc. For example, <code>{estimatedBytes:2400, name:"myImage1", onComplete:completeHandler}</code>.
		 */
		public function DisplayObjectLoader(urlOrRequest:*, vars:Object=null) {
			super(urlOrRequest, vars);
			_refreshLoader(false);
			if (LoaderMax.contentDisplayClass is Class) {
				_sprite = new LoaderMax.contentDisplayClass(this);
				if (!_sprite.hasOwnProperty("rawContent")) {
					throw new Error("LoaderMax.contentDisplayClass must be set to a class with a 'rawContent' property, like com.greensock.loading.display.ContentDisplay");
				}
			} else {
				_sprite = new ContentDisplay(this);
			}
		}
		
		/** @private Set inside ContentDisplay's or FlexContentDisplay's "loader" setter. **/
		public function setContentDisplay(contentDisplay:Sprite):void {
			_sprite = contentDisplay;
		}
		
		/** @private **/
		override protected function _load():void {
			_prepRequest();
			if (this.vars.context is LoaderContext) {
				_context = this.vars.context;
			} else if (_context == null) {
				if (LoaderMax.defaultContext != null) {
					_context = LoaderMax.defaultContext;
					if (_isLocal) {
						_context.securityDomain = null;
					}
				} else if (!_isLocal) {
					_context = new LoaderContext(true, new ApplicationDomain(ApplicationDomain.currentDomain), SecurityDomain.currentDomain); //avoids some security sandbox headaches that plague many users.
				}
			}
			if (Capabilities.playerType != "Desktop") { //AIR apps will choke on Security.allowDomain()
				Security.allowDomain(_url); 
			}
			_loader.load(_request, _context);
		}
		
		/** @inheritDoc **/
		override public function auditSize():void {
			if (Capabilities.playerType != "Desktop") { //AIR apps will choke on Security.allowDomain()
				Security.allowDomain(_url); 
			}
			super.auditSize();
		}
		
		override protected function _closeStream():void {
			_closeFallbackAudit();
			super._closeStream();
		}
		
		protected function _closeFallbackAudit():void {
			if (_fallbackAudit != null) {
				_fallbackAudit.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, _auditStreamHandler, false, 0, true);
				_fallbackAudit.contentLoaderInfo.addEventListener(Event.COMPLETE, _auditStreamHandler, false, 0, true);
				_fallbackAudit.contentLoaderInfo.addEventListener("ioError", _auditStreamHandler, false, 0, true);
				_fallbackAudit.contentLoaderInfo.addEventListener("securityError", _auditStreamHandler, false, 0, true);
				try {
					_fallbackAudit.close();
				} catch (error:Error) {
					
				}
				_fallbackAudit = null;
			}
		}
		
		/** @private **/
		override protected function _auditStreamHandler(event:Event):void {
			//If a security error is thrown because of a missing crossdomain.xml file for example and the user didn't define a specific LoaderContext, we'll try again without checking the policy file, accepting the restrictions that come along with it because typically people would rather have the content show up on the screen rather than just error out (and they can always check the scriptAccessDenied property if they need to figure out whether it's safe to do BitmapData stuff on it, etc.)
			if (event.type == "securityError") {
				if (_fallbackAudit == null) {
					_context = new LoaderContext(false);
					_scriptAccessDenied = true;
					dispatchEvent(new LoaderEvent(LoaderEvent.SCRIPT_ACCESS_DENIED, this, ErrorEvent(event).text));
					_errorHandler(event);
					_fallbackAudit = new Loader(); //so that we can apply a LoaderContext. We don't want to use a Loader initially because they are more memory-intensive than URLStream and they can tend to have more problems with garbage collection.
					_fallbackAudit.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, _auditStreamHandler, false, 0, true);
					_fallbackAudit.contentLoaderInfo.addEventListener(Event.COMPLETE, _auditStreamHandler, false, 0, true);
					_fallbackAudit.contentLoaderInfo.addEventListener("ioError", _auditStreamHandler, false, 0, true);
					_fallbackAudit.contentLoaderInfo.addEventListener("securityError", _auditStreamHandler, false, 0, true);
					var request:URLRequest = new URLRequest();
					request.data = _request.data;
					request.method = _request.method;
					_setRequestURL(request, _url, (!_isLocal || _url.substr(0, 4) == "http") ? "gsCacheBusterID=" + (_cacheID++) + "&purpose=audit" : "");
					if (Capabilities.playerType != "Desktop") { //AIR apps will choke on Security.allowDomain()
						Security.allowDomain(_url); 
					}
					_fallbackAudit.load(request, _context);
					return;
				} else {
					_closeFallbackAudit();
				}
			}
			super._auditStreamHandler(event);
		}
		
		/** @private **/
		protected function _refreshLoader(unloadContent:Boolean=true):void {
			if (_loader != null) {
				//to avoid gc issues and get around a bug in Flash that incorrectly reports progress values on Loaders that were closed before completing, we must force gc and recreate the Loader altogether...
				if (_status == LoaderStatus.LOADING) {
					try {
						_loader.close();
					} catch (error:Error) {
						
					}
				}
				_loader.contentLoaderInfo.removeEventListener(ProgressEvent.PROGRESS, _progressHandler);
				_loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, _completeHandler);
				_loader.contentLoaderInfo.removeEventListener("ioError", _failHandler);
				_loader.contentLoaderInfo.removeEventListener("securityError", _securityErrorHandler);
				_loader.contentLoaderInfo.removeEventListener("httpStatus", _httpStatusHandler);
				_loader.contentLoaderInfo.removeEventListener(Event.INIT, _initHandler);
				if (_loader.hasOwnProperty("uncaughtErrorEvents")) { //not available when published to FP9, so we reference things this way to avoid compiler errors
					Object(_loader).uncaughtErrorEvents.removeEventListener("uncaughtError", _errorHandler);
				}
				if (unloadContent) {
					try {
						if (_loader.parent == null && _sprite != null) {
							_sprite.addChild(_loader); //adding the _loader to the display list BEFORE calling unloadAndStop() and then removing it will greatly improve its ability to gc correctly if event listeners were added to the stage from within a subloaded swf without specifying "true" for the weak parameter of addEventListener(). The order here is critical.
						}
						if (_loader.hasOwnProperty("unloadAndStop")) { //Flash Player 10 and later only
							(_loader as Object).unloadAndStop();
						} else {
							_loader.unload();
						}
						
					} catch (error:Error) {
						
					}
					if (_loader.parent) {
						_loader.parent.removeChild(_loader);
					}
					if (("autoForceGC" in this.vars) ? this.vars.autoForceGC : defaultAutoForceGC) {
						forceGC((this.hasOwnProperty("getClass")) ? 3 : 1);
					}
				}
			}
			_initted = false;
			_loader = new Loader();
			_loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, _progressHandler, false, 0, true);
			_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, _completeHandler, false, 0, true);
			_loader.contentLoaderInfo.addEventListener("ioError", _failHandler, false, 0, true);
			_loader.contentLoaderInfo.addEventListener("securityError", _securityErrorHandler, false, 0, true);
			_loader.contentLoaderInfo.addEventListener("httpStatus", _httpStatusHandler, false, 0, true);
			_loader.contentLoaderInfo.addEventListener(Event.INIT, _initHandler, false, 0, true);
			if (_loader.hasOwnProperty("uncaughtErrorEvents")) { //not available when published to FP9, so we reference things this way to avoid compiler errors
				Object(_loader).uncaughtErrorEvents.addEventListener("uncaughtError", _errorHandler, false, 0, true);
			}
		}
		
		/** @private works around bug in Flash Player that prevents SWFs from properly being garbage collected after being unloaded - for certain types of objects like swfs, this needs to be run more than once (spread out over several frames) to force Flash to properly garbage collect everything. **/
		public static function forceGC(cycles:uint=1):void {
			if (_gcCycles < cycles) {
				_gcCycles = cycles;
				if (_gcDispatcher == null) {
					_gcDispatcher = new Sprite();
					_gcDispatcher.addEventListener(Event.ENTER_FRAME, _forceGCHandler, false, 0, true);
				}
			}
		}
		
		/** @private **/
		protected static function _forceGCHandler(event:Event):void {
			if (--_gcCycles <= 0) {
				_gcDispatcher.removeEventListener(Event.ENTER_FRAME, _forceGCHandler);
				_gcDispatcher = null;
			}
			try {
				new LocalConnection().connect("FORCE_GC");
				new LocalConnection().connect("FORCE_GC");
			} catch (error:Error) {
				
			}
		}
		
		/** @private scrubLevel: 0 = cancel, 1 = unload, 2 = dispose, 3 = flush **/
		override protected function _dump(scrubLevel:int=0, newStatus:int=LoaderStatus.READY, suppressEvents:Boolean=false):void {
			if (!_stealthMode) {
				_refreshLoader(Boolean(scrubLevel != 2));
			}
			if (scrubLevel == 1) {			//unload
				(_sprite as Object).rawContent = null;
			} else if (scrubLevel == 2) {	//dispose
				(_sprite as Object).loader = null;
			} else if (scrubLevel == 3) {	//unload and dispose
				(_sprite as Object).dispose(false, false); //makes sure the ContentDisplay is removed from its parent as well.
			}
			super._dump(scrubLevel, newStatus, suppressEvents);
		}
		
		/** @private **/
		protected function _determineScriptAccess():void {
			if (!_scriptAccessDenied) {
				if (!_loader.contentLoaderInfo.childAllowsParent) {
					_scriptAccessDenied = true;
					dispatchEvent(new LoaderEvent(LoaderEvent.SCRIPT_ACCESS_DENIED, this, "Error #2123: Security sandbox violation: " + this + ". No policy files granted access."));
				}
			}
		}
		
		
//---- EVENT HANDLERS ------------------------------------------------------------------------------------
		
		/** @private **/
		protected function _securityErrorHandler(event:ErrorEvent):void {
			//If a security error is thrown because of a missing crossdomain.xml file for example and the user didn't define a specific LoaderContext, we'll try again without checking the policy file, accepting the restrictions that come along with it because typically people would rather have the content show up on the screen rather than just error out (and they can always check the scriptAccessDenied property if they need to figure out whether it's safe to do BitmapData stuff on it, etc.)
			if (_context != null && _context.checkPolicyFile && !(this.vars.context is LoaderContext)) {
				_context = new LoaderContext(false);
				_scriptAccessDenied = true;
				dispatchEvent(new LoaderEvent(LoaderEvent.SCRIPT_ACCESS_DENIED, this, event.text));
				_errorHandler(event);
				_load();
			} else {
				_failHandler(event);
			}
		}
		
		/** @private **/
		protected function _initHandler(event:Event):void {
			if (!_initted) {
				_initted = true;
				if (_content == null) { //_content is set in ImageLoader or SWFLoader (subclasses), but we put this here just in case someone wants to use DisplayObjectLoader on its own as a lighter weight alternative without the bells & whistles of SWFLoader/ImageLoader.
					_content = (_scriptAccessDenied) ? _loader : _loader.content;
				}
				(_sprite as Object).rawContent = (_content as DisplayObject);
				dispatchEvent(new LoaderEvent(LoaderEvent.INIT, this));
			}
		}
		
//---- GETTERS / SETTERS -------------------------------------------------------------------------
		
		/** A ContentDisplay object (a Sprite) that will contain the remote content as soon as the <code>INIT</code> event has been dispatched. This ContentDisplay can be accessed immediately; you do not need to wait for the content to load. **/
		override public function get content():* {
			return _sprite;
		}
		
		/** 
		 * The raw content that was successfully loaded <strong>into</strong> the <code>content</code> ContentDisplay 
		 * Sprite which varies depending on the type of loader and whether or not script access was denied while 
		 * attempting to load the file: 
		 * 
		 * <ul>
		 * 		<li>ImageLoader with script access granted: <code>flash.display.Bitmap</code></li>
		 * 		<li>ImageLoader with script access denied: <code>flash.display.Loader</code></li>
		 * 		<li>SWFLoader with script access granted: <code>flash.display.DisplayObject</code> (the swf's <code>root</code>)</li>
		 * 		<li>SWFLoader with script access denied: <code>flash.display.Loader</code> (the swf's <code>root</code> cannot be accessed because it would generate a security error)</li>
		 * </ul>
		 **/
		public function get rawContent():* {
			return _content;
		}
		
	}
}