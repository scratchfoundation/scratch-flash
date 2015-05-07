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
import flash.events.*;
import flash.net.*;
import flash.net.FileReference;
import flash.net.URLLoader;
import flash.utils.ByteArray;
import flash.utils.clearInterval;
import flash.utils.setInterval;

import mx.utils.URLUtil;

import org.osmf.utils.URL;

import uiwidgets.DialogBox;
import util.Multipart;

public class ExtensionManagerOnline extends ExtensionManager {

	public var localExt:ScratchExtension = null;
	public var localFilePoller:uint = 0;
	private var localFileRef:FileReference;
	private var localExtSaved:Boolean = true;
	private var appOnline:ScratchOnline;
	public function ExtensionManagerOnline(app:ScratchOnline) {
		super(app);
		appOnline = app;
	}

	public function getLocalFileName(ext:ScratchExtension = null):String {
		if(localFileRef && (ext === localExt || ext == null)) return localFileRef.name;

		return null;
	}

	public function isLocalExtensionSaved():Boolean {
		return !localExt || (localExtSaved && !localFileDirty);
	}

	public function isLocalExtensionDirty(ext:ScratchExtension = null):Boolean {
		return (!ext || ext == localExt) && localExt && localFileDirty;
	}

	override public function extensionsToSave():Array {
		var result:Array = super.extensionsToSave();

		// Add extension ids to the list of extensions
		for each (var extObj:Object in result) {
			var ext:ScratchExtension = extensionDict[extObj.extensionName];
			if(ext && extObj.javascriptURL && ext.id)
				extObj.id = ext.id;
		}

		return result;
	}

	override public function loadSavedExtensions(savedExtensions:Array):void {
		if (!savedExtensions) return;

		// Filter out extensions that are trying to load and shouldn't
		var filteredExtensions:Array = [];
		for(var i:int=0; i<savedExtensions.length; ++i) {
			var extObj:Object = savedExtensions[i];

			var url:String = extObj.javascriptURL;
			extObj.isInternal = isScratchExtension(extObj);
			if (url) {
				if (URLUtil.isHttpURL(url)) {
					var httpHost:String = URLUtil.getServerName(url);
					if (httpHost == 'scratch.mit.edu') {
						url = (new URL(url)).path;
					}
				}

				if(ScratchOnline.app.projectIsPrivate && isDeveloperExtensionURL(url) || extObj.isInternal) {
					extObj.javascriptURL = url;
					filteredExtensions.push(extObj);
				}
			}
			else if (extObj.isInternal || ScratchOnline.app.projectIsPrivate) {
				filteredExtensions.push(extObj);
			}
		}

		super.loadSavedExtensions(filteredExtensions);
	}

	private function isDeveloperExtensionURL(url:String):Boolean {
		return url && url.indexOf('/extensions/') === 0;
	}

	private function isScratchExtension(ext:Object):Boolean {
		return Scratch.app.extensionManager.isInternal(ext.extensionName) ||
				(ext.javascriptURL && ext.javascriptURL.indexOf('/scratchr2/') === 0);
	}

	// Override so that we can keep the reference to the local extension
	private var rawExtensionLoaded:Boolean = false;
	override public function loadRawExtension(extObj:Object):ScratchExtension {
		var ext:ScratchExtension = extensionDict[extObj.extensionName];
		var isLocalExt:Boolean = (localExt && ext == localExt) || (localFilePoller && !localExt);
		ext = super.loadRawExtension(extObj);
		if(isLocalExt) {
			if(!localExt) {
				DialogBox.notify('Extensions', 'Your local extension "' + ext.name +
						'" is now loaded.The editor will notice when ' + localFileRef.name +
						' is\nsaved and offer you to reload the extension. Reloading an extension will stop the project.');
				ext.id = 0;
			}
			localExt = ext;
			localExtSaved = false;
			appOnline.updatePalette();
			appOnline.setSaveNeeded();
		}

		rawExtensionLoaded = true;
		return ext;
	}

	// -----------------------------
	// Javascript Extension Development
	//------------------------------

	private var localFileDirty:Boolean;
	public function loadAndWatchExtensionFile(ext:ScratchExtension = null):void {
		if(localExt || localFilePoller > 0) {
			var msg:String = 'Sorry, a new extension cannot be created while another extension is connected to a file. ' +
					'Please save the project and disconnect from ' + localFileRef.name + ' first.';
			DialogBox.notify('Extensions', msg);
			return;
		}

		var filter:FileFilter = new FileFilter('Scratch 2.0 Javascript Extension', '*.js');
		var self:ExtensionManagerOnline = this;
		Scratch.loadSingleFile(function(e:Event):void {
			FileReference(e.target).removeEventListener(Event.COMPLETE, arguments.callee);
			FileReference(e.target).addEventListener(Event.COMPLETE, self.extensionFileLoaded);
			self.localExt = ext;
			self.extensionFileLoaded(e);
		}, [filter]);
	}

