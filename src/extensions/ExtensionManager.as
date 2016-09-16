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

// ExtensionManager.as
// John Maloney, September 2011
//
// Scratch extension manager. Maintains a dictionary of all extensions in use and manages
// socket-based communications with local and server-based extension helper applications.

package extensions {
import blocks.Block;

import com.adobe.utils.StringUtil;

import flash.errors.IllegalOperationError;
import flash.events.*;
import flash.net.*;
import flash.utils.Dictionary;
import flash.utils.getTimer;

import interpreter.*;

import mx.utils.URLUtil;

import uiwidgets.DialogBox;
import uiwidgets.IndicatorLight;

import util.*;

public class ExtensionManager {

	protected var app:Scratch;
	protected var extensionDict:Object = new Object(); // extension name -> extension record
	private var justStartedWait:Boolean;
	private var pollInProgress:Dictionary = new Dictionary(true);
	static public const extensionSeparator:String = '\u001F';
	static public const extensionSeparatorLegacy:String = '.';
	static public const picoBoardExt:String = 'PicoBoard';
	static public const wedoExt:String = 'LEGO WeDo';
	static public const wedo2Ext:String = 'LEGO WeDo 2.0';

	// Experimental extensions must be hosted on one of these domains
	// These should start with '.' to avoid accepting things like 'malicious.not_github.io'
	static public const allowedDomains:Vector.<String> = new <String>[
			'.github.io',
			'.coding.me'
	];

	public function ExtensionManager(app:Scratch) {
		this.app = app;
		clearImportedExtensions();
	}

	public function extensionActive(extName:String):Boolean {
		return extensionDict.hasOwnProperty(extName);
	}

	public function isInternal(extName:String):Boolean {
		return (extensionDict.hasOwnProperty(extName) && extensionDict[extName].isInternal);
	}

	public function clearImportedExtensions():void {
		for each(var ext:ScratchExtension in extensionDict) {
			if(ext.showBlocks)
				setEnabled(ext.name, false);
		}

		// Clear imported extensions before loading a new project.
		extensionDict = {};
		extensionDict[picoBoardExt] = ScratchExtension.PicoBoard();
		extensionDict[wedoExt] = ScratchExtension.WeDo();
		extensionDict[wedo2Ext] = ScratchExtension.WeDo2();
	}

	// Should the interpreter force async communication with extensions?
	// For example, should 'r' be treated as 'R'?
	public function shouldForceAsync(op:String):Boolean {
		// Non-extension blocks shouldn't be forceAsync
		var extensionName:String = unpackExtensionName(op);
		if (!extensionName) return false;

		var extension:ScratchExtension = extensionDict[extensionName];
		if (extension && extension.port != 0) {
			// HTTP extensions should never be forceAsync
			return false;
		}
		else {
			// JS extensions should be forceAsync in the offline editor.
			// If the extension is not loaded, guess that it's JS. Really that shouldn't ever happen...
			return app.isOffline;
		}
	}

	// -----------------------------
	// Block Specifications
	//------------------------------

	// Return a command spec array for the given operation or null.
	public function specForCmd(op:String):Array {
		for each (var ext:ScratchExtension in extensionDict) {
			for each (var spec:Array in ext.blockSpecs) {
				if (spec.length > 2) {
					var compareOp:String = ext.useScratchPrimitives ?
							spec[2] : (ext.name + extensionSeparator + spec[2]);
					var legacyOp:String = ext.useScratchPrimitives ?
							spec[2] : (ext.name + extensionSeparatorLegacy + spec[2]);
					if (op == compareOp || op == legacyOp) {
						// return using compareOp to upgrade from legacy separator
						return [spec[1], spec[0], Specs.extensionsCategory, compareOp, spec.slice(3)];
					}
				}
			}
		}
		return null;
	}

	// Check whether `prefixedOp` is prefixed with an extension name.
	public static function hasExtensionPrefix(prefixedOp:String):Boolean {
		return prefixedOp.indexOf(extensionSeparator) >= 0;
	}

	// Retrieve the extension name from `prefixedOp`.
	// If `prefixedOp` doesn't have an extension prefix, return `null`.
	public static function unpackExtensionName(prefixedOp:String):String {
		var separatorPosition:int = prefixedOp.indexOf(extensionSeparator);
		if (separatorPosition < 0) {
			return null;
		}
		else {
			return prefixedOp.substr(0, separatorPosition);
		}
	}

	// Unpack `prefixedOp` into `[extensionName, op]`
	// If `prefixedOp` doesn't have an extension prefix, return `[null, prefixedOp]`
	public static function unpackExtensionAndOp(prefixedOp:String):Array {
		var separatorPosition:int = prefixedOp.indexOf(extensionSeparator);
		if (separatorPosition < 0) {
			return [null, prefixedOp];
		}
		else {
			return [prefixedOp.substr(0, separatorPosition), prefixedOp.substr(separatorPosition+1)];
		}
	}

	// -----------------------------
	// Enable/disable/reset
	//------------------------------

	public function setEnabled(extName:String, flag:Boolean):void {
		var ext:ScratchExtension = extensionDict[extName];
		if (ext && ext.showBlocks != flag) {
			ext.showBlocks = flag;
			if(app.jsEnabled && ext.javascriptURL) {
				if(flag) {
					var javascriptURL:String = ext.isInternal ? Scratch.app.fixExtensionURL(ext.javascriptURL) : ext.javascriptURL;
					app.externalCall('ScratchExtensions.loadExternalJS', null, javascriptURL);
					ext.showBlocks = false; // Wait for it to load
				}
				else {
					app.externalCall('ScratchExtensions.unregister', null, extName);
					if(!ext.isInternal) delete extensionDict[extName];
					app.updateTopBar();
				}
			}
		}
	}

	public function isEnabled(extName:String):Boolean {
		var ext:ScratchExtension = extensionDict[extName];
		return ext ? ext.showBlocks : false;
	}

	public function enabledExtensions():Array {
		// Answer an array of enabled extensions, sorted alphabetically.
		var result:Array = [];
		for each (var ext:ScratchExtension in extensionDict) {
			if (ext.showBlocks) result.push(ext);
		}
		result.sortOn('name');
		return result;
	}

	public function stopButtonPressed():* {
		// Send a reset_all command to all active extensions.
		for each (var ext:ScratchExtension in enabledExtensions()) {
			call(ext.name, 'reset_all', []);
		}
	}

	public function extensionsToSave():Array {
		// Answer an array of extension descriptor objects for imported extensions to be saved with the project.
		var result:Array = [];
		for each (var ext:ScratchExtension in extensionDict) {
			if(!ext.showBlocks) continue;

			var descriptor:Object = {};
			descriptor.extensionName = ext.name;
			descriptor.blockSpecs = ext.blockSpecs;
			descriptor.menus = ext.menus;
			if (ext.url) descriptor.url = ext.url;
			if(ext.port) descriptor.extensionPort = ext.port;
			else if(ext.javascriptURL) descriptor.javascriptURL = ext.javascriptURL;
			result.push(descriptor);
		}
		return result;
	}

	// -----------------------------
	// Communications
	//------------------------------

	public function callCompleted(extensionName:String, id:Number):void {
		var ext:ScratchExtension = extensionDict[extensionName];
		if (ext == null) return; // unknown extension

		var index:int = ext.busy.indexOf(id);
		if(index > -1) ext.busy.splice(index, 1);
	}

	public function reporterCompleted(extensionName:String, id:Number, retval:*):void {
		var ext:ScratchExtension = extensionDict[extensionName];
		if (ext == null) return; // unknown extension

		app.updateTopBar();

		var index:int = ext.busy.indexOf(id);
		if(index > -1) {
			ext.busy.splice(index, 1);
			for(var b:Object in ext.waiting) {
				if(ext.waiting[b] == id) {
					delete ext.waiting[b];
					(b as Block).response = retval;
					(b as Block).requestState = 2;
				}
			}
		}
	}

	// -----------------------------
	// Loading
	//------------------------------

	public function loadCustom(ext:ScratchExtension):void {
		if(!extensionDict[ext.name] && ext.javascriptURL) {
			extensionDict[ext.name] = ext;
			ext.showBlocks = false;
			setEnabled(ext.name, true);
		}
	}

	public function loadRawExtension(extObj:Object):ScratchExtension {
		var ext:ScratchExtension = extensionDict[extObj.extensionName];
		if(!ext)
			ext = new ScratchExtension(extObj.extensionName, extObj.extensionPort);
		ext.port = extObj.extensionPort;
		ext.blockSpecs = extObj.blockSpecs;
		if (extObj.url) ext.url = extObj.url;
		ext.showBlocks = true;
		ext.menus = extObj.menus;
		ext.javascriptURL = extObj.javascriptURL;
		if (extObj.host) ext.host = extObj.host; // non-local host allowed but not saved in project
		extensionDict[extObj.extensionName] = ext;
		Scratch.app.translationChanged();
		Scratch.app.updatePalette();

		// Update the indicator
		for (var i:int = 0; i < app.palette.numChildren; i++) {
			var indicator:IndicatorLight = app.palette.getChildAt(i) as IndicatorLight;
			if (indicator && indicator.target === ext) {
				updateIndicator(indicator, indicator.target, true);
				break;
			}
		}

		return ext;
	}

	public function loadSavedExtensions(savedExtensions:Array):void {
		function extensionRefused(extObj:Object, reason: String):void {
			Scratch.app.jsThrowError('Refusing to load project extension "' + extObj.extensionName + '": ' + reason);
		}

		// Reset the system extensions and load the given array of saved extensions.
		if (!savedExtensions) return; // no saved extensions
		for each (var extObj:Object in savedExtensions) {
			if (isInternal(extObj.extensionName)) {
				setEnabled(extObj.extensionName, true);
				continue; // internal extension overrides one saved in project
			}

			if (!('extensionName' in extObj)) {
				Scratch.app.jsThrowError('Refusing to load project extension without a name.');
				continue;
			}

			if (!('extensionPort' in extObj) && !('javascriptURL' in extObj)) {
				extensionRefused(extObj, 'No location specified.');
				continue;
			}

			if (!('blockSpecs' in extObj)) {
				// TODO: resolve potential confusion when the project blockSpecs don't match those in the JS.
				extensionRefused(extObj, 'No blockSpecs.');
				continue;
			}

			var ext:ScratchExtension = new ScratchExtension(extObj.extensionName, extObj.extensionPort || 0);
			ext.blockSpecs = extObj.blockSpecs;
			if (extObj.url) ext.url = extObj.url;
			ext.showBlocks = true;
			ext.isInternal = false;
			ext.menus = extObj.menus;
			if(extObj.javascriptURL) {
				if (!Scratch.app.isExtensionDevMode) {
					extensionRefused(extObj, 'Experimental extensions are only supported on ScratchX.');
					continue;
				}
				var domainAllowed:Boolean = false;
				var url:String = URLUtil.getServerName(extObj.javascriptURL).toLowerCase();
				for (var i:int = 0; i < allowedDomains.length; ++i) {
					if (StringUtil.endsWith(url, allowedDomains[i])) {
						domainAllowed = true;
						break;
					}
				}
				if (!domainAllowed) {
					extensionRefused(
							extObj,
							'Experimental extensions must be hosted on an approved domain. Approved domains are: ' +
							allowedDomains.join(', '));
					continue;
				}
				ext.javascriptURL = extObj.javascriptURL;
				ext.showBlocks = false;
				if(extObj.id) ext.id = extObj.id;
			}

			extensionDict[extObj.extensionName] = ext;
			setEnabled(extObj.extensionName, true);
		}
		Scratch.app.updatePalette();
		Scratch.app.translationChanged();
	}

	// -----------------------------
	// Menu Support
	//------------------------------

	public function menuItemsFor(op:String, menuName:String):Array {
		// Return a list of menu items for the given menu of the extension associated with op or null.
		var extName:String = unpackExtensionName(op);
		if (!extName) return null;
		var ext:ScratchExtension = extensionDict[extName];
		if (!ext || !ext.menus) return null; // unknown extension
		return ext.menus[menuName];
	}

	// -----------------------------
	// Status Indicator
	//------------------------------

	public function updateIndicator(indicator:IndicatorLight, ext:ScratchExtension, firstTime:Boolean = false):void {
		if(ext.port > 0) {
			var msecsSinceLastResponse:uint = getTimer() - ext.lastPollResponseTime;
			if (msecsSinceLastResponse > 500) indicator.setColorAndMsg(0xE00000, 'Cannot find helper app');
			else if (ext.problem != '') indicator.setColorAndMsg(0xE0E000, ext.problem);
			else indicator.setColorAndMsg(0x00C000, ext.success);
		}
		else if(app.jsEnabled) {
			function statusCallback(retval:Object):void {
				if(!retval) retval = {status: 0, msg: 'Cannot communicate with extension.'};

				var color:uint;
				if(retval.status == 2) color = 0x00C000;
				else if(retval.status == 1) color = 0xE0E000;
				else {
					color = 0xE00000;
					if(firstTime) {
						Scratch.app.showTip('extensions');
//					DialogBox.notify('Extension Problem', 'It looks like the '+ext.name+' is not working properly.' +
//							'Please read the extensions help in the tips window.', Scratch.app.stage);
						DialogBox.notify('Extension Problem', 'See the Tips window (on the right) to install the plug-in and get the extension working.');
					}
				}

				indicator.setColorAndMsg(color, retval.msg);
			}

			app.externalCall('ScratchExtensions.getStatus', statusCallback, ext.name);
		}
	}

	// -----------------------------
	// Execution
	//------------------------------

	public function primExtensionOp(b:Block):* {
		var unpackedOp:Array = unpackExtensionAndOp(b.op);
		var extName:String = unpackedOp[0];
		var ext:ScratchExtension = extensionDict[extName];
		if (ext == null) return 0; // unknown extension
		var primOrVarName:String = unpackedOp[1];
		var args:Array = [];
		for (var i:int = 0; i < b.args.length; i++) {
			args.push(app.interp.arg(b, i));
		}

		var value:*;
		if(b.isHat && b.isAsyncHat){
			if(b.requestState == 0){
				request(extName, primOrVarName, args, b);
				app.interp.doYield();
				return null;
			}
			else if(b.requestState == 2){
				b.requestState = 0;
				if(b.forceAsync){
					value = b.response as Boolean;
				}
				else{
					var responseObj:Object = b.response as Object;
					args.push(responseObj);
					if(responseObj && responseObj.hasOwnProperty('predicate')){
						app.externalCall('ScratchExtensions.getReporter', function(v:*):void {
							value = v;
						}, ext.name, responseObj.predicate, args);
					}
					else{
						value = true;
					}
				}
				if(value){
					if(!app.runtime.waitingHatFired(b, true)){
						app.interp.doYield();
					}
				}
				else{
					app.interp.doYield();
					app.runtime.waitingHatFired(b, false);
				}
			}
			else{
				app.interp.doYield();
			}
			return;
		}
		else if (b.isReporter) {
			if(b.isRequester) {
				if(b.requestState == 2) {
					b.requestState = 0;
					return b.response;
				}
				else if(b.requestState == 0) {
					request(extName, primOrVarName, args, b);
				}

				// Returns null if we just made a request or we're still waiting
				return null;
			}
			else {
				var sensorName:String = primOrVarName;
				if(ext.port > 0) {  // we were checking ext.isInternal before, should we?
					sensorName = encodeURIComponent(sensorName);
					for each (var a:* in args) sensorName += '/' + encodeURIComponent(a); // append menu args
					value = ext.stateVars[sensorName];
				}
				else if(Scratch.app.jsEnabled) {
					// JavaScript
					if (Scratch.app.isOffline) {
						throw new IllegalOperationError("JS reporters must be requesters in Offline.");
					}
					app.externalCall('ScratchExtensions.getReporter', function(v:*):void {
						value = v;
					}, ext.name, sensorName, args);
				}
				if (value == undefined) value = 0; // default to zero if missing
				if ('b' == b.type) value = (ext.port>0 ? 'true' == value : true == value); // coerce value to a boolean
				return value;
			}
		} else {
			if ('w' == b.type) {
				var activeThread:Thread = app.interp.activeThread;
				if (activeThread.firstTime) {
					var id:int = ++ext.nextID; // assign a unique ID for this call
					ext.busy.push(id);
					activeThread.tmp = id;
					app.interp.doYield();
					justStartedWait = true;

					if(ext.port == 0) {
						activeThread.firstTime = false;
						if(app.jsEnabled)
							app.externalCall('ScratchExtensions.runAsync', null, ext.name, primOrVarName, args, id);
						else
							ext.busy.pop();

						return;
					}

					args.unshift(id); // pass the ID as the first argument
				} else {
					if (ext.busy.indexOf(activeThread.tmp) > -1) {
						app.interp.doYield();
					} else {
						activeThread.tmp = 0;
						activeThread.firstTime = true;
					}
					return;
				}
			}
			call(extName, primOrVarName, args);
		}
	}

	public function call(extensionName:String, op:String, args:Array):void {
		var ext:ScratchExtension = extensionDict[extensionName];
		if (ext == null) return; // unknown extension
		if (ext.port > 0) {
			var activeThread:Thread = app.interp.activeThread;
			if(activeThread && op != 'reset_all') {
				if(activeThread.firstTime) {
					httpCall(ext, op, args);
					activeThread.firstTime = false;
					app.interp.doYield();
				}
				else {
					activeThread.firstTime = true;
				}
			}
			else {
				httpCall(ext, op, args);
			}
		} else {
			if (Scratch.app.jsEnabled) {
				if (op == 'reset_all') {
					app.externalCall('ScratchExtensions.stop', null, ext.name);
				}
				else {
					// call a JavaScript extension function with the given arguments
					app.externalCall('ScratchExtensions.runCommand', null, ext.name, op, args);
				}
			}

			app.interp.redraw(); // make sure interpreter doesn't do too many extension calls in one cycle
		}
	}

	public function request(extensionName:String, op:String, args:Array, b:Block):void {
		var ext:ScratchExtension = extensionDict[extensionName];
		if (ext == null) {
			// unknown extension, skip the block
			b.requestState = 2;
			return;
		}

		if (ext.port > 0) {
			httpRequest(ext, op, args, b);
		} else if(Scratch.app.jsEnabled) {
			// call a JavaScript extension function with the given arguments
			b.requestState = 1;
			++ext.nextID;
			ext.busy.push(ext.nextID);
			ext.waiting[b] = ext.nextID;

			if (b.forceAsync) {
				// We're forcing a non-requester to be treated as a requester
				app.externalCall('ScratchExtensions.getReporterForceAsync', null, ext.name, op, args, ext.nextID);
			} else {
				// Normal request
				app.externalCall('ScratchExtensions.getReporterAsync', null, ext.name, op, args, ext.nextID);
			}
		}
	}

	private function httpRequest(ext:ScratchExtension, op:String, args:Array, b:Block):void {
		function responseHandler(e:Event):void {
			if(e.type == Event.COMPLETE)
				b.response = loader.data;
			else
				b.response = '';

			b.requestState = 2;
			b.requestLoader = null;
		}

		var loader:URLLoader = new URLLoader();
		loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, responseHandler);
		loader.addEventListener(IOErrorEvent.IO_ERROR, responseHandler);
		loader.addEventListener(Event.COMPLETE, responseHandler);

		b.requestState = 1;
		b.requestLoader = loader;

		var url:String = 'http://' + ext.host + ':' + ext.port + '/' + encodeURIComponent(op);
		for each (var arg:* in args) {
			url += '/' + ((arg is String) ? encodeURIComponent(arg) : arg);
		}
		loader.load(new URLRequest(url));
	}

	private function httpCall(ext:ScratchExtension, op:String, args:Array):void {
		function errorHandler(e:Event):void { } // ignore errors
		var url:String = 'http://' + ext.host + ':' + ext.port + '/' + encodeURIComponent(op);
		for each (var arg:* in args) {
			url += '/' + ((arg is String) ? encodeURIComponent(arg) : arg);
		}
		var loader:URLLoader = new URLLoader();
		loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
		loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
		loader.load(new URLRequest(url));
	}

	public function getStateVar(extensionName:String, varName:String, defaultValue:*):* {
		var ext:ScratchExtension = extensionDict[extensionName];
		if (ext == null) return defaultValue; // unknown extension
		var value:* = ext.stateVars[encodeURIComponent(varName)];
		return (value == undefined) ? defaultValue : value;
	}

	// -----------------------------
	// Polling
	//------------------------------

	public function step():void {
		// Poll all extensions.
		for each (var ext:ScratchExtension in extensionDict) {
			if (ext.showBlocks) {
				if (!ext.isInternal && ext.port > 0) {
					if (ext.blockSpecs.length == 0) httpGetSpecs(ext);
					httpPoll(ext);
				}
			}
		}
	}

	private function httpGetSpecs(ext:ScratchExtension):void {
		// Fetch the block specs (and optional menu specs) from the helper app.
		function completeHandler(e:Event):void {
			var specsObj:Object;
			try {
				specsObj = util.JSON.parse(loader.data);
			} catch(e:*) {}
			if (!specsObj) return;
			// use the block specs and (optionally) menu returned by the helper app
			if (specsObj.blockSpecs) ext.blockSpecs = specsObj.blockSpecs;
			if (specsObj.menus) ext.menus = specsObj.menus;
		}
		function errorHandler(e:Event):void { } // ignore errors
		var url:String = 'http://' + ext.host + ':' + ext.port + '/get_specs';
		var loader:URLLoader = new URLLoader();
		loader.addEventListener(Event.COMPLETE, completeHandler);
		loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
		loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
		loader.load(new URLRequest(url));
	}

	private function httpPoll(ext:ScratchExtension):void {

		if (pollInProgress[ext]) {
			// Don't poll again if there's already one in progress.
			// This can happen a lot if the connection is timing out.
			return;
		}

		// Poll via HTTP.
		function completeHandler(e:Event):void {
			delete pollInProgress[ext];
			processPollResponse(ext, loader.data);
		}
		function errorHandler(e:Event):void {
			// ignore errors
			delete pollInProgress[ext];
		}
		var url:String = 'http://' + ext.host + ':' + ext.port + '/poll';
		var loader:URLLoader = new URLLoader();
		loader.addEventListener(Event.COMPLETE, completeHandler);
		loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
		loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
		pollInProgress[ext] = true;
		loader.load(new URLRequest(url));
	}

	private function processPollResponse(ext:ScratchExtension, response:String):void {
		if (response == null) return;
		ext.lastPollResponseTime = getTimer();
		ext.problem = '';

		// clear the busy list unless we just started a command that waits
		if (justStartedWait) justStartedWait = false;
		else ext.busy = [];

		var i:int;
		var lines:Array = response.split('\n');
		for each (var line:String in lines) {
			i = line.indexOf(' ');
			if (i == -1) i = line.length;
			var key:String = line.slice(0, i);
			var value:String = decodeURIComponent(line.slice(i + 1));
			switch (key) {
			case '_busy':
				for each (var token:String in value.split(' ')) {
					var id:int = parseInt(token);
					if (ext.busy.indexOf(id) == -1) ext.busy.push(id);
				}
				break;
			case '_problem':
				ext.problem = value;
				break;
			case '_success':
				ext.success = value;
				break;
			default:
				var n:Number = Interpreter.asNumber(value);
				var path:Array = key.split('/');
				for (i = 0; i < path.length; i++) {
					// normalize URL encoding for each path segment
					path[i] = encodeURIComponent(decodeURIComponent(path[i]));
				}
				ext.stateVars[path.join('/')] = n == n ? n : value;
			}
		}
	}

	public function hasExperimentalExtensions():Boolean {
		for each (var ext:ScratchExtension in extensionDict) {
			if (!ext.isInternal && ext.javascriptURL) {
				return true;
			}
		}
		return false;
	}
}}
