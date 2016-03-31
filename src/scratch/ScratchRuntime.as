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
import assets.Resources;

import blocks.Block;
import blocks.BlockArg;

import extensions.ExtensionManager;

import flash.display.*;
import flash.events.*;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.media.*;
import flash.net.*;
import flash.system.System;
import flash.text.TextField;
import flash.utils.*;

import interpreter.*;

import leelib.util.flvEncoder.*;

import logging.LogLevel;

import primitives.VideoMotionPrims;

import sound.ScratchSoundPlayer;

import translation.*;

import ui.BlockPalette;
import ui.RecordingSpecEditor;
import ui.SharingSpecEditor;
import ui.media.MediaInfo;

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
	public var currentDoObj:ScratchObj = null;

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
		if (projectToInstall != null && (app.isOffline || app.isExtensionDevMode)) {
			installProject(projectToInstall);
			if (saveAfterInstall) app.setSaveNeeded(true);
			projectToInstall = null;
			saveAfterInstall = false;
			return;
		}
		if (ready==ReadyLabel.COUNTDOWN) {
			var tR:Number = getTimer()*.001-videoSeconds;
			while (t>videoSounds.length/videoFramerate+1/videoFramerate) {
				saveSound();
			}
			var count:int = 3;
			if (tR>=3.75){
				ready = ReadyLabel.READY;
				count = 1;
				videoSounds = [];
				videoFrames=[];
				if (fullEditor) Scratch.app.log(LogLevel.TRACK, "Editor video started",{projectID: app.projectID});
				else Scratch.app.log(LogLevel.TRACK, "Project video started",{projectID: app.projectID});
			}
			else if (tR>=2.5){
				count=1
			}
			else if (tR>=1.25 && micReady) {
				count=2;
			}
			else if (tR>=1.25) {
				videoSeconds+=tR;
			}
			else {
				app.refreshStagePart();
			}
		}
		if (recording) { // Recording a YouTube video?
			var t:Number = getTimer()*.001-videoSeconds;
			//If, based on time and framerate, the current frame needs to be in the video, capture the frame.
			//Will always be true if framerate is 30, as every frame is captured.
			if (t>videoSounds.length/videoFramerate+1/videoFramerate) {
				if (fullEditor) app.removeRecordingTools();
				//saves visual frame to frames and sound clip to sounds
				saveFrame();
				app.updateRecordingTools(t);
			}
			else {
				//Will only run in low quality or full editor mode, when this frame isn't captured for video
				//To reduce lag in low quality mode and full editor mode, video frames are only written
				//to the file if a new frame isn't being captured and the total number of frames captured so far
				//is divisible by 2 or 3.
				//Some frames will be written to the file after recording has finished.
				app.updateRecordingTools(t);
				if (videoFrames.length>videoPosition && (videoFrames.length%2==0 || videoFrames.length%3==0)) {
					baFlvEncoder.addFrame(videoFrames[videoPosition],videoSounds[videoPosition]);
					//forget about frame just written
					videoFrames[videoPosition]=null;
					videoSounds[videoPosition]=null;
					videoPosition++;
				}
			}
			//For a high quality video, every frame is immediately written to the video file
			//after being captured, to reduce memory.
			if (videoFrames.length>videoPosition && videoFramerate==30.0) {
				baFlvEncoder.addFrame(videoFrames[videoPosition],videoSounds[videoPosition]);
				//forget about frame just written
				videoFrames[videoPosition]=null;
				videoSounds[videoPosition]=null;
				videoPosition++;
			}
		}
		app.extensionManager.step();
		if (motionDetector) motionDetector.step(); // Video motion detection

		// Step the stage, sprites, and watchers
		app.stagePane.step(this);

		// run scripts and commit any pen strokes
		processEdgeTriggeredHats();
		interp.stepThreads();
		app.stagePane.commitPenStrokes();
		
		if (ready==ReadyLabel.COUNTDOWN || ready==ReadyLabel.READY) {
			app.stagePane.countdown(count);
		}
	}

