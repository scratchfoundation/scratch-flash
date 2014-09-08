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

package svgeditor
{
	import flash.display.*;
	import flash.text.*;
	import svgutils.*;
	import svgeditor.objs.SVGBitmap;
	import svgeditor.objs.SVGGroup;
	import svgeditor.objs.SVGShape;
	import svgeditor.objs.SVGTextField;

	public class Renderer
	{

		static public function renderToSprite(spr:Sprite, rootSVG:SVGElement):void {
			// Populate the given sprite with DisplayObjects (e.g. SVGBitmap) for the subelements of rootSVG.
			if (!rootSVG) return;
			for each (var el:SVGElement in rootSVG.subElements) {
				appendElementToSprite(el, spr);
			}
		}

		static private function appendElementToSprite(el:SVGElement, spr:Sprite):void {
			// Append a DisplayObject for the given element to the given sprite.
			if ('g' == el.tag) {
				var groupSprite:SVGGroup = new SVGGroup(el);
				renderToSprite(groupSprite, el);
				if (el.transform) groupSprite.transform.matrix = el.transform;
				spr.addChild(groupSprite);
			} else if ('image' == el.tag) {
				var bmp:SVGBitmap = new SVGBitmap(el);
				bmp.redraw();
				if (el.transform) bmp.transform.matrix = el.transform;
				spr.addChild(bmp);
			} else if ('text' == el.tag) {
				var tf:SVGTextField = new SVGTextField(el);
				tf.selectable = false;
				el.renderTextOn(tf);
				if (el.transform) tf.transform.matrix = el.transform;
				spr.addChild(tf);
			} else if (el.path) {
				var shape:SVGShape = new SVGShape(el);
				shape.redraw();
				if (el.transform) shape.transform.matrix = el.transform;
				spr.addChild(shape);
			}
		}

	}
}
