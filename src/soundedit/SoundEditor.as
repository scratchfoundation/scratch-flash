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

// SoundEditor.as
// John Maloney, June 2012

package soundedit {
	import flash.display.*;
	import flash.events.KeyboardEvent;
	import flash.geom.*;
	import flash.media.Microphone;
	import flash.text.*;
	import assets.Resources;
	import translation.*;
	import ui.parts.*;
	import uiwidgets.*;

public class SoundEditor extends Sprite {

	private const waveHeight:int = 170;
	private const borderColor:int = 0x606060;
	private const bgColor:int = 0xF0F0F0;
	private const cornerRadius:int = 20;

	public var app:Scratch;

	private static var microphone:Microphone = Microphone.getMicrophone();

	public var waveform:WaveformView;
	public var levelMeter:SoundLevelMeter;
	public var scrollbar:Scrollbar;

	private var buttons:Array = [];
	private var playButton:IconButton;
	private var stopButton:IconButton;
	private var recordButton:IconButton;

	private var editButton:IconButton;
	private var effectsButton:IconButton;

	private var recordIndicator:Shape;
	private var playIndicator:Shape;

	private var micVolumeLabel:TextField;
	private var micVolumeSlider:Slider;

	public function SoundEditor(app:Scratch, soundsPart:SoundsPart) {
		this.app = app;
		addChild(levelMeter = new SoundLevelMeter(12, waveHeight));
		addChild(waveform = new WaveformView(this, soundsPart));
		addChild(scrollbar = new Scrollbar(10, 10, waveform.setScroll));
		addControls();
		addIndicators();
		addEditAndEffectsButtons();
		addMicVolumeSlider();
		updateIndicators();
	}

	public static function strings():Array {
		var editor:SoundEditor = new SoundEditor(null, null);
		editor.editMenu(Menu.dummyButton());
		editor.effectsMenu(Menu.dummyButton());
		return ['Edit', 'Effects', 'Microphone volume:'];
	}

	public function updateTranslation():void {
		if (editButton.parent) {
			removeChild(editButton);
			removeChild(effectsButton);
		}
		micVolumeLabel.text = Translator.map('Microphone volume:');
		addEditAndEffectsButtons();
		setWidthHeight(width, height);
	}

	public function shutdown():void { waveform.stopAll() }

	public function setWidthHeight(w:int, h:int):void {
		levelMeter.x = 0;
		levelMeter.y = 0;
		waveform.x = 23;
		waveform.y = 0;
		scrollbar.x = 25;
		scrollbar.y = waveHeight + 5;

		var waveWidth:int = w - waveform.x;
		waveform.setWidthHeight(waveWidth, waveHeight);
		scrollbar.setWidthHeight(waveWidth, 10);

		var nextX:int = waveform.x - 2;
		var buttonY:int = waveform.y + waveHeight + 25;
		for each (var b:IconButton in buttons) {
			b.x = nextX;
			b.y = buttonY;
			nextX += b.width + 8;
		}
		editButton.x = nextX + 20;
		editButton.y = buttonY;

		effectsButton.x = editButton.x + editButton.width + 15;
		effectsButton.y = editButton.y;

		recordIndicator.x = recordButton.x + 9;
		recordIndicator.y = recordButton.y + 8;

		playIndicator.x = playButton.x + 12;
		playIndicator.y = playButton.y + 7;

		micVolumeSlider.x = micVolumeLabel.x + micVolumeLabel.textWidth + 15;
		micVolumeSlider.y = micVolumeLabel.y + 7;
	}

	private function addControls():void {
		playButton = new IconButton(waveform.startPlaying, 'playSnd', null, true);
		stopButton = new IconButton(waveform.stopAll, 'stopSnd', null, true);
		recordButton = new IconButton(waveform.toggleRecording, 'recordSnd', null, true);

		buttons = [playButton, stopButton, recordButton];
		for each (var b:IconButton in buttons) {
			if (b is IconButton) b.isMomentary = true;
			addChild(b);
		}
	}

	private function addEditAndEffectsButtons():void {
		addChild(editButton = UIPart.makeMenuButton('Edit', editMenu, true, CSS.textColor));
		addChild(effectsButton = UIPart.makeMenuButton('Effects', effectsMenu, true, CSS.textColor));
	}

	private function addMicVolumeSlider():void {
		function setMicLevel(level:Number):void {
			if(microphone) microphone.gain = level;
		}

		addChild(micVolumeLabel = Resources.makeLabel(Translator.map('Microphone volume:'), CSS.normalTextFormat, 22, 240));

		micVolumeSlider = new Slider(130, 5, setMicLevel);
		micVolumeSlider.min = 1;
		micVolumeSlider.max = 100;
		micVolumeSlider.value = 50;
		addChild(micVolumeSlider);
	}

	private function addIndicators():void {
		recordIndicator = new Shape();
		var g:Graphics = recordIndicator.graphics;
		g.beginFill(0xFF0000);
		g.drawCircle(8, 8, 8)
		g.endFill();
		addChild(recordIndicator);

		playIndicator = new Shape();
		g = playIndicator.graphics;
		g.beginFill(0xFF00);
		g.moveTo(0, 0);
		g.lineTo(11, 8);
		g.lineTo(11, 10);
		g.lineTo(0, 18);
		g.endFill();
		addChild(playIndicator);
	}

	public function updateIndicators():void {
		recordIndicator.visible = waveform.isRecording();
		playIndicator.visible = waveform.isPlaying();
		if (microphone) micVolumeSlider.value = microphone.gain;
	}

	/* Menus */

	private function editMenu(b:IconButton):void {
		var m:Menu = new Menu();
		m.addItem('undo', waveform.undo);
		m.addItem('redo', waveform.redo);
		m.addLine();
		m.addItem('cut', waveform.cut);
		m.addItem('copy', waveform.copy);
		m.addItem('paste', waveform.paste);
		m.addLine();
		m.addItem('delete', waveform.deleteSelection);
		m.addItem('select all', waveform.selectAll);
		var p:Point = b.localToGlobal(new Point(0, 0));
		m.showOnStage(stage, p.x + 1, p.y + b.height - 1);
	}

	private function effectsMenu(b:IconButton):void {
		function applyEffect(selection:String):void { waveform.applyEffect(selection, shiftKey) }
		var shiftKey:Boolean = b.lastEvent.shiftKey;
		var m:Menu = new Menu(applyEffect);
		m.addItem('fade in');
		m.addItem('fade out');
		m.addLine();
		m.addItem('louder');
		m.addItem('softer');
		m.addItem('silence');
		m.addLine();
		m.addItem('reverse');
		var p:Point = b.localToGlobal(new Point(0, 0));
		m.showOnStage(stage, p.x + 1, p.y + b.height - 1);
	}

	/* Keyboard Shortcuts */

	public function keyDown(evt:KeyboardEvent):void {
		if (!stage || stage.focus) return; // sound editor is hidden or someone else has keyboard focus; do nothing
		var k:int = evt.keyCode;
		if ((k == 8) || (k == 127)) waveform.deleteSelection(evt.shiftKey);
		if (k == 37) waveform.leftArrow();
		if (k == 39) waveform.rightArrow();
		if (evt.ctrlKey || evt.shiftKey) { // shift or control key commands (control keys may be grabbed by the browser on Windows...)
			switch (String.fromCharCode(k)) {
			case 'A': waveform.selectAll(); break;
			case 'C': waveform.copy(); break;
			case 'V': waveform.paste(); break;
			case 'X': waveform.cut(); break;
			case 'Y': waveform.redo(); break;
			case 'Z': waveform.undo(); break;
			}
		}
		if (!evt.ctrlKey) {
			var ch:String = String.fromCharCode(evt.charCode);
			if (ch == ' ') waveform.togglePlaying();
			if (ch == '+') waveform.zoomIn();
			if (ch == '-') waveform.zoomOut();
		}
	}

}}