//-------- recording video code ---------
	public var recording:Boolean;
	private var videoFrames:Array = [];
	private var videoSounds:Array = [];
	private var videoTimer:Timer;
	private var baFlvEncoder:ByteArrayFlvEncoder;
	private var videoPosition:int;
	private var videoSeconds:Number;
	private var videoAlreadyDone:int;
	
	private var projectSound:Boolean;
	private var micSound:Boolean;
	private var showCursor:Boolean;
	public var fullEditor:Boolean;
	private var videoFramerate:Number;
	private var videoWidth:int;
	private var videoHeight:int;
	public var ready:int=ReadyLabel.NOT_READY;
	
	private var micBytes:ByteArray;
	private var micPosition:int = 0;
	private var mic:Microphone;
	private var micReady:Boolean;
	
	private var timeout:int;
	
	private function saveFrame():void {
		saveSound();
		var t:Number = getTimer()*.001-videoSeconds;
		while (t>videoSounds.length/videoFramerate+1/videoFramerate) {
			saveSound();
		}
		if (showCursor) var cursor:DisplayObject = Resources.createDO('videoCursor');
		if (showCursor && app.gh.mouseIsDown) var circle:Bitmap = Resources.createBmp('mouseCircle');
		var f:BitmapData;
		if (fullEditor) {
			var aWidth:int = app.stage.stageWidth;
			var aHeight:int = app.stage.stageHeight;
			if (!Scratch.app.isIn3D) {
				if (app.stagePane.videoImage) app.stagePane.videoImage.visible = false;
			}
			if (videoWidth!=aWidth || videoHeight!=aHeight) {
				var scale:Number = 1.0;
				scale = videoWidth/aWidth > videoHeight/aHeight ? videoHeight/aHeight : videoWidth/aWidth;
				var m:Matrix = new Matrix();
				m.scale(scale,scale);
				f = new BitmapData(videoWidth,videoHeight,false);
				f.draw(app.stage,m,null, null, new Rectangle(0,0,aWidth*scale,aHeight*scale),false);
				if(Scratch.app.isIn3D) {
					var scaled:Number = scale;
					if (!app.editMode) {
						scaled *= app.presentationScale;
					}
					else if (app.stageIsContracted) {
						scaled*=0.5;
					}
					var d:BitmapData = app.stagePane.saveScreenData();
					f.draw(d, new Matrix( scaled, 0, 0, scaled, app.stagePane.localToGlobal(new Point(0, 0)).x*scale, app.stagePane.localToGlobal(new Point(0, 0)).y*scale));
				}
				else if (app.stagePane.videoImage) app.stagePane.videoImage.visible = true;
				if (showCursor && app.gh.mouseIsDown) {
					f.draw(circle,new Matrix(scale,0,0,scale,(app.stage.mouseX-circle.width/2.0)*scale,(app.stage.mouseY-circle.height/2.0)*scale));
				}
				if (showCursor) {
					f.draw(cursor,new Matrix(scale,0,0,scale,app.stage.mouseX*scale,app.stage.mouseY*scale));
				}
			}
			else {
				f = new BitmapData(videoWidth,videoHeight,false);
				f.draw(app.stage);
				if(Scratch.app.isIn3D) {
					var scaler:Number = 1;
					if (!app.editMode) {
						scaler *= app.presentationScale;
					}
					else if (app.stageIsContracted) {
						scaler*=0.5;
					}
					var e:BitmapData = app.stagePane.saveScreenData();
					if (scaler==1) f.copyPixels(e, e.rect,new Point(app.stagePane.localToGlobal(new Point(0, 0)).x, app.stagePane.localToGlobal(new Point(0, 0)).y));
					else f.draw(e, new Matrix( scaler, 0, 0, scaler, app.stagePane.localToGlobal(new Point(0, 0)).x, app.stagePane.localToGlobal(new Point(0, 0)).y));
				}
				else if (app.stagePane.videoImage) app.stagePane.videoImage.visible = true;
				if (showCursor && app.gh.mouseIsDown) {
					f.copyPixels(circle.bitmapData,circle.bitmapData.rect,new Point(app.stage.mouseX-circle.width/2.0,app.stage.mouseY-circle.height/2.0));
				}
				if (showCursor) {
					f.draw(cursor,new Matrix(1,0,0,1,app.stage.mouseX,app.stage.mouseY));
				}
			}
		}
		else {
			f = app.stagePane.saveScreenData();
			if (showCursor && app.gh.mouseIsDown) {
				f.copyPixels(circle.bitmapData,circle.bitmapData.rect,new Point(app.stagePane.mouseX-circle.width/2.0,app.stagePane.mouseY-circle.height/2.0));
			}
			if (showCursor) {
				f.draw(cursor,new Matrix(1,0,0,1,app.stagePane.scratchMouseX()+240,-app.stagePane.scratchMouseY()+180));
			}
		}
		while (videoSounds.length>videoFrames.length) {
			videoFrames.push(f);
		}
	}
	
	private function saveSound():void {
		var floats:Array = [];
		if (micSound && micBytes.length>0) {
			micBytes.position=micPosition;
			while (micBytes.length>micBytes.position && floats.length<=baFlvEncoder.audioFrameSize/4) {
				floats.push(micBytes.readFloat());
			}
			micPosition = micBytes.position;
			micBytes.position = micBytes.length;
		}
		while (floats.length<=baFlvEncoder.audioFrameSize/4) {
			floats.push(0);
		}
		if (projectSound) {
			for (var p:int = 0; p<ScratchSoundPlayer.activeSounds.length; p++) {
				var index:int = 0;
				var d:ScratchSoundPlayer = ScratchSoundPlayer.activeSounds[p];
				d.dataBytes.position = d.readPosition;
				while (index<floats.length && d.dataBytes.position<d.dataBytes.length) {
					floats[index]+=d.dataBytes.readFloat();
					if (p==ScratchSoundPlayer.activeSounds.length-1) {
						if (floats[index]<-1 || floats[index]>1) {
							var current1:int = p+1+int(micSound);
							floats[index]=floats[index]/current1;
						}
					}
					index++;
				}
				d.readPosition=d.dataBytes.position;
				d.dataBytes.position=d.dataBytes.length;
			}
		}
		var combinedStream:ByteArray = new ByteArray();
		for each (var n:Number in floats) {
			combinedStream.writeFloat(n);
		}
		floats = null;
		videoSounds.push(combinedStream);
		combinedStream = null;
	}
	
	private function micSampleDataHandler(event:SampleDataEvent):void 
	{ 
	    while(event.data.bytesAvailable) 
	    {
	        var sample:Number = event.data.readFloat(); 
	        micBytes.writeFloat(sample);  
	        micBytes.writeFloat(sample);
	    } 
	} 
	
	public function startVideo(editor:RecordingSpecEditor):void {
		projectSound = editor.soundFlag();
		micSound = editor.microphoneFlag();
		fullEditor = editor.editorFlag();
		showCursor = editor.cursorFlag();
		videoFramerate = (!editor.fifteenFlag()) ? 15.0 : 30.0;
		if (fullEditor) {
			videoFramerate=10.0;
		}
		micReady = true;
		if (micSound) {
			mic = Microphone.getMicrophone(); 
			mic.setSilenceLevel(0);
			mic.gain = editor.getMicVolume(); 
			mic.rate = 44; 
			micReady=false;
		}
		if (fullEditor) {
			if (app.stage.stageWidth<960 && app.stage.stageHeight<640) {
				videoWidth = app.stage.stageWidth;
				videoHeight = app.stage.stageHeight;
			}
			else {
				var ratio:Number = app.stage.stageWidth/app.stage.stageHeight;
				if (960/ratio<640) {
					videoWidth = 960;
					videoHeight = 960/ratio;
				}
				else {
					videoWidth = 640*ratio;
					videoHeight = 640;
				}
			}
		}
		else {
			videoWidth = 480;
			videoHeight = 360;
		}
		ready=ReadyLabel.COUNTDOWN;
		videoSeconds = getTimer()*.001;
		baFlvEncoder = new ByteArrayFlvEncoder(videoFramerate);
		baFlvEncoder.setVideoProperties(videoWidth, videoHeight);
		baFlvEncoder.setAudioProperties(FlvEncoder.SAMPLERATE_44KHZ, true, true, true);
		baFlvEncoder.start();
		waitAndStart();
	}
	
	public function exportToVideo():void {
		var specEditor:RecordingSpecEditor = new RecordingSpecEditor();
		function startCountdown():void {
			startVideo(specEditor);
		}
		DialogBox.close("Record Project Video",null,specEditor,"Start",app.stage,startCountdown);
	}
	
	public function stopVideo():void {
		if (recording) videoTimer.dispatchEvent(new TimerEvent(TimerEvent.TIMER));
		else if (ready==ReadyLabel.COUNTDOWN || ReadyLabel.READY) {
			ready=ReadyLabel.NOT_READY;
			app.refreshStagePart();
			app.stagePane.countdown(0);
		}
	}
	
	public function finishVideoExport(event:TimerEvent):void {
		stopRecording();
		stopAll();
		app.addLoadProgressBox("Writing video to file...");
		videoAlreadyDone = videoPosition;
		clearTimeout(timeout);
		timeout = setTimeout(saveRecording,1);
	}
	
	public function waitAndStart():void {
		if (!micReady && !mic.hasEventListener(StatusEvent.STATUS)) {
			micBytes = new ByteArray();
			mic.addEventListener(SampleDataEvent.SAMPLE_DATA, micSampleDataHandler);
			micReady=true;
		}
		if (ready==ReadyLabel.COUNTDOWN || ready==ReadyLabel.NOT_READY) {
			if (ready==ReadyLabel.NOT_READY) {
				baFlvEncoder=null;
				return;
			}
			clearTimeout(timeout);
			timeout = setTimeout(waitAndStart, 1);
			return;
		}
		app.stagePane.countdown(0);
		ready=ReadyLabel.NOT_READY;
		app.refreshStagePart();
		var player:ScratchSoundPlayer, length:int;
		videoSeconds = getTimer() * 0.001;
		for each (player in ScratchSoundPlayer.activeSounds) {
			length = int((player.soundChannel.position*.001)*videoFramerate);
			player.readPosition = Math.max(Math.min(baFlvEncoder.audioFrameSize*length,player.dataBytes.length),0);
		}
		clearRecording();
		recording = true;
		var seconds:int = 60; //modify to change length of video
		videoTimer = new Timer(1000*seconds,1);
    	videoTimer.addEventListener(TimerEvent.TIMER, finishVideoExport);
    	videoTimer.start();
	}
	
	public function stopRecording():void {
		recording = false;
		videoTimer.stop();
    	videoTimer.removeEventListener(TimerEvent.TIMER, finishVideoExport);
		videoTimer = null;
		//if (fullEditor && app.render3D) app.go3D();
		app.refreshStagePart();
	}

	public function clearRecording():void {
		recording = false;
		videoFrames = [];
		videoSounds = [];
		micBytes = new ByteArray();
		micPosition=0;
		videoPosition=0;
		System.gc();
		ready=ReadyLabel.NOT_READY;
		trace('mem: ' + System.totalMemory);
	}

	public function saveRecording():void {
		//any captured frames that haven't been written to file yet are written here
		if (videoFrames.length>videoPosition) {
			for (var b:int=0; b<20; b++) {
				if (videoPosition>=videoFrames.length) {
					break;
				}
				baFlvEncoder.addFrame(videoFrames[videoPosition],videoSounds[videoPosition]);
				videoFrames[videoPosition]=null;
				videoSounds[videoPosition]=null;
				videoPosition++;
			}
			if (app.lp) app.lp.setProgress(Math.min((videoPosition-videoAlreadyDone) / (videoFrames.length-videoAlreadyDone), 1)); 
			clearTimeout(timeout);
			timeout = setTimeout(saveRecording, 1);
			return;
		}
		var seconds:Number = videoFrames.length/videoFramerate;
		app.removeLoadProgressBox();
		baFlvEncoder.updateDurationMetadata();
		if (micSound) {
			mic.removeEventListener(SampleDataEvent.SAMPLE_DATA, micSampleDataHandler);
			mic = null;
		}
		videoFrames = [];
		videoSounds = [];
		micBytes = null;
		micPosition=0;
		var video:ByteArray;
		video = baFlvEncoder.byteArray;
		baFlvEncoder.kill();
		function saveFile():void {
			var file:FileReference = new FileReference();
			file.save(video, "movie.flv");
			Scratch.app.log(LogLevel.TRACK, "Video downloaded", {projectID: app.projectID, seconds: roundToTens(seconds), megabytes: roundToTens(video.length/1000000)});
			var specEditor:SharingSpecEditor = new SharingSpecEditor();
			DialogBox.close("Playing and Sharing Your Video",null,specEditor,"Back to Scratch");
		    releaseVideo(false);
        }
		function releaseVideo(log:Boolean = true):void {
			if (log) Scratch.app.log(LogLevel.TRACK, "Video canceled", {projectID: app.projectID, seconds: roundToTens(seconds), megabytes: roundToTens(video.length/1000000)});
            video = null;
		}
		DialogBox.close("Video Finished!","To save, click the button below.",null,"Save and Download",app.stage,saveFile,releaseVideo,null,true);
	}
	
	private function roundToTens(x:Number):Number {
		return int((x)*10)/10.;
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

	public function startKeyHats(ch:int):void {
		var keyName:String = null;
		if (('a'.charCodeAt(0) <= ch) && (ch <= 'z'.charCodeAt(0))) keyName = String.fromCharCode(ch);
		if (('0'.charCodeAt(0) <= ch) && (ch <= '9'.charCodeAt(0))) keyName = String.fromCharCode(ch);
		if (28 == ch) keyName = 'left arrow';
		if (29 == ch) keyName = 'right arrow';
		if (30 == ch) keyName = 'up arrow';
		if (31 == ch) keyName = 'down arrow';
		if (32 == ch) keyName = 'space';
		function startMatchingKeyHats(stack:Block, target:ScratchObj):void {
			if (stack.op == 'whenKeyPressed') {
				var k:String = stack.args[0].argValue;
				if (k == 'any' || k == keyName) {
					// only start the stack if it is not already running
					if (!interp.isRunning(stack, target)) interp.toggleThread(stack, target);
				}
			}
		}
		allStacksAndOwnersDo(startMatchingKeyHats);
	}

	// Returns a sorted array of all messages in use, or a single-element array containing the default message name.
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
		if (result.length > 0) {
			result.sort();
			return result;
		}
		return [Translator.map('message1')];
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
		var extName:String = ExtensionManager.unpackExtensionName(b.op);
		return extName && !app.extensionManager.isInternal(extName);
	}

	SCRATCH::allow3d
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

	SCRATCH::allow3d
	private function isGraphicEffectBlock(b:Block):Boolean {
		return ('op' in b && (b.op == 'changeGraphicEffect:by:' || b.op == 'setGraphicEffect:to:') &&
		('argValue' in b.args[0]) && b.args[0].argValue != 'ghost' && b.args[0].argValue != 'brightness');
	}

	// -----------------------------
	// Edge-trigger sensor hats
	//------------------------------

	protected var triggeredHats:Array = [];

	private function clearEdgeTriggeredHats():void { edgeTriggersEnabled = true; triggeredHats = [] }

	// hats whose triggering condition is currently true
	protected var activeHats:Array = [];
	protected var waitingHats:Array = []
	protected function startEdgeTriggeredHats(hat:Block, target:ScratchObj):void {
		if (!hat.isHat || !hat.nextBlock) return; // skip disconnected hats

		if ('whenSensorGreaterThan' == hat.op) {
			var sensorName:String = interp.arg(hat, 0);
			var threshold:Number = interp.numarg(hat, 1);
			if (('loudness' == sensorName && soundLevel() > threshold) ||
					('timer' == sensorName && timer() > threshold) ||
					('video motion' == sensorName && target.visible && VideoMotionPrims.readMotionSensor('motion', target) > threshold)) {
				if (triggeredHats.indexOf(hat) == -1) { // not already trigged
					// only start the stack if it is not already running
					if (!interp.isRunning(hat, target)) interp.toggleThread(hat, target);
				}
				activeHats.push(hat);
			}
		} else if ('whenSensorConnected' == hat.op) {
			if (getBooleanSensor(interp.arg(hat, 0))) {
				if (triggeredHats.indexOf(hat) == -1) { // not already trigged
					// only start the stack if it is not already running
					if (!interp.isRunning(hat, target)) interp.toggleThread(hat, target);
				}
				activeHats.push(hat);
			}
		} else if (app.jsEnabled) {
			var unpackedOp:Array = ExtensionManager.unpackExtensionAndOp(hat.op);
			var extName:String = unpackedOp[0];
			if (extName && app.extensionManager.extensionActive(extName)) {
				var op:String = unpackedOp[1];
				var numArgs:uint = hat.args.length;
				var finalArgs:Array = new Array(numArgs);
				for (var i:uint = 0; i < numArgs; ++i)
					finalArgs[i] = interp.arg(hat, i);

				processExtensionReporter(hat, target, extName, op, finalArgs);
			}
		}
	}

	private function processExtensionReporter(hat:Block, target:ScratchObj, extName:String, op:String, finalArgs:Array):void {
		// TODO: Is it safe to do this in a callback, or must it happen before we return from startEdgeTriggeredHats?
		function triggerHatBlock(triggerCondition:Boolean):void {
			if (triggerCondition) {
				if (triggeredHats.indexOf(hat) == -1) { // not already trigged
					// only start the stack if it is not already running

					if (!interp.isRunning(hat, target)) interp.toggleThread(hat, target);
				}
				activeHats.push(hat);
			}
		}
		if(!hat.isAsyncHat){
			app.externalCall('ScratchExtensions.getReporter', triggerHatBlock, extName, op, finalArgs);
		}
		else{
			//Tell the block to wait like a reporter, fire if true
			if(hat.requestState == 0){
				if(!interp.isRunning(hat, target)){
					interp.toggleThread(hat, target, 0, true);
				}
			}
			if(triggeredHats.indexOf(hat) >= 0){
				activeHats.push(hat);
			}
		}
	}

	public function waitingHatFired(hat:Block, willExec:Boolean):Boolean{
		if(willExec){
			if(activeHats.indexOf(hat) < 0){
				hat.showRunFeedback();
				if(hat.forceAsync){
					activeHats.push(hat);
				}
				return true;
			}
		}
		else{
			activeHats.splice(activeHats.indexOf(hat), 1);
			triggeredHats.splice(triggeredHats.indexOf(hat), 1);
		}
		return false;
	}

	private function processEdgeTriggeredHats():void {
		if (!edgeTriggersEnabled) return;
		activeHats = [];
		allStacksAndOwnersDo(startEdgeTriggeredHats,true);
		triggeredHats = activeHats;
	}

	public function blockDropped(stack:Block):void {
		// Turn on video the first time a video sensor reporter or hat block is added.
		stack.allBlocksDo(function(b:Block):void {
			var op:String = b.op;
			if (op == Specs.GET_PARAM) b.parameterIndex = -1;  // need to invalidate index cache
			if (('senseVideoMotion' == op) ||
					(('whenSensorGreaterThan' == op) && ('video motion' == interp.arg(b, 0)))) {
				app.libraryPart.showVideoButton();
			}

			SCRATCH::allow3d {
				// Should we go 3D?
				if(isGraphicEffectBlock(b))
					app.go3D();
			}
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
		function fileLoadHandler(event:Event):void {
			var file:FileReference = FileReference(event.target);
			fileName = file.name;
			data = file.data;
			if (app.stagePane.isEmpty()) doInstall();
			else DialogBox.confirm('Replace contents of the current project?', app.stage, doInstall);
		}
		function doInstall(ignore:* = null):void {
			installProjectFromFile(fileName, data);
		}
		stopAll();

		var filter:FileFilter;
		if (Scratch.app.isExtensionDevMode) {
			filter = new FileFilter('ScratchX Project', '*.sbx;*.sb;*.sb2');
		}
		else {
			filter = new FileFilter('Scratch Project', '*.sb;*.sb2');
		}
		Scratch.loadSingleFile(fileLoadHandler, filter);
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
		if (data.length < 8 || data.readUTFBytes(8) != 'ScratchV') {
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

		SCRATCH::allow3d { if(app.isIn3D) app.render3D.setStage(project, project.penLayer); }

		for each (var obj:ScratchObj in project.allObjects()) {
			obj.showCostume(obj.currentCostumeIndex);
			if(Scratch.app.isIn3D) obj.updateCostume();
			var spr:ScratchSprite = obj as ScratchSprite;
			if (spr) spr.setDirection(spr.direction);
		}

		app.resetPlugin(function():void {
			app.extensionManager.clearImportedExtensions();
			app.extensionManager.loadSavedExtensions(project.info.savedExtensions);
		});
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
		SCRATCH::allow3d { checkForGraphicEffects(); }
	}

	SCRATCH::allow3d
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
		setTimeout(p.grabKeyboardFocus, 100); // workaround for Window keyboard event handling
	}

	public function hideAskPrompt(p:AskPrompter):void {
		interp.askThread = null;
		lastAnswer = p.answer();
		if (p.parent) {
			p.parent.removeChild(p);
		}
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

	public function renameVariable(oldName:String, newName:String):void {
		if (oldName == newName) return;
		var owner:ScratchObj = app.viewedObj();
		if (!owner.ownsVar(oldName)) owner = app.stagePane;
		if (owner.hasName(newName)) {
			DialogBox.notify("Cannot Rename", "That name is already in use.");
			return;
		}

		var v:Variable = owner.lookupVar(oldName);
		if (v != null) {
			v.name = newName;
			if (v.watcher) v.watcher.changeVarName(newName);
		} else {
			owner.lookupOrCreateVar(newName);
		}
		updateVarRefs(oldName, newName, owner);
		app.updatePalette();
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
		var obj:ScratchObj = app.viewedObj();
		var costume:ScratchCostume = obj.currentCostume();
		costume.costumeName = '';
		var oldName:String = costume.costumeName;
		newName = obj.unusedCostumeName(newName || Translator.map('costume1'));
		costume.costumeName = newName;
		updateArgs(obj.isStage ? allUsesOfBackdrop(oldName) : allUsesOfCostume(oldName), newName);
	}

	public function renameSprite(newName:String):void {
		var obj:ScratchObj = app.viewedObj();
		var oldName:String = obj.objName;
		obj.objName = '';
		newName = app.stagePane.unusedSpriteName(newName || Translator.map('Sprite1'));
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
		var obj:ScratchObj = app.viewedObj();
		var oldName:String = s.soundName;
		s.soundName = '';
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

	public function renameBroadcast(oldMsg:String, newMsg:String):void {
		if (oldMsg == newMsg) return;

		if (allSendersOfBroadcast(newMsg).length > 0 ||
			allReceiversOfBroadcast(newMsg).length > 0) {
			DialogBox.notify("Cannot Rename", "That name is already in use.");
			return;
		}

		for each(var obj:Block in allBroadcastBlocksWithMsg(oldMsg)) {
				Block(obj).broadcastMsg = newMsg;
		}

		app.updatePalette();
	}

	private function sendsBroadcast(obj:ScratchObj, msg:String):Boolean {
		for each (var stack:Block in obj.scripts) {
			var found:Boolean;
			stack.allBlocksDo(function (b:Block):void {
				if (b.op == 'broadcast:' || b.op == 'doBroadcastAndWait') {
					if (b.broadcastMsg == msg) found = true;
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
					if (b.broadcastMsg.toLowerCase() == msg) found = true;
				}
			});
			if (found) return true;
		}
		return false;
	}

	private function allBroadcastBlocksWithMsg(msg:String):Array {
		var result:Array = [];
		for each (var o:ScratchObj in app.stagePane.allObjects()) {
			for each (var stack:Block in o.scripts) {
				stack.allBlocksDo(function (b:Block):void {
					if (b.op == 'broadcast:' || b.op == 'doBroadcastAndWait' || b.op == 'whenIReceive') {
						if (b.broadcastMsg == msg) result.push(b);
					}
				});
			}
		}
		return result;
	}

	public function allUsesOfBackdrop(backdropName:String):Array {
		var result:Array = [];
		allStacksAndOwnersDo(function (stack:Block, target:ScratchObj):void {
			stack.allBlocksDo(function (b:Block):void {
				for each (var a:* in b.args) {
					if (a is BlockArg && a.menuName == 'backdrop' && a.argValue == backdropName) result.push(a);
				}
			});
		});
		return result;
	}

	public function allUsesOfCostume(costumeName:String):Array {
		var result:Array = [];
		for each (var stack:Block in app.viewedObj().scripts) {
			stack.allBlocksDo(function (b:Block):void {
				for each (var a:* in b.args) {
					if (a is BlockArg && a.menuName == 'costume' && a.argValue == costumeName) result.push(a);
				}
			});
		}
		return result;
	}

	public function allUsesOfSprite(spriteName:String):Array {
		var spriteMenus:Array = ["spriteOnly", "spriteOrMouse", "spriteOrStage", "touching", "location"];
		var result:Array = [];
		for each (var stack:Block in allStacks()) {
			// for each block in stack
			stack.allBlocksDo(function (b:Block):void {
				for each (var a:* in b.args) {
					if (a is BlockArg && spriteMenus.indexOf(a.menuName) != -1 && a.argValue == spriteName) result.push(a);
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
				if (variableBlocks.indexOf(b.op) != -1 && b.args[0] is BlockArg && b.args[0].argValue == varName) result.push(b);
			});
		}
		return result;
	}

	public function allUsesOfSoundDo(soundName:String, f:Function):void {
		for each (var stack:Block in app.viewedObj().scripts) {
			stack.allBlocksDo(function (b:Block):void {
				for each (var a:* in b.args) {
					if (a is BlockArg && a.menuName == 'sound' && a.argValue == soundName) f(a);
				}
			});
		}
	}

	public function allCallsOf(callee:String, owner:ScratchObj, includeRecursive:Boolean = true):Array {
		var result:Array = [];
		for each (var stack:Block in owner.scripts) {
			if (!includeRecursive && stack.op == Specs.PROCEDURE_DEF && stack.spec == callee) continue;
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

	public function allStacksAndOwnersDo(f:Function,setDoObj:Boolean=false):void {
		// Call the given function on every stack in the project, passing the stack and owning sprite/stage.
		// This method is used by broadcast, so enumerate sprites/stage from front to back to match Scratch.
		var stage:ScratchStage = app.stagePane;
		var stack:Block;
		for (var i:int = stage.numChildren - 1; i >= 0; i--) {
			var o:* = stage.getChildAt(i);
			if (o is ScratchObj) {
				if (setDoObj) currentDoObj = ScratchObj(o);
				for each (stack in ScratchObj(o).scripts) f(stack, o);
			}
		}
		if (setDoObj) currentDoObj = stage;
		for each (stack in stage.scripts) f(stack, stage);
		currentDoObj = null;
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
		if (w != null && (!w.visible || !w.parent)) {
			showOnStage(w);
			app.updatePalette(false);
		}
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
		if (w != null && w.visible) {
			w.visible = false;
			app.updatePalette(false);
		}
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
	// Undelete support
	//------------------------------

	private var lastDelete:Array; // object, x, y, owner (for blocks/stacks/costumes/sounds)

	public function canUndelete():Boolean { return lastDelete != null }
	public function clearLastDelete():void { lastDelete = null }

	public function recordForUndelete(obj:*, x:int, y:int, index:int, owner:* = null):void {
		if (obj is Block) {
			var comments:Array = (obj as Block).attachedCommentsIn(app.scriptsPane);
			if (comments.length) {
				for each (var c:ScratchComment in comments) {
					c.parent.removeChild(c);
				}
				app.scriptsPane.fixCommentLayout();
				obj = [obj, comments];
			}
		}
		lastDelete = [obj, x, y, index, owner];
	}

	public function undelete():void {
		if (!lastDelete) return;
		var obj:* = lastDelete[0];
		var x:int = lastDelete[1];
		var y:int = lastDelete[2];
		var index:int = lastDelete[3];
		var previousOwner:* = lastDelete[4];
		doUndelete(obj, x, y, previousOwner);
		lastDelete = null;
	}

	protected function doUndelete(obj:*, x:int, y:int, prevOwner:*):void {
		if (obj is MediaInfo) {
			if (prevOwner is ScratchObj) {
				app.selectSprite(prevOwner);
				if (obj.mycostume) app.addCostume(obj.mycostume as ScratchCostume);
				if (obj.mysound) app.addSound(obj.mysound as ScratchSound);
			}
		} else if (obj is ScratchSprite) {
			app.addNewSprite(obj);
			obj.setScratchXY(x, y);
			app.selectSprite(obj);
		} else if ((obj is Array) || (obj is Block) || (obj is ScratchComment)) {
			app.selectSprite(prevOwner);
			app.setTab('scripts');
			var b:DisplayObject = obj is Array ? obj[0] : obj;
			b.x = app.scriptsPane.padding;
			b.y = app.scriptsPane.padding;
			if (b is Block) b.cacheAsBitmap = true;
			app.scriptsPane.addChild(b);
			if (obj is Array) {
				for each (var c:ScratchComment in obj[1]) {
					app.scriptsPane.addChild(c);
				}
			}
			app.scriptsPane.saveScripts();
			if (b is Block) app.updatePalette();
		}
	}

}}
