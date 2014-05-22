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

package ui.media {
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.text.TextField;
	import assets.Resources;
	import scratch.*;
	import ui.parts.SoundsPart;
	import uiwidgets.*;

public class MediaPane extends ScrollFrameContents {

	public var app:Scratch;

	private var isSound:Boolean;
	private var lastCostume:ScratchCostume;

	public function MediaPane(app:Scratch, type:String):void {
		this.app = app;
		isSound = (type == 'sounds');
		refresh();
	}

	public function refresh():void {
		if (app.viewedObj() == null) return;
		replaceContents(isSound ? soundItems() : costumeItems());
		updateSelection();
	}

	// Returns true if we might need to save
	public function updateSelection():Boolean {
		if (isSound) {
			updateSoundSelection();
			return true;
	}

		return updateCostumeSelection();
	}

	private function replaceContents(newItems:Array):void {
		while (numChildren > 0) removeChildAt(0);
		var nextY:int = 3;
		var n:int = 1;
		for each (var item:Sprite in newItems) {
			var numLabel:TextField = Resources.makeLabel('' + n++, CSS.thumbnailExtraInfoFormat);
			numLabel.x = 9;
			numLabel.y = nextY + 1;
			item.x = 7;
			item.y = nextY;
			nextY += item.height + 3;
			addChild(item);
			addChild(numLabel);
		}
		updateSize();
		lastCostume = null;
		x = y = 0; // reset scroll offset
	}

	private function costumeItems():Array {
		var result:Array = [];
		var viewedObj:ScratchObj = app.viewedObj();
		for each (var c:ScratchCostume in viewedObj.costumes) {
			result.push(Scratch.app.createMediaInfo(c, viewedObj));
		}
		return result;
	}

	private function soundItems():Array {
		var result:Array = [];
		var viewedObj:ScratchObj = app.viewedObj();
		for each (var snd:ScratchSound in viewedObj.sounds) {
			result.push(Scratch.app.createMediaInfo(snd, viewedObj));
		}
		return result;
	}

	// Returns true if the costume changed
	private function updateCostumeSelection():Boolean {
		var viewedObj:ScratchObj = app.viewedObj();
		if ((viewedObj == null) || isSound) return false;
		var current:ScratchCostume = viewedObj.currentCostume();
		if (current == lastCostume) return false;
		var oldCostume:ScratchCostume = lastCostume;
		for (var i:int = 0 ; i < numChildren ; i++) {
			var ci:MediaInfo = getChildAt(i) as MediaInfo;
			if (ci != null) {
				if (ci.mycostume == current) {
					ci.highlight();
					scrollToItem(ci);
				} else {
					ci.unhighlight();
				}
			}
		}
		lastCostume = current;
		return (oldCostume != null);
	}

	private function scrollToItem(item:MediaInfo):void {
		var frame:ScrollFrame = parent as ScrollFrame;
		if (!frame) return;
		var itemTop:int = item.y + y - 1;
		var itemBottom:int = itemTop + item.height;
		y -= Math.max(0, itemBottom - frame.visibleH());
		y -= Math.min(0, itemTop);
		frame.updateScrollbars();
	}

	private function updateSoundSelection():void {
		var viewedObj:ScratchObj = app.viewedObj();
		if ((viewedObj == null) || !isSound) return;
		if (viewedObj.sounds.length < 1) return;
		if (!this.parent || !this.parent.parent) return;
		var sp:SoundsPart = this.parent.parent as SoundsPart;
		if (sp == null) return;
	 	sp.currentIndex = Math.min(sp.currentIndex, viewedObj.sounds.length - 1);
		var current:ScratchSound = viewedObj.sounds[sp.currentIndex] as ScratchSound;
		for (var i:int = 0 ; i < numChildren ; i++) {
			var si:MediaInfo = getChildAt(i) as MediaInfo;
			if (si != null) {
				if (si.mysound == current) si.highlight();
				else si.unhighlight();
			}
		}
	}

	// -----------------------------
	// Dropping
	//------------------------------

	public function handleDrop(obj:*):Boolean {
		var item:MediaInfo = obj as MediaInfo;
		if (item && item.owner == app.viewedObj()) {
			changeMediaOrder(item);
			return true;
		}
		return false;
	}

	private function changeMediaOrder(dropped:MediaInfo):void {
		var inserted:Boolean = false;
		var newItems:Array = [];
		var dropY:int = globalToLocal(new Point(dropped.x, dropped.y)).y;
		for (var i:int = 0; i < numChildren; i++) {
			var item:MediaInfo = getChildAt(i) as MediaInfo;
			if (!item) continue; // skip item numbers
			if (!inserted && (dropY < item.y)) {
				newItems.push(dropped);
				inserted = true;
			}
			if (!sameMedia(item, dropped)) newItems.push(item);
		}
		if (!inserted) newItems.push(dropped);
		replacedMedia(newItems);
		// update the target object with the new costume/sound list
		// refresh();
	}

	private function sameMedia(item1:MediaInfo, item2:MediaInfo):Boolean {
		if (item1.mycostume && (item1.mycostume == item2.mycostume)) return true;
		if (item1.mysound && (item1.mysound == item2.mysound)) return true;
		return false;
	}

	private function replacedMedia(newList:Array):void {
		// Note: Clones can share the costume and sound arrays with their prototype,
		// so this method mutates those arrays in place rather than replacing them.
		var el:MediaInfo;
		var scratchObj:ScratchObj = app.viewedObj();
		if (isSound) {
			scratchObj.sounds.splice(0); // remove all
			for each (el in newList) {
				if (el.mysound) scratchObj.sounds.push(el.mysound);
			}
		} else {
			var oldCurrentCostume:ScratchCostume = scratchObj.currentCostume();
			scratchObj.costumes.splice(0); // remove all
			for each (el in newList) {
				if (el.mycostume) scratchObj.costumes.push(el.mycostume);
			}
			var cIndex:int = scratchObj.costumes.indexOf(oldCurrentCostume);
			if (cIndex > -1) scratchObj.currentCostumeIndex = cIndex;
		}
		app.setSaveNeeded();
		refresh();
	}

}}
