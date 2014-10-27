/**
 * VERSION: 1.891
 * DATE: 2011-11-03
 * AS3
 * UPDATES AND DOCS AT: http://www.greensock.com/loadermax/
 **/
package com.greensock.loading {
	import com.greensock.events.LoaderEvent;
	import com.greensock.loading.core.LoaderCore;
	
	import flash.events.Event;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.system.SecurityDomain;
	import flash.utils.getTimer;
	
	/** Dispatched when the XML finishes loading and its contents are parsed (creating any dynamic XML-driven loader instances necessary). If any dynamic loaders are created and have a <code>load="true"</code> attribute, they will begin loading at this point and the XMLLoader's <code>COMPLETE</code> will not be dispatched until the loaders have completed as well. **/
	[Event(name="init", 				type="com.greensock.events.LoaderEvent")]
	/** Dispatched when any loader that the XMLLoader discovered in the XML dispatches an OPEN event. **/
	[Event(name="childOpen", 			type="com.greensock.events.LoaderEvent")]
	/** Dispatched when any loader that the XMLLoader discovered in the XML dispatches a PROGRESS event. **/
	[Event(name="childProgress", 		type="com.greensock.events.LoaderEvent")]
	/** Dispatched when any loader that the XMLLoader discovered in the XML dispatches a COMPLETE event. **/
	[Event(name="childComplete", 		type="com.greensock.events.LoaderEvent")]
	/** Dispatched when any loader that the XMLLoader discovered in the XML dispatches a FAIL event. **/
	[Event(name="childFail", 			type="com.greensock.events.LoaderEvent")]
	/** Dispatched when any loader that the XMLLoader discovered in the XML dispatches a CANCEL event. **/
	[Event(name="childCancel", 			type="com.greensock.events.LoaderEvent")]
	/** Dispatched when any loader that the XMLLoader discovered in the XML dispatches a SCRIPT_ACCESS_DENIED event. **/
	[Event(name="scriptAccessDenied", 	type="com.greensock.events.LoaderEvent")]
	/** Dispatched when the loader's <code>httpStatus</code> value changes. **/
	[Event(name="httpStatus", 			type="com.greensock.events.LoaderEvent")]
	/** Dispatched when the loader experiences a SECURITY_ERROR which can occur when the XML file is loaded from another domain and there is no crossdomain.xml file in place granting appropriate access. **/
	[Event(name="securityError", 		type="com.greensock.events.LoaderEvent")]
/**
 * Loads an XML file and automatically searches it for LoaderMax-related nodes like <code>&lt;LoaderMax&gt;,
 * &lt;ImageLoader&gt;, &lt;SWFLoader&gt;, &lt;XMLLoader&gt;, &lt;DataLoader&gt; &lt;CSSLoader&gt;, &lt;MP3Loader&gt;</code>, 
 * etc.; if it finds any, it will create the necessary instances and begin loading them if they have a <code>load="true"</code>
 * attribute. The XMLLoader's <code>progress</code> will automatically factor in the dynamically-created 
 * loaders that have the <code>load="true"</code> attribute and it won't dispatch its <code>COMPLETE</code> event 
 * until those loaders have completed as well (unless <code>integrateProgress:false</code> is passed to the constructor). 
 * For example, let's say the XML file contains the following XML:
 * 
 * @example Example XML code:<listing version="3.0">
&lt;?xml version="1.0" encoding="iso-8859-1"?&gt; 
&lt;data&gt;
 		&lt;widget name="myWidget1" id="10"&gt;
				&lt;ImageLoader name="widget1" url="img/widget1.jpg" estimatedBytes="2000" /&gt;
		&lt;/widget&gt;
 		&lt;widget name="myWidget2" id="23"&gt;
				&lt;ImageLoader name="widget2" url="img/widget2.jpg" estimatedBytes="2800" load="true" /&gt;
		&lt;/widget&gt;
 		&lt;LoaderMax name="dynamicLoaderMax" load="true" prependURLs="http://www.greensock.com/"&gt;
 				&lt;ImageLoader name="photo1" url="img/photo1.jpg" /&gt;
 				&lt;ImageLoader name="logo" url="img/corporate_logo.png" estimatedBytes="2500" /&gt;
 				&lt;SWFLoader name="mainSWF" url="swf/main.swf" autoPlay="false" estimatedBytes="15000" /&gt;
 				&lt;MP3Loader name="audio" url="mp3/intro.mp3" autoPlay="true" loops="100" /&gt;
 		&lt;/LoaderMax&gt;
&lt;/data&gt;
 </listing>
 * 
 * Once the XML has been loaded and parsed, the XMLLoader will recognize the 7 LoaderMax-related nodes
 * (assuming you activated the various types of loaders - see the <code>activate()</code> method for details) 
 * and it will create instances dynamically. Then it will start loading the ones that had a <code>load="true"</code> 
 * attribute which in this case means all but the first loader will be loaded in the order they were defined in the XML. 
 * Notice the loaders nested inside the <code>&lt;LoaderMax&gt;</code> don't have <code>load="true"</code> but 
 * they will be loaded anyway because their parent LoaderMax has the <code>load="true"</code> attribute. 
 * After the XMLLoader's <code>INIT</code> event is dispatched, you can get any loader by name or URL with the 
 * <code>LoaderMax.getLoader()</code> method and monitor its progress or control it as you please. 
 * And after the XMLLoader's <code>COMPLETE</code> event is dispatched, you can use <code>LoaderMax.getContent()</code> 
 * to get content based on the name or URL of any of the loaders that had <code>load="true"</code> defined
 * in the XML. For example:
 * 
 * @example Example AS3 code:<listing version="3.0">
var loader:XMLLoader = new XMLLoader("xml/doc.xml", {name:"xmlDoc", onComplete:completeHandler});

function completeHandler(event:LoaderEvent):void {
 
		//get the content from the "photo1" ImageLoader that was defined inside the XML
		var photo:ContentDisplay = LoaderMax.getContent("photo1");
		
		//add it to the display list 
		addChild(photo);
		
		//fade it in
		TweenLite.from(photo, 1, {alpha:0});
}
</listing>
 * 
 * You do <strong>not</strong> need to put loader-related nodes in your XML files. It is a convenience that is completely 
 * optional. XMLLoader does a great job of loading plain XML data even without the fancy automatic parsing of 
 * loader data. <br /><br />
 * 
 * You may put extra data in the LoaderMax-related nodes that you'd like associated with that particular
 * loader. XMLLoader will put all of the attributes from the XML node into the <code>vars</code> object of 
 * the resulting loader as well as an extra <code>rawXML</code> property which will contain the raw XML 
 * for that node. For example, if this node is in your XML document: <br /><listing version="3.0">
...
&lt;VideoLoader url="video.flv" name="video1" description="Hidden dangers of steel wool" autoPlay="false"&gt;
	&lt;links&gt;
		&lt;link url="http://www.greensock.com" title="GreenSock" /&gt;
		&lt;link url="http://www.google.com" title="Google" /&gt;
	&lt;/links&gt;
&lt;/VideoLoader&gt;
...
</listing>
 * 
 * Notice the "description" attribute which isn't a LoaderMax-specific property. XMLLoader will still
 * put that value into the VideoLoader's <code>vars</code> property and create a <code>rawXML</code>
 * property there that contains the whole XML node (including the children) so that you can easily get
 * whatever data you need like this: <br />
 * <listing version="3.0">
function completeHandler(event:LoaderEvent):void {
	var video:VideoLoader = LoaderMax.getLoader("video1");
	var description:String = video.vars.description;
	var xml:XML = video.vars.rawXML;
	trace("first link url: " + xml.links[0].link[0].&#64;url); //traces "first link url: http://www.greensock.com"
}
</listing>
 * 
 * <strong>OPTIONAL VARS PROPERTIES</strong><br />
 * The following special properties can be passed into the XMLLoader constructor via its <code>vars</code> 
 * parameter which can be either a generic object or an <code><a href="data/XMLLoaderVars.html">XMLLoaderVars</a></code> object:<br />
 * <ul>
 * 		<li><strong> name : String</strong> - A name that is used to identify the XMLLoader instance. This name can be fed to the <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> methods or traced at any time. Each loader's name should be unique. If you don't define one, a unique name will be created automatically, like "loader21".</li>
 * 		<li><strong> integrateProgress : Boolean</strong> - By default, the XMLLoader will automatically look for LoaderMax-related nodes like <code>&lt;LoaderMax&gt;, &lt;ImageLoader&gt;, &lt;SWFLoader&gt;, &lt;XMLLoader&gt;, &lt;MP3Loader&gt;, &lt;DataLoader&gt;</code>, and <code>&lt;CSSLoader&gt;</code> inside the XML when it inits. If it finds any that have a <code>load="true"</code> attribute, it will begin loading them and integrate their progress into the XMLLoader's overall progress. Its <code>COMPLETE</code> event won't fire until all of these loaders have completed as well. If you prefer NOT to integrate the dynamically-created loader instances into the XMLLoader's overall <code>progress</code>, set <code>integrateProgress</code> to <code>false</code>.</li>
 * 		<li><strong> alternateURL : String</strong> - If you define an <code>alternateURL</code>, the loader will initially try to load from its original <code>url</code> and if it fails, it will automatically (and permanently) change the loader's <code>url</code> to the <code>alternateURL</code> and try again. Think of it as a fallback or backup <code>url</code>. It is perfectly acceptable to use the same <code>alternateURL</code> for multiple loaders (maybe a default image for various ImageLoaders for example).</li>
 * 		<li><strong> noCache : Boolean</strong> - If <code>noCache</code> is <code>true</code>, a "gsCacheBusterID" parameter will be appended to the url with a random set of numbers to prevent caching (don't worry, this info is ignored when you <code>getLoader()</code> or <code>getContent()</code> by url and when you're running locally)</li>
 * 		<li><strong> estimatedBytes : uint</strong> - Initially, the loader's <code>bytesTotal</code> is set to the <code>estimatedBytes</code> value (or <code>LoaderMax.defaultEstimatedBytes</code> if one isn't defined). Then, when the XML has been loaded and analyzed enough to determine the size of any dynamic loaders that were found in the XML data (like &lt;ImageLoader&gt; nodes, etc.), it will adjust the <code>bytesTotal</code> accordingly. Setting <code>estimatedBytes</code> is optional, but it provides a way to avoid situations where the <code>progress</code> and <code>bytesTotal</code> values jump around as XMLLoader recognizes nested loaders in the XML and audits their size. The <code>estimatedBytes</code> value should include all nested loaders as well, so if your XML file itself is 500 bytes and you have 3 &lt;ImageLoader&gt; tags with <code>load="true"</code> and each image is about 2000 bytes, your XMLLoader's <code>estimatedBytes</code> should be 6500. The more accurate the value, the more accurate the loaders' overall progress will be.</li>
 * 		<li><strong> requireWithRoot : DisplayObject</strong> - LoaderMax supports <i>subloading</i>, where an object can be factored into a parent's loading progress. If you want LoaderMax to require this XMLLoader as part of its parent SWFLoader's progress, you must set the <code>requireWithRoot</code> property to your swf's <code>root</code>. For example, <code>var loader:XMLLoader = new XMLLoader("data.xml", {name:"data", requireWithRoot:this.root});</code></li>
 * 		<li><strong> autoDispose : Boolean</strong> - When <code>autoDispose</code> is <code>true</code>, the loader will be disposed immediately after it completes (it calls the <code>dispose()</code> method internally after dispatching its <code>COMPLETE</code> event). This will remove any listeners that were defined in the vars object (like onComplete, onProgress, onError, onInit). Once a loader is disposed, it can no longer be found with <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> - it is essentially destroyed but its content is not unloaded (you must call <code>unload()</code> or <code>dispose(true)</code> to unload its content). The default <code>autoDispose</code> value is <code>false</code>.</li>
 * 		<li><strong> prependURLs : String</strong> - A String that should be prepended to all parsed LoaderMax-related loader URLs (from nodes like &lt;ImageLoader&gt;, &lt;XMLLoader&gt;, etc.) as soon as the XML has been parsed. For example, if your XML has the following node: <code>&lt;ImageLoader url="1.jpg" /&gt;</code> and <code>prependURLs</code> is set to "../images/", then the ImageLoader's url will end up being "../images/1.jpg". <code>prependURLs</code> affects ALL parsed loaders in the XML. However, if you have an <code>&lt;XMLLoader&gt;</code> node inside your XML that also loads another XML doc and you'd like to recursively prepend all of the URLs in this loader's XML as well as the subloading one and all of its children, use <code>recursivePrependURLs</code> instead of <code>prependURLs</code>.</li>
 * 		<li><strong> maxConnections : uint</strong> - Maximum number of simultaneous connections that should be used while loading child loaders that were parsed from the XML and had their "load" attribute set to "true" (like &lt;ImageLoader url="1.jpg" load="true" /&gt;). A higher number will generally result in faster overall load times for the group. The default is 2. Sometimes there are limits imposed by the Flash Player itself or the browser or the user's system, but LoaderMax will do its best to honor the <code>maxConnections</code> you define.</li>
 * 		<li><strong> allowMalformedURL : Boolean</strong> - Normally, the URL will be parsed and any variables in the query string (like "?name=test&amp;state=il&amp;gender=m") will be placed into a URLVariables object which is added to the URLRequest. This avoids a few bugs in Flash, but if you need to keep the entire URL intact (no parsing into URLVariables), set <code>allowMalformedURL:true</code>. For example, if your URL has duplicate variables in the query string like <code>http://www.greensock.com/?c=S&amp;c=SE&amp;c=SW</code>, it is technically considered a malformed URL and a URLVariables object can't properly contain all the duplicates, so in this case you'd want to set <code>allowMalformedURL</code> to <code>true</code>.</li>
 * 		<li><strong> skipFailed : Boolean</strong> - By default, XMLLoader will parse any LoaderMax-related loaders in the XML and load any that have their "load" attribute set to "true" and then if any fail to load, they will simply be skipped. But if you prefer to have the XMLLoader fail immediately if one of the parsed loaders fails to load, set <code>skipFailed</code> to <code>false</code> (it is <code>true</code> by default).</li>
 * 		<li><strong> recursivePrependURLs : String</strong> - A String that should be recursively prepended to all parsed LoaderMax-related loader URLs (from nodes like &lt;ImageLoader&gt;, &lt;XMLLoader&gt;, etc.). The functionality is identical to <code>prependURLs</code> except that it is recursive, affecting all parsed loaders in subloaded XMLLoaders (other XML files that this one loads too). For example, if your XML has the following node: <code>&lt;XMLLoader url="doc2.xml" /&gt;</code> and <code>recursivePrependURLs</code> is set to "../xml/", then the nested XMLLoader's URL will end up being "../xml/doc2.xml". Since it is recursive, parsed loaders inside doc2.xml <i>and</i> any other XML files that it loads will <i>all</i> have their URLs prepended. So if you load doc1.xml which loads doc2.xml which loads doc3.xml (due to <code>&lt;XMLLoader&gt;</code> nodes discovered in each XML file), <code>recursivePrependURLs</code> will affect all of the parsed LoaderMax-related URLs in all 3 documents. If you'd prefer to <i>only</i> have the URLs affected that are in the XML file that this XMLLoader is loading, use <code>prependURLs</code> instead of <code>recursivePrependURLs</code>.
 * 
 * 		<br /><br />----EVENT HANDLER SHORTCUTS----</li>
 * 		<li><strong> onOpen : Function</strong> - A handler function for <code>LoaderEvent.OPEN</code> events which are dispatched when the loader begins loading. Make sure your onOpen function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onRawLoad : Function</strong> - A handler function for <code>XMLLoader.RAW_LOAD</code> events which are dispatched when the loader finishes loading the XML but has <b>NOT</b> parsed the XML yet. This can be useful in rare situations when you want to alter the XML before it is parsed by XMLLoader (for identifying LoaderMax-related nodes like <code>&lt;ImageLoader&gt;</code>, etc.). Make sure your onRawLoad function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onInit : Function</strong> - A handler function for <code>LoaderEvent.INIT</code> events which are dispatched when the loader finishes loading the XML file, parses its contents, and creates any dynamic XML-driven loaders. If any dynamic loaders are created and have a <code>load="true"</code> attribute, they will begin loading at this point and the XMLLoader's <code>COMPLETE</code> will not be dispatched until the loaders have completed as well. Make sure your onInit function accepts a single parameter of type <code>Event</code> (flash.events.Event).</li>
 * 		<li><strong> onProgress : Function</strong> - A handler function for <code>LoaderEvent.PROGRESS</code> events which are dispatched whenever the <code>bytesLoaded</code> changes. Make sure your onProgress function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). You can use the LoaderEvent's <code>target.progress</code> to get the loader's progress value or use its <code>target.bytesLoaded</code> and <code>target.bytesTotal</code>.</li>
 * 		<li><strong> onComplete : Function</strong> - A handler function for <code>LoaderEvent.COMPLETE</code> events which are dispatched when the loader has finished loading successfully. Make sure your onComplete function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onCancel : Function</strong> - A handler function for <code>LoaderEvent.CANCEL</code> events which are dispatched when loading is aborted due to either a failure or because another loader was prioritized or <code>cancel()</code> was manually called. Make sure your onCancel function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onError : Function</strong> - A handler function for <code>LoaderEvent.ERROR</code> events which are dispatched whenever the loader experiences an error (typically an IO_ERROR or SECURITY_ERROR). An error doesn't necessarily mean the loader failed, however - to listen for when a loader fails, use the <code>onFail</code> special property. Make sure your onError function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onFail : Function</strong> - A handler function for <code>LoaderEvent.FAIL</code> events which are dispatched whenever the loader fails and its <code>status</code> changes to <code>LoaderStatus.FAILED</code>. Make sure your onFail function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onIOError : Function</strong> - A handler function for <code>LoaderEvent.IO_ERROR</code> events which will also call the onError handler, so you can use that as more of a catch-all whereas <code>onIOError</code> is specifically for LoaderEvent.IO_ERROR events. Make sure your onIOError function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onHTTPStatus : Function</strong> - A handler function for <code>LoaderEvent.HTTP_STATUS</code> events. Make sure your onHTTPStatus function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). You can determine the httpStatus code using the LoaderEvent's <code>target.httpStatus</code> (LoaderItems keep track of their <code>httpStatus</code> when possible, although certain environments prevent Flash from getting httpStatus information).</li>
 * 		<li><strong> onSecurityError : Function</strong> - A handler function for <code>LoaderEvent.SECURITY_ERROR</code> events which onError handles as well, so you can use that as more of a catch-all whereas onSecurityError is specifically for SECURITY_ERROR events. Make sure your onSecurityError function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onChildOpen : Function</strong> - A handler function for <code>LoaderEvent.CHILD_OPEN</code> events which are dispatched each time any nested LoaderMax-related loaders that were defined in the XML begins loading. Make sure your onChildOpen function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onChildProgress : Function</strong> - A handler function for <code>LoaderEvent.CHILD_PROGRESS</code> events which are dispatched each time any nested LoaderMax-related loaders that were defined in the XML dispatches a <code>PROGRESS</code> event. To listen for changes in the XMLLoader's overall progress, use the <code>onProgress</code> special property instead. You can use the LoaderEvent's <code>target.progress</code> to get the child loader's progress value or use its <code>target.bytesLoaded</code> and <code>target.bytesTotal</code>. The LoaderEvent's <code>currentTarget</code> refers to the XMLLoader, so you can check its overall progress with the LoaderEvent's <code>currentTarget.progress</code>. Make sure your onChildProgress function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onChildComplete : Function</strong> - A handler function for <code>LoaderEvent.CHILD_COMPLETE</code> events which are dispatched each time any nested LoaderMax-related loaders that were defined in the XML finishes loading successfully. Make sure your onChildComplete function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onChildCancel : Function</strong> - A handler function for <code>LoaderEvent.CHILD_CANCEL</code> events which are dispatched each time loading is aborted on any nested LoaderMax-related loaders that were defined in the XML due to either an error or because another loader was prioritized in the queue or because <code>cancel()</code> was manually called on the child loader. Make sure your onChildCancel function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onChildFail : Function</strong> - A handler function for <code>LoaderEvent.CHILD_FAIL</code> events which are dispatched each time any nested LoaderMax-related loaders that were defined in the XML fails (and its <code>status</code> chances to <code>LoaderStatus.FAILED</code>). Make sure your onChildFail function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * </ul><br />
 * 
 * <strong>Note:</strong> Using a <code><a href="data/XMLLoaderVars.html">XMLLoaderVars</a></code> instance 
 * instead of a generic object to define your <code>vars</code> is a bit more verbose but provides 
 * code hinting and improved debugging because it enforces strict data typing. Use whichever one you prefer.<br /><br />
 * 
 * <strong>Note:</strong> If you don't want the fancy auto-parsing capabilities of XMLLoader, you can just use a 
 * <a href="DataLoader.html">DataLoader </a> instead of XMLLoader. Then make the content into XML like: 
 * <code>var xml:XML = new XML(myDataLoader.content);</code><br /><br />
 * 
 * XMLLoader recognizes a few additional attributes for dynamically-created loaders that are defined in the XML:
 * <ul>
 * 		<li><strong>load="true | false"</strong> - If <code>load</code> is <code>"true"</code>, the loader will be loaded by the XMLLoader and its progress will be integrated with the XMLLoader's overall progress.</li>
 * 		<li><strong>prependURLs</strong> (&lt;LoaderMax&gt; and &lt;XMLLoader&gt; nodes only) - To prepend a certain String value to the beginning of all children of a &lt;LoaderMax&gt; or &lt;XMLLoader&gt;, use <code>prependURLs</code>. For example, <code>&lt;LoaderMax name="mainQueue" prependURLs="http://www.greensock.com/images/"&gt;&lt;ImageLoader url="image1.jpg" /&gt;&lt;/LoaderMax&gt;</code> would cause the ImageLoader's url to become "http://www.greensock.com/images/image1.jpg". </li>
 * 		<li><strong>replaceURLText</strong> (&lt;LoaderMax&gt; nodes only) - To replace certain substrings in all child loaders of a &lt;LoaderMax&gt; with other values, use <code>replaceURLText</code>. Separate the old value that should be replaced from the new one that should replace it with a comma (","). The list can be as long as you want. For example, <code>&lt;LoaderMax name="mainQueue" replaceURLText="{imageDirectory},http://www.greensock.com/images/,{language},_en"&gt;&lt;ImageLoader url="{imageDirectory}image1{language}.jpg" /&gt;&lt;/LoaderMax&gt;</code> would cause the ImageLoader's <code>url</code> to become "http://www.greensock.com/images/image1_en.jpg". </li>
 * 		<li><strong>childrenVars</strong> (&lt;LoaderMax&gt; nodes only) - To apply a common set of special properties to all the children of a particular &lt;LoaderMax&gt; node, use <code>childrenVars</code> and define a comma-delimited list of values like <code>&lt;LoaderMax name="mainQueue" childrenVars="width:200,height:100,scaleMode:proportionalOutside,crop:true"&gt;&lt;ImageLoader url="image1.jpg" /&gt;&lt;ImageLoader url="image2.jpg" /&gt;&lt;/LoaderMax&gt;</code>. Values that are defined directly in one of the child nodes will override any value(s) in the childrenVars, making things very flexible. So if you want the <code>width</code> of all of the children to be 200 except one which should be 500, just use <code>childrenVars="width:200"</code> and then in the child that should be 500 pixels wide, set that in the node like <code>&lt;ImageLoader url="1.jpg" width="500" /&gt;</code> (new in version 1.88)</li>
 * 		<li><strong>context="child | separate | own"</strong> - Only valid for <code>&lt;SWFLoader&gt;</code> loaders. It defines the LoaderContext's ApplicationDomain (see Adobe's <code>LoaderContext</code> docs for details). <code>"child"</code> is the default.</li>
 * </ul><br />
 * 
 * <code>content</code> data type: <strong><code>XML</code></strong><br /><br />
 * 
 * @example Example AS3 code:<listing version="3.0">
 import com.greensock.loading.~~;
 import com.greensock.loading.display.~~;
 import com.greensock.events.LoaderEvent;
 
 //we know the XML contains ImageLoader, SWFLoader, DataLoader, and MP3Loader data, so we need to activate those classes once in the swf so that the XMLLoader can recognize them.
 LoaderMax.activate([ImageLoader, SWFLoader, DataLoader, MP3Loader]);
 
 //create an XMLLoader
 var loader:XMLLoader = new XMLLoader("xml/doc.xml", {name:"xmlDoc", requireWithRoot:this.root, estimatedBytes:1400});
 
 //begin loading
 loader.load();
 
 //Or you could put the XMLLoader into a LoaderMax. Create one first...
 var queue:LoaderMax = new LoaderMax({name:"mainQueue", onProgress:progressHandler, onComplete:completeHandler, onError:errorHandler});
 
 //append the XMLLoader and several other loaders
 queue.append( loader );
 queue.append( new SWFLoader("swf/main.swf", {name:"mainSWF", estimatedBytes:4800}) );
 queue.append( new ImageLoader("img/photo1.jpg", {name:"photo1"}) );
 
 //begin loading queue
 queue.load();
 
 function progressHandler(event:LoaderEvent):void {
 	trace("progress: " + event.target.progress);
 }
 
 function completeHandler(event:LoaderEvent):void {
 	trace("load complete. XML content: " + LoaderMax.getContent("xmlDoc"));
	
	//Assuming there was an <ImageLoader name="image1" url="img/image1.jpg" load="true" /> node in the XML, get the associated image...
	var image:ContentDisplay = LoaderMax.getContent("image1");
	addChild(image);
 }
 
 function errorHandler(event:LoaderEvent):void {
 	trace("error occured with " + event.target + ": " + event.text);
 }
 </listing>
 * 
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @see com.greensock.loading.data.XMLLoaderVars
 * 
 * @author Jack Doyle, jack@greensock.com
 */	
	public class XMLLoader extends DataLoader {
		/** @private **/
		private static var _classActivated:Boolean = _activateClass("XMLLoader", XMLLoader, "xml,php,jsp,asp,cfm,cfml,aspx");
		/** @private Any non-String variable types that XMLLoader should recognized in loader nodes like <ImageLoader>, <VideoLoader>, etc. **/
		protected static var _varTypes:Object = {skipFailed:true, skipPaused:true, autoLoad:false, paused:false, load:false, noCache:false, maxConnections:2, autoPlay:false, autoDispose:false, smoothing:false, autoDetachNetStream:false, estimatedBytes:1, x:1, y:1, z:1, rotationX:1, rotationY:1, rotationZ:1, width:1, height:1, scaleX:1, scaleY:1, rotation:1, alpha:1, visible:true, bgColor:0, bgAlpha:0, deblocking:1, repeat:1, checkPolicyFile:false, centerRegistration:false, bufferTime:5, volume:1, bufferMode:false, estimatedDuration:200, crop:false, autoAdjustBuffer:true, suppressInitReparentEvents:true};
		/** Event type constant for when the XML has loaded but has <b>not</b> been parsed yet. This can be useful in rare situations when you want to alter the XML before it is parsed by XMLLoader (for identifying LoaderMax-related nodes like <code>&lt;ImageLoader&gt;</code>, etc.) **/
		public static var RAW_LOAD:String = "rawLoad";
		/** @private contains only the parsed loaders that had the load="true" XML attribute. It also contains the _parsed LoaderMax which is paused, so it won't load (we put it in there for easy searching). **/
		protected var _loadingQueue:LoaderMax;
		/** @private contains all the parsed loaders (<ImageLoader>, <SWFLoader>, <MP3Loader>, <XMLLoader>, etc.) but it is paused. Any loaders that have the load="true" XML attribute will be put into the _loadingQueue. _parsed is also put into the _loadingQueue for easy searching. **/
		protected var _parsed:LoaderMax;
		/** @private **/
		protected var _initted:Boolean;
		
		/**
		 * Constructor
		 * 
		 * @param urlOrRequest The url (<code>String</code>) or <code>URLRequest</code> from which the loader should get its content.
		 * @param vars An object containing optional configuration details. For example: <code>new XMLLoader("xml/data.xml", {name:"data", onComplete:completeHandler, onProgress:progressHandler})</code>.<br /><br />
		 * 
		 * The following special properties can be passed into the constructor via the <code>vars</code> parameter
		 * which can be either a generic object or an <code><a href="data/XMLLoaderVars.html">XMLLoaderVars</a></code> object:<br />
		 * <ul>
		 * 		<li><strong> name : String</strong> - A name that is used to identify the XMLLoader instance. This name can be fed to the <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> methods or traced at any time. Each loader's name should be unique. If you don't define one, a unique name will be created automatically, like "loader21".</li>
		 * 		<li><strong> integrateProgress : Boolean</strong> - By default, the XMLLoader will automatically look for LoaderMax-related nodes like <code>&lt;LoaderMax&gt;, &lt;ImageLoader&gt;, &lt;SWFLoader&gt;, &lt;XMLLoader&gt;, &lt;MP3Loader&gt;, &lt;DataLoader&gt;</code>, and <code>&lt;CSSLoader&gt;</code> inside the XML when it inits. If it finds any that have a <code>load="true"</code> attribute, it will begin loading them and integrate their progress into the XMLLoader's overall progress. Its <code>COMPLETE</code> event won't fire until all of these loaders have completed as well. If you prefer NOT to integrate the dynamically-created loader instances into the XMLLoader's overall <code>progress</code>, set <code>integrateProgress</code> to <code>false</code>.</li>
		 * 		<li><strong> alternateURL : String</strong> - If you define an <code>alternateURL</code>, the loader will initially try to load from its original <code>url</code> and if it fails, it will automatically (and permanently) change the loader's <code>url</code> to the <code>alternateURL</code> and try again. Think of it as a fallback or backup <code>url</code>. It is perfectly acceptable to use the same <code>alternateURL</code> for multiple loaders (maybe a default image for various ImageLoaders for example).</li>
		 * 		<li><strong> noCache : Boolean</strong> - If <code>noCache</code> is <code>true</code>, a "gsCacheBusterID" parameter will be appended to the url with a random set of numbers to prevent caching (don't worry, this info is ignored when you <code>getLoader()</code> or <code>getContent()</code> by url and when you're running locally)</li>
		 * 		<li><strong> estimatedBytes : uint</strong> - Initially, the loader's <code>bytesTotal</code> is set to the <code>estimatedBytes</code> value (or <code>LoaderMax.defaultEstimatedBytes</code> if one isn't defined). Then, when the XML has been loaded and analyzed enough to determine the size of any dynamic loaders that were found in the XML data (like &lt;ImageLoader&gt; nodes, etc.), it will adjust the <code>bytesTotal</code> accordingly. Setting <code>estimatedBytes</code> is optional, but it provides a way to avoid situations where the <code>progress</code> and <code>bytesTotal</code> values jump around as XMLLoader recognizes nested loaders in the XML and audits their size. The <code>estimatedBytes</code> value should include all nested loaders as well, so if your XML file itself is 500 bytes and you have 3 &lt;ImageLoader&gt; tags with <code>load="true"</code> and each image is about 2000 bytes, your XMLLoader's <code>estimatedBytes</code> should be 6500. The more accurate the value, the more accurate the loaders' overall progress will be.</li>
		 * 		<li><strong> requireWithRoot : DisplayObject</strong> - LoaderMax supports <i>subloading</i>, where an object can be factored into a parent's loading progress. If you want LoaderMax to require this XMLLoader as part of its parent SWFLoader's progress, you must set the <code>requireWithRoot</code> property to your swf's <code>root</code>. For example, <code>var loader:XMLLoader = new XMLLoader("data.xml", {name:"data", requireWithRoot:this.root});</code></li>
		 * 		<li><strong> autoDispose : Boolean</strong> - When <code>autoDispose</code> is <code>true</code>, the loader will be disposed immediately after it completes (it calls the <code>dispose()</code> method internally after dispatching its <code>COMPLETE</code> event). This will remove any listeners that were defined in the vars object (like onComplete, onProgress, onError, onInit). Once a loader is disposed, it can no longer be found with <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> - it is essentially destroyed but its content is not unloaded (you must call <code>unload()</code> or <code>dispose(true)</code> to unload its content). The default <code>autoDispose</code> value is <code>false</code>.</li>
		 * 		<li><strong> prependURLs : String</strong> - A String that should be prepended to all parsed LoaderMax-related loader URLs (from nodes like &lt;ImageLoader&gt;, &lt;XMLLoader&gt;, etc.) as soon as the XML has been parsed. For example, if your XML has the following node: <code>&lt;ImageLoader url="1.jpg" /&gt;</code> and <code>prependURLs</code> is set to "../images/", then the ImageLoader's url will end up being "../images/1.jpg". <code>prependURLs</code> affects ALL parsed loaders in the XML. However, if you have an <code>&lt;XMLLoader&gt;</code> node inside your XML that also loads another XML doc and you'd like to recursively prepend all of the URLs in this loader's XML as well as the subloading one and all of its children, use <code>recursivePrependURLs</code> instead of <code>prependURLs</code>.</li>
		 * 		<li><strong> maxConnections : uint</strong> - Maximum number of simultaneous connections that should be used while loading child loaders that were parsed from the XML and had their "load" attribute set to "true" (like &lt;ImageLoader url="1.jpg" load="true" /&gt;). A higher number will generally result in faster overall load times for the group. The default is 2. Sometimes there are limits imposed by the Flash Player itself or the browser or the user's system, but LoaderMax will do its best to honor the <code>maxConnections</code> you define.</li>
		 * 		<li><strong> allowMalformedURL : Boolean</strong> - Normally, the URL will be parsed and any variables in the query string (like "?name=test&amp;state=il&amp;gender=m") will be placed into a URLVariables object which is added to the URLRequest. This avoids a few bugs in Flash, but if you need to keep the entire URL intact (no parsing into URLVariables), set <code>allowMalformedURL:true</code>. For example, if your URL has duplicate variables in the query string like <code>http://www.greensock.com/?c=S&amp;c=SE&amp;c=SW</code>, it is technically considered a malformed URL and a URLVariables object can't properly contain all the duplicates, so in this case you'd want to set <code>allowMalformedURL</code> to <code>true</code>.</li>
		 * 		<li><strong> skipFailed : Boolean</strong> - By default, XMLLoader will parse any LoaderMax-related loaders in the XML and load any that have their "load" attribute set to "true" and then if any fail to load, they will simply be skipped. But if you prefer to have the XMLLoader fail immediately if one of the parsed loaders fails to load, set <code>skipFailed</code> to <code>false</code> (it is <code>true</code> by default).</li>
		 * 		<li><strong> recursivePrependURLs : String</strong> - A String that should be recursively prepended to all parsed LoaderMax-related loader URLs (from nodes like &lt;ImageLoader&gt;, &lt;XMLLoader&gt;, etc.). The functionality is identical to <code>prependURLs</code> except that it is recursive, affecting all parsed loaders in subloaded XMLLoaders (other XML files that this one loads too). For example, if your XML has the following node: <code>&lt;XMLLoader url="doc2.xml" /&gt;</code> and <code>recursivePrependURLs</code> is set to "../xml/", then the nested XMLLoader's URL will end up being "../xml/doc2.xml". Since it is recursive, parsed loaders inside doc2.xml <i>and</i> any other XML files that it loads will <i>all</i> have their URLs prepended. So if you load doc1.xml which loads doc2.xml which loads doc3.xml (due to <code>&lt;XMLLoader&gt;</code> nodes discovered in each XML file), <code>recursivePrependURLs</code> will affect all of the parsed LoaderMax-related URLs in all 3 documents. If you'd prefer to <i>only</i> have the URLs affected that are in the XML file that this XMLLoader is loading, use <code>prependURLs</code> instead of <code>recursivePrependURLs</code>.
		 * 
		 * 		<br /><br />----EVENT HANDLER SHORTCUTS----</li>
		 * 		<li><strong> onOpen : Function</strong> - A handler function for <code>LoaderEvent.OPEN</code> events which are dispatched when the loader begins loading. Make sure your onOpen function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onRawLoad : Function</strong> - A handler function for <code>XMLLoader.RAW_LOAD</code> events which are dispatched when the loader finishes loading the XML but has <b>NOT</b> parsed the XML yet. This can be useful in rare situations when you want to alter the XML before it is parsed by XMLLoader (for identifying LoaderMax-related nodes like <code>&lt;ImageLoader&gt;</code>, etc.). Make sure your onRawLoad function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onInit : Function</strong> - A handler function for <code>LoaderEvent.INIT</code> events which are dispatched when the loader finishes loading the XML file, parses its contents, and creates any dynamic XML-driven loaders. If any dynamic loaders are created and have a <code>load="true"</code> attribute, they will begin loading at this point and the XMLLoader's <code>COMPLETE</code> will not be dispatched until the loaders have completed as well. Make sure your onInit function accepts a single parameter of type <code>Event</code> (flash.events.Event).</li>
		 * 		<li><strong> onProgress : Function</strong> - A handler function for <code>LoaderEvent.PROGRESS</code> events which are dispatched whenever the <code>bytesLoaded</code> changes. Make sure your onProgress function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). You can use the LoaderEvent's <code>target.progress</code> to get the loader's progress value or use its <code>target.bytesLoaded</code> and <code>target.bytesTotal</code>.</li>
		 * 		<li><strong> onComplete : Function</strong> - A handler function for <code>LoaderEvent.COMPLETE</code> events which are dispatched when the loader has finished loading successfully. Make sure your onComplete function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onCancel : Function</strong> - A handler function for <code>LoaderEvent.CANCEL</code> events which are dispatched when loading is aborted due to either a failure or because another loader was prioritized or <code>cancel()</code> was manually called. Make sure your onCancel function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onError : Function</strong> - A handler function for <code>LoaderEvent.ERROR</code> events which are dispatched whenever the loader experiences an error (typically an IO_ERROR or SECURITY_ERROR). An error doesn't necessarily mean the loader failed, however - to listen for when a loader fails, use the <code>onFail</code> special property. Make sure your onError function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onFail : Function</strong> - A handler function for <code>LoaderEvent.FAIL</code> events which are dispatched whenever the loader fails and its <code>status</code> changes to <code>LoaderStatus.FAILED</code>. Make sure your onFail function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onIOError : Function</strong> - A handler function for <code>LoaderEvent.IO_ERROR</code> events which will also call the onError handler, so you can use that as more of a catch-all whereas <code>onIOError</code> is specifically for LoaderEvent.IO_ERROR events. Make sure your onIOError function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onHTTPStatus : Function</strong> - A handler function for <code>LoaderEvent.HTTP_STATUS</code> events. Make sure your onHTTPStatus function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). You can determine the httpStatus code using the LoaderEvent's <code>target.httpStatus</code> (LoaderItems keep track of their <code>httpStatus</code> when possible, although certain environments prevent Flash from getting httpStatus information).</li>
		 * 		<li><strong> onSecurityError : Function</strong> - A handler function for <code>LoaderEvent.SECURITY_ERROR</code> events which onError handles as well, so you can use that as more of a catch-all whereas onSecurityError is specifically for SECURITY_ERROR events. Make sure your onSecurityError function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onChildOpen : Function</strong> - A handler function for <code>LoaderEvent.CHILD_OPEN</code> events which are dispatched each time any nested LoaderMax-related loaders that were defined in the XML begins loading. Make sure your onChildOpen function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onChildProgress : Function</strong> - A handler function for <code>LoaderEvent.CHILD_PROGRESS</code> events which are dispatched each time any nested LoaderMax-related loaders that were defined in the XML dispatches a <code>PROGRESS</code> event. To listen for changes in the XMLLoader's overall progress, use the <code>onProgress</code> special property instead. You can use the LoaderEvent's <code>target.progress</code> to get the child loader's progress value or use its <code>target.bytesLoaded</code> and <code>target.bytesTotal</code>. The LoaderEvent's <code>currentTarget</code> refers to the XMLLoader, so you can check its overall progress with the LoaderEvent's <code>currentTarget.progress</code>. Make sure your onChildProgress function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onChildComplete : Function</strong> - A handler function for <code>LoaderEvent.CHILD_COMPLETE</code> events which are dispatched each time any nested LoaderMax-related loaders that were defined in the XML finishes loading successfully. Make sure your onChildComplete function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onChildCancel : Function</strong> - A handler function for <code>LoaderEvent.CHILD_CANCEL</code> events which are dispatched each time loading is aborted on any nested LoaderMax-related loaders that were defined in the XML due to either an error or because another loader was prioritized in the queue or because <code>cancel()</code> was manually called on the child loader. Make sure your onChildCancel function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onChildFail : Function</strong> - A handler function for <code>LoaderEvent.CHILD_FAIL</code> events which are dispatched each time any nested LoaderMax-related loaders that were defined in the XML fails (and its <code>status</code> chances to <code>LoaderStatus.FAILED</code>). Make sure your onChildFail function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * </ul>
		 * @see com.greensock.loading.data.XMLLoaderVars
		 */
		public function XMLLoader(urlOrRequest:*, vars:Object=null) {
			super(urlOrRequest, vars);
			_preferEstimatedBytesInAudit = true;
			_type = "XMLLoader";
			_loader.dataFormat = "text"; //just to make sure it wasn't overridden if the "format" special vars property was passed into in DataLoader's constructor.
		}
		
		/** @private **/
		override protected function _load():void {
			if (!_initted) {
				_prepRequest();
				_loader.load(_request);
			} else if (_loadingQueue != null) {
				_changeQueueListeners(true);
				_loadingQueue.load(false);
			}
		}
		
		/** @private **/
		protected function _changeQueueListeners(add:Boolean):void {
			if (_loadingQueue != null) {
				var p:String;
				if (add && this.vars.integrateProgress != false) {
					for (p in _listenerTypes) {
						if (p != "onProgress" && p != "onInit") {
							_loadingQueue.addEventListener(_listenerTypes[p], _passThroughEvent, false, -100, true);
						}
					}
					_loadingQueue.addEventListener(LoaderEvent.COMPLETE, _completeHandler, false, -100, true);
					_loadingQueue.addEventListener(LoaderEvent.PROGRESS, _progressHandler, false, -100, true);
					_loadingQueue.addEventListener(LoaderEvent.FAIL, _failHandler, false, -100, true);
				} else {
					_loadingQueue.removeEventListener(LoaderEvent.COMPLETE, _completeHandler);
					_loadingQueue.removeEventListener(LoaderEvent.PROGRESS, _progressHandler);
					_loadingQueue.removeEventListener(LoaderEvent.FAIL, _failHandler);
					for (p in _listenerTypes) {
						if (p != "onProgress" && p != "onInit") {
							_loadingQueue.removeEventListener(_listenerTypes[p], _passThroughEvent);
						}
					}
				}
			}
		}
		
		/** @private scrubLevel: 0 = cancel, 1 = unload, 2 = dispose, 3 = flush **/
		override protected function _dump(scrubLevel:int=0, newStatus:int=0, suppressEvents:Boolean=false):void {
			if (_loadingQueue != null) {
				_changeQueueListeners(false);
				if (scrubLevel == 0) {
					_loadingQueue.cancel();
				} else {
					_loadingQueue.dispose(Boolean(scrubLevel == 3));
					_loadingQueue = null;
				}
			}
			if (scrubLevel >= 1) {
				if (_parsed != null) {
					_parsed.dispose(Boolean(scrubLevel == 3));
					_parsed = null;
				}
				_initted = false;
			}
			_cacheIsDirty = true;
			var content:* = _content; 
			super._dump(scrubLevel, newStatus, suppressEvents);
			if (scrubLevel == 0) {
				_content = content; //super._dump() nulls "_content" but if the XML loaded and not the loading queue (yet), we should keep the XML content. 
			}
		}
		
		/** @private **/
		override protected function _calculateProgress():void { 
			_cachedBytesLoaded = _loader.bytesLoaded;
			if (_loader.bytesTotal != 0) { //otherwise if unload() was called, bytesTotal would go back down to 0.
				_cachedBytesTotal = _loader.bytesTotal;
			}
			if (_cachedBytesTotal < _cachedBytesLoaded || _initted) {
				//In Chrome when the XML file exceeds a certain size and gzip is enabled on the server, Adobe's URLLoader reports bytesTotal as 0!!!
				//and in Firefox, if gzip was enabled, on very small files the URLLoader's bytesLoaded would never quite reach the bytesTotal even after the COMPLETE event fired!
				_cachedBytesTotal = _cachedBytesLoaded; 
			}
			var estimate:uint = uint(this.vars.estimatedBytes);
			if (this.vars.integrateProgress == false) {
				// do nothing
			} else if (_loadingQueue != null && (uint(this.vars.estimatedBytes) < _cachedBytesLoaded || _loadingQueue.auditedSize)) { //make sure that estimatedBytes is prioritized until the _loadingQueue has audited its size successfully!
				if (_loadingQueue.status <= LoaderStatus.COMPLETED) {
					_cachedBytesLoaded += _loadingQueue.bytesLoaded;
					_cachedBytesTotal  += _loadingQueue.bytesTotal;	
				}
			} else if (uint(this.vars.estimatedBytes) > _cachedBytesLoaded && (!_initted || (_loadingQueue != null && _loadingQueue.status <= LoaderStatus.COMPLETED && !_loadingQueue.auditedSize))) {
				_cachedBytesTotal = uint(this.vars.estimatedBytes);
			}
			if (!_initted && _cachedBytesLoaded == _cachedBytesTotal) {
				_cachedBytesLoaded = int(_cachedBytesLoaded * 0.99); //don't allow the progress to hit 1 yet
			}
			_cacheIsDirty = false;
		}
		
		/**
		 * Finds a particular loader inside any LoaderMax instances that were discovered in the xml content. 
		 * For example:<br /><br /><code>
		 * 
		 * var xmlLoader:XMLLoader = new XMLLoader("xml/doc.xml", {name:"xmlDoc", onComplete:completeHandler});<br />
		 * function completeHandler(event:Event):void {<br />
		 *    var imgLoader:ImageLoader = xmlLoader.getLoader("imageInXML") as ImageLoader;<br />
		 *    addChild(imgLoader.content);<br />
		 * }<br /><br /></code>
		 * 
		 * The static <code>LoaderMax.getLoader()</code> method can be used instead which searches all loaders.
		 * 
		 * @param nameOrURL The name or url associated with the loader that should be found.
		 * @return The loader associated with the name or url. Returns <code>null</code> if none were found.
		 */
		public function getLoader(nameOrURL:String):* {
			return (_parsed != null) ? _parsed.getLoader(nameOrURL) : null;
		}
		
		/**
		 * Finds a particular loader's <code>content</code> from inside any loaders that were dynamically 
		 * generated based on the xml data. For example:<br /><br /><code>
		 * 
		 * var loader:XMLLoader = new XMLLoader("xml/doc.xml", {name:"xmlDoc", onComplete:completeHandler});<br />
		 * function completeHandler(event:Event):void {<br />
		 *    var subloadedImage:Bitmap = loader.getContent("imageInXML");<br />
		 *    addChild(subloadedImage);<br />
		 * }<br /><br /></code>
		 * 
		 * The static <code>LoaderMax.getContent()</code> method can be used instead which searches all loaders.
		 * 
		 * @param nameOrURL The name or url associated with the loader whose content should be found.
		 * @return The content associated with the loader's name or url. Returns <code>null</code> if none were found.
		 * @see #content
		 */
		public function getContent(nameOrURL:String):* {
			if (nameOrURL == this.name || nameOrURL == _url) {
				return _content;
			}
			var loader:LoaderCore = this.getLoader(nameOrURL);
			return (loader != null) ? loader.content : null;
		}
		
		/**
		 * Returns and array of all LoaderMax-related loaders (if any) that were found inside the XML. 
		 * For example, if the following XML was in the document, a child loader would be created for it
		 * immediately before the INIT event is dispatched: <br /><br /><code>
		 * 
		 * &lt;ImageLoader url="1.jpg" name="image1" /&gt;<br /><br /></code>
		 * 
		 * Don't forget to use <code>LoaderMax.activate()</code> to activate the types of loaders
		 * that you want XMLLoader to recognize (you only need to activate() them once in your swf). 
		 * Like <code>LoaderMax.activate([ImageLoader, SWFLoader]);</code> to ensure that XMLLoader
		 * recognizes &lt;ImageLoader&gt; and &lt;SWFLoader&gt; nodes. <br /><br />
		 * 
		 * No child loader can be found until the XMLLoader's INIT event is dispatched, meaning the 
		 * XML has been loaded and parsed. 
		 * 
		 * @param includeNested If <code>true</code>, loaders that are nested inside child LoaderMax, XMLLoader, or SWFLoader instances will be included in the returned array as well. The default is <code>false</code>.
		 * @param omitLoaderMaxes If <code>true</code>, no LoaderMax instances will be returned in the array; only LoaderItems like ImageLoaders, XMLLoaders, SWFLoaders, MP3Loaders, etc. The default is <code>false</code>. 
		 * @return An array of loaders.
		 */
		public function getChildren(includeNested:Boolean=false, omitLoaderMaxes:Boolean=false):Array {
			return (_parsed != null) ? _parsed.getChildren(includeNested, omitLoaderMaxes) : [];
		}
		
//---- STATIC METHODS ------------------------------------------------------------------------------------
		
		/** @private **/
		protected static function _parseVars(xml:XML):Object {
			var v:Object = {rawXML:xml};
			var s:String, type:String, value:String, domain:ApplicationDomain;
			var list:XMLList = xml.attributes();
			for each (var attribute:XML in list) {
				s = attribute.name();
				value = attribute.toString();
				if (s == "url") {
					continue;
				} else if (s == "context") {
					v.context = new LoaderContext(true, 
												  (value == "own") ? ApplicationDomain.currentDomain : (value == "separate") ? new ApplicationDomain() : new ApplicationDomain(ApplicationDomain.currentDomain),
												  (!_isLocal) ? SecurityDomain.currentDomain : null);
					continue;
				}
				type = typeof(_varTypes[s]);
				if (type == "boolean") {
					v[s] = Boolean(value == "true" || value == "1");
				} else if (type == "number") {
					v[s] = Number(value);
				} else {
					v[s] = value;
				}
				
			}
			return v;
		}
		
		/**
		 * Parses an XML object and finds all activated loader types (like LoaderMax, ImageLoader, SWFLoader, DataLoader, 
		 * CSSLoader, MP3Loader, etc.), creates the necessary instances, and appends them to the LoaderMax that is defined 
		 * in the 2nd parameter. Don't forget to make sure you <code>activate()</code> the necessary loader types that you 
		 * want XMLLoader to recognize in the XML, like:<br /><br /><code>
		 * 
		 * LoaderMax.activate([ImageLoader, SWFLoader]); //or whatever types you're using.</code>
		 * 
		 * @param xml The XML to parse
		 * @param all The LoaderMax instance to which all parsed loaders should be appended
		 * @param toLoad The LoaderMax instance to which <strong>ONLY</strong> parsed loaders that have a <code>load="true"</code> attribute defined in the XML should be appended. These loaders will also be appended to the LoaderMax defined in the <code>all</code> parameter.
		 */
		public static function parseLoaders(xml:XML, all:LoaderMax, toLoad:LoaderMax=null):void {
			var node:XML;
			var nodeName:String = String(xml.name()).toLowerCase();
			if (nodeName == "loadermax") {
				var queue:LoaderMax = all.append(new LoaderMax(_parseVars(xml))) as LoaderMax;
				if (toLoad != null && queue.vars.load) {
					toLoad.append(queue);
				}
				
				if (queue.vars.childrenVars != null && queue.vars.childrenVars.indexOf(":") != -1) {
					queue.vars.childrenVars = _parseVars( new XML("<childrenVars " + queue.vars.childrenVars.split(",").join("\" ").split(":").join("=\"") + "\" />") );
				}
				
				for each (node in xml.children()) {
					parseLoaders(node, queue, toLoad);
				}
				
				if ("replaceURLText" in queue.vars) {
					var replaceText:Array = queue.vars.replaceURLText.split(",");
					for (var i:int = 0; i < replaceText.length; i += 2) {
						queue.replaceURLText(replaceText[i], replaceText[i+1], false);
					}
				}
				if ("prependURLs" in queue.vars) {
					queue.prependURLs(queue.vars.prependURLs, false);
				}
			} else {
				if (nodeName in _types) {
					var loaderClass:Class = _types[nodeName];
					var parsedVars:Object = _parseVars(xml);
					if (typeof(all.vars.childrenVars) == "object") {
						for (var p:String in all.vars.childrenVars) {
							if (!(p in parsedVars)) {
								parsedVars[p] = all.vars.childrenVars[p];
							}
						}
					}
					var loader:LoaderCore = all.append(new loaderClass(xml.@url, parsedVars));
					if (toLoad != null && loader.vars.load) {
						toLoad.append(loader);
					}
				}
				
				for each (node in xml.children()) {
					parseLoaders(node, all, toLoad);
				}
			}
		}
		
		
//---- EVENT HANDLERS ------------------------------------------------------------------------------------
		
		/** @private **/
		override protected function _progressHandler(event:Event):void {
			if (_dispatchProgress) {
				var bl:uint = _cachedBytesLoaded;
				var bt:uint = _cachedBytesTotal;
				_calculateProgress();
				if (_cachedBytesLoaded != _cachedBytesTotal && (bl != _cachedBytesLoaded || bt != _cachedBytesTotal)) {
					dispatchEvent(new LoaderEvent(LoaderEvent.PROGRESS, this));
				}
			} else {
				_cacheIsDirty = true;
			}
		}
		
		/** @private **/
		override protected function _passThroughEvent(event:Event):void {
			if (event.target != _loadingQueue) {
				super._passThroughEvent(event);
			}
		}
		
		/** @private **/
		override protected function _receiveDataHandler(event:Event):void {
			try {
				_content = new XML(_loader.data);
			} catch (error:Error) {
				_content = _loader.data;
				_failHandler(new LoaderEvent(LoaderEvent.ERROR, this, error.message));
				return;
			}
			dispatchEvent(new LoaderEvent(RAW_LOAD, this, "", _content));
			_initted = true;
			
			_loadingQueue = new LoaderMax({name:this.name + "_Queue", maxConnections:(uint(this.vars.maxConnections) || 2), skipFailed:Boolean(this.vars.skipFailed != false), skipPaused:Boolean(this.vars.skipPaused != false)});
			_parsed = new LoaderMax({name:this.name + "_ParsedLoaders", paused:true});
			parseLoaders(_content as XML, _parsed, _loadingQueue);
			if (_parsed.numChildren == 0) {
				_parsed.dispose(false);
				_parsed = null;
			} else if ("recursivePrependURLs" in this.vars) {
				_parsed.prependURLs(this.vars.recursivePrependURLs, true);
				var loaders:Array = _parsed.getChildren(true, true);
				var i:int = loaders.length;
				while (--i > -1) {
					if (loaders[i] is XMLLoader) {
						loaders[i].vars.recursivePrependURLs = this.vars.recursivePrependURLs;
					}
				}
			} else if ("prependURLs" in this.vars) {
				_parsed.prependURLs(this.vars.prependURLs, true);
			}
			if (_loadingQueue.getChildren(true, true).length == 0) {
				_loadingQueue.empty(false);
				_loadingQueue.dispose(false);
				_loadingQueue = null;
				dispatchEvent(new LoaderEvent(LoaderEvent.INIT, this, "", _content));
			} else {
				_cacheIsDirty = true;
				_changeQueueListeners(true);
				dispatchEvent(new LoaderEvent(LoaderEvent.INIT, this, "", _content));
				_loadingQueue.load(false);
			}
			
			if (_loadingQueue == null || (this.vars.integrateProgress == false)) {
				_completeHandler(event);
			}
		}
		
		/** @private **/
		override protected function _failHandler(event:Event, dispatchError:Boolean=true):void {
			if (event.target == _loadingQueue) {
				//this is a unique situation where we don't want the failure to unload the XML because only one of the nested loaders failed but the XML is perfectly good and usable. Also, we want to retain the _loadingQueue so that getChildren() works. Therefore we don't call super._failHandler();
				_status = LoaderStatus.FAILED;
				_time = getTimer() - _time;
				dispatchEvent(new LoaderEvent(LoaderEvent.CANCEL, this));
				dispatchEvent(new LoaderEvent(LoaderEvent.FAIL, this, this.toString() + " > " + (event as Object).text));
			} else {
				super._failHandler(event, dispatchError);
			}
		}
		
		/** @private **/
		override protected function _completeHandler(event:Event=null):void {
			_calculateProgress();
			if (this.progress == 1) {
				_changeQueueListeners(false);
				super._completeHandler(event);
			}
		}
		
//---- GETTERS / SETTERS -------------------------------------------------------------------------
		
		/** @inheritDoc The purpose of the override is so that we can return 1 in rare cases where the XML file literally is empty (bytesTotal == 0) which is verified when _initted == true. **/
		override public function get progress():Number {
			return (this.bytesTotal != 0) ? _cachedBytesLoaded / _cachedBytesTotal : (_status == LoaderStatus.COMPLETED || _initted) ? 1 : 0;
		}
		
	}
}