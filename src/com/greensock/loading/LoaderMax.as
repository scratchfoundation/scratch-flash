/**
 * VERSION: 1.921
 * DATE: 2012-08-09
 * AS3
 * UPDATES AND DOCS AT: http://www.greensock.com/loadermax/
 **/
package com.greensock.loading {
	import com.greensock.events.LoaderEvent;
	import com.greensock.loading.core.LoaderCore;
	import com.greensock.loading.core.LoaderItem;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.utils.Dictionary;
	
	/** Dispatched when any child of the LoaderMax instance starts loading. So if a LoaderMax contains 5 loaders, the CHILD_OPEN event will be dispatched 5 times during the course of the LoaderMax's load. This can occur even if the LoaderMax itself isn't in the process of loading (because load() or prioritize() could have been called directly on a child loader) **/
	[Event(name="childOpen", 			type="com.greensock.events.LoaderEvent")]
	/** Dispatched when any child of the LoaderMax instance dispatches a PROGRESS event. This can occur even if the LoaderMax itself isn't in the process of loading (because load() or prioritize() could have been called directly on a child loader) **/
	[Event(name="childProgress", 		type="com.greensock.events.LoaderEvent")]
	/** Dispatched when any child of the LoaderMax instance completes. So if a LoaderMax contains 5 loaders, the CHILD_COMPLETE event will be dispatched 5 times during the course of the LoaderMax's load. This can occur even if the LoaderMax itself isn't in the process of loading (because load() or prioritize() could have been called directly on a child loader) **/
	[Event(name="childComplete", 		type="com.greensock.events.LoaderEvent")]
	/** Dispatched when any child of the LoaderMax instance fails to load. This occurs even if the LoaderMax itself isn't in the process of loading (because load() or prioritize() could have been called directly on a child loader) **/
	[Event(name="childFail", 			type="com.greensock.events.LoaderEvent")]
	/** Dispatched when any child of the LoaderMax instance dispatches a CANCEL event which could occur when another child is prioritized in the queue or when the LoaderMax is canceled while loading the child. CHILD_CANCEL can be dispatched even if the LoaderMax itself isn't in the process of loading (because load() or prioritize() could have been called directly on a child loader) **/
	[Event(name="childCancel", 			type="com.greensock.events.LoaderEvent")]
	/** Dispatched when any child of the LoaderMax instance dispatches a SCRIPT_ACCESS_DENIED event. This can occur even if the LoaderMax itself isn't in the process of loading (because load() or prioritize() could have been called directly on a child loader) **/
	[Event(name="scriptAccessDenied", 	type="com.greensock.events.LoaderEvent")]
	/** Dispatched when any child of the LoaderMax instance dispatches an HTTP_STATUS event. This can occur even if the LoaderMax itself isn't in the process of loading (because load() or prioritize() could have been called directly on a child loader) **/
	[Event(name="httpStatus", 			type="com.greensock.events.LoaderEvent")]
	/** Dispatched when any child of the LoaderMax instance dispatches an IO_ERROR event. This can occur even if the LoaderMax itself isn't in the process of loading (because load() or prioritize() could have been called directly on a child loader) **/
	[Event(name="ioError", 				type="com.greensock.events.LoaderEvent")]
	/** Dispatched when any child of the LoaderMax instance dispatches a SECURITY_ERROR event. This can occur even if the LoaderMax itself isn't in the process of loading (because load() or prioritize() could have been called directly on a child loader) **/
	[Event(name="securityError", 		type="com.greensock.events.LoaderEvent")]
/**
 * In its simplest form, a LoaderMax provides a way to group a sequence of loaders together and 
 * report their progress as a whole. It is essentially a queue of loaders. But there are many other 
 * conveniences that the LoaderMax system delivers: 
 * <ul>
 * 		<li><strong> Integration of loaders inside subloaded swfs</strong> - With most other systems, if you subload a swf, the loader will only concern itself with the swf file's bytes but what if that swf must subload other content like XML, images, and/or other swf files before it should be considered fully loaded? LoaderMax can elegantly handle the sub-subloads as deep as they go. You can link any loader and/or LoaderMax with a swf's root (using the <code>requireWithRoot</code> vars property) so that when you subload it into another Flash application, the parent SWFLoader automatically factors the nested loaders into its overall loading progress! It won't dispatch its <code>COMPLETE</code> event until they have finished as well. </li>
 * 		<li><strong> Automatic parsing of LoaderMax-related nodes inside XML</strong> - The XMLLoader class automatically looks for LoaderMax-related nodes like <code>&lt;LoaderMax&gt;, &lt;ImageLoader&gt;, &lt;SWFLoader&gt;, &lt;XMLLoader&gt;, &lt;VideoLoader&gt;, &lt;DataLoader&gt;, &lt;CSSLoader&gt;, &lt;MP3Loader&gt;</code>, etc. in XML files that it loads, and if any are found it will create the necessary instances and then begin loading the ones that had a <code>load="true"</code> attribute, automatically integrating their progress into the XMLLoader's overall progress and it won't dispatch a <code>COMPLETE</code> event until the XML-driven loaders have finished as well.</li>
 * 		<li><strong> Tight file size</strong> - Many other systems are 16-24k+ even if you're just loading text, but LoaderMax can be as little as <strong>7k</strong> (depending on which loader types you use).</li>
 * 		<li><strong> A common set of properties and methods among all loaders</strong> - Every loader type (XMLLoader, SWFLoader, ImageLoader, MP3Loader, CSSLoader, VideoLoader, LoaderMax, etc.) all share common <code>content, name, status, loadTime, paused, bytesLoaded, bytesTotal,</code> and <code>progress</code> properties as well as methods like <code>load(), pause(), resume(), prioritize(), unload(), cancel(), auditSize()</code> and <code>dispose()</code> delivering a touch of polymorphism sweetness.</li>
 * 		<li><strong> Nest LoaderMax instances inside other LoaderMax instances as deeply as you want.</strong> - This makes complex queues simple. Need to know when the first 3 loaders have finished loading inside a 10-loader queue? Just put those 3 into their own LoaderMax that has an onComplete and nest that LoaderMax inside your main LoaderMax queue. </li>
 * 		<li><strong> Set a width/height for an ImageLoader, SWFLoader, or VideoLoader and when it loads, the image/swf/video will automatically scale to fit</strong> using any of the following scaleModes: "stretch", "proportionalInside", "proportionalOutside", "widthOnly", or "heightOnly". Even crop the image/swf/video with <code>crop:true</code>.</li>
 * 		<li><strong> Conveniences like auto smoothing of images, centering their registration point, noCache, setting initial x, y, scaleX, scaleY, rotation, alpha, and blendMode properties, optional autoPlay for mp3s, swfs, and videos, and more.</strong></li>
 *		<li><strong> Works around common Flash hassles/bugs</strong> - LoaderMax implements workarounds for things like garbage collection headaches with subloaded swfs, images, and NetStreams as well as problems with subloaded swfs that use TLF.</li>
 * 		<li><strong> Find loaders and content by name or url</strong> - Every loader has a <code>name</code> property which you can use to uniquely identify it. Feed a name or URL to the static <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> methods to quickly get the associated loader or content.</li>
 *		<li><strong> A single loader can belong to multiple LoaderMax instances</strong></li>
 * 		<li><strong> Accurate progress reporting</strong> - For maximum performance, set an <code>estimatedBytes</code> for each loader or allow LoaderMax's <code>auditSize</code> feature to automatically preload just enough of each child loader's content to determine its <code>bytesTotal</code>, making progress reporting on large queues very accurate.</li>
 * 		<li><strong> prioritize() a loader anytime</strong> - Kick an object to the top of all LoaderMax queues to which it belongs, immediately supplanting the top spot in each one.</li>
 * 		<li><strong> A robust event system</strong></li>
 * 		<li><strong> Define an alternateURL for any loader</strong> - If the original <code>url</code> fails to load, it will automatically switch to the <code>alternateURL</code> and try again.</li>
 * 		<li><strong> Set up multiple event listeners in one line</strong> - Add listeners like onComplete, onProgress, onError, etc. via the constructor like <code>new LoaderMax({name:"mainQueue", onComplete:completeHandler, onProgress:progressHandler, onError:errorHandler});</code></li>
 * 		<li><strong> maxConnections</strong> - Set the maximum number of simultaneous connections for each LoaderMax instance (default is 2). This can speed up overall loading times.</li>
 * 		<li><strong> pause()/resume()</strong> - no queue loading solution would be complete without the ability to pause()/resume() anytime.</li>
 * 		<li><strong> Flex friendly </strong> - Simply change the <code>LoaderMax.contentDisplayClass</code> to <code>FlexContentDisplay</code> and then ImageLoaders, SWFLoaders, and VideoLoaders will return <code>content</code> wrapped in a UIComponent.</li>
 * </ul><br />
 * 
 * @example Example AS3 code:<listing version="3.0">
import com.greensock.~~;
import com.greensock.loading.~~;
import com.greensock.events.LoaderEvent;
import com.greensock.loading.display.~~;
 
//create a LoaderMax named "mainQueue" and set up onProgress, onComplete and onError listeners
var queue:LoaderMax = new LoaderMax({name:"mainQueue", onProgress:progressHandler, onComplete:completeHandler, onError:errorHandler});

//append several loaders
queue.append( new XMLLoader("xml/data.xml", {name:"xmlDoc", alternateURL:"http://otherserver.com/data.xml"}) );
queue.append( new ImageLoader("img/photo1.jpg", {name:"photo1", estimatedBytes:2400, container:this, alpha:0, width:250, height:150, scaleMode:"proportionalInside"}) );
queue.append( new SWFLoader("swf/main.swf", {name:"mainClip", estimatedBytes:3000, container:this, x:250, autoPlay:false}) );

//add a loader to the top of the queue using prepend()
queue.prepend( new MP3Loader("mp3/audio.mp3", {name:"audio", repeat:100, autoPlay:true}) );

//prioritize the loader named "photo1"
LoaderMax.prioritize("photo1");  //same as LoaderMax.getLoader("photo1").prioritize();

//start loading
queue.load();

function progressHandler(event:LoaderEvent):void {
    trace("progress: " + event.target.progress);
}

function completeHandler(event:LoaderEvent):void {
 	var image:ContentDisplay = LoaderMax.getContent("photo1");
 	TweenLite.to(image, 1, {alpha:1, y:100});
 	trace(event.target + " is complete!");
}
 
function errorHandler(event:LoaderEvent):void {
    trace("error occured with " + event.target + ": " + event.text);
}
 </listing>
 * 
 * LoaderMax will automatically skip over any child loaders in the queue that are already complete. By default 
 * it will also skip any that have failed or are paused (you can change this behavior with the <code>skipFailed</code> 
 * and <code>skipPaused</code> special properties). To flush the content and force a full reload, simply <code>unload()</code>
 * first or use the <code>flushContent</code> parameter in <code>load()</code> like <code>load(true)</code>.<br /><br />
 * 
 * <strong>OPTIONAL VARS PROPERTIES</strong><br />
 * The following special properties can be passed into the LoaderMax constructor via the <code>vars</code> 
 * parameter which can be either a generic object or a <code><a href="data/LoaderMaxVars.html">LoaderMaxVars</a></code> object:<br />
 * <ul>
 * 		<li><strong> name : String</strong> - A name that is used to identify the LoaderMax instance. This name can be fed to the <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> methods or traced at any time. Each loader's name should be unique. If you don't define one, a unique name will be created automatically, like "loader21".</li>
 * 		<li><strong> auditSize : Boolean</strong> - By default, when the LoaderMax begins to load it quickly loops through its children and if it finds any that don't have an <code>estimatedBytes</code> defined, it will briefly open a URLStream in order to attempt to determine its <code>bytesTotal</code>, immediately closing the URLStream once the value has been determined. This causes a brief delay initially, but greatly improves the accuracy of the <code>progress</code> and <code>bytesTotal</code> values. Set <code>auditSize</code> to <code>false</code> to prevent the LoaderMax from auditing its childrens' size (it is <code>true</code> by default). For maximum performance, it is best to define an <code>estimatedBytes</code> value for as many loaders as possible to avoid the delay caused by audits. When the LoaderMax audits an XMLLoader, it cannot recognize loaders that will be created from the XML data nor can it recognize loaders inside subloaded swf files from a SWFLoader (it would take far too long to load sufficient data for that - audits should be as fast as possible). If you do not set an appropriate <code>estimatedSize</code> for XMLLoaders or SWFLoaders that contain LoaderMax loaders, you'll notice that the parent LoaderMax's <code>progress</code> and <code>bytesTotal</code> change when the nested loaders are recognized (this is normal). To control the default <code>auditSize</code> value, use the static <code>LoaderMax.defaultAuditSize</code> property.</li>
 * 		<li><strong> maxConnections : uint</strong> - Maximum number of simultaneous connections that should be used while loading the LoaderMax queue. A higher number will generally result in faster overall load times for the group. The default is 2. This value is instance-based, not system-wide, so if you have two LoaderMax instances that both have a <code>maxConnections</code> value of 3 and they are both loading, there could be up to 6 connections at a time total. Sometimes there are limits imposed by the Flash Player itself or the browser or the user's system, but LoaderMax will do its best to honor the <code>maxConnections</code> you define.</li>
 * 		<li><strong> skipFailed : Boolean</strong> - If <code>skipFailed</code> is <code>true</code> (the default), any failed loaders in the queue will be skipped. Otherwise, the LoaderMax will stop when it hits a failed loader and the LoaderMax's status will become <code>LoaderStatus.FAILED</code>.</li>
 * 		<li><strong> skipPaused : Boolean</strong> - If <code>skipPaused</code> is <code>true</code> (the default), any paused loaders in the queue will be skipped. Otherwise, the LoaderMax will stop when it hits a paused loader and the LoaderMax's status will become <code>LoaderStatus.FAILED</code>.</li>
 * 		<li><strong> autoLoad : Boolean</strong> - If <code>true</code>, the LoaderMax instance will automatically call <code>load()</code> whenever you insert()/append()/prepend() a new loader whose status is <code>LoaderStatus.READY</code>. This basically makes it easy to create a LoaderMax queue and dump stuff into it whenever you want it to load without having to check the LoaderMax's status and call <code>load()</code> manually if it's not already loading.</li>
 * 		<li><strong> loaders : Array</strong> - An array of loaders (ImageLoaders, SWFLoaders, XMLLoaders, MP3Loaders, other LoaderMax instances, etc.) that should be immediately inserted into the LoaderMax.</li>
 * 		<li><strong> requireWithRoot : DisplayObject</strong> - LoaderMax supports <i>subloading</i>, where an object can be factored into a parent's loading progress. If you want this LoaderMax to be required as part of its parent SWFLoader's progress, you must set the <code>requireWithRoot</code> property to your swf's <code>root</code>. For example, <code>var loader:LoaderMax = new LoaderMax({name:"mainQueue", requireWithRoot:this.root});</code></li>
 * 		<li><strong> autoDispose : Boolean</strong> - When <code>autoDispose</code> is <code>true</code>, the loader will be disposed immediately after it completes (it calls the <code>dispose()</code> method internally after dispatching its <code>COMPLETE</code> event). This will remove any listeners that were defined in the vars object (like onComplete, onProgress, onError, onInit). Once a loader is disposed, it can no longer be found with <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> - it is essentially destroyed but its content is not unloaded (you must call <code>unload()</code> or <code>dispose(true)</code> to unload its content). The default <code>autoDispose</code> value is <code>false</code>.
 * 			
 * 		<br /><br />----EVENT HANDLER SHORTCUTS----</li>
 * 		<li><strong> onOpen : Function</strong> - A handler function for <code>LoaderEvent.OPEN</code> events which are dispatched when the loader begins loading. Make sure your onOpen function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onProgress : Function</strong> - A handler function for <code>LoaderEvent.PROGRESS</code> events which are dispatched whenever the <code>bytesLoaded</code> changes. Make sure your onProgress function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). You can use the LoaderEvent's <code>target.progress</code> to get the loader's progress value or use its <code>target.bytesLoaded</code> and <code>target.bytesTotal</code>.</li>
 * 		<li><strong> onComplete : Function</strong> - A handler function for <code>LoaderEvent.COMPLETE</code> events which are dispatched when the loader has finished loading. Make sure your onComplete function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onCancel : Function</strong> - A handler function for <code>LoaderEvent.CANCEL</code> events which are dispatched when loading is aborted due to either an error or because another loader was prioritized or <code>cancel()</code> was manually called. Make sure your onCancel function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onError : Function</strong> - A handler function for <code>LoaderEvent.ERROR</code> events which are dispatched whenever the loader or any of its children fails (typically because of an IO_ERROR or SECURITY_ERROR). Make sure your onError function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onChildOpen : Function</strong> - A handler function for <code>LoaderEvent.CHILD_OPEN</code> events which are dispatched each time one of the loader's children (or any descendant) begins loading. Make sure your onChildOpen function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onChildProgress : Function</strong> - A handler function for <code>LoaderEvent.CHILD_PROGRESS</code> events which are dispatched each time one of the loader's children (or any descendant) dispatches a <code>PROGRESS</code> event. To listen for changes in the LoaderMax's overall progress, use the <code>onProgress</code> special property instead. You can use the LoaderEvent's <code>target.progress</code> to get the child loader's progress value or use its <code>target.bytesLoaded</code> and <code>target.bytesTotal</code>. The LoaderEvent's <code>currentTarget</code> refers to the LoaderMax, so you can check its overall progress with the LoaderEvent's <code>currentTarget.progress</code>. Make sure your onChildProgress function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onChildComplete : Function</strong> - A handler function for <code>LoaderEvent.CHILD_COMPLETE</code> events which are dispatched each time one of the loader's children (or any descendant) finishes loading successfully. Make sure your onChildComplete function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onChildCancel : Function</strong> - A handler function for <code>LoaderEvent.CHILD_CANCEL</code> events which are dispatched each time loading is aborted on one of the loader's children (or any descendant) due to either an error or because another loader was prioritized in the queue or because <code>cancel()</code> was manually called on the child loader. Make sure your onChildCancel function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onChildFail : Function</strong> - A handler function for <code>LoaderEvent.CHILD_FAIL</code> events which are dispatched each time one of the loader's children (or any descendant) fails (and its <code>status</code> chances to <code>LoaderStatus.FAILED</code>). Make sure your onChildFail function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onIOError : Function</strong> - A handler function for <code>LoaderEvent.IO_ERROR</code> events which will also call the onError handler, so you can use that as more of a catch-all whereas <code>onIOError</code> is specifically for LoaderEvent.IO_ERROR events. Make sure your onIOError function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onHTTPStatus : Function</strong> - A handler function for <code>LoaderEvent.HTTP_STATUS</code> events. Make sure your onHTTPStatus function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onScriptAccessDenied : Function</strong> - A handler function for <code>LoaderEvent.SCRIPT_ACCESS_DENIED</code> events which are dispatched when one of the LoaderMax's children (or any descendant) is loaded from another domain and no crossdomain.xml is in place to grant full script access for things like smoothing or BitmapData manipulation. Make sure your function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * </ul><br /><br />
 * 
 * <strong>Note:</strong> Using a <code><a href="data/LoaderMaxVars.html">LoaderMaxVars</a></code> instance 
 * instead of a generic object to define your <code>vars</code> is a bit more verbose but provides 
 * code hinting and improved debugging because it enforces strict data typing. Use whichever one you prefer.<br /><br />
 * 
 * <b>Copyright 2010-2012, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @see com.greensock.loading.data.LoaderMaxVars
 * 
 * @author Jack Doyle, jack@greensock.com
 */	
	public class LoaderMax extends LoaderCore {		
		/** @private **/
		public static const version:Number = 1.921;
		/** The default value that will be used for the <code>estimatedBytes</code> on loaders that don't declare one in the <code>vars</code> parameter of the constructor. **/
		public static var defaultEstimatedBytes:uint = 20000;
		/** Controls the default value of <code>auditSize</code> in LoaderMax instances (normally <code>true</code>). For most situations, the auditSize feature is very convenient for ensuring that the overall progress of LoaderMax instances is reported accurately, but when working with very large quantities of files that have no <code>estimatedBytes</code> defined, some developers prefer to turn auditSize off by default. Of course you can always override the default for individual LoaderMax instances by defining an <code>auditSize</code> value in the <code>vars</code> parameter of the constructor. **/
		public static var defaultAuditSize:Boolean = true;
		/** Optionally define a default <code>LoaderContext</code> to use with SWFLoaders and ImageLoaders. This can be useful if you're loading a lot of swfs, for example, and don't want to pass a custom "context" in to each one. LoaderContexts are typically used to tell Flash which ApplicationDomain to load the code into and which SecurityDomain to use. See Adobe's docs for details. **/
		public static var defaultContext:LoaderContext;
		/** The class used by ImageLoaders, SWFLoaders, and VideoLoaders to create the containers into which they'll dump their rawContent - by default it is the <code>com.greensock.loading.display.ContentDisplay</code> class but if you're using Flex, it is typically best to change this to <code>com.greensock.loading.display.FlexContentDisplay</code>. You only need to do this once, like <br /><code>import com.greensock.loading.LoaderMax;<br />import com.greensock.loading.display.FlexContentDisplay;<br />LoaderMax.contentDisplayClass = FlexContentDisplay;</code> **/
		public static var contentDisplayClass:Class;
		
		/** @private **/
		protected var _loaders:Array;
		/** @private **/
		protected var _activeLoaders:Dictionary;
		
		/** If <code>skipFailed</code> is <code>true</code> (the default), any failed loaders in the queue will be skipped. Otherwise, the LoaderMax will stop when it hits a failed loader and the LoaderMax's status will become <code>LoaderStatus.FAILED</code>. Skipped loaders are also ignored when the LoaderMax determines its <code>bytesLoaded, bytesTotal</code>, and <code>progress</code> values. **/
		public var skipFailed:Boolean;
		/** If <code>skipPaused</code> is <code>true</code> (the default), any paused loaders in the queue will be skipped. Otherwise, the LoaderMax will stop when it hits a paused loader and the LoaderMax's status will become <code>LoaderStatus.FAILED</code>. Skipped loaders are also ignored when the LoaderMax determines its <code>bytesLoaded, bytesTotal</code>, and <code>progress</code> values. **/
		public var skipPaused:Boolean;
		/** Maximum number of simultaneous connections that should be used while loading the LoaderMax queue. A higher number will generally result in faster overall load times for the group. The default is 2. This value is instance-based, not system-wide, so if you have two LoaderMax instances that both have a <code>maxConnections</code> value of 3 and they are both loading, there could be up to 6 connections at a time total. **/
		public var maxConnections:uint;
		/** If <code>true</code>, the LoaderMax instance will automatically call <code>load()</code> whenever you insert()/append()/prepend() a new loader whose status is <code>LoaderStatus.READY</code>. This basically makes it easy to create a LoaderMax queue and dump stuff into it whenever you want something to load without having to check the LoaderMax's status and call <code>load()</code> manually if it's not already loading. **/
		public var autoLoad:Boolean;
				
		/**
		 * Constructor
		 * 
		 * @param vars An object containing optional configuration details. For example: <code>new LoaderMax({name:"queue", onComplete:completeHandler, onProgress:progressHandler, maxConnections:3})</code>.<br /><br />
		 * 
		 * The following special properties can be passed into the LoaderMax constructor via the <code>vars</code> parameter
		 * which can be either a generic object or a <code><a href="data/LoaderMaxVars.html">LoaderMaxVars</a></code> object:<br />
		 * <ul>
		 * 		<li><strong> name : String</strong> - A name that is used to identify the LoaderMax instance. This name can be fed to the <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> methods or traced at any time. Each loader's name should be unique. If you don't define one, a unique name will be created automatically, like "loader21".</li>
		 * 		<li><strong> auditSize : Boolean</strong> - By default, when the LoaderMax begins to load it quickly loops through its children and if it finds any that don't have an <code>estimatedBytes</code> defined, it will briefly open a URLStream in order to attempt to determine its <code>bytesTotal</code>, immediately closing the URLStream once the value has been determined. This causes a brief delay initially, but greatly improves the accuracy of the <code>progress</code> and <code>bytesTotal</code> values. Set <code>auditSize</code> to <code>false</code> to prevent the LoaderMax from auditing its childrens' size (it is <code>true</code> by default). For maximum performance, it is best to define an <code>estimatedBytes</code> value for as many loaders as possible to avoid the delay caused by audits. When the LoaderMax audits an XMLLoader, it cannot recognize loaders that will be created from the XML data nor can it recognize loaders inside subloaded swf files from a SWFLoader (it would take far too long to load sufficient data for that - audits should be as fast as possible). If you do not set an appropriate <code>estimatedSize</code> for XMLLoaders or SWFLoaders that contain LoaderMax loaders, you'll notice that the parent LoaderMax's <code>progress</code> and <code>bytesTotal</code> change when the nested loaders are recognized (this is normal). To control the default <code>auditSize</code> value, use the static <code>LoaderMax.defaultAuditSize</code> property.</li>
		 * 		<li><strong> maxConnections : uint</strong> - Maximum number of simultaneous connections that should be used while loading the LoaderMax queue. A higher number will generally result in faster overall load times for the group. The default is 2. This value is instance-based, not system-wide, so if you have two LoaderMax instances that both have a <code>maxConnections</code> value of 3 and they are both loading, there could be up to 6 connections at a time total. Sometimes there are limits imposed by the Flash Player itself or the browser or the user's system, but LoaderMax will do its best to honor the <code>maxConnections</code> you define.</li>
		 * 		<li><strong> skipFailed : Boolean</strong> - If <code>skipFailed</code> is <code>true</code> (the default), any failed loaders in the queue will be skipped. Otherwise, the LoaderMax will stop when it hits a failed loader and the LoaderMax's status will become <code>LoaderStatus.FAILED</code>.</li>
		 * 		<li><strong> skipPaused : Boolean</strong> - If <code>skipPaused</code> is <code>true</code> (the default), any paused loaders in the queue will be skipped. Otherwise, the LoaderMax will stop when it hits a paused loader and the LoaderMax's status will become <code>LoaderStatus.FAILED</code>.</li>
		 * 		<li><strong> autoLoad : Boolean</strong> - If <code>true</code>, the LoaderMax instance will automatically call <code>load()</code> whenever you insert()/append()/prepend() a new loader whose status is <code>LoaderStatus.READY</code>. This basically makes it easy to create a LoaderMax queue and dump stuff into it whenever you want it to load without having to check the LoaderMax's status and call <code>load()</code> manually if it's not already loading.</li>
		 * 		<li><strong> loaders : Array</strong> - An array of loaders (ImageLoaders, SWFLoaders, XMLLoaders, MP3Loaders, other LoaderMax instances, etc.) that should be immediately inserted into the LoaderMax.</li>
		 * 		<li><strong> requireWithRoot : DisplayObject</strong> - LoaderMax supports <i>subloading</i>, where an object can be factored into a parent's loading progress. If you want this LoaderMax to be required as part of its parent SWFLoader's progress, you must set the <code>requireWithRoot</code> property to your swf's <code>root</code>. For example, <code>var loader:LoaderMax = new LoaderMax({name:"mainQueue", requireWithRoot:this.root});</code></li>
		 * 		<li><strong> autoDispose : Boolean</strong> - When <code>autoDispose</code> is <code>true</code>, the loader will be disposed immediately after it completes (it calls the <code>dispose()</code> method internally after dispatching its <code>COMPLETE</code> event). This will remove any listeners that were defined in the vars object (like onComplete, onProgress, onError, onInit). Once a loader is disposed, it can no longer be found with <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> - it is essentially destroyed but its content is not unloaded (you must call <code>unload()</code> or <code>dispose(true)</code> to unload its content). The default <code>autoDispose</code> value is <code>false</code>.
		 * 			
		 * 		<br /><br />----EVENT HANDLER SHORTCUTS----</li>
		 * 		<li><strong> onOpen : Function</strong> - A handler function for <code>LoaderEvent.OPEN</code> events which are dispatched when the loader begins loading. Make sure your onOpen function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onProgress : Function</strong> - A handler function for <code>LoaderEvent.PROGRESS</code> events which are dispatched whenever the <code>bytesLoaded</code> changes. Make sure your onProgress function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). You can use the LoaderEvent's <code>target.progress</code> to get the loader's progress value or use its <code>target.bytesLoaded</code> and <code>target.bytesTotal</code>.</li>
		 * 		<li><strong> onComplete : Function</strong> - A handler function for <code>LoaderEvent.COMPLETE</code> events which are dispatched when the loader has finished loading. Make sure your onComplete function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onCancel : Function</strong> - A handler function for <code>LoaderEvent.CANCEL</code> events which are dispatched when loading is aborted due to either an error or because another loader was prioritized or <code>cancel()</code> was manually called. Make sure your onCancel function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onError : Function</strong> - A handler function for <code>LoaderEvent.ERROR</code> events which are dispatched whenever the loader or any of its children fails (typically because of an IO_ERROR or SECURITY_ERROR). Make sure your onError function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onChildOpen : Function</strong> - A handler function for <code>LoaderEvent.CHILD_OPEN</code> events which are dispatched each time one of the loader's children (or any descendant) begins loading. Make sure your onChildOpen function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onChildProgress : Function</strong> - A handler function for <code>LoaderEvent.CHILD_PROGRESS</code> events which are dispatched each time one of the loader's children (or any descendant) dispatches a <code>PROGRESS</code> event. To listen for changes in the LoaderMax's overall progress, use the <code>onProgress</code> special property instead. You can use the LoaderEvent's <code>target.progress</code> to get the child loader's progress value or use its <code>target.bytesLoaded</code> and <code>target.bytesTotal</code>. The LoaderEvent's <code>currentTarget</code> refers to the LoaderMax, so you can check its overall progress with the LoaderEvent's <code>currentTarget.progress</code>. Make sure your onChildProgress function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onChildComplete : Function</strong> - A handler function for <code>LoaderEvent.CHILD_COMPLETE</code> events which are dispatched each time one of the loader's children (or any descendant) finishes loading successfully. Make sure your onChildComplete function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onChildCancel : Function</strong> - A handler function for <code>LoaderEvent.CHILD_CANCEL</code> events which are dispatched each time loading is aborted on one of the loader's children (or any descendant) due to either an error or because another loader was prioritized in the queue or because <code>cancel()</code> was manually called on the child loader. Make sure your onChildCancel function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onChildFail : Function</strong> - A handler function for <code>LoaderEvent.CHILD_FAIL</code> events which are dispatched each time one of the loader's children (or any descendant) fails (and its <code>status</code> chances to <code>LoaderStatus.FAILED</code>). Make sure your onChildFail function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onIOError : Function</strong> - A handler function for <code>LoaderEvent.IO_ERROR</code> events which will also call the onError handler, so you can use that as more of a catch-all whereas <code>onIOError</code> is specifically for LoaderEvent.IO_ERROR events. Make sure your onIOError function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onHTTPStatus : Function</strong> - A handler function for <code>LoaderEvent.HTTP_STATUS</code> events. Make sure your onHTTPStatus function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onScriptAccessDenied : Function</strong> - A handler function for <code>LoaderEvent.SCRIPT_ACCESS_DENIED</code> events which are dispatched when one of the LoaderMax's children (or any descendant) is loaded from another domain and no crossdomain.xml is in place to grant full script access for things like smoothing or BitmapData manipulation. Make sure your function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * </ul>
		 * @see com.greensock.loading.data.LoaderMaxVars
		 */
		public function LoaderMax(vars:Object=null) {
			super(vars);
			_type = "LoaderMax";
			_loaders = [];
			_activeLoaders = new Dictionary();
			this.skipFailed = Boolean(this.vars.skipFailed != false);
			this.skipPaused = Boolean(this.vars.skipPaused != false);
			this.autoLoad = Boolean(this.vars.autoLoad == true);
			this.maxConnections = ("maxConnections" in this.vars) ? uint(this.vars.maxConnections) : 2;
			if (this.vars.loaders is Array) {
				for (var i:int = 0; i < this.vars.loaders.length; i++) {
					insert(this.vars.loaders[i], i);
				}
			}
		}
		
		/**
		 * Analyzes a url or array of urls and attempts to automatically create the appropriate loader(s) based
		 * on file extension(s) in the url(s), returning either an individual loader like an ImageLoader, 
		 * SWFLoader, XMLLoader, etc or if an array is passed in, a LoaderMax will be returned containing
		 * a child for each parsed url (or URLRequest) in the array. Arrays may also contain LoaderCore instances 
		 * (not just url Strings). For example:<br />
		 * @example Single loader example:<listing version="3.0">
import com.greensock.loading.~~;
import com.greensock.loading.core.~~;
import com.greensock.events.LoaderEvent;
 
//activate the necessary loaders so that their file extensions can be recognized (do this once)
LoaderMax.activate([ImageLoader, SWFLoader, XMLLoader]);

//now parse a url and create the correct type of loader (an ImageLoader in this case because the file extension is ".jpg")
var loader:LoaderCore = LoaderMax.parse("../img/photo1.jpg", {name:"parsedLoader", onComplete:completeHandler});
 
//begin loading
loader.load();
 
function completeHandler(event:LoaderEvent):void {
	trace("finished loading " + event.target);
}
 </listing>
		 * If an array is passed to the <code>LoaderMax.parse()</code> method, it will create a LoaderMax instance
		 * and add the necessary children based on the contents of the array:<br />
		 * @example Array example:<listing version="3.0">
import com.greensock.loading.~~;
import com.greensock.events.LoaderEvent;
 
//activate the necessary loaders so that their file extensions can be recognized (do this once)
LoaderMax.activate([ImageLoader, SWFLoader, XMLLoader, MP3Loader]);
 
var urls:Array = ["img/photo1.jpg","../../xml/data.xml","swf/main.swf","http://www.greensock.com/audio/music.mp3"];

//now parse all of the urls, creating a LoaderMax that contains the correct type of loaders (an ImageLoader, XMLLoader, SWFLoader, and MP3Loader respectively)
var loader:LoaderMax = LoaderMax.parse(urls, {name:"mainQueue", onComplete:completeHandler}) as LoaderMax;
 
//begin loading
loader.load();
 
function completeHandler(event:LoaderEvent):void {
	trace("finished loading " + loader.numChildren + " loaders.");
}
 </listing>
		 * 
		 * @param data A String or an array of Strings (and/or LoaderCore instances and/or URLRequest instances) to parse.
		 * @param vars The <code>vars</code> object to pass the loader's constructor. If <code>data</code> is an array, this <code>vars</code> will be passed to the LoaderMax instance that gets created, and no <code>vars</code> object will be passed to the child loaders that get created.
		 * @param childrenVars The <code>vars</code> object that will be passed to each child loader's constructor (only applicable when the <code>data</code> parameter is an array which means <code>parse()</code> will return a LoaderMax). For example, if you <code>parse()</code> and array of video urls and want <code>autoPlay</code> set to <code>false</code> for all of them, you'd do <code>LoaderMax.parse(["1.flv","2.f4v","3.mp4"], null, {autoPlay:false});</code>. 
		 * @return If <code>data</code> is an array, <code>parse()</code> will return a LoaderMax. Otherwise, it will return the appropriate loader based on the file extension found in the URL. In any case, the object returned will be a <code>LoaderCore</code> object (all LoaderMax loaders extend LoaderCore, so if you need to datatype your object use <code>com.greensock.loading.core.LoaderCore</code>). The return value is typed as "*" in order to avoid compiler errors when developers forget to cast ther objects like <code>var image:ImageLoader = LoaderMax.parse("photo.jpg") as ImageLoader</code>
		 */
		public static function parse(data:*, vars:Object=null, childrenVars:Object=null):* {
			if (data is Array) {
				var queue:LoaderMax = new LoaderMax(vars);
				var l:int = data.length;
				for (var i:int = 0; i < l; i++) {
					queue.append(LoaderMax.parse(data[i], childrenVars));
				}
				return queue;
			} else if (data is String || data is URLRequest) {
				var s:String = (data is String) ? data : URLRequest(data).url;
				s = s.toLowerCase().split("?")[0];
				s = s.substr(s.lastIndexOf(".") + 1);
				if (s in _extensions) {
					return new _extensions[s](data, vars);
				}
			} else if (data is LoaderCore) {
				return data as LoaderCore;
			}
			throw new Error("LoaderMax could not parse " + data + ". Don't forget to use LoaderMax.activate() to activate the necessary types of loaders.");
			return null;
		}
		
		/** @private **/
		override protected function _load():void {
			_loadNext(null);
		}
		
		/**
		 * Appends a loader to the end of the queue.
		 * 
		 * @param loader The loader to append to the queue. It can be any loader (ImageLoader, XMLLoader, SWFLoader, MP3Loader, another LoaderMax, etc.).
		 * @return The loader that was appended.
		 * @see #prepend()
		 * @see #insert()
		 * @see #remove()
		 */
		public function append(loader:LoaderCore):LoaderCore {
			return insert(loader, _loaders.length);
		}
		
		/**
		 * Prepends a loader at the beginning of the queue (<code>append()</code> adds the loader to the end whereas <code>prepend()</code> adds it to the beginning).
		 * 
		 * @param loader The loader to prepend to the queue. It can be any loader (ImageLoader, XMLLoader, SWFLoader, MP3Loader, another LoaderMax, etc.).
		 * @return The loader that was prepended.
		 * @see #append()
		 * @see #insert()
		 * @see #remove()
		 */
		public function prepend(loader:LoaderCore):LoaderCore {
			return insert(loader, 0);
		}
		
		/**
		 * Inserts a loader at a particular position in the queue. Index values are zero-based just like arrays. 
		 * For example, if the LoaderMax has 10 loaders in it already and you want to insert a loader at the 3rd 
		 * position (index: 2) while moving the others back in the queue (like the way <code>splice()</code> works 
		 * in arrays), you'd do:<br /><br /><code>
		 * 
		 * queue.insert( new ImageLoader("img/photo.jpg"), 2);</code><br /><br />
		 * 
		 * When a new loader is added to the LoaderMax, the LoaderMax's status changes to <code>LoaderStatus.READY</code>
		 * unless it is paused or disposed. If the loader is already in the queue, it will be removed first.
		 * 
		 * @param loader The loader to insert into the queue. It can be any loader (ImageLoader, XMLLoader, SWFLoader, MP3Loader, DataLoader, CSSLoader, another LoaderMax, etc.).
		 * @param index The index position at which the loader should be inserted, exactly like the way <code>splice()</code> works for arrays. Index values are 0-based, so the first position is 0, the second is 1, the third is 2, etc.
		 * @return The loader that was inserted
		 * @see #append()
		 * @see #prepend()
		 * @see #remove()
		 */
		public function insert(loader:LoaderCore, index:uint=999999999):LoaderCore {
			if (loader == null || loader == this || _status == LoaderStatus.DISPOSED) {
				return null;
			}
			if (this != loader.rootLoader) {
				_removeLoader(loader, false); //in case it was already added.
			}
			if (loader.rootLoader == _globalRootLoader) { //don't remove from rootLoaders other than _globalRootLoader, otherwise subloading swfs with loaders that contain LoaderMax instances with nested loaders that have requiredWithRoot set to the associated rootLoader won't be able to be found inside that rootLoader. We could of course leave loaders in _globalRootLoader, but that we get a performance benefit from removing them (fewer event listeners getting called).
				loader.rootLoader.remove(loader);
			}
			
			if (index > _loaders.length) {
				index = _loaders.length;
			}
			
			_loaders.splice(index, 0, loader);
			if (this != _globalRootLoader) {
				for (var p:String in _listenerTypes) {
					if (p != "onProgress" && p != "onInit") {
						loader.addEventListener(_listenerTypes[p], _passThroughEvent, false, -100, true);
					}
				}
				loader.addEventListener(LoaderEvent.PROGRESS, _progressHandler, false, -100, true); //use -1 so that if the user adds an event listener, it gets called before LoaderMax is notified. Otherwise bubbling behavior doesn't go in the proper order.
				loader.addEventListener("prioritize", _prioritizeHandler, false, -100, true);
			}
			loader.addEventListener("dispose", _disposeHandler, false, -100, true);
			_cacheIsDirty = true;
			if (_status == LoaderStatus.LOADING) {
				//do nothing 
			} else if (_status != LoaderStatus.PAUSED) {
				_status = LoaderStatus.READY;
			} else if (_prePauseStatus == LoaderStatus.COMPLETED) {
				_prePauseStatus = LoaderStatus.READY;
			}
			
			if (this.autoLoad && loader.status == LoaderStatus.READY) {
				if (_status != LoaderStatus.LOADING) {
					this.load(false);
				} else {
					_loadNext(null); //to ensure the maxConnections pipeline is full
				}
			}
			
			return loader;
		}
		
		/**
		 * Removes a loader from the LoaderMax.
		 * 
		 * @param loader The loader to remove from the LoaderMax
		 * @see #append()
		 * @see #insert()
		 * @see #prepend()
		 */
		public function remove(loader:LoaderCore):void {
			_removeLoader(loader, true);
		}
		
		/** @private **/
		protected function _removeLoader(loader:LoaderCore, rootLoaderAppend:Boolean):void {
			if (loader == null) {
				return;
			}
			if (rootLoaderAppend && this != loader.rootLoader) {
				loader.rootLoader.append(loader);
			}
			_removeLoaderListeners(loader, true);
			_loaders.splice(getChildIndex(loader), 1);
			if (loader in _activeLoaders) {
				delete _activeLoaders[loader];
				loader.cancel();
				if (_status == LoaderStatus.LOADING) {
					_loadNext(null);
				}
			}
			_cacheIsDirty = true;
			_progressHandler(null); //has conditional logic that will only dispatch a PROGRESS event if bytesLoaded or bytesTotal has changed.
		}
		
		/**
		 * Empties the LoaderMax of all its loaders and optionally disposes/unloads them.
		 * 
		 * @param disposeChildren If <code>true</code> (the default), <code>dispose()</code> will be called on all loaders in the LoaderMax.
		 * @param unloadAllContent If <code>true</code>, the <code>content</code> of all child loaders will be unloaded.
		 * @see #dispose()
		 * @see #unload()
		 */
		public function empty(disposeChildren:Boolean=true, unloadAllContent:Boolean=false):void {
			var i:int = _loaders.length;
			while (--i > -1) {
				if (disposeChildren) {
					LoaderCore(_loaders[i]).dispose(unloadAllContent);
				} else if (unloadAllContent) {
					LoaderCore(_loaders[i]).unload();
				} else {
					_removeLoader(_loaders[i], true);
				}
			}
		}
		
		/** @private scrubLevel: 0 = cancel, 1 = unload, 2 = dispose, 3 = flush **/
		override protected function _dump(scrubLevel:int=0, newStatus:int=0, suppressEvents:Boolean=false):void {
			if (newStatus == LoaderStatus.DISPOSED) {
				_status = LoaderStatus.DISPOSED; //must set it first so that when events from children are dispatched, it doesn't trigger other unnecessary actions.
				empty(true, Boolean(scrubLevel == 3));
				if (this.vars.requireWithRoot is DisplayObject) {
					delete _rootLookup[this.vars.requireWithRoot];
				}
				_activeLoaders = null;
			}
			if (scrubLevel <= 1) {
				_cancelActiveLoaders();
			}
			if (scrubLevel == 1) {
				var i:int = _loaders.length;
				while (--i > -1) {
					LoaderCore(_loaders[i]).unload();
				}
			}
			super._dump(scrubLevel, newStatus, suppressEvents);
			_cacheIsDirty = true;
		}
		
		/** @private **/
		override protected function _calculateProgress():void {
			_cachedBytesLoaded = 0;
			_cachedBytesTotal = 0;
			var i:int = _loaders.length;
			var loader:LoaderCore, s:int;
			while (--i > -1) {
				loader = _loaders[i];
				s = loader.status;
				if (s <= LoaderStatus.COMPLETED || (!this.skipPaused && s == LoaderStatus.PAUSED) || (!this.skipFailed && s == LoaderStatus.FAILED)) {
					_cachedBytesLoaded += loader.bytesLoaded;
					_cachedBytesTotal += loader.bytesTotal;
				}
			}
			_cacheIsDirty = false;
		}
		
		/** @private **/
		protected function _cancelActiveLoaders():void {
			var i:int = _loaders.length;
			var loader:LoaderCore;
			while (--i > -1) {
				loader = _loaders[i];
				if (loader.status == LoaderStatus.LOADING) {
					delete _activeLoaders[loader];
					_removeLoaderListeners(loader, false);
					loader.cancel();
				}
			}
		}
		
		/** @private **/
		protected function _removeLoaderListeners(loader:LoaderCore, all:Boolean):void {
			loader.removeEventListener(LoaderEvent.COMPLETE, _loadNext);
			loader.removeEventListener(LoaderEvent.CANCEL, _loadNext);
			if (all) {
				loader.removeEventListener(LoaderEvent.PROGRESS, _progressHandler);
				loader.removeEventListener("prioritize", _prioritizeHandler);
				loader.removeEventListener("dispose", _disposeHandler);
				for (var p:String in _listenerTypes) {
					if (p != "onProgress" && p != "onInit") {
						loader.removeEventListener(_listenerTypes[p], _passThroughEvent);
					}
				}
			}
		}
		
		/**
		 * Returns and array of child loaders that currently have a particular <code>status</code>. For example,
		 * to find all loaders inside the LoaderMax instance that are actively in the process of loading: <br /><br /><code>
		 * 
		 * loader.getChildrenByStatus(LoaderStatus.LOADING, false); </code>
		 * 
		 * @param status Status code like <code>LoaderStatus.READY, LoaderStatus.LOADING, LoaderStatus.COMPLETED, LoaderStatus.PAUSED,</code> or <code>LoaderStatus.FAILED</code>.
		 * @param includeNested If <code>true</code>, loaders that are nested inside other loaders (like LoaderMax instances or XMLLoaders or SWFLoaders) will be returned in the array.
		 * @return An array of loaders that match the defined <code>status</code>. 
		 * @see #getChildren()
		 * @see #getLoader()
		 * @see #numChildren
		 */
		public function getChildrenByStatus(status:int, includeNested:Boolean=false):Array {
			var a:Array = [];
			var loaders:Array = getChildren(includeNested, false);
			var l:int = loaders.length;
			for (var i:int = 0; i < l; i++) {
				if (LoaderCore(loaders[i]).status == status) {
					a.push(loaders[i]);
				}
			}
			return a;
		}
		
		/**
		 * Returns the child that is at a particular position (zero-based index) in the queue. For example, 
		 * <code>myLoaderMax.getChildAt(0)</code> would get the first loader in the queue. 
		 * <code>myLoaderMax.getChildAt(2)</code> would get the 3rd loader in the queue. 
		 * 
		 * @param index The index of the child in the queue that should be returned. For example, <code>myLoaderMax.getChildAt(0)</code> would get the first loader in the queue. <code>myLoaderMax.getChildAt(2)</code> would get the 3rd loader.
		 * @return The child loader that is located at the corresponding index 
		 * @see #getChildren()
		 * @see #getLoader()
		 * @see #getChildrenByStatus()
		 */
		public function getChildAt(index:int):* {
			return _loaders[index];
		}
		
		/**
		 * Returns and array of all child loaders inside the LoaderMax, optionally exposing more deeply nested 
		 * instances as well (like loaders inside a child LoaderMax instance). 
		 * 
		 * @param includeNested If <code>true</code>, loaders that are nested inside child LoaderMax, XMLLoader, or SWFLoader instances will be included in the returned array as well. The default is <code>false</code>.
		 * @param omitLoaderMaxes If <code>true</code>, no LoaderMax instances will be returned in the array; only LoaderItems like ImageLoaders, XMLLoaders, SWFLoaders, MP3Loaders, etc. The default is <code>false</code>. 
		 * @return An array of loaders.
		 * @see #getChildrenByStatus() 
		 * @see #getLoader()
		 * @see #numChildren
		 */
		public function getChildren(includeNested:Boolean=false, omitLoaderMaxes:Boolean=false):Array {
			var a:Array = [];
			var l:int = _loaders.length;
			for (var i:int = 0; i < l; i++) {
				if (!omitLoaderMaxes || !(_loaders[i] is LoaderMax)) {
					a.push(_loaders[i]);
				}
				if (includeNested && _loaders[i].hasOwnProperty("getChildren")) {
					a = a.concat(_loaders[i].getChildren(true, omitLoaderMaxes));
				}
			}
			return a;
		}
		
		/**
		 * Immediately prepends a value to the beginning of each child loader's <code>url</code>. For example,
		 * if the "myLoaderMax" instance contains 3 ImageLoaders with the urls "image1.jpg", "image2.jpg", and "image3.jpg"
		 * and you'd like to add "http://www.greensock.com/images/" to the beginning of them all, you'd do:<br /><br /><code>
		 * 
		 * myLoaderMax.prependURLs("http://www.greensock.com/images/", false);<br /><br /></code>
		 * 
		 * Now the ImageLoader urls would be "http://www.greensock.com/images/image1.jpg", "http://www.greensock.com/images/image2.jpg",
		 * and "http://www.greensock.com/images/image3.jpg" respectively. <br /><br />
		 * 
		 * <code>prependURLs()</code> permanently affects each child loader's url meaning that
		 * <code>LoaderMax.getContent("image1.jpg")</code> would not find the loader whose <code>url</code>
		 * is now "http://www.greensock.com/images/image1.jpg" (although you could simply use its <code>name</code> 
		 * instead of its <code>url</code> to find it). It also means that if a single loader has been
		 * inserted into multiple LoaderMax instances, its <code>url</code> change affects them all. <br /><br />
		 * 
		 * <code>prependURLs()</code> only affects loaders that are children of the LoaderMax when 
		 * the method is called - it does <strong>not</strong> affect loaders that are inserted later. <br /><br />
		 * 
		 * <code>prependURLs()</code> does <strong>NOT</strong> affect any <code>alternateURL</code> values that are defined
		 * for each child loader.
		 * 
		 * @param value The String that should be prepended to each child loader
		 * @param includeNested If <code>true</code>, loaders nested inside child LoaderMax instances will also be affected. It is <code>false</code> by default.
		 * @see #replaceURLText()
		 */
		public function prependURLs(prependText:String, includeNested:Boolean=false):void {
			var loaders:Array = getChildren(includeNested, true);
			var i:int = loaders.length;
			while (--i > -1) {
				LoaderItem(loaders[i]).url = prependText + LoaderItem(loaders[i]).url;
			}
		}
		
		/**
		 * Immediately replaces a certain substring in each child loader's <code>url</code> with another string,
		 * making it simple to do something like change <code>"{imageDirectory}image1.jpg"</code> to 
		 * <code>"http://www.greensock.com/images/image1.jpg"</code>. For example,
		 * if the "myLoaderMax" instance contains 3 ImageLoaders with the urls <code>"{imageDirectory}image1.jpg", 
		 * "{imageDirectory}image2.jpg",</code> and <code>"{imageDirectory}image3.jpg"</code>
		 * and you'd like to replace <code>{imageDirectory}</code> with <code>http://www.greensock.com/images/</code>
		 * you'd do:<br /><br /><code>
		 * 
		 * myLoaderMax.replaceURLText("{imageDirectory}", "http://www.greensock.com/images/", false);<br /><br /></code>
		 * 
		 * Now the ImageLoader urls would be "http://www.greensock.com/images/image1.jpg", "http://www.greensock.com/images/image2.jpg",
		 * and "http://www.greensock.com/images/image3.jpg" respectively. <br /><br />
		 * 
		 * <code>replaceURLText()</code> permanently affects each child loader's <code>url</code> meaning that
		 * <code>LoaderMax.getContent("image1.jpg")</code> would not find the loader whose <code>url</code>
		 * is now "http://www.greensock.com/images/image1.jpg" (although you could simply use its <code>name</code> 
		 * instead of its <code>url</code> to find it). It also means that if a single loader has been
		 * inserted into multiple LoaderMax instances, its <code>url</code> change affects them all. <br /><br />
		 * 
		 * <code>replaceURLText()</code> only affects loaders that are children of the LoaderMax when 
		 * the method is called - it does <strong>not</strong> affect loaders that are inserted later. <br /><br />
		 * 
		 * <code>replaceURLText()</code> <strong>does</strong> affect <code>alternateURL</code> values for child loaders. 
		 * 
		 * @param fromText The old String that should be replaced in each child loader.
		 * @param toText The new String that should replace the <code>fromText</code>.
		 * @param includeNested If <code>true</code>, loaders nested inside child LoaderMax instances will also be affected. It is <code>false</code> by default.
		 * @see #prependURLs()
		 */
		public function replaceURLText(fromText:String, toText:String, includeNested:Boolean=false):void {
			var loaders:Array = getChildren(includeNested, true);
			var loader:LoaderItem;
			var i:int = loaders.length;
			while (--i > -1) {
				loader = loaders[i];
				loader.url = loader.url.split(fromText).join(toText);
				if ("alternateURL" in loader.vars) {
					loader.vars.alternateURL = loader.vars.alternateURL.split(fromText).join(toText);
				}
			}
		}
		
		/**
		 * Finds a loader based on its name or url. For example:<br /><br /><code>
		 * 
		 * var loader:ImageLoader = queue.getLoader("myPhoto1");<br /><br /></code>
		 * 
		 * Feel free to use the static <code>LoaderMax.getLoader()</code> method instead of the instance-based <code>getLoader()</code>
		 * method because the static one will search ALL loaders (the only exception being loaders in a different security
		 * sandbox, like in subloaded swfs from a different domain that didn't have a crossdomain.xml file in place granting permission). 
		 * 
		 * @param nameOrURL The name or url associated with the loader that should be found.
		 * @return The loader associated with the name or url.
		 * @see #getContent()
		 * @see #getChildren()
		 * @see #getChildrenByStatus()
		 */
		public function getLoader(nameOrURL:String):* {
			var i:int = _loaders.length;
			var loader:LoaderCore;
			while (--i > -1) {
				loader = _loaders[i];
				if (loader.name == nameOrURL || (loader is LoaderItem && (loader as LoaderItem).url == nameOrURL)) {
					return loader;
				} else if (loader.hasOwnProperty("getLoader")) {
					loader = (loader as Object).getLoader(nameOrURL) as LoaderCore;
					if (loader != null) {
						return loader;
					}
				}
			}
			return null;
		}
		
		/**
		 * Finds the content of a loader based on its name or url. For example:<br /><br /><code>
		 * 
		 * var image:Bitmap = queue.getContent("myPhoto1");<br /><br /></code>
		 * 
		 * Feel free to use the static <code>LoaderMax.getContent()</code> method instead of the instance-based <code>getContent()</code>
		 * method because the static one will search ALL loaders (the only exception being loaders in a different security
		 * sandbox, like in subloaded swfs from a different domain that didn't have a crossdomain.xml file in place granting permission). 
		 * 
		 * @param nameOrURL The name or url associated with the loader whose content should be found.
		 * @return The content that was loaded by the loader which varies by the type of loader:
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
		 * @see #getLoader()
		 * @see #content
		 */
		public function getContent(nameOrURL:String):* {
			var loader:LoaderCore = this.getLoader(nameOrURL);
			return (loader != null) ? loader.content : null;
		}
		
		/**
		 * Finds the index position of a particular loader in the LoaderMax. Index values are always zero-based,
		 * meaning the first position is 0, the second is 1, the third is 2, etc.
		 * 
		 * @param loader The loader whose index position should be returned
		 * @return The index position of the loader
		 * @see #getChildren()
		 * @see #getChildrenByStatus()
		 */
		public function getChildIndex(loader:LoaderCore):uint {
			var i:int = _loaders.length;
			while (--i > -1) {
				if (_loaders[i] == loader) {
					return i;
				}
			}
			return 999999999;
		}
		
		/** @inheritDoc **/
		override public function auditSize():void {
			if (!this.auditedSize) {
				_auditSize(null);
			}
		}
		
		/** @private **/
		protected function _auditSize(event:Event=null):void {
			if (event != null) {
				event.target.removeEventListener("auditedSize", _auditSize);
				event.target.removeEventListener(LoaderEvent.FAIL, _auditSize);
			}
			var l:uint = _loaders.length;
			var maxStatus:int = (this.skipPaused) ? LoaderStatus.COMPLETED : LoaderStatus.PAUSED;
			var loader:LoaderCore, found:Boolean;
			for (var i:int = 0; i < l; i++) {
				loader = _loaders[i];
				if (!loader.auditedSize && loader.status <= maxStatus) {
					if (!found) {
						loader.addEventListener("auditedSize", _auditSize, false, -100, true);
						loader.addEventListener(LoaderEvent.FAIL, _auditSize, false, -100, true);
					}
					found = true;
					loader.auditSize();
				}
			}
			if (!found) {
				if (_status == LoaderStatus.LOADING) {
					_loadNext(null);
				}
				dispatchEvent(new Event("auditedSize"));
			}
		}
		
		
//---- EVENT HANDLERS ------------------------------------------------------------------------------------
		
		/** @private **/
		protected function _loadNext(event:Event=null):void {
			if (event != null && _activeLoaders != null) {
				delete _activeLoaders[event.target];
				_removeLoaderListeners(LoaderCore(event.target), false);
			}
			
			if (_status == LoaderStatus.LOADING) {
				
				var audit:Boolean = ("auditSize" in this.vars) ? Boolean(this.vars.auditSize) : LoaderMax.defaultAuditSize;
				if (audit && !this.auditedSize) {
					_auditSize(null);
					return;
				}
				
				var loader:LoaderCore, loaders:Array = _loaders.concat(), l:int = loaders.length, activeCount:uint = 0; //use _loaders.concat() because in some rare situations, a loader's COMPLETE event might occur immediately and if autoDispose is true, the length of the array could change mid-loop causing a skip.
				_calculateProgress();
				for (var i:int = 0; i < l; i++) {
					loader = loaders[i];
					if (!this.skipPaused && loader.status == LoaderStatus.PAUSED) {
						super._failHandler(new LoaderEvent(LoaderEvent.FAIL, this, "Did not complete LoaderMax because skipPaused was false and " + loader.toString() + " was paused."), false);
						return;
						
					} else if (!this.skipFailed && loader.status == LoaderStatus.FAILED) {
						super._failHandler(new LoaderEvent(LoaderEvent.FAIL, this, "Did not complete LoaderMax because skipFailed was false and " + loader.toString() + " failed."), false);
						return;
						
					} else if (loader.status <= LoaderStatus.LOADING) {
						activeCount++;
						if (!(loader in _activeLoaders)) {
							_activeLoaders[loader] = true;
							loader.addEventListener(LoaderEvent.COMPLETE, _loadNext, false, -100, true);
							loader.addEventListener(LoaderEvent.CANCEL, _loadNext, false, -100, true);
							loader.load(false);
						}
						if (activeCount == this.maxConnections) {
							break;
						}
					}
				}
				if (activeCount == 0 && _cachedBytesLoaded == _cachedBytesTotal) {
					_completeHandler(null);
				}
			}
		}
		
		/** @private **/
		override protected function _progressHandler(event:Event):void {
			if (_dispatchChildProgress && event != null) {
				dispatchEvent(new LoaderEvent(LoaderEvent.CHILD_PROGRESS, event.target));
			}
			if (_dispatchProgress && _status != LoaderStatus.DISPOSED) {
				var bl:uint = _cachedBytesLoaded;
				var bt:uint = _cachedBytesTotal;
				_calculateProgress();
				if (bl == 0 && _cachedBytesLoaded == 0) {
					//do nothing
				} else if ((_cachedBytesLoaded != _cachedBytesTotal || _status != LoaderStatus.LOADING) && (bl != _cachedBytesLoaded || bt != _cachedBytesTotal)) { //note: added _status != LoaderStatus.LOADING because it's possible for all the children to load independently (without the LoaderMax actively loading), so in those cases, the progress would never reach 1 since LoaderMax's _completeHandler() won't be called to dispatch the final PROGRESS event.
					dispatchEvent(new LoaderEvent(LoaderEvent.PROGRESS, this));
				}
			} else {
				_cacheIsDirty = true;
			}
		}
		
		/** @private **/
		protected function _disposeHandler(event:Event):void {
			_removeLoader(LoaderCore(event.target), false);
		}
		
		/** @private **/
		protected function _prioritizeHandler(event:Event):void {
			var loader:LoaderCore = event.target as LoaderCore;
			_loaders.splice(getChildIndex(loader), 1);
			_loaders.unshift(loader);
			if (_status == LoaderStatus.LOADING && loader.status <= LoaderStatus.LOADING && !(loader in _activeLoaders)) {
				_cancelActiveLoaders();
				var prevMaxConnections:uint = this.maxConnections;
				this.maxConnections = 1;
				_loadNext(null);
				this.maxConnections = prevMaxConnections;
			}
		}
		
		
//---- STATIC METHODS ----------------------------------------------------------------------------
		
		/**
		 * Activates particular loader classes (like ImageLoader, SWFLoader, etc.) so that they can be 
		 * recognized inside the <code>parse()</code> method and XMLLoader. For example, if <code>LoaderMax.parse("image.jpg")</code>
		 * is called without first activating ImageLoader (like <code>LoaderMax.activate([ImageLoader])</code>),
		 * it wouldn't properly recognize the ".jpg" extension and return the necessary ImageLoader instance. Likewise,
		 * without activating ImageLoader first, XMLLoader wouldn't be able to recognize <code>&lt;ImageLoader&gt;</code>
		 * nodes nested inside an XML file. You only need to activate() the loader classes once in your swf. 
		 * For example:<br /><br /><code>
		 * 
		 * LoaderMax.activate([ImageLoader, SWFLoader, MP3Loader, DataLoader, CSSLoader]);</code><br /><br />
		 * 
		 * The reason all loaders aren't activated by default is to conserve file size. <br /><br />
		 * 
		 * @param loaderClasses An array of loader classes, like <code>[ImageLoader, SWFLoader, MP3Loader]</code>.
		 */
		public static function activate(loaderClasses:Array):void {
			//no need to do anything - we just want to force the classes to get compiled in the swf. Each one calls the _activateClass() method in LoaderCore on its own.
		}
		
		/**
		 * By default, LoaderMax associates certain file extensions with certain types of loaders, like "jpg", "png", and "gif"
		 * are associated with ImageLoader and "swf" is associated with SWFLoader so that the <code>LoaderMax.parse()</code> method
		 * can recognize and create the appropriate loaders for each URL passed in. If you'd like to associate additional file 
		 * extensions with certain loader types, you may do so with <code>registerFileType()</code>. For example, to associate
		 * "pdf" with BinaryDataLoader, you would do this:<br /><br /><code>
		 * 
		 * LoaderMax.registerFileType("pdf", BinaryDataLoader);<br /><br /></code>
		 * 
		 * Then, if you call <code>LoaderMax.parse("file/myFile.pdf")</code>, it would recognize the "pdf" file extension
		 * as being associated with BinaryDataLoader and would return a BinaryDataLoader instance accordingly. <br /><br />
		 * 
		 * There is no reason to use <code>registerFileType()</code> unless you plan on utilizing the <code>parse()</code> 
		 * method and need it to recognize a extensions that LoaderMax doesn't already recognize by default. 
		 * 
		 * <b>NOTE:</b> Make sure you activate() the various loader types you want LoaderMax to recognize before calling parse() - see the documentation for <code>LoaderMax.activate()</code>)
		 * 
		 * @param extensions The extension (or comma-delimited list of extensions) that should be associated with the loader class, like <code>"zip"</code> or <code>"zip,pdf"</code>. Do not include the dot in the extension.
		 * @param loaderClass The loader class that should be associated with the extension(s), like <code>BinaryDataLoader</code>.
		 * @see #activate() 
		 */
		public static function registerFileType(extensions:String, loaderClass:Class):void {
			_activateClass("", loaderClass, extensions);
		}
		
		/**
		 * Searches <strong>ALL</strong> loaders to find one based on its name or url. For example:<br /><br /><code>
		 * 
		 * var loader:ImageLoader = LoaderMax.getLoader("myPhoto1") as ImageLoader;<br /><br /></code>
		 * 
		 * @param nameOrURL The name or url associated with the loader that should be found.
		 * @return The loader associated with the name or url.
		 */
		public static function getLoader(nameOrURL:String):* {
			return (_globalRootLoader != null) ? _globalRootLoader.getLoader(nameOrURL) : null;
		}
		
		/**
		 * Searches <strong>ALL</strong> loaders to find content based on its name or url. For example:<br /><br /><code>
		 * 
		 * var image:Bitmap = LoaderMax.getContent("myPhoto1");<br /><br /></code>
		 * 
		 * @param nameOrURL The name or url associated with the loader whose content should be found.
		 * @return The content that was loaded by the loader which varies by the type of loader:
		 * <ul>
		 * 		<li><strong> ImageLoader </strong> - A <code>com.greensock.loading.display.ContentDisplay</code> (a Sprite) which contains the ImageLoader's <code>rawContent</code> (a <code>flash.display.Bitmap</code> unless script access was denied in which case <code>rawContent</code> will be a <code>flash.display.Loader</code> to avoid security errors).</li>
		 * 		<li><strong> SWFLoader </strong> - A <code>com.greensock.loading.display.ContentDisplay</code> (a Sprite) which contains the SWFLoader's <code>rawContent</code> (the swf's <code>root</code> DisplayObject unless script access was denied in which case <code>rawContent</code> will be a <code>flash.display.Loader</code> to avoid security errors).</li>
		 * 		<li><strong> VideoLoader </strong> - A <code>com.greensock.loading.display.ContentDisplay</code> (a Sprite) which contains the VideoLoader's <code>rawContent</code> (a Video object to which the NetStream was attached).</li>
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
		 */
		public static function getContent(nameOrURL:String):* {
			return (_globalRootLoader != null) ? _globalRootLoader.getContent(nameOrURL) : null;
		}
		
		/**
		 * Immediately prioritizes a loader inside any LoaderMax instances that contain it,
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
		 * For example, to immediately prioritize the loader named "myPhoto1":<br /><br /><code>
		 * 
		 * LoaderMax.prioritize("myPhoto1");</code>
		 * 
		 * @param nameOrURL The name or url associated with the loader that should be prioritized
		 * @param loadNow If <code>true</code> (the default), the loader will start loading immediately (otherwise it is simply placed at the top the queue in any LoaderMax instances to which it belongs).
		 * @return The loader that was prioritized. If no loader was found, <code>null</code> is returned.
		 */
		public static function prioritize(nameOrURL:String, loadNow:Boolean=true):LoaderCore {
			var loader:LoaderCore = getLoader(nameOrURL);
			if (loader != null) {
				loader.prioritize(loadNow);
			}
			return loader;
		}
		
		
//---- GETTERS / SETTERS -------------------------------------------------------------------------
		
		/** Number of child loaders currently contained in the LoaderMax instance (does not include deeply nested loaders - only children). To get the quantity of all children including nested ones, use <code>getChildren(true, true).length</code> @see #getChildren() **/
		public function get numChildren():uint {
			return _loaders.length;
		}
		
		/** An array containing the content of each loader inside the LoaderMax **/
		override public function get content():* {
			var a:Array = [];
			var i:int = _loaders.length;
			while (--i > -1) {
				a[i] = LoaderCore(_loaders[i]).content;
			}
			return a;
		}
		
		/** @inheritDoc **/
		override public function get status():int {
			//if the status of children changed after the LoaderMax completed, we need to make adjustments to the LoaderMax's status.
			if (_status == LoaderStatus.COMPLETED) {
				var statusCounts:Array = [0, 0, 0, 0, 0, 0]; //store the counts of each type of status (index 0 is for READY, 1 is LOADING, 2 is COMPLETE, etc.
				var i:int = _loaders.length;
				while (--i > -1) {
					statusCounts[LoaderCore(_loaders[i]).status]++;
				}
				if ((!this.skipFailed && statusCounts[4] != 0) || (!this.skipPaused && statusCounts[3] != 0)) {
					_status = LoaderStatus.FAILED;
				} else if (statusCounts[0] + statusCounts[1] != 0) {
					_status = LoaderStatus.READY;
					_cacheIsDirty = true;
				}
			}
			return _status;
		}
		
		/** @inheritDoc **/
		override public function get auditedSize():Boolean {
			var maxStatus:int = (this.skipPaused) ? LoaderStatus.COMPLETED : LoaderStatus.PAUSED;
			var i:int = _loaders.length;
			while (--i > -1) {
				if (!LoaderCore(_loaders[i]).auditedSize && LoaderCore(_loaders[i]).status <= maxStatus) {
					return false;
				}
			}
			return true;
		}
		
		/** 
		 * An unweighted value between 0 and 1 indicating the overall loading progress of the LoaderMax - this calculation does not concern 
		 * itself whatsoever with <code>bytesLoaded</code> and <code>bytesTotal</code> but rather the ratio of the children that are loaded
		 * (all having equal weight). Therefore, <code>rawProgress</code> is a more crude way of measuring the overall loading progress and 
		 * isn't weighted in terms of file size the way that <code>progress</code> is. The only benefit of using <code>rawProgress</code> instead 
		 * of <code>progress</code> is that there is never a risk of the value moving backwards the way it can with <code>progress</code> 
		 * when child loaders have inaccurately low estimatedByte values (before LoaderMax audits the file size values). The rate at which
		 * <code>rawProgress</code> increases may slow down or speed up depending on the file size of the asset currently loading. For example,
		 * if a LoaderMax contains two loaders, the first for a file that's 100k and the second for a file that's 10,000k, <code>rawProgress</code>
		 * will move quickly (while loading the 100k file) until it reaches 0.5 and then slow down significantly (while loading the 10,000k file) 
		 * until it reaches 1. <br /><br />
		 * 
		 * Or let's say you have a LoaderMax that contains 3 ImageLoaders: the first two must load images that are 25k each and the 
		 * 3rd one must load an image that's 450k. After the first two ImageLoaders finish, the LoaderMax's <code>progress</code> property would 
		 * report 0.1 (50k loaded out of 500k total) whereas the <code>rawProgress</code> would report 0.66 (2 loaders out of 3 total have completed). 
		 * However, if you set the <code>estimatedBytes</code> of all of the ImageLoaders in this example to 25600 (25k) and set the LoaderMax's 
		 * <code>auditSize</code> to <code>false</code>, the <code>progress</code> would read about 0.66 after the first two ImageLoaders complete
		 * (it still thinks they're all 25k) and then when the 3rd one starts loading and LoaderMax finds out that it's 450k, the <code>bytesTotal</code> 
		 * would automatically adjust and the <code>progress</code> would jump backwards to 0.1 (which correctly reflects the weighted progress). 
		 * Of course a solution would be to more accurately set the <code>estimatedBytes</code> and/or leave <code>auditSize true</code> in the 
		 * LoaderMax, but <code>rawProgress</code> can be useful if those solutions are undesirable in your scenario and you need to avoid any
		 * backwards adjustment of a preloader progress bar or some other interface element.<br /><br />
		 * 
		 * @see #progress
		 **/
		public function get rawProgress():Number {
			var loaded:Number = 0;
			var total:uint = 0;
			var status:int;
			var i:int = _loaders.length;
			while (--i > -1) {
				status = LoaderCore(_loaders[i]).status;
				if (status != LoaderStatus.DISPOSED && !(status == LoaderStatus.PAUSED && this.skipPaused) && !(status == LoaderStatus.FAILED && this.skipFailed)) {
					total++;
					loaded += (_loaders[i] is LoaderMax) ? LoaderMax(_loaders[i]).rawProgress : LoaderCore(_loaders[i]).progress;
				}
			}
			return (total == 0) ? 0 : loaded / total;
		}
		
	}
}
