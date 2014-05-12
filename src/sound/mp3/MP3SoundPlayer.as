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

// MP3SoundPlayer.as
// John Maloney, June 2010
//
// A MP3SoundPlayer extents ScratchSoundPlayer to decode MP3 sample data.
// It works be converting the MP3 data into a Flash sound instance, then
// using extract() to get unencoded samples. These are scaled by the client
// object's current volume.
// Note: extract() extracts data at 44100 stereo samples/sec, so no
// interpolation is necessary.
// Note: To avoid having to support MP3 format sound in future versions of Scratch,
// the ability to embed MP3 sound in projects is being deprecated. When an MP3 sound
// is imported, it is converted to a compressed, mono WAV sound. This MP3SoundPlayer
// is still used for previewing sounds before importing.

package sound.mp3 {
	import flash.events.*;
	import flash.media.*;
	import flash.utils.*;
	import scratch.ScratchSound;
	import sound.ScratchSoundPlayer;
	import sound.mp3.*;

public class MP3SoundPlayer extends ScratchSoundPlayer {

	private var mp3Sound:Sound;
	private var isLoading:Boolean;

	public function MP3SoundPlayer(mp3Data:ByteArray) {
		super(null);
		this.soundData = mp3Data;
	}

	public override function atEnd():Boolean {
		if (isLoading) return false;
		return soundChannel == null;
	}

	public override function startPlaying(doneFunction:Function = null):void {
		function loadDone(snd:Sound):void {
			mp3Sound = snd;
			startChannel(doneFunction);
		}
		stopIfAlreadyPlaying();
		activeSounds.push(this);
		isLoading = true;
		if (mp3Sound == null) MP3Loader.load(soundData, loadDone);
		else startChannel(doneFunction);
	}

	private function startChannel(doneFunction:Function):void {
		var flashSnd:Sound = new Sound();
		flashSnd.addEventListener(SampleDataEvent.SAMPLE_DATA, writeSampleData);
		soundChannel = flashSnd.play();
		isLoading = false;
		if (doneFunction != null) soundChannel.addEventListener(Event.SOUND_COMPLETE, doneFunction);
	}

	private function writeSampleData(evt:SampleDataEvent):void {
		var buf:ByteArray = new ByteArray();
		var n:int = mp3Sound.extract(buf, 4096);
		buf.position = 0;
		updateVolume();
		while (buf.bytesAvailable >= 4) {
			evt.data.writeFloat(volume * buf.readFloat());
		}
		if (n < 4096) {
			soundChannel = null; // don't explicitly stop the sound channel in this callback; allow it to stop on its own
			stopPlaying();
		}
	}

}}
