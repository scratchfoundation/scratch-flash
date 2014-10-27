/**
 * VERSION: 1.7
 * DATE: 2010-11-13
 * AS3
 * UPDATES AND DOCS AT: http://www.greensock.com/loadermax/
 **/
package com.greensock.loading {
	import com.greensock.loading.core.LoaderItem;
	
	import flash.display.DisplayObject;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.ProgressEvent;
/**
 * Tracks the loading progress of the swf in which the loader resides (basically a simple tool for tracking
 * the <code>loaderInfo</code>'s progress). SelfLoader is only useful in situations where you want to factor
 * the current swf's loading progress into a LoaderMax queue or maybe display a progress bar for the current
 * swf or fire an event when loading has finished.<br /><br />
 * 
 * <strong>OPTIONAL VARS PROPERTIES</strong><br />
 * The following special properties can be passed into the SelfLoader constructor via its <code>vars</code> parameter:<br />
 * <ul>
 * 		<li><strong> name : String</strong> - A name that is used to identify the loader instance. This name can be fed to the <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> methods or traced at any time. Each loader's name should be unique. If you don't define one, a unique name will be created automatically, like "loader21".</li>
 * 		<li><strong> autoDispose : Boolean</strong> - When <code>autoDispose</code> is <code>true</code>, the loader will be disposed immediately after it completes (it calls the <code>dispose()</code> method internally after dispatching its <code>COMPLETE</code> event). This will remove any listeners that were defined in the vars object (like onComplete, onProgress, onError). Once a loader is disposed, it can no longer be found with <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code>. The default <code>autoDispose</code> value is <code>false</code>.
 * 		
 * 		<br /><br />----EVENT HANDLER SHORTCUTS----</li>
 * 		<li><strong> onProgress : Function</strong> - A handler function for <code>LoaderEvent.PROGRESS</code> events which are dispatched whenever the <code>bytesLoaded</code> changes. Make sure your onProgress function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). You can use the LoaderEvent's <code>target.progress</code> to get the loader's progress value or use its <code>target.bytesLoaded</code> and <code>target.bytesTotal</code>.</li>
 * 		<li><strong> onComplete : Function</strong> - A handler function for <code>LoaderEvent.COMPLETE</code> events which are dispatched when the loader has finished loading successfully. Make sure your onComplete function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * </ul><br />
 * 
 * @example Example AS3 code:<listing version="3.0">
 import com.greensock.loading.~~;
 import com.greensock.events.LoaderEvent;
 
//create a SelfLoader
var loader:SelfLoader = new SelfLoader(this, {name:"self", onProgress:progressHandler, onComplete:completeHandler});

//Or you could put the SelfLoader into a LoaderMax. Create one first...
var queue:LoaderMax = new LoaderMax({name:"mainQueue", onProgress:progressHandler, onComplete:completeHandler, onError:errorHandler});

//append the SelfLoader and several other loaders
queue.append( loader );
queue.append( new ImageLoader("images/photo1.jpg", {name:"photo1", container:this}) );
queue.append( new SWFLoader("swf/child.swf", {name:"child", container:this, x:100, estimatedBytes:3500}) );

//start loading the LoaderMax queue
queue.load();

function progressHandler(event:LoaderEvent):void {
	trace("progress: " + event.target.progress);
}

function completeHandler(event:LoaderEvent):void {
	trace(event.target + " complete");
}

function errorHandler(event:LoaderEvent):void {
	trace("error occured with " + event.target + ": " + event.text);
}
 </listing>
 * 
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 */	
	public class SelfLoader extends LoaderItem {
		/** @private **/
		protected var _loaderInfo:LoaderInfo;
		
		/**
		 * Constructor
		 * 
		 * @param self A DisplayObject from the main swf (it will use this DisplayObject's <code>loaderInfo</code> to track the loading progress).
		 * @param vars An object containing optional configuration details. For example: <code>new SelfLoader(this, {name:"self", onComplete:completeHandler, onProgress:progressHandler})</code>.<br /><br />
		 * 
		 * The following special properties can be passed into the constructor via the <code>vars</code> parameter:<br />
		 * <ul>
		 * 		<li><strong> name : String</strong> - A name that is used to identify the loader instance. This name can be fed to the <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> methods or traced at any time. Each loader's name should be unique. If you don't define one, a unique name will be created automatically, like "loader21".</li>
		 * 		<li><strong> autoDispose : Boolean</strong> - When <code>autoDispose</code> is <code>true</code>, the loader will be disposed immediately after it completes (it calls the <code>dispose()</code> method internally after dispatching its <code>COMPLETE</code> event). This will remove any listeners that were defined in the vars object (like onComplete, onProgress, onError). Once a loader is disposed, it can no longer be found with <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code>. The default <code>autoDispose</code> value is <code>false</code>.
		 * 		
		 * 		<br /><br />----EVENT HANDLER SHORTCUTS----</li>
		 * 		<li><strong> onProgress : Function</strong> - A handler function for <code>LoaderEvent.PROGRESS</code> events which are dispatched whenever the <code>bytesLoaded</code> changes. Make sure your onProgress function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). You can use the LoaderEvent's <code>target.progress</code> to get the loader's progress value or use its <code>target.bytesLoaded</code> and <code>target.bytesTotal</code>.</li>
		 * 		<li><strong> onComplete : Function</strong> - A handler function for <code>LoaderEvent.COMPLETE</code> events which are dispatched when the loader has finished loading successfully. Make sure your onComplete function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * </ul>
		 */
		public function SelfLoader(self:DisplayObject, vars:Object=null) {
			super(self.loaderInfo.url, vars);
			_type = "SelfLoader";
			_loaderInfo = self.loaderInfo;
			_loaderInfo.addEventListener(ProgressEvent.PROGRESS, _progressHandler, false, 0, true);
			_loaderInfo.addEventListener(Event.COMPLETE, _completeHandler, false, 0, true);
			_cachedBytesTotal = _loaderInfo.bytesTotal;
			_cachedBytesLoaded = _loaderInfo.bytesLoaded;
			_status = (_cachedBytesLoaded == _cachedBytesTotal) ? LoaderStatus.COMPLETED : LoaderStatus.LOADING;		
			_auditedSize = true;
			_content = self;
		}
		
		/** @private scrubLevel: 0 = cancel, 1 = unload, 2 = dispose, 3 = flush **/
		override protected function _dump(scrubLevel:int=0, newStatus:int=0, suppressEvents:Boolean=false):void {
			if (scrubLevel >= 2) {
				_loaderInfo.removeEventListener(ProgressEvent.PROGRESS, _progressHandler);
				_loaderInfo.removeEventListener(Event.COMPLETE, _completeHandler);
			}
			super._dump(scrubLevel, newStatus, suppressEvents);
		}
		
	}
}