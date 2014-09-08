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

// StagePart.as
// John Maloney, November 2011
//
// This part frames the Scratch stage and supplies the UI elements around it.
// Note: The Scratch stage is a child of StagePart but is stored in an app instance variable (app.stagePane)
// since it is referred from many places.

package ui.parts {
import flash.display.*;
import flash.events.*;
import flash.text.*;
import assets.Resources;
import scratch.*;
import translation.Translator;

import ui.parts.base.BaseStagePart;

import uiwidgets.*;

public class StagePart extends BaseStagePart {

	private const readoutLabelFormat:TextFormat = new TextFormat(CSS.font, 12, CSS.textColor, true);
	private const readoutFormat:TextFormat = new TextFormat(CSS.font, 10, CSS.textColor);

	private const topBarHeightNormal:int = 39;
	private const topBarHeightSmallPlayerMode:int = 26;

	protected var topBarHeight:int = topBarHeightNormal;

	protected var projectTitle:EditableLabel;
	protected var projectInfo:TextField;
	protected var versionInfo:TextField;
	protected var turboIndicator:TextField;

	private var playButton:Sprite; // YouTube-like play button in center of screen; used by Kiosk version
	private var userNameWarning:Sprite; // Container for privacy warning message for projects that use username block

	// x-y readouts
	private var readouts:Sprite; // readouts that appear below the stage
	private var xLabel:TextField;
	private var xReadout:TextField;
	private var yLabel:TextField;
	private var yReadout:TextField;

	public function StagePart(app:Scratch) {
		super(app);

		addTitleAndInfo();
		addTurboIndicator();
		addXYReadouts();
		fixLayout();
		addEventListener(MouseEvent.MOUSE_WHEEL, mouseWheel);
	}

	public static function strings():Array {
		return [
			'by', 'shared', 'unshared', 'Turbo Mode',
			'This project can detect who is using it, through the “username” block. To hide your identity, sign out before using the project.',
		];
	}

	override public function updateTranslation():void {
		turboIndicator.text = Translator.map('Turbo Mode');
		turboIndicator.x = w - turboIndicator.width - 73;
		updateProjectInfo();
	}

	override public function computeTopBarHeight():int {
		return app.isSmallPlayer ? topBarHeightSmallPlayerMode : topBarHeightNormal;
	}

	override public function installStage(newStage:ScratchStage, showStartButton:Boolean):void {
		super.installStage(newStage, showStartButton);

		if (showStartButton) showPlayButton();
		else hidePlayButton();
	}

	override public function projectName():String { return projectTitle.contents(); }
	override public function setProjectName(s:String):void { projectTitle.setContents(s); }

	override public function refresh():void {
		super.refresh();
		readouts.visible = app.editMode;
		projectTitle.visible = app.editMode;
		projectInfo.visible = app.editMode;
		turboIndicator.visible = app.interp.turboMode;
		if (userNameWarning) userNameWarning.visible = app.usesUserNameBlock;
		if (app.editMode && playButton) hidePlayButton();
		updateProjectInfo();
	}

	// -----------------------------
	// Layout
	//------------------------------

	override protected function drawOutline():void {
		var topBarColors:Array = app.isSmallPlayer ? [CSS.tabColor, CSS.tabColor] : CSS.titleBarColors;

		var g:Graphics = outline.graphics;
		g.clear();
		drawTopBar(g, topBarColors, getTopBarPath(w - 1, topBarHeight), w, topBarHeight, CSS.borderColor);
		g.lineStyle(1, CSS.borderColor, 1, true);
		g.drawRect(0, topBarHeight - 1, w - 1, h - topBarHeight);

		versionInfo.visible = !fullscreenButton.isOn();
	}

	override protected function fixLayout():void {
		if (app.stagePane) app.stagePane.y = topBarHeight;

		projectTitle.x = 50;
		projectTitle.y = app.isOffline ? 8 : 2;
		projectInfo.x = projectTitle.x + 3;
		projectInfo.y = projectTitle.y + 18;

		runButton.x = w - 60;
		runButton.y = int((topBarHeight - runButton.height) / 2);
		stopButton.x = runButton.x + 32;
		stopButton.y = runButton.y + 1;

		turboIndicator.x = w - turboIndicator.width - 73;
		turboIndicator.y = app.isSmallPlayer ? 5 : (app.editMode ? 22 : 12);

		fullscreenButton.x = 11;
		fullscreenButton.y = stopButton.y - 1;

		// version info (only used on old website player)
		versionInfo.x = fullscreenButton.x + 1;
		versionInfo.y = 27;

		projectTitle.setWidth(runButton.x - projectTitle.x - 15);

		// x-y readouts
		var left:int = w - 98; // w - 95
		xLabel.x = left;
		xReadout.x = left + 16;
		yLabel.x = left + 43;
		yReadout.x = left + 60;

		var top:int = h + 1;
		xReadout.y = yReadout.y = top;
		xLabel.y = yLabel.y = top - 2;

		stageSizeButton.x = w - 4;
		stageSizeButton.y = h + 2;

		if (playButton) playButton.scaleX = playButton.scaleY = app.stagePane.scaleX;
	}

	private function addTitleAndInfo():void {
		var fmt:TextFormat = app.isOffline ? new TextFormat(CSS.font, 16, CSS.textColor) : CSS.projectTitleFormat;
		projectTitle = getProjectTitle(fmt);
		addChild(projectTitle);

		addChild(projectInfo = makeLabel('', CSS.projectInfoFormat));

		const versionFormat:TextFormat = new TextFormat(CSS.font, 9, 0x909090);
		addChild(versionInfo = makeLabel(Scratch.versionString, versionFormat));
	}

	protected function getProjectTitle(fmt:TextFormat):EditableLabel {
		return new EditableLabel(null, fmt);
	}

	public function updateVersionInfo(newVersion:String):void {
		versionInfo.text = newVersion;
	}

	private function addTurboIndicator():void {
		turboIndicator = new TextField();
		turboIndicator.defaultTextFormat = new TextFormat(CSS.font, 11, CSS.buttonLabelOverColor, true);
		turboIndicator.autoSize = TextFieldAutoSize.LEFT;
		turboIndicator.selectable = false;
		turboIndicator.text = Translator.map('Turbo Mode');
		turboIndicator.visible = false;
		addChild(turboIndicator);
	}

	protected function addXYReadouts():void {
		readouts = new Sprite();
		addChild(readouts);

		xLabel = makeLabel('x:', readoutLabelFormat);
		readouts.addChild(xLabel);
		xReadout = makeLabel('-888', readoutFormat);
		readouts.addChild(xReadout);

		yLabel = makeLabel('y:', readoutLabelFormat);
		readouts.addChild(yLabel);
		yReadout = makeLabel('-888', readoutFormat);
		readouts.addChild(yReadout);
	}

	protected function updateProjectInfo():void {
		projectTitle.setEditable(false);
		projectInfo.text = '';
	}

	// -----------------------------
	// Stepping
	//------------------------------

	override public function step():void {
		super.step();
		if (app.editMode) updateMouseReadout();
	}

	private var lastX:int, lastY:int;
	protected function updateMouseReadout():void {
		// Update the mouse reaadouts. Do nothing if they are up-to-date (to minimize CPU load).
		if (stage.mouseX != lastX) {
			lastX = app.stagePane.scratchMouseX();
			xReadout.text = String(lastX);
		}
		if (stage.mouseY != lastY) {
			lastY = app.stagePane.scratchMouseY();
			yReadout.text = String(lastY);
		}
	}

	// -----------------------------
	// Run/Stop/Fullscreen Buttons
	//------------------------------

	override public function threadStarted():void {
		super.threadStarted();
		if (playButton) hidePlayButton();
	}

	// -----------------------------
	// Play Button
	//------------------------------

	private function showPlayButton():void {
		// The play button is a YouTube-like button the covers the entire stage.
		// Used by the player to ensure that the user clicks on the SWF to start
		// the project, which ensures that the SWF gets keyboard focus.
		if (!playButton) {
			playButton = new Sprite();
			playButton.graphics.beginFill(0, 0.3);
			playButton.graphics.drawRect(0, 0, 480, 360);
			var flag:Bitmap = Resources.createBmp('playerStartFlag');
			flag.x = (480 - flag.width) / 2;
			flag.y = (360 - flag.height) / 2;
			playButton.alpha = .9;
			playButton.addChild(flag);
			playButton.addEventListener(MouseEvent.MOUSE_DOWN, stopEvent, false, 9);
			playButton.addEventListener(MouseEvent.MOUSE_UP, playProject, false, 9);
			addUserNameWarning();
		}
		playButton.scaleX = playButton.scaleY = app.stagePane.scaleX;
		playButton.x = app.stagePane.x;
		playButton.y = app.stagePane.y;
		addChild(playButton);
	}

	public function addUserNameWarning():void {
		userNameWarning = new Sprite();
		var g:Graphics = userNameWarning.graphics;
		g.clear();
		g.beginFill(CSS.white);
		g.drawRoundRect(10, 30, playButton.width - 20, 70, 15, 15);
		g.endFill();
		userNameWarning.alpha = 0.9;

		const versionFormat:TextFormat = new TextFormat(CSS.font, 16, 0x000000);
		var userNameWarningText:TextField = makeLabel(Translator.map('This project can detect who is using it, through the “username” block. To hide your identity, sign out before using the project.'), versionFormat, 15, 45);
		userNameWarningText.width = userNameWarning.width - 10;
		userNameWarningText.multiline = true;
		userNameWarningText.wordWrap = true;

		userNameWarning.addChild(userNameWarningText);
		playButton.addChild(userNameWarning);

		userNameWarning.visible = false; // Don't show this by default
	}

	override public function playProject(evt:MouseEvent):void {
		super.playProject(evt);

		if(!app.loadInProgress && !evt.shiftKey)
			hidePlayButton();
	}

	override public function hidePlayButton():void {
		if (playButton) removeChild(playButton);
		playButton = null;
	}

	private function mouseWheel(evt:MouseEvent):void {
		evt.preventDefault();
		app.runtime.startKeyHats(evt.delta > 0 ? 30 : 31);
	}
}}
