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

// SoundsPart.as
// John Maloney, November 2011
//
// This part holds the sounds list for the current sprite (or stage),
// as well as the sound recorder, editor, and import button.

package ui.parts {
	import flash.display.*;
	import flash.events.KeyboardEvent;
	import flash.geom.*;
	import flash.text.*;
	import assets.Resources;
	import scratch.*;
	import sound.WAVFile;
	import soundedit.SoundEditor;
	import translation.Translator;
	import ui.media.*;
	import uiwidgets.*;

public class SoundsPart extends UIPart {

	public var editor:SoundEditor;
	public var currentIndex:int;

	private const columnWidth:int = 106;

	private var shape:Shape;
	private var listFrame:ScrollFrame;
	private var nameField:EditableLabel;
	private var undoButton:IconButton;
	private var redoButton:IconButton;

	private var newSoundLabel:TextField;
	private var libraryButton:IconButton;
	private var importButton:IconButton;
	private var recordButton:IconButton;

	public function SoundsPart(app:Scratch) {
		this.app = app;
		addChild(shape = new Shape());

		addChild(newSoundLabel = makeLabel('', new TextFormat(CSS.font, 12, CSS.textColor, true)));
		addNewSoundButtons();

		addListFrame();
		addChild(nameField = new EditableLabel(nameChanged));
		addChild(editor = new SoundEditor(app, this));
		addUndoButtons();
		app.stage.addEventListener(KeyboardEvent.KEY_DOWN, editor.keyDown);
		updateTranslation();
	}

	public static function strings():Array {
		new SoundsPart(Scratch.app).showNewSoundMenu(Menu.dummyButton());
		return [
			'New sound:', 'recording1',
			'Choose sound from library', 'Record new sound', 'Upload sound from file',
		];
	}

	public function updateTranslation():void {
		newSoundLabel.text = Translator.map('New sound:');
		editor.updateTranslation();
		SimpleTooltips.add(libraryButton, {text: 'Choose sound from library', direction: 'bottom'});
		SimpleTooltips.add(recordButton, {text: 'Record new sound', direction: 'bottom'});
		SimpleTooltips.add(importButton, {text: 'Upload sound from file', direction: 'bottom'});
		fixlayout();
	}

	public function selectSound(snd:ScratchSound):void{
		var obj:ScratchObj = app.viewedObj();
		if (obj == null) return;
		if (obj.sounds.length == 0) return;
		currentIndex = 0;
		for (var i:int = 0; i < obj.sounds.length; i++) {
			if ((obj.sounds[i] as ScratchSound) == snd) currentIndex = i;
		}
		(listFrame.contents as MediaPane).updateSelection();
		refresh(false);
	}

	public function refresh(refreshListContents:Boolean = true):void {
		if (refreshListContents) {
			var contents:MediaPane = listFrame.contents as MediaPane;
			contents.refresh();
		}

		nameField.setContents('');
		var viewedObj:ScratchObj = app.viewedObj();
		if (viewedObj.sounds.length < 1) {
			nameField.visible = false;
			editor.visible = false;
			undoButton.visible = false;
			redoButton.visible = false;
			return;
		} else {
			nameField.visible = true;
			editor.visible = true;
			undoButton.visible = true;
			redoButton.visible = true;
			refreshUndoButtons();
		}

		editor.waveform.stopAll();
		var snd:ScratchSound = viewedObj.sounds[currentIndex];
		if (snd) {
			nameField.setContents(snd.soundName);
			editor.waveform.editSound(snd);
		}
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
		newSoundLabel.x = 7;
		newSoundLabel.y = 7;

		listFrame.x = 1;
		listFrame.y = 58;
		listFrame.setWidthHeight(columnWidth, h - listFrame.y);

		var contentsX:int = columnWidth + 13;
		var contentsW:int = w - contentsX - 15;

		nameField.setWidth(Math.min(135, contentsW));
		nameField.x = contentsX;
		nameField.y = 15;

		// undo buttons
		undoButton.x = nameField.x + nameField.width + 30;
		redoButton.x = undoButton.right() + 8;
		undoButton.y = redoButton.y = nameField.y - 2;

		editor.setWidthHeight(contentsW, 200);
		editor.x = contentsX;
		editor.y = 50;
	}

	private function addNewSoundButtons():void {
		var left:int = 16;
		var buttonY:int = 31;
		addChild(libraryButton = makeButton(soundFromLibrary, 'soundlibrary', left, buttonY));
		addChild(recordButton = makeButton(recordSound, 'record', left + 34, buttonY));
		addChild(importButton = makeButton(soundFromComputer, 'import', left + 61, buttonY - 1));
	}

	private function makeButton(fcn:Function, iconName:String, x:int, y:int):IconButton {
		var b:IconButton = new IconButton(fcn, iconName);
		b.isMomentary = true;
		b.x = x;
		b.y = y;
		return b;
	}

	private function addListFrame():void {
		listFrame = new ScrollFrame();
		listFrame.setContents(app.getMediaPane(app, 'sounds'));
		listFrame.contents.color = CSS.tabColor;
		listFrame.allowHorizontalScrollbar = false;
		addChild(listFrame);
	}

	// -----------------------------
	// Sound Name
	//------------------------------

	private function nameChanged():void {
		currentIndex = Math.min(currentIndex, app.viewedObj().sounds.length - 1);
		var current:ScratchSound = app.viewedObj().sounds[currentIndex] as ScratchSound;
		app.runtime.renameSound(current, nameField.contents());
		nameField.setContents(current.soundName);
		(listFrame.contents as MediaPane).refresh();
	}

	// -----------------------------
	// Undo/Redo
	//------------------------------

	private function addUndoButtons():void {
		addChild(undoButton = new IconButton(editor.waveform.undo, makeButtonImg('undo', true), makeButtonImg('undo', false)));
		addChild(redoButton = new IconButton(editor.waveform.redo, makeButtonImg('redo', true), makeButtonImg('redo', false)));
		undoButton.isMomentary = true;
		redoButton.isMomentary = true;
	}

	public function refreshUndoButtons():void {
		undoButton.setDisabled(!editor.waveform.canUndo(), 0.5);
		redoButton.setDisabled(!editor.waveform.canRedo(), 0.5);
	}

	public static function makeButtonImg(iconName:String, isOn:Boolean, buttonSize:Point = null):Sprite {
		var icon:Bitmap = Resources.createBmp(iconName + (isOn ? 'On' : 'Off'));
		var buttonW:int = Math.max(icon.width, buttonSize ? buttonSize.x : 24);
		var buttonH:int = Math.max(icon.height, buttonSize ? buttonSize.y : 24);

		var img:Sprite = new Sprite();
		var g:Graphics = img.graphics;
		g.clear();
		g.lineStyle(0.5, CSS.borderColor, 1, true);
		if (isOn) {
			g.beginFill(CSS.overColor);
		} else {
			var m:Matrix = new Matrix();
			m.createGradientBox(24, 24, Math.PI / 2, 0, 0);
			g.beginGradientFill(GradientType.LINEAR, CSS.titleBarColors , [100, 100], [0x00, 0xFF], m);
		}
		g.drawRoundRect(0, 0, buttonW, buttonH, 8);
		g.endFill();

		icon.x = (buttonW - icon.width) / 2;
		icon.y = (buttonH - icon.height) / 2;
		img.addChild(icon);
		return img;
	}

	// -----------------------------
	// Menu
	//------------------------------

	private function showNewSoundMenu(b:IconButton):void {
		var m:Menu = new Menu(null, 'New Sound', 0xB0B0B0, 28);
		m.minWidth = 90;
		m.addItem('Library', soundFromLibrary);
		m.addItem('Record', recordSound);
		m.addItem('Import', soundFromComputer);
		var p:Point = b.localToGlobal(new Point(0, 0));
		m.showOnStage(stage, p.x - 1, p.y + b.height - 2);
	}

	public function soundFromLibrary(b:* = null):void {
		app.getMediaLibrary("sound", app.addSound).open();
	}

	public function soundFromComputer(b:* = null):void {
		app.getMediaLibrary("sound", app.addSound).importFromDisk();
	}

	public function recordSound(b:* = null):void {
		var newName:String = app.viewedObj().unusedSoundName(Translator.map('recording1'));
		app.addSound(new ScratchSound(newName, WAVFile.empty()));
	}

}}
