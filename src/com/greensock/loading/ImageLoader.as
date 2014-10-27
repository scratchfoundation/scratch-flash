/**
 * VERSION: 1.897
 * DATE: 2012-01-14
 * AS3
 * UPDATES AND DOCS AT: http://www.greensock.com/loadermax/
 **/
package com.greensock.loading {
	import com.greensock.events.LoaderEvent;
	import com.greensock.loading.core.DisplayObjectLoader;
	import com.greensock.loading.core.LoaderItem;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.ProgressEvent;

/**
 * Loads an image file (png, jpg, or gif) and automatically applies smoothing by default. <br /><br />
 * 
 * The ImageLoader's <code>content</code> refers to a <code>ContentDisplay</code> (Sprite) that 
 * is created immediately so that you can position/scale/rotate it or add ROLL_OVER/ROLL_OUT/CLICK listeners
 * before (or while) the image loads. Use the ImageLoader's <code>content</code> property to get the ContentDisplay 
 * Sprite, or use the <code>rawContent</code> property to get the actual Bitmap. If a <code>container</code>
 * is defined in the <code>vars</code> object, the ContentDisplay will immediately be added to that container). <br /><br />
 * 
 * If you define a <code>width</code> and <code>height</code>, it will draw a rectangle 
 * in the ContentDisplay so that interactive events fire appropriately (rollovers, etc.) and width/height/bounds
 * get reported accurately. This rectangle is invisible by default, but you can control its color and alpha
 * with the <code>bgColor</code> and <code>bgAlpha</code> properties. When the image loads, it will be 
 * added to the ContentDisplay at index 0 with <code>addChildAt()</code> and scaled to fit the width/height 
 * according to the <code>scaleMode</code>. These are all optional features - you do not need to define a 
 * <code>width</code> or <code>height</code> in which case the image will load at its native size. 
 * See the list below for all the special properties that can be passed through the <code>vars</code> 
 * parameter but don't let the list overwhelm you - these are all optional and they are intended to make
 * your job as a developer much easier.<br /><br />
 * 
 * <i>[new in version 1.89:]</i> When you <code>load()</code> an ImageLoader, it will automatically 
 * check to see if another ImageLoader exists with a matching <code>url</code> that has already finished
 * loading. If it finds one, it will copy that BitmapData to use in its own Bitmap in order to maximize
 * performance and minimize memory usage. After all, why load the file again if you've already loaded it? 
 * (The exception, of course, is when the ImageLoader's <code>noCache</code> is set to <code>true</code>.)<br /><br />
 * 
 * By default, the ImageLoader will attempt to load the image in a way that allows full script 
 * access. However, if a security error is thrown because the image is being loaded from another
 * domain and the appropriate crossdomain.xml file isn't in place to grant access, the ImageLoader
 * will automatically adjust the default LoaderContext so that it falls back to the more restricted
 * mode which will have the following effect:
 * <ul>
 * 		<li>A <code>LoaderEvent.SCRIPT_ACCESS_DENIED</code> event will be dispatched and the <code>scriptAccessDenied</code> property of the ImageLoader will be set to <code>true</code>. You can check this value before performing any restricted operations on the content like BitmapData.draw().</li>
 * 		<li>The ImageLoader's <code>rawContent</code> property will be a <code>Loader</code> instance instead of a Bitmap.</li>
 * 		<li>The <code>smoothing</code> property will <strong>not</strong> be set to <code>true</code>.</li>
 * 		<li>BitmapData operations like draw() will not be able to be performed on the image.</li>
 * </ul>
 * 
 * To maximize the likelihood of your image loading without any security problems, consider taking the following steps:
 * <ul>
 * 		<li><strong>Use a crossdomain.xml file </strong> - See Adobe's docs for details, but here is an example that grants full access (put this in a crossdomain.xml file that is at the root of the remote domain):<br />
 * 			&lt;?xml version="1.0" encoding="utf-8"?&gt;<br />
 * 			&lt;cross-domain-policy&gt;<br />
 *     			   &lt;allow-access-from domain="~~" /&gt;<br />
 * 			&lt;/cross-domain-policy&gt;</li>
 * 		<li>In the embed code of any HTML wrapper, set <code>AllowScriptAccess</code> to <code>"always"</code></li>
 * </ul><br />
 * 
 * <strong>OPTIONAL VARS PROPERTIES</strong><br />
 * The following special properties can be passed into the ImageLoader constructor via its <code>vars</code> 
 * parameter which can be either a generic object or an <code><a href="data/ImageLoaderVars.html">ImageLoaderVars</a></code> object:<br />
 * <ul>
 * 		<li><strong> name : String</strong> - A name that is used to identify the ImageLoader instance. This name can be fed to the <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> methods or traced at any time. Each loader's name should be unique. If you don't define one, a unique name will be created automatically, like "loader21".</li>
 * 		<li><strong> container : DisplayObjectContainer</strong> - A DisplayObjectContainer into which the <code>ContentDisplay</code> Sprite should be added immediately.</li>
 * 		<li><strong> smoothing : Boolean</strong> - When <code>smoothing</code> is <code>true</code> (the default), smoothing will be enabled for the image which typically leads to much better scaling results (otherwise the image can look crunchy/jagged). If your image is loaded from another domain where the appropriate crossdomain.xml file doesn't grant permission, Flash will not allow smoothing to be enabled (it's a security restriction).</li>
 * 		<li><strong> width : Number</strong> - Sets the <code>ContentDisplay</code>'s <code>width</code> property (applied before rotation, scaleX, and scaleY).</li>
 * 		<li><strong> height : Number</strong> - Sets the <code>ContentDisplay</code>'s <code>height</code> property (applied before rotation, scaleX, and scaleY).</li>
 * 		<li><strong> centerRegistration : Boolean </strong> - If <code>true</code>, the registration point will be placed in the center of the ContentDisplay which can be useful if, for example, you want to animate its scale and have it grow/shrink from its center.</li>
 * 		<li><strong> scaleMode : String </strong> - When a <code>width</code> and <code>height</code> are defined, the <code>scaleMode</code> controls how the loaded image will be scaled to fit the area. The following values are recognized (you may use the <code>com.greensock.layout.ScaleMode</code> constants if you prefer):
 * 			<ul>
 * 				<li><code>"stretch"</code> (the default) - The image will fill the width/height exactly.</li>
 * 				<li><code>"proportionalInside"</code> - The image will be scaled proportionally to fit inside the area defined by the width/height</li>
 * 				<li><code>"proportionalOutside"</code> - The image will be scaled proportionally to completely fill the area, allowing portions of it to exceed the bounds defined by the width/height.</li>
 * 				<li><code>"widthOnly"</code> - Only the width of the image will be adjusted to fit.</li>
 * 				<li><code>"heightOnly"</code> - Only the height of the image will be adjusted to fit.</li>
 * 				<li><code>"none"</code> - No scaling of the image will occur.</li>
 * 			</ul></li>
 * 		<li><strong> hAlign : String </strong> - When a <code>width</code> and <code>height</code> is defined, the <code>hAlign</code> determines how the image is horizontally aligned within that area. The following values are recognized (you may use the <code>com.greensock.layout.AlignMode</code> constants if you prefer):
 * 			<ul>
 * 				<li><code>"center"</code> (the default) - The image will be centered horizontally in the area</li>
 * 				<li><code>"left"</code> - The image will be aligned with the left side of the area</li>
 * 				<li><code>"right"</code> - The image will be aligned with the right side of the area</li>
 * 			</ul></li>
 * 		<li><strong> vAlign : String </strong> - When a <code>width</code> and <code>height</code> is defined, the <code>vAlign</code> determines how the image is vertically aligned within that area. The following values are recognized (you may use the <code>com.greensock.layout.AlignMode</code> constants if you prefer):
 * 			<ul>
 * 				<li><code>"center"</code> (the default) - The image will be centered vertically in the area</li>
 * 				<li><code>"top"</code> - The image will be aligned with the top of the area</li>
 * 				<li><code>"bottom"</code> - The image will be aligned with the bottom of the area</li>
 * 			</ul></li>
 * 		<li><strong> crop : Boolean</strong> - When a <code>width</code> and <code>height</code> are defined, setting <code>crop</code> to <code>true</code> will cause the image to be cropped within that area (by applying a <code>scrollRect</code> for maximum performance). This is typically useful when the <code>scaleMode</code> is <code>"proportionalOutside"</code> or <code>"none"</code> so that any parts of the image that exceed the dimensions defined by <code>width</code> and <code>height</code> are visually chopped off. Use the <code>hAlign</code> and <code>vAlign</code> special properties to control the vertical and horizontal alignment within the cropped area.</li>
 * 		<li><strong> x : Number</strong> - Sets the <code>ContentDisplay</code>'s <code>x</code> property (for positioning on the stage).</li>
 * 		<li><strong> y : Number</strong> - Sets the <code>ContentDisplay</code>'s <code>y</code> property (for positioning on the stage).</li>
 * 		<li><strong> scaleX : Number</strong> - Sets the <code>ContentDisplay</code>'s <code>scaleX</code> property.</li>
 * 		<li><strong> scaleY : Number</strong> - Sets the <code>ContentDisplay</code>'s <code>scaleY</code> property.</li>
 * 		<li><strong> rotation : Number</strong> - Sets the <code>ContentDisplay</code>'s <code>rotation</code> property.</li>
 * 		<li><strong> alpha : Number</strong> - Sets the <code>ContentDisplay</code>'s <code>alpha</code> property.</li>
 * 		<li><strong> visible : Boolean</strong> - Sets the <code>ContentDisplay</code>'s <code>visible</code> property.</li>
 * 		<li><strong> blendMode : String</strong> - Sets the <code>ContentDisplay</code>'s <code>blendMode</code> property.</li>
 * 		<li><strong> bgColor : uint </strong> - When a <code>width</code> and <code>height</code> are defined, a rectangle will be drawn inside the <code>ContentDisplay</code> Sprite immediately in order to ease the development process. It is transparent by default, but you may define a <code>bgAlpha</code> if you prefer.</li>
 * 		<li><strong> bgAlpha : Number </strong> - Controls the alpha of the rectangle that is drawn when a <code>width</code> and <code>height</code> are defined.</li>
 * 		<li><strong> context : LoaderContext</strong> - To control whether or not a policy file is checked (which is required if you're loading an image from another domain and you want to use it in BitmapData operations), define a <code>LoaderContext</code> object. By default, the policy file <strong>will</strong> be checked when running remotely, so make sure the appropriate crossdomain.xml file is in place. See Adobe's <code>LoaderContext</code> documentation for details and precautions. </li>
 * 		<li><strong> estimatedBytes : uint</strong> - Initially, the loader's <code>bytesTotal</code> is set to the <code>estimatedBytes</code> value (or <code>LoaderMax.defaultEstimatedBytes</code> if one isn't defined). Then, when the loader begins loading and it can accurately determine the bytesTotal, it will do so. Setting <code>estimatedBytes</code> is optional, but the more accurate the value, the more accurate your loaders' overall progress will be initially. If the loader will be inserted into a LoaderMax instance (for queue management), its <code>auditSize</code> feature can attempt to automatically determine the <code>bytesTotal</code> at runtime (there is a slight performance penalty for this, however - see LoaderMax's documentation for details).</li>
 * 		<li><strong> alternateURL : String</strong> - If you define an <code>alternateURL</code>, the loader will initially try to load from its original <code>url</code> and if it fails, it will automatically (and permanently) change the loader's <code>url</code> to the <code>alternateURL</code> and try again. Think of it as a fallback or backup <code>url</code>. It is perfectly acceptable to use the same <code>alternateURL</code> for multiple loaders (maybe a default image for various ImageLoaders for example).</li>
 * 		<li><strong> noCache : Boolean</strong> - If <code>true</code>, a "gsCacheBusterID" parameter will be appended to the url with a random set of numbers to prevent caching (don't worry, this info is ignored when you <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> by <code>url</code> or when you're running locally)</li>
 * 		<li><strong> requireWithRoot : DisplayObject</strong> - LoaderMax supports <i>subloading</i>, where an object can be factored into a parent's loading progress. If you want LoaderMax to require this ImageLoader as part of its parent SWFLoader's progress, you must set the <code>requireWithRoot</code> property to your swf's <code>root</code>. For example, <code>var loader:ImageLoader = new ImageLoader("photo1.jpg", {name:"image1", requireWithRoot:this.root});</code></li>
 * 		<li><strong> allowMalformedURL : Boolean</strong> - Normally, the URL will be parsed and any variables in the query string (like "?name=test&amp;state=il&amp;gender=m") will be placed into a URLVariables object which is added to the URLRequest. This avoids a few bugs in Flash, but if you need to keep the entire URL intact (no parsing into URLVariables), set <code>allowMalformedURL:true</code>. For example, if your URL has duplicate variables in the query string like <code>http://www.greensock.com/?c=S&amp;c=SE&amp;c=SW</code>, it is technically considered a malformed URL and a URLVariables object can't properly contain all the duplicates, so in this case you'd want to set <code>allowMalformedURL</code> to <code>true</code>.</li>
 * 		<li><strong> autoDispose : Boolean</strong> - When <code>autoDispose</code> is <code>true</code>, the loader will be disposed immediately after it completes (it calls the <code>dispose()</code> method internally after dispatching its <code>COMPLETE</code> event). This will remove any listeners that were defined in the vars object (like onComplete, onProgress, onError, onInit). Once a loader is disposed, it can no longer be found with <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> - it is essentially destroyed but its content is not unloaded (you must call <code>unload()</code> or <code>dispose(true)</code> to unload its content). The default <code>autoDispose</code> value is <code>false</code>.
 * 
 * 		<br /><br />----EVENT HANDLER SHORTCUTS----</li>
 * 		<li><strong> onOpen : Function</strong> - A handler function for <code>LoaderEvent.OPEN</code> events which are dispatched when the loader begins loading. Make sure your onOpen function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onInit : Function</strong> - A handler function for <code>LoaderEvent.INIT</code> events which are called when the image has downloaded and has been placed into the ContentDisplay Sprite. Make sure your onInit function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onProgress : Function</strong> - A handler function for <code>LoaderEvent.PROGRESS</code> events which are dispatched whenever the <code>bytesLoaded</code> changes. Make sure your onProgress function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). You can use the LoaderEvent's <code>target.progress</code> to get the loader's progress value or use its <code>target.bytesLoaded</code> and <code>target.bytesTotal</code>.</li>
 * 		<li><strong> onComplete : Function</strong> - A handler function for <code>LoaderEvent.COMPLETE</code> events which are dispatched when the loader has finished loading successfully. Make sure your onComplete function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onCancel : Function</strong> - A handler function for <code>LoaderEvent.CANCEL</code> events which are dispatched when loading is aborted due to either a failure or because another loader was prioritized or <code>cancel()</code> was manually called. Make sure your onCancel function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onError : Function</strong> - A handler function for <code>LoaderEvent.ERROR</code> events which are dispatched whenever the loader experiences an error (typically an IO_ERROR or SECURITY_ERROR). An error doesn't necessarily mean the loader failed, however - to listen for when a loader fails, use the <code>onFail</code> special property. Make sure your onError function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onFail : Function</strong> - A handler function for <code>LoaderEvent.FAIL</code> events which are dispatched whenever the loader fails and its <code>status</code> changes to <code>LoaderStatus.FAILED</code>. Make sure your onFail function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onIOError : Function</strong> - A handler function for <code>LoaderEvent.IO_ERROR</code> events which will also call the onError handler, so you can use that as more of a catch-all whereas <code>onIOError</code> is specifically for LoaderEvent.IO_ERROR events. Make sure your onIOError function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onHTTPStatus : Function</strong> - A handler function for <code>LoaderEvent.HTTP_STATUS</code> events. Make sure your onHTTPStatus function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). You can determine the httpStatus code using the LoaderEvent's <code>target.httpStatus</code> (LoaderItems keep track of their <code>httpStatus</code> when possible, although certain environments prevent Flash from getting httpStatus information).</li>
 * 		<li><strong> onSecurityError : Function</strong> - A handler function for <code>LoaderEvent.SECURITY_ERROR</code> events which onError handles as well, so you can use that as more of a catch-all whereas onSecurityError is specifically for SECURITY_ERROR events. Make sure your onSecurityError function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onScriptAccessDenied : Function</strong> - A handler function for <code>LoaderEvent.SCRIPT_ACCESS_DENIED</code> events which are dispatched when the image is loaded from another domain and no crossdomain.xml is in place to grant full script access for things like smoothing or BitmapData manipulation. You can also check the loader's <code>scriptAccessDenied</code> property after the image has loaded. Make sure your function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * </ul><br />
 * 
 * <strong>Note:</strong> Using a <code><a href="data/ImageLoaderVars.html">ImageLoaderVars</a></code> instance 
 * instead of a generic object to define your <code>vars</code> is a bit more verbose but provides 
 * code hinting and improved debugging because it enforces strict data typing. Use whichever one you prefer.<br /><br />
 * 
 * <strong>Jerky animation?</strong> If you animate the image after loading it and you notice that the movement 
 * is rather jerky, try setting the scaleX and/or scaleY to something other than 1, like 1.001 because there is 
 * a bug in Flash that forces Bitmaps to always act like their <code>pixelSnapping</code> is <code>"auto"</code> 
 * when their scaleX/scaleY are 1.<br /><br />
 * 
 * <code>content</code> data type: <strong><code>com.greensock.loading.display.ContentDisplay</code></strong> (a Sprite). 
 * When the image has finished loading, the <code>rawContent</code> will be added to the <code>ContentDisplay</code> Sprite 
 * at index 0 using <code>addChildAt()</code>. <code>rawContent</code> will be a <code>flash.display.Bitmap</code> unless 
 * unless script access is denied in which case it will be a <code>flash.display.Loader</code> (to avoid security errors).<br /><br />
 * 
 * @example Example AS3 code:<listing version="3.0">
 import com.greensock.~~;
 import com.greensock.events.LoaderEvent;
 import com.greensock.loading.~~;
 
 //create an ImageLoader:
 var loader:ImageLoader = new ImageLoader("img/photo1.jpg", {name:"photo1", container:this, x:180, y:100, width:200, height:150, scaleMode:"proportionalInside", centerRegistration:true, onComplete:onImageLoad});
 
 //begin loading
 loader.load();
 
 //when the image loads, fade it in from alpha:0 using TweenLite
 function onImageLoad(event:LoaderEvent):void {
 	TweenLite.from(event.target.content, 1, {alpha:0});
 }
 
 //Or you could put the ImageLoader into a LoaderMax. Create one first...
 var queue:LoaderMax = new LoaderMax({name:"mainQueue", onProgress:progressHandler, onComplete:completeHandler, onError:errorHandler});
 
 //append the ImageLoader and several other loaders
 queue.append( loader );
 queue.append( new XMLLoader("xml/doc.xml", {name:"xmlDoc", estimatedBytes:425}) );
 queue.append( new SWFLoader("swf/main.swf", {name:"mainClip", estimatedBytes:3000, container:this, autoPlay:false}) );
 
 //start loading
 queue.load();
 
 function progressHandler(event:LoaderEvent):void {
     trace("progress: " + queue.progress);
 }
 
 function completeHandler(event:LoaderEvent):void {
 	 trace(event.target + " is complete!");
 }
 
 function errorHandler(event:LoaderEvent):void {
     trace("error occured with " + event.target + ": " + event.text);
 }
 
 </listing>
 * <strong>NOTES / TIPS:</strong><br />
 * <ul>
 * 		<li>You will not see the image unless you either manually add it to the display list in your onComplete handler or simply use the <code>container</code> special property (see above).</li>
 * </ul><br /><br />
 * 
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @see com.greensock.loading.data.ImageLoaderVars
 * 
 * @author Jack Doyle, jack@greensock.com
 */	
	public class ImageLoader extends DisplayObjectLoader {
		/** @private **/
		private static var _classActivated:Boolean = _activateClass("ImageLoader", ImageLoader, "jpg,jpeg,png,gif,bmp");
		/**
		 * Constructor
		 * 
		 * @param urlOrRequest The url (<code>String</code>) or <code>URLRequest</code> from which the loader should get its content
		 * @param vars An object containing optional configuration details. For example: <code>new ImageLoader("img/photo1.jpg", {name:"photo1", container:this, x:100, y:50, alpha:0, onComplete:completeHandler, onProgress:progressHandler})</code>.<br /><br />
		 * 
		 * The following special properties can be passed into the constructor via the <code>vars</code> parameter
		 * which can be either a generic object or an <code><a href="data/ImageLoaderVars.html">ImageLoaderVars</a></code> object:<br />
		 * <ul>
		 * 		<li><strong> name : String</strong> - A name that is used to identify the ImageLoader instance. This name can be fed to the <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> methods or traced at any time. Each loader's name should be unique. If you don't define one, a unique name will be created automatically, like "loader21".</li>
		 * 		<li><strong> container : DisplayObjectContainer</strong> - A DisplayObjectContainer into which the <code>ContentDisplay</code> Sprite should be added immediately.</li>
		 * 		<li><strong> smoothing : Boolean</strong> - When <code>smoothing</code> is <code>true</code> (the default), smoothing will be enabled for the image which typically leads to much better scaling results (otherwise the image can look crunchy/jagged). If your image is loaded from another domain where the appropriate crossdomain.xml file doesn't grant permission, Flash will not allow smoothing to be enabled (it's a security restriction).</li>
		 * 		<li><strong> width : Number</strong> - Sets the <code>ContentDisplay</code>'s <code>width</code> property (applied before rotation, scaleX, and scaleY).</li>
		 * 		<li><strong> height : Number</strong> - Sets the <code>ContentDisplay</code>'s <code>height</code> property (applied before rotation, scaleX, and scaleY).</li>
		 * 		<li><strong> centerRegistration : Boolean </strong> - if <code>true</code>, the registration point will be placed in the center of the ContentDisplay which can be useful if, for example, you want to animate its scale and have it grow/shrink from its center.</li>
		 * 		<li><strong> scaleMode : String </strong> - When a <code>width</code> and <code>height</code> are defined, the <code>scaleMode</code> controls how the loaded image will be scaled to fit the area. The following values are recognized (you may use the <code>com.greensock.layout.ScaleMode</code> constants if you prefer):
		 * 			<ul>
		 * 				<li><code>"stretch"</code> (the default) - The image will fill the width/height exactly.</li>
		 * 				<li><code>"proportionalInside"</code> - The image will be scaled proportionally to fit inside the area defined by the width/height</li>
		 * 				<li><code>"proportionalOutside"</code> - The image will be scaled proportionally to completely fill the area, allowing portions of it to exceed the bounds defined by the width/height.</li>
		 * 				<li><code>"widthOnly"</code> - Only the width of the image will be adjusted to fit.</li>
		 * 				<li><code>"heightOnly"</code> - Only the height of the image will be adjusted to fit.</li>
		 * 				<li><code>"none"</code> - No scaling of the image will occur.</li>
		 * 			</ul></li>
		 * 		<li><strong> hAlign : String </strong> - When a <code>width</code> and <code>height</code> is defined, the <code>hAlign</code> determines how the image is horizontally aligned within that area. The following values are recognized (you may use the <code>com.greensock.layout.AlignMode</code> constants if you prefer):
		 * 			<ul>
		 * 				<li><code>"center"</code> (the default) - The image will be centered horizontally in the area</li>
		 * 				<li><code>"left"</code> - The image will be aligned with the left side of the area</li>
		 * 				<li><code>"right"</code> - The image will be aligned with the right side of the area</li>
		 * 			</ul></li>
		 * 		<li><strong> vAlign : String </strong> - When a <code>width</code> and <code>height</code> is defined, the <code>vAlign</code> determines how the image is vertically aligned within that area. The following values are recognized (you may use the <code>com.greensock.layout.AlignMode</code> constants if you prefer):
		 * 			<ul>
		 * 				<li><code>"center"</code> (the default) - The image will be centered vertically in the area</li>
		 * 				<li><code>"top"</code> - The image will be aligned with the top of the area</li>
		 * 				<li><code>"bottom"</code> - The image will be aligned with the bottom of the area</li>
		 * 			</ul></li>
		 * 		<li><strong> crop : Boolean</strong> - When a <code>width</code> and <code>height</code> are defined, setting <code>crop</code> to <code>true</code> will cause the image to be cropped within that area (by applying a <code>scrollRect</code> for maximum performance). This is typically useful when the <code>scaleMode</code> is <code>"proportionalOutside"</code> or <code>"none"</code> so that any parts of the image that exceed the dimensions defined by <code>width</code> and <code>height</code> are visually chopped off. Use the <code>hAlign</code> and <code>vAlign</code> special properties to control the vertical and horizontal alignment within the cropped area.</li>
		 * 		<li><strong> x : Number</strong> - Sets the <code>ContentDisplay</code>'s <code>x</code> property (for positioning on the stage).</li>
		 * 		<li><strong> y : Number</strong> - Sets the <code>ContentDisplay</code>'s <code>y</code> property (for positioning on the stage).</li>
		 * 		<li><strong> scaleX : Number</strong> - Sets the <code>ContentDisplay</code>'s <code>scaleX</code> property.</li>
		 * 		<li><strong> scaleY : Number</strong> - Sets the <code>ContentDisplay</code>'s <code>scaleY</code> property.</li>
		 * 		<li><strong> rotation : Number</strong> - Sets the <code>ContentDisplay</code>'s <code>rotation</code> property.</li>
		 * 		<li><strong> alpha : Number</strong> - Sets the <code>ContentDisplay</code>'s <code>alpha</code> property.</li>
		 * 		<li><strong> visible : Boolean</strong> - Sets the <code>ContentDisplay</code>'s <code>visible</code> property.</li>
		 * 		<li><strong> blendMode : String</strong> - Sets the <code>ContentDisplay</code>'s <code>blendMode</code> property.</li>
		 * 		<li><strong> bgColor : uint </strong> - When a <code>width</code> and <code>height</code> are defined, a rectangle will be drawn inside the <code>ContentDisplay</code> Sprite immediately in order to ease the development process. It is transparent by default, but you may define a <code>bgAlpha</code> if you prefer.</li>
		 * 		<li><strong> bgAlpha : Number </strong> - Controls the alpha of the rectangle that is drawn when a <code>width</code> and <code>height</code> are defined.</li>
		 * 		<li><strong> context : LoaderContext</strong> - To control whether or not a policy file is checked (which is required if you're loading an image from another domain and you want to use it in BitmapData operations), define a <code>LoaderContext</code> object. By default, the policy file <strong>will</strong> be checked when running remotely, so make sure the appropriate crossdomain.xml file is in place. See Adobe's <code>LoaderContext</code> documentation for details and precautions. </li>
		 * 		<li><strong> estimatedBytes : uint</strong> - Initially, the loader's <code>bytesTotal</code> is set to the <code>estimatedBytes</code> value (or <code>LoaderMax.defaultEstimatedBytes</code> if one isn't defined). Then, when the loader begins loading and it can accurately determine the bytesTotal, it will do so. Setting <code>estimatedBytes</code> is optional, but the more accurate the value, the more accurate your loaders' overall progress will be initially. If the loader will be inserted into a LoaderMax instance (for queue management), its <code>auditSize</code> feature can attempt to automatically determine the <code>bytesTotal</code> at runtime (there is a slight performance penalty for this, however - see LoaderMax's documentation for details).</li>
		 * 		<li><strong> alternateURL : String</strong> - If you define an <code>alternateURL</code>, the loader will initially try to load from its original <code>url</code> and if it fails, it will automatically (and permanently) change the loader's <code>url</code> to the <code>alternateURL</code> and try again. Think of it as a fallback or backup <code>url</code>. It is perfectly acceptable to use the same <code>alternateURL</code> for multiple loaders (maybe a default image for various ImageLoaders for example).</li>
		 * 		<li><strong> noCache : Boolean</strong> - If <code>true</code>, a "gsCacheBusterID" parameter will be appended to the url with a random set of numbers to prevent caching (don't worry, this info is ignored when you <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> by <code>url</code> or when you're running locally)</li>
		 * 		<li><strong> requireWithRoot : DisplayObject</strong> - LoaderMax supports <i>subloading</i>, where an object can be factored into a parent's loading progress. If you want LoaderMax to require this ImageLoader as part of its parent SWFLoader's progress, you must set the <code>requireWithRoot</code> property to your swf's <code>root</code>. For example, <code>var loader:ImageLoader = new ImageLoader("photo1.jpg", {name:"image1", requireWithRoot:this.root});</code></li>
		 * 		<li><strong> allowMalformedURL : Boolean</strong> - Normally, the URL will be parsed and any variables in the query string (like "?name=test&amp;state=il&amp;gender=m") will be placed into a URLVariables object which is added to the URLRequest. This avoids a few bugs in Flash, but if you need to keep the entire URL intact (no parsing into URLVariables), set <code>allowMalformedURL:true</code>. For example, if your URL has duplicate variables in the query string like <code>http://www.greensock.com/?c=S&amp;c=SE&amp;c=SW</code>, it is technically considered a malformed URL and a URLVariables object can't properly contain all the duplicates, so in this case you'd want to set <code>allowMalformedURL</code> to <code>true</code>.</li>
		 * 		<li><strong> autoDispose : Boolean</strong> - When <code>autoDispose</code> is <code>true</code>, the loader will be disposed immediately after it completes (it calls the <code>dispose()</code> method internally after dispatching its <code>COMPLETE</code> event). This will remove any listeners that were defined in the vars object (like onComplete, onProgress, onError, onInit). Once a loader is disposed, it can no longer be found with <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> - it is essentially destroyed but its content is not unloaded (you must call <code>unload()</code> or <code>dispose(true)</code> to unload its content). The default <code>autoDispose</code> value is <code>false</code>.
		 * 
		 * 		<br /><br />----EVENT HANDLER SHORTCUTS----</li>
		 * 		<li><strong> onOpen : Function</strong> - A handler function for <code>LoaderEvent.OPEN</code> events which are dispatched when the loader begins loading. Make sure your onOpen function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onInit : Function</strong> - A handler function for <code>LoaderEvent.INIT</code> events which are called when the image has downloaded and has been placed into the ContentDisplay Sprite. Make sure your onInit function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onProgress : Function</strong> - A handler function for <code>LoaderEvent.PROGRESS</code> events which are dispatched whenever the <code>bytesLoaded</code> changes. Make sure your onProgress function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). You can use the LoaderEvent's <code>target.progress</code> to get the loader's progress value or use its <code>target.bytesLoaded</code> and <code>target.bytesTotal</code>.</li>
		 * 		<li><strong> onComplete : Function</strong> - A handler function for <code>LoaderEvent.COMPLETE</code> events which are dispatched when the loader has finished loading successfully. Make sure your onComplete function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onCancel : Function</strong> - A handler function for <code>LoaderEvent.CANCEL</code> events which are dispatched when loading is aborted due to either a failure or because another loader was prioritized or <code>cancel()</code> was manually called. Make sure your onCancel function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onError : Function</strong> - A handler function for <code>LoaderEvent.ERROR</code> events which are dispatched whenever the loader experiences an error (typically an IO_ERROR or SECURITY_ERROR). An error doesn't necessarily mean the loader failed, however - to listen for when a loader fails, use the <code>onFail</code> special property. Make sure your onError function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onFail : Function</strong> - A handler function for <code>LoaderEvent.FAIL</code> events which are dispatched whenever the loader fails and its <code>status</code> changes to <code>LoaderStatus.FAILED</code>. Make sure your onFail function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onIOError : Function</strong> - A handler function for <code>LoaderEvent.IO_ERROR</code> events which will also call the onError handler, so you can use that as more of a catch-all whereas <code>onIOError</code> is specifically for LoaderEvent.IO_ERROR events. Make sure your onIOError function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onHTTPStatus : Function</strong> - A handler function for <code>LoaderEvent.HTTP_STATUS</code> events. Make sure your onHTTPStatus function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). You can determine the httpStatus code using the LoaderEvent's <code>target.httpStatus</code> (LoaderItems keep track of their <code>httpStatus</code> when possible, although certain environments prevent Flash from getting httpStatus information).</li>
		 * 		<li><strong> onSecurityError : Function</strong> - A handler function for <code>LoaderEvent.SECURITY_ERROR</code> events which onError handles as well, so you can use that as more of a catch-all whereas onSecurityError is specifically for SECURITY_ERROR events. Make sure your onSecurityError function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onScriptAccessDenied : Function</strong> - A handler function for <code>LoaderEvent.SCRIPT_ACCESS_DENIED</code> events which are dispatched when the image is loaded from another domain and no crossdomain.xml is in place to grant full script access for things like smoothing or BitmapData manipulation. You can also check the loader's <code>scriptAccessDenied</code> property after the image has loaded. Make sure your function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * </ul>
		 * @see com.greensock.loading.data.ImageLoaderVars
		 */
		public function ImageLoader(urlOrRequest:*, vars:Object=null) {
			super(urlOrRequest, vars);
			_type = "ImageLoader";
		}
		
		override protected function _load():void {
			if (this.vars.noCache != true) {
				//check to see if another ImageLoader with the same URL exists and has completed so that we can copy that BitmapData to speed things up and reduce memory usage. 
				var loaders:Array = _globalRootLoader.getChildren(true, true);
				var loader:LoaderItem;
				var i:int = loaders.length;
				while (--i > -1) {
					loader = loaders[i];
					if (loader.url == _url && loader != this && loader.status == LoaderStatus.COMPLETED && loader is ImageLoader && ImageLoader(loader).rawContent is Bitmap) {
						_closeStream();
						_content = new Bitmap(ImageLoader(loader).rawContent.bitmapData, "auto", Boolean(this.vars.smoothing != false));
						Object(_sprite).rawContent = (_content as DisplayObject);
						_initted = true;
						_progressHandler(new ProgressEvent(ProgressEvent.PROGRESS, false, false, loader.bytesLoaded, loader.bytesTotal));
						dispatchEvent(new LoaderEvent(LoaderEvent.INIT, this));
						_completeHandler(null);
						return;
					}
				}
			}
			super._load();
		}
		
//---- EVENT HANDLERS ------------------------------------------------------------------------------------
		
		/** @private **/
		override protected function _initHandler(event:Event):void {
			_determineScriptAccess();
			if (!_scriptAccessDenied) {
				_content = Bitmap(_loader.content);
				_content.smoothing = Boolean(this.vars.smoothing != false);
			} else {
				_content = _loader;
			}
			super._initHandler(event);
		}
		
	}
}