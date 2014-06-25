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

// ScratchRuntime.as
// John Maloney, September 2010

package scratch {
	import flash.display.*;
	import flash.events.*;
	import flash.external.ExternalInterface;
	import flash.geom.Rectangle;
	import flash.media.*;
	import flash.net.*;
	import flash.system.System;
	import flash.text.TextField;
	import flash.utils.*;
	import blocks.*;
	import interpreter.*;
	import primitives.VideoMotionPrims;
	import sound.ScratchSoundPlayer;
	import translation.*;
	import ui.media.MediaInfo;
	import ui.BlockPalette;
	import uiwidgets.DialogBox;
	import util.*;
	import watchers.*;

public class ScratchRuntime {

	public var app:Scratch;
	public var interp:Interpreter;
	public var motionDetector:VideoMotionPrims;
	public var keyIsDown:Array = new Array(128); // records key up/down state
	public var shiftIsDown:Boolean;
	public var lastAnswer:String = '';
	public var cloneCount:int;
	public var edgeTriggersEnabled:Boolean = false; // initially false, becomes true when project first run

	private var microphone:Microphone;
	private var timerBase:uint;

	protected var projectToInstall:ScratchStage;
	protected var saveAfterInstall:Boolean;

	public function ScratchRuntime(app:Scratch, interp:Interpreter) {
		this.app = app;
		this.interp = interp;
		timerBase = interp.currentMSecs;
		clearKeyDownArray();
	}

	// -----------------------------
	// Running and stopping
	//------------------------------

	public function stepRuntime():void {
		if (projectToInstall != null && app.isOffline) {
			installProject(projectToInstall);
			if (saveAfterInstall) app.setSaveNeeded(true);
			projectToInstall = null;
			saveAfterInstall = false;
			app.loadInProgress = false;
			return;
		}

		if (recording) saveFrame(); // Recording a Youtube video?  Old / Unused currently.
		app.extensionManager.step();
		if (motionDetector) motionDetector.step(); // Video motion detection

		// Step the stage, sprites, and watchers
		app.stagePane.step(this);

		// run scripts and commit any pen strokes
		processEdgeTriggeredHats();
		interp.stepThreads();
		app.stagePane.commitPenStrokes();
	 }

//-------- recording test ---------
	public var recording:Boolean;
	private var frames:Array = [];

	private function saveFrame():void {
		var f:BitmapData = new BitmapData(480, 360);
		f.draw(app.stagePane);
		frames.push(f);
		if ((frames.length % 100) == 0) {
			trace('frames: ' + frames.length + ' mem: ' + System.totalMemory);
		}
	}

	public function startRecording():void {
		clearRecording();
		recording = true;
	}

	public function stopRecording():void {
		recording = false;
	}

	public function clearRecording():void {
		recording = false;
		frames = [];
		System.gc();
		trace('mem: ' + System.totalMemory);
	}

	// TODO: If keeping this then make it write each frame while recording AND add sound recording
	public function saveRecording():void {
		var myWriter:SimpleFlvWriter = SimpleFlvWriter.getInstance();
		var data:ByteArray = new ByteArray();
		myWriter.createFile(data, 480, 360, 30, frames.length / 30.0);
		for (var i:int = 0; i < frames.length; i++) {
			myWriter.saveFrame(frames[i]);
			frames[i] = null;
		}
		frames = [];
		trace('data: ' + data.length);
		new FileReference().save(data, 'movie.flv');
	}

//----------
	public function stopAll():void {
		interp.stopAllThreads();
		clearRunFeedback();
		app.stagePane.deleteClones();
		cloneCount = 0;
		clearKeyDownArray();
		ScratchSoundPlayer.stopAllSounds();
		app.extensionManager.stopButtonPressed();
		app.stagePane.clearFilters();
		for each (var s:ScratchSprite in app.stagePane.sprites()) {
			s.clearFilters();
			s.hideBubble();
		}
		clearAskPrompts();
		app.removeLoadProgressBox();
		motionDetector = null;
	}

	// -----------------------------
	// Hat Blocks
	//------------------------------

	public function startGreenFlags(firstTime:Boolean = false):void {
		function startIfGreenFlag(stack:Block, target:ScratchObj):void {
			if (stack.op == 'whenGreenFlag') interp.toggleThread(stack, target);
		}
		stopAll();
		lastAnswer = '';
		if (firstTime && app.stagePane.info.videoOn) {
			// turn on video the first time if project was saved with camera on
			app.stagePane.setVideoState('on');
		}
		clearEdgeTriggeredHats();
		timerReset();
		setTimeout(function():void {
			allStacksAndOwnersDo(startIfGreenFlag);
		}, 0);
	}

	public function startClickedHats(clickedObj:ScratchObj):void {
		for each (var stack:Block in clickedObj.scripts) {
			if (stack.op == 'whenClicked') {
				interp.restartThread(stack, clickedObj);
			}
		}
	}

	private function startKeyHats(ch:int):void {
		var keyName:String = null;
		if (('a'.charCodeAt(0) <= ch) && (ch <= 'z'.charCodeAt(0))) keyName = String.fromCharCode(ch);
		if (('0'.charCodeAt(0) <= ch) && (ch <= '9'.charCodeAt(0))) keyName = String.fromCharCode(ch);
		if (28 == ch) keyName = 'left arrow';
		if (29 == ch) keyName = 'right arrow';
		if (30 == ch) keyName = 'up arrow';
		if (31 == ch) keyName = 'down arrow';
		if (32 == ch) keyName = 'space';
		if (keyName == null) return;
		var startMatchingKeyHats:Function = function (stack:Block, target:ScratchObj):void {
			if ((stack.op == 'whenKeyPressed') && (stack.args[0].argValue == keyName)) {
				// only start the stack if it is not already running
				if (!interp.isRunning(stack, target)) interp.toggleThread(stack, target);
			}
		}
		allStacksAndOwnersDo(startMatchingKeyHats);
	}

	public function collectBroadcasts():Array {
		function addBlock(b:Block):void {
			if ((b.op == 'broadcast:') ||
				(b.op == 'doBroadcastAndWait') ||
				(b.op == 'whenIReceive')) {
					if (b.args[0] is BlockArg) {
						var msg:String = b.args[0].argValue;
						if (result.indexOf(msg) < 0) result.push(msg);
					}
			}
		}
		var result:Array = [];
		allStacksAndOwnersDo(function (stack:Block, target:ScratchObj):void {
			stack.allBlocksDo(addBlock);
		});
		var palette:BlockPalette = app.palette;
		for (var i:int = 0; i < palette.numChildren; i++) {
			var b:Block = palette.getChildAt(i) as Block;
			if (b) addBlock(b);
		}
		result.sort();
		return result;
	}

	public function hasUnofficialExtensions():Boolean {
		var found:Boolean = false;
		allStacksAndOwnersDo(function (stack:Block, target:ScratchObj):void {
			if(found) return;
			stack.allBlocksDo(function (b:Block):void {
				if(found) return;
				if(isUnofficialExtensionBlock(b))
					found = true;
			});
		});
		return found;
	}

	private function isUnofficialExtensionBlock(b:Block):Boolean {
		var i:int = b.op.indexOf('.');
		if(i == -1) return false;
		var extName:String = b.op.substr(0, i);
		return !app.extensionManager.isInternal(extName);
	}

	public function hasGraphicEffects():Boolean {
		var found:Boolean = false;
		allStacksAndOwnersDo(function (stack:Block, target:ScratchObj):void {
			if(found) return;
			stack.allBlocksDo(function (b:Block):void {
				if(found) return;
				if(isGraphicEffectBlock(b))
					found = true;
			});
		});
		return found;
	}

	private function isGraphicEffectBlock(b:Block):Boolean {
		return ('op' in b && (b.op == 'changeGraphicEffect:by:' || b.op == 'setGraphicEffect:to:') &&
				('argValue' in b.args[0]) && b.args[0].argValue != 'ghost' && b.args[0].argValue != 'brightness');
	}

	// -----------------------------
	// Edge-trigger sensor hats
	//------------------------------

	private var triggeredHats:Array = [];

	private function clearEdgeTriggeredHats():void { edgeTriggersEnabled = true; triggeredHats = [] }

	// hats whose triggering condition is currently true
	private var activeHats:Array = [];
	private function startEdgeTriggeredHats(hat:Block, target:ScratchObj):void {
		if (!hat.isHat || !hat.nextBlock) return; // skip disconnected hats
		var triggerCondition:Boolean = false;
		if ('whenSensorGreaterThan' == hat.op) {
			var sensorName:String = interp.arg(hat, 0);
			var threshold:Number = interp.numarg(hat, 1);
			triggerCondition = (
					(('loudness' == sensorName) && (soundLevel() > threshold)) ||
					(('timer' == sensorName) && (timer() > threshold)) ||
					(('video motion' == sensorName) && (VideoMotionPrims.readMotionSensor('motion', target) > threshold)));
		} else if ('whenSensorConnected' == hat.op) {
			triggerCondition = getBooleanSensor(interp.arg(hat, 0));
		} else if (app.jsEnabled) {
			var dotIndex:int = hat.op.indexOf('.');
			if (dotIndex > -1) {
				var extName:String = hat.op.substr(0, dotIndex);
				if (app.extensionManager.extensionActive(extName)) {
					var op:String = hat.op.substr(dotIndex+1);
					var args:Array = hat.args;
					var finalArgs:Array = new Array(args.length);
					for (var i:uint=0; i<args.length; ++i)
						finalArgs[i] = interp.arg(hat, i);

					if (ExternalInterface.call('ScratchExtensions.getReporter', extName, op, finalArgs)) {
						triggerCondition = true;
					}
				}
			}
		}
		if (triggerCondition) {
			if (triggeredHats.indexOf(hat) == -1) { // not already trigged
				// only start the stack if it is not already running
				if (!interp.isRunning(hat, target)) interp.toggleThread(hat, target);
			}
			activeHats.push(hat);
		}
	}

	private function processEdgeTriggeredHats():void {
		if (!edgeTriggersEnabled) return;
		activeHats = [];
		allStacksAndOwnersDo(startEdgeTriggeredHats);
		triggeredHats = activeHats;
	}

	public function blockDropped(stack:Block):void {
		// Turn on video the first time a video sensor reporter or hat block is added.
		stack.allBlocksDo(function(b:Block):void {
			var op:String = b.op;
			if (('senseVideoMotion' == op) ||
				(('whenSensorGreaterThan' == op) && ('video motion' == interp.arg(b, 0)))) {
					app.libraryPart.showVideoButton();
			}

			// Should we go 3D?
			if(isGraphicEffectBlock(b))
				app.go3D();
		});
	}

	// -----------------------------
	// Project Loading and Installing
	//------------------------------

	public function installEmptyProject():void {
		app.saveForRevert(null, true);
		app.oldWebsiteURL = '';
		installProject(new ScratchStage());
	}

	public function installNewProject():void {
		installEmptyProject();
	}

	public function selectProjectFile():void {
		// Prompt user for a file name and load that file.
		var fileName:String, data:ByteArray;
		function fileSelected(event:Event):void {
			if (fileList.fileList.length == 0) return;
			var file:FileReference = FileReference(fileList.fileList[0]);
			fileName = file.name;
			file.addEventListener(Event.COMPLETE, fileLoadHandler);
			file.load();
		}
		function fileLoadHandler(event:Event):void {
			data = FileReference(event.target).data;
			if (app.stagePane.isEmpty()) doInstall();
			else DialogBox.confirm('Replace contents of the current project?', app.stage, doInstall);
		}
		function doInstall(ignore:* = null):void {
			installProjectFromFile(fileName, data);
		}
		stopAll();
		var fileList:FileReferenceList = new FileReferenceList();
		fileList.addEventListener(Event.SELECT, fileSelected);
		var filter1:FileFilter = new FileFilter('Scratch 1.4 Project', '*.sb');
		var filter2:FileFilter = new FileFilter('Scratch 2 Project', '*.sb2');
		try {
			// Ignore the exception that happens when you call browse() with the file browser open
			fileList.browse([filter1, filter2]);
		} catch(e:*) {}
	}

	public function installProjectFromFile(fileName:String, data:ByteArray):void {
		// Install a project from a file with the given name and contents.
		stopAll();
		app.oldWebsiteURL = '';
		app.loadInProgress = true;
		installProjectFromData(data);
		app.setProjectName(fileName);
	}

	public function installProjectFromData(data:ByteArray, saveForRevert:Boolean = true):void {
		var newProject:ScratchStage;
		stopAll();
		data.position = 0;
		if (data.readUTFBytes(8) != 'ScratchV') {
			data.position = 0;
			newProject = new ProjectIO(app).decodeProjectFromZipFile(data);
			if (!newProject) {
				projectLoadFailed();
				return;
			}
		} else {
			var info:Object;
			var objTable:Array;
			data.position = 0;
			var reader:ObjReader = new ObjReader(data);
			try { info = reader.readInfo() } catch (e:Error) { data.position = 0 }
			try { objTable = reader.readObjTable() } catch (e:Error) { }
			if (!objTable) {
				projectLoadFailed();
				return;
			}
			newProject = new OldProjectReader().extractProject(objTable);
			newProject.info = info;
			if (info != null) delete info.thumbnail; // delete old thumbnail
		}
		if (saveForRevert) app.saveForRevert(data, false);
		app.extensionManager.clearImportedExtensions();
		decodeImagesAndInstall(newProject);
	}

	public function projectLoadFailed(ignore:* = null):void {
		app.removeLoadProgressBox();
		//DialogBox.notify('Error!', 'Project did not load.', app.stage);
		app.loadProjectFailed();
	}

	public function decodeImagesAndInstall(newProject:ScratchStage):void {
		function imagesDecoded():void { projectToInstall = newProject } // stepRuntime() will finish installation
		new ProjectIO(app).decodeAllImages(newProject.allObjects(), imagesDecoded);
	}

	protected function installProject(project:ScratchStage):void {
		if (app.stagePane != null) stopAll();
		if (app.scriptsPane) app.scriptsPane.viewScriptsFor(null);

		if(app.isIn3D) app.render3D.setStage(project, project.penLayer);

		for each (var obj:ScratchObj in project.allObjects()) {
			obj.showCostume(obj.currentCostumeIndex);
			if(Scratch.app.isIn3D) obj.updateCostume();
			var spr:ScratchSprite = obj as ScratchSprite;
			if (spr) spr.setDirection(spr.direction);
		}

		app.extensionManager.clearImportedExtensions();
		app.extensionManager.loadSavedExtensions(project.info.savedExtensions);
		app.installStage(project);
		app.updateSpriteLibrary(true);
		// set the active sprite
		var allSprites:Array = app.stagePane.sprites();
		if (allSprites.length > 0) {
			allSprites = allSprites.sortOn('indexInLibrary');
			app.selectSprite(allSprites[0]);
		} else {
			app.selectSprite(app.stagePane);
		}
		app.extensionManager.step();
		app.projectLoaded();
		checkForGraphicEffects();
	}

	public function checkForGraphicEffects():void {
		if(hasGraphicEffects()) app.go3D();
		else app.go2D();
	}

	// -----------------------------
	// Ask prompter
	//------------------------------

	public function showAskPrompt(question:String = ''):void {
		var p:AskPrompter = new AskPrompter(question, app);
		interp.askThread = interp.activeThread;
		p.x = 15;
		p.y = ScratchObj.STAGEH - p.height - 5;
		app.stagePane.addChild(p);
		setTimeout(p.grabKeyboardFocus, 100); // work-dround for Window keyboard event handling
	}

	public function hideAskPrompt(p:AskPrompter):void {
		interp.askThread = null;
		lastAnswer = p.answer();
		p.parent.removeChild(p);
		app.stage.focus = null;
	}

	public function askPromptShowing():Boolean {
		var uiLayer:Sprite = app.stagePane.getUILayer();
		for (var i:int = 0; i < uiLayer.numChildren; i++) {
			if (uiLayer.getChildAt(i) is AskPrompter)
				return true;
		}
		return false;
	}

	public function clearAskPrompts():void {
		interp.askThread = null;
		var allPrompts:Array = [];
		var uiLayer:Sprite = app.stagePane.getUILayer();
		var c:DisplayObject;
		for (var i:int = 0; i < uiLayer.numChildren; i++) {
			if ((c = uiLayer.getChildAt(i)) is AskPrompter) allPrompts.push(c);
		}
		for each (c in allPrompts) uiLayer.removeChild(c);
	}

	// -----------------------------
	// Keyboard input handling
	//------------------------------

	public function keyDown(evt:KeyboardEvent):void {
		shiftIsDown = evt.shiftKey;
		var ch:int = evt.charCode;
		if (evt.charCode == 0) ch = mapArrowKey(evt.keyCode);
		if ((65 <= ch) && (ch <= 90)) ch += 32; // map A-Z to a-z
		if (!(evt.target is TextField)) startKeyHats(ch);
		if (ch < 128) keyIsDown[ch] = true;
	}

	public function keyUp(evt:KeyboardEvent):void {
		shiftIsDown = evt.shiftKey;
		var ch:int = evt.charCode;
		if (evt.charCode == 0) ch = mapArrowKey(evt.keyCode);
		if ((65 <= ch) && (ch <= 90)) ch += 32; // map A-Z to a-z
		if (ch < 128) keyIsDown[ch] = false;
	}

	private function clearKeyDownArray():void {
		for (var i:int = 0; i < 128; i++) keyIsDown[i] = false;
	}

	private function mapArrowKey(keyCode:int):int {
		// map key codes for arrow keys to ASCII, other key codes to zero
		if (keyCode == 37) return 28;
		if (keyCode == 38) return 30;
		if (keyCode == 39) return 29;
		if (keyCode == 40) return 31;
		return 0;
	}

	// -----------------------------
	// Sensors
	//------------------------------

	public function getSensor(sensorName:String):Number {
		return app.extensionManager.getStateVar('PicoBoard', sensorName, 0);
	}

	public function getBooleanSensor(sensorName:String):Boolean {
		if (sensorName == 'button pressed') return app.extensionManager.getStateVar('PicoBoard', 'button', 1023) < 10;
		if (sensorName.indexOf('connected') > -1) { // 'A connected' etc.
			sensorName = 'resistance-' + sensorName.charAt(0);
			return app.extensionManager.getStateVar('PicoBoard', sensorName, 1023) < 10;
		}
		return false;
	}

	public function getTimeString(which:String):* {
		// Return local time properties.
		var now:Date = new Date();
		switch (which) {
		case 'hour': return now.hours;
		case 'minute': return now.minutes;
		case 'second': return now.seconds;
		case 'year': return now.fullYear; // four digit year (e.g. 2012)
		case 'month': return now.month + 1; // 1-12
		case 'date': return now.date; // 1-31
		case 'day of week': return now.day + 1; // 1-7, where 1 is Sunday
		}
		return ''; // shouldn't happen
	}

	// -----------------------------
	// Variables
	//------------------------------

	public function createVariable(varName:String):void {
		app.viewedObj().lookupOrCreateVar(varName);
	}

	public function deleteVariable(varName:String):void {
		var v:Variable = app.viewedObj().lookupVar(varName);

		if (app.viewedObj().ownsVar(varName)) {
			app.viewedObj().deleteVar(varName);
		} else {
			app.stageObj().deleteVar(varName);
		}
		clearAllCaches();
	}

	public function allVarNames():Array {
		var result:Array = [], v:Variable;
		for each (v in app.stageObj().variables) result.push(v.name);
		if (!app.viewedObj().isStage) {
			for each (v in app.viewedObj().variables) result.push(v.name);
		}
		return result;
	}

	public function renameVariable(oldName:String, newName:String, block:Block):void {
		var owner:ScratchObj = app.viewedObj();
		var v:Variable = owner.lookupVar(oldName);

		if (v != null) {
			if (!owner.ownsVar(v.name)) owner = app.stagePane;
			v.name = newName;
			if (v.watcher) v.watcher.changeVarName(newName);
		} else {
			owner.lookupOrCreateVar(newName);
		}
		updateVarRefs(oldName, newName, owner);
		clearAllCaches();
	}

	public function updateVariable(v:Variable):void {}
	public function makeVariable(varObj:Object):Variable { return new Variable(varObj.name, varObj.value); }
	public function makeListWatcher():ListWatcher { return new ListWatcher(); }

	private function updateVarRefs(oldName:String, newName:String, owner:ScratchObj):void {
		// Change the variable name in all blocks that use it.
		for each (var b:Block in allUsesOfVariable(oldName, owner)) {
			if (b.op == Specs.GET_VAR) {
				b.setSpec(newName);
				b.fixExpressionLayout();
			} else {
				b.args[0].setArgValue(newName);
			}
		}
	}

	// -----------------------------
	// Lists
	//------------------------------

	public function allListNames():Array {
		var result:Array = app.stageObj().listNames();
		if (!app.viewedObj().isStage) {
			result = result.concat(app.viewedObj().listNames());
		}
		return result;
	}

	public function deleteList(listName:String):void {
		if (app.viewedObj().ownsList(listName)) {
			app.viewedObj().deleteList(listName);
		} else {
			app.stageObj().deleteList(listName);
		}
		clearAllCaches();
	}

	// -----------------------------
	// Sensing
	//------------------------------

	public function timer():Number { return (interp.currentMSecs - timerBase) / 1000 }
	public function timerReset():void { timerBase = interp.currentMSecs }
	public function isLoud():Boolean { return soundLevel() > 10 }

	public function soundLevel():int {
		if (microphone == null) {
			microphone = Microphone.getMicrophone();
			if(microphone) {
				microphone.setLoopBack(true);
				microphone.soundTransform = new SoundTransform(0, 0);
			}
		}
		return microphone ? microphone.activityLevel : 0;
	}

	// -----------------------------
	// Script utilities
	//------------------------------

	public function renameCostume(newName:String):void {
		if (newName == app.viewedObj().currentCostume().costumeName) return;
		recordRenameCostume(newName);
		setCostumeName(newName);
	}

	private function setCostumeName(newName:String):void {
		var obj:ScratchObj = app.viewedObj();
		var costume:ScratchCostume = obj.currentCostume();
		var oldName:String = costume.costumeName;
		newName = obj.unusedCostumeName(newName || Translator.map('costume1'));
		costume.costumeName = newName;
		updateArgs(obj.isStage ? allUsesOfBackdrop(oldName) : allUsesOfCostume(oldName), newName);
	}

	public function renameSprite(newName:String):void {
		if (newName == app.viewedObj().objName) return;
		recordRenameSprite(newName);
		setSpriteName(newName);
	}

	private function setSpriteName(newName:String):void {
		var obj:ScratchObj = app.viewedObj();
		var oldName:String = obj.objName;
		obj.objName = '';
		newName = app.stagePane.unusedSpriteName(newName || 'Sprite1');
		obj.objName = newName;
		for each (var lw:ListWatcher in app.viewedObj().lists) {
			lw.updateTitle();
		}
		updateArgs(allUsesOfSprite(oldName), newName);
	}

	private function updateArgs(args:Array, newValue:*):void {
		for each (var a:BlockArg in args) {
			a.setArgValue(newValue);
		}
		app.setSaveNeeded();
	}

    public function renameSound(s:ScratchSound, newName:String):void {
		if (newName == s.soundName) return;
		recordRenameSound(s, newName);
		setSoundName(s, newName);
	}

	private function setSoundName(s:ScratchSound, newName:String):void {
        var obj:ScratchObj = app.viewedObj();
        var oldName:String = s.soundName;
        newName = obj.unusedSoundName(newName || Translator.map('sound1'));
        s.soundName = newName;
        allUsesOfSoundDo(oldName, function (a:BlockArg):void {
            a.setArgValue(newName);
        });
        app.setSaveNeeded();
    }

	public function clearRunFeedback():void {
		if(app.editMode) {
			for each (var stack:Block in allStacks()) {
				stack.allBlocksDo(function(b:Block):void {
					b.hideRunFeedback();
				});
			}
		}
		app.updatePalette();
	}

	public function allSendersOfBroadcast(msg:String):Array {
		// Return an array of all Scratch objects that broadcast the given message.
		var result:Array = [];
		for each (var o:ScratchObj in app.stagePane.allObjects()) {
			if (sendsBroadcast(o, msg)) result.push(o);
		}
		return result;
	}

	public function allReceiversOfBroadcast(msg:String):Array {
		// Return an array of all Scratch objects that receive the given message.
		var result:Array = [];
		for each (var o:ScratchObj in app.stagePane.allObjects()) {
			if (receivesBroadcast(o, msg)) result.push(o);
		}
		return result;
	}

	private function sendsBroadcast(obj:ScratchObj, msg:String):Boolean {
		for each (var stack:Block in obj.scripts) {
			var found:Boolean;
			stack.allBlocksDo(function (b:Block):void {
				if ((b.op == 'broadcast:') || (b.op == 'doBroadcastAndWait')) {
					if (b.args[0].argValue == msg) found = true;
				}
			});
			if (found) return true;
		}
		return false;
	}

	private function receivesBroadcast(obj:ScratchObj, msg:String):Boolean {
		msg = msg.toLowerCase();
		for each (var stack:Block in obj.scripts) {
			var found:Boolean;
			stack.allBlocksDo(function (b:Block):void {
				if (b.op == 'whenIReceive') {
					if (b.args[0].argValue.toLowerCase() == msg) found = true;
				}
			});
			if (found) return true;
		}
		return false;
	}

	public function allUsesOfBackdrop(backdropName:String):Array {
		var result:Array = [];
		allStacksAndOwnersDo(function (stack:Block, target:ScratchObj):void {
			stack.allBlocksDo(function (b:Block):void {
				for each (var a:BlockArg in b.args) {
					if (a.menuName == 'backdrop' && a.argValue == backdropName) result.push(a);
				}
			});
		});
		return result;
	}

	public function allUsesOfCostume(costumeName:String):Array {
		var result:Array = [];
		for each (var stack:Block in app.viewedObj().scripts) {
			stack.allBlocksDo(function (b:Block):void {
				for each (var a:BlockArg in b.args) {
					if (a.menuName == 'costume' && a.argValue == costumeName) result.push(a);
				}
			});
		}
		return result;
	}

	public function allUsesOfSprite(spriteName:String):Array {
		var spriteMenus:Array = ["spriteOnly", "spriteOrMouse", "spriteOrStage", "touching"];
		var result:Array = [];
		for each (var stack:Block in allStacks()) {
			// for each block in stack
			stack.allBlocksDo(function (b:Block):void {
				for each (var a:BlockArg in b.args) {
					if (spriteMenus.indexOf(a.menuName) != -1 && a.argValue == spriteName) result.push(a);
				}
			});
		}
		return result;
	}

	public function allUsesOfVariable(varName:String, owner:ScratchObj):Array {
		var variableBlocks:Array = [Specs.SET_VAR, Specs.CHANGE_VAR, "showVariable:", "hideVariable:"];
		var result:Array = [];
		var stacks:Array = owner.isStage ? allStacks() : owner.scripts;
		for each (var stack:Block in stacks) {
			// for each block in stack
			stack.allBlocksDo(function (b:Block):void {
				if (b.op == Specs.GET_VAR && b.spec == varName) result.push(b);
				if (variableBlocks.indexOf(b.op) != -1 && b.args[0].argValue == varName) result.push(b);
			});
		}
		return result;
	}

    public function allUsesOfSoundDo(soundName:String, f:Function):void {
        for each (var stack:Block in app.viewedObj().scripts) {
            stack.allBlocksDo(function (b:Block):void {
                for each (var a:BlockArg in b.args) {
                    if (a.menuName == 'sound' && a.argValue == soundName) f(a);
                }
            });
        }
    }

	public function allCallsOf(callee:String, owner:ScratchObj):Array {
		var result:Array = [];
		for each (var stack:Block in owner.scripts) {
			// for each block in stack
			stack.allBlocksDo(function (b:Block):void {
				if (b.op == Specs.CALL && b.spec == callee) result.push(b);
			});
		}
		return result;
	}

	public function updateCalls():void {
		allStacksAndOwnersDo(function (b:Block, target:ScratchObj):void {
			if (b.op == Specs.CALL) {
				if (target.lookupProcedure(b.spec) == null) {
					b.base.setColor(0xFF0000);
					b.base.redraw();
				}
				else b.base.setColor(Specs.procedureColor);
			}
		});
		clearAllCaches();
	}

	public function allStacks():Array {
		// return an array containing all stacks in all objects
		var result:Array = [];
		allStacksAndOwnersDo(
			function (stack:Block, target:ScratchObj):void { result.push(stack) });
		return result;
	}

	public function allStacksAndOwnersDo(f:Function):void {
		// Call the given function on every stack in the project, passing the stack and owning sprite/stage.
		// This method is used by broadcast, so enumerate sprites/stage from front to back to match Scratch.
		var stage:ScratchStage = app.stagePane;
		var stack:Block;
		for (var i:int = stage.numChildren - 1; i >= 0; i--) {
			var o:* = stage.getChildAt(i);
			if (o is ScratchObj) {
				for each (stack in ScratchObj(o).scripts) f(stack, o);
			}
		}
		for each (stack in stage.scripts) f(stack, stage);
	}

	public function clearAllCaches():void {
		for each (var obj:ScratchObj in app.stagePane.allObjects()) obj.clearCaches();
	}

	// -----------------------------
	// Variable, List, and Reporter Watchers
	//------------------------------

	public function showWatcher(data:Object, showFlag:Boolean):void {
		if ('variable' == data.type) {
			if (showFlag) showVarOrListFor(data.varName, data.isList, data.targetObj);
			else hideVarOrListFor(data.varName, data.isList, data.targetObj);
		}
		if ('reporter' == data.type) {
			var w:Watcher = findReporterWatcher(data);
			if (w) {
				w.visible = showFlag;
			} else {
				if (showFlag) {
					w = new Watcher();
					w.initWatcher(data.targetObj, data.cmd, data.param, data.color);
					showOnStage(w);
				}
			}
		}

		app.setSaveNeeded();
	}

	public function showVarOrListFor(varName:String, isList:Boolean, targetObj:ScratchObj):void {
		if (targetObj.isClone) {
			// Clone's can't show local variables/lists (but can show global ones)
			if (!isList && targetObj.ownsVar(varName)) return;
			if (isList && targetObj.ownsList(varName)) return;
		}
		var w:DisplayObject = isList ? watcherForList(targetObj, varName) : watcherForVar(targetObj, varName);
		if (w is ListWatcher) ListWatcher(w).prepareToShow();
		if (w != null) showOnStage(w);
		app.updatePalette(false);
	}

	private function showOnStage(w:DisplayObject):void {
		if (w.parent == null) setInitialPosition(w);
		w.visible = true;
		app.stagePane.addChild(w);
	}

	private function setInitialPosition(watcher:DisplayObject):void {
		var wList:Array = app.stagePane.watchers();
		var w:int = watcher.width;
		var h:int = watcher.height;
		var x:int = 5;
		while (x < 400) {
			var maxX:int = 0;
			var y:int = 5;
			while (y < 320) {
				var otherWatcher:DisplayObject = watcherIntersecting(wList, new Rectangle(x, y, w, h));
				if (!otherWatcher) {
					watcher.x = x;
					watcher.y = y;
					return;
				}
				y = otherWatcher.y + otherWatcher.height + 5;
				maxX = otherWatcher.x + otherWatcher.width;
			}
			x = maxX + 5;
		}
		// Couldn't find an unused place, so pick a random spot
		watcher.x = 5 + Math.floor(400 * Math.random());
		watcher.y = 5 + Math.floor(320 * Math.random());
	}

	private function watcherIntersecting(watchers:Array, r:Rectangle):DisplayObject {
		for each (var w:DisplayObject in watchers) {
			if (r.intersects(w.getBounds(app.stagePane))) return w;
		}
		return null;
	}

	public function hideVarOrListFor(varName:String, isList:Boolean, targetObj:ScratchObj):void {
		var w:DisplayObject = isList ? watcherForList(targetObj, varName) : watcherForVar(targetObj, varName);
		if (w != null) w.visible = false;
		app.updatePalette(false);
	}

	public function watcherShowing(data:Object):Boolean {
		if ('variable' == data.type) {
			var targetObj:ScratchObj = data.targetObj;
			var varName:String = data.varName;
			var uiLayer:Sprite = app.stagePane.getUILayer();
			var i:int;
			if(data.isList)
				for (i = 0; i < uiLayer.numChildren; i++) {
					var listW:ListWatcher = uiLayer.getChildAt(i) as ListWatcher;
					if (listW && (listW.listName == varName) && listW.visible) return true;
				}
			else
				for (i = 0; i < uiLayer.numChildren; i++) {
					var varW:Watcher = uiLayer.getChildAt(i) as Watcher;
					if (varW && varW.isVarWatcherFor(targetObj, varName) && varW.visible) return true;
				}
		}
		if ('reporter' == data.type) {
			var w:Watcher = findReporterWatcher(data);
			return w && w.visible;
		}
		return false;
	}

	private function findReporterWatcher(data:Object):Watcher {
		var uiLayer:Sprite = app.stagePane.getUILayer();
		for (var i:int = 0; i < uiLayer.numChildren; i++) {
			var w:Watcher = uiLayer.getChildAt(i) as Watcher;
			if (w && w.isReporterWatcher(data.targetObj, data.cmd, data.param)) return w;
		}
		return null;
	}

	private function watcherForVar(targetObj:ScratchObj, vName:String):DisplayObject {
		var v:Variable = targetObj.lookupVar(vName);
		if (v == null) return null; // variable is not defined
		if (v.watcher == null) {
			if (app.stagePane.ownsVar(vName)) targetObj = app.stagePane; // global
			var existing:Watcher = existingWatcherForVar(targetObj, vName);
			if (existing != null) {
				v.watcher = existing;
			} else {
				v.watcher = new Watcher();
				Watcher(v.watcher).initForVar(targetObj, vName);
			}
		}
		return v.watcher;
	}

	private function watcherForList(targetObj:ScratchObj, listName:String):DisplayObject {
		var w:ListWatcher;
		for each (w in targetObj.lists) {
			if (w.listName == listName) return w;
		}
		for each (w in app.stagePane.lists) {
			if (w.listName == listName) return w;
		}
		return null;
	}

	private function existingWatcherForVar(target:ScratchObj, vName:String):Watcher {
		var uiLayer:Sprite = app.stagePane.getUILayer();
		for (var i:int = 0; i < uiLayer.numChildren; i++) {
			var c:* = uiLayer.getChildAt(i);
			if ((c is Watcher) && (c.isVarWatcherFor(target, vName))) return c;
		}
		return null;
	}

	// -----------------------------
	// Undo support
	//------------------------------

	private var done:Array = [];
	private var undone:Array = [];

	public function canUndo():Boolean {
		return !!done.length && !app.gh.carriedObj;
	}
	public function canRedo():Boolean {
		return !!undone.length && !app.gh.carriedObj;
	}

	public function undoLabel():String {
		return actionListLabel('Undo', done);
	}
	public function redoLabel():String {
		return actionListLabel('Redo', undone);
	}
	private function actionListLabel(prefix:String, a:Array):String {
		var action:String = a.length ? getActionName(a[a.length - 1]) : '';
		return Translator.map(prefix) + ' ' + action;
	}

	public function undo():Boolean {
		if (!canUndo()) return false;
		var a:Array = done.pop();
		unperform(a);
		undone.push(a);
		return true;
	}

	public function redo():Boolean {
		if (!canRedo()) return false;
		var a:Array = undone.pop();
		perform(a);
		done.push(a);
		return true;
	}

	private static const DROP_BLOCK:int = 1;
	private static const REPLACE_ARG:int = 2;
	private static const INSERT_BLOCK:int = 3;
	private static const INSERT_BLOCK_ABOVE:int = 4;
	private static const INSERT_BLOCK_SUB1:int = 5;
	private static const INSERT_BLOCK_SUB2:int = 6;
	private static const INSERT_BLOCK_AROUND:int = 7;
	private static const DROP_INTO_THUMBNAIL:int = 8;
	private static const DELETE_BLOCK:int = 9;
	private static const CLEAN_UP:int = 10;
	private static const DELETE_SPRITE:int = 11;
	private static const ADD_SPRITE:int = 12;
	private static const CHANGE_INPUT:int = 13;
	private static const RENAME_SPRITE:int = 14;
	private static const RENAME_COSTUME:int = 15;
	private static const RENAME_SOUND:int = 16;
	private static const EDIT_SOUND:int = 17;
	private static const DELETE_COMMENT:int = 18;
	private static const ADD_COMMENT:int = 19;

	public function recordDropBlock(b:Block):void {
		recordAction([DROP_BLOCK, app.viewedObj(), b.parent, b, b.originalState, b.saveState()]);
	}
	public function recordReplaceArg(a:DisplayObject, b:Block):void {
		recordAction([REPLACE_ARG, app.viewedObj(), a.parent, a, b, Block(a.parent).argIndex(a), b.originalState]);
	}
	public function recordInsertBlock(t:Block, b:Block):void {
		recordAction([INSERT_BLOCK, app.viewedObj(), t, b, t.nextBlock, b.originalState]);
	}
	public function recordInsertBlockAbove(t:Block, b:Block):void {
		recordAction([INSERT_BLOCK_ABOVE, app.viewedObj(), t, b, t.saveState(), b.originalState]);
	}
	public function recordInsertBlockSub1(t:Block, b:Block):void {
		recordAction([INSERT_BLOCK_SUB1, app.viewedObj(), t, b, t.subStack1, b.originalState]);
	}
	public function recordInsertBlockSub2(t:Block, b:Block):void {
		recordAction([INSERT_BLOCK_SUB2, app.viewedObj(), t, b, t.subStack2, b.originalState]);
	}
	public function recordInsertBlockAround(t:Block, b:Block):void {
		recordAction([INSERT_BLOCK_AROUND, app.viewedObj(), t, b, t.saveState(), b.originalState]);
	}
	public function recordDropIntoThumbnail(t:ScratchObj, b:Block):void {
		recordAction([DROP_INTO_THUMBNAIL, t, b]);
	}
	public function recordDeleteBlock(b:Block, state:BlockState):void {
		if (state.role == Block.ROLE_NONE) return;
		recordAction([DELETE_BLOCK, app.viewedObj(), b, state]);
	}
	public function recordCleanUp():void {
		var obj:ScratchObj = app.viewedObj();
		var positions:Array = [];
		for each (var s:Block in obj.scripts) {
			positions.push([s, s.x, s.y]);
		}
		recordAction([CLEAN_UP, obj, positions]);
	}
	public function recordDeleteSprite(s:ScratchSprite):void {
		recordAction([DELETE_SPRITE, s, s.scratchX, s.scratchY]);
	}
	public function recordAddSprite(s:ScratchSprite):void {
		recordAction([ADD_SPRITE, s]);
	}
	public function recordChangeInput(i:BlockArg, old:String):void {
		if (old == i.field.text) return;
		recordAction([CHANGE_INPUT, app.viewedObj(), i, old, i.field.text]);
	}
	public function recordRenameSprite(name:String):void {
		var obj:ScratchObj = app.viewedObj();
		recordAction([RENAME_SPRITE, obj, obj.objName, name]);
	}
	public function recordRenameCostume(name:String):void {
		var obj:ScratchObj = app.viewedObj();
		var costume:ScratchCostume = obj.currentCostume();
		recordAction([RENAME_COSTUME, obj, costume, costume.costumeName, name]);
	}
	public function recordRenameSound(s:ScratchSound, name:String):void {
		var obj:ScratchObj = app.viewedObj();
		recordAction([RENAME_SOUND, obj, s, s.soundName, name]);
	}
	public function recordEditSound(s:ScratchSound, action:String, record:Array):void {
		var obj:ScratchObj = app.viewedObj();
		var d:Object = s.editorData;
		recordAction([EDIT_SOUND, obj, s, action, [d.samples, d.condensedSamples, d.samplesPerCondensedSample], record]);
	}
	public function recordDeleteComment(c:ScratchComment, x:Number, y:Number):void {
		recordAction([DELETE_COMMENT, app.viewedObj(), c, x, y]);
	}
	public function recordAddComment(c:ScratchComment):void {
		recordAction([ADD_COMMENT, app.viewedObj(), c, c.x, c.y, c.blockRef]);
	}

	private function recordAction(a:Array):void {
		done.push(a);
		undone.length = 0;
	}

	private static const scriptActions:Array = [DROP_BLOCK, REPLACE_ARG, INSERT_BLOCK, INSERT_BLOCK_ABOVE, INSERT_BLOCK_SUB1, INSERT_BLOCK_SUB2, INSERT_BLOCK_AROUND, DELETE_BLOCK, CLEAN_UP, CHANGE_INPUT, RENAME_SPRITE, DELETE_COMMENT, ADD_COMMENT];
	private function unperform(a:Array):void {
		selectSpriteForAction(a);
		switch (a[0]) {
		case DROP_BLOCK:
			removeBlock(a[3]);
			a[3].restoreState(a[4]);
			break;
		case REPLACE_ARG:
			a[2].replaceArg(a[5], a[3]);
			a[4].restoreState(a[6]);
			break;
		case INSERT_BLOCK:
			removeBlock(a[3]);
			if (a[4]) {
				removeBlock(a[4]);
				a[2].insertBlock(a[4]);
			}
			a[3].restoreState(a[5]);
			break;
		case INSERT_BLOCK_ABOVE:
			removeBlock(a[2]);
			removeBlock(a[3]);
			a[2].restoreState(a[4]);
			a[3].restoreState(a[5]);
			break;
		case INSERT_BLOCK_SUB1:
			removeBlock(a[3]);
			if (a[4]) {
				removeBlock(a[4]);
				a[2].insertBlockSub1(a[4]);
			}
			a[3].restoreState(a[5]);
			break;
		case INSERT_BLOCK_SUB2:
			removeBlock(a[3]);
			if (a[4]) {
				removeBlock(a[4]);
				a[2].insertBlockSub2(a[4]);
			}
			a[3].restoreState(a[5]);
			break;
		case INSERT_BLOCK_AROUND:
			removeBlock(a[2]);
			removeBlock(a[3]);
			a[2].restoreState(a[4]);
			a[3].restoreState(a[5]);
			break;
		case DROP_INTO_THUMBNAIL:
			selectSpriteIfNeeded(a[1]);
			selectTabIfNeeded('scripts');
			if (a[2].parent) a[2].parent.removeChild(a[2]);
			break;
		case DELETE_BLOCK:
			a[2].restoreState(a[3]);
			break;
		case CLEAN_UP:
			for each (var s:Array in a[2]) {
				s[0].x = s[1];
				s[0].y = s[2];
			}
			break;
		case DELETE_SPRITE:
			app.addSprite(a[1]);
			a[1].setScratchXY(a[2], a[3]);
			break;
		case ADD_SPRITE:
			a[1].deleteSprite();
			break;
		case CHANGE_INPUT:
			a[2].setArgValue(a[3]);
			break;
		case RENAME_SPRITE:
			selectSpriteIfNeeded(a[1]);
			setSpriteName(a[2]);
			app.libraryPart.refresh();
			break;
		case RENAME_COSTUME:
			selectSpriteIfNeeded(a[1]);
			selectTabIfNeeded('images');
			a[1].currentCostumeIndex = a[1].costumes.indexOf(a[2]);
			setCostumeName(a[3]);
			app.imagesPart.refresh();
			break;
		case RENAME_SOUND:
			selectSpriteIfNeeded(a[1]);
			selectTabIfNeeded('sounds');
			setSoundName(a[2], a[3]);
			app.soundsPart.selectSound(a[2]);
			break;
		case EDIT_SOUND:
			selectSpriteIfNeeded(a[1]);
			selectTabIfNeeded('sounds');
			app.soundsPart.selectSound(a[2]);
			app.soundsPart.editor.waveform.installUndoRecord(a[4]);
			break;
		case DELETE_COMMENT:
			app.scriptsPane.addChild(a[2]);
			a[2].x = a[3];
			a[2].y = a[4];
			break;
		case ADD_COMMENT:
			app.scriptsPane.removeChild(a[2]);
			break;
		}
	}

	private function perform(a:Array):void {
		selectSpriteForAction(a);
		switch (a[0]) {
		case DROP_BLOCK:
			removeBlock(a[3]);
			a[3].restoreState(a[5]);
			break;
		case REPLACE_ARG:
			removeBlock(a[4]);
			a[2].replaceArgWithBlock(a[3], a[4], app.scriptsPane);
			break;
		case INSERT_BLOCK:
			removeBlock(a[3]);
			a[2].insertBlock(a[3]);
			break;
		case INSERT_BLOCK_ABOVE:
			removeBlock(a[3]);
			a[2].insertBlockAbove(a[3]);
			break;
		case INSERT_BLOCK_SUB1:
			removeBlock(a[3]);
			a[2].insertBlockSub1(a[3]);
			break;
		case INSERT_BLOCK_SUB2:
			removeBlock(a[3]);
			a[2].insertBlockSub2(a[3]);
			break;
		case INSERT_BLOCK_AROUND:
			removeBlock(a[3]);
			a[2].insertBlockAround(a[3]);
			break;
		case DROP_INTO_THUMBNAIL:
			selectSpriteIfNeeded(a[1]);
			selectTabIfNeeded('scripts');
			a[2].x = app.scriptsPane.padding;
			a[2].y = app.scriptsPane.padding;
			app.scriptsPane.addChild(a[2]);
			break;
		case DELETE_BLOCK:
			removeBlock(a[2]);
			if (a[2].parent) a[2].parent.removeChild(a[2]);
			break;
		case CLEAN_UP:
			app.scriptsPane.cleanup();
			break;
		case DELETE_SPRITE:
			a[1].deleteSprite();
			break;
		case ADD_SPRITE:
			app.addSprite(a[1]);
			break;
		case CHANGE_INPUT:
			a[2].setArgValue(a[4]);
			break;
		case RENAME_SPRITE:
			selectSpriteIfNeeded(a[1]);
			setSpriteName(a[3]);
			app.libraryPart.refresh();
			break;
		case RENAME_COSTUME:
			selectSpriteIfNeeded(a[1]);
			selectTabIfNeeded('images');
			a[1].currentCostumeIndex = a[1].costumes.indexOf(a[2]);
			setCostumeName(a[4]);
			app.imagesPart.refresh();
			break;
		case RENAME_SOUND:
			selectSpriteIfNeeded(a[1]);
			selectTabIfNeeded('sounds');
			setSoundName(a[2], a[4]);
			app.soundsPart.selectSound(a[2]);
			break;
		case EDIT_SOUND:
			selectSpriteIfNeeded(a[1]);
			selectTabIfNeeded('sounds');
			app.soundsPart.selectSound(a[2]);
			app.soundsPart.editor.waveform.installUndoRecord(a[5]);
			break;
		case DELETE_COMMENT:
			if (a[2].parent) a[2].parent.removeChild(a[2]);
			break;
		case ADD_COMMENT:
			app.scriptsPane.addChild(a[2]);
			a[2].x = a[3];
			a[2].y = a[4];
			a[2].blockRef = a[5];
			break;
		}
	}

	public function getActionName(a:Array):String {
		switch (a[0]) {
		case DROP_BLOCK:
		case REPLACE_ARG:
		case INSERT_BLOCK:
		case INSERT_BLOCK_ABOVE:
		case INSERT_BLOCK_SUB1:
		case INSERT_BLOCK_SUB2:
		case INSERT_BLOCK_AROUND: return Translator.map('drop block');
		case DROP_INTO_THUMBNAIL: return Translator.map('copy block');
		case DELETE_BLOCK: return Translator.map('delete block');
		case DELETE_SPRITE: return Translator.map('delete sprite');
		case CLEAN_UP: return Translator.map('clean up');
		case ADD_SPRITE: return Translator.map('add sprite');
		case CHANGE_INPUT: return Translator.map('change input');
		case RENAME_SPRITE: return Translator.map('rename sprite');
		case RENAME_COSTUME: return a[1].isStage ? Translator.map('rename backdrop') : Translator.map('rename costume');
		case RENAME_SOUND: return Translator.map('rename sound');
		case EDIT_SOUND: return Translator.map(a[3]);
		case DELETE_COMMENT: return Translator.map('delete comment');
		case ADD_COMMENT: return Translator.map('add comment');
		}
		return '';
	}

	private function selectSpriteForAction(a:Array):void {
		if (scriptActions.indexOf(a[0]) != -1) {
			selectSpriteIfNeeded(a[1]);
			selectTabIfNeeded('scripts');
		}
	}

	private function selectSpriteIfNeeded(s:ScratchObj):void {
		if (app.viewedObj() != s) {
			app.selectSprite(s);
		}
	}

	private function selectTabIfNeeded(t:String):void {
		if (app.lastTab != t) {
			app.setTab(t);
		}
	}

	private function removeBlock(b:Block):void {
		if (b.parent is Block) Block(b.parent).removeBlock(b);
	}

}}
