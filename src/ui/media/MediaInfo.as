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

// MediaInfo.as
// John Maloney, December 2011
//
// This object represent a sound, image, or script. It is used:
//	* to represent costumes, backdrops, or sounds in a MediaPane
//	* to represent images, sounds, and sprites in the backpack (a BackpackPart)
//	* to drag between the backpack and the media pane

package ui.media {
import by.blooddy.crypto.MD5;

import ui.BaseItem;
import ui.ItemData;
import ui.styles.ItemStyle;

import util.JSON;
import flash.display.*;
import flash.events.*;
import flash.geom.*;
import flash.net.*;
import flash.text.*;
import assets.Resources;
import blocks.*;
import scratch.*;
import translation.Translator;
import ui.parts.*;
import uiwidgets.*;

public class MediaInfo extends BaseItem {
	protected static var infoHeight:int = 28;

	// at most one of the following is non-null:
	public var scripts:Array;

	public var objType:String = 'unknown';
	public var objName:String = '';
	public var objWidth:int = 0;
	public var md5:String;

	public var owner:ScratchObj; // object owning a sound or costume in MediaPane; null for other cases
	public var isBackdrop:Boolean;
	public var forBackpack:Boolean;

	private var frame:Shape; // visible when selected
	protected var info:TextField;
	protected var deleteButton:IconButton;

	public function get asCostume():ScratchCostume {
		return data.obj as ScratchCostume;
	}
	public function get asSound():ScratchSound {
		return data.obj as ScratchSound;
	}
	public function get asSprite():ScratchSprite {
		return data.obj as ScratchSprite;
	}
	public function MediaInfo(obj:*, owningObj:ScratchObj = null) {
		var t:String = '';
		var objIsObj:Boolean;
		if (obj is ScratchCostume) {
			t = owningObj.isStage ? 'backdrop' : 'costume';
			objName = (obj as ScratchCostume).costumeName;
			md5 = (obj as ScratchCostume).baseLayerMD5;
			objType = 'image';
		}
		else if (obj is ScratchObj) {
			t = obj is ScratchStage ? 'stage' : 'sprite';
			objType = 'sprite';
			objName = (obj as ScratchObj).objName;
			md5 = MD5.hash(util.JSON.stringify(obj));
		}
		else if (obj is ScratchSound) {
			t = 'sound';
			objType = 'sound';
			objName = (obj as ScratchSound).soundName;
			md5 = (obj as ScratchSound).md5;
		}
		else if (obj is Block || obj is Array) {
			// scripts holds an array of blocks, stacks, and comments in Array form
			// initialize script list from either a stack (Block) or an array of stacks already in array form
			t = 'script';
			objType = 'script';
			objName = '';
			scripts = (obj is Block) ? [BlockIO.stackToArray(obj)] : obj;
			md5 = MD5.hash(util.JSON.stringify(scripts));
		} else { // from backpack?
			// initialize from a JSON object
			objType = obj.type ? obj.type : '';
			t = objType;
			objName = obj.name ? obj.name : '';
			objWidth = obj.width ? obj.width : 0;
			scripts = obj.scripts;
			md5 = ('script' != objType) ? obj.md5 : null;
			objIsObj = true;
		}

		var d:ItemData = new ItemData(t, objName, md5, obj, {owner:owningObj});
		var style:ItemStyle = (t == 'sound' && owner ? CSS.soundItemStyle : CSS.itemStyle);
		if (objIsObj && obj._style is ItemStyle)
			style = obj._style;
		super(style, d);
		owner = owningObj;

		addFrame();
		addInfo();
		unhighlight();
		addDeleteButton();
		updateLabelAndInfo(false);
		addEventListener(MouseEvent.CLICK, click);
		addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, menu);
	}

	public static function strings():Array {
		return ['Backdrop', 'Costume', 'Script', 'Sound', 'Sprite', 'save to local file'];
	}

	// -----------------------------
	// Highlighting (for MediaPane)
	//------------------------------

	public function highlight():void {
		if (frame.alpha != 1) { frame.alpha = 1; showDeleteButton(true) }
	}

	public function unhighlight():void {
		if (frame.alpha != 0) { frame.alpha = 0; showDeleteButton(false) }
	}

	protected function showDeleteButton(flag:Boolean):void {
		if (deleteButton) {
			deleteButton.visible = flag;
			if (flag && asCostume && owner && (owner.costumes.length < 2)) deleteButton.visible = false;
		}
	}

	// -----------------------------
	// Thumbnail
	//------------------------------

	public function updateMediaThumbnail():void { /* xxx */ }
	public function thumbnailX():int { return image.x }
	public function thumbnailY():int { return image.y }

	protected function setInfo(s:String):void {
		info.text = s;
		info.x = Math.max(0, (style.frameWidth - info.textWidth) / 2);
	}

	// -----------------------------
	// Label and Info
	//------------------------------

	public function updateLabelAndInfo(forBackpack:Boolean):void {
		this.forBackpack = forBackpack;
		setText(label, (forBackpack ? backpackTitle() : objName));
		label.x = ((style.frameWidth - label.textWidth) / 2) - 2;

		setText(info, (forBackpack ? objName: infoString()));
		info.x = Math.max(0, (style.frameWidth - info.textWidth) / 2);
	}

	public function hideTextFields():void {
		setText(label, '');
		setText(info, '');
	}

	private function backpackTitle():String {
		if ('image' == objType) return Translator.map(isBackdrop ? 'Backdrop' : 'Costume');
		if ('script' == objType) return Translator.map('Script');
		if ('sound' == objType) return Translator.map('Sound');
		if ('sprite' == objType) return Translator.map('Sprite');
		return objType;
	}

	private function infoString():String {
		if (asCostume) return costumeInfoString();
		if (asSound) return soundInfoString(asSound.getLengthInMsec());
		return '';
	}

	private function costumeInfoString():String {
		// Use the actual dimensions (rounded up to an integer) of my costume.
		var w:int, h:int;
		var dispObj:DisplayObject = asCostume.displayObj();
		if (dispObj is Bitmap) {
			w = dispObj.width;
			h = dispObj.height;
		} else {
			var r:Rectangle = dispObj.getBounds(dispObj);
			w = Math.ceil(r.width);
			h = Math.ceil(r.height);
		}
		return w + 'x' + h;
	}

	private function soundInfoString(msecs:Number):String {
		// Return a formatted time in MM:SS.HH (where HH is hundredths of a second).
		function twoDigits(n:int):String { return (n < 10) ? '0' + n : '' + n }

		var secs:int = msecs / 1000;
		var hundredths:int = (msecs % 1000) / 10;
		return twoDigits(secs / 60) + ':' + twoDigits(secs % 60) + '.' + twoDigits(hundredths);
	}

	// -----------------------------
	// Backpack Support
	//------------------------------
//	override public function getSpriteToDrag():Sprite {
//		var result:MediaInfo = Scratch.app.createMediaInfo({
//			type: objType,
//			name: objName,
//			width: objWidth,
//			md5: md5
//		});
//		if (asCostume) result = Scratch.app.createMediaInfo(asCostume, owner);
//		if (asSound) result = Scratch.app.createMediaInfo(asSound, owner);
//		if (asSprite) result = Scratch.app.createMediaInfo(asSprite);
//		if (scripts) result = Scratch.app.createMediaInfo(scripts);
//
//		result.removeDeleteButton();
//		if (thumbnail.bitmapData) result.setThumbnailBM(thumbnail.bitmapData);
//		result.hideTextFields();
//		result.scaleX = result.scaleY = transform.concatenatedMatrix.a;
//		return result;
//	}

	public function addDeleteButton():void {
		removeDeleteButton();
		deleteButton = new IconButton(deleteMe, Resources.createBmp('removeItem'));
		deleteButton.x = frame.width - deleteButton.width + 5;
		deleteButton.y = 3;
		deleteButton.visible = false;
		addChild(deleteButton);
	}

	public function removeDeleteButton():void {
		if (deleteButton) {
			removeChild(deleteButton);
			deleteButton = null;
		}
	}

	public function backpackRecord():Object {
		// Return an object to be saved in the backpack.
		var result:Object = {
			type: objType,
			name: objName,
			md5: md5
		};
		if (asCostume) {
			result.width = asCostume.width();
			result.height = asCostume.height();
		}
		if (asSound) {
			result.seconds = asSound.getLengthInMsec() / 1000;
		}
		if (scripts) {
			result.scripts = scripts;
			delete result.md5;
		}
		return result;
	}

	// -----------------------------
	// Parts
	//------------------------------

	private function addFrame():void {
		frame = new Shape();
		var g:Graphics = frame.graphics;
		g.lineStyle(3, CSS.overColor, 1, true);
		g.beginFill(CSS.itemSelectedColor);
		g.drawRoundRect(0, 0, style.frameWidth, style.frameHeight, 12, 12);
		g.endFill();
		addChildAt(frame, 0);
	}

	protected function addInfo():void {
		label.y = style.frameHeight - infoHeight;
		info = Resources.makeLabel('', CSS.thumbnailExtraInfoFormat);
		info.y = style.frameHeight - Math.floor(infoHeight * 0.5);
		addChild(info);
	}

	private function setText(tf:TextField, s:String):void {
		// Set the text of the given TextField, truncating if necessary.
		var desiredWidth:int = frame.width - 6;
		tf.text = s;
		while ((tf.textWidth > desiredWidth) && (s.length > 0)) {
			s = s.substring(0, s.length - 1);
			tf.text = s + '\u2026'; // truncated name with ellipses
		}
	}

	// -----------------------------
	// User interaction
	//------------------------------

	public function click(evt:MouseEvent):void {
		if (!getBackpack()) {
			var app:Scratch = Scratch.app;
			if (asCostume) {
				var s:ScratchObj = app.viewedObj();
				s.showCostume(s.indexOfCostume(asCostume));
				app.selectCostume();
			}
			if (asSound) app.selectSound(asSound);
		}
	}

	public function handleTool(tool:String, evt:MouseEvent):void {
		if (tool == 'copy') duplicateMe();
		if (tool == 'cut') deleteMe();
		if (tool == 'help') Scratch.app.showTip('scratchUI');
	}

	public function menu(evt:MouseEvent):Menu {
		var m:Menu = new Menu();
		addMenuItems(m);
		return m;
	}

	protected function addMenuItems(m:Menu):void {
		if (!getBackpack()) m.addItem('duplicate', duplicateMe);
		m.addItem('delete', deleteMe);
		m.addLine();
		if (asCostume) {
			m.addItem('save to local file', exportCostume);
		}
		if (asSound) {
			m.addItem('save to local file', exportSound);
		}
	}

	protected function duplicateMe():void {
		if (owner && !getBackpack()) {
			if (asCostume) Scratch.app.addCostume(asCostume.duplicate());
			if (asSound) Scratch.app.addSound(asSound.duplicate());
		}
	}

	protected function deleteMe(ib:IconButton = null):void {
		if (owner) {
			Scratch.app.runtime.recordForUndelete(this, 0, 0, 0, owner);
			if (asCostume) {
				owner.deleteCostume(asCostume);
				Scratch.app.refreshImageTab(false);
			}
			if (asSound) {
				owner.deleteSound(asSound);
				Scratch.app.refreshSoundTab();
			}

			if(ib && ib.lastEvent) ib.lastEvent.stopImmediatePropagation();
		}
	}

	private function exportCostume():void {
		if (!asCostume) return;
		asCostume.prepareToSave();
		var ext:String = ScratchCostume.fileExtension(asCostume.baseLayerData);
		var defaultName:String = asCostume.costumeName + ext;
		new FileReference().save(asCostume.baseLayerData, defaultName);
	}

	private function exportSound():void {
		if (!asSound) return;
		asSound.prepareToSave();
		var defaultName:String = asSound.soundName + '.wav';
		new FileReference().save(asSound.soundData, defaultName);
	}

	protected function getBackpack():UIPart {
		return null;
	}
}}
