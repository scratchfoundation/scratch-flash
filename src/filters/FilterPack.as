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

// FilterPack.as
// John Maloney, July 2010
//
// Scratch image filters. Uses compiled "pixel-bender" shaders for performance.
// Use setFilter() to set filter parameters. buildFilters() returns a list of filters
// to be assigned to the filters property of s DisplayObject (e.g. a sprite).

package filters {
	import flash.display.*;
	import flash.filters.*;
import flash.geom.ColorTransform;
import flash.system.Capabilities;
	import scratch.*;
	import util.*;

public class FilterPack {
	public static var filterNames:Array = [
		"color", "fisheye", "whirl", "pixelate", "mosaic", "brightness", "ghost"];

	public var targetObj:ScratchObj;
	private var filterDict:Object;

	[Embed(source="kernels/fisheye.pbj", mimeType="application/octet-stream")]
	private var FisheyeKernel:Class;
	private var fisheyeShader:Shader = new Shader(new FisheyeKernel());

	[Embed(source="kernels/hsv.pbj", mimeType="application/octet-stream")]
	private var HSVKernel:Class;
	private var hsvShader:Shader = new Shader(new HSVKernel());

	[Embed(source="kernels/mosaic.pbj", mimeType="application/octet-stream")]
	private var MosaicKernel:Class;
	private var mosaicShader:Shader = new Shader(new MosaicKernel());

	[Embed(source="kernels/pixelate.pbj", mimeType="application/octet-stream")]
	private var PixelateKernel:Class;
	private var pixelateShader:Shader = new Shader(new PixelateKernel());

	[Embed(source="kernels/whirl.pbj", mimeType="application/octet-stream")]
	private var WhirlKernel:Class;
	private var whirlShader:Shader = new Shader(new WhirlKernel());

	public function FilterPack(targetObj:ScratchObj) {
		this.targetObj = targetObj;
		this.filterDict = new Object();
		resetAllFilters();
	}

	public function getAllSettings():Object {
		return filterDict;
	}

	public function resetAllFilters():void {
		for (var i:int = 0; i < filterNames.length; i++) {
			filterDict[filterNames[i]] = 0;
		}
	}

	public function getFilterSetting(filterName:String):Number {
		var v:* = filterDict[filterName];
		if (!(v is Number)) return 0;
		return v;
	}

	public function setFilter(filterName:String, newValue:Number):Boolean {
		if (newValue != newValue) return false;
		if (filterName == "brightness") newValue = Math.max(-100, Math.min(newValue, 100));
		if (filterName == "color") newValue = newValue % 200;
		if (filterName == "ghost") newValue = Math.max(0, Math.min(newValue, 100));

		var oldValue:Number = filterDict[filterName];
		filterDict[filterName] = newValue;

		return (newValue != oldValue);
	}

	public function duplicateFor(target:ScratchObj):FilterPack {
		var result:FilterPack = new FilterPack(target);
		for (var i:int = 0; i < filterNames.length; i++) {
			var fName:String = filterNames[i];
			result.setFilter(fName, filterDict[fName]);
		}
		return result;
	}

	private static var emptyArray:Array = [];
	private var newFilters:Array = [];
	public function buildFilters(force:Boolean = false):Array {
		// disable filters not running on x86 because PixelBender is really slow
		if((Scratch.app.isIn3D || Capabilities.cpuArchitecture != 'x86') && !force) return emptyArray;

		var scale:Number = targetObj.isStage ? 1 : Scratch.app.stagePane.scaleX;
		var srcWidth:Number = targetObj.width * scale;
		var srcHeight:Number = targetObj.height * scale;
		var n:Number;
		newFilters.length = 0;

		if (filterDict["whirl"] != 0) {
			// range: -infinity..infinity
			var radians:Number = (Math.PI * filterDict["whirl"]) / 180;
			var scaleX:Number, scaleY:Number
			if (srcWidth > srcHeight) {
				scaleX = srcHeight / srcWidth;
				scaleY = 1;
			} else {
				scaleX = 1;
				scaleY = srcWidth / srcHeight;
			}
			whirlShader.data.whirlRadians.value = [radians];
			whirlShader.data.center.value = [srcWidth / 2, srcHeight / 2];
			whirlShader.data.radius.value = [Math.min(srcWidth, srcHeight) / 2];
			whirlShader.data.scale.value = [scaleX, scaleY];
			newFilters.push(new ShaderFilter(whirlShader));
		}
		if (filterDict["fisheye"] != 0) {
			// range: -100..infinity
			n = Math.max(0, (filterDict["fisheye"] + 100) / 100);
			fisheyeShader.data.scaledPower.value = [n];
			fisheyeShader.data.center.value = [srcWidth / 2, srcHeight / 2];
			newFilters.push(new ShaderFilter(fisheyeShader));
		}
		if (filterDict["pixelate"] != 0) {
			// range of absolute value: 0..(10 * min(w, h))
			n = (Math.abs(filterDict["pixelate"]) / 10) + 1;
			if (targetObj == Scratch.app.stagePane) n *= Scratch.app.stagePane.scaleX;
			n = Math.min(n, Math.min(srcWidth, srcHeight));
			pixelateShader.data.pixelSize.value = [n];
			newFilters.push(new ShaderFilter(pixelateShader));
		}
		if (filterDict["mosaic"] != 0) {
			// range of absolute value: 0..(10 * min(w, h))
			n = Math.round((Math.abs(filterDict["mosaic"]) + 10) / 10);
			n = Math.max(1, Math.min(n, Math.min(srcWidth, srcHeight)));
			mosaicShader.data.count.value = [n];
			mosaicShader.data.widthAndHeight.value = [srcWidth, srcHeight];
			newFilters.push(new ShaderFilter(mosaicShader));
		}
		if (filterDict["color"] != 0) {
			// brightness range is -100..100
//			n = Math.max(-100, Math.min(filterDict["brightness"], 100));
//			hsvShader.data.brightnessShift.value = [n];
			hsvShader.data.brightnessShift.value = [0];

			// hue range: -infinity..infinity
			n = ((360.0 * filterDict["color"]) / 200.0) % 360.0;
			hsvShader.data.hueShift.value = [n];
			newFilters.push(new ShaderFilter(hsvShader));
		}
		return newFilters;
	}
}}
