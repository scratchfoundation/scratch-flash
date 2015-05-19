/*
 * Scratch Project Editor and Player
 * Copyright (C) 2015 Massachusetts Institute of Technology
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

package util {
import flash.display.Loader;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.HTTPStatusEvent;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
import flash.net.URLRequestHeader;
import flash.net.URLRequestMethod;
import flash.utils.ByteArray;

public class ServerWeb extends Server {

	protected var URLs:Object = {};

	// -----------------------------
	// URL Helpers
	//------------------------------

	public function overrideURLs(overrides:Object):void {
		for (var name:String in overrides) {
			if (overrides.hasOwnProperty(name)) {
				URLs[name] = overrides[name];
			}
		}
	}

	protected function getCdnStaticSiteURL():String {
		var token:String = ScratchOnline.app.getCdnToken();
		if (token) token = '__' + token + '__/';
		else token = '';

		return URLs.siteCdnPrefix + URLs.staticFiles + token;
	}

	// -----------------------------
	// Media Library
	//------------------------------

	override public function getThumbnail(idAndExt:String, w:int, h:int, whenDone:Function):URLLoader {
		function decodeImage(data:ByteArray):void {
			if (!data || data.length == 0) return; // no data
			var decoder:Loader = new Loader();
			decoder.contentLoaderInfo.addEventListener(Event.COMPLETE, imageDecoded);
			decoder.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, imageError);
			decoder.loadBytes(data);
		}
		function imageError(e:IOErrorEvent):void {
			Scratch.app.log('ServerOnline failed to decode image: ' + idAndExt);
		}
		function imageDecoded(e:Event):void {
			whenDone(e.target.content.bitmapData);
		}
		var url:String = getCdnStaticSiteURL() + 'medialibrarythumbnails/' + idAndExt;
		return serverGet(url, decodeImage);
	}

	override public function getMediaLibrary(libraryType:String, whenDone:Function):URLLoader {
		var url:String = getCdnStaticSiteURL() + 'medialibraries/'+libraryType+'Library.json';
		return serverGet(url, whenDone);
	}

	// -----------------------------
	// Server GET/POST
	//------------------------------

	protected function serverGet(url:String, whenDone:Function):URLLoader {
		return callServer(url, null, null, whenDone);
	}

	protected function callServer(url:String, data:*, mimeType:String, whenDone:Function, queryParams:Object=null):URLLoader {
		// Make a GET or POST request to the given URL (do a POST if the data is not null).
		// The whenDone() function is called when the request is done, either with the
		// data returned by the server or with a null argument if the request failed.
		// The request includes site and session authentication headers.

		function completeHandler(e:Event):void {
			whenDone(loader.data);
		}
		function errorHandler(err:ErrorEvent):void {
//			if(err.type != IOErrorEvent.IO_ERROR || url.indexOf('/backpack/') == -1) {
//				if(data)
//					Scratch.app.logMessage('Failed server request for '+url+' with data ['+data+']');
//				else
//					Scratch.app.logMessage('Failed server request for '+url);
//			}
			if(data || url.indexOf('/set/') > -1) {
				// TEMPORARY HOTFIX: Don't send this message since it seems to saturate our logging backend.
				//Scratch.app.logMessage('Failed server request for '+url+' with data ['+data+']');
				trace('Failed server request for '+url+' with data ['+data+']');
			}
			whenDone(null);
		}
		function statusHandler(e:HTTPStatusEvent):void {
			if(e.status == 403 && data) {
				ScratchOnline.app.handleExternalLogout();
			}
		}

		var loader:URLLoader = new URLLoader();
		loader.dataFormat = URLLoaderDataFormat.BINARY;
		loader.addEventListener(Event.COMPLETE, completeHandler);
		loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
		loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
		loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, statusHandler);

		// Add a cache breaker if we're sending data and the url has no query string.
		var nextSeparator:String = '?';
		if(data && url.indexOf('?') == -1) {
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

			if(mimeType) request.requestHeaders.push(new URLRequestHeader("Content-type", mimeType));

			// header for CSRF authentication when sending data
			var csrfCookie:String = getCSRF();
			if (csrfCookie && (csrfCookie.length > 0)) {
				request.requestHeaders.push(new URLRequestHeader('X-CSRFToken', csrfCookie));
			}
		}

		loader.load(request);
		return loader;
	}

	public function getCSRF():String {
		return null;
	}
}
}
