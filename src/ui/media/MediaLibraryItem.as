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

// MediaLibraryItem.as
// John Maloney, April 2013
//
// This object represents an image, sound, or sprite in the MediaLibrary. It displays
// a name, thumbnail, and a line of information for the media object it represents.

package ui.media {
	import flash.display.*;
	import flash.events.MouseEvent;
	import flash.net.URLLoader;
	import flash.text.*;
	import flash.utils.ByteArray;
	import assets.Resources;
	import scratch.*;
	import sound.ScratchSoundPlayer;
	import sound.mp3.MP3SoundPlayer;
	import svgutils.SVGImporter;
	import translation.Translator;

import ui.events.PointerEvent;

import uiwidgets.*;
	import util.*;

public class MediaLibraryItem extends Sprite {
	public var dbObj:Object;
	public var isSound:Boolean;

	public var frameWidth:int;
	public var frameHeight:int;
	private var thumbnailWidth:int;
	private var thumbnailHeight:int;

	private static var labelFormat:TextFormat;
	private static var infoFormat:TextFormat;

	private static var spriteCache:Object = {}; // maps md5 -> JSON for sprites
	private static var thumbnailCache:Object = {};

	private var frame:Shape; // visible when selected
	protected var thumbnail:Bitmap;
	protected var label:DisplayObject;
	private var info:TextField;
	private var playButton:IconButton;

	private var sndData:ByteArray;
	private static var sndPlayer:ScratchSoundPlayer;

	private var loaders:Array = []; // list of URLLoaders for stopLoading()

	private static var defaultScale:Number;
	private static var itemFrameWidth:Number;
	private static var itemFrameHeight:Number;
	private static var soundFrameWidth:Number;
	private static var soundFrameHeight:Number;
	private static var itemThumbWidth:Number;
	private static var itemThumbHeight:Number;
	private static var soundThumbWidth:Number;
	private static var soundThumbHeight:Number;
	setDefaultScale(1); // static init

	public function MediaLibraryItem(dbObject:Object = null) {
		this.dbObj = dbObject;
		if (dbObj.seconds) isSound = true;

		frameWidth = isSound ? soundFrameWidth : itemFrameWidth;
		frameHeight = isSound ? soundFrameHeight : itemFrameHeight;
		thumbnailWidth = isSound ? soundThumbWidth : itemThumbWidth;
		thumbnailHeight = isSound ? soundThumbHeight : itemThumbHeight;

		addFrame();
		visible = false; // must call show(true) first
		unhighlight();
		addEventListener(PointerEvent.TAP, click);
		addEventListener(PointerEvent.DOUBLE_TAP, doubleClick);
	}

	public static function strings():Array { return ['Costumes:', 'Scripts:'] }

	public static function setDefaultScale(scale:Number):void {
		// TODO: most or all usage of 'defaultScale' should be rephrased in terms of frameWidth or thumbnailWidth.
		defaultScale = scale;
		itemFrameWidth = 140 * scale;
		itemFrameHeight = 140 * scale;
		soundFrameWidth = 115 * scale;
		soundFrameHeight = 95 * scale;
		itemThumbWidth = 120 * scale;
		itemThumbHeight = 90 * scale;
		soundThumbWidth = 68 * scale;
		soundThumbHeight = 51 * scale;
		labelFormat = new TextFormat(CSS.font, 14 * scale, CSS.textColor);
		infoFormat = new TextFormat(CSS.font, 10 * scale, CSS.textColor);
	}

	public static function stopSounds():void {
		if (sndPlayer) sndPlayer.stopPlaying();
		sndPlayer = null;
	}

	private var visualReady:Boolean = false;
	public function show(shouldShow:Boolean, whenDone:Function = null):void {
		if (visible == shouldShow && (visualReady || !shouldShow)) {
			if (whenDone) whenDone();
			return;
		}

		// TODO: do more on show/hide?
		visible = shouldShow;
		if (shouldShow) {
			if (!visualReady) {
				visualReady = true;
				addThumbnail();
				addLabel();
				addInfo();
				unhighlight();
				if (isSound) addPlayButton();
				loadThumbnail(whenDone);
			}
			else {
				if (whenDone) whenDone();
			}
		}
		else {
			if (whenDone) whenDone();
		}
	}

	// -----------------------------
	// Thumbnail
	//------------------------------

	private function loadThumbnail(done:Function):void {
		var ext:String = fileType(dbObj.md5);
		if (['gif', 'png', 'jpg', 'jpeg', 'svg'].indexOf(ext) > -1) setImageThumbnail(dbObj.md5, done);
		else if (ext == 'json') setSpriteThumbnail(done);
		else if (done) done();
	}

	public function stopLoading():void {
		var app:Scratch = root as Scratch;
		for each (var loader:URLLoader in loaders) if (loader) loader.close();
		loaders = [];
	}

	private function fileType(s:String):String {
		if (!s) return '';
		var i:int = s.lastIndexOf('.');
		return (i < 0) ? '' : s.slice(i + 1);
	}

	// all paths must call done() even on failure!
	private function setImageThumbnail(md5:String, done:Function, spriteMD5:String = null):void {
		var forStage:Boolean = (dbObj.width == 480); // if width is 480, format thumbnail for stage
		var importer:SVGImporter;
		function gotSVGData(data:ByteArray):void {
			if (data) {
				importer = new SVGImporter(XML(data));
				importer.loadAllImages(svgImagesLoaded);
			}
			else {
				if (done) done();
			}
		}
		function svgImagesLoaded():void {
			var c:ScratchCostume = new ScratchCostume('', null);
			c.setSVGRoot(importer.root, false);
			setThumbnail(c.thumbnail(thumbnailWidth, thumbnailHeight, forStage));
			if (done) done();
		}
		function setThumbnail(bm:BitmapData):void {
			if (bm) {
				thumbnailCache[md5] = bm;
				if (spriteMD5) thumbnailCache[spriteMD5] = bm;
				setThumbnailBM(bm);
			}
			if (done) done();
		}
		// first, check the thumbnail cache
		var cachedBM:BitmapData = thumbnailCache[md5];
		if (cachedBM) { setThumbnailBM(cachedBM); if (done) done(); return; }

		// if not in the thumbnail cache, fetch/compute it
		trace('loading '+md5);
		if (fileType(md5) == 'svg') loaders.push(Scratch.app.server.getAsset(md5, gotSVGData));
		else loaders.push(Scratch.app.server.getThumbnail(md5, thumbnailWidth, thumbnailHeight, setThumbnail));
	}

	// all paths must call done() even on failure!
	private function setSpriteThumbnail(done:Function):void {
		function gotJSONData(data:String):void {
			var md5:String;
			if (data) {
				var sprObj:Object = util.JSON.parse(data);
				spriteCache[spriteMD5] = data;
				dbObj.scriptCount = (sprObj.scripts is Array) ? sprObj.scripts.length : 0;
				dbObj.costumeCount = (sprObj.costumes is Array) ? sprObj.costumes.length : 0;
				dbObj.soundCount = (sprObj.sounds is Array) ? sprObj.sounds.length : 0;
				if (dbObj.scriptCount > 0) setInfo(Translator.map('Scripts:') + ' ' + dbObj.scriptCount);
				else if (dbObj.costumeCount > 1) setInfo(Translator.map('Costumes:') + ' ' + dbObj.costumeCount);
				else setInfo('');
				if ((sprObj.costumes is Array) && (sprObj.currentCostumeIndex is Number)) {
					var cList:Array = sprObj.costumes;
					var cObj:Object = cList[Math.round(sprObj.currentCostumeIndex) % cList.length];
					if (cObj) md5 = cObj.baseLayerMD5;
				}
			}
			if (md5) {
				setImageThumbnail(md5, done, spriteMD5);
			}
			else {
				if (done) done();
			}
		}
		// first, check the thumbnail cache
		var spriteMD5:String = dbObj.md5;
		var cachedBM:BitmapData = thumbnailCache[spriteMD5];
		if (cachedBM) { setThumbnailBM(cachedBM); if (done) done(); return; }

		if (spriteCache[spriteMD5]) gotJSONData(spriteCache[spriteMD5]);
		else loaders.push(Scratch.app.server.getAsset(spriteMD5, gotJSONData));
	}

	private function setThumbnailBM(bm:BitmapData):void {
		thumbnail.bitmapData = bm;
		thumbnail.x = (frameWidth - thumbnail.width) / 2;
	}

	private function setInfo(s:String):void {
		info.text = s;
		info.x = Math.max(0, (frameWidth - info.textWidth) / 2);
	}

	// -----------------------------
	// Parts
	//------------------------------

	private function addFrame():void {
		frame = new Shape();
		var g:Graphics = frame.graphics;
		g.lineStyle(3 * defaultScale, CSS.overColor, 1, true);
		g.beginFill(CSS.itemSelectedColor);
		g.drawRoundRect(0, 0, frameWidth, frameHeight, 12 * defaultScale, 12 * defaultScale);
		g.endFill();
		addChild(frame);
	}

	protected function addThumbnail():void {
		if (isSound) {
			thumbnail = Resources.createBmp('speakerOff');
			thumbnail.x = 22 * defaultScale;
			thumbnail.y = 25 * defaultScale;
		} else {
			var blank:BitmapData = new BitmapData(1, 1, true, 0);
			thumbnail = new Bitmap(blank);
			thumbnail.x = (frameWidth - thumbnail.width) / 2;
			thumbnail.y = 13 * defaultScale;
		}
		addChild(thumbnail);
	}

	protected function addLabel():void {
		var objName:String = dbObj.name ? dbObj.name : '';
		var tf:TextField = Resources.makeLabel(objName, labelFormat);
		label = tf;
		label.x = ((frameWidth - tf.textWidth) / 2) - 2 * defaultScale;
		label.y = frameHeight - 32 * defaultScale;
		addChild(label);
	}

	private function addInfo():void {
		info = Resources.makeLabel('', infoFormat);
		info.x = Math.max(0, (frameWidth - info.textWidth) / 2);
		info.y = frameHeight - 17 * defaultScale;
		addChild(info);
	}

	private function addPlayButton():void {
		playButton = new IconButton(toggleSoundPlay, 'play');
		playButton.x = 75 * defaultScale;
		playButton.y = 28 * defaultScale;
		addChild(playButton);
	}

	private function setText(tf:TextField, s:String):void {
		// Set the text of the given TextField, truncating if necessary.
		var desiredWidth:int = frame.width - 6 * defaultScale;
		tf.text = s;
		while ((tf.textWidth > desiredWidth) && (s.length > 0)) {
			s = s.substring(0, s.length - 1);
			tf.text = s + '\u2026'; // truncated name with ellipses
		}
	}

	// -----------------------------
	// User interaction
	//------------------------------

	public function click(evt:MouseEvent):void {
		if (!evt.shiftKey) unhighlightAll();
		toggleHighlight();
	}

	public function doubleClick(evt:MouseEvent):void {
		if (!evt.shiftKey) unhighlightAll();
		highlight();
		var lib:MediaLibrary = parent.parent.parent as MediaLibrary;
		if (lib) lib.addSelected();
	}

	// -----------------------------
	// Highlighting
	//------------------------------

	public function isHighlighted():Boolean { return frame.alpha == 1; }
	private function toggleHighlight():void { if (frame.alpha == 1) unhighlight(); else highlight(); }

	private function highlight():void {
		if (frame.alpha != 1) {
			frame.alpha = 1;
			if (info) {
				// TODO: handle highlight before info
				info.visible = true;
			}
		}
	}

	private function unhighlight():void {
		if (frame.alpha != 0) {
			frame.alpha = 0;
			if (info) {
				info.visible = false;
			}
		}
	}

	private function unhighlightAll():void {
		var contents:ScrollFrameContents = parent as ScrollFrameContents;
		if (contents) {
			for (var i:int = 0; i < contents.numChildren; i++) {
				var item:MediaLibraryItem = contents.getChildAt(i) as MediaLibraryItem;
				if (item) item.unhighlight();
			}
		}
	}

	// -----------------------------
	// Play Sound
	//------------------------------

	private function toggleSoundPlay(b:IconButton):void {
		if (sndPlayer && sndData && sndPlayer.isPlaying(sndData)) stopPlayingSound(null);
		else {
			if (sndPlayer) stopSounds();
			startPlayingSound();
		}
	}

	private function stopPlayingSound(ignore:* = null):void {
		if (sndPlayer) sndPlayer.stopPlaying();
		sndPlayer = null;
		playButton.turnOff();
	}

	private function startPlayingSound():void {
		if (sndData) {
			if (ScratchSound.isWAV(sndData)) {
				sndPlayer = new ScratchSoundPlayer(sndData);
			} else {
				sndPlayer = new MP3SoundPlayer(sndData);
			}
		}
		if (sndPlayer) {
			sndPlayer.startPlaying(stopPlayingSound);
			playButton.turnOn();
		} else {
			downloadAndPlay();
		}
	}

	private function downloadAndPlay():void {
		// Download and play a library sound.
		function gotSoundData(wavData:ByteArray):void {
			if (!wavData) return;
			sndData = wavData;
			startPlayingSound();
		}
		Scratch.app.server.getAsset(dbObj.md5, gotSoundData);
	}

}}
