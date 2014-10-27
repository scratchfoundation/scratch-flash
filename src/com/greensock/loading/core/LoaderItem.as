/**
 * VERSION: 1.92
 * DATE: 2012-08-08
 * AS3
 * UPDATES AND DOCS AT: http://www.greensock.com/loadermax/
 **/
package com.greensock.loading.core {
	import com.greensock.events.LoaderEvent;
	import com.greensock.loading.LoaderStatus;
	import com.greensock.loading.LoaderMax;
	
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.net.URLRequest;
	import flash.net.URLStream;
	import flash.net.URLVariables;
	
	/** Dispatched when the loader experiences an IO_ERROR while loading or auditing its size. **/
	[Event(name="ioError", type="com.greensock.events.LoaderEvent")]
/**
 * Serves as the base class for all individual loaders (not LoaderMax) like <code>ImageLoader, 
 * XMLLoader, SWFLoader, MP3Loader</code>, etc. There is no reason to use this class on its own. 
 * Please see the documentation for the other classes.
 * <br /><br />
 * 
 * <b>Copyright 2010-2012, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 */	
	public class LoaderItem extends LoaderCore {
		/** @private **/
		protected static var _cacheID:Number = new Date().getTime();
		
		/** @private **/
		protected var _url:String;
		/** @private **/
		protected var _request:URLRequest;
		/** @private **/
		protected var _scriptAccessDenied:Boolean;
		/** @private used in auditSize() just to preload enough of the file to determine bytesTotal. **/
		protected var _auditStream:URLStream;
		/** @private For certain types of loaders like SWFLoader and XMLLoader where there may be nested loaders found, it's better to prioritize the estimatedBytes if one is defined. Otherwise, the file size will be used which may be MUCH smaller than all the assets inside of it (like an XML file with a bunch of VideoLoaders).**/
		protected var _preferEstimatedBytesInAudit:Boolean;
		/** @private **/
		protected var _httpStatus:int;
		/** @private used to prevent problems that could occur if an audit is in process and load() is called on a bad URL - the audit could fail first and swap the URL and then when the real load fails just after that, we couldn't just do if (_url != this.vars.alternateURL) because the audit would have already changed it.  **/
		protected var _skipAlternateURL:Boolean;
		
		/**
		 * Constructor
		 * 
		 * @param urlOrRequest The url (<code>String</code>) or <code>URLRequest</code> from which the loader should get its content
		 * @param vars An object containing optional parameters like <code>estimatedBytes, name, autoDispose, onComplete, onProgress, onError</code>, etc. For example, <code>{estimatedBytes:2400, name:"myImage1", onComplete:completeHandler}</code>.
		 */
		public function LoaderItem(urlOrRequest:*, vars:Object=null) {
			super(vars);
			_request = (urlOrRequest is URLRequest) ? urlOrRequest as URLRequest : new URLRequest(urlOrRequest);
			_url = _request.url;
			_setRequestURL(_request, _url);
		}
		
		/** @private **/
		protected function _prepRequest():void {
			_scriptAccessDenied = false;
			_httpStatus = 0;
			_closeStream();
			if (this.vars.noCache && (!_isLocal || _url.substr(0, 4) == "http")) {
				_setRequestURL(_request, _url, "gsCacheBusterID=" + (_cacheID++));
			}
		}
		
		/** @private Flash doesn't properly apply extra GET url parameters when the URL contains them already (like "http://www.greensock.com?id=2") - it ends up missing an "&" delimiter so this method splits any that exist out into a URLVariables object and optionally adds extra parameters like gsCacheBusterID, etc. **/
		protected function _setRequestURL(request:URLRequest, url:String, extraParams:String=""):void {
			var a:Array = (this.vars.allowMalformedURL) ? [url] : url.split("?");
			
			//in order to avoid a VERY strange bug in certain versions of the Flash Player (like 10.0.12.36), we must loop through each character and rebuild a separate String variable instead of just using a[0], otherwise the "?" delimiter will be omitted when GET parameters are appended to the URL by Flash! Performing any String manipulations on the url will cause the issue as long as there is a "?" in the url. Like url.split("?") or url.substr(0, url.indexOf("?"), etc. Absolutely baffling. Definitely a bug in the Player - it was fixed in 10.1.
			var s:String = a[0];
			var parsedURL:String = "";
			for (var i:int = 0; i < s.length; i++) {
				parsedURL += s.charAt(i);
			}
			
			request.url = parsedURL;
			if (a.length >= 2) {
				extraParams += (extraParams == "") ? a[1] : "&" + a[1];
			}
			if (extraParams != "") {
				var data:URLVariables = (request.data is URLVariables) ? request.data as URLVariables : new URLVariables();
				a = extraParams.split("&");
				i = a.length;
				var pair:Array;
				while (--i > -1) {
					pair = a[i].split("=");
					data[pair.shift()] = pair.join("=");
				}
				request.data = data;
			}
		}
		
		/** @private scrubLevel: 0 = cancel, 1 = unload, 2 = dispose, 3 = flush **/
		override protected function _dump(scrubLevel:int=0, newStatus:int=0, suppressEvents:Boolean=false):void {
			_closeStream();
			super._dump(scrubLevel, newStatus, suppressEvents);
		}
		
		/** @inheritDoc **/
		override public function auditSize():void {
			if (_auditStream == null) {
				_auditStream = new URLStream();
				_auditStream.addEventListener(ProgressEvent.PROGRESS, _auditStreamHandler, false, 0, true);
				_auditStream.addEventListener(Event.COMPLETE, _auditStreamHandler, false, 0, true);
				_auditStream.addEventListener("ioError", _auditStreamHandler, false, 0, true);
				_auditStream.addEventListener("securityError", _auditStreamHandler, false, 0, true);
				var request:URLRequest = new URLRequest();
				request.data = _request.data;
				request.method = _request.method;
				_setRequestURL(request, _url, (!_isLocal || _url.substr(0, 4) == "http") ? "gsCacheBusterID=" + (_cacheID++) + "&purpose=audit" : "");
				_auditStream.load(request);  
			}
		}
		
		/** @private **/
		protected function _closeStream():void {
			if (_auditStream != null) {
				_auditStream.removeEventListener(ProgressEvent.PROGRESS, _auditStreamHandler);
				_auditStream.removeEventListener(Event.COMPLETE, _auditStreamHandler);
				_auditStream.removeEventListener("ioError", _auditStreamHandler);
				_auditStream.removeEventListener("securityError", _auditStreamHandler);
				try {
					_auditStream.close();
				} catch (error:Error) {
					
				}
				_auditStream = null;
			}
		}
		
//---- EVENT HANDLERS ------------------------------------------------------------------------------------
		
		/** @private **/
		protected function _auditStreamHandler(event:Event):void {
			if (event is ProgressEvent) {
				_cachedBytesTotal = (event as ProgressEvent).bytesTotal;
				if (_preferEstimatedBytesInAudit && uint(this.vars.estimatedBytes) > _cachedBytesTotal) {
					_cachedBytesTotal = uint(this.vars.estimatedBytes);
				}
			} else if (event.type == "ioError" || event.type == "securityError") {
				if (this.vars.alternateURL != undefined && this.vars.alternateURL != "" && this.vars.alternateURL != _url) {
					_errorHandler(event);
					if (_status != LoaderStatus.DISPOSED) { //it is conceivable that the user disposed the loader in an onError handler
						_url = this.vars.alternateURL;
						_setRequestURL(_request, _url);
						var request:URLRequest = new URLRequest();
						request.data = _request.data;
						request.method = _request.method;
						_setRequestURL(request, _url, (!_isLocal || _url.substr(0, 4) == "http") ? "gsCacheBusterID=" + (_cacheID++) + "&purpose=audit" : "");
						_auditStream.load(request);
					}
					return;
				} else {	
					//note: a CANCEL event won't be dispatched because technically the loader wasn't officially loading - we were only briefly checking the bytesTotal with a URLStream.
					super._failHandler(event);
				}
			}
			_auditedSize = true;
			_closeStream();
			dispatchEvent(new Event("auditedSize"));
		}
		
		/** @private **/
		override protected function _failHandler(event:Event, dispatchError:Boolean=true):void {
			if (this.vars.alternateURL != undefined && this.vars.alternateURL != "" && !_skipAlternateURL) { //don't do (_url != vars.alternateURL) because the audit could have changed it already - that's the whole purpose of _skipAlternateURL.
				_errorHandler(event);
				_skipAlternateURL = true;
				_url = "temp" + Math.random(); //in case the audit already changed the _url to vars.alternateURL, we temporarily make it something different in order to force the refresh in the url setter which skips running the code if the url is set to the same value as it previously was. 
				this.url = this.vars.alternateURL; //also calls _load()
			} else {
				super._failHandler(event, dispatchError);
			}
		}
		
		
		/** @private **/
		protected function _httpStatusHandler(event:Event):void {
			_httpStatus = (event as Object).status;
			dispatchEvent(new LoaderEvent(LoaderEvent.HTTP_STATUS, this));
		}
		
		
//---- GETTERS / SETTERS -------------------------------------------------------------------------
		
		/** The url from which the loader should get its content. **/
		public function get url():String {
			return _url;
		}
		public function set url(value:String):void {
			if (_url != value) {
				_url = value;
				_setRequestURL(_request, _url);
				var isLoading:Boolean = Boolean(_status == LoaderStatus.LOADING);
				_dump(1, LoaderStatus.READY, true);
				_auditedSize = Boolean(uint(this.vars.estimatedBytes) != 0 && this.vars.auditSize != true);
				_cachedBytesTotal = (uint(this.vars.estimatedBytes) != 0) ? uint(this.vars.estimatedBytes) : LoaderMax.defaultEstimatedBytes;
				_cacheIsDirty = true;
				if (isLoading) {
					_load();
				}
			}
		}
		
		/** The <code>URLRequest</code> associated with the loader. **/
		public function get request():URLRequest {
			return _request;
		}
		
		/** The httpStatus code of the loader. You may listen for <code>LoaderEvent.HTTP_STATUS</code> events on certain types of loaders to be notified when it changes, but in some environments the Flash player cannot sense httpStatus codes in which case the value will remain <code>0</code>. **/
		public function get httpStatus():int {
			return _httpStatus;
		}
		
		/**
		 * If the loaded content is denied script access (because of security sandbox restrictions,
		 * a missing crossdomain.xml file, etc.), <code>scriptAccessDenied</code> will be set to <code>true</code>.
		 * In the case of loaded images or swf files, this means that you should not attempt to perform 
		 * BitmapData operations on the content. An image's <code>smoothing</code> property cannot be set 
		 * to <code>true</code> either. Even if script access is denied for particular content, LoaderMax will still
		 * attempt to load it.
		 **/
		public function get scriptAccessDenied():Boolean {
			return _scriptAccessDenied;
		}
		
	}
}