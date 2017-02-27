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

package ui.media {
import flash.display.*;
import flash.events.*;
import flash.media.Sound;
import flash.net.*;
import flash.text.*;
import flash.utils.*;
import assets.Resources;
import extensions.ScratchExtension;
import scratch.*;
import sound.mp3.MP3Loader;
import translation.Translator;
import uiwidgets.*;
import util.*;

public class MediaLibrary extends Sprite {

	private const titleFormat:TextFormat = new TextFormat(CSS.font, 24, 0x444143);

	private static const backdropCategories:Array = [
		'All', 'Indoors', 'Outdoors', 'Other'];
	private static const costumeCategories:Array = [
		'All', 'Animals', 'Fantasy', 'Letters', 'People', 'Things', 'Transportation'];
	private static const extensionCategories:Array = [
		'All', 'Hardware'];
	private static const soundCategories:Array = [
		'All', 'Animal', 'Effects', 'Electronic', 'Human', 'Instruments',
		'Music Loops', 'Musical Notes', 'Percussion', 'Vocals'];

	private static const backdropThemes:Array = [
		'Castle', 'City', 'Flying', 'Holiday', 'Music and Dance', 'Nature', 'Space', 'Sports', 'Underwater'];
	private static const costumeThemes:Array = [
		'Castle', 'City', 'Dance', 'Dress-Up', 'Flying', 'Holiday', 'Music', 'Space', 'Sports', 'Underwater', 'Walking'];

	private static const imageTypes:Array = ['All', 'Bitmap', 'Vector'];

	private static const spriteFeatures:Array = ['All', 'Scripts', 'Costumes > 1', 'Sounds'];

	protected var app:Scratch;
	private var assetType:String;
	protected var whenDone:Function;
	protected var allItems:Array = [];

	private var title:TextField;
	private var outerFrame:Shape;
	private var innerFrame:Shape;
	private var resultsFrame:ScrollFrame;
	protected var resultsPane:ScrollFrameContents;

	protected var categoryFilter:MediaFilter;
	protected var themeFilter:MediaFilter;
	protected var imageTypeFilter:MediaFilter;
	protected var spriteFeaturesFilter:MediaFilter;

	private var closeButton:IconButton;
	private var okayButton:Button;
	private var cancelButton:Button;

	private static var libraryCache:Object = {}; // cache of all mediaLibrary entries

	public function MediaLibrary(app:Scratch, type:String, whenDone:Function) {
		this.app = app;
		this.assetType = type;
		this.whenDone = whenDone;

		addChild(outerFrame = new Shape());
		addChild(innerFrame = new Shape());
		addTitle();
		addFilters();
		addResultsFrame();
		addButtons();
	}

	public static function strings():Array {
		var result:Array = [
			'Backdrop Library', 'Costume Library', 'Sprite Library', 'Sound Library',
			'Category', 'Theme', 'Type', 'Features',
			'Uploading image...', 'Uploading sprite...', 'Uploading sound...',
			'Importing sound...', 'Converting mp3...',
		];
		result = result.concat(backdropCategories);
		result = result.concat(costumeCategories);
		result = result.concat(extensionCategories);
		result = result.concat(soundCategories);

		result = result.concat(backdropThemes);
		result = result.concat(costumeThemes);

		result = result.concat(imageTypes);
		result = result.concat(spriteFeatures);

		return result;
	}

	public function open():void {
		app.closeTips();
		app.mediaLibrary = this;
		setWidthHeight(app.stage.stageWidth, app.stage.stageHeight);
		app.addChild(this);
		viewLibrary();
	}

	public function importFromDisk():void {
		if (parent) close();
		if (assetType == 'sound') importSoundsFromDisk();
		else importImagesOrSpritesFromDisk();
	}

	public function close(ignore:* = null):void {
		stopLoadingThumbnails();
		parent.removeChild(this);
		app.mediaLibrary = null;
		app.reopenTips();
	}

	public function setWidthHeight(w:int, h:int):void {
		const inset:int = 30; // inset around entire dialog
		const rightInset:int = 15;

		title.x = inset + 20;
		title.y = inset + 15;

		closeButton.x = w - (inset + closeButton.width + 10);
		closeButton.y = inset + 10;

		cancelButton.x = w - (inset + cancelButton.width + rightInset);
		cancelButton.y = h - (inset + cancelButton.height + 10);
		okayButton.x = cancelButton.x - (okayButton.width + 10);
		okayButton.y = cancelButton.y;

		drawBackground(w, h);

		outerFrame.x = inset;
		outerFrame.y = inset;
		drawOuterFrame(w - (2 * inset), h - (2 * inset));

		innerFrame.x = title.x + title.textWidth + 25;
		innerFrame.y = inset + 35;
		drawInnerFrame(w - (innerFrame.x + inset + rightInset), h - (innerFrame.y + inset + cancelButton.height + 20));

		resultsFrame.x = innerFrame.x + 5;
		resultsFrame.y = innerFrame.y + 5;
		resultsFrame.setWidthHeight(innerFrame.width - 10, innerFrame.height - 10);

		var nextX:int = title.x + 3;
		var nextY:int = inset + 60;
		var spaceBetweenFilteres:int = 12;

		categoryFilter.x = nextX;
		categoryFilter.y = nextY;
		nextY += categoryFilter.height + spaceBetweenFilteres;

		if (themeFilter.visible) {
			themeFilter.x = nextX;
			themeFilter.y = nextY;
			nextY += themeFilter.height + spaceBetweenFilteres;
		}

		if (imageTypeFilter.visible) {
			imageTypeFilter.x = nextX;
			imageTypeFilter.y = nextY;
			nextY += imageTypeFilter.height + spaceBetweenFilteres;
		}

		if (spriteFeaturesFilter.visible) {
			spriteFeaturesFilter.x = nextX;
			spriteFeaturesFilter.y = nextY;
		}

	}

	private function drawBackground(w:int, h:int):void {
		const bgColor:int = 0;
		const bgAlpha:Number = 0.6;
		var g:Graphics = this.graphics;
		g.clear();
		g.beginFill(bgColor, bgAlpha);
		g.drawRect(0, 0, w, h);
		g.endFill();
	}

	private function drawOuterFrame(w:int, h:int):void {
		var g:Graphics = outerFrame.graphics;
		g.clear();
		g.beginFill(CSS.tabColor);
		g.drawRoundRect(0, 0, w, h, 12, 12);
		g.endFill();
	}

	private function drawInnerFrame(w:int, h:int):void {
		var g:Graphics = innerFrame.graphics;
		g.clear();
		g.beginFill(CSS.white, 1);
		g.drawRoundRect(0, 0, w, h, 8, 8);
		g.endFill();
	}

	private function addTitle():void {
		var s:String = assetType;
		if ('backdrop' == s) s = 'Backdrop Library';
		if ('costume' == s) s = 'Costume Library';
		if ('extension' == s) s = 'Extension Library';
		if ('sprite' == s) s = 'Sprite Library';
		if ('sound' == s) s = 'Sound Library';
		addChild(title = Resources.makeLabel(Translator.map(s), titleFormat));
	}

	private function addFilters():void {
		var categories:Array = [];
		if ('backdrop' == assetType) categories = backdropCategories;
		if ('costume' == assetType) categories = costumeCategories;
		if ('extension' == assetType) categories = extensionCategories;
		if ('sprite' == assetType) categories = costumeCategories;
		if ('sound' == assetType) categories = soundCategories;
		categoryFilter = new MediaFilter('Category', categories, filterChanged);
		addChild(categoryFilter);

		themeFilter = new MediaFilter(
			'Theme',
			('backdrop' == assetType) ? backdropThemes : costumeThemes,
			filterChanged);
		themeFilter.currentSelection = '';
		addChild(themeFilter);

		imageTypeFilter = new MediaFilter('Type', imageTypes, filterChanged);
		addChild(imageTypeFilter);

		spriteFeaturesFilter = new MediaFilter('Features', spriteFeatures, filterChanged);
		addChild(spriteFeaturesFilter);

		themeFilter.visible = (['sprite', 'costume', 'backdrop'].indexOf(assetType) > -1);
		imageTypeFilter.visible = (['sprite', 'costume'].indexOf(assetType) > -1);
		spriteFeaturesFilter.visible = ('sprite' == assetType);
spriteFeaturesFilter.visible = false; // disable features filter for now
	}

	private function filterChanged(filter:MediaFilter):void {
		if (filter == categoryFilter) themeFilter.currentSelection = '';
		if (filter == themeFilter) categoryFilter.currentSelection = '';
		showFilteredItems();

		// scroll to top when filters change
		resultsPane.y = 0;
		resultsFrame.updateScrollbars()
	}

	private function addResultsFrame():void {
		resultsPane = new ScrollFrameContents();
		resultsPane.color = CSS.white;
		resultsPane.hExtra = 0;
		resultsPane.vExtra = 5;
		resultsFrame = new ScrollFrame();
		resultsFrame.setContents(resultsPane);
		addChild(resultsFrame);
	}

	private function addButtons():void {
		addChild(closeButton = new IconButton(close, 'close'));
		addChild(okayButton = new Button(Translator.map('OK'), addSelected));
		addChild(cancelButton = new Button(Translator.map('Cancel'), close));
	}

	// -----------------------------
	// Library Contents
	//------------------------------

	private function viewLibrary():void {
		function gotLibraryData(data:ByteArray):void {
			if (!data) return; // failure
			var s:String = data.readUTFBytes(data.length);
			libraryCache[assetType] = util.JSON.parse(stripComments(s)) as Array;
			collectEntries();
		}
		function collectEntries():void {
			allItems = [];
			for each (var entry:Object in libraryCache[assetType]) {
				if (entry.type == assetType) {
					if (entry.tags is Array) entry.category = entry.tags[0];
					var info:Array = entry.info as Array;
					if (info) {
						if (entry.type == 'backdrop') {
							entry.width = info[0];
							entry.height = info[1];
						}
						if (entry.type == 'sound') {
							entry.seconds = info[0];
						}
						if (entry.type == 'sprite') {
							entry.scriptCount = info[0];
							entry.costumeCount = info[1];
							entry.soundCount = info[2];
						}
					}
					allItems.push(new MediaLibraryItem(entry));
				}
			}
			showFilteredItems();
			startLoadingThumbnails();
		}
		if ('extension' == assetType) {
			addScratchExtensions();
			return;
		}
		if (!libraryCache[assetType]) app.server.getMediaLibrary(assetType, gotLibraryData);
		else collectEntries();
	}


	protected function addScratchExtensions():void {
		const extList:Array = [
			ScratchExtension.PicoBoard(),
			ScratchExtension.WeDo(),
			ScratchExtension.WeDo2()
		];
		allItems = [];
		for each (var ext:ScratchExtension in extList) {
			allItems.push(new MediaLibraryItem({
				extension: ext,
				name: ext.displayName,
				md5: ext.thumbnailMD5,
				tags: ext.tags
			}));
		}
		showFilteredItems();
		startLoadingThumbnails();
	}

	private function stripComments(s:String):String {
		// Remove full-line comments starting with '//'. The comment delimiter must be at the very start of the line.
		var result:String = '';
		for each (var line:String in s.split('\n')) {
			var isComment:Boolean = false;
			if ((line.length > 0) && (line.charAt(0) == '<')) isComment = true; // Full-line comments starting with '<!--' (added by Gaia).
			if ((line.length > 1) && (line.charAt(0) == '/') && (line.charAt(1) == '/')) isComment = true;
			if (!isComment) result += line + '\n';
		}
		return result;
	}

	protected function showFilteredItems():void {
		var tag:String = '';
		if (categoryFilter.currentSelection != '') tag = categoryFilter.currentSelection;
		if (themeFilter.currentSelection != '') tag = themeFilter.currentSelection;
		tag = tag.replace(new RegExp(' ', 'g'), '-'); // e.g., change 'Music and Dance' -> 'Music-and-Dance'
		tag = tag.toLowerCase();
		var showAll:Boolean = ('all' == tag);
		var filtered:Array = [];
		for each (var item:MediaLibraryItem in allItems) {
			if ((showAll || (item.dbObj.tags.indexOf(tag) > -1)) && hasSelectedFeatures(item.dbObj)) {
				filtered.push(item);
			}
		}
		while (resultsPane.numChildren > 0) resultsPane.removeChildAt(0);
		appendItems(filtered);
	}

	private function hasSelectedFeatures(item:Object):Boolean {
		var imageType:String = imageTypeFilter.currentSelection;
		if (imageTypeFilter.visible && (imageType != 'All')) {
			if (imageType == 'Vector') {
				if (item.tags.indexOf('vector') == -1) return false;
			} else {
				if (item.tags.indexOf('vector') != -1) return false;
			}
		}
		var spriteFeatures:String = spriteFeaturesFilter.currentSelection;
		if (spriteFeaturesFilter.visible && (spriteFeatures != 'All')) {
			if (('Scripts' == spriteFeatures) && (item.scriptCount == 0)) return false;
			if (('Costumes > 1' == spriteFeatures) && (item.costumeCount <= 1)) return false;
			if (('Sounds' == spriteFeatures) && (item.soundCount == 0)) return false;
		}
		return true;
	}

	protected function appendItems(items:Array):void {
		if (items.length == 0) return;
		var itemWidth:int = (items[0] as MediaLibraryItem).frameWidth + 6;
		var totalWidth:int = resultsFrame.width - 15;
		var columnCount:int = totalWidth / itemWidth;
		var extra:int = (totalWidth - (columnCount * itemWidth)) / columnCount; // extra space per column

		var colNum:int = 0;
		var nextX:int = 2;
		var nextY:int = 2;
		for each (var item:MediaLibraryItem in items) {
			item.x = nextX;
			item.y = nextY;
			resultsPane.addChild(item);
			nextX += item.frameWidth + 6 + extra;
			if (++colNum == columnCount) {
				colNum = 0;
				nextX = 2;
				nextY += item.frameHeight + 5;
			}
		}
		if (nextX > 5) nextY += item.frameHeight + 2; // if there's anything on this line, start a new one
		resultsPane.updateSize();
	}

	public function addSelected():void {
		// Close dialog and call whenDone() with an array of selected media items.
		var io:ProjectIO = new ProjectIO(app);
		close();
		for (var i:int = 0; i < resultsPane.numChildren; i++) {
			var item:MediaLibraryItem = resultsPane.getChildAt(i) as MediaLibraryItem;
			if (item && item.isHighlighted()) {
				var md5AndExt:String = item.dbObj.md5;
				var obj:Object = null;
				if (assetType == 'extension') {
					whenDone(item.dbObj.extension);
				} else if (md5AndExt.slice(-5) == '.json') {
					io.fetchSprite(md5AndExt, whenDone);
				} else if (assetType == 'sound') {
					io.fetchSound(md5AndExt, item.dbObj.name, whenDone);
				} else if (assetType == 'costume') {
					obj = {
						centerX: item.dbObj.info[0],
						centerY: item.dbObj.info[1],
						bitmapResolution: 1
					};
					if (item.dbObj.info.length == 3)
						obj.bitmapResolution = item.dbObj.info[2];

					io.fetchImage(md5AndExt, item.dbObj.name, 0, whenDone, obj);
				} else { // assetType == backdrop
					if (item.dbObj.info.length == 3) {
						obj = {
							centerX: ScratchCostume.kCalculateCenter,
							centerY: ScratchCostume.kCalculateCenter,
							bitmapResolution: item.dbObj.info[2]
						};
					} else if (item.dbObj.info.length == 2 && item.dbObj.info[0] == 960 && item.dbObj.info[1] == 720) {
						obj = {
							centerX: ScratchCostume.kCalculateCenter,
							centerY: ScratchCostume.kCalculateCenter,
							bitmapResolution: 2
						};
					}
					io.fetchImage(md5AndExt, item.dbObj.name, 0, whenDone, obj);
				}
			}
		}
	}

	// -----------------------------
	// Thumbnail loading
	//------------------------------

	protected function startLoadingThumbnails():void {
		function loadSomeThumbnails():void {
			var count:int = 10 - inProgress;
			while ((next < allItems.length) && (count-- > 0)) {
				inProgress++;
				allItems[next++].loadThumbnail(loadDone);
			}
			if ((next < allItems.length) || inProgress) setTimeout(loadSomeThumbnails, 40);
		}
		function loadDone():void { inProgress-- }

		var next:int = 0;
		var inProgress:int = 0;
		loadSomeThumbnails();
	}

	private function stopLoadingThumbnails():void {
		for (var i:int = 0; i < resultsPane.numChildren; i++) {
			var item:MediaLibraryItem = resultsPane.getChildAt(i) as MediaLibraryItem;
			if (item) item.stopLoading();
		}
	}

	// -----------------------------
	// Import from disk
	//------------------------------

	private function importImagesOrSpritesFromDisk():void {
		function fileSelected(e:Event):void {
			for (var j:int = 0; j < files.fileList.length; j++) {
				var file:FileReference = FileReference(files.fileList[j]);
				file.addEventListener(Event.COMPLETE, fileLoaded);
				file.load();
			}
		}
		function fileLoaded(e:Event):void {
			var fRef:FileReference = e.target as FileReference;
			if (fRef) convertAndUploadImageOrSprite(fRef.name, fRef.data)
		}
		var costumeOrSprite:*;
		var files:FileReferenceList = new FileReferenceList();
		files.addEventListener(Event.SELECT, fileSelected);
		try {
			// Ignore the exception that happens when you call browse() with the file browser open
			files.browse();
		} catch(e:*) {}
	}

	protected function uploadCostume(costume:ScratchCostume, whenDone:Function):void {
		whenDone();
	}

	protected function uploadSprite(sprite:ScratchSprite, whenDone:Function):void {
		whenDone();
	}

	private function convertAndUploadImageOrSprite(fName:String, data:ByteArray):void {
		function imageDecoded(e:Event):void {
			var bm:BitmapData = ScratchCostume.scaleForScratch(e.target.content.bitmapData);
			costumeOrSprite = new ScratchCostume(fName, bm);
			uploadCostume(costumeOrSprite, uploadComplete);
		}
		function spriteDecoded(s:ScratchSprite):void {
			costumeOrSprite = s;
			uploadSprite(s, uploadComplete);
		}
		function imagesDecoded():void {
			sprite.updateScriptsAfterTranslation();
			spriteDecoded(sprite);
		}
		function uploadComplete():void {
			app.removeLoadProgressBox();
			whenDone(costumeOrSprite);
		}
		function decodeError():void {
			DialogBox.notify('Error decoding image', 'Sorry, Scratch was unable to load the image '+fName+'.', Scratch.app.stage);
		}
		function spriteError():void {
			DialogBox.notify('Error decoding sprite', 'Sorry, Scratch was unable to load the sprite '+fName+'.', Scratch.app.stage);
		}
		var costumeOrSprite:*;
		var fExt:String = '';
		var i:int = fName.lastIndexOf('.');
		if (i > 0) {
			fExt = fName.slice(i).toLowerCase();
			fName = fName.slice(0, i);
		}

		if ((fExt == '.png') || (fExt == '.jpg') || (fExt == '.jpeg')) {
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, imageDecoded);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(e:Event):void { decodeError(); });
			try {
				loader.loadBytes(data);
			} catch(e:*) {
				decodeError();
			}
		} else if (fExt == '.gif') {
			try {
				importGIF(fName, data);
			} catch(e:*) {
				decodeError();
			}
		} else if (ScratchCostume.isSVGData(data)) {
			data = svgAddGroupIfNeeded(data); // wrap group around imported elements
			costumeOrSprite = new ScratchCostume(fName, null);
			costumeOrSprite.setSVGData(data, true);
			uploadCostume(costumeOrSprite as ScratchCostume, uploadComplete);
		} else {
			data.position = 0;
			if (data.bytesAvailable > 4 && data.readUTFBytes(4) == 'ObjS') {
				var info:Object;
				var objTable:Array;
				data.position = 0;
				var reader:ObjReader = new ObjReader(data);
				try { info = reader.readInfo() } catch (e:Error) { data.position = 0 }
				try { objTable = reader.readObjTable() } catch (e:Error) { }
				if (!objTable) {
					spriteError();
					return;
				}
				var newProject:ScratchStage = new OldProjectReader().extractProject(objTable);
				var sprite:ScratchSprite = newProject.numChildren > 3 ? newProject.getChildAt(3) as ScratchSprite : null;
				if (!sprite) {
					spriteError();
					return;
				}
				new ProjectIO(app).decodeAllImages(newProject.allObjects(), imagesDecoded, spriteError);
			} else {
				data.position = 0;
				new ProjectIO(app).decodeSpriteFromZipFile(data, spriteDecoded, spriteError);
			}
		}
	}

	private function importGIF(fName:String, data:ByteArray):void {
		var gifReader:GIFDecoder = new GIFDecoder();
		gifReader.read(data);
		if (gifReader.frames.length == 0) return; // bad GIF (error; no images)
		var newCostumes:Array = [];
		for (var i:int = 0; i < gifReader.frames.length; ++i) {
			newCostumes.push(new ScratchCostume(fName + '-' + i, gifReader.frames[i]));
		}

		gifImported(newCostumes);
	}

	protected function gifImported(newCostumes:Array):void {
		whenDone(newCostumes);
	}

	private function svgAddGroupIfNeeded(svgData:ByteArray):ByteArray {
		var xml:XML = XML(svgData);
		if (!svgNeedsGroup(xml)) return svgData;

		var groupNode:XML = new XML('<g></g>');
		for each (var el:XML in xml.elements()) {
			if (el.localName() != 'defs') {
				delete xml.children()[el.childIndex()];
				groupNode.appendChild(el); // move all non-def elements into group
			}
		}
		xml.appendChild(groupNode);

		// fix for an apparent bug in Flash XML parser (changes 'xml' namespace to 'aaa')
		for each (var k:* in xml.attributes()) {
			if (k.localName() == 'space') delete xml.@[k.name()];
		}
		xml.@['xml:space'] = 'preserve';

		var newSVG:XML = xml;
		var data: ByteArray = new ByteArray();
		data.writeUTFBytes(newSVG.toXMLString());
		return data;
	}

	private function svgNeedsGroup(xml:XML):Boolean {
		// Return true if the given SVG contains more than one non-defs element.
		var nonDefsCount:int;
		for each (var el:XML in xml.elements()) {
			if (el.localName() != 'defs') nonDefsCount++;
		}
		return nonDefsCount > 1;
	}

	private function importSoundsFromDisk():void {
		function fileSelected(e:Event):void {
			for (var j:int = 0; j < files.fileList.length; j++) {
				var file:FileReference = FileReference(files.fileList[j]);
				file.addEventListener(Event.COMPLETE, fileLoaded);
				file.load();
			}
		}
		function fileLoaded(e:Event):void {
			convertAndUploadSound(FileReference(e.target).name, FileReference(e.target).data);
		}
		var files:FileReferenceList = new FileReferenceList();
		files.addEventListener(Event.SELECT, fileSelected);
		try {
			// Ignore the exception that happens when you call browse() with the file browser open
			files.browse();
		} catch(e:*) {}
	}

	protected function startSoundUpload(sndToUpload:ScratchSound, origName:String, whenDone:Function):void {
		if(!sndToUpload) {
			DialogBox.notify(
					'Sorry!',
					'The sound file '+origName+' is not recognized by Scratch.  Please use MP3 or WAV sound files.',
					stage);
			return;
		}
		whenDone();
	}

	private function convertAndUploadSound(sndName:String, data:ByteArray):void {
		function uploadComplete():void {
			app.removeLoadProgressBox();
			whenDone(snd);
		}
		var snd:ScratchSound;
		var origName:String = sndName;
		var i:int = sndName.lastIndexOf('.');
		if (i > 0) sndName = sndName.slice(0, i); // remove extension

		app.addLoadProgressBox('Importing sound...');
		try {
			snd = new ScratchSound(sndName, data); // try reading the data as a WAV file
		} catch (e:Error) { }

		if (snd && snd.sampleCount > 0) { // WAV data
			startSoundUpload(snd, origName, uploadComplete);
		} else { // try to read data as an MP3 file
			if (app.lp) app.lp.setTitle('Converting mp3 file...');
			var sound:Sound;
			function uploadConvertedSound(out:ScratchSound):void {
				snd = out;
				if (snd && snd.sampleCount > 0) {
					startSoundUpload(out, origName, uploadComplete);
				}
				else {
					app.removeLoadProgressBox();
					DialogBox.notify('Error decoding sound', 'Sorry, Scratch was unable to load the sound ' + sndName + '.', Scratch.app.stage);
				}
			}
			SCRATCH::allow3d {
				sound = new Sound();
				try {
					data.position = 0;
					sound.loadCompressedDataFromByteArray(data, data.length);
					MP3Loader.extractSamples(origName, sound, sound.length * 44.1, uploadConvertedSound);
				}
				catch(e:Error) {
					trace(e);
					uploadComplete();
				}
			}

			if (!sound)
				setTimeout(function():void {
					MP3Loader.convertToScratchSound(sndName, data, uploadConvertedSound);
				}, 1);
		}
	}

}}
