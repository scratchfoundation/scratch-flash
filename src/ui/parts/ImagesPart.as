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

// ImagesPart.as
// John Maloney, November 2011
//
// This part holds the Costumes/Scenes list for the current sprite (or stage),
// as well as the image editor, camera, import button and other image media tools.

package ui.parts {
import flash.display.*;
import flash.events.MouseEvent;
import flash.geom.*;
import flash.text.*;
import flash.utils.setTimeout;

import scratch.*;

import svgeditor.*;

import svgutils.*;

import translation.Translator;

import ui.media.*;

import uiwidgets.*;

public class ImagesPart extends UIPart {

	public var editor:ImageEdit;

	private const columnWidth:int = 106;
	private const contentsX:int = columnWidth + 13;
	private const topButtonSize:Point = new Point(24, 22);
	private const smallSpace:int = 3;
	private var bigSpace:int;

	private var shape:Shape;
	private var listFrame:ScrollFrame;
	private var nameField:EditableLabel;
	private var undoButton:IconButton;
	private var redoButton:IconButton;
	private var clearButton:Button;
	private var libraryButton:Button;
	private var editorImportButton:Button;
	private var cropButton:IconButton;
	private var flipHButton:IconButton;
	private var flipVButton:IconButton;
	private var centerButton:IconButton;

	private var newCostumeLabel:TextField;
	private var backdropLibraryButton:IconButton;
	private var costumeLibraryButton:IconButton;
	private var paintButton:IconButton;
	private var importButton:IconButton;
	private var cameraButton:IconButton;

	public function ImagesPart(app:Scratch) {
		this.app = app;
		addChild(shape = new Shape());

		addChild(newCostumeLabel = makeLabel('', new TextFormat(CSS.font, 12, CSS.textColor, true)));
		addNewCostumeButtons();

		addListFrame();
		addChild(nameField = new EditableLabel(nameChanged));

		addEditor(true);

		addUndoButtons();
		addFlipButtons();
		addCenterButton();
		updateTranslation();
	}

	protected function addEditor(isSVG:Boolean):void {
		if (isSVG) {
			addChild(editor = new SVGEdit(app, this));
		}
		else {
			addChild(editor = new BitmapEdit(app, this));
		}
	}

	public static function strings():Array {
		return [
			'Clear', 'Add', 'Import', 'New backdrop:', 'New costume:', 'photo1', 'Undo', 'Redo', 'Flip left-right',
			'Flip up-down', 'Set costume center', 'Choose backdrop from library', 'Choose costume from library',
			'Paint new backdrop', 'Upload backdrop from file', 'New backdrop from camera', 'Paint new costume',
			'Upload costume from file', 'New costume from camera',
		];
	}

	public function updateTranslation():void {
		clearButton.setLabel(Translator.map('Clear'));
		libraryButton.setLabel(Translator.map('Add'));
		editorImportButton.setLabel(Translator.map('Import'));
		if (editor) editor.updateTranslation();
		updateLabel();
		fixlayout();
	}

	public function refresh(fromEditor:Boolean = false):void {
		updateLabel();
		backdropLibraryButton.visible = isStage();
		costumeLibraryButton.visible = !isStage();
		(listFrame.contents as MediaPane).refresh();
		if (!fromEditor) selectCostume(); // this refresh is because the editor just saved the costume; do nothing
	}

	private function updateLabel():void {
		newCostumeLabel.text = Translator.map(isStage() ? 'New backdrop:' : 'New costume:')

		SimpleTooltips.add(backdropLibraryButton, {text: 'Choose backdrop from library', direction: 'bottom'});
		SimpleTooltips.add(costumeLibraryButton, {text: 'Choose costume from library', direction: 'bottom'});
		if (isStage()) {
			SimpleTooltips.add(paintButton, {text: 'Paint new backdrop', direction: 'bottom'});
			SimpleTooltips.add(importButton, {text: 'Upload backdrop from file', direction: 'bottom'});
			SimpleTooltips.add(cameraButton, {text: 'New backdrop from camera', direction: 'bottom'});
		}
		else {
			SimpleTooltips.add(paintButton, {text: 'Paint new costume', direction: 'bottom'});
			SimpleTooltips.add(importButton, {text: 'Upload costume from file', direction: 'bottom'});
			SimpleTooltips.add(cameraButton, {text: 'New costume from camera', direction: 'bottom'});
		}
	}

	private function isStage():Boolean { return app.viewedObj() && app.viewedObj().isStage }

	public function step():void {
		(listFrame.contents as MediaPane).updateSelection();
		listFrame.updateScrollbars();
	}

	public function setWidthHeight(w:int, h:int):void {
		this.w = w;
		this.h = h;
		var g:Graphics = shape.graphics;
		g.clear();

		g.lineStyle(0.5, CSS.borderColor, 1, true);
		g.beginFill(CSS.tabColor);
		g.drawRect(0, 0, w, h);
		g.endFill();

		g.lineStyle(0.5, CSS.borderColor, 1, true);
		g.beginFill(CSS.panelColor);
		g.drawRect(columnWidth + 1, 5, w - columnWidth - 6, h - 10);
		g.endFill();

		fixlayout();
	}

	private function fixlayout():void {
		var extraSpace:int = Math.max(0, (w - 590) / 3);
		bigSpace = smallSpace + extraSpace;

		newCostumeLabel.x = 7;
		newCostumeLabel.y = 7;

		listFrame.x = 1;
		listFrame.y = 58;
		listFrame.setWidthHeight(columnWidth, h - listFrame.y);

		var contentsW:int = w - contentsX - 15;
		nameField.setWidth(Math.min(135, contentsW));
		nameField.x = contentsX;
		nameField.y = 15;

		// undo buttons
		undoButton.x = nameField.x + nameField.width + bigSpace;
		redoButton.x = undoButton.right() + smallSpace;
		clearButton.x = redoButton.right() + bigSpace;
		clearButton.y = nameField.y;
		undoButton.y = redoButton.y = nameField.y - 2;

		fixEditorLayout();
		if (parent) refresh();
	}

	public function selectCostume():void {
		var contents:MediaPane = listFrame.contents as MediaPane;
		var changed:Boolean = contents.updateSelection();
		var obj:ScratchObj = app.viewedObj();
		if (obj == null) return;
		nameField.setContents(obj.currentCostume().costumeName);

		var zoomAndScroll:Array = editor.getZoomAndScroll();
		editor.shutdown();
		var c:ScratchCostume = obj.currentCostume();
		useBitmapEditor(c.isBitmap() && !c.text);
		editor.editCostume(c, obj.isStage);
		editor.setZoomAndScroll(zoomAndScroll);
		if (changed) app.setSaveNeeded();
	}

	private function addListFrame():void {
		listFrame = new ScrollFrame();
		listFrame.setContents(app.getMediaPane(app, 'costumes'));
		listFrame.contents.color = CSS.tabColor;
		listFrame.allowHorizontalScrollbar = false;
		addChild(listFrame);
	}

	private function nameChanged():void {
		app.runtime.renameCostume(nameField.contents());
		nameField.setContents(app.viewedObj().currentCostume().costumeName);
		(listFrame.contents as MediaPane).refresh();
	}

	private function addNewCostumeButtons():void {
		var left:int = 8;
		var buttonY:int = 32;
		addChild(backdropLibraryButton = makeButton(costumeFromLibrary, 'landscape', left, buttonY + 1));
		addChild(costumeLibraryButton = makeButton(costumeFromLibrary, 'library', left + 1, buttonY - 2));
		addChild(paintButton = makeButton(paintCostume, 'paintbrush', left + 23, buttonY - 1));
		addChild(importButton = makeButton(costumeFromComputer, 'import', left + 44, buttonY - 2));
		addChild(cameraButton = makeButton(costumeFromCamera, 'camera', left + 72, buttonY));
	}

	public function useBitmapEditor(flag:Boolean):void {
		// Switch editors based on flag. Do nothing if editor is already of the correct type.
		// NOTE: After switching editors, the caller must install costume and other state in the new editor.
		var oldSettings:DrawProperties, oldZoomAndScroll:Array;
		if (editor) {
			oldSettings = editor.getShapeProps();
			oldZoomAndScroll = editor.getWorkArea().getZoomAndScroll();
		}
		if (flag) {
			if (editor is BitmapEdit) return;
			if (editor && editor.parent) removeChild(editor);
			addEditor(false);
		}
		else {
			if (editor is SVGEdit) return;
			if (editor && editor.parent) removeChild(editor);
			addEditor(true);
		}
		if (oldSettings) {
			editor.setShapeProps(oldSettings);
			editor.getWorkArea().setZoomAndScroll([oldZoomAndScroll[0], 0.5, 0.5]);
		}
		editor.registerToolButton('setCenter', centerButton);
		fixEditorLayout();
	}

	private function fixEditorLayout():void {
		var contentsW:int = w - contentsX - 15;
		if (editor) {
			editor.x = contentsX;
			editor.y = 45;
			editor.setWidthHeight(contentsW, h - editor.y - 14);
		}

		contentsW = w - 16;
		// import button
		libraryButton.x = clearButton.x + clearButton.width + smallSpace;
		libraryButton.y = clearButton.y;
		editorImportButton.x = libraryButton.x + libraryButton.width + smallSpace;
		editorImportButton.y = clearButton.y;

		// buttons in the upper right
		centerButton.x = contentsW - centerButton.width;
		flipVButton.x = centerButton.x - flipVButton.width - smallSpace;
		flipHButton.x = flipVButton.x - flipHButton.width - smallSpace;
		cropButton.x = flipHButton.x - cropButton.width - smallSpace;
		cropButton.y = flipHButton.y = flipVButton.y = centerButton.y = nameField.y - 1;
	}

	// -----------------------------
	// Button Creation
	//------------------------------

	private function makeButton(fcn:Function, iconName:String, x:int, y:int):IconButton {
		var b:IconButton = new IconButton(fcn, iconName);
		b.isMomentary = true;
		b.x = x;
		b.y = y;
		return b;
	}

	private function makeTopButton(fcn:Function, iconName:String, isRadioButton:Boolean = false):IconButton {
		return new IconButton(
				fcn, SoundsPart.makeButtonImg(iconName, true, topButtonSize),
				SoundsPart.makeButtonImg(iconName, false, topButtonSize), isRadioButton);
	}

	// -----------------------------
	// Bitmap/Vector Conversion
	//------------------------------

	public function convertToBitmap():void {
		function finishConverting():void {
			var c:ScratchCostume = editor.targetCostume;
			var forStage:Boolean = editor.isScene;
			var zoomAndScroll:Array = editor.getZoomAndScroll();
			useBitmapEditor(true);

			var bm:BitmapData = c.bitmapForEditor(forStage);
			c.setBitmapData(bm, 2 * c.rotationCenterX, 2 * c.rotationCenterY);

			editor.editCostume(c, forStage, true);
			editor.setZoomAndScroll(zoomAndScroll);
			editor.saveContent();
		}
		if (editor is BitmapEdit) return;
		editor.shutdown();
		setTimeout(finishConverting, 300); // hack: allow time for SVG embedded bitmaps to be rendered before rendering
	}

	public function convertToVector():void {
		if (editor is SVGEdit) return;
		editor.shutdown();
		editor.setToolMode('select', true);
		var c:ScratchCostume = editor.targetCostume;
		var forStage:Boolean = editor.isScene;
		var zoomAndScroll:Array = editor.getZoomAndScroll();
		useBitmapEditor(false);

		var svg:SVGElement = new SVGElement('svg');
		var nonTransparentBounds:Rectangle = c.baseLayerBitmap.getColorBoundsRect(0xFF000000, 0x00000000, false);
		if (nonTransparentBounds.width != 0 && nonTransparentBounds.height != 0) {
			svg.subElements.push(SVGElement.makeBitmapEl(c.baseLayerBitmap, 1 / c.bitmapResolution));
		}
		c.rotationCenterX /= c.bitmapResolution;
		c.rotationCenterY /= c.bitmapResolution;
		c.setSVGData(new SVGExport(svg).svgData(), false, false);

		editor.editCostume(c, forStage, true);
		editor.setZoomAndScroll(zoomAndScroll);
//		editor.saveContent();
	}

	// -----------------------------
	// Undo/Redo
	//------------------------------

	private function addUndoButtons():void {
		addChild(undoButton = makeTopButton(undo, 'undo'));
		addChild(redoButton = makeTopButton(redo, 'redo'));
		addChild(clearButton = new Button(Translator.map('Clear'), clear, true));
		addChild(libraryButton = new Button(Translator.map('Add'), importFromLibrary, true));
		addChild(editorImportButton = new Button(Translator.map('Import'), importIntoEditor, true));
		undoButton.isMomentary = true;
		redoButton.isMomentary = true;
		SimpleTooltips.add(undoButton, {text: 'Undo', direction: 'bottom'});
		SimpleTooltips.add(redoButton, {text: 'Redo', direction: 'bottom'});
		SimpleTooltips.add(clearButton, {text: 'Erase all', direction: 'bottom'});
	}

	private function undo(b:*):void { editor.undo(b) }
	private function redo(b:*):void { editor.redo(b) }
	private function clear():void { editor.clearCanvas() }

	private function importFromLibrary():void {
		var type:String = isStage() ? 'backdrop' : 'costume';
		var lib:MediaLibrary = app.getMediaLibrary(type, addCostume);
		lib.open();
	}

	private function importIntoEditor():void {
		var lib:MediaLibrary = app.getMediaLibrary('', addCostume);
		lib.importFromDisk();
	}

	private function addCostume(costumeOrList:*):void {
		var c:ScratchCostume = costumeOrList as ScratchCostume;

		// If they imported a GIF, take the first frame only
		if (!c && costumeOrList is Array)
			c = costumeOrList[0] as ScratchCostume;

		var p:Point = new Point(240, 180);
		editor.addCostume(c, p);
	}

	public function refreshUndoButtons():void {
		if(undoButton){
			undoButton.setDisabled(!(editor.canUndo() || editor.canUndoSegmentation()), 0.5);
		}
		if(redoButton){
			redoButton.setDisabled(!(editor.canRedo() || editor.canRedoSegmentation()), 0.5);
		}
		if(clearButton){
			if (editor.canClearCanvas()) {
				clearButton.alpha = 1;
				clearButton.mouseEnabled = true;
			}
			else {
				clearButton.alpha = 0.5;
				clearButton.mouseEnabled = false;
			}
		}
	}

	public function setCanCrop(enabled:Boolean):void {
		if (enabled) {
			cropButton.alpha = 1;
			cropButton.mouseEnabled = true;
		}
		else {
			cropButton.alpha = 0.5;
			cropButton.mouseEnabled = false;
		}

	}

	// -----------------------------
	// Flip and costume center buttons
	//------------------------------

	private function addFlipButtons():void {
		addChild(cropButton = makeTopButton(crop, 'crop'));
		addChild(flipHButton = makeTopButton(flipH, 'flipH'));
		addChild(flipVButton = makeTopButton(flipV, 'flipV'));
		cropButton.isMomentary = true;
		flipHButton.isMomentary = true;
		flipVButton.isMomentary = true;
		SimpleTooltips.add(cropButton, {text: 'Crop to selection', direction: 'bottom'});
		SimpleTooltips.add(flipHButton, {text: 'Flip left-right', direction: 'bottom'});
		SimpleTooltips.add(flipVButton, {text: 'Flip up-down', direction: 'bottom'});
		setCanCrop(false);
	}

	private function crop(ignore:*):void {
		var bitmapEditor:BitmapEdit = editor as BitmapEdit;
		if (bitmapEditor) {
			bitmapEditor.cropToSelection();
		}
	}
	private function flipH(ignore:*):void { editor.flipContent(false); }
	private function flipV(ignore:*):void { editor.flipContent(true); }

	private function addCenterButton():void {
		function setCostumeCenter(b:IconButton):void {
			editor.setToolMode('setCenter');
			b.lastEvent.stopPropagation();
		}
		centerButton = makeTopButton(setCostumeCenter, 'setCenter', true);
		SimpleTooltips.add(centerButton, {text: 'Set costume center', direction: 'bottom'});
		editor.registerToolButton('setCenter', centerButton);
		addChild(centerButton);
	}

	// -----------------------------
	// New costume/backdrop
	//------------------------------

	private function costumeFromComputer(ignore:* = null):void { importCostume(true) }
	private function costumeFromLibrary(ignore:* = null):void { importCostume(false) }

	private function importCostume(fromComputer:Boolean):void {
		function addCostume(costumeOrSprite:*):void {
			var c:ScratchCostume = costumeOrSprite as ScratchCostume;
			if (c) {
				addAndSelectCostume(c);
				return;
			}
			var spr:ScratchSprite = costumeOrSprite as ScratchSprite;
			if (spr) {
				// If a sprite was selected, add all it's costumes to this sprite.
				for each (c in spr.costumes) addAndSelectCostume(c);
				return;
			}
			var costumeList:Array = costumeOrSprite as Array;
			if (costumeList) {
				for each (c in costumeList) {
					addAndSelectCostume(c);
				}
			}
		}
		var type:String = isStage() ? 'backdrop' : 'costume';
		var lib:MediaLibrary = app.getMediaLibrary(type, addCostume);
		if (fromComputer) lib.importFromDisk();
		else lib.open();
	}

	private function paintCostume(ignore:* = null):void {
		addAndSelectCostume(ScratchCostume.emptyBitmapCostume('', isStage()));
	}

	protected function savePhotoAsCostume(photo:BitmapData):void {
		app.closeCameraDialog();
		var obj:ScratchObj = app.viewedObj();
		if (obj == null) return;
		if (obj.isStage) { // resize photo to stage
			var scale:Number = 480 / photo.width;
			var m:Matrix = new Matrix();
			m.scale(scale, scale);
			var scaledPhoto:BitmapData = new BitmapData(480, 360, true, 0);
			scaledPhoto.draw(photo, m);
			photo = scaledPhoto;
		}
		var c:ScratchCostume = new ScratchCostume(Translator.map('photo1'), photo);
		addAndSelectCostume(c);
		editor.getWorkArea().zoom();
	}

	private function costumeFromCamera(ignore:* = null):void {
		app.openCameraDialog(savePhotoAsCostume);
	}

	private function addAndSelectCostume(c:ScratchCostume):void {
		var obj:ScratchObj = app.viewedObj();
		if (!c.baseLayerData) c.prepareToSave();
		if (!app.okayToAdd(c.baseLayerData.length)) return; // not enough room
		c.costumeName = obj.unusedCostumeName(c.costumeName);
		obj.costumes.push(c);
		obj.showCostume(obj.costumes.length - 1);
		app.setSaveNeeded(true);
		refresh();
	}

	// -----------------------------
	// Help tool
	//------------------------------

	public function handleTool(tool:String, evt:MouseEvent):void {
		var localP:Point = globalToLocal(new Point(stage.mouseX, stage.mouseY));
		if (tool == 'help') {
			if (localP.x > columnWidth) Scratch.app.showTip('paint');
			else Scratch.app.showTip('scratchUI');
		}
	}

}
}
