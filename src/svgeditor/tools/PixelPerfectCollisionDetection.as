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

package svgeditor.tools
{
    import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.BitmapDataChannel;
import flash.display.BlendMode;
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.Sprite;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;

   
    public class PixelPerfectCollisionDetection
    {
        /** Are the two display objects colliding (overlapping)? **/
        public static function isColliding(target1:DisplayObject, target2:DisplayObject, sensitive:Boolean = false, debugSpr:Sprite = null):Boolean
        {
            //var collisionRect:Rectangle = getCollisionRect(target1, target2, commonParent, pixelPrecise, tolerance);
			var collisionRect:Rectangle = areaOfCollision(target1, target2, sensitive, debugSpr);

            if (collisionRect != null && collisionRect.size.length> 0) return true;
            else return false;
        }

		public static function areaOfCollision(object1:DisplayObject, object2:DisplayObject, sensitive:Boolean = false, debugSpr:Sprite = null):Rectangle {
			if (object1.hitTestObject(object2)) {
				var limits1:Rectangle = object1.getBounds(object1.stage);
				var limits2:Rectangle = object2.getBounds(object2.stage);
				var limits:Rectangle = limits1.intersection(limits2);
				limits.x = Math.floor(limits.x);
				limits.y = Math.floor(limits.y);
				limits.width = Math.ceil(limits.width);
				limits.height = Math.ceil(limits.height);
				if (limits.width < 1 || limits.height < 1) return null;

				var scaleX:Number = 1.0;
				var scaleY:Number = 1.0;
				if(limits.width < 20) {
					scaleX = Math.floor(20 / limits.width);
					var ow:int = limits.width;
					limits.width *= scaleX;
				}

				if(limits.height < 20) {
					scaleY = Math.floor(20 / limits.height);
					limits.height *= scaleY;
				}
				
				var image:BitmapData = new BitmapData(limits.width, limits.height, true);
				image.fillRect(image.rect, 0x00000000);
				var matrix:Matrix = object1.transform.concatenatedMatrix.clone();
				matrix.translate(-limits.left, -limits.top);
				matrix.scale(scaleX, scaleY);
				image.draw(object1, matrix, null, null, null, sensitive);
	            var alpha1:BitmapData = new BitmapData(limits.width, limits.height, false, 0);
	            alpha1.copyChannel(image, image.rect, new Point(0, 0), BitmapDataChannel.ALPHA, BitmapDataChannel.RED);

				image.fillRect(image.rect, 0x00000000);
				matrix = object2.transform.concatenatedMatrix.clone();
				matrix.translate(-limits.left, -limits.top);
				matrix.scale(scaleX, scaleY);
				image.draw(object2, matrix, null, null, null, sensitive);
	            var alpha2:BitmapData = new BitmapData(limits.width, limits.height, false, 0);
	            alpha2.copyChannel(image, image.rect, new Point(0, 0), BitmapDataChannel.ALPHA, BitmapDataChannel.GREEN);

				// combine the alpha maps
				alpha1.draw(alpha2, null, null, BlendMode.LIGHTEN);

				// find color
				var intersection:Rectangle = sensitive ? alpha1.getColorBoundsRect(0x010100, 0x010100) : alpha1.getColorBoundsRect(0x070700, 0x070700);
if(debugSpr) {
//	var spr:Sprite = object1.stage.getChildAt(0) as Sprite;
//	spr.graphics.lineStyle(1);
//	spr.graphics.drawRect(limits.x, limits.y, limits.width, limits.height);
	if(debugSpr.width > debugSpr.stage.stageWidth)
		while(debugSpr.numChildren)
			debugSpr.removeChildAt(0);
	var bm:Bitmap = new Bitmap(alpha1);
	bm.alpha = (intersection.width == 0 ? 0.5 : 1.0);
	bm.x = debugSpr.width + 2;
	debugSpr.addChild(bm);
}
				if(intersection.width == 0) return null;
//if(debugSpr) trace(intersection);
				intersection.offset(limits.left, limits.top);
				return intersection;
			}
			return null;
		}
    }
}