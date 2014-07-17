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

/*
John:
  [x] cursors for select and stamp mode
  [x] deactivate when media library showing (so cursor doesn't disappear)
  [ ] snap costume center to grid
  [ ] allow larger pens (make size slider be non-linear)
  [ ] when converting stage from bitmap to vector, trim white area (?)
  [ ] minor: small shift when baking in after moving selection
  [ ] add readout for pen size
  [ ] add readout for zoom
*/

package svgeditor {
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;

	import scratch.ScratchCostume;

	import svgeditor.objs.*;
	import svgeditor.tools.*;

	import svgutils.SVGElement;

	import ui.parts.*;

	import uiwidgets.*;

public class BitmapEdit extends ImageEdit {

	public var stampMode:Boolean;

	public static const bitmapTools:Array = [
		{ name: 'bitmapBrush',		desc: 'Brush' },
		{ name: 'line',				desc: 'Line' },
		{ name: 'rect',				desc: 'Rectangle',	shiftDesc: 'Square' },
		{ name: 'ellipse',			desc: 'Ellipse',	shiftDesc: 'Circle' },
		{ name: 'text',				desc: 'Text' },
		{ name: 'paintbucket',		desc: 'Fill with color' },
		{ name: 'bitmapEraser',		desc: 'Erase' },
		{ name: 'bitmapSelect',		desc: 'Select' },
	];

	private var offscreenBM:BitmapData;
	private var lastToolMode:String;

	public function BitmapEdit(app:Scratch, imagesPart:ImagesPart) {
		super(app, imagesPart);
		addStampTool();
		setToolMode('bitmapBrush');
	}

	public function revertToCreateTool(e:MouseEvent):Boolean {
		// If just finished creating and placing a rect or ellipse, return to that tool.
		if (toolMode == 'bitmapSelect' && ((lastToolMode == 'rect') || (lastToolMode == 'ellipse'))) {
			setToolMode(lastToolMode);
			(currentTool as SVGCreateTool).eventHandler(e);
			return true;
		}
		return false;
	}

	protected override function getToolDefs():Array { return bitmapTools }

	protected override function onColorChange(e:Event):void {
		var pencilTool:BitmapPencilTool = currentTool as BitmapPencilTool;
		if (pencilTool) pencilTool.updateProperties();
		super.onColorChange(e);
	}

	public override function shutdown():void {
		super.shutdown();

		// Bake and save costume
		bakeIntoBitmap();
		saveToCostume();
	}

	// -----------------------------
	// Bitmap selection support
	//------------------------------

	public override function snapToGrid(toolsP:Point):Point {
		var toolsLayer:Sprite = getToolsLayer();
		var contentLayer:Sprite = workArea.getContentLayer();
		var p:Point = contentLayer.globalToLocal(toolsLayer.localToGlobal(toolsP));
		var roundedP:Point = workArea.getScale() == 1 ? new Point(Math.round(p.x), Math.round(p.y)) : new Point(Math.round(p.x * 2) / 2, Math.round(p.y * 2) / 2);
		return toolsLayer.globalToLocal(contentLayer.localToGlobal(roundedP));
	}

	public function getSelection(r:Rectangle):SVGBitmap {
		var bm:BitmapData = workArea.getBitmap().bitmapData;
		r = r.intersection(bm.rect); // constrain selection to bitmap content
		if ((r.width < 1) || (r.height < 1)) return null; // empty rectangle

		var selectionBM:BitmapData = new BitmapData(r.width, r.height, true, 0);
		selectionBM.copyPixels(bm, r, new Point(0, 0));
		if (stampMode) {
			highlightTool('bitmapSelect');
		} else {
			bm.fillRect(r, bgColor()); // cut out the selection
		}

		if (isScene) removeWhiteAroundSelection(selectionBM);

		var el:SVGElement = SVGElement.makeBitmapEl(selectionBM, 0.5);
		var result:SVGBitmap = new SVGBitmap(el, el.bitmap);
		result.redraw();
		result.x = r.x / 2;
		result.y = r.y / 2;
		workArea.getContentLayer().addChild(result);
		return result;
	}

	private function removeWhiteAroundSelection(bm:BitmapData):void {
		// Clear extra white pixels around the actual content when editing on the stage.

		// Find the box around the non-white pixels
		var r:Rectangle = bm.getColorBoundsRect(0xFFFFFFFF, 0xFFFFFFFF, false);
		if ((r.width == 0) || (r.height == 0)) return; // if all white, do nothing

		r.inflate(1, 1);
		const corners:Array = [
			new Point(r.x, r.y),
			new Point(r.right, 0),
			new Point(0, r.bottom),
			new Point(r.right, r.bottom)
		];
		for each (var p:Point in corners) {
			if (bm.getPixel(p.x, p.y) == 0xFFFFFF) bm.floodFill(p.x, p.y, 0);
		}
	}

	protected override function selectHandler(evt:Event = null):void {
		if ((currentTool is ObjectTransformer && !(currentTool as ObjectTransformer).getSelection())) {
			// User clicked away from the object transformer, so bake it in.
			bakeIntoBitmap();
			saveToCostume();
		}
	}

	public function deletingSelection():void {
		if (app.runtime.shiftIsDown) {
			var bm:BitmapData = workArea.getBitmap().bitmapData;
			bm.fillRect(bm.rect, 0);
			app.runtime.shiftIsDown = false;
			bakeIntoBitmap(false);
		}
	}

	// -----------------------------
	// Load and Save Costume
	//------------------------------

	protected override function loadCostume(c:ScratchCostume):void {
		var bm:BitmapData = workArea.getBitmap().bitmapData;
		bm.fillRect(bm.rect, bgColor()); // clear

		var scale:Number = 2 / c.bitmapResolution;
		var costumeBM:BitmapData = c.bitmapForEditor(isScene);
		var destP:Point = isScene ?
			new Point(0, 0) :
			new Point(480 - (scale * c.rotationCenterX), 360 - (scale * c.rotationCenterY));
		bm.copyPixels(costumeBM, costumeBM.rect, destP);
		if (c.undoList.length == 0) {
			recordForUndo(costumeBM, (scale * c.rotationCenterX), (scale * c.rotationCenterY));
		}
	}

	public override function addCostume(c:ScratchCostume, destP:Point):void {
		var el:SVGElement = SVGElement.makeBitmapEl(c.bitmapForEditor(isScene), 0.5);
		var sel:SVGBitmap = new SVGBitmap(el, el.bitmap);
		sel.redraw();
		sel.x = destP.x - c.width() / 2;
		sel.y = destP.y - c.height() / 2;
		workArea.getContentLayer().addChild(sel);

		setToolMode('bitmapSelect');
		(currentTool as ObjectTransformer).select(new Selection([sel]));
	}

	public override function saveContent(evt:Event = null):void {
		// Note: Don't save when there is an active selection or in text entry mode.
		if (currentTool is ObjectTransformer) return;
		if (currentTool is TextTool) return; // should select the text so it can be manipulated
		bakeIntoBitmap();
		saveToCostume();
	}

	private function saveToCostume():void {
		// Note: Although the bitmap is double resolution, the rotation center is not doubled,
		// since it is applied to the costume after the bitmap has been scaled down.
		var c:ScratchCostume = targetCostume;
		var bm:BitmapData = workArea.getBitmap().bitmapData;
		if (isScene) {
			c.setBitmapData(bm.clone(), bm.width / 2, bm.height / 2);
		} else {
			var r:Rectangle = bm.getColorBoundsRect(0xFF000000, 0, false);
			var newBM:BitmapData;
			if (r.width >= 1 && r.height >= 1) {
				newBM = new BitmapData(r.width, r.height, true, 0);
				newBM.copyPixels(bm, r, new Point(0, 0));
				c.setBitmapData(newBM, Math.floor(480 - r.x), Math.floor(360 - r.y));
			} else {
				newBM = new BitmapData(2, 2, true, 0); // empty bitmap
				c.setBitmapData(newBM, 0, 0);
			}
		}
		recordForUndo(c.baseLayerBitmap.clone(), c.rotationCenterX, c.rotationCenterY);
		Scratch.app.setSaveNeeded();
	}

	override public function setToolMode(newMode:String, bForce:Boolean = false):void {
		highlightTool('none');
		if (('bitmapSelect' == newMode) && (('ellipse' == toolMode) || ('rect' == toolMode))) {
			lastToolMode = toolMode;
		} else {
			lastToolMode = '';
		}
		var obj:ISVGEditable = null;
		if (newMode != toolMode && currentTool is SVGEditTool)
			obj = (currentTool as SVGEditTool).getObject();

		var prevToolMode:String = toolMode;
		super.setToolMode(newMode, bForce);
		if (lastToolMode != '') highlightTool(lastToolMode);

		if (obj) {
			if (currentTool is TextTool && prevToolMode == 'bitmapSelect') {
				(currentTool as TextTool).setObject(obj);
			}
			else if (!(currentTool is ObjectTransformer)) {
				// User was editing an object and switched tools, bake the object
				bakeIntoBitmap();
				saveToCostume();
			}
		}
	}

	private function highlightTool(toolName:String):void {
		// Hack! This method forces a given to be highlighted even if that's not the
		// actual mode. Used to force shape buttons to stay highlighted even when moving
		// the shape around with the select tool.
		if (!toolName || (toolName == '')) return;
		for each (var btn:IconButton in toolButtons) btn.turnOff();
		if (toolButtons[toolName]) toolButtons[toolName].turnOn();
	}

	private function createdObjectIsEmpty():Boolean {
		// Return true if the created object is empty (i.e. the user clicked without moving the mouse).
		var content:Sprite = workArea.getContentLayer();
		if (content.numChildren == 1) {
			var svgShape:SVGShape = content.getChildAt(0) as SVGShape;
			if (svgShape) {
				var el:SVGElement = svgShape.getElement();
				var attr:Object = el.attributes;
				if (el.tag == 'ellipse') {
					if (!attr.rx || (attr.rx < 1)) return true;
					if (!attr.ry || (attr.ry < 1)) return true;
				}
				if (el.tag == 'rect') {
					if (!attr.width || (attr.width < 1)) return true;
					if (!attr.height || (attr.height < 1)) return true;
				}
			}
		}
		return false;
	}

	private function bakeIntoBitmap(doClear:Boolean = true):void {
		// Render any content objects (text, circle, rectangle, line) into my bitmap.
		// Note: Must do this at low quality setting to avoid antialiasing.
		var content:Sprite = workArea.getContentLayer();
		if (content.numChildren == 0) return; // nothing to bake in
		var bm:BitmapData = workArea.getBitmap().bitmapData;
		if (bm && (content.numChildren > 0)) {
			var m:Matrix = new Matrix();
			m = content.getChildAt(0).transform.matrix.clone();
			m.scale(2, 2);
			var oldQuality:String = stage.quality;
			if (!Scratch.app.runtime.shiftIsDown) stage.quality = StageQuality.LOW;
			for (var i:int = 0; i < content.numChildren; i++) {
				var el:DisplayObject = content.getChildAt(i) as DisplayObject;
				var textEl:SVGTextField = el as SVGTextField;
				if (textEl && !Scratch.app.runtime.shiftIsDown) {
					// Even in LOW quality mode, text is anti-aliased.
					// This code forces it to have sharp edges for ease of using the paint bucket.
					const threshold:int = 0x60 << 24;
					var c:int = 0xFF000000 | textEl.textColor;
					clearOffscreenBM();
					offscreenBM.draw(el, m, null, null, null, true);
					// force pixels above threshold to be text color, alpha 1.0
					offscreenBM.threshold(
						offscreenBM, offscreenBM.rect, new Point(0, 0),
						'>', threshold, c, 0xFF000000, false);
					// force pixels below threshold to be transparent
					offscreenBM.threshold(
						offscreenBM, offscreenBM.rect, new Point(0, 0),
						'<=', threshold, 0, 0xFF000000, false);
					// copy result into work bitmap
					bm.draw(offscreenBM);
				} else {
					bm.draw(el, m, null, null, null, true);
				}
			}
			stage.quality = oldQuality;
		}
		if (doClear) workArea.clearContent();
		stampMode = false;
	}

	private function clearOffscreenBM():void {
		var bm:BitmapData = workArea.getBitmap().bitmapData;
		if (!offscreenBM ||
			(offscreenBM.width != bm.width) ||
			(offscreenBM.height != bm.height)) {
				offscreenBM = new BitmapData(bm.width, bm.height, true, 0);
				return;
		}
		offscreenBM.fillRect(offscreenBM.rect, 0);
	}

	// -----------------------------
	// Set costume center support
	//------------------------------

	public override function translateContents(x:Number, y:Number):void {
		var bm:BitmapData = workArea.getBitmap().bitmapData;
		var newBM:BitmapData = new BitmapData(bm.width, bm.height, true, 0);
		newBM.copyPixels(bm, bm.rect, new Point(Math.round(2 * x), Math.round(2 * y)));
		workArea.getBitmap().bitmapData = newBM;
	}

	// -----------------------------
	// Stamp and Flips
	//------------------------------

	private function addStampTool():void {
		const buttonSize:Point = new Point(37, 33);
		var lastTool:DisplayObject = toolButtonsLayer.getChildAt(toolButtonsLayer.numChildren - 1);
		var btn:IconButton = new IconButton(
			stampBitmap,
			SoundsPart.makeButtonImg('bitmapStamp', true, buttonSize),
			SoundsPart.makeButtonImg('bitmapStamp', false, buttonSize));
		btn.x = 0;
		btn.y = lastTool.y + lastTool.height + 4;
		SimpleTooltips.add(btn, {text: 'Select and duplicate', direction: 'right'});
		registerToolButton('bitmapStamp', btn);
		toolButtonsLayer.addChild(btn);
	}

	private function stampBitmap(ignore:*):void {
		setToolMode('bitmapBrush');
		setToolMode('bitmapSelect');
		highlightTool('bitmapStamp');
		stampMode = true;
	}

	protected override function flipAll(vertical:Boolean):void {
		var oldBM:BitmapData = workArea.getBitmap().bitmapData;
		var newBM:BitmapData = new BitmapData(oldBM.width, oldBM.height, true, 0);
		var m:Matrix = new Matrix();
		if (vertical) {
			m.scale(1, -1);
			m.translate(0, oldBM.height);
		} else {
			m.scale(-1, 1);
			m.translate(oldBM.width, 0);
		}
		newBM.draw(oldBM, m);
		workArea.getBitmap().bitmapData = newBM;
		saveToCostume();
	}

	private function getBitmapSelection():SVGBitmap {
		var content:Sprite = workArea.getContentLayer();
		for (var i:int = 0; i < content.numChildren; i++) {
			var svgBM:SVGBitmap = content.getChildAt(i) as SVGBitmap;
			if (svgBM) return svgBM;
		}
		return null;
	}

	// -----------------------------
	// Grow/Shrink Tool Support
	//------------------------------

	public function scaleAll(scale:Number):void {
		var bm:BitmapData = workArea.getBitmap().bitmapData;
		var r:Rectangle = isScene ?
			bm.getColorBoundsRect(0xFFFFFFFF, 0xFFFFFFFF, false) :
			bm.getColorBoundsRect(0xFF000000, 0, false);
		var newBM:BitmapData = new BitmapData(Math.max(1, r.width * scale), Math.max(1, r.height * scale), true, bgColor());
		var m:Matrix = new Matrix();
		m.translate(-r.x, -r.y);
		m.scale(scale, scale);
		newBM.draw(bm, m);
		var destP:Point = new Point(r.x - ((r.width * (scale - 1)) / 2), r.y - ((r.height * (scale - 1)) / 2));
		bm.fillRect(bm.rect, bgColor());
		bm.copyPixels(newBM, newBM.rect, destP);
		saveToCostume();
	}

	// -----------------------------
	// Clear/Undo/Redo
	//------------------------------

	public override function canClearCanvas():Boolean {
		// True if canvas has any marks.
		var bm:BitmapData = workArea.getBitmap().bitmapData;
		var r:Rectangle = bm.getColorBoundsRect(0xFFFFFFFF, bgColor(), false);
		return (r.width > 0) && (r.height > 0);
	}

	public override function clearCanvas(ignore:* = null):void {
		setToolMode('bitmapBrush');
		var bm:BitmapData = workArea.getBitmap().bitmapData;
		bm.fillRect(bm.rect, bgColor());
		super.clearCanvas();
	}

	private function bgColor():int { return isScene ? 0xFFFFFFFF : 0 }

	protected override function restoreUndoState(undoRec:Array):void {
		var c:ScratchCostume = targetCostume;
		c.setBitmapData(undoRec[0], undoRec[1], undoRec[2]);
		loadCostume(c);
	}

}}
