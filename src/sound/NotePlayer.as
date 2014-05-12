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

// NotePlayer.as
// John Maloney, June 2010
//
// Subclass of ScratchSoundPlayer to play notes on a sampled instrument or drum.
//
// A sampled instrument outputs interpolated sound samples from  an array of signed,
// 16-bit integers with an original sampling rate of 22050 samples/sec. The pitch is
// shifted by change the step size while iterating through this array. An instrument
// may also be looped so that it can be sustained and it may have a volume envelope
// to control the attack and decay of the note.

package sound {
	import flash.utils.ByteArray;

public class NotePlayer extends ScratchSoundPlayer {

	private var originalPitch:Number;
	private var index:Number = 0;
	private var samplesRemaining:int; // determines note duration

	// Looping
	private var isLooped:Boolean = false;
	private var loopPoint:int; // final sample in loop
	private var loopLength:Number;

	// Volume Envelope
	private var envelopeValue:Number = 1;
	private var samplesSinceStart:int = 0;
	private var attackEnd:int = 0;
	private var attackRate:Number = 0;
	private var holdEnd:int = 0;
	private var decayRate:Number = 1;

	public function NotePlayer(soundData:ByteArray, originalPitch:Number, loopStart:int = -1, loopEnd:int = -1, env:Array = null):void {
		super(null); // required by compiler since signature of this constructor differs from superclass
		if (soundData == null) soundData = new ByteArray(); // missing instrument or drum resource
		this.soundData = soundData;
		this.originalPitch = originalPitch; 
		stepSize = 0.5; // default, no pitch shift   
		startOffset = 0;
		endOffset = soundData.length / 2; // end of sample data
		getSample = function():int { return 0 } // called once at startup time

		if ((loopStart >= 0) && (loopStart < endOffset)) {
			isLooped = true;
			loopPoint = loopStart;
			if ((loopEnd > 0) && (loopEnd <= endOffset)) endOffset = loopEnd;
			loopLength = endOffset - loopPoint;

			// Compute the original pitch more exactly from the loop length:
			var oneCycle:Number = 22050 / originalPitch;
			var cycles:int = Math.round(loopLength / oneCycle);
			this.originalPitch = 22050 / (loopLength / cycles);
		}
		if (env) {
			attackEnd = env[0] * 44.100;
			if (attackEnd > 0) attackRate = Math.pow(33000, 1 / attackEnd);
			holdEnd = attackEnd + (env[1] * 44.100);
			var decayCount:int = env[2] * 44100;
			decayRate = (decayCount == 0) ? 1 : Math.pow(33000, -1 / decayCount);
		}
	}

	public function setNoteAndDuration(midiKey:Number, secs:Number):void {
		midiKey = Math.max(0, Math.min(midiKey, 127));
		var pitch:Number = 440 * Math.pow(2, (midiKey - 69) / 12); // midi key 69 is A (440 Hz)
		stepSize = pitch / (2 * originalPitch); // adjust for original sampling rate of 22050
		setDuration(secs);
	}

	public function setDuration(secs:Number):void {
		samplesSinceStart = 0;
		samplesRemaining = 44100 * secs;
		if (!isLooped) samplesRemaining = Math.min(samplesRemaining, endOffset / stepSize);
		 envelopeValue = (attackEnd > 0) ? 1 / 33000 : 1;
	}

	protected override function interpolatedSample():Number {
		if (samplesRemaining-- <= 0) { noteFinished(); return 0 }
		index += stepSize;
		if(index >= endOffset) {
			if(!isLooped) return 0;
			var sub:Number = loopLength - ((index - endOffset) % loopLength);
			if(sub == 0) index = endOffset - loopLength;
			else index = endOffset - sub;
		}
		var i:int = int(index);
		var frac:Number = index - i;
		var byteIndex:int = i << 1;
		var result:int = (soundData[byteIndex + 1] << 8) + soundData[byteIndex];
		var curr:Number = (result <= 32767 ? result : result - 65536);

		++i;
		var next:Number = -1;
		if (i >= endOffset) {
			if (isLooped) i = loopPoint;
			else next = 0;
		}
		if(next < 0) {
			byteIndex = i << 1;
			result = (soundData[byteIndex + 1] << 8) + soundData[byteIndex];
			next = (result <= 32767 ? result : result - 65536);
		}
		var sample:Number = (curr + (frac * (next - curr))) / 100000; // xxx 32000; attenuate...
		if (samplesRemaining < 1000) sample *= (samplesRemaining / 1000.0); // relaase phease
		updateEnvelope();
		return envelopeValue * volume * sample;
	}

	private function updateEnvelope():void {
		// Compute envelopeValue for the current sample.
		++samplesSinceStart;
		if (samplesSinceStart < attackEnd) {
			envelopeValue *= attackRate;
		} else if (samplesSinceStart == attackEnd) {
			envelopeValue = 1;
		} else if (samplesSinceStart > holdEnd && decayRate < 1) {
			envelopeValue *= decayRate;
		}
	}
}}
