/**
 * VERSION: 1.922
 * DATE: 2012-09-06
 * AS3
 * UPDATES AND DOCS AT: http://www.greensock.com/loadermax/
 **/
package com.greensock.loading {
	import com.greensock.events.LoaderEvent;
	import com.greensock.loading.core.LoaderItem;
	import com.greensock.loading.display.ContentDisplay;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.NetStatusEvent;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	/** Dispatched when the loader's <code>httpStatus</code> value changes. **/
	[Event(name="httpStatus", 	type="com.greensock.events.LoaderEvent")]
	/** Dispatched when the <code>netStream</code> dispatches a NET_STATUS event. **/
	[Event(name="netStatus", 	type="com.greensock.events.LoaderEvent")]
/**
 * Loads an FLV, F4V, or MP4 video file using a NetStream and also provides convenient playback methods 
 * and properties like <code>pauseVideo(), playVideo(), gotoVideoTime(), bufferProgress, playProgress, volume, 
 * duration, videoPaused, metaData, </code> and <code>videoTime</code>. Just like ImageLoader and SWFLoader, 
 * VideoLoader's <code>content</code> property refers to a <code>ContentDisplay</code> object (Sprite) that 
 * gets created immediately so that you can position/scale/rotate it or add ROLL_OVER/ROLL_OUT/CLICK listeners
 * before (or while) the video loads. Use the VideoLoader's <code>content</code> property to get the ContentDisplay 
 * Sprite, or use the <code>rawContent</code> property to get the <code>Video</code> object that is used inside the 
 * ContentDisplay to display the video. If a <code>container</code> is defined in the <code>vars</code> object, 
 * the ContentDisplay will immediately be added to that container).
 * 
 * <p>You don't need to worry about creating a NetConnection, a Video object, attaching the NetStream, or any 
 * of the typical hassles. VideoLoader can even scale the video into the area you specify using scaleModes 
 * like <code>"stretch", "proportionalInside", "proportionalOutside",</code> and more. A VideoLoader will 
 * dispatch useful events like <code>VIDEO_COMPLETE, VIDEO_PAUSE, VIDEO_PLAY, VIDEO_BUFFER_FULL, 
 * VIDEO_BUFFER_EMPTY, NET_STATUS, VIDEO_CUE_POINT</code>, and <code>PLAY_PROGRESS</code> in addition 
 * to the typical loader events, making it easy to hook up your own control interface. It packs a 
 * surprising amount of functionality into a very small amount of kb.</p>
 * 
 * <p><strong>OPTIONAL VARS PROPERTIES</strong></p>
 * <p>The following special properties can be passed into the VideoLoader constructor via its <code>vars</code> 
 * parameter which can be either a generic object or a <code><a href="data/VideoLoaderVars.html">VideoLoaderVars</a></code> object:</p>
 * <ul>
 * 		<li><strong> name : String</strong> - A name that is used to identify the VideoLoader instance. This name can be fed to the <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> methods or traced at any time. Each loader's name should be unique. If you don't define one, a unique name will be created automatically, like "loader21".</li>
 * 		<li><strong> bufferTime : Number</strong> - The amount of time (in seconds) that should be buffered before the video can begin playing (set <code>autoPlay</code> to <code>false</code> to pause the video initially).</li>
 * 		<li><strong> autoPlay : Boolean</strong> - By default, the video will begin playing as soon as it has been adequately buffered, but to prevent it from playing initially, set <code>autoPlay</code> to <code>false</code>.</li>
 * 		<li><strong> smoothing : Boolean</strong> - When <code>smoothing</code> is <code>true</code> (the default), smoothing will be enabled for the video which typically leads to better scaling results.</li>
 * 		<li><strong> container : DisplayObjectContainer</strong> - A DisplayObjectContainer into which the <code>ContentDisplay</code> should be added immediately.</li>
 * 		<li><strong> width : Number</strong> - Sets the <code>ContentDisplay</code>'s <code>width</code> property (applied before rotation, scaleX, and scaleY).</li>
 * 		<li><strong> height : Number</strong> - Sets the <code>ContentDisplay</code>'s <code>height</code> property (applied before rotation, scaleX, and scaleY).</li>
 * 		<li><strong> centerRegistration : Boolean </strong> - if <code>true</code>, the registration point will be placed in the center of the <code>ContentDisplay</code> which can be useful if, for example, you want to animate its scale and have it grow/shrink from its center.</li>
 * 		<li><strong> scaleMode : String </strong> - When a <code>width</code> and <code>height</code> are defined, the <code>scaleMode</code> controls how the video will be scaled to fit the area. The following values are recognized (you may use the <code>com.greensock.layout.ScaleMode</code> constants if you prefer):
 * 			<ul>
 * 				<li><code>"stretch"</code> (the default) - The video will fill the width/height exactly.</li>
 * 				<li><code>"proportionalInside"</code> - The video will be scaled proportionally to fit inside the area defined by the width/height</li>
 * 				<li><code>"proportionalOutside"</code> - The video will be scaled proportionally to completely fill the area, allowing portions of it to exceed the bounds defined by the width/height.</li>
 * 				<li><code>"widthOnly"</code> - Only the width of the video will be adjusted to fit.</li>
 * 				<li><code>"heightOnly"</code> - Only the height of the video will be adjusted to fit.</li>
 * 				<li><code>"none"</code> - No scaling of the video will occur.</li>
 * 			</ul></li>
 * 		<li><strong> hAlign : String </strong> - When a <code>width</code> and <code>height</code> are defined, the <code>hAlign</code> determines how the video is horizontally aligned within that area. The following values are recognized (you may use the <code>com.greensock.layout.AlignMode</code> constants if you prefer):
 * 			<ul>
 * 				<li><code>"center"</code> (the default) - The video will be centered horizontally in the area</li>
 * 				<li><code>"left"</code> - The video will be aligned with the left side of the area</li>
 * 				<li><code>"right"</code> - The video will be aligned with the right side of the area</li>
 * 			</ul></li>
 * 		<li><strong> vAlign : String </strong> - When a <code>width</code> and <code>height</code> are defined, the <code>vAlign</code> determines how the video is vertically aligned within that area. The following values are recognized (you may use the <code>com.greensock.layout.AlignMode</code> constants if you prefer):
 * 			<ul>
 * 				<li><code>"center"</code> (the default) - The video will be centered vertically in the area</li>
 * 				<li><code>"top"</code> - The video will be aligned with the top of the area</li>
 * 				<li><code>"bottom"</code> - The video will be aligned with the bottom of the area</li>
 * 			</ul></li>
 * 		<li><strong> crop : Boolean</strong> - When a <code>width</code> and <code>height</code> are defined, setting <code>crop</code> to <code>true</code> will cause the video to be cropped within that area (by applying a <code>scrollRect</code> for maximum performance). This is typically useful when the <code>scaleMode</code> is <code>"proportionalOutside"</code> or <code>"none"</code> so that any parts of the video that exceed the dimensions defined by <code>width</code> and <code>height</code> are visually chopped off. Use the <code>hAlign</code> and <code>vAlign</code> special properties to control the vertical and horizontal alignment within the cropped area.</li>
 * 		<li><strong> x : Number</strong> - Sets the <code>ContentDisplay</code>'s <code>x</code> property (for positioning on the stage).</li>
 * 		<li><strong> y : Number</strong> - Sets the <code>ContentDisplay</code>'s <code>y</code> property (for positioning on the stage).</li>
 * 		<li><strong> scaleX : Number</strong> - Sets the <code>ContentDisplay</code>'s <code>scaleX</code> property.</li>
 * 		<li><strong> scaleY : Number</strong> - Sets the <code>ContentDisplay</code>'s <code>scaleY</code> property.</li>
 * 		<li><strong> rotation : Number</strong> - Sets the <code>ContentDisplay</code>'s <code>rotation</code> property.</li>
 * 		<li><strong> alpha : Number</strong> - Sets the <code>ContentDisplay</code>'s <code>alpha</code> property.</li>
 * 		<li><strong> visible : Boolean</strong> - Sets the <code>ContentDisplay</code>'s <code>visible</code> property.</li>
 * 		<li><strong> blendMode : String</strong> - Sets the <code>ContentDisplay</code>'s <code>blendMode</code> property.</li>
 * 		<li><strong> bgColor : uint </strong> - When a <code>width</code> and <code>height</code> are defined, a rectangle will be drawn inside the <code>ContentDisplay</code> immediately in order to ease the development process. It is transparent by default, but you may define a <code>bgAlpha</code> if you prefer.</li>
 * 		<li><strong> bgAlpha : Number </strong> - Controls the alpha of the rectangle that is drawn when a <code>width</code> and <code>height</code> are defined.</li>
 * 		<li><strong> volume : Number</strong> - A value between 0 and 1 indicating the volume at which the video should play (default is 1).</li>
 * 		<li><strong> repeat : int</strong> - Number of times that the video should repeat. To repeat indefinitely, use -1. Default is 0.</li>
 * 		<li><strong> stageVideo : StageVideo</strong> - By default, the NetStream gets attached to a <code>Video</code> object, but if you want to use StageVideo in Flash, you can define the <code>stageVideo</code> property and VideoLoader will attach its NetStream to that StageVideo instance instead of the regular Video instance (which is the <code>rawContent</code>). Please read Adobe's docs regarding StageVideo to understand the benefits, tradeoffs and limitations.</li>
 * 		<li><strong> checkPolicyFile : Boolean</strong> - If <code>true</code>, the VideoLoader will check for a crossdomain.xml file on the remote host (only useful when loading videos from other domains - see Adobe's docs for details about NetStream's <code>checkPolicyFile</code> property). </li>
 * 		<li><strong> estimatedDuration : Number</strong> - Estimated duration of the video in seconds. VideoLoader will only use this value until it receives the necessary metaData from the video in order to accurately determine the video's duration. You do not need to specify an <code>estimatedDuration</code>, but doing so can help make the playProgress and some other values more accurate (until the metaData has loaded). It can also make the <code>progress/bytesLoaded/bytesTotal</code> more accurate when a <code>estimatedDuration</code> is defined, particularly in <code>bufferMode</code>.</li>
 * 		<li><strong> deblocking : int</strong> - Indicates the type of filter applied to decoded video as part of post-processing. The default value is 0, which lets the video compressor apply a deblocking filter as needed. See Adobe's <code>flash.media.Video</code> class docs for details.</li>
 * 		<li><strong> bufferMode : Boolean </strong> - When <code>true</code>, the loader will report its progress only in terms of the video's buffer which can be very convenient if, for example, you want to display loading progress for the video's buffer or tuck it into a LoaderMax with other loaders and allow the LoaderMax to dispatch its <code>COMPLETE</code> event when the buffer is full instead of waiting for the whole file to download. When <code>bufferMode</code> is <code>true</code>, the VideoLoader will dispatch its <code>COMPLETE</code> event when the buffer is full as opposed to waiting for the entire video to load. You can toggle the <code>bufferMode</code> anytime. Please read the full <code>bufferMode</code> property ASDoc description below for details about how it affects things like <code>bytesTotal</code>.</li>
 * 		<li><strong> autoAdjustBuffer : Boolean </strong> If the buffer becomes empty during playback and <code>autoAdjustBuffer</code> is <code>true</code> (the default), it will automatically attempt to adjust the NetStream's <code>bufferTime</code> based on the rate at which the video has been loading, estimating what it needs to be in order to play the rest of the video without emptying the buffer again. This can prevent the annoying problem of video playback start/stopping/starting/stopping on a system tht doesn't have enough bandwidth to adequately buffer the video. You may also set the <code>bufferTime</code> in the constructor's <code>vars</code> parameter to set the initial value.</li>
 * 		<li><strong> autoDetachNetStream : Boolean</strong> - If <code>true</code>, the NetStream will only be attached to the Video object (the <code>rawContent</code>) when it is in the display list (on the stage). This conserves memory but it can cause a very brief rendering delay when the content is initially added to the stage (often imperceptible). Also, if you add it to the stage when the <code>videoTime</code> is <i>after</i> its last encoded keyframe, it will render at that last keyframe.</li>
 * 		<li><strong> alternateURL : String</strong> - If you define an <code>alternateURL</code>, the loader will initially try to load from its original <code>url</code> and if it fails, it will automatically (and permanently) change the loader's <code>url</code> to the <code>alternateURL</code> and try again. Think of it as a fallback or backup <code>url</code>. It is perfectly acceptable to use the same <code>alternateURL</code> for multiple loaders (maybe a default image for various ImageLoaders for example).</li>
 * 		<li><strong> noCache : Boolean</strong> - If <code>noCache</code> is <code>true</code>, a "gsCacheBusterID" parameter will be appended to the url with a random set of numbers to prevent caching (don't worry, this info is ignored when you <code>getLoader()</code> or <code>getContent()</code> by url and when you're running locally)</li>
 * 		<li><strong> estimatedBytes : uint</strong> - Initially, the loader's <code>bytesTotal</code> is set to the <code>estimatedBytes</code> value (or <code>LoaderMax.defaultEstimatedBytes</code> if one isn't defined). Then, when the loader begins loading and it can accurately determine the bytesTotal, it will do so. Setting <code>estimatedBytes</code> is optional, but the more accurate the value, the more accurate your loaders' overall progress will be initially. If the loader will be inserted into a LoaderMax instance (for queue management), its <code>auditSize</code> feature can attempt to automatically determine the <code>bytesTotal</code> at runtime (there is a slight performance penalty for this, however - see LoaderMax's documentation for details).</li>
 * 		<li><strong> requireWithRoot : DisplayObject</strong> - LoaderMax supports <i>subloading</i>, where an object can be factored into a parent's loading progress. If you want LoaderMax to require this VideoLoader as part of its parent SWFLoader's progress, you must set the <code>requireWithRoot</code> property to your swf's <code>root</code>. For example, <code>var loader:VideoLoader = new VideoLoader("myScript.php", {name:"textData", requireWithRoot:this.root});</code></li>
 * 		<li><strong> allowMalformedURL : Boolean</strong> - Normally, the URL will be parsed and any variables in the query string (like "?name=test&amp;state=il&amp;gender=m") will be placed into a URLVariables object which is added to the URLRequest. This avoids a few bugs in Flash, but if you need to keep the entire URL intact (no parsing into URLVariables), set <code>allowMalformedURL:true</code>. For example, if your URL has duplicate variables in the query string like <code>http://www.greensock.com/?c=S&amp;c=SE&amp;c=SW</code>, it is technically considered a malformed URL and a URLVariables object can't properly contain all the duplicates, so in this case you'd want to set <code>allowMalformedURL</code> to <code>true</code>.</li>
 * 		<li><strong> autoDispose : Boolean</strong> - When <code>autoDispose</code> is <code>true</code>, the loader will be disposed immediately after it completes (it calls the <code>dispose()</code> method internally after dispatching its <code>COMPLETE</code> event). This will remove any listeners that were defined in the vars object (like onComplete, onProgress, onError, onInit). Once a loader is disposed, it can no longer be found with <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> - it is essentially destroyed but its content is not unloaded (you must call <code>unload()</code> or <code>dispose(true)</code> to unload its content). The default <code>autoDispose</code> value is <code>false</code>.
 * 		
 * 		<p>----EVENT HANDLER SHORTCUTS----</p></li>
 * 		<li><strong> onOpen : Function</strong> - A handler function for <code>LoaderEvent.OPEN</code> events which are dispatched when the loader begins loading. Make sure your onOpen function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onInit : Function</strong> - A handler function for <code>Event.INIT</code> events which will be called when the video's metaData has been received and the video is placed into the <code>ContentDisplay</code>. The <code>INIT</code> event can be dispatched more than once if the NetStream receives metaData more than once (which occasionally happens, particularly with F4V files - the first time often doesn't include the cuePoints). Make sure your <code>onInit</code> function accepts a single parameter of type <code>Event</code> (flash.events.Event).</li>
 * 		<li><strong> onProgress : Function</strong> - A handler function for <code>LoaderEvent.PROGRESS</code> events which are dispatched whenever the <code>bytesLoaded</code> changes. Make sure your onProgress function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). You can use the LoaderEvent's <code>target.progress</code> to get the loader's progress value or use its <code>target.bytesLoaded</code> and <code>target.bytesTotal</code>.</li>
 * 		<li><strong> onComplete : Function</strong> - A handler function for <code>LoaderEvent.COMPLETE</code> events which are dispatched when the loader has finished loading successfully. Make sure your onComplete function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onCancel : Function</strong> - A handler function for <code>LoaderEvent.CANCEL</code> events which are dispatched when loading is aborted due to either a failure or because another loader was prioritized or <code>cancel()</code> was manually called. Make sure your onCancel function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onError : Function</strong> - A handler function for <code>LoaderEvent.ERROR</code> events which are dispatched whenever the loader experiences an error (typically an IO_ERROR). An error doesn't necessarily mean the loader failed, however - to listen for when a loader fails, use the <code>onFail</code> special property. Make sure your onError function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onFail : Function</strong> - A handler function for <code>LoaderEvent.FAIL</code> events which are dispatched whenever the loader fails and its <code>status</code> changes to <code>LoaderStatus.FAILED</code>. Make sure your onFail function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * 		<li><strong> onIOError : Function</strong> - A handler function for <code>LoaderEvent.IO_ERROR</code> events which will also call the onError handler, so you can use that as more of a catch-all whereas <code>onIOError</code> is specifically for LoaderEvent.IO_ERROR events. Make sure your onIOError function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
 * </ul>
 * 
 * <p><strong>Note:</strong> Using a <code><a href="data/VideoLoaderVars.html">VideoLoaderVars</a></code> instance 
 * instead of a generic object to define your <code>vars</code> is a bit more verbose but provides 
 * code hinting and improved debugging because it enforces strict data typing. Use whichever one you prefer.</p>
 * 
 * <p><strong>Note:</strong> To avoid garbage collection issues in the Flash player, the <code>netStream</code> 
 * object that VideoLoader employs must get recreated internally anytime the VideoLoader is unloaded or its loading 
 * is cancelled, so if you need to directly access the <code>netStream</code>, it is best to do so <strong>after</strong>
 * the <code>COMPLETE</code> event has been dispatched. Otherwise, if you store a reference to the VideoLoader's 
 * <code>netStream</code> before or during a load and it gets cancelled or unloaded for some reason, it won't reference 
 * the one that was used to load the video.</p>
 * 
 * <p><strong>Note:</strong> There is a bug/inconsistency in Adobe's NetStream class that causes relative URLs 
 * to use the swf's location as the base path instead of the HTML page's location like all other loaders. Therefore,
 * it would be wise to use the "base" attribute of the &lt;OBJECT&gt; and &lt;EMBED&gt; tags in the HTML to 
 * make sure all relative paths are consistent. See <a href="http://kb2.adobe.com/cps/041/tn_04157.html" target="_blank">http://kb2.adobe.com/cps/041/tn_04157.html</a>
 * for details.</p>
 * 
 * <p><strong>Note:</strong> In order to minimize memory usage, VideoLoader doesn't attach the NetStream to its Video
 * object (the <code>rawContent</code>) until it is added to the display list. Therefore, if your VideoLoader's content
 * isn't somewhere on the stage, the NetStream's visual content won't be fully decoded into memory (that's a good thing). 
 * The only time this could be of consequence is if you are trying to do a BitmapData.draw() of the VideoLoader's content 
 * or rawContent when it isn't on the stage. In that case, you'd just need to attach the NetStream manually before doing 
 * your BitmapData.draw() like <code>myVideoLoader.rawContent.attachNetStream(myVideoLoader.netStream)</code>. </p>
 * 
 * Example AS3 code:<listing version="3.0">
 import com.greensock.loading.~~;
 import com.greensock.loading.display.~~;
 import com.greensock.~~;
 import com.greensock.events.LoaderEvent;
 
//create a VideoLoader
var video:VideoLoader = new VideoLoader("assets/video.flv", {name:"myVideo", container:this, width:400, height:300, scaleMode:"proportionalInside", bgColor:0x000000, autoPlay:false, volume:0, requireWithRoot:this.root, estimatedBytes:75000});

//start loading
video.load();
 
//add a CLICK listener to a button that causes the video to toggle its paused state.
button.addEventListener(MouseEvent.CLICK, togglePause);
function togglePause(event:MouseEvent):void {
    video.videoPaused = !video.videoPaused;
}

//or you could put the VideoLoader into a LoaderMax queue. Create one first...
var queue:LoaderMax = new LoaderMax({name:"mainQueue", onProgress:progressHandler, onComplete:completeHandler, onError:errorHandler});

//append the VideoLoader and several other loaders
queue.append( video );
queue.append( new DataLoader("assets/data.txt", {name:"myText"}) );
queue.append( new ImageLoader("assets/image1.png", {name:"myImage", estimatedBytes:3500}) );

//start loading the LoaderMax queue
queue.load();

function progressHandler(event:LoaderEvent):void {
	trace("progress: " + event.target.progress);
}

function completeHandler(event:LoaderEvent):void {
	//play the video
	video.playVideo();
	
	//tween the volume up to 1 over the course of 2 seconds.
	TweenLite.to(video, 2, {volume:1});
}

function errorHandler(event:LoaderEvent):void {
	trace("error occured with " + event.target + ": " + event.text);
}
 </listing>
 * 
 * <p><strong>Copyright 2010-2012, GreenSock. All rights reserved.</strong> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for <a href="http://www.greensock.com/club/">Club GreenSock</a> members, the software agreement that was issued with the membership.</p>
 * 
 * @see com.greensock.loading.data.VideoLoaderVars
 * 
 * @author Jack Doyle, jack@greensock.com
 */	
	public class VideoLoader extends LoaderItem {
		/** @private **/
		private static var _classActivated:Boolean = _activateClass("VideoLoader", VideoLoader, "flv,f4v,mp4,mov");
		
		/** Event type constant for when the video completes. **/
		public static const VIDEO_COMPLETE:String="videoComplete";
		/** Event type constant for when the video's buffer is full. **/
		public static const VIDEO_BUFFER_FULL:String="videoBufferFull";
		/** Event type constant for when the video's buffer is empty. **/
		public static const VIDEO_BUFFER_EMPTY:String="videoBufferEmpty";
		/** Event type constant for when the video is paused. **/
		public static const VIDEO_PAUSE:String="videoPause";
		/** Event type constant for when the video begins or resumes playing. If the buffer isn't full yet when VIDEO_PLAY is dispatched, the video will wait to visually begin playing until the buffer is full. So VIDEO_PLAY indicates when the NetStream received an instruction to play, not necessarily when it visually begins playing. **/
		public static const VIDEO_PLAY:String="videoPlay";
		/** Event type constant for when the video reaches a cue point in the playback of the NetStream. **/
		public static const VIDEO_CUE_POINT:String="videoCuePoint";
		/** Event type constant for when the playback progresses (only dispatched when the video is playing). **/
		public static const PLAY_PROGRESS:String="playProgress";
		
		/** @private **/
		protected var _ns:NetStream;
		/** @private **/
		protected var _nc:NetConnection;
		/** @private **/
		protected var _auditNS:NetStream;
		/** @private **/
		protected var _video:Video;
		/** @private **/
		protected var _stageVideo:Object; //don't type as StageVideo because that would break publishing to FP9
		/** @private **/
		protected var _sound:SoundTransform;
		/** @private **/
		protected var _videoPaused:Boolean;
		/** @private **/
		protected var _videoComplete:Boolean;
		/** @private **/
		protected var _forceTime:Number;
		/** @private **/
		protected var _duration:Number;
		/** @private **/
		protected var _pausePending:Boolean;
		/** @private **/
		protected var _volume:Number;
		/** @private **/
		protected var _sprite:Sprite;
		/** @private **/
		protected var _initted:Boolean;
		/** @private **/
		protected var _bufferMode:Boolean;
		/** @private **/
		protected var _repeatCount:uint;
		/** @private **/
		protected var _bufferFull:Boolean;
		/** @private **/
		protected var _dispatchPlayProgress:Boolean;
		/** @private **/
		protected var _prevTime:Number;
		/** @private **/
		protected var _prevCueTime:Number;
		/** @private **/
		protected var _firstCuePoint:CuePoint;
		/** @private due to a bug in the NetStream class, we cannot seek() or pause() before the NetStream has dispatched a RENDER Event (or after 50ms for Flash Player 9). **/
		protected var _renderedOnce:Boolean;
		/** @private primarily used for FP9 to work around a Flash bug with seek() and pause() (see the _waitForRender() method for note). **/
		protected var _renderTimer:Timer;
		/** @private **/
		protected var _autoDetachNetStream:Boolean;
		/** @private the first VIDEO_PLAY event shouldn't be dispatched until the NetStream's NetStatusEvent fires with the code NetStream.Play.Start gets dispatched, so we track it with this Boolean variable. Otherwise, if you create a VideoLoader with autoPlay:false and then immediately load() and playVideo(), it would dispatch the VIDEO_PLAY event twice, once for the playVideo() and once when the NetStatusEvent is received. **/
		protected var _playStarted:Boolean;
		/** @private set to true as soon as the video finishes, and then is set back to false 1 ENTER_FRAME later - we use this to work around a bug in the Flash Player that causes a flicker when a seek() is called on a NetStream that just finished. **/
		protected var _finalFrame:Boolean;
		
		/** The metaData that was received from the video (contains information about its width, height, frame rate, etc.). See Adobe's docs for information about a NetStream's onMetaData callback. **/
		public var metaData:Object;
		/** If the buffer becomes empty during playback and <code>autoAdjustBuffer</code> is <code>true</code> (the default), it will automatically attempt to adjust the NetStream's <code>bufferTime</code> based on the rate at which the video has been loading, estimating what it needs to be in order to play the rest of the video without emptying the buffer again. This can prevent the annoying problem of video playback start/stopping/starting/stopping on a system tht doesn't have enough bandwidth to adequately buffer the video. You may also set the <code>bufferTime</code> in the constructor's <code>vars</code> parameter to set the initial value. **/
		public var autoAdjustBuffer:Boolean;
		
		/**
		 * Constructor
		 * 
		 * @param urlOrRequest The url (<code>String</code>) or <code>URLRequest</code> from which the loader should get its content.
		 * @param vars An object containing optional configuration details. For example: <code>new VideoLoader("video/video.flv", {name:"myVideo", onComplete:completeHandler, onProgress:progressHandler})</code>.
		 * 
		 * <p>The following special properties can be passed into the constructor via the <code>vars</code> parameter
		 * which can be either a generic object or a <code><a href="data/VideoLoaderVars.html">VideoLoaderVars</a></code> object:</p>
		 * <ul>
		 * 		<li><strong> name : String</strong> - A name that is used to identify the VideoLoader instance. This name can be fed to the <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> methods or traced at any time. Each loader's name should be unique. If you don't define one, a unique name will be created automatically, like "loader21".</li>
		 * 		<li><strong> bufferTime : Number</strong> - The amount of time (in seconds) that should be buffered before the video can begin playing (set <code>autoPlay</code> to <code>false</code> to pause the video initially).</li>
		 * 		<li><strong> autoPlay : Boolean</strong> - By default, the video will begin playing as soon as it has been adequately buffered, but to prevent it from playing initially, set <code>autoPlay</code> to <code>false</code>.</li>
		 * 		<li><strong> smoothing : Boolean</strong> - When <code>smoothing</code> is <code>true</code> (the default), smoothing will be enabled for the video which typically leads to better scaling results.</li>
		 * 		<li><strong> container : DisplayObjectContainer</strong> - A DisplayObjectContainer into which the <code>ContentDisplay</code> should be added immediately.</li>
		 * 		<li><strong> width : Number</strong> - Sets the <code>ContentDisplay</code>'s <code>width</code> property (applied before rotation, scaleX, and scaleY).</li>
		 * 		<li><strong> height : Number</strong> - Sets the <code>ContentDisplay</code>'s <code>height</code> property (applied before rotation, scaleX, and scaleY).</li>
		 * 		<li><strong> centerRegistration : Boolean </strong> - if <code>true</code>, the registration point will be placed in the center of the <code>ContentDisplay</code> which can be useful if, for example, you want to animate its scale and have it grow/shrink from its center.</li>
		 * 		<li><strong> scaleMode : String </strong> - When a <code>width</code> and <code>height</code> are defined, the <code>scaleMode</code> controls how the video will be scaled to fit the area. The following values are recognized (you may use the <code>com.greensock.layout.ScaleMode</code> constants if you prefer):
		 * 			<ul>
		 * 				<li><code>"stretch"</code> (the default) - The video will fill the width/height exactly.</li>
		 * 				<li><code>"proportionalInside"</code> - The video will be scaled proportionally to fit inside the area defined by the width/height</li>
		 * 				<li><code>"proportionalOutside"</code> - The video will be scaled proportionally to completely fill the area, allowing portions of it to exceed the bounds defined by the width/height.</li>
		 * 				<li><code>"widthOnly"</code> - Only the width of the video will be adjusted to fit.</li>
		 * 				<li><code>"heightOnly"</code> - Only the height of the video will be adjusted to fit.</li>
		 * 				<li><code>"none"</code> - No scaling of the video will occur.</li>
		 * 			</ul></li>
		 * 		<li><strong> hAlign : String </strong> - When a <code>width</code> and <code>height</code> are defined, the <code>hAlign</code> determines how the video is horizontally aligned within that area. The following values are recognized (you may use the <code>com.greensock.layout.AlignMode</code> constants if you prefer):
		 * 			<ul>
		 * 				<li><code>"center"</code> (the default) - The video will be centered horizontally in the area</li>
		 * 				<li><code>"left"</code> - The video will be aligned with the left side of the area</li>
		 * 				<li><code>"right"</code> - The video will be aligned with the right side of the area</li>
		 * 			</ul></li>
		 * 		<li><strong> vAlign : String </strong> - When a <code>width</code> and <code>height</code> are defined, the <code>vAlign</code> determines how the video is vertically aligned within that area. The following values are recognized (you may use the <code>com.greensock.layout.AlignMode</code> constants if you prefer):
		 * 			<ul>
		 * 				<li><code>"center"</code> (the default) - The video will be centered vertically in the area</li>
		 * 				<li><code>"top"</code> - The video will be aligned with the top of the area</li>
		 * 				<li><code>"bottom"</code> - The video will be aligned with the bottom of the area</li>
		 * 			</ul></li>
		 * 		<li><strong> crop : Boolean</strong> - When a <code>width</code> and <code>height</code> are defined, setting <code>crop</code> to <code>true</code> will cause the video to be cropped within that area (by applying a <code>scrollRect</code> for maximum performance). This is typically useful when the <code>scaleMode</code> is <code>"proportionalOutside"</code> or <code>"none"</code> so that any parts of the video that exceed the dimensions defined by <code>width</code> and <code>height</code> are visually chopped off. Use the <code>hAlign</code> and <code>vAlign</code> special properties to control the vertical and horizontal alignment within the cropped area.</li>
		 * 		<li><strong> x : Number</strong> - Sets the <code>ContentDisplay</code>'s <code>x</code> property (for positioning on the stage).</li>
		 * 		<li><strong> y : Number</strong> - Sets the <code>ContentDisplay</code>'s <code>y</code> property (for positioning on the stage).</li>
		 * 		<li><strong> scaleX : Number</strong> - Sets the <code>ContentDisplay</code>'s <code>scaleX</code> property.</li>
		 * 		<li><strong> scaleY : Number</strong> - Sets the <code>ContentDisplay</code>'s <code>scaleY</code> property.</li>
		 * 		<li><strong> rotation : Number</strong> - Sets the <code>ContentDisplay</code>'s <code>rotation</code> property.</li>
		 * 		<li><strong> alpha : Number</strong> - Sets the <code>ContentDisplay</code>'s <code>alpha</code> property.</li>
		 * 		<li><strong> visible : Boolean</strong> - Sets the <code>ContentDisplay</code>'s <code>visible</code> property.</li>
		 * 		<li><strong> blendMode : String</strong> - Sets the <code>ContentDisplay</code>'s <code>blendMode</code> property.</li>
		 * 		<li><strong> bgColor : uint </strong> - When a <code>width</code> and <code>height</code> are defined, a rectangle will be drawn inside the <code>ContentDisplay</code> immediately in order to ease the development process. It is transparent by default, but you may define a <code>bgAlpha</code> if you prefer.</li>
		 * 		<li><strong> bgAlpha : Number </strong> - Controls the alpha of the rectangle that is drawn when a <code>width</code> and <code>height</code> are defined.</li>
		 * 		<li><strong> volume : Number</strong> - A value between 0 and 1 indicating the volume at which the video should play (default is 1).</li>
		 * 		<li><strong> repeat : int</strong> - Number of times that the video should repeat. To repeat indefinitely, use -1. Default is 0.</li>
		 * 		<li><strong> stageVideo : StageVideo</strong> - By default, the NetStream gets attached to a <code>Video</code> object, but if you want to use StageVideo in Flash, you can define the <code>stageVideo</code> property and VideoLoader will attach its NetStream to that StageVideo instance instead of the regular Video instance (which is the <code>rawContent</code>). Please read Adobe's docs regarding StageVideo to understand the benefits, tradeoffs and limitations.</li>		
		 * 		<li><strong> checkPolicyFile : Boolean</strong> - If <code>true</code>, the VideoLoader will check for a crossdomain.xml file on the remote host (only useful when loading videos from other domains - see Adobe's docs for details about NetStream's <code>checkPolicyFile</code> property). </li>
		 * 		<li><strong> estimatedDuration : Number</strong> - Estimated duration of the video in seconds. VideoLoader will only use this value until it receives the necessary metaData from the video in order to accurately determine the video's duration. You do not need to specify an <code>estimatedDuration</code>, but doing so can help make the playProgress and some other values more accurate (until the metaData has loaded). It can also make the <code>progress/bytesLoaded/bytesTotal</code> more accurate when a <code>estimatedDuration</code> is defined, particularly in <code>bufferMode</code>.</li>
		 * 		<li><strong> deblocking : int</strong> - Indicates the type of filter applied to decoded video as part of post-processing. The default value is 0, which lets the video compressor apply a deblocking filter as needed. See Adobe's <code>flash.media.Video</code> class docs for details.</li>
		 * 		<li><strong> bufferMode : Boolean </strong> - When <code>true</code>, the loader will report its progress only in terms of the video's buffer which can be very convenient if, for example, you want to display loading progress for the video's buffer or tuck it into a LoaderMax with other loaders and allow the LoaderMax to dispatch its <code>COMPLETE</code> event when the buffer is full instead of waiting for the whole file to download. When <code>bufferMode</code> is <code>true</code>, the VideoLoader will dispatch its <code>COMPLETE</code> event when the buffer is full as opposed to waiting for the entire video to load. You can toggle the <code>bufferMode</code> anytime. Please read the full <code>bufferMode</code> property ASDoc description below for details about how it affects things like <code>bytesTotal</code>.</li>
		 * 		<li><strong> autoAdjustBuffer : Boolean </strong> If the buffer becomes empty during playback and <code>autoAdjustBuffer</code> is <code>true</code> (the default), it will automatically attempt to adjust the NetStream's <code>bufferTime</code> based on the rate at which the video has been loading, estimating what it needs to be in order to play the rest of the video without emptying the buffer again. This can prevent the annoying problem of video playback start/stopping/starting/stopping on a system tht doesn't have enough bandwidth to adequately buffer the video. You may also set the <code>bufferTime</code> in the constructor's <code>vars</code> parameter to set the initial value.</li>
		 * 		<li><strong> autoDetachNetStream : Boolean</strong> - If <code>true</code>, the NetStream will only be attached to the Video object (the <code>rawContent</code>) when it is in the display list (on the stage). This conserves memory but it can cause a very brief rendering delay when the content is initially added to the stage (often imperceptible). Also, if you add it to the stage when the <code>videoTime</code> is <i>after</i> its last encoded keyframe, it will render at that last keyframe.</li>
		 * 		<li><strong> alternateURL : String</strong> - If you define an <code>alternateURL</code>, the loader will initially try to load from its original <code>url</code> and if it fails, it will automatically (and permanently) change the loader's <code>url</code> to the <code>alternateURL</code> and try again. Think of it as a fallback or backup <code>url</code>. It is perfectly acceptable to use the same <code>alternateURL</code> for multiple loaders (maybe a default image for various ImageLoaders for example).</li>
		 * 		<li><strong> noCache : Boolean</strong> - If <code>noCache</code> is <code>true</code>, a "gsCacheBusterID" parameter will be appended to the url with a random set of numbers to prevent caching (don't worry, this info is ignored when you <code>getLoader()</code> or <code>getContent()</code> by url and when you're running locally)</li>
		 * 		<li><strong> estimatedBytes : uint</strong> - Initially, the loader's <code>bytesTotal</code> is set to the <code>estimatedBytes</code> value (or <code>LoaderMax.defaultEstimatedBytes</code> if one isn't defined). Then, when the loader begins loading and it can accurately determine the bytesTotal, it will do so. Setting <code>estimatedBytes</code> is optional, but the more accurate the value, the more accurate your loaders' overall progress will be initially. If the loader will be inserted into a LoaderMax instance (for queue management), its <code>auditSize</code> feature can attempt to automatically determine the <code>bytesTotal</code> at runtime (there is a slight performance penalty for this, however - see LoaderMax's documentation for details).</li>
		 * 		<li><strong> requireWithRoot : DisplayObject</strong> - LoaderMax supports <i>subloading</i>, where an object can be factored into a parent's loading progress. If you want LoaderMax to require this VideoLoader as part of its parent SWFLoader's progress, you must set the <code>requireWithRoot</code> property to your swf's <code>root</code>. For example, <code>var loader:VideoLoader = new VideoLoader("myScript.php", {name:"textData", requireWithRoot:this.root});</code></li>
		 * 		<li><strong> allowMalformedURL : Boolean</strong> - Normally, the URL will be parsed and any variables in the query string (like "?name=test&amp;state=il&amp;gender=m") will be placed into a URLVariables object which is added to the URLRequest. This avoids a few bugs in Flash, but if you need to keep the entire URL intact (no parsing into URLVariables), set <code>allowMalformedURL:true</code>. For example, if your URL has duplicate variables in the query string like <code>http://www.greensock.com/?c=S&amp;c=SE&amp;c=SW</code>, it is technically considered a malformed URL and a URLVariables object can't properly contain all the duplicates, so in this case you'd want to set <code>allowMalformedURL</code> to <code>true</code>.</li>
		 * 		<li><strong> autoDispose : Boolean</strong> - When <code>autoDispose</code> is <code>true</code>, the loader will be disposed immediately after it completes (it calls the <code>dispose()</code> method internally after dispatching its <code>COMPLETE</code> event). This will remove any listeners that were defined in the vars object (like onComplete, onProgress, onError, onInit). Once a loader is disposed, it can no longer be found with <code>LoaderMax.getLoader()</code> or <code>LoaderMax.getContent()</code> - it is essentially destroyed but its content is not unloaded (you must call <code>unload()</code> or <code>dispose(true)</code> to unload its content). The default <code>autoDispose</code> value is <code>false</code>.
		 * 		
		 * 		<p>----EVENT HANDLER SHORTCUTS----</p></li>
		 * 		<li><strong> onOpen : Function</strong> - A handler function for <code>LoaderEvent.OPEN</code> events which are dispatched when the loader begins loading. Make sure your onOpen function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onInit : Function</strong> - A handler function for <code>Event.INIT</code> events which will be called when the video's metaData has been received and the video is placed into the <code>ContentDisplay</code>. The <code>INIT</code> event can be dispatched more than once if the NetStream receives metaData more than once (which occasionally happens, particularly with F4V files - the first time often doesn't include the cuePoints). Make sure your <code>onInit</code> function accepts a single parameter of type <code>Event</code> (flash.events.Event).</li>
		 * 		<li><strong> onProgress : Function</strong> - A handler function for <code>LoaderEvent.PROGRESS</code> events which are dispatched whenever the <code>bytesLoaded</code> changes. Make sure your onProgress function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>). You can use the LoaderEvent's <code>target.progress</code> to get the loader's progress value or use its <code>target.bytesLoaded</code> and <code>target.bytesTotal</code>.</li>
		 * 		<li><strong> onComplete : Function</strong> - A handler function for <code>LoaderEvent.COMPLETE</code> events which are dispatched when the loader has finished loading successfully. Make sure your onComplete function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onCancel : Function</strong> - A handler function for <code>LoaderEvent.CANCEL</code> events which are dispatched when loading is aborted due to either a failure or because another loader was prioritized or <code>cancel()</code> was manually called. Make sure your onCancel function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onError : Function</strong> - A handler function for <code>LoaderEvent.ERROR</code> events which are dispatched whenever the loader experiences an error (typically an IO_ERROR). An error doesn't necessarily mean the loader failed, however - to listen for when a loader fails, use the <code>onFail</code> special property. Make sure your onError function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onFail : Function</strong> - A handler function for <code>LoaderEvent.FAIL</code> events which are dispatched whenever the loader fails and its <code>status</code> changes to <code>LoaderStatus.FAILED</code>. Make sure your onFail function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * 		<li><strong> onIOError : Function</strong> - A handler function for <code>LoaderEvent.IO_ERROR</code> events which will also call the onError handler, so you can use that as more of a catch-all whereas <code>onIOError</code> is specifically for LoaderEvent.IO_ERROR events. Make sure your onIOError function accepts a single parameter of type <code>LoaderEvent</code> (<code>com.greensock.events.LoaderEvent</code>).</li>
		 * </ul>
		 * @see com.greensock.loading.data.VideoLoaderVars
		 */
		public function VideoLoader(urlOrRequest:*, vars:Object=null) {
			super(urlOrRequest, vars);
			_type = "VideoLoader";
			_nc = new NetConnection();
			_nc.connect(null);
			_nc.addEventListener("asyncError", _failHandler, false, 0, true);
			_nc.addEventListener("securityError", _failHandler, false, 0, true);
			
			_renderTimer = new Timer(80, 0);
			_renderTimer.addEventListener(TimerEvent.TIMER, _renderHandler, false, 0, true);
			
			_video = new Video(this.vars.width || 320, this.vars.height || 240);
			_video.smoothing = Boolean(this.vars.smoothing != false);
			_video.deblocking = uint(this.vars.deblocking);
			//the video isn't decoded into memory fully until the NetStream is attached to the Video object. We only attach it when it is in the display list (thus can be seen) in order to conserve memory.
			_video.addEventListener(Event.ADDED_TO_STAGE, _videoAddedToStage, false, 0, true);
			_video.addEventListener(Event.REMOVED_FROM_STAGE, _videoRemovedFromStage, false, 0, true);
			
			_stageVideo = this.vars.stageVideo;
			
			_autoDetachNetStream = Boolean(this.vars.autoDetachNetStream == true);
			
			_refreshNetStream();
			
			_duration = isNaN(this.vars.estimatedDuration) ? 200 : Number(this.vars.estimatedDuration); //just set it to a high number so that the progress starts out low.
			_bufferMode = _preferEstimatedBytesInAudit = Boolean(this.vars.bufferMode == true);
			_videoPaused = _pausePending = Boolean(this.vars.autoPlay == false);
			this.autoAdjustBuffer = !(this.vars.autoAdjustBuffer == false);
			
			this.volume = ("volume" in this.vars) ? Number(this.vars.volume) : 1;
			
			if (LoaderMax.contentDisplayClass is Class) {
				_sprite = new LoaderMax.contentDisplayClass(this);
				if (!_sprite.hasOwnProperty("rawContent")) {
					throw new Error("LoaderMax.contentDisplayClass must be set to a class with a 'rawContent' property, like com.greensock.loading.display.ContentDisplay");
				}
			} else {
				_sprite = new ContentDisplay(this);
			}
			
			Object(_sprite).rawContent = null; //so that the video doesn't initially show at the wrong size before the metaData is received at which point we can accurately determine the aspect ratio.
		}
		
		/** @private **/
		protected function _refreshNetStream():void {
			if (_ns != null) {
				_ns.pause();
				try {
					_ns.close();
				} catch (error:Error) {
					
				}
				_sprite.removeEventListener(Event.ENTER_FRAME, _playProgressHandler);
				_video.attachNetStream(null);
				_video.clear();
				_ns.client = {};
				_ns.removeEventListener(NetStatusEvent.NET_STATUS, _statusHandler);
				_ns.removeEventListener("ioError", _failHandler);
				_ns.removeEventListener("asyncError", _failHandler);
				_ns.removeEventListener(Event.RENDER, _renderHandler);
			}
			_prevTime = _prevCueTime = 0;
			
			_ns = (this.vars.netStream is NetStream) ? this.vars.netStream : new NetStream(_nc);
			_ns.checkPolicyFile = Boolean(this.vars.checkPolicyFile == true);
			_ns.client = {onMetaData:_metaDataHandler, onCuePoint:_cuePointHandler};
			
			_ns.addEventListener(NetStatusEvent.NET_STATUS, _statusHandler, false, 0, true);
			_ns.addEventListener("ioError", _failHandler, false, 0, true);
			_ns.addEventListener("asyncError", _failHandler, false, 0, true); 
			
			_ns.bufferTime = isNaN(this.vars.bufferTime) ? 5 : Number(this.vars.bufferTime);
			
			if (_stageVideo != null) {
				_stageVideo.attachNetStream(_ns);
			} else if (!_autoDetachNetStream || _video.stage != null) {
				_video.attachNetStream(_ns);
			}
			
			_sound = _ns.soundTransform;
		}
		
		/** @private **/
		override protected function _load():void {
			_prepRequest();
			_repeatCount = 0;
			_prevTime = _prevCueTime = 0;
			_bufferFull = _playStarted = _renderedOnce = false;
			this.metaData = null;
			_pausePending = _videoPaused;
			if (_videoPaused) {
				_setForceTime(0);
				_sound.volume = 0;
				_ns.soundTransform = _sound; //temporarily silence the audio because in some cases, the Flash Player will begin playing it for a brief second right before the buffer is full (we can't pause until then)
			} else {
				this.volume = _volume; //ensures the volume is back to normal in case it had been temporarily silenced while buffering
			}
			_sprite.addEventListener(Event.ENTER_FRAME, _playProgressHandler);
			_sprite.addEventListener(Event.ENTER_FRAME, _loadingProgressCheck);
			_waitForRender();
			_videoComplete = _initted = false;
			if (this.vars.noCache && (!_isLocal || _url.substr(0, 4) == "http") && _request.data != null) {
				var concatChar:String = (_request.url.indexOf("?") != -1) ? "&" : "?";
				_ns.play( _request.url + concatChar + _request.data.toString() );
			} else {
				_ns.play(_request.url);
			}
		}
		
		/** @private scrubLevel: 0 = cancel, 1 = unload, 2 = dispose, 3 = flush **/
		override protected function _dump(scrubLevel:int=0, newStatus:int=0, suppressEvents:Boolean=false):void {
			if (_sprite == null) {
				return; //already disposed!
			}
			_sprite.removeEventListener(Event.ENTER_FRAME, _loadingProgressCheck);
			_sprite.removeEventListener(Event.ENTER_FRAME, _playProgressHandler);
			_sprite.removeEventListener(Event.ENTER_FRAME, _detachNS);
			_sprite.removeEventListener(Event.ENTER_FRAME, _finalFrameFinished);
			_ns.removeEventListener(Event.RENDER, _renderHandler);
			_renderTimer.stop();
			_forceTime = NaN;
			_prevTime = _prevCueTime = 0;
			_initted = false;
			_renderedOnce = false;
			_videoComplete = false;
			this.metaData = null;
			if (scrubLevel != 2) {
				_refreshNetStream();
				(_sprite as Object).rawContent = null;
				if (_video.parent != null) {
					_video.parent.removeChild(_video);
				}
			}
				
			if (scrubLevel >= 2) {
				
				if (scrubLevel == 3) {
					(_sprite as Object).dispose(false, false);
				}
				
				_renderTimer.removeEventListener(TimerEvent.TIMER, _renderHandler);
				_nc.removeEventListener("asyncError", _failHandler);
				_nc.removeEventListener("securityError", _failHandler);
				_ns.removeEventListener(NetStatusEvent.NET_STATUS, _statusHandler);
				_ns.removeEventListener("ioError", _failHandler);
				_ns.removeEventListener("asyncError", _failHandler);
				_video.removeEventListener(Event.ADDED_TO_STAGE, _videoAddedToStage);
				_video.removeEventListener(Event.REMOVED_FROM_STAGE, _videoRemovedFromStage);
				_firstCuePoint = null;
				
				(_sprite as Object).gcProtect = (scrubLevel == 3) ? null : _ns; //we need to reference the NetStream in the ContentDisplay before forcing garbage collection, otherwise gc kills the NetStream even if it's attached to the Video and is playing on the stage!
				_ns.client = {};
				_video = null;
				_ns = null;
				_nc = null;
				_sound = null;
				(_sprite as Object).loader = null;
				_sprite = null;
				_renderTimer = null;
			} else {
				_duration = isNaN(this.vars.estimatedDuration) ? 200 : Number(this.vars.estimatedDuration); //just set it to a high number so that the progress starts out low.
				_videoPaused = _pausePending = Boolean(this.vars.autoPlay == false);
			}
			super._dump(scrubLevel, newStatus, suppressEvents);
		}
		
		/** @private Set inside ContentDisplay's or FlexContentDisplay's "loader" setter. **/
		public function setContentDisplay(contentDisplay:Sprite):void {
			_sprite = contentDisplay;
		}
		
		/** @inheritDoc **/
		override public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false):void {
			if (type == PLAY_PROGRESS) {
				_dispatchPlayProgress = true;
			}
			super.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		/** @private **/
		override protected function _calculateProgress():void {
			_cachedBytesLoaded = _ns.bytesLoaded;
			if (_cachedBytesLoaded > 1) {
				if (_bufferMode) {
					_cachedBytesTotal = _ns.bytesTotal * (_ns.bufferTime / _duration);
					if (_ns.bufferLength > 0) {
						_cachedBytesLoaded = (_ns.bufferLength / _ns.bufferTime) * _cachedBytesTotal;
					}
				} else {
					_cachedBytesTotal = _ns.bytesTotal;
				}
				if (_cachedBytesTotal <= _cachedBytesLoaded) {
					_cachedBytesTotal = ((this.metaData != null && _renderedOnce && _initted) || (getTimer() - _time >= 10000)) ? _cachedBytesLoaded : int(1.01 * _cachedBytesLoaded) + 1; //make sure the metaData has been received because if the NetStream file is cached locally sometimes the bytesLoaded == bytesTotal BEFORE the metaData arrives. Or timeout after 10 seconds.
				}
				if (!_auditedSize) {
					_auditedSize = true;
					dispatchEvent(new Event("auditedSize"));
				}
			}
			_cacheIsDirty = false;
		}
		
		/**
		 * Adds an ActionScript cue point. Cue points are only triggered when the video is playing and passes
		 * the cue point's position in the video (in the forwards direction - they are not triggered when you skip
		 * to a previous time in the video with <code>gotoVideoTime()</code>). 
		 * 
		 * <p>For example, to add a cue point named "coolPart" at the 5-second point of the video, do:</p>
		 * 
		 * <listing version="3.0">
myVideoLoader.addASCuePoint(5, "coolPart", {message:"This is a cool part.", id:5}); 
myVideoLoader.addEventListener(VideoLoader.VIDEO_CUE_POINT, cuePointHandler); 
function cuePointHandler(event:LoaderEvent):void { 
	trace("hit cue point " + event.data.name + ", message: " + event.data.parameters.message); 
}
</listing>
		 * 
		 * @param time The time (in seconds) at which the cue point should be placed in the video. 
		 * @param name The name of the cue point. It is acceptable to have multiple cue points with the same name.
		 * @param parameters An object containing any data that you want associated with the cue point. For example, <code>{message:"descriptive text", id:5}</code>. This data can be retrieved in the VIDEO_CUE_POINT handler via the LoaderEvent's <code>data</code> property like <code>event.data.parameters</code>
		 * @return The cue point that was added
		 * @see #removeASCuePoint()
		 * @see #gotoVideoCuePoint()
		 * @see #getCuePointTime()
		 */
		public function addASCuePoint(time:Number, name:String="", parameters:Object=null):Object {
			var prev:CuePoint = _firstCuePoint;
			if (prev != null && prev.time > time) {
				prev = null;
			} else {
				while (prev && prev.time <= time && prev.next && prev.next.time <= time) {
					prev = prev.next;
				}
			}
			var cp:CuePoint = new CuePoint(time, name, parameters, prev);
			if (prev == null) {
				if (_firstCuePoint != null) {
					_firstCuePoint.prev = cp;
					cp.next = _firstCuePoint;
				}
				_firstCuePoint = cp;
			}
			return cp;
		}
		
		/**
		 * Removes an ActionScript cue point that was added with <code>addASCuePoint()</code>. If multiple ActionScript
		 * cue points match the search criteria, only one is removed. To remove all, call this function repeatedly in a 
		 * loop with the same parameters until it returns null. 
		 * 
		 * @param timeNameOrCuePoint The time, name or cue point object that should be removed. The method removes the first cue point that matches the criteria. 
		 * @return The cue point that was removed (or <code>null</code> if none were found that match the criteria)
		 * @see #addASCuePoint()
		 */
		public function removeASCuePoint(timeNameOrCuePoint:*):Object {
			var cp:CuePoint = _firstCuePoint;
			while (cp) {
				if (cp == timeNameOrCuePoint || cp.time == timeNameOrCuePoint || cp.name == timeNameOrCuePoint) {
					if (cp.next) {
						cp.next.prev = cp.prev;
					}
					if (cp.prev) {
						cp.prev.next = cp.next;
					} else if (cp == _firstCuePoint) {
						_firstCuePoint = cp.next;
					}
					cp.next = cp.prev = null;
					cp.gc = true;
					return cp;
				}
				cp = cp.next;
			}
			return null;
		}
		
		/**
		 * Finds a cue point by name and returns its corresponding time (where it is positioned in the video). 
		 * All cue points will be included in the search (cue points embedded into the video when it was encoded
		 * as well as cue points that were added with <code>addASCuePoint()</code>).
		 * 
		 * @param name The name of the cue point
		 * @return The cue point's time (NaN if no cue point was found with the specified name)
		 * @see #addASCuePoint()
		 * @see #gotoVideoCuePoint()
		 * @see #gotoVideoTime()
		 */
		public function getCuePointTime(name:String):Number {
			if (this.metaData != null && this.metaData.cuePoints is Array) {
				var i:int = this.metaData.cuePoints.length;
				while (--i > -1) { 
					if (name == this.metaData.cuePoints[i].name) {
						return Number(this.metaData.cuePoints[i].time);
					}
				}
			}
			var cp:CuePoint = _firstCuePoint;
			while (cp) {
				if (cp.name == name) {
					return cp.time;
				}
				cp = cp.next;
			}
			return NaN;
		}
		
		/**
		 * Attempts to jump to a certain cue point (either a cue point that was embedded in the
		 * video itself when it was encoded or a cue point that was added via <code>addASCuePoint()</code>). 
		 * If the video hasn't downloaded enough to get to the cue point or if there is no keyframe at that 
		 * point in the video, it will get as close as possible. For example, to jump to a cue point
		 * named "highlight1" and play from there:<p><code>
		 * 
		 * loader.gotoVideoCuePoint("highlight1", true);</code></p>
		 * 
		 * @param name The name of the cue point
		 * @param forcePlay If <code>true</code>, the video will resume playback immediately after seeking to the new position.
		 * @param skipCuePoints If <code>true</code> (the default), any cue points that are positioned between the current videoTime and the destination cue point will be ignored when moving to the new videoTime. In other words, it is like a record player that has its needle picked up, moved, and dropped into a new position rather than dragging it across the record, triggering the various cue points (if any exist there). IMPORTANT: cue points are only triggered when the time advances in the forward direction; they are never triggered when rewinding or restarting. 
		 * @return The cue point's time (NaN if the cue point wasn't found)
		 * @see #gotoVideoTime()
		 * @see #addASCuePoint()
		 * @see #removeASCuePoint()
		 */
		public function gotoVideoCuePoint(name:String, forcePlay:Boolean=false, skipCuePoints:Boolean=true):Number {
			return gotoVideoTime(getCuePointTime(name), forcePlay, skipCuePoints);
		}
		
		/** 
		 * Pauses playback of the video. 
		 * 
		 * @param event An optional Event which simply makes it easier to use the method as a handler for mouse clicks or other events.
		 * 
		 * @see #videoPaused
		 * @see #gotoVideoTime()
		 * @see #playVideo()
		 * @see #videoTime
		 * @see #playProgress
		 **/
		public function pauseVideo(event:Event=null):void {
			this.videoPaused = true;
		}
		
		/** 
		 * Plays the video (if the buffer isn't full yet, playback will wait until the buffer is full).
		 * 
		 * @param event An optional Event which simply makes it easier to use the method as a handler for mouse clicks or other events.
		 * 
		 * @see #videoPaused
		 * @see #pauseVideo()
		 * @see #gotoVideoTime()
		 * @see #videoTime
		 * @see #playProgress
		 **/
		public function playVideo(event:Event=null):void {
			this.videoPaused = false;
		}
		
		/** 
		 * Attempts to jump to a certain time in the video. If the video hasn't downloaded enough to get to
		 * the new time or if there is no keyframe at that time value, it will get as close as possible.
		 * For example, to jump to exactly 3-seconds into the video and play from there:<p><code>
		 * 
		 * loader.gotoVideoTime(3, true);</code></p>
		 * 
		 * <p>The VideoLoader's <code>videoTime</code> will immediately reflect the new time, but <code>PLAY_PROGRESS</code> 
		 * event won't be dispatched until the NetStream's <code>time</code> renders at that spot (which can take a frame or so).</p>
		 * 
		 * @param time The time (in seconds, offset from the very beginning) at which to place the virtual playhead on the video.
		 * @param forcePlay If <code>true</code>, the video will resume playback immediately after seeking to the new position.
		 * @param skipCuePoints If <code>true</code> (the default), any cue points that are positioned between the current videoTime and the destination time (defined by the <code>time</code> parameter) will be ignored when moving to the new videoTime. In other words, it is like a record player that has its needle picked up, moved, and dropped into a new position rather than dragging it across the record, triggering the various cue points (if any exist there). IMPORTANT: cue points are only triggered when the time advances in the forward direction; they are never triggered when rewinding or restarting. 
		 * @see #pauseVideo()
		 * @see #playVideo()
		 * @see #videoTime
		 * @see #playProgress
		 **/
		public function gotoVideoTime(time:Number, forcePlay:Boolean=false, skipCuePoints:Boolean=true):Number {
			if (isNaN(time) || _ns == null) {
				return NaN;
			} else if (time > _duration) {
				time = _duration;
			}
			var changed:Boolean = (time != this.videoTime);
			if (_initted && _renderedOnce && changed && !_finalFrame) { //don't seek() until metaData has been received otherwise it can prevent it from ever being received. Also, if the NetStream hasn't rendered once and we seek(), it often completely loses its audio!
				_seek(time);
			} else {
				_setForceTime(time);
			}
			_videoComplete = false;
			if (changed) {
				if (skipCuePoints) {
					_prevCueTime = time;
				} else {
					_playProgressHandler(null);
				}
			}
			if (forcePlay) {
				playVideo();
			}
			return time;
		}
		
		/** Clears the video from the rawContent (the Video object). This also works around a bug in Adobe's <code>Video</code> class that prevents clear() from working properly in some versions of the Flash Player (https://bugs.adobe.com/jira/browse/FP-178). Note that this does not detatch the NetStream - it simply deletes the currently displayed image/frame, so you'd want to make sure the video is paused or finished before calling <code>clearVideo()</code>. **/
		public function clearVideo():void {
			_video.smoothing = false; //a bug in Adobe's Video class causes it to not fully clear the video unless smoothing is set to false first. https://bugs.adobe.com/jira/browse/FP-178
			_video.clear();
			_video.smoothing = (this.vars.smoothing != false);
			_video.clear(); //we need to call it a second time after the smoothing is changed, otherwise it doesn't work in some later versions of the player! 
		}
		
		/** @protected **/
		protected function _seek(time:Number):void {
			_ns.seek(time);
			_setForceTime(time);
			if (_bufferFull) {
				_bufferFull = false;
				dispatchEvent(new LoaderEvent(VIDEO_BUFFER_EMPTY, this));
			}
		}
		
		/** @private **/
		protected function _setForceTime(time:Number):void {
			if (!(_forceTime || _forceTime == 0)) { //if _forceTime is already set, the listener was already added (we remove it after 1 frame or after the buffer fills for the first time and metaData is received (whichever takes longer)
				_waitForRender(); //if, for example, after a video has finished playing, we seek(0) the video and immediately check the playProgress, it returns 1 instead of 0 because it takes a short time to render the first frame and accurately reflect the _ns.time variable. So we use a single ENTER_FRAME to help us override the _ns.time value briefly.
			}
			_forceTime = time;
		}
		
		/** @private **/
		protected function _waitForRender():void {
			_ns.addEventListener(Event.RENDER, _renderHandler, false, 0, true); //only works in Flash Player 10 and later
			_renderTimer.reset();
			_renderTimer.start(); //backup for Flash Player 9
		}
		
		/** @private **/
		protected function _onBufferFull():void {
			if (!_renderedOnce && !_renderTimer.running) { //in Flash Player 9, NetStream doesn't dispatch the RENDER event and the only reliable way I could find to sense when a render truly must have occured is to wait about 50 milliseconds after the buffer fills. Even waiting for an ENTER_FRAME event wouldn't work consistently (depending on the frame rate). Also, depending on the version of Flash that published the swf, the NetStream's NetStream.Buffer.Full status event may not fire (CS3 and CS4)!
				_waitForRender();
				return;
			}
			if (_pausePending) {
				if (!_initted && getTimer() - _time < 10000) {
					_video.attachNetStream(null); //in some rare circumstances, the NetStream will finish buffering even before the metaData has been received. If we pause() the NetStream before the metaData arrives, it can prevent the metaData from ever arriving (bug in Flash) even after you resume(). So in this case, we allow the NetStream to continue playing so that metaData can be received, but we detach it from the Video object so that the user doesn't see the video playing. The volume is also muted, so to the user things look paused even though the NetStream is continuing to play/load. We'll re-attach the NetStream to the Video after either the metaData arrives or 10 seconds elapse.
				} else if (_renderedOnce) {
					_applyPendingPause();
				}
			} else if (!_bufferFull) {
				_bufferFull = true;
				dispatchEvent(new LoaderEvent(VIDEO_BUFFER_FULL, this));
			}
		}
		
		/** @private **/
		protected function _applyPendingPause():void {
			_pausePending = false;
			this.volume = _volume; //Just resets the volume to where it should be because we temporarily made it silent during the buffer.
			_seek(_forceTime || 0);
			if (_stageVideo != null) {
				_stageVideo.attachNetStream(_ns);
				_ns.pause();
			} else if (!_autoDetachNetStream || _video.stage != null) {
				_video.cacheAsBitmap = false; //works around an odd bug in Flash that can cause the video not to render when it is attached and paused immediately. 
				_video.attachNetStream(_ns); //in case it was removed
				_ns.pause(); //If we pause() the NetStream when it isn't attached to the _video, a bug in Flash causes it to act like it continues playing!!!
			}
		}
		
		/** @private **/
		protected function _forceInit():void {
			if (_ns.bufferTime >= _duration) {
				_ns.bufferTime = uint(_duration - 1);
			}
			_initted = true;
			if (!_bufferFull && _ns.bufferLength >= _ns.bufferTime) {
				_onBufferFull();
			}
			Object(_sprite).rawContent = _video; //resizes it appropriately
			if (!_bufferFull && _pausePending && _renderedOnce && _video.stage != null) {
				_video.attachNetStream(null); //if the NetStream is still buffering, there's a good chance that the video will appear to play briefly right before we pause it, so we detach the NetStream from the Video briefly to avoid that funky visual behavior (we attach it again as soon as it buffers).
			} else if (_stageVideo != null) {
				_stageVideo.attachNetStream(_ns);
			} else if (!_autoDetachNetStream || _video.stage != null) {
				_video.attachNetStream(_ns);
			}
		}
		
		
//---- EVENT HANDLERS ------------------------------------------------------------------------------------
		
		/** @private **/
		protected function _metaDataHandler(info:Object):void {
			if (this.metaData == null || this.metaData.cuePoints == null) { //sometimes videos will trigger the onMetaData multiple times (especially F4V files) and occassionally the last call doesn't contain cue point data!
				this.metaData = info;
			}
			_duration = info.duration;
			if ("width" in info) {
				_video.width = Number(info.width); 
				_video.height = Number(info.height);
			} 
			if ("framerate" in info) {
				_renderTimer.delay = int(1000 / Number(info.framerate) + 1); 
			}
			if (!_initted) {
				_forceInit();
			} else {
				(_sprite as Object).rawContent = _video; //on rare occasions, _metaDataHandler() is called twice by the NeStream (particularly for F4V files) and the 2nd call contains more data than the first, so just in case the width/height changed, we set the rawContent of the ContentDisplay to make sure things render according to the correct size.
			}
			dispatchEvent(new LoaderEvent(LoaderEvent.INIT, this, "", info));
		}
		
		/** @private **/
		protected function _cuePointHandler(info:Object):void {
			if (!_videoPaused) { //in case there's a cue point very early on and autoPlay was set to false - remember, to work around bugs in NetStream, we cannot pause() it until we receive metaData and the first frame renders.
				dispatchEvent(new LoaderEvent(VIDEO_CUE_POINT, this, "", info));
			}
		}
		
		/** @private **/
		protected function _playProgressHandler(event:Event):void {
			if (!_bufferFull && !_videoComplete && (_ns.bufferLength >= _ns.bufferTime || this.duration - this.videoTime - _ns.bufferLength < 0.1)) { //remember, bufferLength could be less than bufferTime if videoTime is towards the end of the video and there's less time remaining to play than there is bufferTime. 
				_onBufferFull();
			}
			if (_bufferFull && (_firstCuePoint || _dispatchPlayProgress)) { 
				var prevTime:Number = _prevTime,
					prevCueTime:Number = _prevCueTime;
				_prevTime = _prevCueTime = ((_forceTime || _forceTime == 0) && _ns.time <= _duration) ? _ns.time : this.videoTime; //note: isNaN(_forceTime) is much slower than !(_forceTime || _forceTime == 0)
				var next:CuePoint,
					cp:CuePoint = _firstCuePoint;
				while (cp) {
					next = cp.next;
					if (cp.time > prevCueTime && cp.time <= _prevCueTime && !cp.gc) {
						dispatchEvent(new LoaderEvent(VIDEO_CUE_POINT, this, "", cp));
					}
					cp = next;
				}
				if (_dispatchPlayProgress && prevTime != _prevTime) {
					dispatchEvent(new LoaderEvent(PLAY_PROGRESS, this));
				}
			}
		}
		
		/** @private **/
		protected function _statusHandler(event:NetStatusEvent):void {
			var code:String = event.info.code;
			if (code == "NetStream.Play.Start" && !_playStarted) { //remember, NetStream.Play.Start can be received BEFORE the buffer is full.
				_playStarted = true;
				if (!_pausePending) {
					dispatchEvent(new LoaderEvent(VIDEO_PLAY, this));
				}
			}
			dispatchEvent(new LoaderEvent(NetStatusEvent.NET_STATUS, this, code, event.info));
			if (code == "NetStream.Play.Stop") {
				if (_videoPaused) {
					return; //Can happen when we seek() to a time in the video between the last keyframe and the end of the video file - NetStream.Play.Stop gets received even though the NetStream was paused.
				}
				_finalFrame = true;
				_sprite.addEventListener(Event.ENTER_FRAME, _finalFrameFinished, false, 100, true);
				if (this.vars.repeat == -1 || uint(this.vars.repeat) > _repeatCount) {
					_repeatCount++;
					dispatchEvent(new LoaderEvent(VIDEO_COMPLETE, this));
					gotoVideoTime(0, !_videoPaused, true);
				} else {
					_videoComplete = true;
					this.videoPaused = true;
					_playProgressHandler(null);
					dispatchEvent(new LoaderEvent(VIDEO_COMPLETE, this));
				}
			} else if (code == "NetStream.Buffer.Full") {
				_onBufferFull();
			} else if (code == "NetStream.Seek.Notify") {
				if (!_autoDetachNetStream && !isNaN(_forceTime)) {
					_renderHandler(null); //note: do not _ns.pause() here when the NetStream isn't attached to the _video because a bug in Flash will prevent it from working (just when this NetStreamEvent occurs!)
				}
				//previously called _playProgressHandler(null) but a bug in NetStream often causes its time property not to report its correct (new) position yet, so we just wait to call _playProgressHandler() until the next frame.
			} else if (code == "NetStream.Seek.InvalidTime" && "details" in event.info) {
				_seek(event.info.details);
			} else if (code == "NetStream.Buffer.Empty" && !_videoComplete) {
				var videoRemaining:Number = this.duration - this.videoTime;
				var prevBufferMode:Boolean = _bufferMode;
				_bufferMode = false; //make sure bufferMode is false so that when we check progress, it gives us the data we need.
				_cacheIsDirty = true;
				var prog:Number = this.progress;
				_bufferMode = prevBufferMode;
				_cacheIsDirty = true;
				if (prog == 1) {
					//sometimes NetStream dispatches a "NetStream.Buffer.Empty" NetStatusEvent right before it finishes playing in which case we can deduce that the buffer isn't really empty.
					return;
				}
				var loadRemaining:Number = (1 / prog) * this.loadTime;
				var revisedBufferTime:Number = videoRemaining * (1 - (videoRemaining / loadRemaining)) * 0.9; //90% of the estimated time because typically you'd want the video to start playing again sooner and the 10% might be made up while it's playing anyway.
				if (this.autoAdjustBuffer && loadRemaining > videoRemaining) {
					_ns.bufferTime = revisedBufferTime;
				}
				_bufferFull = false;
				dispatchEvent(new LoaderEvent(VIDEO_BUFFER_EMPTY, this));
			} else if (code == "NetStream.Play.StreamNotFound" || 
					   code == "NetConnection.Connect.Failed" ||
					   code == "NetStream.Play.Failed" ||
					   code == "NetStream.Play.FileStructureInvalid" || 
					   code == "The MP4 doesn't contain any supported tracks") {
				_failHandler(new LoaderEvent(LoaderEvent.ERROR, this, code));
			}
		}
		
		/** @private **/
		protected function _finalFrameFinished(event:Event):void {
			_sprite.removeEventListener(Event.ENTER_FRAME, _finalFrameFinished);
			_finalFrame = false;
			if (!isNaN(_forceTime)) {
				_seek(_forceTime);
			}
		}
		
		/** @private **/
		protected function _loadingProgressCheck(event:Event):void {
			var bl:uint = _cachedBytesLoaded;
			var bt:uint = _cachedBytesTotal;
			if (!_bufferFull && _ns.bufferLength >= _ns.bufferTime) {
				_onBufferFull();
			}
			_calculateProgress();
			if (_cachedBytesLoaded == _cachedBytesTotal) { 
				_sprite.removeEventListener(Event.ENTER_FRAME, _loadingProgressCheck);
				if (!_bufferFull) {
					_onBufferFull();
				}
				if (!_initted) {
					_forceInit();
					_errorHandler(new LoaderEvent(LoaderEvent.ERROR, this, "No metaData was received."));
				}
				_completeHandler(event);
			} else if (_dispatchProgress && (_cachedBytesLoaded / _cachedBytesTotal) != (bl / bt)) {
				dispatchEvent(new LoaderEvent(LoaderEvent.PROGRESS, this));
			}
		}
		
		/** @inheritDoc 
		 * Flash has a bug/inconsistency that causes NetStreams to load relative URLs as being relative to the swf file itself
		 * rather than relative to the HTML file in which it is embedded (all other loaders exhibit the opposite behavior), so 
		 * we need to make sure the audits use NetStreams instead of URLStreams (for relative urls at least). 
		 **/
		override public function auditSize():void {
			if (_url.substr(0, 4) == "http" && _url.indexOf("://") != -1) { //if the url isn't relative, use the regular URLStream to do the audit because it's faster/more efficient. 
				super.auditSize();
			} else if (_auditNS == null) {
				_auditNS = new NetStream(_nc);
				_auditNS.bufferTime = isNaN(this.vars.bufferTime) ? 5 : Number(this.vars.bufferTime);
				_auditNS.client = {onMetaData:_auditHandler, onCuePoint:_auditHandler};
				_auditNS.addEventListener(NetStatusEvent.NET_STATUS, _auditHandler, false, 0, true);
				_auditNS.addEventListener("ioError", _auditHandler, false, 0, true);
				_auditNS.addEventListener("asyncError", _auditHandler, false, 0, true);
				_auditNS.soundTransform = new SoundTransform(0);
				var request:URLRequest = new URLRequest();
				request.data = _request.data;
				_setRequestURL(request, _url, (!_isLocal || _url.substr(0, 4) == "http") ? "gsCacheBusterID=" + (_cacheID++) + "&purpose=audit" : "");
				_auditNS.play(request.url);
			}
		}
			
		/** @private **/
		protected function _auditHandler(event:Event=null):void {
			var type:String = (event == null) ? "" : event.type;
			var code:String = (event == null || !(event is NetStatusEvent)) ? "" : NetStatusEvent(event).info.code;
			if (event != null && "duration" in event) {
				_duration = Object(event).duration;
			}
			if (_auditNS != null) {
				_cachedBytesTotal = _auditNS.bytesTotal; 
				if (_bufferMode && _duration != 0) {
					_cachedBytesTotal *= (_auditNS.bufferTime / _duration);
				}
			}
			if (type == "ioError" ||
				type == "asyncError" || 
				code == "NetStream.Play.StreamNotFound" || 
				code == "NetConnection.Connect.Failed" ||
				code == "NetStream.Play.Failed" ||
				code == "NetStream.Play.FileStructureInvalid" || 
				code == "The MP4 doesn't contain any supported tracks") {
				if (this.vars.alternateURL != undefined && this.vars.alternateURL != "" && this.vars.alternateURL != _url) {
					_errorHandler(new LoaderEvent(LoaderEvent.ERROR, this, code));
					if (_status != LoaderStatus.DISPOSED) { //it is conceivable that the user disposed the loader in an onError handler
						_url = this.vars.alternateURL;
						_setRequestURL(_request, _url);
						var request:URLRequest = new URLRequest();
						request.data = _request.data;
						_setRequestURL(request, _url, (!_isLocal || _url.substr(0, 4) == "http") ? "gsCacheBusterID=" + (_cacheID++) + "&purpose=audit" : "");
						_auditNS.play(request.url);
					}
					return;
				} else {	
					//note: a CANCEL event won't be dispatched because technically the loader wasn't officially loading - we were only briefly checking the bytesTotal with a NetStream.
					super._failHandler(new LoaderEvent(LoaderEvent.ERROR, this, code));
				}
			}
			_auditedSize = true;
			_closeStream();
			dispatchEvent(new Event("auditedSize"));
		}
		
		/** @private **/
		override protected function _closeStream():void {
			if (_auditNS != null) {
				_auditNS.client = {};
				_auditNS.removeEventListener(NetStatusEvent.NET_STATUS, _auditHandler);
				_auditNS.removeEventListener("ioError", _auditHandler);
				_auditNS.removeEventListener("asyncError", _auditHandler);
				_auditNS.pause();
				try {
					_auditNS.close();
				} catch (error:Error) {
					
				}
				_auditNS = null;
			} else {
				super._closeStream();
			}
		}
		
		/** @private **/
		override protected function _auditStreamHandler(event:Event):void {
			if (event is ProgressEvent && _bufferMode) {
				(event as ProgressEvent).bytesTotal *= (_ns.bufferTime / _duration);
			}
			super._auditStreamHandler(event);
		}
		
		/** @private **/
		protected function _renderHandler(event:Event):void {
			_renderedOnce = true;
			if (!_videoPaused || _initted) if (!_finalFrame) { //if the video hasn't initted yet and it's paused, keep reporting the _forceTime and let the _renderTimer keep calling until the condition is no longer met. 
				_forceTime = NaN;
				_renderTimer.stop();
				_ns.removeEventListener(Event.RENDER, _renderHandler);
			}
			if (_pausePending) {
				if (_bufferFull) {
					_applyPendingPause();
				} else if (_video.stage != null) {
					//if the NetStream is still buffering, there's a good chance that the video will appear to play briefly right before we pause it, so we detach the NetStream from the Video briefly to avoid that funky visual behavior (we attach it again as soon as it buffers).
					//we cannot do _video.attachNetStream(null) here (within this RENDER handler) because it causes Flash Pro to crash! We must wait for an ENTER_FRAME event.
					_sprite.addEventListener(Event.ENTER_FRAME, _detachNS, false, 100, true);
				}
			} else if (_videoPaused && _initted) {
				_ns.pause();
			}
		}
		
		/** @private see notes in _renderHandler() **/
		private function _detachNS(event:Event):void {
			_sprite.removeEventListener(Event.ENTER_FRAME, _detachNS);
			if (!_bufferFull && _pausePending) {
				_video.attachNetStream(null); //if the NetStream is still buffering, there's a good chance that the video will appear to play briefly right before we pause it, so we detach the NetStream from the Video briefly to avoid that funky visual behavior (we attach it again as soon as it buffers).
			}
		}
		
		/** @private The video isn't decoded into memory fully until the NetStream is attached to the Video object. We only attach it when it is in the display list (thus can be seen) in order to conserve memory. **/
		protected function _videoAddedToStage(event:Event):void {
			if (_autoDetachNetStream) {
				if (!_pausePending) {
					_seek(this.videoTime); //a bug in Flash prevents the video from rendering visually unless we seek() when we attachNetStream() 
				}
				if (_stageVideo != null) {
					_stageVideo.attachNetStream(_ns);
				} else {
					_video.attachNetStream(_ns);
				}
			}
		}
		
		/** @private **/
		protected function _videoRemovedFromStage(event:Event):void {
			if (_autoDetachNetStream) {
				_video.attachNetStream(null);
				_video.clear();
			}
		}
		
		
//---- GETTERS / SETTERS -------------------------------------------------------------------------
		
		/** A ContentDisplay (a Sprite) that contains a Video object to which the NetStream is attached. This ContentDisplay Sprite can be accessed immediately; you do not need to wait for the video to load. **/
		override public function get content():* {
			return _sprite;
		}
		
		/** The <code>Video</code> object to which the NetStream was attached (automatically created by VideoLoader internally) **/
		public function get rawContent():Video {
			return _video;
		}
		
		/** The <code>NetStream</code> object used to load the video **/
		public function get netStream():NetStream {
			return _ns;
		}
		
		/** The playback status of the video: <code>true</code> if the video's playback is paused, <code>false</code> if it isn't. **/
		public function get videoPaused():Boolean {
			return _videoPaused;
		}
		public function set videoPaused(value:Boolean):void {
			var changed:Boolean = Boolean(value != _videoPaused);
			_videoPaused = value;
			if (_videoPaused) {
				//If we're trying to pause a NetStream that hasn't even been buffered yet, we run into problems where it won't load. So we need to set the _pausePending to true and then when it's buffered, it'll pause it at the beginning.
				if (!_renderedOnce) {
					_setForceTime(0);
					_pausePending = true;
					_sound.volume = 0; //temporarily make it silent while buffering.
					_ns.soundTransform = _sound;
				} else {
					_pausePending = false;
					this.volume = _volume; //Just resets the volume to where it should be in case we temporarily made it silent during the buffer.
					_ns.pause();
				}
				if (changed) {
					//previously, we included _sprite.removeEventListener(Event.ENTER_FRAME, _playProgressHandler) but discovered it was better to leave it running in order to work around a bug in Adobe's NetStream that causes it not to accurately report its time even when the NetStatusEvent is dispatched with the code "NetStream.Seek.Notify". Consequently, when the VideoLoader was paused and the videoProgress was changed or gotoVideoTime() was called, the PLAY_PROGRESS event would be dispatched before the NetStream.time arrived where it was supposed to be. 
					dispatchEvent(new LoaderEvent(VIDEO_PAUSE, this));
				}
			} else {
				if (_pausePending || !_bufferFull) {
					if (_stageVideo != null) {
						_stageVideo.attachNetStream(_ns);
					} else if (_video.stage != null) {
						_video.attachNetStream(_ns); //in case we had to detach it while buffering and waiting for the metaData
					}
					//if we don't seek() first, sometimes the NetStream doesn't attach to the video properly!
					//if we don't seek() first and the NetStream was previously rendered between its last keyframe and the end of the file, the "NetStream.Play.Stop" will have been called and it will refuse to continue playing even after resume() is called!
					//if we seek() before the metaData has been received (_initted==true), it typically prevents it from being received at all!
					//if we seek() before the NetStream has rendered once, it can lose audio completely!
					if (_initted && _renderedOnce) {
						_seek(this.videoTime); 
					}
					_pausePending = false;
				}
				this.volume = _volume; //Just resets the volume to where it should be in case we temporarily made it silent during the buffer.
				_ns.resume();
				if (changed && _playStarted) {
					dispatchEvent(new LoaderEvent(VIDEO_PLAY, this));
				}
			}
		}
		
		/** A value between 0 and 1 describing the progress of the buffer (0 = not buffered at all, 0.5 = halfway buffered, and 1 = fully buffered). The buffer progress is in relation to the <code>bufferTime</code> which is 5 seconds by default or you can pass a custom value in through the <code>vars</code> parameter in the constructor like <code>{bufferTime:20}</code>. **/
		public function get bufferProgress():Number {
			if (uint(_ns.bytesTotal) < 5) {
				return 0;
			}
			return (_ns.bufferLength > _ns.bufferTime) ? 1 : _ns.bufferLength / _ns.bufferTime;
		}
		
		/** A value between 0 and 1 describing the playback progress where 0 means the virtual playhead is at the very beginning of the video, 0.5 means it is at the halfway point and 1 means it is at the end of the video. **/
		public function get playProgress():Number {
			//Often times the duration MetaData that gets passed in doesn't exactly reflect the duration, so after the FLV is finished playing, the time and duration wouldn't equal each other, so we'd get percentPlayed values of 99.26978. We have to use this _videoComplete variable to accurately reflect the status.
			//If for example, after an FLV has finished playing, we gotoVideoTime(0) the FLV and immediately check the playProgress, it returns 1 instead of 0 because it takes a short time to render the first frame and accurately reflect the _ns.time variable. So we use an interval to help us override the _ns.time value briefly.
			return (_videoComplete) ? 1 : (this.videoTime / _duration);
		}
		public function set playProgress(value:Number):void {
			if (_duration != 0) {
				gotoVideoTime((value * _duration), !_videoPaused, true);
			}
		}
		
		/** The volume of the video (a value between 0 and 1). **/
		public function get volume():Number {
			return _volume;
		}
		public function set volume(value:Number):void {
			_sound.volume = _volume = value;
			_ns.soundTransform = _sound;
		}
		
		/** The time (in seconds) at which the virtual playhead is positioned on the video. For example, if the virtual playhead is currently at the 3-second position (3 seconds from the beginning), this value would be 3. **/
		public function get videoTime():Number {
			if (_forceTime || _forceTime == 0) {
				return _forceTime;
			} else if (_videoComplete) {
				return _duration;
			} else if (_ns.time > _duration) {
				return _duration * 0.995; //sometimes the NetStream reports a time that's greater than the duration so we must correct for that.
			} else {
				return _ns.time;
			}
		}
		public function set videoTime(value:Number):void {
			gotoVideoTime(value, !_videoPaused, true);
		}
		
		/** The duration (in seconds) of the video. This value is only accurate AFTER the metaData has been received and the <code>INIT</code> event has been dispatched. **/
		public function get duration():Number {
			return _duration;
		}
		
		/** 
		 * When <code>bufferMode</code> is <code>true</code>, the loader will report its progress only in terms of the 
		 * video's buffer instead of its overall file loading progress which has the following effects:
		 * <ul>
		 * 		<li>The <code>bytesTotal</code> will be calculated based on the NetStream's <code>duration</code>, <code>bufferLength</code>, and <code>bufferTime</code> meaning it may fluctuate in order to accurately reflect the overall <code>progress</code> ratio.</li> 
		 * 		<li>Its <code>COMPLETE</code> event will be dispatched as soon as the buffer is full, so if the VideoLoader is nested in a LoaderMax, the LoaderMax will move on to the next loader in its queue at that point. However, the VideoLoader's NetStream will continue to load in the background, using up bandwidth.</li>
		 * </ul>
		 * 
		 * <p>This can be very convenient if, for example, you want to display loading progress based on the video's buffer
		 * or if you want to load a series of loaders in a LoaderMax and have it fire its <code>COMPLETE</code> event
		 * when the buffer is full (as opposed to waiting for the entire video to load). </p>
		 **/
		public function get bufferMode():Boolean {
			return _bufferMode;
		}
		public function set bufferMode(value:Boolean):void {
			_bufferMode = value;
			_preferEstimatedBytesInAudit = _bufferMode;
			_calculateProgress();
			if (_cachedBytesLoaded < _cachedBytesTotal && _status == LoaderStatus.COMPLETED) {
				_status = LoaderStatus.LOADING;
				_sprite.addEventListener(Event.ENTER_FRAME, _loadingProgressCheck);
			}
		}
		
		/** If <code>true</code> (the default), the NetStream will only be attached to the Video object (the <code>rawContent</code>) when it is in the display list (on the stage). This conserves memory but it can cause a very brief rendering delay when the content is initially added to the stage (often imperceptible). Also, if you add it to the stage when the videoTime is <i>after</i> its last encoded keyframe, it will render at that last keyframe. **/
		public function get autoDetachNetStream():Boolean {
			return _autoDetachNetStream;
		}
		public function set autoDetachNetStream(value:Boolean):void {
			_autoDetachNetStream = value;
			if (_autoDetachNetStream && _video.stage == null) {
				_video.attachNetStream(null);
				_video.clear();
			} else if (_stageVideo != null) {
				_stageVideo.attachNetStream(_ns);
			} else {
				_video.attachNetStream(_ns);
			}
		}
		
		/** By default, the NetStream gets attached to a <code>Video</code> object, but if you want to use StageVideo in Flash, you can define the <code>stageVideo</code> object and VideoLoader will attach its NetStream to that StageVideo instance instead of the regular Video instance (which is the <code>rawContent</code>). Please read Adobe's docs regarding StageVideo to understand the tradeoffs and limitations. <strong>Note:</strong> the data type is <code>Object</code> instead of <code>StageVideo</code> in order to make VideoLoader compatible with Flash Player 9 and 10. Otherwise, you wouldn't be able to publish to those players because StageVideo was introduced in a later version. **/
		public function get stageVideo():Object {
			return _stageVideo;
		}
		public function set stageVideo(value:Object):void {
			if (_stageVideo != value) {
				_stageVideo = value;
				if (_stageVideo != null) {
					_stageVideo.attachNetStream(_ns);
					_video.clear();
				} else {
					_video.attachNetStream(_ns);
				}
			}
		}
		
	}
}

/** @private for the linked list of cue points - makes processing very fast. **/
internal class CuePoint {
	public var next:CuePoint;
	public var prev:CuePoint;
	public var time:Number;
	public var name:String;
	public var parameters:Object;
	public var gc:Boolean;
	
	public function CuePoint(time:Number, name:String, params:Object, prev:CuePoint) {
		this.time = time;
		this.name = name;
		this.parameters = params;
		if (prev) {
			this.prev = prev;
			if (prev.next) {
				prev.next.prev = this;
				this.next = prev.next;
			}
			prev.next = this;
		}
	}
	
}