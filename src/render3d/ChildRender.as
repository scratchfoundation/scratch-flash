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

package render3d {
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	public class ChildRender extends BitmapData {
		private const allowPartial:Boolean = true;
		private const maxSize:uint = 1022;
		private const halfSize:uint = maxSize >> 1;
		private var orig_width:Number;
		private var orig_height:Number;
		private var orig_bounds:Rectangle;
		public var inner_x:Number;
		public var inner_y:Number;
		public var inner_w:Number;
		public var inner_h:Number;
		public var scale:Number;
		public function ChildRender(w:Number, h:Number, dispObj:DisplayObject, penLayer:DisplayObject, b:Rectangle) {
			orig_width = w;
			orig_height = h;
			orig_bounds = b;
			scale = 1;

			reset(dispObj, penLayer);

			super(Math.ceil(Math.min(w, maxSize)), Math.ceil(Math.min(h, maxSize)), true, 0);
		}

		public function reset(dispObj:DisplayObject, penLayer:DisplayObject):void {
			inner_x = inner_y = 0;
			inner_w = inner_h = 1;

			if(!allowPartial) {
				if(orig_width > maxSize || orig_height > maxSize)
					scale = maxSize / Math.max(orig_width, orig_height);

				return;
			}

			// Is it too large and needs to be partially rendered?
			var bounds:Rectangle;
			if(orig_width > maxSize || orig_height > maxSize) {
				bounds = getVisibleBounds(dispObj, penLayer);
				bounds.inflate(halfSize - bounds.width / 2, 0);
				if(bounds.x < 0) {
					bounds.width += bounds.x;
					bounds.x = 0;
				}
				if(bounds.right > orig_width)
					bounds.width += orig_width - bounds.right;

				inner_x = bounds.x / orig_width;
				inner_w = maxSize / orig_width;
			}

			if(orig_height > maxSize) {
				if(!bounds) bounds = getVisibleBounds(dispObj, penLayer);
				bounds.inflate(0, halfSize - bounds.height / 2);
				if(bounds.y < 0) {
					bounds.height += bounds.y;
					bounds.y = 0;
				}
				if(bounds.bottom > orig_height)
					bounds.height += orig_height - bounds.bottom;

				inner_y = bounds.y / orig_height;
				inner_h = maxSize / orig_height;
			}
		}

		public function isPartial():Boolean {
			return allowPartial && (width < orig_width || height < orig_height);
		}

		public function get renderWidth():Number {
			return (width > orig_width ? orig_width : width);
		}

		public function get renderHeight():Number {
			return (height > orig_height ? orig_height : height);
		}

		public function needsResize(w:Number, h:Number):Boolean {
			if(width > orig_width && Math.ceil(w) > width) {
				return true;
			}
			if(height > orig_height && Math.ceil(h) > height) {
				return true;
			}

			return false;
		}

		public function needsRender(dispObj:DisplayObject, w:Number, h:Number, penLayer:DisplayObject):Boolean {
			if(inner_x == 0 && inner_y == 0 && inner_w == 1 && inner_h == 1) return false;

			var renderRect:Rectangle = new Rectangle(inner_x*w, inner_y*h, inner_w*w, inner_h*h);
			renderRect.width += 0.001;
			renderRect.height += 0.001;
			var stageRect:Rectangle = getVisibleBounds(dispObj, penLayer);
			var containsStage:Boolean = renderRect.containsRect(stageRect);
			return !containsStage;
		}

		private function getVisibleBounds(dispObj:DisplayObject, penLayer:DisplayObject):Rectangle {
			var visibleBounds:Rectangle = penLayer.getBounds(dispObj);
			var tl:Point = orig_bounds.topLeft;
			visibleBounds.offset(-tl.x, -tl.y);
			if(visibleBounds.x < 0) {
				visibleBounds.width += visibleBounds.x;
				visibleBounds.x = 0;
			}
			if(visibleBounds.y < 0) {
				visibleBounds.height += visibleBounds.y;
				visibleBounds.y = 0;
			}
			if(visibleBounds.right > orig_width) {
				visibleBounds.width += orig_width - visibleBounds.right;
			}
			if(visibleBounds.bottom > orig_height) {
				visibleBounds.height += orig_height - visibleBounds.bottom;
			}
			visibleBounds.x *= dispObj.scaleX;
			visibleBounds.y *= dispObj.scaleY;
			visibleBounds.width *= dispObj.scaleX;
			visibleBounds.height *= dispObj.scaleY;

			return visibleBounds;
		}
	}
}
