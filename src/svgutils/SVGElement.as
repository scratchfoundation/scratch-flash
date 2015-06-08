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

// SVGElement.as
// John Maloney, April 2012.
//
// An SVGElement represents an an SVG file element. All SVGElements have a tag, id,
// and a dictionary of attributes. Some elements (e.g. 'g' and 'svg' elements) may
// have a non-empty subElement array. Text elements have a non-null text, image
// elements have a non-null bitmap, and path elements have a non-null path.
//
// SVGElements can convert SVG colors in various formats to an integer RGB value.

package svgutils {
	import flash.display.*;
	import flash.geom.*;
	import flash.text.*;

	import svgeditor.DrawProperties;

public class SVGElement {

	public var tag:String;
	public var id:String;
	public var attributes:Object;
	public var subElements:Array;

	public var bitmap:BitmapData;
	public var path:SVGPath;
	public var text:String;
	public var transform:Matrix;

	public function SVGElement(tag:String, id:String = '') {
		if (!id || (id.length == 0)) id = 'ID' + Math.random();
		this.tag = tag;
		this.id = id;
		this.attributes = {};
		this.subElements = [];
	}

	public function allElements():Array {
		// Return an array of all my SVG elements (visible and not) in rendering order.
		function collectElements(el:SVGElement):void {
			result.push(el);
			for each (var subEl:SVGElement in el.subElements) collectElements(subEl);
		}
		var result:Array = [];
		collectElements(this);
		return result;
	}

	public function clone():SVGElement {
		// Return a shallow copy (no subElements) of the current SVGElement.
		var copy:SVGElement = new SVGElement(tag, id);
		copy.attributes = {};
		for (var attr:String in attributes) {
			var v:* = attributes[attr];
			if (v is Array) v = v.concat(); // make a copy of array value
			copy.attributes[attr] = v;
		}
		copy.bitmap = bitmap;
		if(path) copy.path = path.clone();
		copy.text = text;
		if(transform) copy.transform = transform.clone();
		return copy;
	}

	public static function makeBitmapEl(bm:BitmapData, scale:Number = 1):SVGElement {
		// Create an SVGElement for the given bitmap.
		var el:SVGElement = new SVGElement('image');
		el.bitmap = bm;
		el.setAttribute('x', 0);
		el.setAttribute('y', 0);
		el.setAttribute('width', bm.width);
		el.setAttribute('height', bm.height);
		if (scale != 1) {
			el.transform = new Matrix();
			el.transform.scale(scale, scale);
		}
		return el;
	}

	public function setShapeStroke(props:DrawProperties):void {
		if(props.alpha > 0 && tag != 'text') {
			setAttribute('stroke', colorToHex(props.color & 0xFFFFFF));
			setAttribute('stroke-width', props.strokeWidth);
		} else {
			setAttribute('stroke', 'none');
		}
	}

	public function setShapeFill(props:DrawProperties):void {
		var fillable:Boolean = props.alpha>0 && (tag != 'path' || !path || path.getSegmentEndPoints()[2]);
		setAttribute('fill', (fillable ? colorToHex(props.color & 0xFFFFFF) : 'none'));
	}

	public function applyShapeProps(props:DrawProperties):void {
		var isShape:Boolean = (tag == 'path' || tag == 'ellipse' || tag == 'rect' || tag == 'polylines');
		if (isShape && getAttribute('stroke') != 'none')
			setAttribute('stroke-width', props.strokeWidth);
		if (tag == 'text') {
			setAttribute('fill', colorToHex(props.color & 0xFFFFFF));
		}
	}

	public function setFont(fontName:String, fontSize:int = 0):void {
		if (tag == 'text') {
			setAttribute('font-family', fontName);
			if (fontSize > 0) setAttribute('font-size', fontSize);
		}
	}

	// Detects if this is part of the background of a backdrop
	public function isBackDropBG():Boolean {
		return ('scratch-type' in attributes && attributes['scratch-type'].indexOf('backdrop-') === 0);
	}

	public function isBackDropFill():Boolean {
		return ('scratch-type' in attributes && attributes['scratch-type'] == 'backdrop-fill');
	}

	public function alpha():Number {
		var a:Number = Number(getAttribute('opacity', 1));
		if (a >= 1) return 1;
		return (a > 0) ? a : 0;
	}

	public function getAttribute(key:String, defaultIfMissing:* = undefined):* {
		// Return the value of the given attribute or the given default
		// value if the attribute is missing.
		if(attributes.hasOwnProperty(key)) {
			var rawValue:* = attributes[key];
			if(rawValue is String && rawValue.indexOf('%') == rawValue.length - 1)
				return parseFloat(rawValue) / 100;
			// This fixes corrupted gradients created
			else if(defaultIfMissing is Number && rawValue === 'undefined')
				return defaultIfMissing;

			return rawValue;
		}
		return defaultIfMissing;
	}

	public function setAttribute(key:String, value:*):void {
		if (value === null || value === undefined) {
			delete attributes[key];
		} else {
			attributes[key] = value;
		}
	}

	public function deleteAttributes(keys:Array):void {
		for each (var k:String in keys) delete attributes[k];
	}

	public function extractNumericArgs(input:String):Array {
		// Parse a string containing one more numeric arguments and return an array of Numbers.
		var result:Array = [];
		var numStrings:Array = input.match(/(?:\+|-)?\d+(?:\.\d+)?(?:e(?:\+|-)?\d+)?/g);
		for each (var s:String in numStrings) result.push(Number(s));
		return result;
	}

	public function convertToPath():void {
		// Convert a circle, ellipse, line, polyline, polygon, or rect into a path with
		// a 'points' attribute (an array of Points) for internal use and an SVG 'd'
		// attribute (a string containing path commands) for export.
		// Note: For ellipses, this code is only doing a poor approximation of what it
		// should really do. Right now, it's grabbing the end points out of the C commands
		// while ignoring the control points. It should be generating a sequence of points
		// that cause Paula's curve drawing algorithm to create the same shape (i.e. curve
		// fitting).
		new SVGImportPath().generatePathCmds(this);
		deleteAttributes(['cx', 'cy', 'rx', 'ry', 'r']); // delete circle/ellipse attributes
		deleteAttributes(['x', 'y', 'width', 'height']); // delete rectangle attributes
		deleteAttributes(['x1', 'y1', 'x2', 'y2']); // delete rectangle attributes
		setAttribute('d', SVGExport.pathCmds(path));
		setAttribute('stroke-linecap', 'round');
		tag = 'path';
	}

	public function setPath(pathStr:String):void {
		setAttribute('d', pathStr);
		updatePath();
	}

	public function updatePath():void {
		// This can be used to update the path for, say, a rectangle or ellipse after
		// changing their attributes.
		new SVGImportPath().generatePathCmds(this);
	}

	// -----------------------------
	// Rendering
	//------------------------------

	public function renderImageOn(bmp:Bitmap):void {
		// Render an image element on the given Bitmap.
		var bmData:BitmapData = bitmap;
		if (bmData == null) { // image not yet loaded; use a placeholder (a magenta rectangle)
			var w:int = getAttribute('width', 10);
			var h:int = getAttribute('height', 10);
			bmData = new BitmapData(w, h, false, 0xFF00FF);
		}
		bmp.bitmapData = bmData;
		bmp.x = getAttribute('x', 0);
		bmp.y = getAttribute('y', 0);
		bmp.alpha = alpha();
		if (transform) bmp.transform.matrix = transform;
	}

	public function renderPathOn(s:Shape, forHitTest:Boolean = false):void {
		SVGPath.render(this, s.graphics, forHitTest);
		//s.alpha = alpha();
		//if (transform) s.transform.matrix = transform;
	}

	public function renderTextOn(tf:TextField):void {
		// Render a text element on the given TextField.
		// For now, always use an embedded font to allow rotation.
		const useEmbeddedFont:Boolean = true;
		if (!text) return;
		var fmt:TextFormat = new TextFormat(
			getAttribute('font-family', 'Helvetica'),
			getAttribute('font-size', 18),
			0, // textColor is set below
			(getAttribute('font-weight') == 'bold'),
			(getAttribute('font-style') == 'italic')
		);
		if (useEmbeddedFont) {
			if (!hasEmbeddedFont(fmt.font)) {
				setAttribute('font-family', 'Helvetica');
				fmt.font = 'Helvetica';
			}
			tf.embedFonts = true;
			tf.antiAliasType = AntiAliasType.ADVANCED;
		}
		tf.defaultTextFormat = fmt;
		tf.text = text;
		tf.width = tf.textWidth + 6;
		tf.height = tf.textHeight + 4;
		var c:String = getAttribute('fill', null);
		if (!c) c = getAttribute('stroke', 'black');
		tf.textColor = getColorValue(c);

		// Adjust for the 2-pixel TextField inset (gutter) and the
		// fact that the y-origin for SVG text is the baseline.
		var ascent:Number = tf.getLineMetrics(0).ascent;
		tf.x = getAttribute('x', 0) - 2;
		tf.y = (getAttribute('y', 0) - ascent) - 2;

		// Adjust by dx and dy.
		tf.x += Number(getAttribute('dx', 0));
		tf.y += Number(getAttribute('dy', 0));

		// Adjust x position if text-anchor is middle or end.
		// Note: start/end should take the text direction into account.
		var anchor:String = getAttribute('text-anchor', 'start');
		if ('end' == anchor) tf.x -= tf.textWidth;
		if ('middle' == anchor) tf.x -= (tf.textWidth / 2);

		tf.alpha = alpha();
		if (transform) tf.transform.matrix = transform;
	}

	private function hasEmbeddedFont(fontName:String):Boolean {
		for each (var f:Font in Font.enumerateFonts(false)) {
			if (fontName == f.fontName) return true;
		}
		return false;
	}

	// -----------------------------
	// Colors
	//------------------------------

	private function testColorValue():void {
		// Unit tests for the getColorValue() function.
		var tests:Array = ['red', 'purple', '#F70', '#FF8000', 'rgb(255, 128, 0)', 'rgb(100%, 50%, 0%)'];
		for each (var s:String in tests) {
			trace(s + ' -> ' + getColorValue(s).toString(16));
		}
	}

	static public function colorToHex(c:uint):String {
		var s:String = c.toString(16).toUpperCase();
		while (s.length < 6) s = '0' + s;
		return '#' + s;
	}

	public function getColorValue(attrValue:*):int {
		var s:String = attrValue as String;
		if (!s || (s == 'none') || (s == '')) return 0x808080;
		if (s.charAt(0) == '#') { // #RGB or #RRGGBB
			s = s.slice(1);
			if (s.length < 6) s = s.charAt(0) + s.charAt(0) + s.charAt(1) + s.charAt(1) + s.charAt(2) + s.charAt(2);
			return int('0x' + s);
		}
		var i:int = s.indexOf('rgb(');
		if (i == 0) {
			s = s.slice(4, s.length - 1);
			var rgb:Array = s.split(',');
			if (s.indexOf('%') > -1) { // rgb(R%, G%, B%)
				return (colorPercent(rgb[0]) << 16) | (colorPercent(rgb[1]) << 8) | colorPercent(rgb[2]);
			} else { // rgb(rrr, ggg, bbb)
				return (colorComponent(rgb[0]) << 16) | (colorComponent(rgb[1]) << 8) | colorComponent(rgb[2]);
			}
		}
		return getColorByName(s);
	}

	private function colorPercent(s:String):int {
		var i:int = s.indexOf('%');
		if (i > -1) s = s.slice(0, i);
		var fraction:Number = Math.max(0, Math.min(Number(s) / 100, 1));
		return 255 * fraction;
	}

	private function colorComponent(s:String):int {
		return Math.max(0, Math.min(Number(s), 255));
	}

	private function getColorByName(colorName:String):int {
		// Return an RGB value for the given color name or zero (black) if
		// the color name is not recognized.
		return namedColors[colorName.toLowerCase()];
	}

	private const namedColors:Object = {
		'aliceblue': 0xF0F8FF,
		'antiquewhite': 0xFAEBD7,
		'aqua': 0x00FFFF,
		'aquamarine': 0x7FFFD4,
		'azure': 0xF0FFFF,
		'beige': 0xF5F5DC,
		'bisque': 0xFFE4C4,
		'black': 0x000000,
		'blanchedalmond': 0xFFEBCD,
		'blue': 0x0000FF,
		'blueviolet': 0x8A2BE2,
		'brown': 0xA52A2A,
		'burlywood': 0xDEB887,
		'cadetblue': 0x5F9EA0,
		'chartreuse': 0x7FFF00,
		'chocolate': 0xD2691E,
		'coral': 0xFF7F50,
		'cornflowerblue': 0x6495ED,
		'cornsilk': 0xFFF8DC,
		'crimson': 0xDC143C,
		'cyan': 0x00FFFF,
		'darkblue': 0x00008B,
		'darkcyan': 0x008B8B,
		'darkgoldenrod': 0xB8860B,
		'darkgray': 0xA9A9A9,
		'darkgrey': 0xA9A9A9,
		'darkgreen': 0x006400,
		'darkkhaki': 0xBDB76B,
		'darkmagenta': 0x8B008B,
		'darkolivegreen': 0x556B2F,
		'darkorange': 0xFF8C00,
		'darkorchid': 0x9932CC,
		'darkred': 0x8B0000,
		'darksalmon': 0xE9967A,
		'darkseagreen': 0x8FBC8F,
		'darkslateblue': 0x483D8B,
		'darkslategray': 0x2F4F4F,
		'darkslategrey': 0x2F4F4F,
		'darkturquoise': 0x00CED1,
		'darkviolet': 0x9400D3,
		'deeppink': 0xFF1493,
		'deepskyblue': 0x00BFFF,
		'dimgray': 0x696969,
		'dimgrey': 0x696969,
		'dodgerblue': 0x1E90FF,
		'firebrick': 0xB22222,
		'floralwhite': 0xFFFAF0,
		'forestgreen': 0x228B22,
		'fuchsia': 0xFF00FF,
		'gainsboro': 0xDCDCDC,
		'ghostwhite': 0xF8F8FF,
		'gold': 0xFFD700,
		'goldenrod': 0xDAA520,
		'gray': 0x808080,
		'grey': 0x808080,
		'green': 0x008000,
		'greenyellow': 0xADFF2F,
		'honeydew': 0xF0FFF0,
		'hotpink': 0xFF69B4,
		'indianred': 0xCD5C5C,
		'indigo': 0x4B0082,
		'ivory': 0xFFFFF0,
		'khaki': 0xF0E68C,
		'lavender': 0xE6E6FA,
		'lavenderblush': 0xFFF0F5,
		'lawngreen': 0x7CFC00,
		'lemonchiffon': 0xFFFACD,
		'lightblue': 0xADD8E6,
		'lightcoral': 0xF08080,
		'lightcyan': 0xE0FFFF,
		'lightgoldenrodyellow': 0xFAFAD2,
		'lightgray': 0xD3D3D3,
		'lightgrey': 0xD3D3D3,
		'lightgreen': 0x90EE90,
		'lightpink': 0xFFB6C1,
		'lightsalmon': 0xFFA07A,
		'lightseagreen': 0x20B2AA,
		'lightskyblue': 0x87CEFA,
		'lightslategray': 0x778899,
		'lightslategrey': 0x778899,
		'lightsteelblue': 0xB0C4DE,
		'lightyellow': 0xFFFFE0,
		'lime': 0x00FF00,
		'limegreen': 0x32CD32,
		'linen': 0xFAF0E6,
		'magenta': 0xFF00FF,
		'maroon': 0x800000,
		'mediumaquamarine': 0x66CDAA,
		'mediumblue': 0x0000CD,
		'mediumorchid': 0xBA55D3,
		'mediumpurple': 0x9370D8,
		'mediumseagreen': 0x3CB371,
		'mediumslateblue': 0x7B68EE,
		'mediumspringgreen': 0x00FA9A,
		'mediumturquoise': 0x48D1CC,
		'mediumvioletred': 0xC71585,
		'midnightblue': 0x191970,
		'mintcream': 0xF5FFFA,
		'mistyrose': 0xFFE4E1,
		'moccasin': 0xFFE4B5,
		'navajowhite': 0xFFDEAD,
		'navy': 0x000080,
		'oldlace': 0xFDF5E6,
		'olive': 0x808000,
		'olivedrab': 0x6B8E23,
		'orange': 0xFFA500,
		'orangered': 0xFF4500,
		'orchid': 0xDA70D6,
		'palegoldenrod': 0xEEE8AA,
		'palegreen': 0x98FB98,
		'paleturquoise': 0xAFEEEE,
		'palevioletred': 0xD87093,
		'papayawhip': 0xFFEFD5,
		'peachpuff': 0xFFDAB9,
		'peru': 0xCD853F,
		'pink': 0xFFC0CB,
		'plum': 0xDDA0DD,
		'powderblue': 0xB0E0E6,
		'purple': 0x800080,
		'red': 0xFF0000,
		'rosybrown': 0xBC8F8F,
		'royalblue': 0x4169E1,
		'saddlebrown': 0x8B4513,
		'salmon': 0xFA8072,
		'sandybrown': 0xF4A460,
		'seagreen': 0x2E8B57,
		'seashell': 0xFFF5EE,
		'sienna': 0xA0522D,
		'silver': 0xC0C0C0,
		'skyblue': 0x87CEEB,
		'slateblue': 0x6A5ACD,
		'slategray': 0x708090,
		'slategrey': 0x708090,
		'snow': 0xFFFAFA,
		'springgreen': 0x00FF7F,
		'steelblue': 0x4682B4,
		'tan': 0xD2B48C,
		'teal': 0x008080,
		'thistle': 0xD8BFD8,
		'tomato': 0xFF6347,
		'turquoise': 0x40E0D0,
		'violet': 0xEE82EE,
		'wheat': 0xF5DEB3,
		'white': 0xFFFFFF,
		'whitesmoke': 0xF5F5F5,
		'yellow': 0xFFFF00,
		'yellowgreen': 0x9ACD32
	}

}}
