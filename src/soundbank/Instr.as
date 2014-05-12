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

// Instr.as
// John Maloney, April 2012
//
// This class embeds the sound data for Scratch instruments and drums.
// The static variable 'samples' is a dictionary of named sound buffers.
// Call initSamples() to initialize 'samples' before using.
//
// All instrument and drum samples were created for Scratch by:
//
//		Paul Madden, paulmatthewmadden@yahoo.com
//
// Paul is an excellent sound designer and we appreciate all the effort
// he put into this project.

package soundbank {
	import flash.utils.*;
	import sound.WAVFile;

public class Instr {

	public static var samples:Object;

	public static function initSamples():void {
		// Initialize the dictionary of named sound buffers.
		// Details: Build the dictionary by enumerating all the embedded sounds in this file
		// (i.e. constants with a value of type 'class'), extracting the sound data from the
		// WAV file, and adding an entry for it to the 'samples' object.

		if (samples) return; // already initialized

		samples = {};
		var classDescription:XML = describeType(Instr);
		for each (var k:XML in classDescription.elements('constant')) {
			if (k.attribute('type') == 'Class') {
				var instrName:String = k.attribute('name');
				samples[instrName] = getWAVSamples(new Instr[instrName]);
			}
		}
	}

	private static function getWAVSamples(wavData:ByteArray):ByteArray {
		// Extract a sound buffer from a WAV file. Assume the WAV file contains 16-bit, uncompressed sound data.
		var info:Object = WAVFile.decode(wavData);
		var soundBuffer:ByteArray = new ByteArray();
		soundBuffer.endian = Endian.LITTLE_ENDIAN;
		wavData.position = info.sampleDataStart;
		wavData.readBytes(soundBuffer, 0, 2 * info.sampleCount);
		return soundBuffer;
	}

	/* Instruments */

	[Embed(source='instruments/AcousticGuitar_F3_22k.wav', mimeType='application/octet-stream')]
		public static const AcousticGuitar_F3:Class;

	[Embed(source='instruments/AcousticPiano(5)_A#3_22k.wav', mimeType='application/octet-stream')]
		public static const AcousticPiano_As3:Class;

	[Embed(source='instruments/AcousticPiano(5)_C4_22k.wav', mimeType='application/octet-stream')]
		public static const AcousticPiano_C4:Class;

	[Embed(source='instruments/AcousticPiano(5)_G4_22k.wav', mimeType='application/octet-stream')]
		public static const AcousticPiano_G4:Class;

	[Embed(source='instruments/AcousticPiano(5)_F5_22k.wav', mimeType='application/octet-stream')]
		public static const AcousticPiano_F5:Class;

	[Embed(source='instruments/AcousticPiano(5)_C6_22k.wav', mimeType='application/octet-stream')]
		public static const AcousticPiano_C6:Class;

	[Embed(source='instruments/AcousticPiano(5)_D#6_22k.wav', mimeType='application/octet-stream')]
		public static const AcousticPiano_Ds6:Class;

	[Embed(source='instruments/AcousticPiano(5)_D7_22k.wav', mimeType='application/octet-stream')]
		public static const AcousticPiano_D7:Class;

	[Embed(source='instruments/AltoSax_A3_22K.wav', mimeType='application/octet-stream')]
		public static const AltoSax_A3:Class;

	[Embed(source='instruments/AltoSax(3)_C6_22k.wav', mimeType='application/octet-stream')]
		public static const AltoSax_C6:Class;

	[Embed(source='instruments/Bassoon_C3_22k.wav', mimeType='application/octet-stream')]
		public static const Bassoon_C3:Class;

	[Embed(source='instruments/BassTrombone_A2(2)_22k.wav', mimeType='application/octet-stream')]
		public static const BassTrombone_A2_2:Class;

	[Embed(source='instruments/BassTrombone_A2(3)_22k.wav', mimeType='application/octet-stream')]
		public static const BassTrombone_A2_3:Class;

	[Embed(source='instruments/Cello(3b)_C2_22k.wav', mimeType='application/octet-stream')]
		public static const Cello_C2:Class;

	[Embed(source='instruments/Cello(3)_A#2_22k.wav', mimeType='application/octet-stream')]
		public static const Cello_As2:Class;

	[Embed(source='instruments/Choir(4)_F3_22k.wav', mimeType='application/octet-stream')]
		public static const Choir_F3:Class;

	[Embed(source='instruments/Choir(4)_F4_22k.wav', mimeType='application/octet-stream')]
		public static const Choir_F4:Class;

	[Embed(source='instruments/Choir(4)_F5_22k.wav', mimeType='application/octet-stream')]
		public static const Choir_F5:Class;

	[Embed(source='instruments/Clarinet_C4_22k.wav', mimeType='application/octet-stream')]
		public static const Clarinet_C4:Class;

	[Embed(source='instruments/ElectricBass(2)_G1_22k.wav', mimeType='application/octet-stream')]
		public static const ElectricBass_G1:Class;

	[Embed(source='instruments/ElectricGuitar(2)_F3(1)_22k.wav', mimeType='application/octet-stream')]
		public static const ElectricGuitar_F3:Class;

	[Embed(source='instruments/ElectricPiano_C2_22k.wav', mimeType='application/octet-stream')]
		public static const ElectricPiano_C2:Class;

	[Embed(source='instruments/ElectricPiano_C4_22k.wav', mimeType='application/octet-stream')]
		public static const ElectricPiano_C4:Class;

	[Embed(source='instruments/EnglishHorn(1)_D4_22k.wav', mimeType='application/octet-stream')]
		public static const EnglishHorn_D4:Class;

	[Embed(source='instruments/EnglishHorn(1)_F3_22k.wav', mimeType='application/octet-stream')]
		public static const EnglishHorn_F3:Class;

	[Embed(source='instruments/Flute(3)_B5(1)_22k.wav', mimeType='application/octet-stream')]
		public static const Flute_B5_1:Class;

	[Embed(source='instruments/Flute(3)_B5(2)_22k.wav', mimeType='application/octet-stream')]
		public static const Flute_B5_2:Class;

	[Embed(source='instruments/Marimba_C4_22k.wav', mimeType='application/octet-stream')]
		public static const Marimba_C4:Class;

	[Embed(source='instruments/MusicBox_C4_22k.wav', mimeType='application/octet-stream')]
		public static const MusicBox_C4:Class;

	[Embed(source='instruments/Organ(2)_G2_22k.wav', mimeType='application/octet-stream')]
		public static const Organ_G2:Class;

	[Embed(source='instruments/Pizz(2)_A3_22k.wav', mimeType='application/octet-stream')]
		public static const Pizz_A3:Class;

	[Embed(source='instruments/Pizz(2)_E4_22k.wav', mimeType='application/octet-stream')]
		public static const Pizz_E4:Class;

	[Embed(source='instruments/Pizz(2)_G2_22k.wav', mimeType='application/octet-stream')]
		public static const Pizz_G2:Class;

	[Embed(source='instruments/SteelDrum_D5_22k.wav', mimeType='application/octet-stream')]
		public static const SteelDrum_D5:Class;

	[Embed(source='instruments/SynthLead(6)_C4_22k.wav', mimeType='application/octet-stream')]
		public static const SynthLead_C4:Class;

	[Embed(source='instruments/SynthLead(6)_C6_22k.wav', mimeType='application/octet-stream')]
		public static const SynthLead_C6:Class;

	[Embed(source='instruments/SynthPad(2)_A3_22k.wav', mimeType='application/octet-stream')]
		public static const SynthPad_A3:Class;

	[Embed(source='instruments/SynthPad(2)_C6_22k.wav', mimeType='application/octet-stream')]
		public static const SynthPad_C6:Class;

	[Embed(source='instruments/TenorSax(1)_C3_22k.wav', mimeType='application/octet-stream')]
		public static const TenorSax_C3:Class;

	[Embed(source='instruments/Trombone_B3_22k.wav', mimeType='application/octet-stream')]
		public static const Trombone_B3:Class;

	[Embed(source='instruments/Trumpet_E5_22k.wav', mimeType='application/octet-stream')]
		public static const Trumpet_E5:Class;

	[Embed(source='instruments/Vibraphone_C3_22k.wav', mimeType='application/octet-stream')]
		public static const Vibraphone_C3:Class;

	[Embed(source='instruments/Violin(2)_D4_22K.wav', mimeType='application/octet-stream')]
		public static const Violin_D4:Class;

	[Embed(source='instruments/Violin(3)_A4_22k.wav', mimeType='application/octet-stream')]
		public static const Violin_A4:Class;

	[Embed(source='instruments/Violin(3b)_E5_22k.wav', mimeType='application/octet-stream')]
		public static const Violin_E5:Class;

	[Embed(source='instruments/WoodenFlute_C5_22k.wav', mimeType='application/octet-stream')]
		public static const WoodenFlute_C5:Class;

	/* Drums */

	[Embed(source='drums/BassDrum(1b)_22k.wav', mimeType='application/octet-stream')]
		public static const BassDrum:Class;

	[Embed(source='drums/Bongo_22k.wav', mimeType='application/octet-stream')]
		public static const Bongo:Class;

	[Embed(source='drums/Cabasa(1)_22k.wav', mimeType='application/octet-stream')]
		public static const Cabasa:Class;

	[Embed(source='drums/Clap(1)_22k.wav', mimeType='application/octet-stream')]
		public static const Clap:Class;

	[Embed(source='drums/Claves(1)_22k.wav', mimeType='application/octet-stream')]
		public static const Claves:Class;

	[Embed(source='drums/Conga(1)_22k.wav', mimeType='application/octet-stream')]
		public static const Conga:Class;

	[Embed(source='drums/Cowbell(3)_22k.wav', mimeType='application/octet-stream')]
		public static const Cowbell:Class;

	[Embed(source='drums/Crash(2)_22k.wav', mimeType='application/octet-stream')]
		public static const Crash:Class;

	[Embed(source='drums/Cuica(2)_22k.wav', mimeType='application/octet-stream')]
		public static const Cuica:Class;

	[Embed(source='drums/GuiroLong(1)_22k.wav', mimeType='application/octet-stream')]
		public static const GuiroLong:Class;

	[Embed(source='drums/GuiroShort(1)_22k.wav', mimeType='application/octet-stream')]
		public static const GuiroShort:Class;

	[Embed(source='drums/HiHatClosed(1)_22k.wav', mimeType='application/octet-stream')]
		public static const HiHatClosed:Class;

	[Embed(source='drums/HiHatOpen(2)_22k.wav', mimeType='application/octet-stream')]
		public static const HiHatOpen:Class;

	[Embed(source='drums/HiHatPedal(1)_22k.wav', mimeType='application/octet-stream')]
		public static const HiHatPedal:Class;

	[Embed(source='drums/Maracas(1)_22k.wav', mimeType='application/octet-stream')]
		public static const Maracas:Class;

	[Embed(source='drums/SideStick(1)_22k.wav', mimeType='application/octet-stream')]
		public static const SideStick:Class;

	[Embed(source='drums/SnareDrum(1)_22k.wav', mimeType='application/octet-stream')]
		public static const SnareDrum:Class;

	[Embed(source='drums/Tambourine(3)_22k.wav', mimeType='application/octet-stream')]
		public static const Tambourine:Class;

	[Embed(source='drums/Tom(1)_22k.wav', mimeType='application/octet-stream')]
		public static const Tom:Class;

	[Embed(source='drums/Triangle(1)_22k.wav', mimeType='application/octet-stream')]
		public static const Triangle:Class;

	[Embed(source='drums/Vibraslap(1)_22k.wav', mimeType='application/octet-stream')]
		public static const Vibraslap:Class;

	[Embed(source='drums/WoodBlock(1)_22k.wav', mimeType='application/octet-stream')]
		public static const WoodBlock:Class;

}}
