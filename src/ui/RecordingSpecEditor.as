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

package ui {
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.text.*;
	import assets.Resources;
	import blocks.*;
	import uiwidgets.*;
	import util.*;
	import translation.Translator;

public class RecordingSpecEditor extends Sprite {

	private var base:Shape;
	private var row:Array = [];

	private var description:TextField;
	private var notSavedLabel:TextField;
	private var pleaseNoteLabel:TextField;
	private var moreLabel:TextField;
	private var moreButton:IconButton;
	private var checkboxLabels:Array = [];
	private var checkboxes:Array = [];
	private var micVolumeSlider:Slider;
	private var topBar:Shape;
	private var bottomBar:Shape;

	private var toggleOn:Boolean;
	private var slotColor:int = 0xBBBDBF;
	private const labelColor:int = 0x8738bf; // 0x6c36b3; // 0x9c35b3;

	public function RecordingSpecEditor() {
		addChild(base = new Shape());
		setWidthHeight(440, 10);

		addChild(description = makeLabel('Capture and download a video of your project to your computer.\nYou can record up to 60 seconds of video.',14));
		addChild(notSavedLabel = makeLabel('that the video will not be saved on Scratch.',14));
		addChild(pleaseNoteLabel = makeLabel('Please note',14,true));
		addChild(moreLabel = makeLabel('More Options', 14));
		moreLabel.addEventListener(MouseEvent.MOUSE_DOWN, toggleButtons);
		var format:TextFormat = new TextFormat();
		format.align = TextFormatAlign.CENTER;
		format.leading = 5;
		description.setTextFormat(format);
		
		topBar = new Shape();
		bottomBar = new Shape();
		const slotRadius:int = 9;
		var g:Graphics = topBar.graphics;
		g.clear();
		g.beginFill(slotColor);
		g.drawRoundRect(0, 0, 400, 1, slotRadius, slotRadius);
		g.endFill();
		var gr:Graphics = bottomBar.graphics;
		gr.clear();
		gr.beginFill(slotColor);
		gr.drawRoundRect(0, 0, 400, 1, slotRadius, slotRadius);
		gr.endFill();
		addChild(topBar);
		addChild(bottomBar);
		
		addChild(moreButton = new IconButton(toggleButtons, 'toggle'));
		
		moreButton.disableMouseover();

		addCheckboxesAndLabels();

		checkboxes[0].setOn(true);
		showButtons(false);
		fixLayout();
	}

	private function setWidthHeight(w:int, h:int):void {
		var g:Graphics = base.graphics;
		g.clear();
		g.beginFill(CSS.white);
		g.drawRect(0, 0, w, h);
		g.endFill();
	}

	public function spec():String {
		var result:String = '';
		for each (var o:* in row) {
			if (o is TextField) result += ReadStream.escape(TextField(o).text);
			if ((result.length > 0) && (result.charAt(result.length - 1) != ' ')) result += ' ';
		}
		if ((result.length > 0) && (result.charAt(result.length - 1) == ' ')) result = result.slice(0, result.length - 1);
		return result;
	}

	public function soundFlag():Boolean {
		// True if the 'include sound from project' box is checked.
		return checkboxes[0].isOn();
	}
	
	public function editorFlag():Boolean {
		return checkboxes[3].isOn();
	}

	public function microphoneFlag():Boolean {
		// True if the 'include sound from microphone' box is checked.
		return checkboxes[1].isOn();
	}
	
	public function cursorFlag():Boolean {
		return checkboxes[2].isOn();
	}
	
	public function fifteenFlag():Boolean {
		return checkboxes[4].isOn();
	}

	private function addCheckboxesAndLabels():void {
		checkboxLabels = [
		makeLabel('Include sound from project', 14),
		makeLabel('Include sound from microphone', 14),
		makeLabel('Show mouse pointer',14),
		makeLabel('Record entire editor (may run slowly)',14),
		makeLabel('Record at highest quality (may run slowly)',14),
		];
		function disable():void {
			if (editorFlag()) {
				checkboxes[4].setDisabled(true,.4);
			}
			else {
				checkboxes[4].setDisabled(false);
			}
		}
		function hideVolume():void {
			if (microphoneFlag()) {
				addChild(micVolumeSlider)
			}
			else {
				removeChild(micVolumeSlider)
			}
		}
		checkboxes = [
		new IconButton(null, 'checkbox'),
		new IconButton(hideVolume, 'checkbox'),
		new IconButton(null, 'checkbox'),
		new IconButton(disable, 'checkbox'),
		new IconButton(null, 'checkbox'),
		];
		var c:int=0;
		for each (var label:TextField in checkboxLabels) {
			function toggleCheckbox(e:MouseEvent):void {
				var box:IconButton;
				box = checkboxes[checkboxLabels.indexOf(e.currentTarget)];
				box.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN));
			}
			c=c+1;
			label.addEventListener(MouseEvent.MOUSE_DOWN, toggleCheckbox);
			 addChild(label);
		}
		for each (var b:IconButton in checkboxes) {
			b.disableMouseover();
			addChild(b);
		}
		micVolumeSlider = new Slider(75, 10, null,true);
		micVolumeSlider.min = 1;
		micVolumeSlider.max = 100;
		micVolumeSlider.value = 50;
	}

	public function getMicVolume():int {
		return micVolumeSlider.value;
	}
	
	private function makeLabel(s:String, fontSize:int,bold:Boolean = false):TextField {
		var tf:TextField = new TextField();
		tf.selectable = false;
		tf.defaultTextFormat = new TextFormat(CSS.font, fontSize, CSS.textColor,bold);
		tf.autoSize = TextFieldAutoSize.LEFT;
		tf.text = Translator.map(s);
		addChild(tf);
		return tf;
	}

	private function toggleButtons(ignore:*):void {
		showButtons(!toggleOn)
		removeChild(moreLabel)
		if (toggleOn) {
			addChild(moreLabel = makeLabel('Fewer Options', 14))
		}
		else {
			addChild(moreLabel = makeLabel('More Options', 14))
		}
		moreLabel.addEventListener(MouseEvent.MOUSE_DOWN, toggleButtons);
		fixLayout()
	}

	private function showButtons(showParams:Boolean):void {
		var label:TextField, b:IconButton,i:int;
		var height:int = 140;
		if (showParams) {
			height+=14
			toggleOn = true;
			for (i=1; i<checkboxLabels.length; i++) {
				label = checkboxLabels[i];
				height+=label.height+7;
				addChild(label);
			}
			for (i=1; i<checkboxes.length; i++) addChild(checkboxes[i]);
			if (microphoneFlag()) addChild(micVolumeSlider);
		} else {
			toggleOn = false;
			for (i=1; i<checkboxLabels.length; i++) {
				label = checkboxLabels[i];
				if (label.parent) removeChild(label);
			}
			for (i=1; i<checkboxes.length; i++) removeChild(checkboxes[i]);
			if (microphoneFlag()) removeChild(micVolumeSlider);
		}

		moreButton.setOn(showParams);

		setWidthHeight(base.width, height);
		if (parent is DialogBox) DialogBox(parent).fixLayout();
	}

	private function appendObj(o:DisplayObject):void {
		row.push(o);
		addChild(o);
		if (stage) {
			if (o is TextField) stage.focus = TextField(o);
		}
		fixLayout();
	}

	private function makeTextField(contents:String):TextField {
		var result:TextField = new TextField();
		result.borderColor = 0;
		result.backgroundColor = labelColor;
		result.background = true;
		result.type = TextFieldType.INPUT;
		result.defaultTextFormat = Block.blockLabelFormat;
		if (contents.length > 0) {
			result.width = 1000;
			result.text = contents;
			result.width = Math.max(10, result.textWidth + 2);
		} else {
			result.width = 27;
		}
		result.height = result.textHeight + 5;
		return result;
	}

	private function fixLayout(updateDelete:Boolean = true):void {
		description.x = (440-description.width)/2;
		description.y = 0;
		
		topBar.x = 20;
		topBar.y = 48;
		
		var buttonX:int = 30;

		var rowY:int = 62;
		for (var i:int = 0; i < checkboxes.length; i++) {
			var label:TextField = checkboxLabels[i];
			checkboxes[i].x = buttonX;
			checkboxes[i].y = rowY - 4;
			checkboxLabels[i].x = checkboxes[i].x+20;
			checkboxLabels[i].y = checkboxes[i].y-3;
			if (i==1) {
				micVolumeSlider.x = checkboxLabels[i].x+checkboxLabels[i].width+15;
				micVolumeSlider.y = checkboxes[i].y+4;
			}
			rowY += 30;
		}
		if (toggleOn) {
			moreButton.x = buttonX+1;
			moreButton.y = rowY-5;
	
			moreLabel.x = moreButton.x+10;
			moreLabel.y = moreButton.y - 4;
		}
		else {
			moreButton.x = buttonX+1;
			moreButton.y = 85;
	
			moreLabel.x = moreButton.x+10;
			moreLabel.y = moreButton.y - 4;
		}
		
		bottomBar.x = 20;
		bottomBar.y = moreButton.y+20;
			
		notSavedLabel.x = (440-notSavedLabel.width-pleaseNoteLabel.width)/2+pleaseNoteLabel.width;
		notSavedLabel.y = bottomBar.y+7;
		
		pleaseNoteLabel.x = (440-notSavedLabel.width-pleaseNoteLabel.width)/2;
		pleaseNoteLabel.y = bottomBar.y+7;
		

		if (parent is DialogBox) DialogBox(parent).fixLayout();
	}
}}

