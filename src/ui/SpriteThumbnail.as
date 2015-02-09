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
	import flash.filters.GlowFilter;
	import flash.text.*;
	import assets.Resources;
	import blocks.Block;
	import scratch.*;
	import translation.Translator;
	import ui.media.MediaInfo;
	import ui.parts.LibraryPart;
	import uiwidgets.*;

public class SpriteThumbnail extends Sprite {

	private const frameW:int = 73;
	private const frameH:int = 73;
	private const stageFrameH:int = 86;

	private const thumbnailW:int = 68;
	private const thumbnailH:int = 51;

	public var targetObj:ScratchObj;

	private var app:Scratch;
	private var thumbnail:Bitmap;
	private var label:TextField;
	private var sceneInfo:TextField;
	private var selectedFrame:Shape;
	private var highlightFrame:Shape;
	private var infoSprite:Sprite;
	private var detailsButton:IconButton;

	private var lastSrcImg:DisplayObject;
	private var lastName:String = '';
	private var lastSceneCount:int = 0;

	public function SpriteThumbnail(targetObj:ScratchObj, app:Scratch) {
		this.targetObj = targetObj;
		this.app = app;

		addFrame();
		addSelectedFrame();
		addHighlightFrame();

		thumbnail = new Bitmap();
		thumbnail.x = 3;
		thumbnail.y = 3;
		thumbnail.filters = [grayOutlineFilter()];
		addChild(thumbnail);

		label = Resources.makeLabel('', CSS.thumbnailFormat);
		label.width = frameW;
		addChild(label);

		if (targetObj.isStage) {
			sceneInfo = Resources.makeLabel('', CSS.thumbnailExtraInfoFormat);
			sceneInfo.width = frameW;
			addChild(sceneInfo);
		}

		addDetailsButton();
		updateThumbnail();
	}

	public static function strings():Array {
		return ['backdrop', 'backdrops', 'hide', 'show', 'Stage'] }

	private function addDetailsButton():void {
		detailsButton = new IconButton(showSpriteDetails, 'spriteInfo');
		detailsButton.x = detailsButton.y = -2;
		detailsButton.isMomentary = true;
		detailsButton.visible = false;
		addChild(detailsButton);
	}

	private function addFrame():void {
		if (targetObj.isStage) return;

		var frame:Shape = new Shape();
		var g:Graphics = frame.graphics;
		g.lineStyle(NaN);
		g.beginFill(0xFFFFFF);
		g.drawRoundRect(0, 0, frameW, frameH, 12, 12);
		g.endFill();
		addChild(frame);
	}

	private function addSelectedFrame():void {
		selectedFrame = new Shape();
		var g:Graphics = selectedFrame.graphics;
		var h:int = targetObj.isStage ? stageFrameH : frameH;
		g.lineStyle(3, CSS.overColor, 1, true);
		g.beginFill(CSS.itemSelectedColor);
		g.drawRoundRect(0, 0, frameW, h, 12, 12);
		g.endFill();
		selectedFrame.visible = false;
		addChild(selectedFrame);
	}

	private function addHighlightFrame():void {
		const highlightColor:int = 0xE0E000;
		highlightFrame = new Shape();
		var g:Graphics = highlightFrame.graphics;
		var h:int = targetObj.isStage ? stageFrameH : frameH;
		g.lineStyle(2, highlightColor, 1, true);
		g.drawRoundRect(1, 1, frameW - 1, h - 1, 12, 12);
		highlightFrame.visible = false;
		addChild(highlightFrame);
	}

	public function setTarget(obj:ScratchObj):void {
		targetObj = obj;
		updateThumbnail();
	}

	public function select(flag:Boolean):void {
		if (selectedFrame.visible == flag) return;
		selectedFrame.visible = flag;
		detailsButton.visible = flag && !targetObj.isStage;
	}

	public function showHighlight(flag:Boolean):void {
		// Display a highlight if flag is true (e.g. to show broadcast senders/receivers).
		highlightFrame.visible = flag;
	}

	public function showInfo(flag:Boolean):void {
		if (infoSprite) {
			removeChild(infoSprite);
			infoSprite = null;
		}
		if (flag) {
			infoSprite = makeInfoSprite();
			addChild(infoSprite);
		}
	}

	public function makeInfoSprite():Sprite {
		var result:Sprite = new Sprite();
		var bm:Bitmap = Resources.createBmp('hatshape');
		bm.x = (frameW - bm.width) / 2;
		bm.y = 20;
		result.addChild(bm);
		var tf:TextField = Resources.makeLabel(String(targetObj.scripts.length), CSS.normalTextFormat);
		tf.x = bm.x + 20 - (tf.textWidth / 2);
		tf.y = bm.y + 4;
		result.addChild(tf);
		return result;
	}

