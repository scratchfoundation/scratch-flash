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

// ScratchObj.as
// John Maloney, April 2010
//
// This is the superclass for both ScratchStage and ScratchSprite,
// containing the variables and methods common to both.

package scratch {
	import blocks.*;

	import filters.FilterPack;

	import flash.display.*;
	import flash.events.MouseEvent;
import flash.geom.ColorTransform;
import flash.utils.*;

	import interpreter.*;

	import scratch.ScratchComment;
import scratch.ScratchSprite;

import translation.Translator;

	import util.*;

	import watchers.*;

public class ScratchObj extends Sprite {

	[Embed(source='../assets/pop.wav', mimeType='application/octet-stream')] protected static var Pop:Class;

	public static const STAGEW:int = 480;
	public static const STAGEH:int = 360;

	public var objName:String = 'no name';
	public var isStage:Boolean = false;
	public var variables:Array = [];
	public var lists:Array = [];
	public var scripts:Array = [];
	public var scriptComments:Array = [];
	public var sounds:Array = [];
	public var costumes:Array = [];
	public var currentCostumeIndex:Number;
	public var volume:Number = 100;
	public var instrument:int = 0;
	public var filterPack:FilterPack;
	public var isClone:Boolean;

	public var img:Sprite; // holds a bitmap or svg object, after applying image filters, scale, and rotation
	private var lastCostume:ScratchCostume;

	// Caches used by the interpreter:
	public var listCache:Object = {};
	public var procCache:Object = {};
	public var varCache:Object = {};

	public function clearCaches():void {
		// Clear the list, procedure, and variable caches for this object.
		listCache = {};
		procCache = {};
		varCache = {};
	}

	public function allObjects():Array { return [this] }

	public function deleteCostume(c:ScratchCostume):void {
		if (costumes.length < 2) return; // a sprite must have at least one costume
		var i:int = costumes.indexOf(c);
		if (i < 0) return;
		costumes.splice(i, 1);
		if (currentCostumeIndex >= i) showCostume(currentCostumeIndex - 1);
		if (Scratch.app) Scratch.app.setSaveNeeded();
	}

	public function deleteSound(snd:ScratchSound):void {
		var i:int = sounds.indexOf(snd);
		if (i < 0) return;
		sounds.splice(i, 1);
		if (Scratch.app) Scratch.app.setSaveNeeded();
	}

	public function showCostumeNamed(n:String):void {
		var i:int = indexOfCostumeNamed(n);
		if (i >= 0) showCostume(i);
	}

	public function indexOfCostumeNamed(n:String):int {
		for (var i:int = 0; i < costumes.length; i++) {
			if (ScratchCostume(costumes[i]).costumeName == n) return i;
		}
		return -1;
	}

	public function showCostume(costumeIndex:Number):void {
		if (isNaNOrInfinity(costumeIndex)) costumeIndex = 0;
		currentCostumeIndex = costumeIndex % costumes.length;
		if (currentCostumeIndex < 0) currentCostumeIndex += costumes.length;
		var c:ScratchCostume = currentCostume();
		if (c == lastCostume) return; // optimization: already showing that costume
		lastCostume = c.isBitmap() ? c : null; // cache only bitmap costumes for now

		updateImage();
	}

	public function updateCostume():void { updateImage(); }

	public function currentCostume():ScratchCostume {
		return costumes[Math.round(currentCostumeIndex) % costumes.length];
	}

	public function costumeNumber():int {
		// One-based costume number as seen by user (currentCostumeIndex is 0-based)
		return currentCostumeIndex + 1;
	}

	public function unusedCostumeName(baseName:String = ''):String {
		// Create a unique costume name by appending a number if necessary.
		if (baseName == '') baseName = Translator.map(isStage ? 'backdrop1' : 'costume1');
		var existingNames:Array = [];
		for each (var c:ScratchCostume in costumes) {
			existingNames.push(c.costumeName.toLowerCase());
		}
		var lcBaseName:String = baseName.toLowerCase();
		if (existingNames.indexOf(lcBaseName) < 0) return baseName; // basename is not already used
		lcBaseName = withoutTrailingDigits(lcBaseName);
		var i:int = 2;
		while (existingNames.indexOf(lcBaseName + i) >= 0) { i++ } // find an unused name
		return withoutTrailingDigits(baseName) + i;
	}

	public function unusedSoundName(baseName:String = ''):String {
		// Create a unique sound name by appending a number if necessary.
		if (baseName == '') baseName = 'sound';
		var existingNames:Array = [];
		for each (var snd:ScratchSound in sounds) {
			existingNames.push(snd.soundName.toLowerCase());
		}
		var lcBaseName:String = baseName.toLowerCase();
		if (existingNames.indexOf(lcBaseName) < 0) return baseName; // basename is not already used
		lcBaseName = withoutTrailingDigits(lcBaseName);
		var i:int = 2;
		while (existingNames.indexOf(lcBaseName + i) >= 0) { i++ } // find an unused name
		return withoutTrailingDigits(baseName) + i;
	}

	protected function withoutTrailingDigits(s:String):String {
		var i:int = s.length - 1;
		while ((i >= 0) && ('0123456789'.indexOf(s.charAt(i)) > -1)) i--;
		return s.slice(0, i + 1);
	}

	protected function updateImage():void {
		var currChild:DisplayObject = (img.numChildren == 1 ? img.getChildAt(0) : null);
		var currDispObj:DisplayObject = currentCostume().displayObj();
		var change:Boolean = (currChild != currDispObj);
		if(change) {
			while (img.numChildren > 0) img.removeChildAt(0);
			img.addChild(currDispObj);
		}
		clearCachedBitmap();
		adjustForRotationCenter();
		updateRenderDetails(0);
	}

	protected function updateRenderDetails(reason:uint):void {
	SCRATCH::allow3d {
		if(this is ScratchStage || this is ScratchSprite || (parent && parent is ScratchStage)) {
			var renderOpts:Object = {};
			var costume:ScratchCostume = currentCostume();

			// 0 - costume change, 1 - rotation style change
			if(reason == 0) {
				if(costume && costume.baseLayerID == ScratchCostume.WasEdited)
					costume.prepareToSave();

				var id:String = (costume ? costume.baseLayerMD5 : null);
				if(!id) id = objName + (costume ? costume.costumeName : '_' + currentCostumeIndex);
				else if(costume && costume.textLayerMD5) id += costume.textLayerMD5;

				renderOpts.bitmap = (costume && costume.bitmap ? costume.bitmap : null);
			}

			// TODO: Clip original bitmap to match visible bounds?
			if(reason == 1)
				renderOpts.costumeFlipped = (this is ScratchSprite ? (this as ScratchSprite).isCostumeFlipped() : false);

			if(reason == 0) {
				if(this is ScratchSprite) {
					renderOpts.bounds = (this as ScratchSprite).getVisibleBounds(this);
					renderOpts.raw_bounds = getBounds(this);
				}
				else
					renderOpts.bounds = getBounds(this);
			}
			if (Scratch.app.isIn3D) Scratch.app.render3D.updateRender((this is ScratchStage ? img : this), id, renderOpts);
		}
	}
	}

	protected function adjustForRotationCenter():void {
		// Adjust the offset of img relative to it's parent. If this object is a
		// ScratchSprite, then img is adjusted based on the costume's rotation center.
		// If it is a ScratchStage, img is centered on the stage.
		var costumeObj:DisplayObject = img.getChildAt(0);
		if (isStage) {
			if (costumeObj is Bitmap) {
				img.x = (STAGEW - costumeObj.width) / 2;
				img.y = (STAGEH - costumeObj.height) / 2;
			} else {
				// SVG costume; don't center for now
				img.x = img.y = 0;
			}
		} else {
			var c:ScratchCostume = currentCostume();
			costumeObj.scaleX = 1 / c.bitmapResolution; // don't flip
			img.x = -c.rotationCenterX / c.bitmapResolution;
			img.y = -c.rotationCenterY / c.bitmapResolution;
			if ((this as ScratchSprite).isCostumeFlipped()) {
				costumeObj.scaleX = -1 / c.bitmapResolution; // flip
				img.x = -img.x;
			}
		}
	}

	public function clearCachedBitmap():void {
		// Does nothing here, but overridden in ScratchSprite
	}

	static private var cTrans:ColorTransform = new ColorTransform();
	public function applyFilters(forDragging:Boolean = false):void {
		img.filters = filterPack.buildFilters(forDragging);
		clearCachedBitmap();
		if(!Scratch.app.isIn3D || forDragging) {
			var n:Number = Math.max(0, Math.min(filterPack.getFilterSetting('ghost'), 100));
			cTrans.alphaMultiplier = 1.0 - (n / 100.0);
			n = 255 * Math.max(-100, Math.min(filterPack.getFilterSetting('brightness'), 100)) / 100;
			cTrans.redOffset = cTrans.greenOffset = cTrans.blueOffset = n;
			img.transform.colorTransform = cTrans;
		}
		else {
			updateEffectsFor3D();
		}
	}

	public function updateEffectsFor3D():void {
		SCRATCH::allow3d {
			if((parent && parent is ScratchStage) || this is ScratchStage) {
				if(parent is ScratchStage)
					(parent as ScratchStage).updateSpriteEffects(this, filterPack.getAllSettings());
				else {
					(this as ScratchStage).updateSpriteEffects(img, filterPack.getAllSettings());
//					if((this as ScratchStage).videoImage)
//						(this as ScratchStage).updateSpriteEffects((this as ScratchStage).videoImage, filterPack.getAllSettings());
				}
			}
		}
	}

	protected function shapeChangedByFilter():Boolean {
		var filters:Object = filterPack.getAllSettings();
		return (filters['fisheye'] !== 0 || filters['whirl'] !== 0 || filters['mosaic'] !== 0);
	}

	static public const clearColorTrans:ColorTransform = new ColorTransform();
	public function clearFilters():void {
		filterPack.resetAllFilters();
		img.filters = [];
		img.transform.colorTransform = clearColorTrans;
		clearCachedBitmap();

		SCRATCH::allow3d {
			if (parent && parent is ScratchStage) {
				(parent as ScratchStage).updateSpriteEffects(this, null);
			}
		}
	}

	public function setMedia(media:Array, currentCostume:ScratchCostume):void {
		var newCostumes:Array = [];
		sounds = [];
		for each (var m:* in media) {
			if (m is ScratchSound) sounds.push(m);
			if (m is ScratchCostume) newCostumes.push(m);
		}
		if (newCostumes.length > 0) costumes = newCostumes;
		var i:int = costumes.indexOf(currentCostume);
		currentCostumeIndex = (i < 0) ? 0 : i;
		showCostume(i);
	}

	public function defaultArgsFor(op:String, specDefaults:Array):Array {
		// Return an array of default parameter values for the given operation (primitive name).
		// For most ops, this will simply return the array of default arg values from the command spec.
		var sprites:Array;

		if ((['broadcast:', 'doBroadcastAndWait', 'whenIReceive'].indexOf(op)) > -1) {
			var msgs:Array = Scratch.app.runtime.collectBroadcasts();
			return [msgs[0]];
		}
		if ((['lookLike:', 'startScene', 'startSceneAndWait', 'whenSceneStarts'].indexOf(op)) > -1) {
			return [costumes[costumes.length - 1].costumeName];
		}
		if ((['playSound:', 'doPlaySoundAndWait'].indexOf(op)) > -1) {
			return (sounds.length > 0) ? [sounds[sounds.length - 1].soundName] : [''];
		}
		if ('createCloneOf' == op) {
			if (!isStage) return ['_myself_'];
			sprites = Scratch.app.stagePane.sprites();
			return (sprites.length > 0) ? [sprites[sprites.length - 1].objName] : [''];
		}
		if ('getAttribute:of:' == op) {
			sprites = Scratch.app.stagePane.sprites();
			return (sprites.length > 0) ? ['x position', sprites[sprites.length - 1].objName] : ['volume', '_stage_'];
		}

		if ('setVar:to:' == op) return [defaultVarName(), 0];
		if ('changeVar:by:' == op) return [defaultVarName(), 1];
		if ('showVariable:' == op) return [defaultVarName()];
		if ('hideVariable:' == op) return [defaultVarName()];

		if ('append:toList:' == op) return ['thing', defaultListName()];
		if ('deleteLine:ofList:' == op) return [1, defaultListName()];
		if ('insert:at:ofList:' == op) return ['thing', 1, defaultListName()];
		if ('setLine:ofList:to:' == op) return [1, defaultListName(), 'thing'];
		if ('getLine:ofList:' == op) return [1, defaultListName()];
		if ('lineCountOfList:' == op) return [defaultListName()];
		if ('list:contains:' == op) return [defaultListName(), 'thing'];
		if ('showList:' == op) return [defaultListName()];
		if ('hideList:' == op) return [defaultListName()];

		return specDefaults;
	}

	public function defaultVarName():String {
		if (variables.length > 0) return variables[variables.length - 1].name; // local var
		return isStage ? '' : Scratch.app.stagePane.defaultVarName(); // global var, if any
	}

	public function defaultListName():String {
		if (lists.length > 0) return lists[lists.length - 1].listName; // local list
		return isStage ? '' : Scratch.app.stagePane.defaultListName(); // global list, if any
	}

	/* Scripts */

	public function allBlocks():Array {
		var result:Array = [];
		for each (var script:Block in scripts) {
			script.allBlocksDo(function(b:Block):void { result.push(b) });
		}
		return result;
	}

	public function visibleScripts():Array {
		var result:Array = [];
		for each (var script:Block in scripts) {
			if (script.op === Specs.PROCEDURE_DEF) {
				if (script.spec.indexOf(Specs.MAGIC_PROC_PREFIX) === 0) {
					continue;
				}
			}
			result.push(script);
		}
		return result;
	}

	public function magicProcedureDefinitions():Array {
		var result:Array = [];
		for each (var script:Block in scripts) {
			if (script.op === Specs.PROCEDURE_DEF) {
				if (script.spec.indexOf(Specs.MAGIC_PROC_PREFIX) === 0) {
					result.push(script);
				}
			}
		}
		return result;
	}

	/* Sounds */

	public function findSound(arg:*):ScratchSound {
		// Return a sound describe by arg, which can be a string (sound name),
		// a number (sound index), or a string representing a number (sound index).
		if (sounds.length == 0) return null;
		if (typeof(arg) == 'number') {
			var i:int = Math.round(arg - 1) % sounds.length;
			if (i < 0) i += sounds.length; // ensure positive
			return sounds[i];
		} else if (typeof(arg) == 'string') {
			for each (var snd:ScratchSound in sounds) {
				if (snd.soundName == arg) return snd; // arg matches a sound name
			}
			// try converting string arg to a number
			var n:Number = Number(arg);
			if (isNaN(n)) return null;
			return findSound(n);
		}
		return null;
	}

	public function setVolume(vol:Number):void {
		volume = Math.max(0, Math.min(vol, 100));
	}

	public function setInstrument(instr:Number):void {
		instrument = Math.max(1, Math.min(Math.round(instr), 128));
	}

	/* Procedures */

	public function procedureDefinitions():Array {
		var result:Array = [];
		for (var i:int = 0; i < scripts.length; i++) {
			var b:Block = scripts[i] as Block;
			if (
				b && (b.op == Specs.PROCEDURE_DEF) &&
				b.spec.indexOf(Specs.MAGIC_PROC_PREFIX) !== 0
			) result.push(b);
		}
		return sortScriptsArray(result);
	}

	public function sortScriptsArray(arr:Array):Array {
		return arr.sort(function(a:Block, b:Block):int {
      var aStr:String = a.getSummary();
      var bStr:String = b.getSummary();
      if (aStr < bStr) {
        return -1;
      } else if (aStr > bStr) {
        return 1;
      } else {
        return 0;
      }
    });
	}

	public function lookupProcedure(procName:String):Block {
		for (var i:int = 0; i < scripts.length; i++) {
			var b:Block = scripts[i] as Block;
			if (b && (b.op == Specs.PROCEDURE_DEF) && (b.spec == procName)) return b;
		}
		return null;
	}

	/* Variables */

	public function varNames():Array {
		var varList:Array = [];
		for each (var v:Variable in variables) {
			if (v.name.indexOf(Specs.BROADCAST_VAR_PREFIX) !== 0) {
				varList.push(v.name);
			}
		}
		return varList.sort();
	}

	public function setVarTo(varName:String, value:*):void {
		var v:Variable = lookupOrCreateVar(varName);
		v.value = value;
		Scratch.app.runtime.updateVariable(v);
	}

	public function ownsVar(varName:String):Boolean {
		// Return true if this object owns a variable of the given name.
		for each (var v:Variable in variables) {
			if (v.name == varName) return true;
		}
		return false;
	}

	public function hasName(varName:String):Boolean {
		var p:ScratchObj = parent as ScratchObj;
		return ownsVar(varName) || ownsList(varName) || p && (p.ownsVar(varName) || p.ownsList(varName));
	}

	public function lookupOrCreateVar(varName:String):Variable {
		// Lookup and return a variable. If lookup fails, create the variable in this object.
		var v:Variable = lookupVar(varName);
		if (v == null) { // not found; create it
			v = new Variable(varName, 0);
			variables.push(v);
			Scratch.app.updatePalette(false);
		}
		return v;
	}

	public function lookupVar(varName:String):Variable {
		// Look for variable first in sprite (local), then stage (global).
		// Return null if not found.
		var v:Variable;
		for each (v in variables) {
			if (v.name == varName) return v;
		}
		for each (v in Scratch.app.stagePane.variables) {
			if (v.name == varName) return v;
		}
		return null;
	}

	public function deleteVar(varToDelete:String):void {
		var newVars:Array = [];
		for each (var v:Variable in variables) {
			if (v.name == varToDelete) {
				if ((v.watcher != null) && (v.watcher.parent != null)) {
					v.watcher.parent.removeChild(v.watcher);
				}
				v.watcher = v.value = null;
			}
			else newVars.push(v);
		}
		variables = newVars;
	}

	/* Lists */

	public function listNames():Array {
		var result:Array = [];
		for each (var list:ListWatcher in lists) result.push(list.listName);
		return result.sort();
	}

	public function ownsList(listName:String):Boolean {
		// Return true if this object owns a list of the given name.
		for each (var w:ListWatcher in lists) {
			if (w.listName == listName) return true;
		}
		return false;
	}

	public function lookupOrCreateList(listName:String):ListWatcher {
		// Look and return a list. If lookup fails, create the list in this object.
		var list:ListWatcher = lookupList(listName);
		if (list == null) { // not found; create it
			list = new ListWatcher(listName, [], this);
			lists.push(list);
			Scratch.app.updatePalette(false);
		}
		return list;
	}

	public function lookupList(listName:String):ListWatcher {
		// Look for list first in this sprite (local), then stage (global).
		// Return null if not found.
		var list:ListWatcher;
		for each (list in lists) {
			if (list.listName == listName) return list;
		}
		for each (list in Scratch.app.stagePane.lists) {
			if (list.listName == listName) return list;
		}
		return null;
	}

	public function deleteList(listName:String):void {
		var newLists:Array = [];
		for each (var w:ListWatcher in lists) {
			if (w.listName == listName) {
				if (w.parent) w.parent.removeChild(w);
			} else {
				newLists.push(w);
			}
		}
		lists = newLists;
	}

	/* Events */

	private const DOUBLE_CLICK_MSECS:int = 300;
	private var lastClickTime:uint;

	public function click(evt:MouseEvent):void {
		var app:Scratch = root as Scratch;
		if (!app) return;
		var now:uint = getTimer();
		app.runtime.startClickedHats(this);
		if ((now - lastClickTime) < DOUBLE_CLICK_MSECS) {
			if (isStage || ScratchSprite(this).isClone) return;
			app.selectSprite(this);
			lastClickTime = 0;
		} else {
			lastClickTime = now;
		}
	}

	/* Translation */

	public function updateScriptsAfterTranslation():void {
		// Update the scripts of this object after switching languages.
		var newScripts:Array = [];
		for each (var b:Block in scripts) {
			var newStack:Block = BlockIO.arrayToStack(BlockIO.stackToArray(b), isStage);
			newStack.x = b.x;
			newStack.y = b.y;
			newScripts.push(newStack);
			if (b.parent) { // stack in the scripts pane; replace it
				b.parent.addChild(newStack);
				b.parent.removeChild(b);
			}
		}
		scripts = newScripts;
		var blockList:Array = allBlocks();
		for each (var c:ScratchComment in scriptComments) {
			c.updateBlockRef(blockList);
		}
	}

	/* Saving */

	public function writeJSON(json:util.JSON):void {
		var allScripts:Array = [];
		for each (var b:Block in scripts) {
			allScripts.push([b.x, b.y, BlockIO.stackToArray(b)]);
		}
		var allComments:Array = [];
		for each (var c:ScratchComment in scriptComments) {
			allComments.push(c.toArray());
		}
		json.writeKeyValue('objName', objName);
		if (variables.length > 0)	json.writeKeyValue('variables', variables);
		if (lists.length > 0)		json.writeKeyValue('lists', lists);
		if (scripts.length > 0)		json.writeKeyValue('scripts', allScripts);
		if (scriptComments.length > 0) json.writeKeyValue('scriptComments', allComments);
		if (sounds.length > 0)		json.writeKeyValue('sounds', sounds);
		json.writeKeyValue('costumes', costumes);
		json.writeKeyValue('currentCostumeIndex', currentCostumeIndex);
	}

	public function readJSON(jsonObj:Object):void {
		objName = jsonObj.objName;
		variables = jsonObj.variables || [];
		for (var i:int = 0; i < variables.length; i++) {
			var varObj:Object = variables[i];
			variables[i] = Scratch.app.runtime.makeVariable(varObj);
		}
		lists = jsonObj.lists || [];
		scripts = jsonObj.scripts || [];
		scriptComments = jsonObj.scriptComments || [];
		sounds = jsonObj.sounds || [];
		costumes = jsonObj.costumes || [];
		currentCostumeIndex = jsonObj.currentCostumeIndex;
		if (isNaNOrInfinity(currentCostumeIndex)) currentCostumeIndex = 0;
	}

	private function isNaNOrInfinity(n:Number):Boolean {
		if (n != n) return true; // NaN
		if (n == Number.POSITIVE_INFINITY) return true;
		if (n == Number.NEGATIVE_INFINITY) return true;
		return false;
	}

	public function instantiateFromJSON(newStage:ScratchStage):void {
		var i:int, jsonObj:Object;

		// lists
		for (i = 0; i < lists.length; i++) {
			jsonObj = lists[i];
			var newList:ListWatcher = new ListWatcher();
			newList.readJSON(jsonObj);
			newList.target = this;
			newStage.addChild(newList);
			newList.updateTitleAndContents();
			lists[i] = newList;
		}

		// scripts
		var scriptEntries:Array = scripts;
		scripts = [];
		addJSONScripts(scriptEntries);

		// script comments
		for (i = 0; i < scriptComments.length; i++) {
			scriptComments[i] = ScratchComment.fromArray(scriptComments[i]);
		}

		// sounds
		for (i = 0; i < sounds.length; i++) {
			jsonObj = sounds[i];
			sounds[i] = new ScratchSound('json temp', null);
			sounds[i].readJSON(jsonObj);
		}

		// costumes
		for (i = 0; i < costumes.length; i++) {
			jsonObj = costumes[i];
			costumes[i] = new ScratchCostume('json temp', null);
			costumes[i].readJSON(jsonObj);
		}
	}

	public function addJSONScripts(scriptEntries:Array):void {
		for each (var entry:Array in scriptEntries) {
			// Entries are of the form [x, y, stack]
			var b:Block = BlockIO.arrayToStack(entry[2], isStage);
			b.x = entry[0];
			b.y = entry[1];
			scripts.push(b);
		}
	}

	public function getSummary():String {
		var s:Array = [];
		s.push(h1(objName));
		if (variables.length) {
			s.push(h2(Translator.map("Variables")));
			for each (var v:Variable in variables) {
				s.push("- " + v.name + " = " + v.value);
			}
			s.push("");
		}
		if (lists.length) {
			s.push(h2(Translator.map("Lists")));
			for each (var list:ListWatcher in lists) {
				s.push("- " + list.listName + (list.contents.length ? ":" : ""));
				for each (var item:* in list.contents) {
					s.push("    - " + item);
				}
			}
			s.push("");
		}
		s.push(h2(Translator.map(isStage ? "Backdrops" : "Costumes")));
		for each (var costume:ScratchCostume in costumes) {
			s.push("- " + costume.costumeName);
		}
		s.push("");
		if (sounds.length) {
			s.push(h2(Translator.map("Sounds")));
			for each (var sound:ScratchSound in sounds) {
				s.push("- " + sound.soundName);
			}
			s.push("");
		}
		if (scripts.length) {
			s.push(h2(Translator.map("Scripts")));
			for each (var script:Block in scripts) {
				s.push(script.getSummary());
				s.push("")
			}
		}
		return s.join("\n");
	}

	protected static function h1(s:String, ch:String = "="):String {
		return s + "\n" + new Array(s.length + 1).join(ch) + "\n";
	}
	protected static function h2(s:String):String {
		return h1(s, "-");
	}

}}
