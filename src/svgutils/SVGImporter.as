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

// SVGImporter.as
// John Maloney, April 2012.
//
// An SVGImporter imports converts an SVG file into a collection of SVGElements.
// To use, instantiate an SVGImporter on the XML object for the SVG file.
// The result of reading the SVG file are in two public variables:
//
//		root - the root of the visible object hierarchy
//		elements - a dictionary of all elements, including defs, keyed by their ID
//
// Style attributes (e.g. style="stroke:none; fill:#FF0000") are broken into individual attributes.
// Attributes with units are converted to unitless numbers in pixels (e.g. "10cm" -> 354.3307).
// Percentage attributes are converted to simple numbers (e.g. "50%" -> 0.5).
// Reference attributes (e.g. "url(#gradient1)") are resolved by replacing the URL with the
// SVGElement to which it refers.
//
// All vector elements (circles, ellipses, lines, paths, polygons, polylines, and rects) are converted
// into simplified paths consisting of only M, L, C, and Q commands with absolute coordinates.
//
// Optionally applies transforms to all elements. For paths elements, the points of the path are
// transformed, leaving no remaining transform. For text and image elements, the translation part
// of the transform is applied, possibly leaving a transform matrix with rotation, scaling, and/or skew.
//
// To be done later:
//	* clipping paths
//	* support for the "use" construct in gradients

