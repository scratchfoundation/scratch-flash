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

// ScratchExtension.as
// John Maloney, March 2013
//
// Contains the name, port number, and block specs for an extension, as well as its runtime state.
// This file also defines the extensions built into Scratch (e.g. WeDo, PicoBoard).
//
// Extension block types:
//	' ' - command block
//  'w' - command block that waits
//	'r' - reporter block (returns a number or string)
//	'R' - http reporter block that waits for the callback (returns a number or string)
//	'b' - boolean reporter block
//	'-' - (not actually a block) add some blank space between blocks
//
// Possible argument slots:
//	'%n' - number argument slot
//	'%s' - string argument slot
//	'%b' - boolean argument slot

package extensions {
import flash.utils.Dictionary;

public class ScratchExtension {

	public var name:String = '';
	public var host:String = '127.0.0.1'; // most extensions run on the local host
	public var port:int;
	public var blockSpecs:Array = [];
	public var isInternal:Boolean;
	public var useScratchPrimitives:Boolean; // true for extensions built into Scratch (WeDo, PicoBoard) that have custom primitives
	public var showBlocks:Boolean;
	public var menus:Object = {};
	public var thumbnailMD5:String = ''; // md5 has for extension image shown in extension library
	public var url:String = ''; // URL for extension documentation page (with helper app download link, if appropriate)
	public var javascriptURL:String = ''; // URL to load a JavaScript extension
	public var tags:Array = []; // tags for the extension library filter

	// Runtime state
	public var stateVars:Object = {};
	public var lastPollResponseTime:int;
	public var problem:String = '';
	public var success:String = 'Okay';
	public var nextID:int;
	public var busy:Array = [];
	public var waiting:Dictionary = new Dictionary(true);

	public function ScratchExtension(name:String, port:int) {
		this.name = name;
		this.port = port;
	}

	private static function getExtensionURL(extensionName:String):String {
		var path:String = Scratch.app.isOffline ? '' : '/scratchr2/';

		path += 'static/js/scratch_extensions/' + extensionName;

		return path;
	}

	public static function PicoBoard():ScratchExtension {
		// Return a descriptor for the Scratch PicoBoard extension.
		var result:ScratchExtension = new ScratchExtension('PicoBoard', 0);
		result.isInternal = true;
		result.javascriptURL = getExtensionURL('picoExtension.js');
		result.thumbnailMD5 = '82318df0f682b1de33f64da8726660dc.png';
		result.url = 'http://wiki.scratch.mit.edu/wiki/Sensor_Board_Blocks';
		result.tags = ['hardware'];
		return result;
	}

	public static function WeDo():ScratchExtension {
		// Return a descriptor for the LEGO WeDo extension.
		var result:ScratchExtension = new ScratchExtension(ExtensionManager.wedoExt, 0);
		result.isInternal = true;
		result.javascriptURL = getExtensionURL('wedoExtension.js');
		result.thumbnailMD5 = 'c4a6bfa4cb9f4d71b3d1e65db63cb761.png';
		result.url = 'http://info.scratch.mit.edu/WeDo';
		result.tags = ['hardware'];
		return result;
	}

}}
