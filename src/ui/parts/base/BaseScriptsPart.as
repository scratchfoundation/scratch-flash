/*
 * Scratch Project Editor and Player
 * Copyright (C) 2014 Massachusetts Institute of Technology
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General License for more details.
 *
 * You should have received a copy of the GNU General License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

// IScriptsPart.as
// Shane Clements, March 2014
//
// This is an interface for the part that holds the palette and scripts pane for the current sprite (or stage).

package ui.parts.base {
import flash.display.Bitmap;
import flash.display.Shape;
import flash.display.Sprite;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.utils.getTimer;

import org.gestouch.core.Touch;
import org.gestouch.gestures.Gesture;
import org.gestouch.gestures.TransformGesture;

import scratch.ScratchObj;
import scratch.ScratchSprite;

import ui.BlockPalette;
import ui.PaletteSelector;
import ui.parts.UIPart;

import uiwidgets.IndicatorLight;
import uiwidgets.ScriptsPane;
import uiwidgets.ScrollFrame;
import uiwidgets.ZoomWidget;

public class BaseScriptsPart extends UIPart implements IScriptsPart {
	protected var selector:PaletteSelector;
	protected var spriteWatermark:Bitmap;
	protected var paletteFrame:ScrollFrame;
	protected var scriptsFrame:ScrollFrame;
	protected var zoomWidget:ZoomWidget;
	protected var shape:Shape;

	protected var xyDisplay:Sprite;
	private var xLabel:TextField;
	private var yLabel:TextField;
	private var xReadout:TextField;
	private var yReadout:TextField;
	private var lastX:int = -10000000; // impossible value to force initial update
	private var lastY:int = -10000000; // impossible value to force initial update
	private var lastUpdateTime:uint;

	private const readoutLabelFormat:TextFormat = new TextFormat(CSS.font, 12, CSS.textColor, true);
	private const readoutFormat:TextFormat = new TextFormat(CSS.font, 12, CSS.textColor);

	function BaseScriptsPart(app:Scratch, dragScroll:Boolean = false) {
		this.app = app;
		addChild(shape = new Shape());
		addChild(selector = getPaletteSelector());

		var palette:BlockPalette = new BlockPalette();
		palette.color = CSS.tabColor;
		paletteFrame = getPaletteFrame(dragScroll);
		paletteFrame.allowHorizontalScrollbar = false;
		paletteFrame.setContents(palette);
		addChild(paletteFrame);

		var scriptsPane:ScriptsPane = getScriptsPane();
		scriptsFrame = new ScrollFrame(false);
		if (dragScroll) {
			var scriptsScrollGesture:TransformGesture = new TransformGesture();
			scriptsScrollGesture.gestureShouldReceiveTouchCallback = shouldScriptsScrollReceiveTouch;
			scriptsFrame.enableDragScrolling(scriptsScrollGesture);
		}
		scriptsFrame.setContents(scriptsPane);
		addChild(scriptsFrame);

		addChild(spriteWatermark = new Bitmap());
		addXYDisplay();

		app.palette = palette;
		app.scriptsPane = scriptsPane;

		addChild(zoomWidget = new ZoomWidget(scriptsPane));
	}

	public function showPalette():void {}

	protected function getPaletteFrame(dragScroll:Boolean):ScrollFrame {
		return new ScrollFrame(dragScroll);
	}

	protected function getScriptsPane():ScriptsPane {
		return new ScriptsPane(app);
	}

	protected function shouldScriptsScrollReceiveTouch(gesture:Gesture, touch:Touch):Boolean {
		return touch.target == scriptsFrame || touch.target == scriptsFrame.contents;
	}

	// Derived classes need to actually do something with the layout
	public function setWidthHeight(w:int, h:int):void {
		this.w = w;
		this.h = h;
	}

	protected function getPaletteSelector():PaletteSelector {
		return new PaletteSelector(app);
	}

	public function resetCategory():void {
		selector.selectedCategory = -1;
		selector.select(Specs.motionCategory);
	}

	public function updatePalette():void {
		selector.updateTranslation();
		selector.refresh();
	}

	public function updateSpriteWatermark():void {
		var target:ScratchObj = app.viewedObj();
		if (target && !target.isStage) {
			spriteWatermark.bitmapData = target.currentCostume().thumbnail(40, 40, false);
		} else {
			spriteWatermark.bitmapData = null;
		}
	}

	public function step():void {
		// Update the mouse reaadouts. Do nothing if they are up-to-date (to minimize CPU load).
		var target:ScratchObj = app.viewedObj();
		if (target.isStage) {
			if (xyDisplay.visible) xyDisplay.visible = false;
		} else {
			if (!xyDisplay.visible) xyDisplay.visible = true;

			var spr:ScratchSprite = target as ScratchSprite;
			if (!spr) return;
			if (spr.scratchX != lastX) {
				lastX = spr.scratchX;
				xReadout.text = String(lastX);
			}
			if (spr.scratchY != lastY) {
				lastY = spr.scratchY;
				yReadout.text = String(lastY);
			}
		}
		if (selector.selectedCategory == Specs.extensionsCategory)
			updateExtensionIndicators();
	}

	private function updateExtensionIndicators():void {
		if ((getTimer() - lastUpdateTime) < 500) return;
		for (var i:int = 0; i < app.palette.numChildren; i++) {
			var indicator:IndicatorLight = app.palette.getChildAt(i) as IndicatorLight;
			if (indicator) app.extensionManager.updateIndicator(indicator, indicator.target);
		}
		lastUpdateTime = getTimer();
	}

	protected function getReadoutLabelFormat():TextFormat {
		return readoutLabelFormat;
	}

	protected function getReadoutFormat():TextFormat {
		return readoutFormat;
	}

	private function addXYDisplay():void {
		xyDisplay = new Sprite();
		xyDisplay.addChild(xLabel = makeLabel('x:', getReadoutLabelFormat(), 0, 0));
		xyDisplay.addChild(xReadout = makeLabel('-888', getReadoutFormat(), 15, 0));
		xyDisplay.addChild(yLabel = makeLabel('y:', getReadoutLabelFormat(), 0, 13));
		xyDisplay.addChild(yReadout = makeLabel('-888', getReadoutFormat(), 15, 13));
		addChild(xyDisplay);
	}

	public function refresh(visible:Boolean = true):void {}
}}