	public function updateThumbnail(translationChanged:Boolean = false):void {
		if (targetObj == null) return;
		if (translationChanged) lastSceneCount = -1;
		updateName();
		if (targetObj.isStage) updateSceneCount();

		if (targetObj.img.numChildren == 0) return; // shouldn't happen
		if (targetObj.currentCostume().svgLoading) return; // don't update thumbnail while loading SVG bitmaps
		var src:DisplayObject = targetObj.img.getChildAt(0);
		if (src == lastSrcImg) return; // thumbnail is up to date

		var c:ScratchCostume = targetObj.currentCostume();
		thumbnail.bitmapData = c.thumbnail(thumbnailW, thumbnailH, targetObj.isStage);
		lastSrcImg = src;
	}

	private function grayOutlineFilter():GlowFilter {
		// Filter to provide a gray outline even around totally white costumes.
		var f:GlowFilter = new GlowFilter(CSS.onColor);
		f.strength = 1;
		f.blurX = f.blurY = 2;
		f.knockout = false;
		return f;
	}

	private function updateName():void {
		var s:String = (targetObj.isStage) ? Translator.map('Stage') : targetObj.objName;
		if (s == lastName) return;
		lastName = s;
		label.text = s;
		while ((label.textWidth > 60) && (s.length > 0)) {
			s = s.substring(0, s.length - 1);
			label.text = s + '\u2026'; // truncated name with ellipses
		}
		label.x = ((frameW - label.textWidth) / 2) - 2;
		label.y = 57;
	}

	private function updateSceneCount():void {
		if (targetObj.costumes.length == lastSceneCount) return;
		var sceneCount:int = targetObj.costumes.length;
		sceneInfo.text = sceneCount + ' ' + Translator.map((sceneCount == 1) ? 'backdrop' : 'backdrops');
		sceneInfo.x = ((frameW - sceneInfo.textWidth) / 2) - 2;
		sceneInfo.y = 70;
		lastSceneCount = sceneCount;
	}

	// -----------------------------
	// Grab and Drop
	//------------------------------

	public function objToGrab(evt:MouseEvent):MediaInfo {
		if (targetObj.isStage) return null;
		var result:MediaInfo = app.createMediaInfo(targetObj);
		result.removeDeleteButton();
		result.computeThumbnail();
		result.hideTextFields();
		return result;
	}

	public function handleDrop(obj:*):Boolean {
		function addCostume(c:ScratchCostume):void { app.addCostume(c, targetObj) }
		function addSound(snd:ScratchSound):void { app.addSound(snd, targetObj) }
		var item:MediaInfo = obj as MediaInfo;
		if (item) {
			// accept dropped costumes and sounds from another sprite, but not yet from Backpack
			if (item.mycostume) {
				addCostume(item.mycostume.duplicate());
				return true;
			}
			if (item.mysound) {
				addSound(item.mysound.duplicate());
				return true;
			}
		}
		if (obj is Block) {
			// copy a block/stack to this sprite
			if (targetObj == app.viewedObj()) return false; // dropped on my own thumbnail; do nothing
			var copy:Block = Block(obj).duplicate(false, targetObj.isStage);
			copy.x = app.scriptsPane.padding;
			copy.y = app.scriptsPane.padding;
			targetObj.scripts.push(copy);
			return false; // do not consume the original block
		}
		return false;
	}

	// -----------------------------
	// User interaction
	//------------------------------

	public function click(evt:Event):void {
		if (!targetObj.isStage && targetObj is ScratchSprite) app.flashSprite(targetObj as ScratchSprite);
		app.selectSprite(targetObj);
	}

	public function menu(evt:MouseEvent):Menu {
		function hideInScene():void {
			t.visible = false;
			t.updateBubble();
		}
		function showInScene():void {
			t.visible = true;
			t.updateBubble();
		}
		if (targetObj.isStage) return null;
		var t:ScratchSprite = targetObj as ScratchSprite;
		var m:Menu = t.menu(evt); // basic sprite menu
		m.addLine();
		if (t.visible) {
			m.addItem('hide', hideInScene);
		} else {
			m.addItem('show', showInScene);
		}
		return m;
	}

	public function handleTool(tool:String, evt:MouseEvent):void {
		if (tool == 'help') Scratch.app.showTip('scratchUI');
		var spr:ScratchSprite = targetObj as ScratchSprite;
		if (!spr) return;
		if (tool == 'copy') spr.duplicateSprite();
		if (tool == 'cut') spr.deleteSprite();
	}

	private function showSpriteDetails(ignore:*):void {
		var lib:LibraryPart = parent.parent.parent as LibraryPart;
		if (lib) lib.showSpriteDetails(true);
	}

}}
