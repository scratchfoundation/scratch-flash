/*
 * Scratch Project Editor and Player
 * Copyright (C) 2014 Massachusetts Institute of Technology
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

// ScratchStage.as
// John Maloney, April 2010
//
// A Scratch stage object. Supports a drawing surface for the pen commands.

package scratch {
	import flash.display.*;
	import flash.geom.*;
	import flash.media.*;
	import flash.events.*;
	import flash.system.Capabilities;
	import flash.utils.ByteArray;
	import flash.net.FileReference;
	import blocks.Block;
	import filters.FilterPack;
	import translation.Translator;
	import uiwidgets.Menu;
	import ui.media.MediaInfo;
	import util.*;
	import watchers.*;
	import by.blooddy.crypto.image.PNG24Encoder;
	import by.blooddy.crypto.image.PNGFilter;
	import by.blooddy.crypto.MD5;

public class ScratchStage extends ScratchObj {

	public var info:Object = new Object();
	public var tempoBPM:Number = 60;

	public var penActivity:Boolean;
	public var newPenStrokes:Shape;
	public var penLayer:Bitmap;

	public var penLayerPNG:ByteArray;
	public var penLayerID:int = -1;
	public var penLayerMD5:String;

	private var bg:Shape;

	// camera support
	public var videoImage:Bitmap;
	static private var camera:Camera;
	private var video:Video;
	private var videoAlpha:Number = 0.5;
	private var flipVideo:Boolean = true;

	public function ScratchStage() {
		objName = 'Stage';
		isStage = true;
		scrollRect = new Rectangle(0, 0, STAGEW, STAGEH); // clip drawing to my bounds
		cacheAsBitmap = true; // clip damage reports to my bounds
		filterPack = new FilterPack(this);

		addWhiteBG();
		img = new Sprite();
		img.addChild(new Bitmap(new BitmapData(1, 1)));
		img.cacheAsBitmap = true;
		addChild(img);
		addPenLayer();
		initMedia();
		showCostume(0);
	}

	public function setTempo(bpm:Number):void {
		tempoBPM = Math.max(20, Math.min(bpm, 500));
	}

	public function objNamed(s:String):ScratchObj {
		// Return the object with the given name, or null if not found.
		if (('_stage_' == s) || (objName == s)) return this;
		return spriteNamed(s);
	}

	public function spriteNamed(spriteName:String):ScratchSprite {
		// Return the sprite (but not a clone) with the given name, or null if not found.
		for each (var spr:ScratchSprite in sprites()) {
			if ((spr.objName == spriteName) && !spr.isClone) return spr;
		}
		var app:Scratch = Scratch.app;
		if ((app != null) && (app.gh.carriedObj is ScratchSprite)) {
			spr = ScratchSprite(app.gh.carriedObj);
			if ((spr.objName == spriteName) && !spr.isClone) return spr;
		}
		return null;
	}

	public function spritesAndClonesNamed(spriteName:String):Array {
		// Return all sprites and clones with the given name.
		var result:Array = [];
		for (var i:int = 0; i < numChildren; i++) {
			var c:* = getChildAt(i);
			if ((c is ScratchSprite) && (c.objName == spriteName)) result.push(c);
		}
		var app:Scratch = parent as Scratch;
		if (app != null) {
			var spr:ScratchSprite = app.gh.carriedObj as ScratchSprite;
			if (spr && (spr.objName == spriteName)) result.push(spr);
		}
		return result;
	}

	public function unusedSpriteName(baseName:String):String {
		var existingNames:Array = ['_mouse_', '_stage_', '_edge_', '_myself_'];
		for each (var s:ScratchSprite in sprites()) {
			existingNames.push(s.objName.toLowerCase());
		}
		var lcBaseName:String = baseName.toLowerCase();
		if (existingNames.indexOf(lcBaseName) < 0) return baseName; // basename is not already used
		lcBaseName = withoutTrailingDigits(lcBaseName);
		var i:int = 2;
		while (existingNames.indexOf(lcBaseName + i) >= 0) { i++ } // find an unused name
		return withoutTrailingDigits(baseName) + i;
	}

	private function initMedia():void {
		costumes.push(ScratchCostume.emptyBitmapCostume(Translator.map('backdrop1'), true));
		sounds.push(new ScratchSound(Translator.map('pop'), new Pop()));
		sounds[0].prepareToSave();
	}

	private function addWhiteBG():void {
		bg = new Shape();
		bg.graphics.beginFill(0xFFFFFF);
		bg.graphics.drawRect(0, 0, STAGEW, STAGEH);
		addChild(bg);
	}

	private function addPenLayer():void {
		newPenStrokes = new Shape();
		var bm:BitmapData = new BitmapData(STAGEW, STAGEH, true, 0);
		penLayer = new Bitmap(bm);
		addChild(penLayer);
	}

	public function baseW():Number { return bg.width }
	public function baseH():Number { return bg.height }

	public function scratchMouseX():int { return Math.max(-240, Math.min(mouseX - (STAGEW / 2), 240)) }
	public function scratchMouseY():int { return -Math.max(-180, Math.min(mouseY - (STAGEH / 2), 180)) }

	public override function allObjects():Array {
		// Return an array of all sprites in this project plus the stage.
		var result:Array = sprites();
		result.push(this);
		return result;
	}

	public function sprites():Array {
		// Return an array of all sprites in this project.
		var result:Array = [];
		for (var i:int = 0; i < numChildren; i++) {
			var o:* = getChildAt(i);
			if ((o is ScratchSprite) && !o.isClone) result.push(o);
		}
		return result;
	}

	public function deleteClones():void {
		var clones:Array = [];
		for (var i:int = 0; i < numChildren; i++) {
			var o:* = getChildAt(i);
			if ((o is ScratchSprite) && o.isClone) {
				if (o.bubble && o.bubble.parent) o.bubble.parent.removeChild(o.bubble);
				clones.push(o);
			}
		}
		for each (var c:ScratchSprite in clones) removeChild(c);
	}

	public function watchers():Array {
		// Return an array of all variable and lists on the stage, visible or not.
		var result:Array = [];
		var uiLayer:Sprite = getUILayer();
		for (var i:int = 0; i < uiLayer.numChildren; i++) {
			var o:* = uiLayer.getChildAt(i);
			if ((o is Watcher) || (o is ListWatcher)) result.push(o);
		}
		return result;
	}

	public function removeObsoleteWatchers():void {
		// Called after deleting a sprite.
		var toDelete:Array = [];
		var uiLayer:Sprite = getUILayer();
		for (var i:int = 0; i < uiLayer.numChildren; i++) {
			var w:Watcher = uiLayer.getChildAt(i) as Watcher;
			if (w && !w.target.isStage && (w.target.parent != this)) toDelete.push(w);

			var lw:ListWatcher = uiLayer.getChildAt(i) as ListWatcher;
			if (lw && !lw.target.isStage && (lw.target.parent != this)) toDelete.push(lw);
		}
		for each (var c:DisplayObject in toDelete) uiLayer.removeChild(c);
	}

	/* Menu */

	public function menu(evt:MouseEvent):Menu {
		var m:Menu = new Menu();
		m.addItem('save picture of stage', saveScreenshot);
		return m;
	}

	private function saveScreenshot():void {
		var bitmapData:BitmapData = new BitmapData(STAGEW, STAGEH, true, 0);
		bitmapData.draw(this);
		var pngData:ByteArray = PNG24Encoder.encode(bitmapData, PNGFilter.PAETH);
		var file:FileReference = new FileReference();
		file.save(pngData, 'stage.png');
	}

	/* Scrolling support */

	public var xScroll:Number = 0;
	public var yScroll:Number = 0;

	public function scrollAlign(s:String):void {
		var c:DisplayObject = currentCostume().displayObj();
		var sceneW:int = Math.max(c.width, STAGEW);
		var sceneH:int = Math.max(c.height, STAGEH);
		switch (s) {
		case 'top-left':
			xScroll = 0;
			yScroll = sceneH - STAGEH;
			break;
		case 'top-right':
			xScroll = sceneW - STAGEW;
			yScroll = sceneH - STAGEH;
			break;
		case 'middle':
			xScroll = Math.floor((sceneW - STAGEW) / 2);
			yScroll = Math.floor((sceneH - STAGEH) / 2);
			break;
		case 'bottom-left':
			xScroll = 0;
			yScroll = 0;
			break;
		case 'bottom-right':
			xScroll = sceneW - STAGEW;
			yScroll = 0;
			break;
		}
		updateImage();
	}

	public function scrollRight(n:Number):void { xScroll += n; updateImage() }
	public function scrollUp(n:Number):void { yScroll += n; updateImage() }

	public function getUILayer():Sprite {
		if(Scratch.app.isIn3D) return Scratch.app.render3D.getUIContainer();
		return this;
	}

	override protected function updateImage():void {
		super.updateImage();
		if(Scratch.app.isIn3D)
			Scratch.app.render3D.getUIContainer().transform.matrix = transform.matrix.clone();

		return; // scrolling background support is disabled; see note below

		// NOTE: The following code supports the scrolling backgrounds
		// feature, which was explored but removed before launch.
		// This prototype implementation renders SVG backdrops to a bitmap
		// (to allow wrapping) but that causes pixelation in presentation mode.
		// If the scrolling backgrounds feature is ever resurrected this code
		// is a good starting point but the pixelation issue should be fixed.
		clearCachedBitmap();
		while (img.numChildren > 0) img.removeChildAt(0);

		var c:DisplayObject = currentCostume().displayObj();
		var sceneW:int = Math.max(c.width, STAGEW);
		var sceneH:int = Math.max(c.height, STAGEH);

		// keep x and y scroll within range 0 .. sceneW/sceneH
		xScroll = xScroll % sceneW;
		yScroll = yScroll % sceneH;
		if (xScroll < 0) xScroll += sceneW;
		if (yScroll < 0) yScroll += sceneH;

		if ((xScroll == 0) && (yScroll == 0) && (c.width == STAGEW) && (c.height == STAGEH)) {
			img.addChild(currentCostume().displayObj());
			return;
		}

		var bm:BitmapData;
		if ((c is BitmapData) && (c.width >= STAGEW) && (c.height >= STAGEH)) {
			bm = c as BitmapData;
		} else {
			// render SVG to a bitmap. also centers scenes smaller than the stage
			var m:Matrix = null;
			var insetX:int = Math.max(0, (STAGEW - c.width) / 2);
			var insetY:int = Math.max(0, (STAGEH - c.height) / 2);
			if (currentCostume().svgRoot) insetX = insetY = 0;
			if ((insetX > 0) || (insetY > 0)) {
				m = new Matrix();
				m.scale(c.scaleX, c.scaleY);
				m.translate(insetX, insetY);
			}
			bm = new BitmapData(sceneW, sceneH, false);
			bm.draw(c, m);
		}

		var stageBM:BitmapData = bm;
		if ((xScroll != 0) || (yScroll != 0)) {
			var yBase:int = STAGEH - sceneH;
			stageBM = new BitmapData(STAGEW, STAGEH, false, 0x505050);
			stageBM.copyPixels(bm, bm.rect, new Point(-xScroll, yBase + yScroll));
			stageBM.copyPixels(bm, bm.rect, new Point(sceneW - xScroll, yBase + yScroll));
			stageBM.copyPixels(bm, bm.rect, new Point(-xScroll, yBase + yScroll - sceneH));
			stageBM.copyPixels(bm, bm.rect, new Point(sceneW - xScroll, yBase + yScroll - sceneH));
		}

		img.addChild(new Bitmap(stageBM));
		img.x = img.y = 0;
	}

	/* Camera support */

	public function step(runtime:ScratchRuntime):void {
		if (videoImage != null) {
			if (flipVideo) {
				// flip the image like a mirror
				var m:Matrix = new Matrix();
				m.scale(-1, 1);
				m.translate(video.width, 0);
				videoImage.bitmapData.draw(video, m);
			} else {
				videoImage.bitmapData.draw(video);
			}
			if(Scratch.app.isIn3D) Scratch.app.render3D.updateRender(videoImage);
		}
		cachedBitmapIsCurrent = false;

		// Step the watchers
		var uiContainer:Sprite = getUILayer();
		for (var i:int = 0; i < uiContainer.numChildren; i++) {
			var c:DisplayObject = uiContainer.getChildAt(i);
			if (c.visible == true) {
				if (c is Watcher) Watcher(c).step(runtime);
				if (c is ListWatcher) ListWatcher(c).step();
			}
		}
	}

