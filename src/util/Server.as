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

// ServerOffline.as
// John Maloney, June 2013
//
// Interface to the Scratch website API's for Offline Editor.
//
// Note: All operations call the whenDone function with the result
// if the operation succeeded or null if it failed.

package util {
import by.blooddy.crypto.serialization.JSON;

import flash.display.BitmapData;
import flash.display.Loader;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.HTTPStatusEvent;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.geom.Matrix;
import flash.net.SharedObject;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
import flash.net.URLRequestHeader;
import flash.net.URLRequestMethod;
import flash.system.Capabilities;
import flash.system.Security;
import flash.utils.ByteArray;

import logging.LogLevel;

import mx.utils.URLUtil;

public class Server implements IServer {

	protected var URLs:Object = {};

	public function Server() {
		setDefaultURLs();

		// Accept URL overrides from the flash variables
		try {
			var urlOverrides:String = Scratch.app.loaderInfo.parameters['urlOverrides'];
			if (urlOverrides) overrideURLs(by.blooddy.crypto.serialization.JSON.decode(urlOverrides));
		} catch (e:*) {
		}
	}

	// No default URLs
	protected function setDefaultURLs():void {}

	public function overrideURLs(overrides:Object):void {
		var forceProtocol:String;
		var swfURL:String = Scratch.app.loaderInfo.url;
		if (swfURL && URLUtil.isHttpURL(swfURL)) { // "isHttpURL" is true if the protocol is either HTTP or HTTPS
			forceProtocol = URLUtil.getProtocol(swfURL);
		}
		for (var name:String in overrides) {
			if (overrides.hasOwnProperty(name)) {
				var url:String = overrides[name];

				if (forceProtocol && URLUtil.isHttpURL(url)) {
					url = URLUtil.replaceProtocol(url, forceProtocol);
				}

				URLs[name] = url;
			}
		}
	}

	protected function getCdnStaticSiteURL():String {
		return URLs.siteCdnPrefix + URLs.staticFiles;
	}

	// Returns a URL for downloading the JS for an official extension given input like 'myExtension.js'
	public function getOfficialExtensionURL(extensionName:String):String {
		var path:String;

		if (Scratch.app.isOffline) {
			path = 'static/js/scratch_extensions/';
		}
		else if (Scratch.app.isExtensionDevMode) {
			path = 'scratch_extensions/';
		}
		else {
			// Skip the CDN when debugging to make iteration easier
			var extensionSite:String = Capabilities.isDebugger ? URLs.sitePrefix : URLs.siteCdnPrefix;
			path = extensionSite + URLs.staticFiles + 'js/scratch_extensions/';
		}

		path += extensionName;

		return path;
	}

	// -----------------------------
	// Server GET/POST
	//------------------------------

	// This will be called with the HTTP status result from any callServer() that receives one, even when successful.
	// The url and data parameters match those passed to callServer.
	protected function onCallServerHttpStatus(url:String, data:*, event:HTTPStatusEvent):void {
		if (event.status < 200 || event.status > 299) {
			Scratch.app.logMessage(event.toString());
		}
	}

	// This will be called if callServer encounters an error, before whenDone(null) is called.
	// The url and data parameters match those passed to callServer.
	protected function onCallServerError(url:String, data:*, event:ErrorEvent):void {
		// Don't send this as an error since it seems to saturate our logging backend.
		Scratch.app.log(LogLevel.WARNING, 'Failed server request', {event: event, url: url, data: data});
		// We shouldn't have SecurityErrorEvents unless the crossdomain file failed to load
		// Re-trying here should help project save failures but we'll need to add more code to re-try loading projects
		if (event is SecurityErrorEvent) {
			var urlPathStart:int = url.indexOf('/', 10);
			var policyFileURL:String = url.substr(0, urlPathStart) + '/crossdomain.xml?cb=' + Math.random();
			Security.loadPolicyFile(policyFileURL);
			Scratch.app.log(LogLevel.WARNING, 'Reloading policy file', {policy: policyFileURL, initiator: url});
		}
	}

	// This will be called if callServer encounters an exception, before whenDone(null) is called.
	// The url and data parameters match those passed to callServer.
	protected function onCallServerException(url:String, data:*, exception:*):void {
		if (exception is Error) {
			Scratch.app.logException(exception);
		}
	}

	// TODO: Maybe should have this or onCallServerError() but not both
	public var callServerErrorInfo:Object; // only valid during a whenDone() call reporting failure.

	// Make a GET or POST request to the given URL (do a POST if the data is not null).
	// The whenDone() function is called when the request is done, either with the
	// data returned by the server or with a null argument if the request failed.
	// The request includes site and session authentication headers.
	protected function callServer(url:String, data:*, mimeType:String, whenDone:Function,
	                              queryParams:Object = null):URLLoader {
		function addListeners():void {
			loader.addEventListener(Event.COMPLETE, completeHandler);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
			loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, statusHandler);
		}

		function removeListeners():void {
			loader.removeEventListener(Event.COMPLETE, completeHandler);
			loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			loader.removeEventListener(HTTPStatusEvent.HTTP_STATUS, statusHandler);
		}

		function completeHandler(event:Event):void {
			removeListeners();
			callServerErrorInfo = null;
			whenDone(loader.data);
		}

		var httpStatus:int = 0;

		function errorHandler(event:ErrorEvent):void {
			removeListeners();
			onCallServerError(url, data, event);
			callServerErrorInfo = {url: url, httpStatus: httpStatus, errorEvent: event};
			whenDone(null);
			callServerErrorInfo = null;
		}

		function exceptionHandler(exception:*):void {
			removeListeners();
			onCallServerException(url, data, exception);
			whenDone(null);
		}

		function statusHandler(e:HTTPStatusEvent):void {
			httpStatus = e.status;
			onCallServerHttpStatus(url, data, e);
		}

		var loader:URLLoader = new URLLoader();
		loader.dataFormat = URLLoaderDataFormat.BINARY;
		addListeners();

		// Add a cache breaker if we're sending data and the url has no query string.
		var nextSeparator:String = '?';
		if (data && url.indexOf('?') == -1) {
			url += '?v=' + Scratch.versionString + '&_rnd=' + Math.random();
			nextSeparator = '&';
		}
		for (var key:String in queryParams) {
			if (queryParams.hasOwnProperty(key)) {
				url += nextSeparator + encodeURIComponent(key) + '=' + encodeURIComponent(queryParams[key]);
				nextSeparator = '&';
			}
		}
		var request:URLRequest = new URLRequest(url);
		if (data) {
			request.method = URLRequestMethod.POST;
			request.data = data;

			if (mimeType) request.requestHeaders.push(new URLRequestHeader("Content-type", mimeType));

			// header for CSRF authentication when sending data
			var csrfCookie:String = getCSRF();
			if (csrfCookie && (csrfCookie.length > 0)) {
				request.requestHeaders.push(new URLRequestHeader('X-CSRFToken', csrfCookie));
			}

			if (data.length == 0) {
				// Flash's URLLoader will convert a POST with a zero-length body into a GET; apparently there's no way
				// to avoid that behavior.
				// Most Scratch servers will respond to this with error 403, leading to other problems down the road.
				// Since this situation likely means the asset is broken anyway, complain about it and skip the upload.
				// It's better to, for example, save a project with one missing asset than to fail the save altogether.
				onCallServerError(url, data, new ErrorEvent("Refusing to POST with empty body"));
				return loader;
			}
		}

		try {
			loader.load(request);
		} catch (e:*) {
			// Local sandbox exception?
			exceptionHandler(e);
		}
		return loader;
	}

	public function getCSRF():String {
		return null;
	}

	// Make a simple GET. Uses the same callbacks as callServer().
	public function serverGet(url:String, whenDone:Function):URLLoader {
		return callServer(url, null, null, whenDone);
	}

	// -----------------------------
	// Asset API
	//------------------------------
	public function getAsset(md5:String, whenDone:Function):URLLoader {
//		if (BackpackPart.localAssets[md5] && BackpackPart.localAssets[md5].length > 0) {
//			whenDone(BackpackPart.localAssets[md5]);
//			return null;
//		}
		var url:String = URLs.assetCdnPrefix + URLs.internalAPI + 'asset/' + md5 + '/get/';
		return serverGet(url, whenDone);
	}

	public function getMediaLibrary(libraryType:String, whenDone:Function):URLLoader {
		var url:String = getCdnStaticSiteURL() + 'medialibraries/' + libraryType + 'Library.json';
		return serverGet(url, whenDone);
	}

	protected function downloadThumbnail(url:String, w:int, h:int, whenDone:Function):URLLoader {
		function decodeImage(data:ByteArray):void {
			if (!data || data.length == 0) return; // no data
			var decoder:Loader = new Loader();
			decoder.contentLoaderInfo.addEventListener(Event.COMPLETE, imageDecoded);
			decoder.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, imageError);
			try {
				decoder.loadBytes(data);
			} catch (e:*) {
				if (e is Error) {
					Scratch.app.logException(e);
				}
				else {
					Scratch.app.logMessage('Server caught exception decoding image: ' + url);
				}
			}
		}

		function imageError(e:IOErrorEvent):void {
			Scratch.app.log(LogLevel.WARNING, 'ServerOnline failed to decode image', {url: url});
		}

		function imageDecoded(e:Event):void {
			whenDone(makeThumbnail(e.target.content.bitmapData));
		}

		return serverGet(url, decodeImage);
	}

	private static function makeThumbnail(bm:BitmapData):BitmapData {
		const tnWidth:int = 120;
		const tnHeight:int = 90;
		var result:BitmapData = new BitmapData(tnWidth, tnHeight, true, 0);
		if ((bm.width == 0) || (bm.height == 0)) return result;
		var scale:Number = Math.min(tnWidth / bm.width, tnHeight / bm.height);
		var m:Matrix = new Matrix();
		m.scale(scale, scale);
		m.translate((tnWidth - (scale * bm.width)) / 2, (tnHeight - (scale * bm.height)) / 2);
		result.draw(bm, m);
		return result;
	}

	public function getThumbnail(idAndExt:String, w:int, h:int, whenDone:Function):URLLoader {
		var url:String = getCdnStaticSiteURL() + 'medialibrarythumbnails/' + idAndExt;
		return downloadThumbnail(url, w, h, whenDone);
	}

	// -----------------------------
	// Translation Support
	//------------------------------

	public function getLanguageList(whenDone:Function):void {
		serverGet('locale/lang_list.txt', whenDone);
	}

	public function getPOFile(lang:String, whenDone:Function):void {
		serverGet('locale/' + lang + '.po', whenDone);
	}

	public function getSelectedLang(whenDone:Function):void {
		// Get the language setting.
		var sharedObj:SharedObject = SharedObject.getLocal('Scratch');
		if (sharedObj.data.lang) whenDone(sharedObj.data.lang);
	}

	public function setSelectedLang(lang:String):void {
		// Record the language setting.
		var sharedObj:SharedObject = SharedObject.getLocal('Scratch');
		if (lang == '') lang = 'en';
		sharedObj.data.lang = lang;
		sharedObj.flush();
	}
}
}
