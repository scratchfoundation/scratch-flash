/**
 * BMPFunctions
 *
 * BMPFunctions class provides some functions to modify bitmapData.
 *
 * @author: Han Sanghun (http://hangunsworld.com, hanguns@gmail.com)
 * @created: 2007 10 06
 * @last modified: 2008 03 24
 *
 * Modify Histories
 * 2007 10 08: Adds floodFill method.
 * 2007 10 22: Adds addWatermark method.
 * 2008 03 24: Changes package directory.
 */

/*
 Licensed under the MIT License

 Copyright (c) 2008 Han Sanghun

 Permission is hereby granted, free of charge, to any person obtaining a copy of
 this software and associated documentation files (the "Software"), to deal in
 the Software without restriction, including without limitation the rights to
 use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 the Software, and to permit persons to whom the Software is furnished to do so,
 subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

 http://hangunsworld.com/code/com/hangunsworld/net/
 */
package com.hangunsworld.util{
	
	import	flash.display.BitmapData;
	import	flash.display.Sprite;
	import	flash.geom.Matrix;
	import	flash.geom.Rectangle;
	import	flash.geom.Point;
	
	public class BMPFunctions{
		
		
		
		/**
		* Flood fills on an image starting at an (x, y) cordinate and filling with a specific color.
		* The floodFill() method is similar to the paint bucket tool in various paint programs.
		*
		* @param bd The BitmapData to modify.
		* @param x The x cordinate of the image. 
		* @param y The y cordinate of the image.
		* @param color The color with which flood fills the image.
		* @param tolerance The similarity of colors. Ranges from 0 to 255. [OPTIONAL]
		* @param contiguous The continueity of the area to be filled. [OPTIONAL]
		*
		* @return A modified BitmapData.
		*/
		public static function floodFill(bd:BitmapData, x:uint, y:uint, color:uint, tolerance:uint=0, contiguous:Boolean=false):BitmapData{
			// Varlidates the (x, y) cordinates.
			x = Math.min(bd.width-1, x);
			y = Math.min(bd.height-1, y);
			// Validates the tolerance.
			tolerance = Math.max(0, Math.min(255, tolerance));
			
			// Gets the color of the selected point.
			var targetColor:uint = bd.getPixel32(x, y);
			
			if(contiguous){
				// Fills only the connected area.
				var w:uint = bd.width;
				var h:uint = bd.height;
				
				// Temporary BitmapData
				var temp_bd:BitmapData = new BitmapData(w, h, false, 0x000000);
				
				// Fills similar pixels with gray.
				temp_bd.lock();
				for(var i:uint=0; i<w; i++){
					for(var k:uint=0; k<h; k++){
						var d:int = BMPFunctions.getColorDifference32(targetColor, bd.getPixel32(i, k));
						if(d <= tolerance){
							temp_bd.setPixel(i, k, 0x333333);
						}
					}
				}
				temp_bd.unlock();
				
				// Fills the connected area with white.
				temp_bd.floodFill(x, y, 0xFFFFFF);
				
				// Uese threshold() to get the white pixels only.
				var rect:Rectangle = new Rectangle(0, 0, w, h);
				var pnt:Point = new Point(0, 0);
				temp_bd.threshold(temp_bd, rect, pnt, "<", 0xFF666666, 0xFF000000);
				
				// Gets the colorBoundsRect to minimizes a for loop.
				rect = temp_bd.getColorBoundsRect(0xFFFFFFFF, 0xFFFFFFFF);
				x = rect.x;
				y = rect.y;
				w = x + rect.width;
				h = y + rect.height;
				
				// Modifies the original image.
				bd.lock();
				for(i=x; i<w; i++){
					for(k=y; k<h; k++){
						if(temp_bd.getPixel(i, k) == 0xFFFFFF){
							bd.setPixel32(i, k, color);
						}
					}
				}
				bd.unlock();
			}else{
				// Fills all pixels similar to the targetColor.
				BMPFunctions.replaceColor(bd, targetColor, color, tolerance);
			}// end if else
			
			return bd;
		}// end floodFill
		
		
		
		/**
		* Replaces colors similar to color c1 with color c2.
		*
		* @param bd The BitmapData to modify.
		* @param c1 The color to be replaced.
		* @param c2 The color with which replaces c1.
		* @param tolerance The similarity of colors. Ranges from 0 to 255. [OPTIONAL]
		*
		* @return A modified BitmapData.
		*/
		public static function replaceColor(bd:BitmapData, c1:uint, c2:uint, tolerance:uint=0):BitmapData{
			// Validates the tolerance.
			tolerance = Math.max(0, Math.min(255, tolerance));
			
			bd.lock();
			var w:uint = bd.width;
			var h:uint = bd.height;
			for(var i:uint=0; i<w; i++){
				for(var k:uint=0; k<h; k++){
					var d:int = BMPFunctions.getColorDifference32(c1, bd.getPixel32(i, k));
					if(d <= tolerance){
						bd.setPixel32(i, k, c2);
					}
				}
			}
			bd.unlock();
			
			return bd;
		}// end replaceColor
		
		/**
		* Calculates of the difference of two colors on an RGB basis.
		*
		* @param c1 The first color to compare.
		* @param c2 The second color to compare.
		*
		* @return A difference of the two colors.
		*/
		public static function getColorDifference(c1:uint, c2:uint):int{
			var r1:int = (c1 & 0x00FF0000) >>> 16;
			var g1:int = (c1 & 0x0000FF00) >>> 8;
			var b1:int = (c1 & 0x0000FF);
			
			var r2:int = (c2 & 0x00FF0000) >>> 16;
			var g2:int = (c2 & 0x0000FF00) >>> 8;
			var b2:int = (c2 & 0x0000FF);
			
			var r:int = Math.pow((r1-r2), 2);
			var g:int = Math.pow((g1-g2), 2);
			var b:int = Math.pow((b1-b2), 2);
			
			var d:int = Math.sqrt(r + g + b);
			
			// Adjusts the range to 0-255.
			d = Math.floor(d / 441 * 255);
			
			return d;
		}// end getColorDifference
		
		/**
		* Calculates of the difference of two colors on an RGBA basis.
		*
		* @param c1 The first color to compare.
		* @param c2 The second color to compare.
		*
		* @return A difference of the two colors.
		*/
		public static function getColorDifference32(c1:uint, c2:uint):int{
			var a1:int = (c1 & 0xFF000000) >>> 24;
			var r1:int = (c1 & 0x00FF0000) >>> 16;
			var g1:int = (c1 & 0x0000FF00) >>> 8;
			var b1:int = (c1 & 0x0000FF);
			
			var a2:int = (c2 & 0xFF000000) >>> 24;
			var r2:int = (c2 & 0x00FF0000) >>> 16;
			var g2:int = (c2 & 0x0000FF00) >>> 8;
			var b2:int = (c2 & 0x0000FF);
			
			var a:int = Math.pow((a1-a2), 2);
			var r:int = Math.pow((r1-r2), 2);
			var g:int = Math.pow((g1-g2), 2);
			var b:int = Math.pow((b1-b2), 2);
			
			var d:int = Math.sqrt(a + r + g + b);
			
			// Adjusts the range to 0-255.
			d = Math.floor(d / 510 * 255);
			
			return d;
		}// end getColorDifference32
		
		
		/**
		* Applies watermarks to a BitmapData.
		*
		* @param bd A BitmapData to modify.
		* @param wm A BitmapData to be used as a watermark.
		* @param margin Space between watermarks. [OPTIONAL]
		* @param offset Offsets of the wartermark. [OPTIONAL]
		* @param scale Scale of the wartermark. [OPTIONAL]
		* @param rotation Rotation of the wartermark. [OPTIONAL]
		* @param alpha Transparency of the wartermark. [OPTIONAL]
		*
		* @return A BitmapData composited with watermarks.
		*/
		public static function addWatermark(bd:BitmapData, wm:BitmapData, margin:uint=0, offset:uint=0, scale:Number=1, rotation:uint=0, alpha:Number=1):BitmapData{
			// Validates parameters
			rotation = Math.min(360, rotation);
			alpha = Math.min(1, Math.max(0, alpha));
			
			// Watermark with margins.
			var wm2:BitmapData = new BitmapData(wm.width+margin, wm.height+margin, true, 0x00);
			var rect:Rectangle = new Rectangle(0, 0, wm.width, wm.height);
			var pnt:Point = new Point(0, 0);
			wm2.copyPixels(wm, rect, pnt);
			
			// Temporary Sprites to fill with watermarks.
			var sp1:Sprite = new Sprite();
			var sp2:Sprite = new Sprite();
			
			// Matrix
			var matrix:Matrix = new flash.geom.Matrix(); 
			matrix.translate(offset, offset);
			matrix.rotate(rotation / 180 * Math.PI);
			matrix.scale(scale, scale);
			
			// Fills the temporary Sprites.
			sp2.graphics.beginBitmapFill(wm2, matrix, true, true);
			sp2.graphics.drawRect(0, 0, bd.width, bd.height);
			sp2.graphics.endFill();
			
			sp1.addChild(sp2);
			sp2.alpha = alpha;
			
			// Draws watermarks to the original BitmapData.
			bd.draw(sp1);
			
			// Clears temporary Sprites.
			sp2.graphics.clear();
			sp1.removeChild(sp2);
			
			return bd;
		}// end addWatermark

		
	}// end class

}// end package