	public function stopWatchingExtensionFile():void {
		if(localFilePoller>0) clearInterval(localFilePoller);
		localExt = null;
		localFilePoller = 0;
		localFileDirty = false;
		localFileRef = null;
		localExtSaved = true;
		localExtCodeDate = null;
		appOnline.updatePalette();
	}

	private var localExtCodeDate:Date = null;
	private function extensionFileLoaded(e:Event):void {
		localFileRef = FileReference(e.target);
		var lastModified:Date = localFileRef.modificationDate;
		var self:ExtensionManagerOnline = this;
		localFilePoller = setInterval(function():void {
			if(lastModified.getTime() != self.localFileRef.modificationDate.getTime()) {
				lastModified = self.localFileRef.modificationDate;
				self.localFileDirty = true;
				clearInterval(self.localFilePoller);
				// Shutdown the extension
				self.localFileRef.load();
			}
		}, 200);

		if(localFileDirty && localExt) {
			//DialogBox.confirm('Reload the "' + localExt.name + '" from ' + localFileRef.name + '?', null, loadLocalCode);
			appOnline.updatePalette();
			appOnline.updateSaveStatus();
		}
		else
			loadLocalCode();
	}

	public function getLocalCodeDate():Date {
		return localExtCodeDate;
	}

	public function loadLocalCode(db:DialogBox = null):void {
		Scratch.app.runtime.stopAll();

		if(localExt) appOnline.externalCall('ScratchExtensions.unregister', null, localExt.name);

		localFileDirty = false;
		rawExtensionLoaded = false;
		localExtCodeDate = localFileRef.modificationDate;
		appOnline.externalCall('ScratchExtensions.loadLocalJS', null, localFileRef.data.toString());
//		if(!rawExtensionLoaded)
//			DialogBox.notify('Extensions', 'There was a problem loading your extension code. Please check your javascript console and fix the code.');

		appOnline.updateSaveStatus();
		appOnline.updatePalette();
	}

	override public function setEnabled(extName:String, flag:Boolean):void {
		var ext:ScratchExtension = extensionDict[extName];
		if(ext && localExt === ext && !flag) {
			stopWatchingExtensionFile();
		}

		super.setEnabled(extName, flag);
	}

	public function saveLocalExtension(whenDone:Function = null):void {
		//return !!localExtCode;
		if (localFileDirty) {
			appOnline.updateSaveStatus();
			DialogBox.confirm('Your latest extension changes must be tested first. Reload the "' + localExt.name + '" from ' + localFileRef.name + '?', null, loadLocalCode);
			return;
		}

		var loader:URLLoader = saveExtension(localExt.name, localExt.id, localFileRef.data, localFileRef.name);
		var self:ExtensionManagerOnline = this;
		loader.addEventListener(Event.COMPLETE, function(evt:Event):void {
			self.onExtensionUploaded(evt);
			if(whenDone != null) whenDone();
		});
	}

	public function saveExtension(name:String, id:uint, data:ByteArray, fileName:String = ''):URLLoader {
		var multipart:Multipart = new Multipart(appOnline.serverOnline.getExtensionURL() + 'upload/');
		multipart.addFile('extension_file', data, 'application/javascript', fileName);
		multipart.addField('title', name);
		if(id>0) multipart.addField('extension_id', id.toString());

		var req:URLRequest = multipart.request;

		// header for CSRF authentication
		var csrfCookie:String = appOnline.serverOnline.getCSRF();
		if (csrfCookie && (csrfCookie.length > 0)) {
			req.requestHeaders.push(new URLRequestHeader('X-CSRFToken', csrfCookie));
		}

		var loader:URLLoader = new URLLoader();
		loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onUploadHTTPStatus);
		loader.load(req);

		return loader;
	}

	private function onUploadHTTPStatus(e:HTTPStatusEvent):void {
		trace('Server replied with: '+e);
	}

	private function onExtensionUploaded(e:Event):void {
		var loader:URLLoader = e.target as URLLoader;
		var json:Object = util.JSON.parse(loader.data);
		localExt.javascriptURL = json.url;
		localExt.id = json.id;
		localExtSaved = true;
		appOnline.updatePalette();
		appOnline.updateSaveStatus();
	}
}}
