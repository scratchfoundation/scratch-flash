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

// SVGDisplayRender.as
// John Maloney, April 2012.
//
// An SVGDisplayRender converts an SVGElement tree (the result of importing an SVG file)
// into a Flash Sprite with children representing the visual elements of the SVG as
// Flash DisplayObjects. For example, SVG image elements become Bitmaps, path elements
// become Shapes, and text elements become TextFields. For efficiency, multiple path
// elements are drawn onto a single Shape. This speeds up drawing the sprite and also
// saves a little memory.
//
// SVGDisplayRender is optimized for for displaying an SVG image as a Scratch costume
// or scene, possibly scaled or rotated. A vector graphics editor would use a different
// internal representation optimized for editing.

package svgutils {
	import flash.display.*;
	import flash.geom.Rectangle;
	import flash.text.TextField;

public class SVGDisplayRender {

	private var svgSprite:Sprite;
	private var currentShape:Shape;
	private var forHitTest:Boolean;

	public function renderAsSprite(rootSVG:SVGElement, doShift:Boolean = false, forHitTest:Boolean = false):Sprite {
		// Return a sprite containing all the SVG elements that Scratch can render.
		// If doShift is true, shift visible objects so the visible bounds is at (0,0).

		this.forHitTest = forHitTest;
		svgSprite = new Sprite();
		if (!rootSVG) return svgSprite;

		for each (var el:SVGElement in rootSVG.allElements()) renderElement(el);
		if (currentShape) svgSprite.addChild(currentShape); // add final shape layer, if any

		if (doShift) {
			var r:Rectangle = svgSprite.getBounds(svgSprite);
			if ((r.x != 0) || (r.y != 0)) {
				// Shift all chidren so that the bounding box of visible part is at 0,0.
				for (var i:int = 0; i < svgSprite.numChildren; i++) {
					var c:DisplayObject = svgSprite.getChildAt(i);
					c.x += -r.x;
					c.y += -r.y;
				}
			}
		}
		return svgSprite;
	}

	private function renderElement(el:SVGElement):void {
		// Render the given element, either by adding a new child to svgSprite or
		// by drawing onto the current shape.
		if ('image' == el.tag) {
			var bmp:Bitmap = new Bitmap();
			el.renderImageOn(bmp);
			addLayer(bmp);
		} else if ('text' == el.tag) {
			var tf:TextField = new TextField();
			tf.selectable = false;
			tf.mouseEnabled = false;
			tf.tabEnabled = false;
			el.renderTextOn(tf);
			addLayer(tf);
		} else if (el.path) {
//			if (!currentShape) currentShape = new Shape();
			var shape:Shape = new Shape();
			el.renderPathOn(shape, forHitTest);
			if(el.transform) shape.transform.matrix = el.transform;
			addLayer(shape);
		}
	}

	private function addLayer(obj:DisplayObject):void {
		// Add the given display object, but first add and clear the current shape, if any.
		if (currentShape) {
			svgSprite.addChild(currentShape);
			currentShape = null;
		}
		svgSprite.addChild(obj);
	}

}}