//	private var testBM:Bitmap = new Bitmap();
	private var stampBounds:Rectangle = new Rectangle();
	public function stampSprite(s:ScratchSprite, stampAlpha:Number):void {
		if(s == null) return;
//		if(!testBM.parent) {
//			//testBM.filters = [new GlowFilter(0xFF00FF, 0.8)];
//			testBM.y = 360; testBM.x = 15;
//			stage.addChild(testBM);
//		}

		var penBM:BitmapData = penLayer.bitmapData;
		var m:Matrix = new Matrix();
		if(Scratch.app.isIn3D) {
			var bmd:BitmapData = getBitmapOfSprite(s, stampBounds);
			if(!bmd) return;

			// TODO: Optimize for garbage collection
			var childCenter:Point = stampBounds.topLeft;
			commitPenStrokes();
			m.translate(childCenter.x * s.scaleX, childCenter.y * s.scaleY);
			m.rotate((Math.PI * s.rotation) / 180);
			m.translate(s.x, s.y);
			penBM.draw(bmd, m, new ColorTransform(1, 1, 1, stampAlpha), null, null, (s.rotation % 90 != 0));
			Scratch.app.render3D.updateRender(penLayer);
//			testBM.bitmapData = bmd;
		}
		else {
			var wasVisible:Boolean = s.visible;
			s.visible = true;  // if this is done after commitPenStrokes, it doesn't work...
			commitPenStrokes();
			m.rotate((Math.PI * s.rotation) / 180);
			m.scale(s.scaleX, s.scaleY);
			m.translate(s.x, s.y);
			var oldGhost:Number = s.filterPack.getFilterSetting('ghost');
			s.filterPack.setFilter('ghost', 100 * (1 - stampAlpha));
			s.applyFilters();
			penBM.draw(s, m);
			s.filterPack.setFilter('ghost', oldGhost);
			s.applyFilters();
			s.visible = wasVisible;
		}
	}

	public function getBitmapOfSprite(s:ScratchSprite, bounds:Rectangle, for_carry:Boolean = false):BitmapData {
		var b:Rectangle = s.currentCostume().bitmap ? s.img.getChildAt(0).getBounds(s) : s.getVisibleBounds(s);
		bounds.width = b.width; bounds.height = b.height; bounds.x = b.x; bounds.y = b.y;
		if(!Scratch.app.render3D || s.width < 1 || s.height < 1) return null;

		var ghost:Number = s.filterPack.getFilterSetting('ghost');
		var oldBright:Number = s.filterPack.getFilterSetting('brightness');
		s.filterPack.setFilter('ghost', 0);
		s.filterPack.setFilter('brightness', 0);
		var bmd:BitmapData = Scratch.app.render3D.getRenderedChild(s, b.width*s.scaleX, b.height*s.scaleY, for_carry);
		s.filterPack.setFilter('ghost', ghost);
		s.filterPack.setFilter('brightness', oldBright);

		return bmd;
	}

	public function setVideoState(newState:String):void {
		if ('off' == newState) {
			if (video) video.attachCamera(null); // turn off camera
			if (videoImage && videoImage.parent) videoImage.parent.removeChild(videoImage);
			video = null;
			videoImage = null;
			return;
		}
		Scratch.app.libraryPart.showVideoButton();
		flipVideo = ('on' == newState); // 'on' means mirrored; 'on-flip' means unmirrored
		if (camera == null) {
			// Set up the camera only the first time it is used.
			camera = Camera.getCamera();
			if (!camera) return; // no camera available or access denied
			camera.setMode(640, 480, 30);
		}
		if (video == null) {
			video = new Video(480, 360);
			video.attachCamera(camera);
			videoImage = new Bitmap(new BitmapData(video.width, video.height, false));
			videoImage.alpha = videoAlpha;
			addChildAt(videoImage, getChildIndex(penLayer) + 1);
		}
	}

	public function setVideoTransparency(transparency:Number):void {
		videoAlpha = 1 - Math.max(0, Math.min(transparency / 100, 1));
		if (videoImage) videoImage.alpha = videoAlpha;
	}

	public function isVideoOn():Boolean { return videoImage != null }

	/* Pen support */

	public function clearPenStrokes():void {
		var bm:BitmapData = penLayer.bitmapData;
		bm.fillRect(bm.rect, 0);
		newPenStrokes.graphics.clear();
		penActivity = false;
		if(Scratch.app.isIn3D) Scratch.app.render3D.updateRender(penLayer);
	}

	public function commitPenStrokes():void {
		if (!penActivity) return;
		penLayer.bitmapData.draw(newPenStrokes);
		newPenStrokes.graphics.clear();
		penActivity = false;
		if(Scratch.app.isIn3D) Scratch.app.render3D.updateRender(penLayer);
	}

	private var cachedBM:BitmapData;
	private var cachedBitmapIsCurrent:Boolean;

	private function updateCachedBitmap():void {
		if (cachedBitmapIsCurrent) return;
		if (!cachedBM) cachedBM = new BitmapData(STAGEW, STAGEH, false);
		cachedBM.fillRect(cachedBM.rect, 0xF0F080);
		cachedBM.draw(img);
		if (penLayer) cachedBM.draw(penLayer);
		if (videoImage) cachedBM.draw(videoImage);
		cachedBitmapIsCurrent = true;
	}

	public function bitmapWithoutSprite(s:ScratchSprite):BitmapData {
		// Used by the 'touching color' primitives. Draw the background layers
		// and all sprites (but not watchers or talk bubbles) except the given
		// sprite within the bounding rectangle of the given sprite into
		// a bitmap and return it.

		var r:Rectangle = s.bounds();
		var bm:BitmapData = new BitmapData(r.width, r.height, false);

		if (!cachedBitmapIsCurrent) updateCachedBitmap();

		var m:Matrix = new Matrix();
		m.translate(-r.x, -r.y);
		bm.draw(cachedBM, m);

		for (var i:int = 0; i < this.numChildren; i++) {
			var o:ScratchSprite = this.getChildAt(i) as ScratchSprite;
			if (o && (o != s) && o.visible && o.bounds().intersects(r)) {
				var oBnds:Rectangle = o.bounds();
				m = new Matrix();
				m.translate(o.img.x, o.img.y);
				m.rotate((Math.PI * o.rotation) / 180);
				m.scale(o.scaleX, o.scaleY);
				m.translate(o.x - r.x, o.y - r.y);
				var colorTransform:ColorTransform = (o.img.alpha == 1) ? null : new ColorTransform(1, 1, 1, o.img.alpha);
				bm.draw(o.img, m, colorTransform);
			}
		}
		return bm;
	}

	public function updateSpriteEffects(spr:DisplayObject, effects:Object):void {
		if(Scratch.app.isIn3D) Scratch.app.render3D.updateFilters(spr, effects);
	}

	public function getBitmapWithoutSpriteFilteredByColor(s:ScratchSprite, c:int):BitmapData {
		commitPenStrokes(); // force any pen strokes to be rendered so they can be sensed

		var bm1:BitmapData;
		var mask:uint = 0x00F8F8F0; //0xF0F8F8F0;
		if(Scratch.app.isIn3D) {
			var b:Rectangle = s.currentCostume().bitmap ? s.img.getChildAt(0).getBounds(s) : s.getVisibleBounds(s);
			bm1 = Scratch.app.render3D.getOtherRenderedChildren(s, 1);
			//mask = 0x80F8F8F0;
		}
		else {
			// OLD code here
			bm1 = bitmapWithoutSprite(s);
		}

		var bm2:BitmapData = new BitmapData(bm1.width, bm1.height, true, 0);
		bm2.threshold(bm1, bm1.rect, bm1.rect.topLeft, '==', c, 0xFF000000, mask); // match only top five bits of each component
//		if(!testBM.parent) {
//			testBM.filters = [new GlowFilter(0xFF00FF, 0.8)];
//			stage.addChild(testBM);
//		}
//		testBM.x = bm1.width;
//		testBM.y = 300;
//		testBM.bitmapData = bm1;
//		if(dumpPixels) {
//			var arr:Vector.<uint> = bm1.getVector(bm1.rect);
//			var pxs:String = '';
//			for(var i:int=0; i<arr.length; ++i)
//				pxs += getNumberAsHexString(arr[i], 8) + ', ';
//			trace('Looking for '+getNumberAsHexString(c, 8)+'   bitmap pixels: '+pxs);
//			dumpPixels = false;
//		}

		return bm2;
	}
