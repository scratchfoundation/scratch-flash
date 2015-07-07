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

import ui.events.PointerEvent;
import ui.media.MediaInfo;
import ui.parts.LibraryPart;
import ui.styles.ItemStyle;

import uiwidgets.*;

public class SpriteThumbnail extends BaseItem {
	protected var app:Scratch;
	private var sceneInfo:TextField;
	protected var selectedFrame:DisplayObject;
	protected var highlightFrame:DisplayObject;
	private var infoSprite:Sprite;
	private var detailsButton:IconButton;

	protected var lastSrcImg:DisplayObject;
	private var lastName:String = '';
	private var lastSceneCount:int = 0;

	static private var counter:uint;
	public function SpriteThumbnail(targetObj:ScratchObj, app:Scratch, itemStyle:ItemStyle) {
//		super(itemStyle, new ItemData(targetObj.isStage ? 'stage' : 'sprite', targetObj.objName, targetObj.generateMD5(), targetObj));
		super(itemStyle, new ItemData(targetObj.isStage ? 'stage' : 'sprite', targetObj.objName, ++counter + '', targetObj));
		this.app = app;

		addFrame();
		addSelectedFrame();
		addHighlightFrame();

		addChild(image);

		addLabels();
		addDetailsButton();
		updateThumbnail();
		addEventListener(PointerEvent.TAP, click);
		addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, menu);
	}

	public static function strings():Array {
		return ['backdrop', 'backdrops', 'hide', 'show', 'Stage'] }

	protected function addLabels():void {
		label = Resources.makeLabel('', CSS.thumbnailFormat);
		label.width = style.frameWidth;
		addChild(label);

		if (data.type == 'stage') {
			sceneInfo = Resources.makeLabel('', CSS.thumbnailExtraInfoFormat);
			sceneInfo.width = style.frameWidth;
			addChild(sceneInfo);
		}
	}

	protected function addDetailsButton():void {
		detailsButton = new IconButton(showSpriteDetails, 'spriteInfo');
		detailsButton.x = detailsButton.y = -2;
		detailsButton.isMomentary = true;
		detailsButton.visible = false;
		addChild(detailsButton);
	}

	private var frame:Shape;
	protected function addFrame():void {
		if (data.type == 'stage') return;

		frame = new Shape();
		var g:Graphics = frame.graphics;
		g.lineStyle(NaN);
		g.beginFill(0xFFFFFF);
		g.drawRoundRect(0, 0, style.frameWidth, style.frameHeight, 12, 12);
		g.endFill();
		addChild(frame);
	}

	protected function addSelectedFrame():void {
		selectedFrame = new Shape();
		var g:Graphics = (selectedFrame as Shape).graphics;
		g.lineStyle(3, CSS.overColor, 1, true);
		g.beginFill(CSS.itemSelectedColor);
		g.drawRoundRect(0, 0, style.frameWidth, style.frameHeight, 12, 12);
		g.endFill();
		selectedFrame.visible = false;
		addChild(selectedFrame);
	}

	protected function addHighlightFrame():void {
		const highlightColor:int = 0xE0E000;
		highlightFrame = new Shape();
		var g:Graphics = (highlightFrame as Shape).graphics;
		g.lineStyle(2, highlightColor, 1, true);
		g.drawRoundRect(1, 1, style.frameWidth - 1, style.frameHeight - 1, 12, 12);
		highlightFrame.visible = false;
		addChild(highlightFrame);
	}

	public function setTarget(obj:ScratchObj):void {
		data.obj = obj;
		updateThumbnail();
	}

	public function select(flag:Boolean):void {
		if (selectedFrame.visible == flag) return;
		selectedFrame.visible = flag;
		detailsButton.visible = flag && data.type != 'stage';
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
		bm.x = (style.frameWidth - bm.width) / 2;
		bm.y = 20;
		result.addChild(bm);
		var tf:TextField = Resources.makeLabel(String(data.obj.scripts.length), CSS.normalTextFormat);
		tf.x = bm.x + 20 - (tf.textWidth / 2);
		tf.y = bm.y + 4;
		result.addChild(tf);
		return result;
	}

	public function updateThumbnail(translationChanged:Boolean = false):void {
		highlightFrame.visible = false;
		selectedFrame.visible = false;
		if (frame) frame.visible = false;

		if (data.obj == null) return;
		if (translationChanged) lastSceneCount = -1;
		updateName();
		if (data.type == 'stage') updateSceneCount();

		if (data.obj.img.numChildren == 0) return; // shouldn't happen
		if (data.obj.currentCostume().svgLoading) return; // don't update thumbnail while loading SVG bitmaps
		var src:DisplayObject = data.obj.img.getChildAt(0);
		if (src == lastSrcImg) return; // thumbnail is up to date

		refresh();
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
		var s:String = data.type == 'stage' ? Translator.map('Stage') : data.obj.objName;
		if (s == lastName) return;
		lastName = s;
		label.text = s;
		while ((label.textWidth > 60) && (s.length > 0)) {
			s = s.substring(0, s.length - 1);
			label.text = s + '\u2026'; // truncated name with ellipses
		}
		label.x = ((style.frameWidth - label.textWidth) / 2) - 2;
		label.y = 57;
	}

	protected function updateSceneCount():void {
		if (data.obj.costumes.length == lastSceneCount) return;
		var sceneCount:int = data.obj.costumes.length;
		sceneInfo.text = sceneCount + ' ' + Translator.map((sceneCount == 1) ? 'backdrop' : 'backdrops');
		sceneInfo.x = ((style.frameWidth - sceneInfo.textWidth) / 2) - 2;
		sceneInfo.y = 70;
		lastSceneCount = sceneCount;
	}

	// -----------------------------
	// Grab and Drop
	//------------------------------

	override public function getSpriteToDrag():Sprite {
		if (data.type == 'stage') return null;

		return super.getSpriteToDrag();
	}

	public function handleDrop(obj:*):Boolean {
		function addCostume(c:ScratchCostume):void { app.addCostume(c, data.obj); }
		function addSound(snd:ScratchSound):void { app.addSound(snd, data.obj); }
		var item:MediaInfo = obj as MediaInfo;
		if (item) {
			// accept dropped costumes and sounds from another sprite, but not yet from Backpack
			if (item.asCostume) {
				addCostume(item.asCostume.duplicate());
				return true;
			}
			if (item.asSound) {
				addSound(item.asSound.duplicate());
				return true;
			}
		}
		if (obj is Block) {
			// copy a block/stack to this sprite
			if (data.obj == app.viewedObj()) return false; // dropped on my own thumbnail; do nothing
			var copy:Block = Block(obj).duplicate(false, data.type == 'stage');
			copy.x = app.scriptsPane.padding;
			copy.y = app.scriptsPane.padding;
			data.obj.scripts.push(copy);
			return false; // do not consume the original block
		}
		return false;
	}

	// -----------------------------
	// User interaction
	//------------------------------

	public function click(evt:Event):void {
		if (data.type != 'stage' && data.obj is ScratchSprite) app.flashSprite(data.obj as ScratchSprite);
		app.selectSprite(data.obj);
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
		if (data.type == 'stage') return null;
		var t:ScratchSprite = data.obj as ScratchSprite;
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
		var spr:ScratchSprite = data.obj as ScratchSprite;
		if (!spr) return;
		if (tool == 'copy') spr.duplicateSprite();
		if (tool == 'cut') spr.deleteSprite();
	}

	private function showSpriteDetails(ignore:*):void {
		var lib:LibraryPart = parent.parent.parent as LibraryPart;
		if (lib) lib.showSpriteDetails(true);
	}
}}