package svgutils {
import flash.display.Loader;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.geom.*;

import logging.LogLevel;

import util.Base64Encoder;

public class SVGImporter {

	public var root:SVGElement; // root of the visible element tree
	public var elements:Object = {}; // all elements, including defs, keyed by id

	// Add tags to this list to avoid warnings about unknown tags.
	private const ignoredTags:Array = [
		'filter', 'foreignObject', 'marker', 'metadata', 'namedview',
		'pattern', 'perspective', 'pgf', 'title', 'use'];

	public function SVGImporter(svg:XML) {
		elements = {};
		if (svg.localName() != 'svg') {
			trace('ERROR! Top-level must be an svg element.');
			return;
		}
		root = extractElement(svg, []);
		if (!root) {
			Scratch.app.log(LogLevel.WARNING, 'No SVG root (empty file?)');
			root = new SVGElement('svg');
		}
		resolveGradientLinks();
		resolveURLRefs();
		computeTransforms(root, null);
	}

	// -----------------------------
	// Element Extraction
	//------------------------------

	private function extractElement(xml:XML, parentList:Array):SVGElement {
		// Extract an SVGElement from the given XML object. Return an SVGElement
		// or null if the given element is empty or is ignored by Scratch.
		// Recursively extract subelements if appropriate.
		var tag:String = xml.localName();
		if (ignoredTags.indexOf(tag) >= 0) return null; // ignored by Scratch
		switch (tag) {
		case 'circle':
		case 'clipPath':
		case 'ellipse':
		case 'image':
		case 'line':
		case 'path':
		case 'polygon':
		case 'polyline':
		case 'rect':
		case 'text':
			return readBasic(xml, parentList);
		case 'defs':
			return readDefs(xml, parentList);
		case 'g':
			return readGroup(xml, parentList);
		case 'linearGradient':
		case 'radialGradient':
			return readGradient(xml, parentList);
		case 'stop':
			return readBasic(xml, parentList);
		case 'svg':
			return readSVG(xml, parentList);
		case 'switch':
			return readSwitch(xml, parentList);
		default:
			trace('Unknown SVG element: ' + tag);
		}
		return null;
	}

	private function readBasic(xml:XML, parentList:Array):SVGElement {
		var result:SVGElement = new SVGElement(xml.localName(), xml.attribute('id'));
		if ('text' == xml.localName()) result.text = xml.text()[0];
		for each (var attr:XML in xml.attributes()) {
			var ns:String = attr.namespace();
			if ((ns == '') || (ns == 'http://www.w3.org/1999/xlink')) {
				// ignore non-standard attributes (e.g. those added by Adobe, Inkscape, etc)
				var attrName:String = attr.localName();
				var attrValue:String = attr.toString();
				if (attrName == 'style') addStyleAttributes(result, attrValue);
				else result.attributes[attrName] = convertUnits(attrValue);
			}
		}
		inheritAttributes(result, parentList);
		new SVGImportPath().generatePathCmds(result);
		elements[result.id] = result;
		return result;
	}

	private function readDefs(xml:XML, parentList:Array):SVGElement {
		// Add the subelements of a 'defs' element to elementsDict.
		// Return null since a 'defs' element (and it's subelements) are not visible.
		var defsEl:SVGElement = readBasic(xml, parentList);
		for each (var elementXML:XML in xml.elements()) {
			var el:SVGElement = extractElement(elementXML, []);
			if (el) elements[el.id] = el;
		}
		return null;
	}

	private function readGradient(xml:XML, parentList:Array):SVGElement {
		// Read a 'linearGradient' or 'radialGradient' element, including all it's subelements.
		// Return null if the group has no subelements.
		var result:SVGElement = readBasic(xml, []);
		for each (var elementXML:XML in xml.elements()) {
			var el:SVGElement = extractElement(elementXML, []);
			if (el) result.subElements.push(el);
		}
		return result;
	}

	private function readGroup(xml:XML, parentList:Array):SVGElement {
		// Read a 'g' element, including all it's subelements.
		// Return null if the group has no subelements.
		var result:SVGElement = readBasic(xml, parentList);
		parentList = [result].concat(parentList);
		for each (var elementXML:XML in xml.elements()) {
			var el:SVGElement = extractElement(elementXML, parentList);
			if (el) result.subElements.push(el);
		}
		if (result.subElements.length == 0) return null; // empty group
		return result;
	}

	private function readText(xml:XML, parentList:Array):SVGElement {
		// Read a 'text' element, including all it's subelements.
		var result:SVGElement = readBasic(xml, parentList);
		parentList = [result].concat(parentList);

		// Read any tspan elements
		var text:String = xml.text().length ? xml.text()[0] : '';
		for each (var elementXML:XML in xml.elements()) {
			if (elementXML.localName() == 'tspan') {
				if (text.length > 0) text += '\n';
				text += elementXML.text()[0];
			}
			var el:SVGElement = extractElement(elementXML, parentList);
			if (el) result.subElements.push(el);
		}
		return result;
	}

	private function readSVG(xml:XML, parentList:Array):SVGElement {
		// Read an 'svg' element, including all it's subelements.
		// Note: Attributes of 'svg' elements are not inherited.
		var result:SVGElement = readBasic(xml, parentList);
		for each (var elementXML:XML in xml.elements()) {
			var el:SVGElement = extractElement(elementXML, []); // svg attributes are not inherited
			if (el) result.subElements.push(el);
		}
		return result;
	}

	private function readSwitch(xml:XML, parentList:Array):SVGElement {
		// Return a group element with the attributes of the switch element whose
		// only child is the first switch element that can be handled by Scratch.
		// Return null if none of the switch elements can be handled.
		var switchEl:SVGElement = readBasic(xml, parentList);
		switchEl.tag = 'g'; // convert a group
		parentList = [switchEl].concat(parentList);
		for each (var elementXML:XML in xml.elements()) {
			var el:SVGElement = extractElement(elementXML, parentList);
			if (el) {
				switchEl.subElements.push(el);
				return switchEl;
			}
		}
		return null;
	}

	// -----------------------------
	// Attribute Inheritance
	//------------------------------

	private function inheritAttributes(el:SVGElement, parentList:Array):void {
		// Ensure that the given element has local copies of any inherited attributes that it needs.
		const inheritableAttributes:Array = [
			'fill', 'fill-rule', 'stroke', 'stroke-width', 'text-anchor',
			'font-family', 'font-size', 'font-style', 'font-weight'];
		for each (var k:String in inheritableAttributes) {
			if (el.attributes[k] == undefined) {
				var attrVal:* = inheritedValue(k, parentList);
				if (attrVal) el.attributes[k] = attrVal;
			}
		}
		// Compute the cumulative opacity.
		var alpha:Number = el.getAttribute('opacity', 1);
		for each (var parentEl:SVGElement in parentList) {
			alpha = alpha * parentEl.getAttribute('opacity', 1);
		}
		if (alpha != 1) el.attributes['opacity'] = alpha;
	}

	private function inheritedValue(attrName:String, parentList:Array):* {
		// Return the first definition of the given attribute found in the give list of parent SVGElements.
		// Return null if no definition is found.
		for each (var el:SVGElement in parentList) {
			var attrVal:* = el.attributes[attrName];
			if (attrVal) return attrVal;
		}
		return null;
	}

	// -----------------------------
	// Image Loading
	//------------------------------

	public function hasUnloadedImages():Boolean {
		for each (var el:SVGElement in root.allElements()) {
			if (('image' == el.tag) && (el.bitmap == null)) return true;
		}
		return false;
	}

	public function loadAllImages(whenDone:Function = null):void {
		// Load all images. If not null, call whenDone when images are loaded.
		function imageLoaded():void {
			imagesLoaded++;
			if ((imagesLoaded == imageCount) && (whenDone != null)) whenDone(root);
		}
		var imageCount:int = 0, imagesLoaded:int = 0;
		for each (var el:SVGElement in root.allElements()) {
			if (('image' == el.tag) && (el.bitmap == null)) {
				imageCount++;
				loadImage(el, imageLoaded);
			}
		}
		if ((imageCount == 0) && (whenDone != null)) whenDone(root);
	}

	private function loadImage(el:SVGElement, whenDone:Function):void {
		// Load the image for the given element. When the image has loaded,
		// save it in the element's bitmap variable and call whenDone().
		function loadDone(evt:Event):void {
			el.bitmap = evt.target.content.bitmapData;
			whenDone();
		}
		var data:String = el.getAttribute('href');
		if (!data) { whenDone(); return; } // no data
		data = data.slice(data.indexOf(',') + 1);
		var loader:Loader = new Loader();
		loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadDone);
		loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(e:Event):void { whenDone(); });
		loader.loadBytes(Base64Encoder.decode(data));
	}

	// -----------------------------
	// Gradient Link Resolution
	//------------------------------
	private function resolveGradientLinks():void {
		// Copy linked gradients stop lists into the gradient elements that reference them.
		// Test case: taco.svg
		for each (var gradEl:SVGElement in elements) {
			if (('linearGradient' == gradEl.tag) || ('radialGradient' == gradEl.tag)) {
				var href:String = gradEl.getAttribute('href');
				if (!href || (href.length < 2)) continue;
				href = href.slice(1);  // remove leading #
				var stopsEl:SVGElement = elements[href];
				for each (var el:SVGElement in stopsEl.subElements) {
					// clone stops into gradEl
					gradEl.subElements.push(el.clone());
				}
			}
		}
	}

	// -----------------------------
	// URL Reference Resolution
	//------------------------------
	private function resolveURLRefs():void {
		// Replace attribute values of the form 'url(#tag)' with the SVGElement
		// to which they refer. Ignore references that are not defined.
		for each (var el:SVGElement in root.allElements()) {
			for (var k:String in el.attributes) {
				var attrValue:String = el.getAttribute(k) as String;
				if (attrValue && (attrValue.indexOf('url(#') == 0)) {
					var ref:String = attrValue.slice(5, attrValue.indexOf(')'));
					var refTarget:SVGElement = elements[ref];
					if (refTarget) el.attributes[k] = refTarget;
				}
			}
		}
	}

	// -----------------------------
	// Transforms
	//------------------------------
	private function computeTransforms(el:SVGElement, inherited:Matrix):void {
		// Recursively compute the transform for each visual element
		// and set its transform to the resulting composite transform.
		// Simple translations are applies to text and image elements
		// and all transformations are applies to paths. The transform
		// field of composite elements is cleared to avoid potential confusion.
		var local:Matrix = localXForm(el);
		if (local == null) el.transform = inherited;
		else if (inherited == null) el.transform = local;
		else {
			var m:Matrix = local.clone();
			m.concat(inherited);
			el.transform = m;
		}

		// Propagate transforms to children, then remove the transform from parent.
		for each (var subEl:SVGElement in el.subElements) computeTransforms(subEl, el.transform);
		if (el.subElements.length > 0) el.transform = null;

		if (false && el.transform) { // transform prebaking code; no longer used but could be useful in the future
			if (el.path) {
				// Transform the path immediately and discard the transform.
				applyTransformToPath(el, el.transform);
				el.transform = null;
			}
			if (isTranslationMatrix(el.transform)) {
				if ('image' == el.tag) {
					// Simple translation; just move the element and discard the transform.
					el.setAttribute('x', el.getAttribute('x', 0) + el.transform.tx);
					el.setAttribute('y', el.getAttribute('y', 0) + el.transform.ty);
					el.transform = null;
				}
			}
		}
	}

	private static const degToRadians:Number = Math.PI / 180;

	private function localXForm(el:SVGElement):Matrix {
		var s:String = el.attributes['transform'];
		if (s == null) return null;
		var result:Matrix = new Matrix();
		var pattern:RegExp = /(\w+)\s*\(([^)]*)\)/g;
		var xform:Object = pattern.exec(s);
		while (xform) {
			var m:Matrix = new Matrix();
			var type:String = xform[1].toLowerCase();
			var args:Array = el.extractNumericArgs(xform[2]);
			switch (type) {
			case 'translate' :
				m.translate(args[0], args.length > 1 ? args[1] : 0);
				break;
			case 'scale' :
				m.scale(args[0], args.length > 1 ? args[1] : args[0]);
				break;
			case 'rotate' :
				if (args.length > 1) {
					var tx:Number = args.length > 1 ? args[1] : 0;
					var ty:Number = args.length > 2 ? args[2] : 0;
					m.translate(-tx, -ty);
					m.rotate(args[0] * degToRadians);
					m.translate(tx, ty);
				}
				else m.rotate(args[0] * degToRadians);
				break;
			case 'skewx' :
				m.c = Math.tan(args[0] * degToRadians);
				break;
			case 'skewy' :
				m.b = Math.tan(args[0] * degToRadians);
				break;
			case 'matrix':
				m = new Matrix(args[0], args[1], args[2], args[3], args[4], args[5]);
				break;
			}
			m.concat(result);
			result = m;
			xform = pattern.exec(s);
		}
		return result;
	}

	private function applyTransformToPath(el:SVGElement, m:Matrix):void {
		for each (var cmd:Array in el.path) {
			for (var i:int = 1; (i + 1) < cmd.length; i += 2) {
				var p:Point = m.transformPoint(new Point(cmd[i], cmd[i + 1]));
				cmd[i] = p.x;
				cmd[i + 1] = p.y;
			}
		}
		el.setAttribute('d', SVGExport.pathCmds(el.path)); // avoid keeping obsolete data; el.path is the "truth"
		// Scale the stroke width if necessary
		var scaleX:Number = Math.sqrt((m.a * m.a) + (m.b * m.b));
		var scaleY:Number = Math.sqrt((m.c * m.c) + (m.d * m.d));
		if (!((scaleX == 1) && (scaleY == 1))) {
			var w:Number = Math.max(scaleX, scaleY) * el.getAttribute('stroke-width', 1);
			el.setAttribute('stroke-width', w);
		}
	}

	private function isTranslationMatrix(m:Matrix):Boolean {
		if (!m) return false;
		return (m.a == 1) && (m.b == 0) && (m.c == 0) && (m.d == 1);
	}

	// -----------------------------
	// Style Attributes
	//------------------------------
	private function addStyleAttributes(el:SVGElement, styleString:String):void {
		// Parse the given style string and add each attribute to the attribute dictionary of the given element.
		var styles:Array = removeWhitespace(styleString).split(';');
		for each (var style:String in styles) {
			if (style.length == 0) continue;
			var pair:Array = style.split(':');
			if (pair.length == 2) el.attributes[pair[0]] = convertUnits(pair[1]);
		}
	}

	private function removeWhitespace(s:String):String { return s.replace(/[\s\t\r\n]*/g, '') }

	private function convertUnits(s:String):* {
		// Convert the units of the given attribute to a unitless number if necessary.
		var n:Number;
		if (('xtcmn'.indexOf(s.slice(-1)) > -1) &&
			('.0123456789'.indexOf(s.slice(-3, -2)) > -1)) {
				var units:String = s.slice(-2);
				n = Number(s.slice(0, -2));
				switch (units) {
				case 'px': return n;
				case 'pt': return n * 1.25;
				case 'pc': return n * 15;
				case 'mm': return n * 3.543307;
				case 'cm': return n * 35.43307;
				case 'in': return n * 90;
				}
		}
		if (s.slice(-1) == '%') {
			n = Number(s.slice(0, -1));
			if (!isNaN(n)) return n / 100;
		}
		return s;
	}

}}
