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
	import flash.events.*;
	import flash.geom.*;
	import flash.ui.Mouse;
	import assets.Resources;
	import svgeditor.objs.SVGShape;
	import uiwidgets.*;

	public class ImageCanvas extends Sprite
	{
		private var visibleArea:Sprite;
		private var interactiveLayer:Sprite;
		private var visibleCanvas:Sprite;
		private var contentLayer:Sprite;
		private var bitmapLayer:Bitmap;
		private var visibleMask:Shape;

		static public const canvasWidth:uint = 480;
		static public const canvasHeight:uint = 360;
		static private const canvasBorderWidth:uint = 25;
		static private const scrollbarThickness:int = 9;
		static private const maxZoom:Number = 16;
		private var hScrollbar:Scrollbar;
		private var vScrollbar:Scrollbar;
		private var visibleRect:Rectangle;
		private var currWidth:uint;
		private var currHeight:uint;
		private var isZoomedIn:Boolean;
		private var editor:ImageEdit;

		public function ImageCanvas(w:uint, h:uint, ed:ImageEdit) {
			editor = ed;
			createLayers();

			hScrollbar = new Scrollbar(50, scrollbarThickness, setHScroll);
			hScrollbar.addEventListener(Event.SCROLL, scrollEventHandler, false, 0, true);
			hScrollbar.addEventListener(Event.COMPLETE, scrollEventHandler, false, 0, true);
			addChild(hScrollbar);
			vScrollbar = new Scrollbar(scrollbarThickness, 50, setVScroll);
			vScrollbar.addEventListener(Event.SCROLL, scrollEventHandler, false, 0, true);
			vScrollbar.addEventListener(Event.COMPLETE, scrollEventHandler, false, 0, true);
			addChild(vScrollbar);

			currWidth = currHeight = 0;
			isZoomedIn = false;
			resize(w, h);
		}

		private function scrollEventHandler(e:Event):void {
			var showTool:Boolean = (e.type == Event.COMPLETE);
			editor.getToolsLayer().visible = showTool;
			if(showTool) {
				editor.refreshCurrentTool();
			}
		}

		public function toggleContentInteraction(enable:Boolean):void {
			visibleArea.mouseEnabled = enable;
			visibleArea.mouseChildren = enable;
		}

		public function getVisibleLayer():Sprite {
			return visibleCanvas;
		}

		public function getVisibleRect(relative:Sprite):Rectangle {
			return visibleArea.getRect(relative);
		}

		public function getMaskRect(relative:Sprite):Rectangle {
			return visibleMask.getRect(relative);
		}

		public function getInteractionLayer():Sprite {
			return interactiveLayer;
		}

		public function getContentLayer():Sprite {
			return contentLayer;
		}

		public function getBitmap():Bitmap {
			return bitmapLayer;
		}

		public function bitmapMousePoint():Point {
			if (!bitmapLayer) return new Point(0, 0);
			var bm:BitmapData = bitmapLayer.bitmapData;
			var x:int = Math.min(bm.width, Math.max(0, visibleArea.mouseX / bitmapLayer.scaleX));
			var y:int = Math.min(bm.height, Math.max(0, visibleArea.mouseY / bitmapLayer.scaleY));
			return new Point(x, y);
		}

		public function clickInBitmap(stageX:int, stageY:int):Boolean {
			var globalR:Rectangle = visibleMask.getRect(stage);
			return globalR.contains(stageX, stageY);
		}

		public function addBitmapFeedback(feedbackObj:DisplayObject):void {
			visibleArea.addChild(feedbackObj);
		}

		public function getScale():Number { return visibleArea.scaleX }

		private function createLayers():void {
			interactiveLayer = new Sprite();
			addChild(interactiveLayer);

			visibleMask = new Shape();
			addChild(visibleMask);

			visibleArea = new Sprite();
			addChild(visibleArea);
			visibleCanvas = new Sprite();
			visibleCanvas.mouseEnabled = false;
			visibleArea.addChild(visibleCanvas);

			contentLayer = new Sprite();

			if (editor is BitmapEdit) {
				// Bitmap editor works at double resolution.
				var bm:BitmapData = new BitmapData(960, 720, true, 0);
				visibleArea.addChild(bitmapLayer = new Bitmap(bm));
				bitmapLayer.scaleX = bitmapLayer.scaleY = 0.5;
			}

			visibleArea.mask = visibleMask;
			visibleArea.addChild(contentLayer);
		}

		public function clearContent():void {
			while(contentLayer.numChildren > 0) contentLayer.removeChildAt(0);
		}

		public function getBackDropFills():Array {
			var fills:Array = [];
			for(var i:uint=0; i< contentLayer.numChildren; ++i) {
				var dObj:DisplayObject = contentLayer.getChildAt(i);
				if(dObj is SVGShape) {
					var st:String = (dObj as SVGShape).getElement().getAttribute('scratch-type');
					if(st == 'backdrop-fill')
						fills.push(dObj);
				}
			}

			return fills;
		}

		public function addBackdropFill(s:SVGShape):void {
			contentLayer.addChildAt(s, 0);
		}

		public function addBackdropStroke(s:SVGShape):void {
			for(var i:uint=0; i<contentLayer.numChildren; ++i) {
				var dObj:DisplayObject = contentLayer.getChildAt(i);
				if(!(dObj is SVGShape) || (dObj as SVGShape).getElement().getAttribute('scratch-type') != 'backdrop-fill') {
					contentLayer.addChildAt(s, i);
					return;
				}
			}

			contentLayer.addChildAt(s, i);
		}

		private function getZoomLevelZero(w:uint, h:uint):Number {
			if (editor is BitmapEdit) return 1;
return 1; // Force integer scaling in both editors for now
			var aspectRatio:Number = canvasWidth / canvasHeight;
			var availRatio:Number = w / h;
			return (availRatio > aspectRatio ?
				aspectRatio * h / canvasWidth :
				w / (aspectRatio * canvasHeight));
		}

		public function resize(w:uint, h:uint):void {
			var left:int = 0;
			var top:int = 0;
			var visibleW:int = w - vScrollbar.w;
			var visibleH:int = h - hScrollbar.h;

			// Set dimensions which fit within the available area and maintain the proper aspect ratio
			var zoomLevelZero:Number = getZoomLevelZero(visibleW, visibleH);
			if(!isZoomedIn || visibleArea.scaleX < zoomLevelZero) {
				visibleArea.scaleX = visibleArea.scaleY = zoomLevelZero;
				isZoomedIn = false;
				editor.updateZoomReadout();
			}

			if(visibleArea.scaleX * canvasWidth < visibleW - 1) {
				left = (visibleW - visibleArea.scaleX * canvasWidth);
				visibleW -= left;
				left *= 0.5;
			}

			if(visibleArea.scaleX * canvasHeight < visibleH - 1) {
				top = (visibleH - visibleArea.scaleX * canvasHeight);
				visibleH -= top;
				top *= 0.5;
			}

			drawGrid();

			var g:Graphics = visibleMask.graphics;
			g.clear();
			g.beginFill(0xF0F000);
			g.drawRect(left, top, visibleW, visibleH);
			g.endFill();

			// TODO: Make the interactive margins only exist when there is no scrollbar in their way
			g = interactiveLayer.graphics;
			g.clear();
			g.beginFill(0xF0F000, 0);
			g.drawRect(left-canvasBorderWidth, top-canvasBorderWidth, visibleW + 2*canvasBorderWidth, visibleH + 2*canvasBorderWidth);
			g.endFill();

			// Adjust the scroll position properly without losing our visible canvas position
			visibleRect = visibleMask.getRect(this);
			var maxScrollH:Number = visibleRect.right - visibleArea.scaleX * canvasWidth;
			var maxScrollV:Number = visibleRect.bottom - visibleArea.scaleY * canvasHeight;
			visibleArea.x = Math.max(maxScrollH, Math.min(visibleRect.left, visibleArea.x));
			visibleArea.y = Math.max(maxScrollV, Math.min(visibleRect.top, visibleArea.y));
			updateScrollbars();

			currWidth = w;
			currHeight = h;
		}

		private function drawGrid():void {
			// Draw the background grid and center guide lines.

			var g:Graphics = visibleCanvas.graphics;
			g.clear();
			g.beginBitmapFill(Resources.createBmp('canvasGrid').bitmapData);
			g.drawRect(0, 0, canvasWidth, canvasHeight);
			g.endFill();

			// center lines
			var lineColor:int = 0xB0B0B0;
			var thickness:Number = 0.5;
			var centerX:Number = canvasWidth / 2;
			var centerY:Number = canvasHeight / 2;
			g.beginFill(lineColor);
			g.drawRect(centerX - 4, centerY - (thickness / 2), 8, thickness);
			g.beginFill(lineColor);
			g.drawRect(centerX - (thickness / 2), centerY - 4, thickness, 8);
		}

		private function setHScroll(frac:Number):void {
			visibleArea.x = Math.round(visibleRect.left - frac * maxScrollH());
		}

		private function setVScroll(frac:Number):void {
			visibleArea.y = Math.round(visibleRect.top - frac * maxScrollV());
		}

		private function maxScrollH():int {
			return Math.max(0, visibleArea.scaleX * canvasWidth - visibleMask.width);
		}

		private function maxScrollV():int {
			return Math.max(0, visibleArea.scaleY * canvasHeight - visibleMask.height);
		}

		private function updateScrollbars():void {
			var margin:int = 2;
			var r:Rectangle = visibleMask.getRect(this);
			hScrollbar.x = r.x;
			hScrollbar.y = r.bottom + margin;
			hScrollbar.setWidthHeight(visibleMask.width, hScrollbar.h);
			hScrollbar.visible = hScrollbar.update(-visibleArea.x / maxScrollH(), r.width / (visibleArea.scaleX * canvasWidth));

			vScrollbar.x = r.right + margin;
			vScrollbar.y = r.top;
			vScrollbar.setWidthHeight(vScrollbar.w, visibleMask.height);
			vScrollbar.visible = vScrollbar.update(-visibleArea.y / maxScrollV(), r.height / (visibleArea.scaleY * canvasHeight));
		}

		public function centerAround(p:Point):void {
			p = visibleArea.globalToLocal(p);
			p.x *= visibleArea.scaleX;
			p.y *= visibleArea.scaleY;
			setHScroll(Math.min(1, Math.max(0, (p.x - visibleMask.width * 0.5) / maxScrollH())));
			setVScroll(Math.min(1, Math.max(0, (p.y - visibleMask.height * 0.5) / maxScrollV())));
			resize(currWidth, currHeight);
			//updateScrollbars();
		}

		public function zoomOut():void {
			var r:Rectangle = visibleMask.getRect(visibleMask);
			var p:Point = new Point(r.x + r.width / 2, r.y + r.height / 2);
			p = visibleMask.localToGlobal(p);
			var zoomPos:Point = p;
			p = visibleArea.globalToLocal(p);
			visibleArea.scaleX *= 0.5;
			visibleArea.scaleY *= 0.5;
			editor.updateZoomReadout();

			p = visibleArea.localToGlobal(p).subtract(zoomPos);
			visibleArea.x -= p.x;
			visibleArea.y -= p.y;
			resize(currWidth, currHeight);
		}

		// Send a point to zoom in on or no point to fit the window
		public function zoom(p:Point = null):void {
			if(!p) {
				isZoomedIn = false;
				resize(currWidth, currHeight);
				return;
			}

			isZoomedIn = true;
			var zoomPos:Point = new Point(p.x, p.y);
			p = visibleArea.globalToLocal(p);
			if(visibleArea.scaleX < maxZoom) {
				visibleArea.scaleX *= 2;
				visibleArea.scaleY *= 2;
			}
			editor.updateZoomReadout();
			p = visibleArea.localToGlobal(p).subtract(zoomPos);

			visibleArea.x = visibleArea.x - p.x;
			visibleArea.y = visibleArea.y - p.y;
			resize(currWidth, currHeight);
		}

		public function getZoomAndScroll():Array { return [visibleArea.scaleX, hScrollbar.scrollValue(), vScrollbar.scrollValue()] }

		public function setZoomAndScroll(zoomAndScroll:Array):void {
			var newZoom:Number = zoomAndScroll[0];
			if (editor is BitmapEdit) newZoom = Math.round(newZoom); // use integer zoom for bitmap editor
			visibleArea.scaleX = visibleArea.scaleY = newZoom;
			isZoomedIn = newZoom > 1;
			editor.updateZoomReadout();

			setHScroll(zoomAndScroll[1]);
			setVScroll(zoomAndScroll[2]);

			resize(currWidth, currHeight);
		}

		// -----------------------------
		// Cursor Tool Support
		//------------------------------

		private const growthFactor:Number = 1.2;

		public function handleTool(tool:String, evt:MouseEvent):void {
			if ('help' == tool) Scratch.app.showTip('paint');
			var bitmapEditor:BitmapEdit = editor as BitmapEdit;
			if (bitmapEditor && (('grow' == tool) || ('shrink' == tool))) {
				if ('grow' == tool) bitmapEditor.scaleAll(growthFactor);
				if ('shrink' == tool) bitmapEditor.scaleAll(1 / growthFactor);
			} else {
				CursorTool.setTool(null);
			}
			evt.stopImmediatePropagation(); // keep current paint tool from responding to this mouse event
		}

	}
}
