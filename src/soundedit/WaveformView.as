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

// WaveformView.as
// John Maloney, June 2012
//
// WaveformView implements a simple sound editor that can record, play, and edit sounds.
// It provide a visual display of the waveform (condensed), selection with auto-scroll, and
// a playback cursor. For editing, it supports basic cut/copy/paste/delete. It also support
// undo/redo and a small set of "effects" that can be applied to the selection.

package soundedit {
	import flash.display.*;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.SampleDataEvent;
	import flash.geom.Point;
	import flash.media.*;
	import flash.text.*;
	import assets.Resources;
	import ui.parts.SoundsPart;
	import util.DragClient;
	import scratch.ScratchSound;

public class WaveformView extends Sprite implements DragClient {

	private const backgroundColor:int = 0xF6F6F6;
	private const selectionColor:int = 0xD0D0FF;
	private const shortSelectionColor:int = 0xA0A0D0;
	private const waveformColor:int = 0x303030;
	private const playCursorColor:int = 0x0000FF;

	private static var PasteBuffer:Vector.<int> = new Vector.<int>();

	private var targetSound:ScratchSound;

	private var frame:Shape;
	private var wave:Shape;
	private var playCursor:Shape;
	private var recordingIndicator:TextField;

	private var soundsPart:SoundsPart;
	private var editor:SoundEditor;

	private var samples:Vector.<int> = new Vector.<int>();
	private var samplingRate:int = 22050;
	private var condensedSamples:Vector.<int> = new Vector.<int>();
	private var samplesPerCondensedSample:int = 32;

	private var scrollStart:int;	// first visible condensedSample
	private var selectionStart:int;	// first selected condensedSample
	private var selectionEnd:int;	// last selected condensedSample

	public function WaveformView(editor:SoundEditor, soundsPart:SoundsPart) {
		this.editor = editor;
		this.soundsPart = soundsPart;
		addChild(frame = new Shape());
		addChild(wave = new Shape());
		addChild(playCursor = new Shape());
		addRecordingMessage();
		playCursor.visible = false;
		addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		addEventListener(Event.ENTER_FRAME, step);
	}

	public function setWidthHeight(w:int, h:int):void {
		// draw the frame
		var g:Graphics = frame.graphics;
		g.clear();
		g.lineStyle(1, CSS.borderColor, 1, true);
		g.beginFill(backgroundColor)
		g.drawRoundRect(0, 0, w, h, 13, 13);
		g.endFill();

		// draw the playCursor
		g = playCursor.graphics;
		g.clear();
		g.beginFill(playCursorColor);
		g.drawRect(0, 1, 1, h - 2);
		g.endFill();

		drawWave();
	}

	private function addRecordingMessage():void {
		var fmt:TextFormat = new TextFormat(CSS.font, 18, 0xED9A00);
		recordingIndicator = Resources.makeLabel('Recording...', fmt, 15, 12);
		recordingIndicator.visible = false;
		addChild(recordingIndicator);
	}

	/* Startup */

	public function editSound(snd:ScratchSound):void {
		targetSound = snd;
		samplingRate = snd.rate;
		if (snd.editorData) {
			samples = snd.editorData.samples;
			condensedSamples = snd.editorData.condensedSamples;
			samplesPerCondensedSample = snd.editorData.samplesPerCondensedSample;
		} else {
			samples = targetSound.getSamples();
			adjustTimeScale();
			initEditorData();
		}
		selectionEnd = selectionStart = 0;
		scrollTo(0);
	}

	private function initEditorData():void {
		// Set the initial editor data for this sound.
		targetSound.editorData = {
			samples: samples,
			condensedSamples: condensedSamples,
			samplesPerCondensedSample: samplesPerCondensedSample,
			undoList: [],
			undoIndex: 0
		}
	}

	/* Scrolling */

	public function setScroll(n:Number):void {
		// Called when the scrollbar is dragged. Range of n is 0..1.
		var maxScroll:int = Math.max(0, condensedSamples.length - frame.width);
		scrollStart = clipTo(n * maxScroll, 0, maxScroll);
		drawWave();
	}

	private function scrollTo(condensedIndex:int):void {
		// Used internally. Updates the scrollbar.
		var maxScroll:int = Math.max(0, condensedSamples.length - frame.width);
		scrollStart = clipTo(condensedIndex, 0, maxScroll);
		editor.scrollbar.update(scrollStart / maxScroll, frame.width / condensedSamples.length);
		drawWave();
	}

	/* Time Scale */

	public function zoomIn():void  { setCondensation(Math.max(samplesPerCondensedSample / 2, 32)) }
	public function zoomOut():void { setCondensation(Math.min(samplesPerCondensedSample * 2, 512)) }

	private function adjustTimeScale():void {
		// select a time scale
		var secs:Number = samples.length / samplingRate;
		var n:int = 512;
		if (secs <= 120) n = 256;
		if (secs <= 30) n = 128;
		if (secs <= 10) n = 64;
		if (secs <= 2) n = 32;
		samplesPerCondensedSample = 0; // force setCondensation() to recompute
		setCondensation(n);
	}

	private function setCondensation(n:int):void {
		if (n == samplesPerCondensedSample) return;
		n = Math.max(1, n);
		var adjust:Number = samplesPerCondensedSample / n;
		samplesPerCondensedSample = n;
		computeCondensedSamples();
		selectionStart *= adjust;
		selectionEnd *= adjust;
		scrollTo(scrollStart * adjust);
	}

	private function computeCondensedSamples():void {
		condensedSamples = new Vector.<int>();
		var level:int, n:int;
		for (var i:int = 0; i < samples.length; i++) {
			var v:int = samples[i];
			if (v < 0) v = -v;
			if (v > level) level = v;
			if (++n == samplesPerCondensedSample) {
				condensedSamples.push(level);
				level = n = 0;
			}
		}
		// level for the leftover samples when samples length is not an exact multiple of samplesPerCondensedSample
		if (n > 0) condensedSamples.push(level);
	}

	/* Drawing */

	private function drawWave():void {
		recordingIndicator.visible = isRecording();
		var g:Graphics = wave.graphics;
		g.clear();
		if (!isRecording()) {
			drawSelection(g, 1);
			drawSamples(g);
			drawSelection(g, 0.3);
		}
	}

	private function drawSelection(g:Graphics, alpha:Number):void {
		var xStart:int = clipTo(selectionStart - scrollStart, 0, frame.width - 1);
		var xEnd:int = clipTo(selectionEnd - scrollStart, 0, frame.width - 1);
		var w:int = Math.max(1, (xEnd - xStart));
		if (w == 1) {
			g.beginFill(shortSelectionColor, 0.7);
			g.drawRect(xStart + 1, 1, w, frame.height - 2);
		} else {
			g.beginFill(selectionColor, alpha);
			g.drawRoundRect(xStart + 1, 1, w, frame.height - 2, 11, 11);
		}
		g.endFill();
	}

	private function drawSamples(g:Graphics):void {
		if (condensedSamples.length == 0) return; // no samples
		var h:int = frame.height - 2;
		var scale:Number = (h / 2) / 32768;
		var center:int = (h / 2) + 1;
		var count:int = Math.min(condensedSamples.length, frame.width);
		var i:int, x:int;
		g.beginFill(waveformColor);
		if (samplesPerCondensedSample < 5) {
			i = scrollStart * samplesPerCondensedSample;
			for (x = 1; x < frame.width; x++) {
				if (i >= samples.length) break;
				var dy:int = scale * samples[i];
				if (dy > 0) g.drawRect(x, center - dy, 1, dy);
				else g.drawRect(x, center, 1, -dy);
				i += samplesPerCondensedSample;
			}
		} else {
			i = scrollStart;
			for (x = 1; x < frame.width; x++) {
				if (i >= condensedSamples.length) break;
				dy = scale * condensedSamples[i];
				g.drawRect(x, center - dy, 1, (2 * dy) + 1);
				i++;
			}
		}
		g.endFill();
	}

	private function clipTo(n:Number, low:Number, high:Number):Number {
		// Return n clipped to the given range. If n is out of range, return closest number in range.
		if (high < low) high = low;
		if (n < low) return low;
		if (n > high) return high;
		return n;
	}

	/* Recording */

	private var mic:Microphone;
	private var recordSamples:Vector.<int> = new Vector.<int>();

	public function stopAll(ignore:* = null):void {
		stopPlaying();
		stopRecording();
		drawWave();
	}

	public function toggleRecording(ignore:* = null):void {
		if (isRecording()) {
			stopRecording();
		} else {
			stopAll();
			openMicrophone();
			if(mic) {
				recordSamples = new Vector.<int>();
				mic.addEventListener(SampleDataEvent.SAMPLE_DATA, recordData);
			}
		}
		editor.updateIndicators();
		drawWave();
	}

	public function isRecording():Boolean { return recordSamples != null }

	private function stopRecording():void {
		if (mic) mic.removeEventListener(SampleDataEvent.SAMPLE_DATA, recordData);
		editor.levelMeter.clear();
		if (recordSamples && (recordSamples.length > 0)) appendRecording(recordSamples);
		recordSamples = null;
		editor.updateIndicators();
		drawWave();
	}

	private function recordData(evt:SampleDataEvent):void {
		var peak:Number = 0;
		while (evt.data.bytesAvailable) {
			var sample:Number = evt.data.readFloat();
			peak = Math.max(peak, Math.abs(sample));
			recordSamples.push(sample * 32767);
		}
		editor.levelMeter.setLevel(100 * peak);
	}

	private function appendRecording(newSamples:Vector.<int>):void {
		// Insert the given samples.
		var insertionPoint:int = ((selectionStart == 0) && ((selectionEnd - selectionStart) < 5)) ? 0 : selectionEnd;
		var before:Vector.<int> = extract(0, insertionPoint);
		var after:Vector.<int> = extract(insertionPoint);
		updateContents(before.concat(newSamples).concat(after), false, 128);
		selectionStart = before.length / samplesPerCondensedSample;
		selectionEnd = (before.length + newSamples.length) / samplesPerCondensedSample;
		scrollTo(selectionStart);
	}

	private function openMicrophone():void {
		mic = Microphone.getMicrophone();
		if (!mic) return;

		mic.setSilenceLevel(0);
		mic.setLoopBack(true);
		mic.soundTransform = new SoundTransform(0, 0);
		if (samplingRate == 22050) mic.rate = 22;
		if (samplingRate > 22050) mic.rate = 44;
		if (samplingRate < 22050) mic.rate = 11;
	}

	/* Playing */

	private var soundChannel:SoundChannel;
	private var playIndex:int; // index of next sample to play
	private var playEndIndex:int; // index of sample at which to stop playing
	private var playStart:int; // index of first condensed sampled to play, used by play cursor
	private var playbackStarting:Boolean;

	public function startPlaying(ignore:* = null):void {
		stopAll();
		if (!samples || (samples.length == 0)) return;

		playIndex = clipTo(selectionStart * samplesPerCondensedSample, 0, samples.length);
		playEndIndex = clipTo(selectionEnd * samplesPerCondensedSample, 0, samples.length);
		if ((selectionEnd - selectionStart) <= 1) { // no selection
			if ((condensedSamples.length - selectionStart) < 2) playIndex = 0; // if selection is at end, start at beginning
			playEndIndex = samples.length; // play to end if no selection
		}
		playStart = playIndex / samplesPerCondensedSample;
		playbackStarting = true;

		var sound:Sound = new Sound();
		sound.addEventListener(SampleDataEvent.SAMPLE_DATA, playBuffer);
		soundChannel = sound.play();
		soundChannel.addEventListener(Event.SOUND_COMPLETE, stopPlaying);
		playCursor.visible = true;
		editor.updateIndicators();
		drawWave();
	}

	public function isPlaying():Boolean { return soundChannel != null }

	private function stopPlaying(ignore:* = null):void {
		if (soundChannel) soundChannel.stop();
		soundChannel = null;
		editor.levelMeter.clear();
		playCursor.visible = false;
		editor.updateIndicators();
		drawWave();
	}

	public function togglePlaying(ignore:* = null):void {
		if (soundChannel) stopPlaying();
		else startPlaying();
	}

	private function playBuffer(evt:SampleDataEvent):void {
		// Fill the next sound buffer with samples. Write several copies of each each original
		// sample to convert from lower original sampling rates (11025 or 22050) and mono->stereo.
		// Note: This "cheap trick" of duplicating samples can also approximate imported sounds
		// at sampling rates of 16000 and 8000 (actual playback rates: 14700 and 8820).
		//
		var max:int, i:int;
		var dups:int = 2 * (44100 / samplingRate); // number of copies of each samples to write
		if (dups & 1) dups++; // ensure that dups is even
		if (playEndIndex > samples.length) playEndIndex = samples.length; // Don't try to play more than we have
		var count:int = 6000 / dups;
		for (i = 0; i < count && (playIndex < playEndIndex); i++) {
			var sample:Number = samples[playIndex++] / 32767;
			for (var j:int = 0; j < dups; j++)
				evt.data.writeFloat(sample);
		}
		if (playbackStarting) {
			if (i < count) {
				// Very short sound or selection; pad with enough zeros so sound actually plays.
				for (i = 0; i < 2048; i++)
					evt.data.writeFloat(0 / 32767);
			}
			playbackStarting = false;
		}
	}

	/* Editing Operations */

	public function leftArrow():void {
		if (selectionStart > 0) {
			selectionStart--;
			selectionEnd--;
			drawWave();
		}
	}

	public function rightArrow():void {
		if (selectionEnd < condensedSamples.length) {
			selectionStart++;
			selectionEnd++;
			drawWave();
		}
	}

	public function copy():void { PasteBuffer = extract(selectionStart, selectionEnd) }
	public function cut():void { copy(); deleteSelection() }

	public function deleteSelection(crop:Boolean = false):void {
		if (crop) {
			updateContents(extract(selectionStart, selectionEnd));
		} else {
			updateContents(extract(0, selectionStart).concat(extract(selectionEnd)));
		}
	}

	public function paste():void {
		var before:Vector.<int> = extract(0, selectionStart);
		var after:Vector.<int> = extract(selectionEnd);
		updateContents(before.concat(PasteBuffer).concat(after));
	}

	public function selectAll():void {
		selectionStart = 0;
		selectionEnd = Math.max(0, condensedSamples.length - 1);
		drawWave();
	}

	private function extract(condensedStart:int, condensedEnd:int = -1):Vector.<int> {
		// Answer a vector of samples spanning the given range of condensed samples.
		// If condensedEnd is omitted, select from condensedStart to the end.
		if (condensedEnd == -1) condensedEnd = condensedSamples.length;
		var first:int = clipTo(condensedStart * samplesPerCondensedSample, 0, samples.length);
		var last:int = clipTo(condensedEnd * samplesPerCondensedSample, 0, samples.length);
		return samples.slice(first, last);
	}

	private function updateContents(newSamples:Vector.<int>, keepSelection:Boolean = false, newCondensation:int = -1):void {
		// Replace my contents with the given sample buffer.
		// Record change for undo.
		recordForUndo();
		samples = newSamples;
		if (newCondensation > 0) samplesPerCondensedSample = newCondensation;
		computeCondensedSamples();

		var data:Object = targetSound.editorData;
		data.samples = samples;
		data.condensedSamples = condensedSamples;
		data.samplesPerCondensedSample = samplesPerCondensedSample;
		targetSound.setSamples(samples, samplingRate);
		editor.app.setSaveNeeded();

		var end:int = condensedSamples.length - 1;
		scrollStart = clipTo(scrollStart, 0, end - frame.width);
		if (keepSelection) {
			selectionStart = clipTo(selectionStart, 0, end);
			selectionEnd = clipTo(selectionEnd, 0, end);
		} else {
			selectionEnd = selectionStart = clipTo(selectionStart, 0, end);
		}
		drawWave();
	}

	/* Effects */

	public function applyEffect(effect:String, shiftKey:Boolean):void {
		if (emptySelection()) return;
		var before:Vector.<int> = extract(0, selectionStart);
		var selection:Vector.<int> = extract(selectionStart, selectionEnd);
		var after:Vector.<int> = extract(selectionEnd);
		switch (effect) {
		case 'fade in': fadeIn(selection); break;
		case 'fade out': fadeOut(selection); break;
		case 'louder': louder(selection, shiftKey); break;
		case 'softer': softer(selection, shiftKey); break;
		case 'silence': silence(selection); break;
		case 'reverse': reverse(selection); break;
		}
		updateContents(before.concat(selection).concat(after), true);
	}

	private function fadeIn(buf:Vector.<int>):void {
		var len:int = buf.length;
		for (var i:int = 0; i < len; i++) buf[i] = (i / len) * buf[i];
	}

	private function fadeOut(buf:Vector.<int>):void {
		var len:int = buf.length;
		for (var i:int = 0; i < len; i++) buf[i] = ((len - i) / len) * buf[i];
	}

	private function louder(buf:Vector.<int>, shiftKey:Boolean):void {
		var i:int, max:int;
		for (i = 0; i < buf.length; i++) max = Math.max(max, Math.abs(buf[i]));
		var scale:Number = Math.min(loudnessScale(shiftKey), 32767 / max);
		for (i = 0; i < buf.length; i++) buf[i] = scale * buf[i];
	}

	private function softer(buf:Vector.<int>, shiftKey:Boolean):void {
		var i:int, max:int;
		for (i = 0; i < buf.length; i++) max = Math.max(max, Math.abs(buf[i]));
		var scale:Number = Math.max(1 / loudnessScale(shiftKey), Math.min(1, 512/max));
		for (i = 0; i < buf.length; i++) buf[i] = scale * buf[i];
	}

	private function loudnessScale(shiftKey:Boolean):Number { return shiftKey ? 1.3 : 3 }

	private function silence(buf:Vector.<int>):void {
		for (var i:int = 0; i < buf.length; i++) buf[i] = 0;
	}

	private function reverse(buf:Vector.<int>):void {
		var len:int = buf.length;
		var tmp:Vector.<int> = buf.slice(0, len);
		for (var i:int = 0; i < len; i++) {
			buf[i] = tmp[(len - 1) - i];
		}
	}

	/* Undo */

	public function undo(ignore:* = null):void {
		var data:Object = targetSound.editorData;
		if (data.undoIndex == data.undoList.length) data.undoList.push([samples, condensedSamples, samplesPerCondensedSample]); // save current state for redo
		if (data.undoIndex > 0) installUndoRecord(data.undoList[--data.undoIndex]);
		soundsPart.refreshUndoButtons();
	}

	public function redo(ignore:* = null):void {
		var data:Object = targetSound.editorData;
		if (data.undoIndex < (data.undoList.length - 1)) installUndoRecord(data.undoList[++data.undoIndex]);
		soundsPart.refreshUndoButtons();
	}

	public function canUndo():Boolean { return targetSound && targetSound.editorData.undoIndex > 0 }
	public function canRedo():Boolean { return targetSound && targetSound.editorData.undoIndex < (targetSound.editorData.undoList.length - 1) }

	private function installUndoRecord(r:Array):void {
		stopAll();
		samples = r[0];
		condensedSamples = r[1];
		samplesPerCondensedSample = r[2];
		selectionEnd = selectionStart = 0;
		scrollTo(0);
	}

	private function recordForUndo():void {
		var data:Object = targetSound.editorData;
		if (data.undoList.length > data.undoIndex) data.undoList = data.undoList.slice(0, data.undoIndex);
		data.undoList.push([samples, condensedSamples, samplesPerCondensedSample]);
		data.undoIndex = data.undoList.length;
		soundsPart.refreshUndoButtons();
	}

	/* Mouse */

	private var selectMode:String; // when not dragging, null; when dragging, one of: new, start, end
	private var startOffset:int; // offset where drag started

	public function mouseDown(evt:MouseEvent):void { Scratch(root).gh.setDragClient(this, evt) }

	public function dragBegin(evt:MouseEvent):void {
		// Decide how to make or adjust the selection.
		const close:int = 8;
		startOffset = Math.max(0, offsetAtMouse() - 1);
		selectMode = 'new';
		if (emptySelection()) {
			if (Math.abs(startOffset - selectionStart) < close) startOffset = selectionStart;
			if (mousePastEnd()) startOffset = condensedSamples.length;
		} else {
			// Clicking close to the start or end of a selection adjusts the selection.
			if (Math.abs(startOffset - selectionStart) < close) selectMode = 'start';
			else if (Math.abs(startOffset - selectionEnd) < close) selectMode = 'end';
		}
		dragMove(evt);
	}

	private function emptySelection():Boolean { return (selectionEnd - selectionStart) <= 1 }

	public function dragMove(evt:MouseEvent):void {
		var thisOffset:int = offsetAtMouse();
		if ('start' == selectMode) {
			selectionStart = thisOffset;
			selectionEnd = Math.max(thisOffset, selectionEnd);
		}
		if ('end' == selectMode) {
			selectionStart = Math.min(selectionStart, thisOffset);
			selectionEnd = thisOffset;
		}
		if ('new' == selectMode) {
			if (thisOffset < startOffset) {
				selectionStart = thisOffset;
				selectionEnd = startOffset;
			} else {
				selectionStart = startOffset;
				selectionEnd = thisOffset;
			}
		}
		drawWave();
	}

	public function dragEnd(evt:MouseEvent):void { selectMode = null }

	private function offsetAtMouse():int {
		var localX:int = globalToLocal(new Point(stage.mouseX, 0)).x;
		return clipTo(scrollStart + localX, 0, condensedSamples.length);
	}

	private function mousePastEnd():Boolean {
		var localX:int = globalToLocal(new Point(stage.mouseX, 0)).x;
		return (scrollStart + localX) > condensedSamples.length;
	}

	/* Stepping */

	private function step(evt:Event):void {
		if (selectMode) {
			// autoscroll while selecting
			var localX:int = globalToLocal(new Point(stage.mouseX, 0)).x;
			if (localX < 0) scrollTo(scrollStart + (localX / 4));
			else if (localX > frame.width) scrollTo(scrollStart + ((localX - frame.width) / 4));
			dragMove(null);
		}
		if (soundChannel) {
			// update the play cursor while playing
			var cursorOffset:int = playStart + ((soundChannel.position * samplingRate) / (1000 * samplesPerCondensedSample));
			cursorOffset = Math.min(cursorOffset, condensedSamples.length);
			if (cursorOffset < scrollStart) scrollTo(cursorOffset);
			if (cursorOffset >= (scrollStart + frame.width)) scrollTo(cursorOffset);
			playCursor.x = clipTo(cursorOffset - scrollStart + 1, 1, frame.width - 1);
		}
	}

}}
