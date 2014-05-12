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

package svgeditor.tools {
	import flash.display.*;
	import flash.events.MouseEvent;
	import flash.geom.*;
	import flash.ui.Mouse;
	import svgeditor.*;

public final class BitmapPencilTool extends SVGTool {

	private var eraseMode:Boolean;	// true if this is the eraser tool

	// brush/eraser properties
	private var brushSize:int = 1;
	private var brushColor:int;

	// feedbackObj shows where drawing/erasing will occur
	private var feedbackObj:Bitmap;

	// state used for drawing
	private var canvas:BitmapData;
	private var brush:BitmapData;
	private var eraser:BitmapData;
	private var tempBM:BitmapData;
	private var lastPoint:Point;

	public function BitmapPencilTool(editor:ImageEdit, eraseMode:Boolean = false) {
		super(editor);
		this.eraseMode = eraseMode;
		mouseEnabled = false;
		mouseChildren = false;
	}

	override protected function init():void {
		super.init();
		editor.stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown, false, 0, true);
		editor.stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove, false, 0, true);
		editor.stage.addEventListener(MouseEvent.MOUSE_UP, mouseUp, false, 0, true);
		editor.getToolsLayer().mouseEnabled = false;
		updateProperties();
	}

	override protected function shutdown():void {
		editor.stage.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		editor.stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
		editor.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
		editor.getToolsLayer().mouseEnabled = true;
		removeFeedback();
		super.shutdown();
	}

	public function updateProperties():void {
		updateFeedback();
		moveFeedback();
	}

	private function mouseDown(evt:MouseEvent):void {
		if (!editor) return;
		if (!editor.isActive()) return;
		if (!editor.getWorkArea().clickInBitmap(evt.stageX, evt.stageY)) return; // mouse down not over canvas
		startStroke();
		mouseMove(evt); // draw the first point
	}

	private function startStroke():void {
		// Initialize the canvas, brush and eraser state.
		updateProperties();
		canvas = editor.getWorkArea().getBitmap().bitmapData;
		// when editing a backdrop/scene, erase by drawing with white
		var eraseWithWhite:Boolean = editor.isScene && (eraseMode || (brushColor == 0));
		brush = makeBrush(brushSize, (eraseWithWhite ? 0xFFFFFFFF : brushColor));
		eraser = makeBrush(brushSize, 0, 0xFFFFFFFF);
		tempBM = new BitmapData(brushSize, brushSize, true, 0);
		lastPoint = null;
	}

	private function mouseMove(evt:MouseEvent):void {
		if (!editor.isActive()) return;
		moveFeedback();
		if (brush) { // drawing or erasing
			var p:Point = penPoint();
			if (lastPoint) drawLine(lastPoint.x, lastPoint.y, p.x, p.y);
			else drawAtPoint(p);
			lastPoint = p;
		}
	}

	private function mouseUp(evt:MouseEvent):void {
		if (brush) editor.saveContent();
		brush = eraser = tempBM = null;
	}

	/* Draw/erase feedback */

	private function updateFeedback():void {
		// Create the feedback object, if necessary, and update it with the current pen properties.
		if (!feedbackObj) {
			feedbackObj = new Bitmap();
			feedbackObj.scaleX = feedbackObj.scaleY = 0.5;
			editor.getWorkArea().addBitmapFeedback(feedbackObj);
		}
		getPenProps();
		var outlineOnly:Boolean = eraseMode || (brushColor == 0);
		feedbackObj.bitmapData = makeBrush(brushSize, brushColor, 0, outlineOnly);
	}

	private function getPenProps():void {
		var props:DrawProperties = editor.getShapeProps();
		brushSize = Math.max(1, 2 * Math.round(props.strokeWidth));
		brushColor = (props.alpha > 0) ? (0xFF000000 | props.color) : 0;
	}

	private function moveFeedback():void {
		// Update the position of the brush/eraser feedback object.
		if (!feedbackObj) return;
		var p:Point = penPoint();
		feedbackObj.x = p.x / 2;
		feedbackObj.y = p.y / 2;
		setFeedbackVisibility()
	}

	private function penPoint():Point {
		// Return the position of the top-left corner of the brush relative to the bitmap.
		var p:Point = editor.getWorkArea().bitmapMousePoint();
		var gridX:int = Math.round(p.x - brushSize / 2);
		var gridY:int = Math.round(p.y - brushSize / 2);
		if (gridX & 1) gridX -= 1;
		if (gridY & 1) gridY -= 1;
		return new Point(gridX, gridY);
	}

	private function setFeedbackVisibility():void {
		var r:Rectangle = editor.getWorkArea().getMaskRect(editor);
		var inDrawingArea:Boolean = r.containsPoint(new Point(editor.mouseX, editor.mouseY));
		if (inDrawingArea) {
			Mouse.hide();
			feedbackObj.visible = true;
		} else {
			Mouse.show();
			feedbackObj.visible = false;
		}
	}

	private function removeFeedback():void {
		if (feedbackObj && feedbackObj.parent) feedbackObj.parent.removeChild(feedbackObj);
		feedbackObj = null;
	}

	/* Rendering */

	private function drawLine(x0:int, y0:int, x1:int, y1:int):void {
		// Bresenham line algorithm.
		var dx:int = Math.abs(x1 - x0);
		var dy:int = Math.abs(y1 - y0);
		var sx:int = (x0 < x1) ? 1 : -1;
		var sy:int = (y0 < y1) ? 1 : -1;
		var err:int = dx - dy;

		while (1) {
			drawAtPoint(new Point(x0, y0));
			if ((x0 == x1) && (y0 == y1)) break;
			var e2:int = 2 * err;
			if (e2 > -dy) {
				err = err - dy;
				x0 = x0 + sx;
			}
			if (e2 < dx) {
				err = err + dx;
				y0 = y0 + sy;
			}
		}
	}

	private function drawAtPoint(p:Point):void {
		// Stamp with the brush or erase with the eraser at the given point.
		var isErasing:Boolean = eraseMode || (brushColor == 0);
		if (isErasing && !editor.isScene) {
			var r:Rectangle = new Rectangle(p.x, p.y, brushSize, brushSize);
			tempBM.fillRect(tempBM.rect, 0);
			tempBM.copyPixels(canvas, r, new Point(0, 0), eraser, new Point(0, 0), true);
			canvas.copyPixels(tempBM, tempBM.rect, p);
		} else {
			canvas.copyPixels(brush, brush.rect, p, null, null, true);
		}
	}

	private function makeBrush(diameter:int, c:int, bgColor:int = 0, outlineOnly:Boolean = false):BitmapData {
		// Return a BitmapData object containing a round brush with the given diameter and colors.
		if (outlineOnly) c = 0xFF303030;
		var bm:BitmapData = new BitmapData(diameter, diameter, true, bgColor);
		switch (diameter) {
		case 1:
		case 2:
			bm.fillRect(bm.rect, c);
			break;
		case 3:
			bm.fillRect(bm.rect, c);
			if (outlineOnly) bm.fillRect(new Rectangle(1, 1, 1, 1), bgColor);
			break;
		case 4:
			bm.fillRect(bm.rect, c);
			if (outlineOnly) bm.fillRect(new Rectangle(1, 1, 2, 2), bgColor);
			break;
		case 5:
			bm.fillRect(new Rectangle(0, 1, 5, 3), c);
			bm.fillRect(new Rectangle(1, 0, 3, 5), c);
			if (outlineOnly) bm.fillRect(new Rectangle(1, 1, 3, 3), bgColor);
			break;
		case 6:
			bm.fillRect(new Rectangle(0, 2, 6, 2), c);
			bm.fillRect(new Rectangle(2, 0, 2, 6), c);
			bm.fillRect(new Rectangle(1, 1, 4, 4), c);
			if (outlineOnly) bm.fillRect(new Rectangle(2, 2, 2, 2), bgColor);
			break;
		case 7:
			bm.fillRect(new Rectangle(0, 2, 7, 3), c);
			bm.fillRect(new Rectangle(2, 0, 3, 7), c);
			bm.fillRect(new Rectangle(1, 1, 5, 5), c);
			if (outlineOnly) {
				bm.fillRect(new Rectangle(2, 2, 3, 3), bgColor);
				bm.fillRect(new Rectangle(1, 3, 5, 1), bgColor);
				bm.fillRect(new Rectangle(3, 1, 1, 5), bgColor);
			}
			break;
		default:
			drawCircle(diameter, c, bm, outlineOnly);
		}
		return bm;
	}

	private function drawCircle(diameter:int, c:int, bm:BitmapData, outlineOnly:Boolean):void {
		// Use Bresenham circle algorithm to approximate a circle.
		function fillLine(x1:int, x2:int, y:int):void {
			if (outlineOnly) {
				bm.setPixel32(x1, y, c);
				bm.setPixel32(x2, y, c);
			} else {
				bm.fillRect(new Rectangle(x1, y, x2 - x1 + 1, 1), c);
			}
		}
		var radius:int = diameter / 2;
		var center:int = radius;
		var adjust:int = ((diameter & 1) == 0) ? -1 : 0; // adjust for even diameter
		var x:int = radius, y:int = 0;
		var xChange:int = 1 - (radius << 1);
		var yChange:int = 0;
		var radiusError:int = 0;

		while (x >= y) {
			fillLine(-x + center, x + center + adjust, y + center + adjust);
			fillLine(-y + center, y + center + adjust, x + center + adjust);
			fillLine(-y + center, y + center + adjust, -x + center);
			fillLine(-x + center, x + center + adjust, -y + center);

			y++;
			radiusError += yChange;
			yChange += 2;
			if (((radiusError << 1) + xChange) > 0) {
				x--;
				radiusError += xChange;
				xChange += 2;
			}
		}
	}

}}
