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

package ui.parts.base {
import ui.parts.*;
import flash.display.*;
import flash.events.*;
import flash.media.*;
import scratch.*;
import uiwidgets.*;

public class BaseStagePart extends UIPart {

	protected var outline:Shape;
	protected var runButton:IconButton;
	protected var stopButton:IconButton;
	protected var fullscreenButton:IconButton;
	protected var stageSizeButton:Sprite;

	protected var runButtonOnTicks:int;
	private var projectTitle:String;

	public function BaseStagePart(app:Scratch) {
		this.app = app;
		outline = new Shape();
		addChild(outline);
		addRunStopButtons();
		addFullScreenButton();
		addStageSizeButton();
	}

	public function findMouseTargetOnStage(globalX:int, globalY:int):DisplayObject {
		// Find the front-most, visible stage element at the given point.
		// Take sprite shape into account so you can click or grab a sprite
		// through a hole in another sprite that is in front of it.
		// Return the stage if no other object is found.
		if(app.isIn3D) app.stagePane.visible = true;
		var uiLayer:Sprite = app.stagePane.getUILayer();
		for (var i:int = uiLayer.numChildren - 1; i > 0; --i) {
			var o:DisplayObject = uiLayer.getChildAt(i) as DisplayObject;
			if (o is Bitmap) break; // hit the paint layer of the stage; no more elments
			if (o.visible && o.hitTestPoint(globalX, globalY, true)) {
				if(app.isIn3D) app.stagePane.visible = false;
				return o;
			}
		}
		if(app.stagePane != uiLayer) {
			for (i = app.stagePane.numChildren - 1; i > 0; --i) {
				o = app.stagePane.getChildAt(i) as DisplayObject;
				if (o is Bitmap) break; // hit the paint layer of the stage; no more elments
				if (o.visible && o.hitTestPoint(globalX, globalY, true)) {
					if(app.isIn3D) app.stagePane.visible = false;
					return o;
				}
			}
		}

		if(app.isIn3D) app.stagePane.visible = false;
		return null;
	}

	public function projectName():String { return projectTitle; }
	public function setProjectName(s:String):void { projectTitle = s; }

	public function setWidthHeight(w:int, h:int, scale:Number):void {
		this.w = w;
		this.h = h;
		if (app.stagePane && app.stagePane.scaleX != scale) {
			app.stagePane.scaleX = app.stagePane.scaleY = scale;
			var stagePane:ScratchStage = app.stagePane;
			for(var i:int=0; i<stagePane.numChildren; ++i) {
				var spr:ScratchSprite = (stagePane.getChildAt(i) as ScratchSprite);
				if(spr) {
					spr.clearCachedBitmap();
					spr.updateCostume();
					spr.applyFilters();
				}
			}
			stagePane.clearCachedBitmap();
			stagePane.updateCostume();
			stagePane.applyFilters();
		}
		drawOutline();
		fixLayout();
	}

	private var firstPlay:Boolean = false;
	public function installStage(newStage:ScratchStage, showStartButton:Boolean):void {
		var scale:Number = app.stageIsContracted ? 0.5 : 1;
		if (app.stagePane != null && app.stagePane.parent != null) {
			scale = app.stagePane.scaleX;
			app.stagePane.parent.removeChild(app.stagePane); // remove old stage
		}
		newStage.x = 1;
		newStage.y = 1;
		newStage.scaleX = newStage.scaleY = scale;
		addChild(newStage);
		app.stagePane = newStage;
		firstPlay = true;
		app.fixLayout();
	}

	public function isInPresentationMode():Boolean { return fullscreenButton.visible && fullscreenButton.isOn(); }
	public function exitPresentationMode():void {
		fullscreenButton.setOn(false);
		drawOutline();
		refresh();
	}

	public function refresh():void {
		stageSizeButton.visible = app.editMode;
		fullscreenButton.visible = !app.isSmallPlayer;
		if (app.editMode) {
			fullscreenButton.setOn(false);
			drawStageSizeButton();
		}
	}

	// -----------------------------
	// Layout
	//------------------------------

	protected function drawOutline():void {}
	protected function fixLayout():void {}

	public function updateTranslation():void {}
	public function computeTopBarHeight():int { return 0; }

	// -----------------------------
	// Stepping
	//------------------------------

	public function step():void {
		updateRunStopButtons();
	}

	protected function updateRunStopButtons():void {
		// Update the run/stop buttons.
		// Note: To ensure that the user sees at least a flash of the
		// on button, it stays on a minumum of two display cycles.
		if (app.interp.threadCount() > 0) threadStarted();
		else if (runButtonOnTicks > 2) {
			runButton.turnOff();
			stopButton.turnOn();
		}
		runButtonOnTicks++;
	}

	// -----------------------------
	// Run/Stop/Fullscreen Buttons
	//------------------------------

	public function threadStarted():void {
		runButtonOnTicks = 0;
		runButton.turnOn();
		stopButton.turnOff();
	}

	protected function addRunStopButtons():void {
		function startAll(b:IconButton):void { playProject(b.lastEvent) }
		function stopAll(b:IconButton):void { app.runtime.stopAll() }
		runButton = new IconButton(startAll, 'greenflag');
		runButton.actOnMouseUp();
		addChild(runButton);
		stopButton = new IconButton(stopAll, 'stop');
		addChild(stopButton);
	}

	protected function addFullScreenButton():void {
		function toggleFullscreen(b:IconButton):void {
			app.setPresentationMode(b.isOn());
			drawOutline();
		}
		fullscreenButton = new IconButton(toggleFullscreen, 'fullscreen');
		fullscreenButton.disableMouseover();
		addChild(fullscreenButton);
	}

	private function addStageSizeButton():void {
		function toggleStageSize(evt:*):void {
			app.toggleSmallStage();
		}
		stageSizeButton = new Sprite();
		stageSizeButton.addEventListener(MouseEvent.MOUSE_DOWN, toggleStageSize);
		drawStageSizeButton();
		addChild(stageSizeButton);
	}

	private function drawStageSizeButton():void {
		var g:Graphics = stageSizeButton.graphics;
		g.clear();

		// draw tab
		g.lineStyle(1, CSS.borderColor);
		g.beginFill(CSS.tabColor);
		g.moveTo(10, 0);
		g.lineTo(3, 0);
		g.lineTo(0, 3);
		g.lineTo(0, 13);
		g.lineTo(3, 15);
		g.lineTo(10, 15);

		// draw arrow
		g.lineStyle();
		g.beginFill(CSS.arrowColor);
		if (app.stageIsContracted) {
			g.moveTo(3, 3.5);
			g.lineTo(9, 7.5);
			g.lineTo(3, 12);
		} else {
			g.moveTo(8, 3.5);
			g.lineTo(2, 7.5);
			g.lineTo(8, 12);
		}
		g.endFill();
	}

	// -----------------------------
	// Play Button
	//------------------------------

	protected function stopEvent(e:Event):void {
		e.stopImmediatePropagation();
		e.preventDefault();
	}

	public function playProject(evt:MouseEvent):void {
		if(app.loadInProgress) {
			stopEvent(evt);
			return;
		}

		// Mute the project if it was started with the control key down
		SoundMixer.soundTransform = new SoundTransform((evt && evt.ctrlKey ? 0 : 1));

		if (evt && evt.shiftKey) {
			app.toggleTurboMode();
			return;
		}

		stopEvent(evt);
		app.runtime.startGreenFlags(firstPlay);
		firstPlay = false;
	}

	public function hidePlayButton():void {}
}}
