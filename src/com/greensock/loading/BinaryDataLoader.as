/**
 * VERSION: 1.84
 * DATE: 2011-03-23
 * AS3
 * UPDATES AND DOCS AT: http://www.greensock.com/loadermax/
 **/
package com.greensock.loading {
	import flash.events.Event;

/**
 * Loads generic binary data - identical to using a DataLoader with its "<code>format</code>" 
 * special property set to <code>"binary"</code>. The reason for having a <code>BinaryDataLoader</code>
 * class is to allow certain file extensions (like ".zip") to be associated with it so that the 
 * <code>LoaderMax.parse()</code> method can accurately parse URLs with those file extensions. If you do 
 * not plan on using the <code>LoaderMax.parse()</code> method, however, you could save a small amount 
 * of kb by simply using DataLoaders with their format set to "binary" instead of using BinaryDataLoaders.<br /><br />
 * 
 * The following are essentially the same:<br /><code>
 * new DataLoader("file.zip", {format:"binary"}); <br />
 * new BinaryDataLoader("file.zip"); </code><br /><br />
 * 
 * If you'd like to associate additional file extensions with BinaryDataLoader, you may use the
 * <code>LoaderMax.registerFileType()</code> method.<br /><br />
 * 
 * <strong>OPTIONAL VARS PROPERTIES</strong><br />
 * The following special properties can be passed into the BinaryDataLoader constructor via its <code>vars</code> 
 * parameter which can be either a generic object or a <code><a href="data/DataLoaderVars.html">DataLoaderVars</a></code> object:<br />
 * <ul>
 * 		<li><strong> name : String</strong> - A name that is used to identify the loader instance. This name can be fed to the <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> methods or traced at any time. Each loader's name should be unique. If you don't define one, a unique name will be created automatically, like "loader21".</li>
 * 		<li><strong> alternateURL : String</strong> - If you define an <code>alternateURL</code>, the loader will initially try to load from its original <code>url</code> and if it fails, it will automatically (and permanently) change the loader's <code>url</code> to the <code>alternateURL</code> and try again. Think of it as a fallback or backup <code>url</code>. It is perfectly acceptable to use the same <code>alternateURL</code> for multiple loaders (maybe a default image for various ImageLoaders for example).</li>
 * 		<li><strong> noCache : Boolean</strong> - If <code>true</code>, a "gsCacheBusterID" parameter will be appended to the url with a random set of numbers to prevent caching (don't worry, this info is ignored when you <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> by <code>url</code> or when you're running locally)</li>
 * 		<li><strong> estimatedBytes : uint</strong> - Initially, the loader's <code>bytesTotal</code> is set to the <code>estimatedBytes</code> value (or <code>LoaderMax.defaultEstimatedBytes</code> if one isn't defined). Then, when the loader begins loading and it can accurately determine the bytesTotal, it will do so. Setting <code>estimatedBytes</code> is optional, but the more accurate the value, the more accurate your loaders' overall progress will be initially. If the loader is inserted into a LoaderMax instance (for queue management), its <code>auditSize</code> feature can attempt to automatically determine the <code>bytesTotal</code> at runtime (there is a slight performance penalty for this, however - see LoaderMax's documentation for details).</li>
 * 		<li><strong> requireWithRoot : DisplayObject</strong> - LoaderMax supports <i>subloading</i>, where an object can be factored into a parent's loading progress. If you want LoaderMax to require this BinaryDataLoader as part of its parent SWFLoader's progress, you must set the <code>requireWithRoot</code> property to your swf's <code>root</code>. For example, <code>var loader:BinaryDataLoader = new BinaryDataLoader("file.zip", {name:"zipFile", requireWithRoot:this.root});</code></li>
 * 		<li><strong> allowMalformedURL : Boolean</strong> - Normally, the URL will be parsed and any variables in the query string (like "?name=test&amp;state=il&amp;gender=m") will be placed into a URLVariables object which is added to the URLRequest. This avoids a few bugs in Flash, but if you need to keep the entire URL intact (no parsing into URLVariables), set <code>allowMalformedURL:true</code>. For example, if your URL has duplicate variables in the query string like <code>http://www.greensock.com/?c=S&amp;c=SE&amp;c=SW</code>, it is technically considered a malformed URL and a URLVariables object can't properly contain all the duplicates, so in this case you'd want to set <code>allowMalformedURL</code> to <code>true</code>.</li>
 * 		<li><strong> autoDispose : Boolean</strong> - When <code>autoDispose</code> is <code>true</code>, the loader will be disposed immediately after it completes (it calls the <code>dispose()</code> method internally after dispatching its <code>COMPLETE</code> event). This will remove any listeners that were defined in the vars object (like onComplete, onProgress, onError, onInit). Once a loader is disposed, it can no longer be found with <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> - it is essentially destroyed but its content is not unloaded (you must call <code>unload()</code> or <code>dispose(true)</code> to unload its content). The default <code>autoDispose</code> value is <code>false</code>.
 * 		
 * 		<br /><br />----EVENT HANDLER SHORTCUTS----</li>
 * 		<li><strong> onOpen : Function</strong> - A handler function for <code>LoaderEvent.OPEN</code> events which are dispatched when the loader begins loading. Make sure your onOpen function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onProgress : Function</strong> - A handler function for <code>LoaderEvent.PROGRESS</code> events which are dispatched whenever the <code>bytesLoaded</code> changes. Make sure your onProgress function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). You can use the LoaderEvent's <code>target.progress</code> to get the loader's progress value or use its <code>target.bytesLoaded</code> and <code>target.bytesTotal</code>.</li>
 * 		<li><strong> onComplete : Function</strong> - A handler function for <code>LoaderEvent.COMPLETE</code> events which are dispatched when the loader has finished loading successfully. Make sure your onComplete function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onCancel : Function</strong> - A handler function for <code>LoaderEvent.CANCEL</code> events which are dispatched when loading is aborted due to either a failure or because another loader was prioritized or <code>cancel()</code> was manually called. Make sure your onCancel function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onError : Function</strong> - A handler function for <code>LoaderEvent.ERROR</code> events which are dispatched whenever the loader experiences an error (typically an IO_ERROR or SECURITY_ERROR). An error doesn't necessarily mean the loader failed, however - to listen for when a loader fails, use the <code>onFail</code> special property. Make sure your onError function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onFail : Function</strong> - A handler function for <code>LoaderEvent.FAIL</code> events which are dispatched whenever the loader fails and its <code>status</code> changes to <code>LoaderStatus.FAILED</code>. Make sure your onFail function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onIOError : Function</strong> - A handler function for <code>LoaderEvent.IO_ERROR</code> events which will also call the onError handler, so you can use that as more of a catch-all whereas <code>onIOError</code> is specifically for LoaderEvent.IO_ERROR events. Make sure your onIOError function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onHTTPStatus : Function</strong> - A handler function for <code>LoaderEvent.HTTP_STATUS</code> events. Make sure your onHTTPStatus function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). You can determine the httpStatus code using the LoaderEvent's <code>target.httpStatus</code> (LoaderItems keep track of their <code>httpStatus</code> when possible, although certain environments prevent Flash from getting httpStatus information).</li>
 * </ul><br />
 * 
 * <strong>Note:</strong> Using a <code><a href="data/DataLoaderVars.html">DataLoaderVars</a></code> instance 
 * instead of a generic object to define your <code>vars</code> is a bit more verbose but provides 
 * code hinting and improved debugging because it enforces strict data typing. Use whichever one you prefer.<br /><br />
 * 
 * @example Example AS3 code:<listing version="3.0">
 import com.greensock.loading.~~;
 import com.greensock.events.LoaderEvent;
 
 //create a BinaryDataLoader
 var loader:BinaryDataLoader = new BinaryDataLoader("file.zip", {name:"myZipFile", requireWithRoot:this.root, estimatedBytes:6800});
 
 //begin loading
 loader.load();
 
 //or we could parse() and array of files, creating a LoaderMax queue with loaders for each file. To do that, we'll first create the array:
 var files:Array = ["files/archive.zip","images/1.jpg","files/report.pdf","swfs/child.swf"];
 
 //since we want the parse() method to recognize the .pdf file as a BinaryDataLoader, we should registerFileType() first because pdf isn't one of the extensions recognized by default.
 LoaderMax.registerFileType("pdf", BinaryDataLoader);
  
 //before we parse() the array, we need to activate() the loader types that LoaderMax should recognize (we only need to do this once)
 LoaderMax.activate([BinaryDataLoader, ImageLoader, SWFLoader]);
 
 //now parse the files and create a LoaderMax queue
 var queue:LoaderMax = LoaderMax.parse(files, {onProgress:progressHandler, onComplete:completeHandler, onChildFail:childFailHandler});
 queue.load();
 
 function progressHandler(event:LoaderEvent):void {
 	trace("progress: " + event.target.progress);
 }
 
 function completeHandler(event:LoaderEvent):void {
 	trace("completed " + event.target);
 }
 
 function childFailHandler(event:LoaderEvent):void {
 	trace(event.target + " failed.");
 }
 
 </listing>
 * 
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @see com.greensock.loading.data.DataLoaderVars
 * 
 * @author Jack Doyle, jack@greensock.com
 */	
	public class BinaryDataLoader extends DataLoader {
		/** @private **/
		private static var _classActivated:Boolean = _activateClass("BinaryDataLoader", BinaryDataLoader, "zip");
		
		/**
		 * Constructor
		 * 
		 * @param urlOrRequest The url (<code>String</code>) or <code>URLRequest</code> from which the loader should get its content.
		 * @param vars An object containing optional configuration details. For example: <code>new BinaryDataLoader("file.zip", {name:"myZipFile", onComplete:completeHandler, onProgress:progressHandler})</code>.<br /><br />
		 * 
		 * The following special properties can be passed into the constructor via the <code>vars</code> parameter 
		 * which can be either a generic object or a <code><a href="data/DataLoaderVars.html">DataLoaderVars</a></code> object:<br />
		 * <ul>
		 * 		<li><strong> name : String</strong> - A name that is used to identify the loader instance. This name can be fed to the <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> methods or traced at any time. Each loader's name should be unique. If you don't define one, a unique name will be created automatically, like "loader21".</li>
		 * 		<li><strong> alternateURL : String</strong> - If you define an <code>alternateURL</code>, the loader will initially try to load from its original <code>url</code> and if it fails, it will automatically (and permanently) change the loader's <code>url</code> to the <code>alternateURL</code> and try again. Think of it as a fallback or backup <code>url</code>. It is perfectly acceptable to use the same <code>alternateURL</code> for multiple loaders (maybe a default image for various ImageLoaders for example).</li>
		 * 		<li><strong> noCache : Boolean</strong> - If <code>true</code>, a "gsCacheBusterID" parameter will be appended to the url with a random set of numbers to prevent caching (don't worry, this info is ignored when you <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> by <code>url</code> or when you're running locally)</li>
		 * 		<li><strong> estimatedBytes : uint</strong> - Initially, the loader's <code>bytesTotal</code> is set to the <code>estimatedBytes</code> value (or <code>LoaderMax.defaultEstimatedBytes</code> if one isn't defined). Then, when the loader begins loading and it can accurately determine the bytesTotal, it will do so. Setting <code>estimatedBytes</code> is optional, but the more accurate the value, the more accurate your loaders' overall progress will be initially. If the loader is inserted into a LoaderMax instance (for queue management), its <code>auditSize</code> feature can attempt to automatically determine the <code>bytesTotal</code> at runtime (there is a slight performance penalty for this, however - see LoaderMax's documentation for details).</li>
		 * 		<li><strong> requireWithRoot : DisplayObject</strong> - LoaderMax supports <i>subloading</i>, where an object can be factored into a parent's loading progress. If you want LoaderMax to require this BinaryDataLoader as part of its parent SWFLoader's progress, you must set the <code>requireWithRoot</code> property to your swf's <code>root</code>. For example, <code>var loader:BinaryDataLoader = new BinaryDataLoader("file.zip", {name:"myZipFile", requireWithRoot:this.root});</code></li>
		 * 		<li><strong> allowMalformedURL : Boolean</strong> - Normally, the URL will be parsed and any variables in the query string (like "?name=test&amp;state=il&amp;gender=m") will be placed into a URLVariables object which is added to the URLRequest. This avoids a few bugs in Flash, but if you need to keep the entire URL intact (no parsing into URLVariables), set <code>allowMalformedURL:true</code>. For example, if your URL has duplicate variables in the query string like <code>http://www.greensock.com/?c=S&amp;c=SE&amp;c=SW</code>, it is technically considered a malformed URL and a URLVariables object can't properly contain all the duplicates, so in this case you'd want to set <code>allowMalformedURL</code> to <code>true</code>.</li>
		 * 		<li><strong> autoDispose : Boolean</strong> - When <code>autoDispose</code> is <code>true</code>, the loader will be disposed immediately after it completes (it calls the <code>dispose()</code> method internally after dispatching its <code>COMPLETE</code> event). This will remove any listeners that were defined in the vars object (like onComplete, onProgress, onError, onInit). Once a loader is disposed, it can no longer be found with <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> - it is essentially destroyed but its content is not unloaded (you must call <code>unload()</code> or <code>dispose(true)</code> to unload its content). The default <code>autoDispose</code> value is <code>false</code>.
		 * 		
		 * 		<br /><br />----EVENT HANDLER SHORTCUTS----</li>
		 * 		<li><strong> onOpen : Function</strong> - A handler function for <code>LoaderEvent.OPEN</code> events which are dispatched when the loader begins loading. Make sure your onOpen function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onProgress : Function</strong> - A handler function for <code>LoaderEvent.PROGRESS</code> events which are dispatched whenever the <code>bytesLoaded</code> changes. Make sure your onProgress function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). You can use the LoaderEvent's <code>target.progress</code> to get the loader's progress value or use its <code>target.bytesLoaded</code> and <code>target.bytesTotal</code>.</li>
		 * 		<li><strong> onComplete : Function</strong> - A handler function for <code>LoaderEvent.COMPLETE</code> events which are dispatched when the loader has finished loading successfully. Make sure your onComplete function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onCancel : Function</strong> - A handler function for <code>LoaderEvent.CANCEL</code> events which are dispatched when loading is aborted due to either a failure or because another loader was prioritized or <code>cancel()</code> was manually called. Make sure your onCancel function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onError : Function</strong> - A handler function for <code>LoaderEvent.ERROR</code> events which are dispatched whenever the loader experiences an error (typically an IO_ERROR or SECURITY_ERROR). An error doesn't necessarily mean the loader failed, however - to listen for when a loader fails, use the <code>onFail</code> special property. Make sure your onError function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onFail : Function</strong> - A handler function for <code>LoaderEvent.FAIL</code> events which are dispatched whenever the loader fails and its <code>status</code> changes to <code>LoaderStatus.FAILED</code>. Make sure your onFail function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onIOError : Function</strong> - A handler function for <code>LoaderEvent.IO_ERROR</code> events which will also call the onError handler, so you can use that as more of a catch-all whereas <code>onIOError</code> is specifically for LoaderEvent.IO_ERROR events. Make sure your onIOError function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onHTTPStatus : Function</strong> - A handler function for <code>LoaderEvent.HTTP_STATUS</code> events. Make sure your onHTTPStatus function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). You can determine the httpStatus code using the LoaderEvent's <code>target.httpStatus</code> (LoaderItems keep track of their <code>httpStatus</code> when possible, although certain environments prevent Flash from getting httpStatus information).</li>
		 * </ul>
		 * @see com.greensock.loading.data.DataLoaderVars
		 */
		public function BinaryDataLoader(urlOrRequest:*, vars:Object=null) {
			super(urlOrRequest, vars);
			_loader.dataFormat = "binary"; //just to make sure it wasn't overridden if the "format" special vars property was passed into in DataLoader's constructor.
			_type = "BinaryDataLoader";
		}
		
	}
}