//	private var dumpPixels:Boolean = false;

	private function getNumberAsHexString(number:uint, minimumLength:uint = 1, showHexDenotation:Boolean = true):String {
		// The string that will be output at the end of the function.
		var string:String = number.toString(16).toUpperCase();

		// While the minimumLength argument is higher than the length of the string, add a leading zero.
		while (minimumLength > string.length) {
			string = "0" + string;
		}

		// Return the result with a "0x" in front of the result.
		if (showHexDenotation) { string = "0x" + string; }

		return string;
	}

	public function updateRender(dispObj:DisplayObject, renderID:String = null, renderOpts:Object = null):void {
		if(Scratch.app.isIn3D) Scratch.app.render3D.updateRender(dispObj, renderID, renderOpts);
	}

	public function projectThumbnailPNG():ByteArray {
		// Generate project thumbnail.
		// Note: Do not save the video layer in the thumbnail for privacy reasons.
		var bm:BitmapData = new BitmapData(STAGEW, STAGEH, false);
		if (videoImage) videoImage.visible = false;

		// Get a screenshot of the stage
		if(Scratch.app.isIn3D) Scratch.app.render3D.getRender(bm);
		else bm.draw(this);

		if (videoImage) videoImage.visible = true;
		return PNG24Encoder.encode(bm);
	}

	public function savePenLayer():void {
		penLayerID = -1;
		penLayerPNG = PNG24Encoder.encode(penLayer.bitmapData, PNGFilter.PAETH);
		penLayerMD5 = by.blooddy.crypto.MD5.hashBytes(penLayerPNG) + '.png';
	}

	public function clearPenLayer():void {
		penLayerPNG = null;
		penLayerMD5 = null;
	}

	public function isEmpty():Boolean {
		// Return true if this project has no scripts, no variables, no lists,
		// at most one sprite, and only the default costumes and sound media.
		var defaultMedia:Array = [
			'510da64cf172d53750dffd23fbf73563.png',
			'b82f959ab7fa28a70b06c8162b7fef83.svg',
			'df0e59dcdea889efae55eb77902edc1c.svg',
			'83a9787d4cb6f3b7632b4ddfebf74367.wav',
			'f9a1c175dbe2e5dee472858dd30d16bb.svg',
			'6e8bd9ae68fdb02b7e1e3df656a75635.svg',
			'0aa976d536ad6667ce05f9f2174ceb3d.svg',	// new empty backdrop
			'790f7842ea100f71b34e5b9a5bfbcaa1.svg', // even newer empty backdrop
			'c969115cb6a3b75470f8897fbda5c9c9.svg'	// new empty costume
		];
		if (sprites().length > 1) return false;
		if (scriptCount() > 0) return false;
		for each (var obj:ScratchObj in allObjects()) {
			if (obj.variables.length > 0) return false;
			if (obj.lists.length > 0) return false;
			for each (var c:ScratchCostume in obj.costumes) {
				if (defaultMedia.indexOf(c.baseLayerMD5) < 0) return false;
			}
			for each (var snd:ScratchSound in obj.sounds) {
				if (defaultMedia.indexOf(snd.md5) < 0) return false;
			}
		}
		return true;
	}

	public function updateInfo():void {
		info.scriptCount = scriptCount();
		info.spriteCount = spriteCount();
		info.flashVersion = Capabilities.version;
		if (Scratch.app.projectID != '') info.projectID = Scratch.app.projectID;
		info.videoOn = isVideoOn();
		info.swfVersion = Scratch.versionString;

		delete info.loadInProgress;
		if (Scratch.app.loadInProgress) info.loadInProgress = true; // log flag for debugging

		if (this == Scratch.app.stagePane) {
			// If this is the active stage pane, record the current extensions.
			var extensionsToSave:Array = Scratch.app.extensionManager.extensionsToSave();
			if (extensionsToSave.length == 0) delete info.savedExtensions;
			else info.savedExtensions = extensionsToSave;
		}

		delete info.userAgent;
		if (Scratch.app.jsEnabled) {
			Scratch.app.externalCall('window.navigator.userAgent.toString', function(userAgent:String):void {
				if (userAgent) info.userAgent = userAgent;
			});
		}
	}

	public function updateListWatchers():void {
		for (var i:int = 0; i < numChildren; i++) {
			var c:DisplayObject = getChildAt(i);
			if (c is ListWatcher) {
				ListWatcher(c).updateContents();
			}
		}
	}

	public function scriptCount():int {
		var scriptCount:int;
		for each (var obj:ScratchObj in allObjects()) {
			for each (var b:* in obj.scripts) {
				if ((b is Block) && b.isHat) scriptCount++;
			}
		}
		return scriptCount;
	}

	public function spriteCount():int { return sprites().length }

	/* Dropping */

	public function handleDrop(obj:*):Boolean {
		if ((obj is ScratchSprite) || (obj is Watcher) || (obj is ListWatcher)) {
			if (scaleX != 1) {
				obj.scaleX = obj.scaleY = obj.scaleX / scaleX; // revert to original scale
			}
			var p:Point = globalToLocal(new Point(obj.x, obj.y));
			obj.x = p.x;
			obj.y = p.y;
			if (obj.parent) obj.parent.removeChild(obj); // force redisplay
			addChild(obj);
			if (obj is ScratchSprite) {
				obj.setScratchXY(p.x - 240, 180 - p.y);
				(obj as ScratchSprite).updateCostume();
				Scratch.app.selectSprite(obj);
				obj.setScratchXY(p.x - 240, 180 - p.y); // needed because selectSprite() moves sprite back if costumes tab is open
				(obj as ScratchObj).applyFilters();
			}
			if (!(obj is ScratchSprite) || Scratch.app.editMode) Scratch.app.setSaveNeeded();
			return true;
		}
		Scratch.app.setSaveNeeded();
		if ((obj is MediaInfo) && obj.fromBackpack) {
			function addSpriteForCostume(c:ScratchCostume):void {
				var s:ScratchSprite = new ScratchSprite(c.costumeName);
				s.setInitialCostume(c.duplicate());
				app.addNewSprite(s, false, true);
			}
			var app:Scratch = root as Scratch;
			// Add sprites
			if (obj.mysprite) {
				app.addNewSprite(obj.mysprite.duplicate(), false, true);
				return true;
			}
			if (obj.objType == 'sprite') {
				function addDroppedSprite(spr:ScratchSprite):void {
					spr.objName = obj.objName;
					app.addNewSprite(spr, false, true);
				}
				new ProjectIO(app).fetchSprite(obj.md5, addDroppedSprite);
				return true;
			}
			if (obj.mycostume) {
				addSpriteForCostume(obj.mycostume);
				return true;
			}
			if (obj.objType == 'image') {
				new ProjectIO(app).fetchImage(obj.md5, obj.objName, addSpriteForCostume);
				return true;
			}
		}
		return false;
	}

	/* Saving */

	public override function writeJSON(json:util.JSON):void {
		super.writeJSON(json);
		var children:Array = [];
		for (var i:int = 0; i < numChildren; i++) {
			var c:DisplayObject = getChildAt(i);
			if (((c is ScratchSprite) && !ScratchSprite(c).isClone)
				|| (c is Watcher) || (c is ListWatcher)) {
				children.push(c);
			}
		}

		// If UI elements are on another layer (during 3d rendering), process them from there
		var uiLayer:Sprite = getUILayer();
		if(uiLayer != this) {
			for (i = 0; i < uiLayer.numChildren; i++) {
				c = uiLayer.getChildAt(i);
				if (((c is ScratchSprite) && !ScratchSprite(c).isClone)
						|| (c is Watcher) || (c is ListWatcher)) {
					children.push(c);
				}
			}
		}

		json.writeKeyValue('penLayerMD5', penLayerMD5);
		json.writeKeyValue('penLayerID', penLayerID);
		json.writeKeyValue('tempoBPM', tempoBPM);
		json.writeKeyValue('videoAlpha', videoAlpha);
		json.writeKeyValue('children', children);
		json.writeKeyValue('info', info);
	}

	public override function readJSON(jsonObj:Object):void {
		var children:Array, i:int, o:Object;

		// read stage fields
		super.readJSON(jsonObj);
		penLayerMD5 = jsonObj.penLayerMD5;
		tempoBPM = jsonObj.tempoBPM;
		if (jsonObj.videoAlpha) videoAlpha = jsonObj.videoAlpha;
		children = jsonObj.children;
		info = jsonObj.info;

		// instantiate sprites and record their names
		var spriteNameMap:Object = new Object();
		spriteNameMap[objName] = this; // record stage's name
		for (i = 0; i < children.length; i++) {
			o = children[i];
			if (o.objName != undefined) { // o is a sprite record
				var s:ScratchSprite = new ScratchSprite();
				s.readJSON(o);
				spriteNameMap[s.objName] = s;
				children[i] = s;
			}
		}

		// instantiate Watchers and add all children (sprites and watchers)
		for (i = 0; i < children.length; i++) {
			o = children[i];
			if (o is ScratchSprite) {
				addChild(ScratchSprite(o));
			} else if (o.sliderMin != undefined) { // o is a watcher record
				o.target = spriteNameMap[o.target]; // update target before instantiating
				if (o.target) {
					if (o.cmd == "senseVideoMotion" && o.param && o.param.indexOf(',')) {
						// fix old video motion/direction watchers
						var args:Array = o.param.split(',');
						if (args[1] == 'this sprite') continue;
						o.param = args[0];
					}
					var w:Watcher = new Watcher();
					w.readJSON(o);
					addChild(w);
				}
			}
		}

		// instantiate lists, variables, scripts, costumes, and sounds
		for each (var scratchObj:ScratchObj in allObjects()) {
			scratchObj.instantiateFromJSON(this);
		}
	}

}}
