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
	import uiwidgets.*;
	import util.*;

public class MediaLibraryItem extends Sprite {

	public var dbObj:Object;
	public var isSound:Boolean;

	public var frameWidth:int;
	public var frameHeight:int;
	private var thumbnailWidth:int;
	private var thumbnailHeight:int;

	private const labelFormat:TextFormat = new TextFormat(CSS.font, 14, CSS.textColor);
	private const infoFormat:TextFormat = new TextFormat(CSS.font, 10, CSS.textColor);

	private static var spriteCache:Object = {}; // maps md5 -> JSON for sprites
	private static var thumbnailCache:Object = {};

	private var frame:Shape; // visible when selected
	protected var thumbnail:Bitmap;
	protected var label:DisplayObject;
	private var info:TextField;
	private var playButton:IconButton;

	private var sndData:ByteArray;
	private var sndPlayer:ScratchSoundPlayer;

	private var loaders:Array = []; // list of URLLoaders for stopLoading()

	public function MediaLibraryItem(dbObject:Object = null) {
		this.dbObj = dbObject;
		if (dbObj.seconds) isSound = true;

		frameWidth = isSound ? 115 : 140;
		frameHeight = isSound ? 95 : 140;
		thumbnailWidth = isSound ? 68 : 120;
		thumbnailHeight = isSound ? 51 : 90;

		addFrame();
		addThumbnail();
		addLabel();
		addInfo();
		unhighlight();
		if (isSound) addPlayButton();
	}

	public static function strings():Array { return ['Costumes:', 'Scripts:'] }

	// -----------------------------
	// Thumbnail
	//------------------------------

	public function loadThumbnail(done:Function):void {
		var ext:String = fileType(dbObj.md5);
		if (['gif', 'png', 'jpg', 'jpeg', 'svg'].indexOf(ext) > -1) setImageThumbnail(dbObj.md5, done);
		else if (ext == 'json') setSpriteThumbnail(done);
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
				done();
			}
		}
		function svgImagesLoaded():void {
			var c:ScratchCostume = new ScratchCostume('', null);
			c.setSVGRoot(importer.root, false);
			setThumbnail(c.thumbnail(thumbnailWidth, thumbnailHeight, forStage));
			done();
		}
		function setThumbnail(bm:BitmapData):void {
			if (bm) {
				thumbnailCache[md5] = bm;
				if (spriteMD5) thumbnailCache[spriteMD5] = bm;
				setThumbnailBM(bm);
			}
			done();
		}
		// first, check the thumbnail cache
		var cachedBM:BitmapData = thumbnailCache[md5];
		if (cachedBM) { setThumbnailBM(cachedBM); done(); return; }

		// if not in the thumbnail cache, fetch/compute it
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
				done();
			}
		}
		// first, check the thumbnail cache
		var spriteMD5:String = dbObj.md5;
		var cachedBM:BitmapData = thumbnailCache[spriteMD5];
		if (cachedBM) { setThumbnailBM(cachedBM); done(); return; }

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
		g.lineStyle(3, CSS.overColor, 1, true);
		g.beginFill(CSS.itemSelectedColor);
		g.drawRoundRect(0, 0, frameWidth, frameHeight, 12, 12);
		g.endFill();
		addChild(frame);
	}

	protected function addThumbnail():void {
		if (isSound) {
			thumbnail = Resources.createBmp('speakerOff');
			thumbnail.x = 22;
			thumbnail.y = 25;
		} else {
			var blank:BitmapData = new BitmapData(1, 1, true, 0);
			thumbnail = new Bitmap(blank);
			thumbnail.x = (frameWidth - thumbnail.width) / 2;
			thumbnail.y = 13;
		}
		addChild(thumbnail);
	}

	protected function addLabel():void {
		var objName:String = dbObj.name ? dbObj.name : '';
		var tf:TextField = Resources.makeLabel(objName, labelFormat);
		label = tf;
		label.x = ((frameWidth - tf.textWidth) / 2) - 2;
		label.y = frameHeight - 32;
		addChild(label);
	}

	private function addInfo():void {
		info = Resources.makeLabel('', infoFormat);
		info.x = Math.max(0, (frameWidth - info.textWidth) / 2);
		info.y = frameHeight - 17;
		addChild(info);
	}

	private function addPlayButton():void {
		playButton = new IconButton(toggleSoundPlay, 'play');
		playButton.x = 75;
		playButton.y = 28;
		addChild(playButton);
	}

	private function setText(tf:TextField, s:String):void {
		// Set the text of the given TextField, truncating if necessary.
		var desiredWidth:int = frame.width - 6;
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
			info.visible = true;
		}
	}

	private function unhighlight():void {
		if (frame.alpha != 0) {
			frame.alpha = 0;
			info.visible = false;
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
		if (sndPlayer) stopPlayingSound(null);
		else startPlayingSound();
	}

	private function stopPlayingSound(ignore:*):void {
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
