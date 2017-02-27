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

// ScratchCostume.as
// John Maloney, April 2010
// John Maloney, January 2011 (major restructure)
//
// A Scratch costume (or scene) is a named image with a rotation center.
// The bitmap field contains the composite costume image.
//
// Internally, a costume consists of a base image and an optional text layer.
// If a costume has a text layer, the text image is stored as a separate
// bitmap and composited with the base image to create the costume bitmap.
// Storing the text layer separately allows the text to be changed independent
// of the base image. Saving the text image means that costumes with text
// do not depend on the fonts available on the viewer's computer. (However,
// editing the text *does* depend on the user's fonts.)
//
// The source data (GIF, PNG, JPEG, or SVG format) for each layer is retained so
// that it does not need to be recomputed when saving the project. This also
// avoids the possible image degradation that might occur when repeatedly
// converting to/from JPEG format.

package scratch {
import by.blooddy.crypto.MD5;
import by.blooddy.crypto.image.PNG24Encoder;
import by.blooddy.crypto.image.PNGFilter;

import flash.display.*;
import flash.geom.*;
import flash.text.TextField;
import flash.utils.*;

import render3d.DisplayObjectContainerIn3D;

import svgeditor.objs.SegmentationState;

import svgutils.*;

import util.*;

public class ScratchCostume {

	public var costumeName:String;
	public var bitmap:BitmapData; // composite bitmap (base layer + text layer)
	public var bitmapResolution:int = 1; // used for double or higher resolution costumes
	public var rotationCenterX:int;
	public var rotationCenterY:int;

	public var baseLayerBitmap:BitmapData;
	public var baseLayerID:int = -1;
	public var baseLayerMD5:String;
	private var __baseLayerData:ByteArray;

	public static const WasEdited:int = -10; // special baseLayerID used to indicate costumes that have been edited
	public static const kCalculateCenter:int = 99999; // calculate a default rotation center

	public var svgRoot:SVGElement; // non-null for an SVG costume
	public var svgLoading:Boolean; // true while loading bitmaps embedded in an SVG
	private var svgSprite:Sprite;
	private var svgWidth:Number;
	private var svgHeight:Number;

	public var oldComposite:BitmapData; // composite bitmap from old Scratch file (used only during loading)

	public var textLayerBitmap:BitmapData;
	public var textLayerID:int = -1;
	public var textLayerMD5:String;
	private var __textLayerData:ByteArray;

	public var text:String;
	public var textRect:Rectangle;
	public var textColor:int;
	public var fontName:String;
	public var fontSize:int;

	// Undo support; not saved
	public var undoList:Array = [];
	public var undoListIndex:int;

	private var segmentation:SegmentationState = new SegmentationState();

	public function ScratchCostume(
			name:String, data:*, centerX:int = kCalculateCenter, centerY:int = kCalculateCenter, bmRes:int = 1) {
		costumeName = name;
		rotationCenterX = centerX;
		rotationCenterY = centerY;
		if (data == null) {
			rotationCenterX = rotationCenterY = 0;
		}
		else if (data is BitmapData) {
			bitmap = baseLayerBitmap = data;
			bitmapResolution = bmRes;
			if (centerX == kCalculateCenter) rotationCenterX = bitmap.rect.width / 2;
			if (centerY == kCalculateCenter) rotationCenterY = bitmap.rect.height / 2;
			prepareToSave();
		}
		else if (data is ByteArray) {
			setSVGData(data, (centerX == kCalculateCenter));
			prepareToSave();
		}
	}

	public function get baseLayerData():ByteArray {
		return __baseLayerData;
	}

	public function set baseLayerData(data:ByteArray):void {
		__baseLayerData = data;
		baseLayerMD5 = null;
	}

	public function get textLayerData():ByteArray {
		return __textLayerData;
	}

	public function set textLayerData(data:ByteArray):void {
		__textLayerData = data;
		textLayerMD5 = null;
	}

	public function get segmentationState():SegmentationState {
		return segmentation;
	}

	public function nextSegmentationState():void {
		segmentation = segmentation.next;
	}

	public function prevSegmentationState():void {
		segmentation = segmentation.prev;
	}

	public static function scaleForScratch(bm:BitmapData):BitmapData {
		if ((bm.width <= 480) && (bm.height <= 360)) return bm;
		var scale:Number = Math.min(480 / bm.width, 360 / bm.height);
		var result:BitmapData = new BitmapData(scale * bm.width, scale * bm.height, true, 0);
		var m:Matrix = new Matrix();
		m.scale(scale, scale);
		result.draw(bm, m);
		return result;
	}

	public function scaleAndCenter(bm:BitmapData, isScene:Boolean):Rectangle {
		var scale:Number = 2 / bitmapResolution;
		var costumeBM:BitmapData = bitmapForEditor(isScene);
		var destP:Point = isScene ? new Point(0, 0) :
				new Point(480 - (scale * rotationCenterX), 360 - (scale * rotationCenterY));
		bm.copyPixels(costumeBM, costumeBM.rect, destP);
		var costumeRect:Rectangle = costumeBM.rect;
		costumeRect.x = destP.x;
		costumeRect.y = destP.y;
		return costumeRect;
	}

	public static function isSVGData(data:ByteArray):Boolean {
		if (!data || (data.length < 10)) return false;
		var oldPosition:int = data.position;
		data.position = 0;
		var s:String = data.readUTFBytes(10);
		data.position = oldPosition;
		var validXML:Boolean = true;
		try{
			XML(data)
		}
		catch (e:*){
			validXML = false;
		}
		return ((s.indexOf('<?xml') >= 0) || (s.indexOf('<svg') >= 0)) && validXML;
	}

	public static function emptySVG():ByteArray {
		var data:ByteArray = new ByteArray();
		data.writeUTFBytes(
				'<svg width="0" height="0"\n' +
				'  xmlns="http://www.w3.org/2000/svg" version="1.1"\n' +
				'  xmlns:xlink="http://www.w3.org/1999/xlink">\n' +
				'</svg>\n');
		return data;
	}

	public static function emptyBackdropSVG():ByteArray {
		var data:ByteArray = new ByteArray();
		data.writeUTFBytes(
				'<svg width="480" height="360"\n' +
				'  xmlns="http://www.w3.org/2000/svg" version="1.1"\n' +
				'  xmlns:xlink="http://www.w3.org/1999/xlink">\n' +
				'	<rect x="0" y="0" width="480" height="360" fill="#FFF" scratch-type="backdrop-fill"> </rect>\n' +
				'</svg>\n');
		return data;
	}

	public static function emptyBitmapCostume(costumeName:String, forBackdrop:Boolean):ScratchCostume {
		var bm:BitmapData = forBackdrop ? new BitmapData(480, 360, true, 0xFFFFFFFF) : new BitmapData(1, 1, true, 0);
		var result:ScratchCostume = new ScratchCostume(costumeName, bm);
		return result;
	}

	public function setBitmapData(bm:BitmapData, centerX:int, centerY:int):void {
		clearOldCostume();
		bitmap = baseLayerBitmap = bm;
		baseLayerID = WasEdited;
		baseLayerMD5 = null;
		bitmapResolution = 2;
		rotationCenterX = centerX;
		rotationCenterY = centerY;
		if (Scratch.app && Scratch.app.viewedObj() && (Scratch.app.viewedObj().currentCostume() == this)) {
			Scratch.app.viewedObj().updateCostume();
			Scratch.app.refreshImageTab(true);
		}
	}

	public function setSVGData(data:ByteArray, computeCenter:Boolean, fromEditor:Boolean = true):void {
		// Initialize an SVG costume.
		function refreshAfterImagesLoaded():void {
			svgSprite = new SVGDisplayRender().renderAsSprite(svgRoot, false, true);
			if (Scratch.app && Scratch.app.viewedObj() && (Scratch.app.viewedObj().currentCostume() == thisC)) {
				Scratch.app.viewedObj().updateCostume();
				Scratch.app.refreshImageTab(fromEditor);
			}
			svgLoading = false;
		}
		var thisC:ScratchCostume = this; // record "this" for use in callback
		clearOldCostume();
		baseLayerData = data;
		baseLayerID = WasEdited;
		var importer:SVGImporter = new SVGImporter(XML(data));
		setSVGRoot(importer.root, computeCenter);
		svgLoading = true;
		importer.loadAllImages(refreshAfterImagesLoaded);
	}

	public function setSVGRoot(svg:SVGElement, computeCenter:Boolean):void {
		svgRoot = svg;
		svgSprite = new SVGDisplayRender().renderAsSprite(svgRoot, false, true);
		var r:Rectangle;
		var viewBox:Array = svg.getAttribute('viewBox', '').split(' ');
		if (viewBox.length == 4) r = new Rectangle(viewBox[0], viewBox[1], viewBox[2], viewBox[3]);
		if (!r) {
			var w:Number = svg.getAttribute('width', -1);
			var h:Number = svg.getAttribute('height', -1);
			if ((w >= 0) && (h >= 0)) r = new Rectangle(0, 0, w, h);
		}
		if (!r) r = svgSprite.getBounds(svgSprite);
		svgWidth = r.x + r.width;
		svgHeight = r.y + r.height;
		if (computeCenter) {
			rotationCenterX = r.x + (r.width / 2);
			rotationCenterY = r.y + (r.height / 2);
		}
	}

	private function clearOldCostume():void {
		bitmap = null;
		baseLayerBitmap = null;
		bitmapResolution = 1;
		baseLayerID = -1;
		baseLayerData = null;
		svgRoot = null;
		svgSprite = null;
		svgWidth = svgHeight = 0;
		oldComposite = null;
		textLayerBitmap = null;
		textLayerID = -1;
		textLayerMD5 = null;
		textLayerData = null;
		text = null;
		textRect = null;
	}

	public function isBitmap():Boolean { return baseLayerBitmap != null }

	public function displayObj():DisplayObject {
		if (svgRoot) {
			if (!svgSprite) svgSprite = new SVGDisplayRender().renderAsSprite(svgRoot, false, true);
			return svgSprite;
		}

		var bitmapObj:Bitmap = new Bitmap(bitmap);
		bitmapObj.scaleX = bitmapObj.scaleY = 1 / bitmapResolution;
		return bitmapObj;
	}

	private static var shapeDict:Object = {};
	public function getShape():Shape {
		if (!baseLayerMD5) prepareToSave();
		var id:String = baseLayerMD5;
		if (id && textLayerMD5) id += textLayerMD5;
		else if (textLayerMD5) id = textLayerMD5;

		var s:Shape = shapeDict[id];
		if (!s) {
			s = new Shape();
			var pts:Vector.<Point> = RasterHull();
			s.graphics.clear();

			if (pts.length) {
				s.graphics.lineStyle(1);
				s.graphics.moveTo(pts[pts.length - 1].x, pts[pts.length - 1].y);
				for each(var pt:Point in pts)
					s.graphics.lineTo(pt.x, pt.y);
			}

			if (id)
				shapeDict[id] = s;
		}

		return s;
	}

	/* > 0 ; counter clockwise order */
	/* =0 ; C is on the line AB; */
	/* <0 ; clockwise order; */
	private function CCW(A:Point, B:Point, C:Point):Number {
		return ((B.x - A.x) * (C.y - A.y) - (B.y - A.y) * (C.x - A.x));
	}

	/* make a convex hull of boundary of foreground object in the binary
	 image */
	/* in some case L[0]=R[0], or L[ll]=R[rr] if first line or last line of
	 object is composed of
	 ** a single point
	 */
	private function RasterHull():Vector.<Point> {
		var H:Vector.<Point> = new Vector.<Point>();
		var dispObj:DisplayObject = displayObj();
		var r:Rectangle = dispObj.getBounds(dispObj);
		if (r.width < 1 || r.height < 1) {
			H.push(new Point());
			return H;
		}

		r.width += Math.floor(r.left) - r.left;
		r.left = Math.floor(r.left);
		r.height += Math.floor(r.top) - r.top;
		r.top = Math.floor(r.top);
		var desiredWidth: int = Math.max(0, Math.ceil(r.width));
		var desiredHeight: int = Math.max(0, Math.ceil(r.height));
		if (desiredWidth >= DisplayObjectContainerIn3D.texSizeMax
				|| desiredHeight >= DisplayObjectContainerIn3D.texSizeMax) {
			var factor:Number = (DisplayObjectContainerIn3D.texSizeMax - 1) / Math.max(desiredWidth, desiredHeight);
			desiredWidth *= factor;
			desiredHeight *= factor;
		}
		// TODO: figure out why we add 1 to each dimension in addition to using Math.ceil above
		var image:BitmapData = new BitmapData(desiredWidth + 1, desiredHeight + 1, true, 0);

		var m:Matrix = new Matrix();
		m.translate(-r.left, -r.top);
		m.scale(image.width / r.width, image.height / r.height);
		image.draw(dispObj, m);

		var L:Vector.<Point> = new Vector.<Point>(image.height); //stack of left-side hull;
		var R:Vector.<Point> = new Vector.<Point>(image.height); //stack of right side hull;
		var rr:int = -1, ll:int = -1;
		var Q:Point = new Point();
		var w:int = image.width;
		var h:int = image.height;
		var c:uint;
		for (var y:int = 0; y < h; ++y) {
			for (var x:int = 0; x < w; ++x) {
				c = (image.getPixel32(x, y) >> 24) & 0xff;
				if (c > 0) break;
			}
			if (x == w) continue;

			Q.x = x + r.left;
			Q.y = y + r.top;
			while (ll > 0) {
				if (CCW(L[ll - 1], L[ll], Q) < 0)
					break;
				else
					--ll;
			}

			L[++ll] = Q.clone();
			for (x = w - 1; x >= 0; --x) {//x=-1 never occurs;
				c = (image.getPixel32(x, y) >> 24) & 0xff;
				if (c > 0) break;
			}

			Q.x = x + r.left;
			while (rr > 0) {
				if (CCW(R[rr - 1], R[rr], Q) > 0)
					break;
				else
					--rr;
			}
			R[++rr] = Q.clone();
		}

		/* collect final results*/
		for (var i:int = 0; i < (ll + 1); ++i)
			H[i] = L[i]; //left part;

		for (var j:int = rr; j >= 0; --j)
			H[i++] = R[j]; //right part;

		R.length = L.length = 0;
		image.dispose();

		return H;
	}

	public function width():Number { return svgRoot ? svgWidth : (bitmap ? bitmap.width / bitmapResolution : 0) }
	public function height():Number { return svgRoot ? svgHeight : (bitmap ? bitmap.height / bitmapResolution : 0) }

	public function duplicate():ScratchCostume {
		// Return a copy of this costume.

		if (oldComposite) computeTextLayer();

		var dup:ScratchCostume = new ScratchCostume(costumeName, null);
		dup.bitmap = bitmap;
		dup.bitmapResolution = bitmapResolution;
		dup.rotationCenterX = rotationCenterX;
		dup.rotationCenterY = rotationCenterY;

		dup.baseLayerBitmap = baseLayerBitmap;
		dup.baseLayerData = baseLayerData;
		dup.baseLayerMD5 = baseLayerMD5;

		dup.svgRoot = svgRoot;
		dup.svgWidth = svgWidth;
		dup.svgHeight = svgHeight;

		dup.textLayerBitmap = textLayerBitmap;
		dup.textLayerData = textLayerData;
		dup.textLayerMD5 = textLayerMD5;

		dup.text = text;
		dup.textRect = textRect;
		dup.textColor = textColor;
		dup.fontName = fontName;
		dup.fontSize = fontSize;

		if (svgRoot && svgSprite) dup.setSVGSprite(cloneSprite(svgSprite));

		return dup;
	}

	private function cloneSprite(spr:Sprite):Sprite {
		var clone:Sprite = new Sprite();
		clone.graphics.copyFrom(spr.graphics);
		clone.x = spr.x;
		clone.y = spr.y;
		clone.scaleX = spr.scaleX;
		clone.scaleY = spr.scaleY;
		clone.rotation = spr.rotation;

		for (var i:int = 0; i < spr.numChildren; ++i) {
			var dispObj:DisplayObject = spr.getChildAt(i);
			if (dispObj is Sprite)
				clone.addChild(cloneSprite(dispObj as Sprite));
			else if (dispObj is Shape) {
				var shape:Shape = new Shape();
				shape.graphics.copyFrom((dispObj as Shape).graphics);
				shape.transform = dispObj.transform;
				clone.addChild(shape);
			}
			else if (dispObj is Bitmap) {
				var bm:Bitmap = new Bitmap((dispObj as Bitmap).bitmapData);
				bm.x = dispObj.x;
				bm.y = dispObj.y;
				bm.scaleX = dispObj.scaleX;
				bm.scaleY = dispObj.scaleY;
				bm.rotation = dispObj.rotation;
				bm.alpha = dispObj.alpha;
				clone.addChild(bm);
			}
			else if (dispObj is TextField) {
				var tf:TextField = new TextField();
				tf.selectable = false;
				tf.mouseEnabled = false;
				tf.tabEnabled = false;
				tf.textColor = (dispObj as TextField).textColor;
				tf.defaultTextFormat = (dispObj as TextField).defaultTextFormat;
				tf.embedFonts = (dispObj as TextField).embedFonts;
				tf.antiAliasType = (dispObj as TextField).antiAliasType;
				tf.text = (dispObj as TextField).text;
				tf.alpha = dispObj.alpha;
				tf.width = tf.textWidth + 6;
				tf.height = tf.textHeight + 4;

				tf.x = dispObj.x;
				tf.y = dispObj.y;
				tf.scaleX = dispObj.scaleX;
				tf.scaleY = dispObj.scaleY;
				tf.rotation = dispObj.rotation;
				clone.addChild(tf);
			}
		}

		return clone;
	}

	public function setSVGSprite(spr:Sprite):void {
		svgSprite = spr;
	}

	public function thumbnail(w:int, h:int, forStage:Boolean):BitmapData {
		var dispObj:DisplayObject = displayObj();
		var r:Rectangle = forStage ? new Rectangle(0, 0, 480 * bitmapResolution, 360 * bitmapResolution) :
				dispObj.getBounds(dispObj);
		var centerX:Number = r.x + (r.width / 2);
		var centerY:Number = r.y + (r.height / 2);
		var bm:BitmapData = new BitmapData(w, h, true, 0x00FFFFFF); // transparent fill color
		var scale:Number = Math.min(w / r.width, h / r.height);
		if (bitmap) scale = Math.min(1, scale);
		var m:Matrix = new Matrix();
		if (scale < 1 || !bitmap) m.scale(scale, scale); // don't scale up bitmaps
		m.translate((w / 2) - (scale * centerX), (h / 2) - (scale * centerY));
		bm.draw(dispObj, m);
		return bm;
	}

	public function bitmapForEditor(forStage:Boolean):BitmapData {
		// Return a double-resolution bitmap for use in the bitmap editor.
		var dispObj:DisplayObject = displayObj();
		var dispR:Rectangle = dispObj.getBounds(dispObj);
		var w:int = Math.ceil(Math.max(1, dispR.width));
		var h:int = Math.ceil(Math.max(1, dispR.height));
		if (forStage) {
			w = 480 * bitmapResolution;
			h = 360 * bitmapResolution
		}

		var scale:Number = 2 / bitmapResolution;
		var bgColor:int = forStage ? 0xFFFFFFFF : 0;
		var bm:BitmapData = new BitmapData(scale * w, scale * h, true, bgColor);
		var m:Matrix = new Matrix();
		if (!forStage) m.translate(-dispR.x, -dispR.y);
		m.scale(scale, scale);

		if (SCRATCH::allow3d) {
			bm.drawWithQuality(dispObj, m, null, null, null, false, StageQuality.LOW);
		}
		else {
			Scratch.app.ignoreResize = true;
			var oldQuality:String = Scratch.app.stage.quality;
			Scratch.app.stage.quality = StageQuality.LOW;
			bm.draw(dispObj, m);
			Scratch.app.stage.quality = oldQuality;
			Scratch.app.ignoreResize = false;
		}

		return bm;
	}

	public function toString():String {
		var result:String = 'ScratchCostume(' + costumeName + ' ';
		result += rotationCenterX + ',' + rotationCenterY;
		result += svgRoot ? ' svg)' : ' bitmap)';
		return result;
	}

	public function writeJSON(json:util.JSON):void {
		json.writeKeyValue('costumeName', costumeName);
		json.writeKeyValue('baseLayerID', baseLayerID);
		json.writeKeyValue('baseLayerMD5', baseLayerMD5);
		json.writeKeyValue('bitmapResolution', bitmapResolution);
		json.writeKeyValue('rotationCenterX', rotationCenterX);
		json.writeKeyValue('rotationCenterY', rotationCenterY);
		if (text != null) {
			json.writeKeyValue('text', text);
			json.writeKeyValue('textRect', [textRect.x, textRect.y, textRect.width, textRect.height]);
			json.writeKeyValue('textColor', textColor);
			json.writeKeyValue('fontName', fontName);
			json.writeKeyValue('fontSize', fontSize);
			json.writeKeyValue('textLayerID', textLayerID);
			json.writeKeyValue('textLayerMD5', textLayerMD5);
		}
	}

	public function readJSON(jsonObj:Object):void {
		costumeName = jsonObj.costumeName;
		baseLayerID = jsonObj.baseLayerID;
		if (jsonObj.baseLayerID == undefined) {
			if (jsonObj.imageID) baseLayerID = jsonObj.imageID; // slightly older .sb2 format
		}
		baseLayerMD5 = jsonObj.baseLayerMD5;
		if (jsonObj.bitmapResolution) bitmapResolution = jsonObj.bitmapResolution;
		rotationCenterX = jsonObj.rotationCenterX;
		rotationCenterY = jsonObj.rotationCenterY;
		text = jsonObj.text;
		if (text != null) {
			if (jsonObj.textRect is Array) {
				textRect =
						new Rectangle(jsonObj.textRect[0], jsonObj.textRect[1], jsonObj.textRect[2], jsonObj.textRect[3]);
			}
			textColor = jsonObj.textColor;
			fontName = jsonObj.fontName;
			fontSize = jsonObj.fontSize;
			textLayerID = jsonObj.textLayerID;
			textLayerMD5 = jsonObj.textLayerMD5;
		}
	}

	public function prepareToSave():void {
		if (oldComposite) computeTextLayer();
		if (baseLayerID == WasEdited) baseLayerMD5 = null; // costume was edited; recompute hash
		baseLayerID = textLayerID = -1;
		if (baseLayerData == null) baseLayerData = PNG24Encoder.encode(baseLayerBitmap, PNGFilter.PAETH);
		if (baseLayerMD5 == null) baseLayerMD5 =
				MD5.hashBytes(baseLayerData) + fileExtension(baseLayerData);
		if (textLayerBitmap != null) {
			if (textLayerData == null) textLayerData = PNG24Encoder.encode(textLayerBitmap, PNGFilter.PAETH);
			if (textLayerMD5 == null) textLayerMD5 = MD5.hashBytes(textLayerData) + '.png';
		}
	}

	private function computeTextLayer():void {
		// When saving an old-format project, generate the text layer bitmap by subtracting
		// the base layer bitmap from the composite bitmap. (The new costume format keeps
		// the text layer bitmap only, rather than the entire composite image.)

		if (oldComposite == null || baseLayerBitmap == null) return; // nothing to do
		var diff:* = oldComposite.compare(baseLayerBitmap); // diff is 0 if oldComposite and baseLayerBitmap are
	                                                        // identical
		if (diff is BitmapData) {
			var stencil:BitmapData = new BitmapData(diff.width, diff.height, true, 0);
			stencil.threshold(diff, diff.rect, new Point(0, 0), '!=', 0, 0xFF000000);
			textLayerBitmap = new BitmapData(diff.width, diff.height, true, 0);
			textLayerBitmap.copyPixels(
					oldComposite, oldComposite.rect, new Point(0, 0), stencil, new Point(0, 0), false);
		}
		else if (diff != 0) {
			trace('computeTextLayer diff: ' + diff); // should not happen
		}
		oldComposite = null;
	}

	public static function fileExtension(data:ByteArray):String {
		data.position = 6;
		if (data.readUTFBytes(4) == 'JFIF') return '.jpg';
		data.position = 0;
		var s:String = data.readUTFBytes(4);
		if (s == 'GIF8') return '.gif';
		if (s == '\x89PNG') return '.png';
		if ((s == '<?xm') || (s == '<svg')) return '.svg';
		return '.dat'; // generic data; should not happen
	}

	public function generateOrFindComposite(allCostumes:Vector.<ScratchCostume>):void {
		// If this costume has a text layer bitmap, compute or find a composite bitmap.
		// Since there can be multiple copies of the same costume, first try to find a
		// costume with the same base and text layer bitmaps and share its composite
		// costume. This saves speeds up loading and saves memory.

		if (bitmap != null) return;
		if (textLayerBitmap == null) {  // no text layer; use the base layer bitmap
			bitmap = baseLayerBitmap;
			return;
		}
		for each (var c:ScratchCostume in allCostumes) {
			if ((c.baseLayerBitmap === baseLayerBitmap) && (c.textLayerBitmap === textLayerBitmap) &&
					(c.bitmap != null)) {
				bitmap = c.bitmap;
				return;  // found a composite bitmap to share
			}
		}
		// compute the composite bitmap
		bitmap = baseLayerBitmap.clone();
		bitmap.draw(textLayerBitmap);
	}

}
}
