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

package util {
	import flash.display.DisplayObject;
	import blocks.*;
	import interpreter.Variable;
	import scratch.*;
	import watchers.*;

public class OldProjectReader {

	public function extractProject(objTable:Array):ScratchStage {
		var newStage:ScratchStage = new ScratchStage();
		var stageContents:Array = [];
		recordSpriteNames(objTable);
		for (var i:int = 0; i < objTable.length; i++) {
			var entry:Array = objTable[i];
			var classID:int = entry[1];
			if (classID == 125) {
			/* stage:
				objName 9
				vars 10
				blocksBin 11
				isClone 12 (not used)
				media 13
				current costume 14
				---
				zoom 15 (not used)
				hPan 16 (not used)
				vPan 17 (not used)
				obsoleteSavedState 18 (not used)
				spriteOrderInLibrary 19
				volume 20 (always 100 in saved projects)
				tempoBPM 21
				sceneStates 22 (not used)
				lists 23
			*/
				stageContents = entry[5];
				newStage = entry[0];
				newStage.objName = entry[9];
				newStage.variables = buildVars(entry[10]);
				newStage.scripts = buildScripts(entry[11]);
				newStage.scriptComments = buildComments(entry[11]);
				fixCommentRefs(newStage.scriptComments, newStage.scripts)
				newStage.setMedia(entry[13], entry[14]);
				if (entry.length > 19) recordSpriteLibraryOrder(entry[19]);
				if (entry.length > 21) newStage.tempoBPM = entry[21];
				if (entry.length > 23)newStage.lists = buildLists(entry[23], newStage);
			}
			if (classID == 124) {
			/* sprite:
				objName 9
				vars 10
				blocksBin 11
				isClone 12 (not used)
				media 13
				current costume 14
				---
				visibility 15 (always 100 in saved projects)
				scalePoint 16
				rotationDegrees 17
				rotationStyle 18
				volume 19 (always 100 in saved projects)
				tempoBPM 20 (sprites now use stage tempo)
				draggable 21
				sceneStates 22 (not used)
				lists 23
			*/
				var s:ScratchSprite = entry[0];
				s.objName = entry[9];
				s.variables = buildVars(entry[10]);
				s.scripts = buildScripts(entry[11]);
				s.scriptComments = buildComments(entry[11]);
				fixCommentRefs(s.scriptComments, s.scripts)
				s.setMedia(entry[13], entry[14]);
				s.visible = (entry[7] & 1) == 0;
				s.scaleX = s.scaleY = entry[16][0];
				s.rotationStyle = entry[18];
				var dir:Number = Math.round(entry[17] * 1000000) / 1000000; // round to nearest millionth
				s.setDirection(dir - 270);
				if (entry.length > 21) s.isDraggable = entry[21];
				if (entry.length > 23) s.lists = buildLists(entry[23], s);
				var c:ScratchCostume = s.currentCostume();
				s.setScratchXY(
					entry[3][0] + c.rotationCenterX - 240,
					180 - (entry[3][1] + c.rotationCenterY));
			}
		}
		for (i = stageContents.length - 1; i >= 0 ; i--) {
			// filter out any SensorBoardMorphs on the stage
			if (stageContents[i] is DisplayObject) newStage.addChild(stageContents[i]);
		}
		fixWatchers(newStage);
		return newStage;
	}

	private function recordSpriteNames(objTable:Array):void {
		// Set the objName for every sprite in the object table.
		// This must be done before processing scripts so that
		// inter-sprite references (e.g. in 'distanceTo:' can
		// be converted from a direct object reference to a name.
		for (var i:int = 0; i < objTable.length; i++) {
			var entry:Array = objTable[i];
			if (entry[1] == 124) {
				ScratchSprite(entry[0]).objName = entry[9];
			}
		}
	}

	private function fixWatchers(newStage:ScratchStage):void {
		// Connect each variable watcher on the stage to its underlying variable.
		// Update the contents of visible list watchers.
		for (var i:int = 0; i < newStage.numChildren; i++) {
			var c:* = newStage.getChildAt(i);
			if (c is Watcher) {
				var w:Watcher = c as Watcher;
				var t:ScratchObj = w.target;
				for each (var v:Variable in t.variables) {
					if (w.isVarWatcherFor(t, v.name)) v.watcher = w;
				}
			}
			if (c is ListWatcher) c.updateTitleAndContents();
		}
	}

	private function recordSpriteLibraryOrder(spriteList:Array):void {
		for (var i:int = 0; i < spriteList.length; i++) {
			var s:ScratchSprite = spriteList[i];
			s.indexInLibrary = i;
		}
	}

	private function buildVars(pairs:Array):Array {
		if (pairs == null) return [];
		var result:Array = [];
		for (var i:int = 0; i < (pairs.length - 1); i += 2) {
			result.push(new Variable(pairs[i], pairs[i + 1]));
		}
		return result;
	}

	private function buildLists(pairs:Array, targetObj:ScratchObj):Array {
		if (pairs == null) return [];
		var result:Array = [];
		for (var i:int = 0; i < (pairs.length - 1); i += 2) {
			var listW:ListWatcher = ListWatcher(pairs[i + 1]);
			listW.target = targetObj;
			result.push(listW);
		}
		return result;
	}

	private function buildScripts(scripts:Array):Array {
		if (!(scripts[0] is Array)) return [];
		var result:Array = [];
		for each (var stack:Array in scripts) {
			// stack is of form: [[x y] [blocks]]
			var a:Array = stack[1][0];
			if (a && (a[0] == 'scratchComment')) continue; // skip comments
			var topBlock:Block = BlockIO.arrayToStack(stack[1]);
			topBlock.x = stack[0][0];
			topBlock.y = stack[0][1];
			result.push(topBlock);
		}
		return result;
	}

	private function buildComments(scripts:Array):Array {
		if (!(scripts[0] is Array)) return [];
		var result:Array = [];
		for each (var stack:Array in scripts) {
			// stack is of form: [[x y] [blocks]]
			var a:Array = stack[1][0];
			if (a && (a[0] != 'scratchComment')) continue; // skip non-comments
			var blockID:int = a[4] ? a[4] : -1;
			var comment:ScratchComment = new ScratchComment(a[1], a[2], a[3], blockID);
			comment.x = stack[0][0];
			comment.y = stack[0][1];
			result.push(comment);
		}
		return result;
	}

	private function fixCommentRefs(comments:Array, stacks:Array):void {
		// Bind comments block references, using the Squeak enumeration order.
		var blockListOld:Array = [null]; // Scratch 1.4 blockRefs are 1-based
		var blockListNew:Array = []; // Scratch 2.0 blockRefs are 0-based
		for each (var b:Block in stacks) {
			b.fixStackLayout();
			oldAddAllBlocksTo(b, blockListOld);
			newAddAllBlocksTo(b, blockListNew);
		}
		for each (var c:ScratchComment in comments) {
			if ((c.blockID > 0) && (c.blockID < blockListOld.length)) {
				var target:Block = blockListOld[c.blockID] as Block;
				var newID:int = blockListNew.indexOf(target);
				c.blockID = newID;
			}
		}
	}

	private function oldAddAllBlocksTo(b:Block, blockList:Array):void {
		// Recursively enumerate all blocks of the given stack in Squeak order
		// and add them to blockList. Block arguments are not included.
		if (b.subStack2) oldAddAllBlocksTo(b.subStack2, blockList);
		if (b.subStack1) oldAddAllBlocksTo(b.subStack1, blockList);
		if (b.nextBlock) oldAddAllBlocksTo(b.nextBlock, blockList);
		blockList.push(b);
	}

	private function newAddAllBlocksTo(b:Block, blockList:Array):void {
		// Recursively enumerate all blocks of the given stack in Squeak order
		// and add them to blockList. Block arguments are not included.
		blockList.push(b);
		if (b.subStack1) newAddAllBlocksTo(b.subStack1, blockList);
		if (b.subStack2) newAddAllBlocksTo(b.subStack2, blockList);
		if (b.nextBlock) newAddAllBlocksTo(b.nextBlock, blockList);
	}

	private function arrayToString(a:Array):String {
		var result:String = '[', i:int;
		for (i = 0; i < a.length; i++) {
			result += (a[i] is Array) ? arrayToString(a[i]) : a[i];
			if (i < (a.length - 1)) result += ' ';
		}
		return result + ']';
	}

}}
