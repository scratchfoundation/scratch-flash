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

// LibraryPart.as
// John Maloney, November 2011
//
// This part holds the Sprite Library and the UI elements around it.

package ui.parts {
	import flash.display.*;
	import flash.geom.*;
	import flash.text.*;
	import flash.utils.*;
	import scratch.*;
	import translation.Translator;
	import ui.media.*;
	import ui.SpriteThumbnail;
	import uiwidgets.*;
	import util.ProjectIO;

public class LibraryPart extends UIPart {

	private const smallTextFormat:TextFormat = new TextFormat(CSS.font, 10, CSS.textColor);

	private const bgColor:int = 0xFFFFFF;
	private const stageAreaWidth:int = 77;
	private const updateInterval:int = 200; // msecs between thumbnail updates

	private var lastUpdate:uint; // time of last thumbnail update

	private var shape:Shape;

	private var stageThumbnail:SpriteThumbnail;
	private var spritesFrame:ScrollFrame;
	protected var spritesPane:ScrollFrameContents;
	private var spriteDetails:SpriteInfoPart;

	private var spritesTitle:TextField;
	private var newSpriteLabel:TextField;
	private var paintButton:IconButton;
	private var libraryButton:IconButton;
	private var importButton:IconButton;
	private var photoButton:IconButton;

	private var newBackdropLabel:TextField;
	private var backdropLibraryButton:IconButton;
	private var backdropPaintButton:IconButton;
	private var backdropImportButton:IconButton;
	private var backdropCameraButton:IconButton;

	private var videoLabel:TextField;
	private var videoButton:IconButton;

	public function LibraryPart(app:Scratch) {
		this.app = app;
		shape = new Shape();
		addChild(shape);

		spritesTitle = makeLabel(Translator.map('Sprites'), CSS.titleFormat, stageAreaWidth + 10, 5);
		addChild(spritesTitle);

		addChild(newSpriteLabel = makeLabel(Translator.map('New sprite:'), CSS.titleFormat, 10, 5));
		addChild(libraryButton = makeButton(spriteFromLibrary, 'library'));
		addChild(paintButton = makeButton(paintSprite, 'paintbrush'));
		addChild(importButton = makeButton(spriteFromComputer, 'import'));
		addChild(photoButton = makeButton(spriteFromCamera, 'camera'));

		addStageArea();
		addNewBackdropButtons();
		addVideoControl();
		addSpritesArea();

		spriteDetails = new SpriteInfoPart(app);
		addChild(spriteDetails);
		spriteDetails.visible = false;

		updateTranslation();
	}

	public static function strings():Array {
		return [
			'Sprites', 'New sprite:', 'New backdrop:', 'Video on:', 'backdrop1', 'costume1', 'photo1', 'pop',
			'Choose sprite from library', 'Paint new sprite', 'Upload sprite from file', 'New sprite from camera',
			'Choose backdrop from library', 'Paint new backdrop', 'Upload backdrop from file', 'New backdrop from camera',
		];
	}

	public function updateTranslation():void {
		spritesTitle.text = Translator.map('Sprites');
		newSpriteLabel.text = Translator.map('New sprite:');
		newBackdropLabel.text = Translator.map('New backdrop:');
		videoLabel.text = Translator.map('Video on:');
		stageThumbnail.updateThumbnail(true);
		spriteDetails.updateTranslation();

		SimpleTooltips.add(libraryButton, {text: 'Choose sprite from library', direction: 'bottom'});
		SimpleTooltips.add(paintButton, {text: 'Paint new sprite', direction: 'bottom'});
		SimpleTooltips.add(importButton, {text: 'Upload sprite from file', direction: 'bottom'});
		SimpleTooltips.add(photoButton, {text: 'New sprite from camera', direction: 'bottom'});

		SimpleTooltips.add(backdropLibraryButton, {text: 'Choose backdrop from library', direction: 'bottom'});
		SimpleTooltips.add(backdropPaintButton, {text: 'Paint new backdrop', direction: 'bottom'});
		SimpleTooltips.add(backdropImportButton, {text: 'Upload backdrop from file', direction: 'bottom'});
		SimpleTooltips.add(backdropCameraButton, {text: 'New backdrop from camera', direction: 'bottom'});

		fixLayout();
	}

	public function setWidthHeight(w:int, h:int):void {
		this.w = w;
		this.h = h;
		var g:Graphics = shape.graphics;
		g.clear();
		drawTopBar(g, CSS.titleBarColors, getTopBarPath(w,CSS.titleBarH), w, CSS.titleBarH);
		g.lineStyle(1, CSS.borderColor, 1, true);
		g.drawRect(0, CSS.titleBarH, w, h - CSS.titleBarH);
		g.lineStyle(1, CSS.borderColor);
		g.moveTo(stageAreaWidth, 0);
		g.lineTo(stageAreaWidth, h);
		g.lineStyle();
		g.beginFill(CSS.tabColor);
		g.drawRect(1, CSS.titleBarH + 1, stageAreaWidth - 1, h - CSS.titleBarH - 1);
		g.endFill()
		fixLayout();
		if (app.viewedObj()) refresh(); // refresh, but not during initialization
	}

	private function fixLayout():void {
		var buttonY:int = 4;

		libraryButton.x = 380;
		if (app.stageIsContracted) libraryButton.x = 138;
		libraryButton.y = buttonY + 0;
		paintButton.x = libraryButton.x + libraryButton.width + 3;
		paintButton.y = buttonY + 1;
		importButton.x = paintButton.x + paintButton.width + 4;
		importButton.y = buttonY + 0;
		photoButton.x = importButton.x + importButton.width + 8;
		photoButton.y = buttonY + 2;

		newSpriteLabel.x = libraryButton.x - newSpriteLabel.width - 6;
		newSpriteLabel.y = 6;

		stageThumbnail.x = 2;
		stageThumbnail.y = CSS.titleBarH + 2;

		spritesFrame.x = stageAreaWidth + 1;
		spritesFrame.y = CSS.titleBarH + 1;
		spritesFrame.allowHorizontalScrollbar = false;
		spritesFrame.setWidthHeight(w - spritesFrame.x, h - spritesFrame.y);

		spriteDetails.x = spritesFrame.x;
		spriteDetails.y = spritesFrame.y;
		spriteDetails.setWidthHeight(w - spritesFrame.x, h - spritesFrame.y);
	}

	public function highlight(highlightList:Array):void {
		// Highlight each ScratchObject in the given list to show,
		// for example, broadcast senders or receivers. Passing an
		// empty list to this function clears all highlights.
		for each (var tn:SpriteThumbnail in allThumbnails()) {
			tn.showHighlight(highlightList.indexOf(tn.targetObj) >= 0);
		}
	}

	public function refresh():void {
		// Create thumbnails for all sprites. This function is called
		// after loading project, or adding or deleting a sprite.
		newSpriteLabel.visible = !app.stageIsContracted;
		spritesTitle.visible = !app.stageIsContracted;
		if (app.viewedObj().isStage) showSpriteDetails(false);
		if (spriteDetails.visible) spriteDetails.refresh();
		stageThumbnail.setTarget(app.stageObj());
		spritesPane.clear(false);
		var sortedSprites:Array = app.stageObj().sprites();
		sortedSprites.sort(
			function(spr1:ScratchSprite, spr2:ScratchSprite):int {
				return spr1.indexInLibrary - spr2.indexInLibrary
		});
		const inset:int = 2;
		var rightEdge:int = w - spritesFrame.x;
		var nextX:int = inset, nextY:int = inset;
		var index:int = 1;
		for each (var spr:ScratchSprite in sortedSprites) {
			spr.indexInLibrary = index++; // renumber to ensure unique indices
 			var tn:SpriteThumbnail = new SpriteThumbnail(spr, app);
			tn.x = nextX;
			tn.y = nextY;
			spritesPane.addChild(tn);
			nextX += tn.width;
			if ((nextX + tn.width) > rightEdge) { // start new line
				nextX = inset;
				nextY += tn.height;
			}
		}
		spritesPane.updateSize();
		scrollToSelectedSprite();
		step();
	}

	private function scrollToSelectedSprite():void {
		var viewedObj:ScratchObj = app.viewedObj();
		var sel:SpriteThumbnail;
		for (var i:int = 0; i < spritesPane.numChildren; i++) {
			var tn:SpriteThumbnail = spritesPane.getChildAt(i) as SpriteThumbnail;
			if (tn && (tn.targetObj == viewedObj)) sel = tn;
		}
		if (sel) {
			var selTop:int = sel.y + spritesPane.y - 1;
			var selBottom:int = selTop + sel.height;
			spritesPane.y -= Math.max(0, selBottom - spritesFrame.visibleH());
			spritesPane.y -= Math.min(0, selTop);
			spritesFrame.updateScrollbars();
		}
	}

	public function showSpriteDetails(flag:Boolean):void {
		spriteDetails.visible = flag;
		if (spriteDetails.visible) spriteDetails.refresh();
	}

	public function step():void {
		// Update thumbnails and sprite details.
		var viewedObj:ScratchObj = app.viewedObj();
		var updateThumbnails:Boolean = ((getTimer() - lastUpdate) > updateInterval);
		for each (var tn:SpriteThumbnail in allThumbnails()) {
			if (updateThumbnails) tn.updateThumbnail();
			tn.select(tn.targetObj == viewedObj);
		}
		if (updateThumbnails) lastUpdate = getTimer();
		if (spriteDetails.visible) spriteDetails.step();
		if (videoButton.visible) updateVideoButton();
	}

	private function addStageArea():void {
		stageThumbnail = new SpriteThumbnail(app.stagePane, app);
		addChild(stageThumbnail);
	}

	private function addNewBackdropButtons():void {
		addChild(newBackdropLabel = makeLabel(
			Translator.map('New backdrop:'), smallTextFormat, 3, 126));

		// new backdrop buttons
		addChild(backdropLibraryButton = makeButton(backdropFromLibrary, 'landscapeSmall'));
		addChild(backdropPaintButton = makeButton(paintBackdrop, 'paintbrushSmall'));
		addChild(backdropImportButton = makeButton(backdropFromComputer, 'importSmall'));
		addChild(backdropCameraButton = makeButton(backdropFromCamera, 'cameraSmall'));

		var buttonY:int = 145;
		backdropLibraryButton.x = 4;
		backdropLibraryButton.y = buttonY + 3;
		backdropPaintButton.x = backdropLibraryButton.right() + 4;
		backdropPaintButton.y = buttonY + 1;
		backdropImportButton.x = backdropPaintButton.right() + 1;
		backdropImportButton.y = buttonY + 0;
		backdropCameraButton.x = backdropImportButton.right() + 5;
		backdropCameraButton.y = buttonY + 3;
	}

	private function addSpritesArea():void {
		spritesPane = new ScrollFrameContents();
		spritesPane.color = bgColor;
		spritesPane.hExtra = spritesPane.vExtra = 0;
		spritesFrame = new ScrollFrame();
		spritesFrame.setContents(spritesPane);
		addChild(spritesFrame);
	}

	private function makeButton(fcn:Function, iconName:String):IconButton {
		var b:IconButton = new IconButton(fcn, iconName);
		b.isMomentary = true;
		return b;
	}

	// -----------------------------
	// Video Button
	//------------------------------

	public	function showVideoButton():void {
		// Show the video button. Turn on the camera the first time this is called.
		if (videoButton.visible) return; // already showing
		videoButton.visible = true;
		videoLabel.visible = true;
		if (!app.stagePane.isVideoOn()) {
			app.stagePane.setVideoState('on');
		}
	}

	private function updateVideoButton():void {
		var isOn:Boolean = app.stagePane.isVideoOn();
		if (videoButton.isOn() != isOn) videoButton.setOn(isOn);
	}

	private function addVideoControl():void {
		function turnVideoOn(b:IconButton):void {
			app.stagePane.setVideoState(b.isOn() ? 'on' : 'off');
			app.setSaveNeeded();
		}
		addChild(videoLabel = makeLabel(
			Translator.map('Video on:'), smallTextFormat,
			1, backdropLibraryButton.y + 22));

		videoButton = makeButton(turnVideoOn, 'checkbox');
		videoButton.x = videoLabel.x + videoLabel.width + 1;
		videoButton.y = videoLabel.y + 3;
		videoButton.disableMouseover();
		videoButton.isMomentary = false;
		addChild(videoButton);

		videoLabel.visible = videoButton.visible = false; // hidden until video turned on
	}

	// -----------------------------
	// New Sprite Operations
	//------------------------------

	private function paintSprite(b:IconButton):void {
		var spr:ScratchSprite = new ScratchSprite();
		spr.setInitialCostume(ScratchCostume.emptyBitmapCostume(Translator.map('costume1'), false));
		app.addNewSprite(spr, true);
	}

	private function spriteFromCamera(b:IconButton):void {
		function savePhoto(photo:BitmapData):void {
			var s:ScratchSprite = new ScratchSprite();
			s.setInitialCostume(new ScratchCostume(Translator.map('photo1'), photo));
			app.addNewSprite(s);
			app.closeCameraDialog();
		}
		app.openCameraDialog(savePhoto);
	}

	private function spriteFromComputer(b:IconButton):void { importSprite(true) }
	private function spriteFromLibrary(b:IconButton):void { importSprite(false) }

	private function importSprite(fromComputer:Boolean):void {
		function addSprite(costumeOrSprite:*):void {
			var spr:ScratchSprite;
			var c:ScratchCostume = costumeOrSprite as ScratchCostume;
			if (c) {
				spr = new ScratchSprite(c.costumeName);
				spr.setInitialCostume(c);
				app.addNewSprite(spr);
				return;
			}
			spr = costumeOrSprite as ScratchSprite;
			if (spr) {
				app.addNewSprite(spr);
				return;
			}
			var list:Array = costumeOrSprite as Array;
			if (list) {
				var sprName:String = list[0].costumeName;
				if (sprName.length > 3) sprName = sprName.slice(0, sprName.length - 2);
				spr = new ScratchSprite(sprName);
				for each (c in list) spr.costumes.push(c);
				if (spr.costumes.length > 1) spr.costumes.shift(); // remove default costume
				spr.showCostumeNamed(list[0].costumeName);
				app.addNewSprite(spr);
			}
		}
		var lib:MediaLibrary = app.getMediaLibrary('sprite', addSprite);
		if (fromComputer) lib.importFromDisk();
		else lib.open();
	}

	// -----------------------------
	// New Backdrop Operations
	//------------------------------

	private function backdropFromCamera(b:IconButton):void {
		function savePhoto(photo:BitmapData):void {
			addBackdrop(new ScratchCostume(Translator.map('photo1'), photo));
			app.closeCameraDialog();
		}
		app.openCameraDialog(savePhoto);
	}

	private function backdropFromComputer(b:IconButton):void {
		var lib:MediaLibrary = app.getMediaLibrary('backdrop', addBackdrop);
		lib.importFromDisk();
	}

	private function backdropFromLibrary(b:IconButton):void {
		var lib:MediaLibrary = app.getMediaLibrary('backdrop', addBackdrop);
		lib.open();
	}

	private function paintBackdrop(b:IconButton):void {
		addBackdrop(ScratchCostume.emptyBitmapCostume(Translator.map('backdrop1'), true));
	}

	private function addBackdrop(costumeOrList:*):void {
		var c:ScratchCostume = costumeOrList as ScratchCostume;
		if (c) {
			if (!c.baseLayerData) c.prepareToSave();
			if (!app.okayToAdd(c.baseLayerData.length)) return; // not enough room
			c.costumeName = app.stagePane.unusedCostumeName(c.costumeName);
			app.stagePane.costumes.push(c);
			app.stagePane.showCostumeNamed(c.costumeName);
		}
		var list:Array = costumeOrList as Array;
		if (list) {
			for each (c in list) {
				if (!c.baseLayerData) c.prepareToSave();
				if (!app.okayToAdd(c.baseLayerData.length)) return; // not enough room
				app.stagePane.costumes.push(c);
			}
			app.stagePane.showCostumeNamed(list[0].costumeName);
		}
		app.setTab('images');
		app.selectSprite(app.stagePane);
		app.setSaveNeeded(true);
	}

	// -----------------------------
	// Dropping
	//------------------------------

	public function handleDrop(obj:*):Boolean {
		return false;
	}

	protected function changeThumbnailOrder(dropped:ScratchSprite, dropX:int, dropY:int):void {
		// Update the order of library items based on the drop point. Update the
		// indexInLibrary field of all sprites, then refresh the library.
		dropped.indexInLibrary = -1;
		var inserted:Boolean = false;
		var nextIndex:int = 1;
		for (var i:int = 0; i < spritesPane.numChildren; i++) {
			var th:SpriteThumbnail = spritesPane.getChildAt(i) as SpriteThumbnail;
			var spr:ScratchSprite = th.targetObj as ScratchSprite;
			if (!inserted) {
				if (dropY < (th.y - (th.height / 2))) { // insert before this row
					dropped.indexInLibrary = nextIndex++;
					inserted = true;
				} else if (dropY < (th.y + (th.height / 2))) {
					if (dropX < th.x) { // insert before the current thumbnail
						dropped.indexInLibrary = nextIndex++;
						inserted = true;
					}
				}
			}
			if (spr != dropped) spr.indexInLibrary = nextIndex++;
		}
		if (dropped.indexInLibrary < 0) dropped.indexInLibrary = nextIndex++;
		refresh();
	}

	// -----------------------------
	// Misc
	//------------------------------

	private function allThumbnails():Array {
		// Return a list containing all thumbnails.
		var result:Array = [stageThumbnail];
		for (var i:int = 0; i < spritesPane.numChildren; i++) {
			result.push(spritesPane.getChildAt(i));
		}
		return result;
	}

}}
