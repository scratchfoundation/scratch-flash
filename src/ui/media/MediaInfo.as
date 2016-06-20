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

public class MediaInfo extends Sprite {

	public var frameWidth:int = 81;
	private var frameHeight:int = 94;
	protected var thumbnailWidth:int = 68;
	protected var thumbnailHeight:int = 51;

	// at most one of the following is non-null:
	public var mycostume:ScratchCostume;
	public var mysprite:ScratchSprite;
	public var mysound:ScratchSound;
	public var scripts:Array;

	public var objType:String = 'unknown';
	public var objName:String = '';
	public var objWidth:int = 0;
	public var bitmapResolution:int = 1;
	public var md5:String;

	public var owner:ScratchObj; // object owning a sound or costume in MediaPane; null for other cases
	public var isBackdrop:Boolean;
	public var forBackpack:Boolean;

	private var frame:Shape; // visible when selected
	private var thumbnail:Bitmap;
	private var label:TextField;
	private var info:TextField;
	private var deleteButton:IconButton;

	public function MediaInfo(obj:*, owningObj:ScratchObj = null) {
		owner = owningObj;
		mycostume = obj as ScratchCostume;
		mysound = obj as ScratchSound;
		mysprite = obj as ScratchSprite;
		if (mycostume) {
			objType = 'image';
			objName = mycostume.costumeName;
			md5 = mycostume.baseLayerMD5;
		} else if (mysound) {
			objType = 'sound';
			objName = mysound.soundName;
			md5 = mysound.md5;
			if (owner) frameHeight = 75; // use a shorter frame for sounds in a MediaPane
		} else if (mysprite) {
			objType = 'sprite';
			objName = mysprite.objName;
			md5 = null; // initially null
		} else if ((obj is Block) || (obj is Array)) {
			// scripts holds an array of blocks, stacks, and comments in Array form
			// initialize script list from either a stack (Block) or an array of stacks already in array form
			objType = 'script';
			objName = '';
			scripts = (obj is Block) ? [BlockIO.stackToArray(obj)] : obj;
			md5 = null; // scripts don't have an MD5 hash
		} else {
			// initialize from a JSON object
			objType = obj.type ? obj.type : '';
			objName = obj.name ? obj.name : '';
			objWidth = obj.width ? obj.width : 0;
			bitmapResolution = obj.bitmapResolution ? obj.bitmapResolution : 1;
			scripts = obj.scripts;
			md5 = ('script' != objType) ? obj.md5 : null;
		}
		addFrame();
		addThumbnail();
		addLabelAndInfo();
		unhighlight();
		addDeleteButton();
		updateLabelAndInfo(false);
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

	private function showDeleteButton(flag:Boolean):void {
		if (deleteButton) {
			deleteButton.visible = flag;
			if (flag && mycostume && owner && (owner.costumes.length < 2)) deleteButton.visible = false;
		}
	}

	// -----------------------------
	// Thumbnail
	//------------------------------

	public function updateMediaThumbnail():void { /* xxx */ }
	public function thumbnailX():int { return thumbnail.x }
	public function thumbnailY():int { return thumbnail.y }

	public function computeThumbnail():Boolean {
		if (mycostume) setLocalCostumeThumbnail();
		else if (mysprite) setLocalSpriteThumbnail();
		else if (scripts) setScriptThumbnail();
		else return false;

		return true;
	}

	private function setLocalCostumeThumbnail():void {
		// Set the thumbnail for a costume local to this project (and not necessarily saved to the server).
		var forStage:Boolean = owner && owner.isStage;
		var bm:BitmapData = mycostume.thumbnail(thumbnailWidth, thumbnailHeight, forStage);
		isBackdrop = forStage;
		setThumbnailBM(bm);
	}

	private function setLocalSpriteThumbnail():void {
		// Set the thumbnail for a sprite local to this project (and not necessarily saved to the server).
		setThumbnailBM(mysprite.currentCostume().thumbnail(thumbnailWidth, thumbnailHeight, false));
	}

	protected function fileType(s:String):String {
		if (!s) return '';
		var i:int = s.lastIndexOf('.');
		return (i < 0) ? '' : s.slice(i + 1);
	}

	private function setScriptThumbnail():void {
		if (!scripts || (scripts.length < 1)) return; // no scripts
		var script:Block = BlockIO.arrayToStack(scripts[0]);
		var scale:Number = Math.min(thumbnailWidth / script.width, thumbnailHeight / script.height);
		var bm:BitmapData = new BitmapData(thumbnailWidth, thumbnailHeight, true, 0);
		var m:Matrix = new Matrix();
		m.scale(scale, scale);
		bm.draw(script, m);
		setThumbnailBM(bm);
	}

	protected function setThumbnailBM(bm:BitmapData):void {
		thumbnail.bitmapData = bm;
		thumbnail.x = (frameWidth - thumbnail.width) / 2;
	}

	protected function setInfo(s:String):void {
		info.text = s;
		info.x = Math.max(0, (frameWidth - info.textWidth) / 2);
	}

	// -----------------------------
	// Label and Info
	//------------------------------

	public function updateLabelAndInfo(forBackpack:Boolean):void {
		this.forBackpack = forBackpack;
		setText(label, (forBackpack ? backpackTitle() : objName));
		label.x = ((frameWidth - label.textWidth) / 2) - 2;

		setText(info, (forBackpack ? objName: infoString()));
		info.x = Math.max(0, (frameWidth - info.textWidth) / 2);
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
		if (mycostume) return costumeInfoString();
		if (mysound) return soundInfoString(mysound.getLengthInMsec());
		return '';
	}

	private function costumeInfoString():String {
		// Use the actual dimensions (rounded up to an integer) of my costume.
		var w:int, h:int;
		var dispObj:DisplayObject = mycostume.displayObj();
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

	public function objToGrab(evt:MouseEvent):* {
		var result:MediaInfo = Scratch.app.createMediaInfo({
			type: objType,
			name: objName,
			width: objWidth,
			md5: md5
		});
		if (mycostume) result = Scratch.app.createMediaInfo(mycostume, owner);
		if (mysound) result = Scratch.app.createMediaInfo(mysound, owner);
		if (mysprite) result = Scratch.app.createMediaInfo(mysprite);
		if (scripts) result = Scratch.app.createMediaInfo(scripts);

		result.removeDeleteButton();
		if (thumbnail.bitmapData) result.thumbnail.bitmapData = thumbnail.bitmapData;
		result.hideTextFields();
		return result;
	}

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
		if (mycostume) {
			result.width = mycostume.width();
			result.height = mycostume.height();
			if (mycostume.bitmapResolution != 1) {
				result.bitmapResolution = mycostume.bitmapResolution;
			}
		}
		if (mysound) {
			result.seconds = mysound.getLengthInMsec() / 1000;
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
		g.drawRoundRect(0, 0, frameWidth, frameHeight, 12, 12);
		g.endFill();
		addChild(frame);
	}

	private function addThumbnail():void {
		if ('sound' == objType) {
			thumbnail = Resources.createBmp('speakerOff');
			thumbnail.x = 18;
			thumbnail.y = 16;
		} else {
			thumbnail = Resources.createBmp('questionMark');
			thumbnail.x = (frameWidth - thumbnail.width) / 2;
			thumbnail.y = 13;
		}
		addChild(thumbnail);
		if (owner) computeThumbnail();
	}

	private function addLabelAndInfo():void {
		label = Resources.makeLabel('', CSS.thumbnailFormat);
		label.y = frameHeight - 28;
		addChild(label);
		info = Resources.makeLabel('', CSS.thumbnailExtraInfoFormat);
		info.y = frameHeight - 14;
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
			if (mycostume) {
				app.viewedObj().showCostumeNamed(mycostume.costumeName);
				app.selectCostume();
			}
			if (mysound) app.selectSound(mysound);
		}
	}

	public function handleTool(tool:String, evt:MouseEvent):void {
		if (tool == 'copy') duplicateMe();
		if (tool == 'cut') deleteMe();
		if (tool == 'help') Scratch.app.showTip('scratchUI');	}

	public function menu(evt:MouseEvent):Menu {
		var m:Menu = new Menu();
		addMenuItems(m);
		return m;
	}

	protected function addMenuItems(m:Menu):void {
		if (!getBackpack()) m.addItem('duplicate', duplicateMe);
		m.addItem('delete', deleteMe);
		m.addLine();
		if (mycostume) {
			m.addItem('save to local file', exportCostume);
		}
		if (mysound) {
			m.addItem('save to local file', exportSound);
		}
	}

	protected function duplicateMe():void {
		if (owner && !getBackpack()) {
			if (mycostume) Scratch.app.addCostume(mycostume.duplicate());
			if (mysound) Scratch.app.addSound(mysound.duplicate());
		}
	}

	protected function deleteMe(ignore:* = null):void {
		if (owner) {
			Scratch.app.runtime.recordForUndelete(this, 0, 0, 0, owner);
			if (mycostume) {
				owner.deleteCostume(mycostume);
				Scratch.app.refreshImageTab(false);
			}
			if (mysound) {
				owner.deleteSound(mysound);
				Scratch.app.refreshSoundTab();
			}
		}
	}

	private function exportCostume():void {
		if (!mycostume) return;
		mycostume.prepareToSave();
		var ext:String = ScratchCostume.fileExtension(mycostume.baseLayerData);
		var defaultName:String = mycostume.costumeName + ext;
		new FileReference().save(mycostume.baseLayerData, defaultName);
	}

	private function exportSound():void {
		if (!mysound) return;
		mysound.prepareToSave();
		var defaultName:String = mysound.soundName + '.wav';
		new FileReference().save(mysound.soundData, defaultName);
	}

	protected function getBackpack():UIPart {
		return null;
	}
}}
