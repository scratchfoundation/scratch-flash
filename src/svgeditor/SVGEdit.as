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

package svgeditor {
	import flash.display.*;
	import flash.events.*;
	import flash.filters.GlowFilter;
	import flash.geom.*;
	import flash.text.*;
	import flash.utils.*;

	import scratch.ScratchCostume;

	import svgeditor.*;
import svgeditor.ColorPicker;
import svgeditor.objs.*;
	import svgeditor.tools.*;

	import svgutils.*;

	import ui.parts.ImagesPart;

	import uiwidgets.*;

	public class SVGEdit extends ImageEdit {
		public static const tools:Array = [
			{ name: 'select',		desc: 'Select' },
			{ name: 'pathedit',		desc: 'Reshape' },
			null, // Space
			{ name: 'path',			desc: 'Pencil' },
			{ name: 'vectorLine',	desc: 'Line' },
			{ name: 'vectorRect',	desc: 'Rectangle',	shiftDesc: 'Square' },
			{ name: 'vectorEllipse',desc: 'Ellipse',	shiftDesc: 'Circle' },
			{ name: 'text',			desc: 'Text' },
			null, // Space
			{ name: 'vpaintbrush',	desc: 'Color a shape' },
			{ name: 'clone',		desc: 'Duplicate',	shiftDesc: 'Multiple' },
			null, // Space
			{ name: 'front',		desc: 'Forward a layer',	shiftDesc: 'Bring to front' },
			{ name: 'back',			desc: 'Back a layer',		shiftDesc: 'Send to back' },
			{ name: 'group',		desc: 'Group' },
			{ name: 'ungroup',		desc: 'Ungroup' },
		];

		private static const immediateTools:Array = ['back', 'front', 'group', 'ungroup', 'noZoom', 'zoomOut'];
		private static const bmptoolist:Array = ['wand' , 'lasso', 'slice'];
		private static const unimplemented:Array = ['wand' , 'lasso', 'slice'];

		public function SVGEdit(app:Scratch, imagesPart:ImagesPart) {
			super(app, imagesPart);

			PathEndPointManager.init(this);
			setToolMode('path');
		}

		override protected function getToolDefs():Array { return tools; }
		override protected function getImmediateToolList():Array { return immediateTools; }

		override protected function selectHandler(event:Event = null):void {
			// Send ShapeProperties to the ShapePropertiesUI
			//if(toolMode != 'select') return;

			// Reset the smoothness ui
			drawPropsUI.showSmoothnessUI(false);

			var objs:Array = [];
			var isGroup:Boolean = false;
			if(currentTool is ObjectTransformer) {
				var s:Selection = (currentTool is ObjectTransformer ? (currentTool as ObjectTransformer).getSelection() : null);
				if(s) {
					objs = s.getObjs();
					isGroup = s.isGroup();
				}
			}
			else if(currentTool is SVGEditTool) {
				var obj:ISVGEditable = (currentTool as SVGEditTool).getObject();
				if(obj) {
					objs.push(obj);
					drawPropsUI.showSmoothnessUI((obj is SVGShape), false);
					if (obj is SVGTextField) {
						drawPropsUI.updateFontUI(obj.getElement().getAttribute('font-family'));
					}
				}
			}

			lastShape = null;
			if(objs.length == 1) {
				updateShapeUI(objs[0]);
			}

			// Toggle the group/ungroup buttons depending on the selection
			(toolButtons['group'] as IconButton).setDisabled(objs.length < 2);
			(toolButtons['ungroup'] as IconButton).setDisabled(!objs.length || !isGroup);
			(toolButtons['front'] as IconButton).setDisabled(!objs.length);
			(toolButtons['back'] as IconButton).setDisabled(!objs.length);
		}

		override public function setWidthHeight(w:int, h:int):void {
			super.setWidthHeight(w, h);
			toolButtonsLayer.x = w - 25; // move my tool buttons to the right side
		}

		private var smoothValue:Number = 20;
		private var lastShape:SVGShape = null;
		public function smoothStroke():void {
			var smoothed:Boolean = false;
			if(currentTool is SVGEditTool) {
				var shape:SVGShape = (currentTool as SVGEditTool).getObject() as SVGShape;
				if(shape) {
					if(shape == lastShape) {
						// Don't go over 40
						smoothValue = Math.min(35, smoothValue + 5);
					}
					else smoothValue = 20;

					shape.smoothPath2(smoothValue);
					saveContent();
					currentTool.refresh();
					lastShape = shape;
					smoothed = true;
				}
			}

			if(!smoothed) lastShape = null;
		}

		private function showPanel(panel:Sprite):void {
			//panel.fixLayout();
			var dx:int = (w - panel.width) / 2;
			var dy:int = (h - panel.height) / 2;
			panel.x = dx;
			panel.y = dy;
			addChild(panel);
		}

		override protected function runImmediateTool(name:String, shiftKey:Boolean, s:Selection):void {
			if(!(currentTool is ObjectTransformer) || !s) return;

			var bSave:Boolean = true;
			switch(name) {
				case 'front':
					s.raise(shiftKey);
					break;
				case 'back':
					s.lower(shiftKey);
					break;
				case 'group':
					// Highlight the grouped elements
					highlightElements(s, false);

					s = s.group();
					(currentTool as ObjectTransformer).select(null);
					(currentTool as ObjectTransformer).select(s);
					break;
				case 'ungroup':
					s = s.ungroup();

					// Highlight the separated elements
					highlightElements(s, true);

					(currentTool as ObjectTransformer).select(null);
					break;
				default:
					bSave = false;
			}

			if(bSave) saveContent();
		}

		override protected function onDrawPropsChange(e:Event):void {
			if(currentTool is SVGEditTool && (toolMode != 'select') && (toolMode != 'text')) {
				var obj:ISVGEditable = (currentTool as SVGEditTool).getObject();
				if(obj) {
					var el:SVGElement = obj.getElement();
					el.setAttribute('stroke-width', drawPropsUI.settings.strokeWidth);
					//el.applyShapeProps(drawPropsUI.settings);
					obj.redraw();
					saveContent();
				}
			}
			else {
				super.onDrawPropsChange(e);
			}
		}


		override protected function stageKeyDownHandler(event:KeyboardEvent):Boolean {
			if(!super.stageKeyDownHandler(event)) {
				// Press 's' to smooth a shape
				if(event.keyCode == 83) {
					smoothStroke();
				}
			}
			return false;
		}

		private function highlightElements(s:Selection, separating:Boolean):void {
			if(!separating) return;

			var t:Timer = new Timer(20, 25);
			var maxStrength:uint = 12;
			t.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void {
				var strength:Number = maxStrength * (1 - t.currentCount / t.repeatCount);
				var dist:Number = 6 + strength * 0.5;
				strength += 2;
				var filters:Array = [new GlowFilter(0xFFFFFF, (1 - t.currentCount / t.repeatCount), dist, dist, strength), new GlowFilter(0x28A5DA)];
				for each(var dObj:DisplayObject in s.getObjs())
					dObj.filters = filters;

				if(t.currentCount == t.repeatCount)
					t.removeEventListener(TimerEvent.TIMER, arguments.callee);

				e.updateAfterEvent();
			});

			t.addEventListener(TimerEvent.TIMER_COMPLETE, function(e:TimerEvent):void {
				t.removeEventListener(TimerEvent.TIMER_COMPLETE, arguments.callee);
				t.stop();
				t = null;
				//s.toggleHighlight(false);

				var filters:Array = [];
				for each(var dObj:DisplayObject in s.getObjs())
					dObj.filters = filters;
			});
			t.start();
		}

		// -----------------------------
		// Flipping
		//------------------------------
		override protected function flipAll(vertical:Boolean):void {
			//var anchorPt:Point = new Point(targetCostume.rotationCenterX, targetCostume.rotationCenterY);

			var cl:Sprite = workArea.getContentLayer();
			if(cl.numChildren == 0) return;

			var objs:Array = new Array(cl.numChildren);
			for(var i:uint=0; i<cl.numChildren; ++i)
				objs[i] = cl.getChildAt(i);

			var s:Selection = new Selection(objs);
			s.flip(vertical);
			s.shutdown();
			saveContent();
		}

		override public function stamp():void {
			setToolMode('clone');
		}

		//---------------------------------
		// Costume edit and save
		//---------------------------------

		override protected function loadCostume(c:ScratchCostume):void {
			workArea.clearContent();

			if (c.isBitmap()) {
				insertBitmap(c.baseLayerBitmap.clone(), c.costumeName, true, targetCostume.rotationCenterX, targetCostume.rotationCenterY);
				insertOldTextLayer();
			} else {
				if (targetCostume.undoList.length == 0) recordForUndo(c.baseLayerData, c.rotationCenterX, c.rotationCenterY);
				installSVGData(c.baseLayerData, c.rotationCenterX, c.rotationCenterY);
			}
			imagesPart.refreshUndoButtons();

			// set the initial tool
			if(toolMode == 'select' || (c.svgRoot && c.svgRoot.subElements.length && (!isScene || c.svgRoot.subElements.length > 1)))
				setToolMode('select', true);
		}

		override public function addCostume(c:ScratchCostume, destP:Point):void {
			var p:Point = new Point(ImageCanvas.canvasWidth / 2, ImageCanvas.canvasHeight / 2);
			p = p.subtract(destP);
			p = p.add(new Point(c.rotationCenterX, c.rotationCenterY));
			if (c.isBitmap()) {
				insertBitmap(c.baseLayerBitmap.clone(), c.costumeName, false, p.x, p.y);
				insertOldTextLayer();
			} else {
				installSVGData(c.baseLayerData, Math.round(p.x), Math.round(p.y), true);
			}
			saveContent();
		}

		private function insertBitmap(bm:BitmapData, name:String, isLoad:Boolean, destX:Number, destY:Number):void {
			// Insert the given bitmap.
			if (!bm.transparent) { // convert to a 32-bit bitmap to support alpha (e.g. eraser tool)
				var newBM:BitmapData = new BitmapData(bm.width, bm.height, true, 0);
				newBM.copyPixels(bm, bm.rect, new Point(0, 0));
				bm = newBM;
			}
			if (isLoad) saveInitialBitmapForUndo(bm, name);
			var imgEl:SVGElement = new SVGElement('image', name);
			imgEl.bitmap = bm;
			imgEl.setAttribute('x', 0);
			imgEl.setAttribute('y', 0);
			imgEl.setAttribute('width', bm.width);
			imgEl.setAttribute('height', bm.height);
			if (!isScene) {
				var xOffset:int = Math.ceil(ImageCanvas.canvasWidth / 2 - destX);
				var yOffset:int = Math.ceil(ImageCanvas.canvasHeight / 2 - destY);
				imgEl.transform = new Matrix();
				imgEl.transform.translate(xOffset, yOffset);
			}
			var bmp:SVGBitmap = new SVGBitmap(imgEl);
			bmp.redraw();
			workArea.getContentLayer().addChild(bmp);
		}

		private function insertOldTextLayer():void {
			if (!targetCostume.text) return; // no text layer

			var textX:int = targetCostume.textRect.x;
			var textY:int = targetCostume.textRect.y;
			if (!isScene) {
				textX += (ImageCanvas.canvasWidth / 2) - targetCostume.rotationCenterX;
				textY += (ImageCanvas.canvasHeight / 2) - targetCostume.rotationCenterY;
			}

			// Approximate adjustment for Squeak text placement differences and
			// the fact that the y-origin for SVG text is the baseline.
			// Not really possible to get this right for all fonts/size.
			// It's fairly close for Helvetica Bold, the default font in Scratch 1.4.
			var tf:TextField = new TextField();
			tf.defaultTextFormat = new TextFormat('Helvetica', targetCostume.fontSize);
			textX += 5;
			textY += Math.round(0.9 * tf.getLineMetrics(0).ascent);

			var textEl:SVGElement = new SVGElement('text');
			textEl.text = targetCostume.text;
			textEl.setAttribute('font-family', 'Helvetica');
			textEl.setAttribute('font-weight', 'bold');
			textEl.setAttribute('font-size', targetCostume.fontSize);
			textEl.setAttribute('stroke', SVGElement.colorToHex(targetCostume.textColor & 0xFFFFFF));
			textEl.setAttribute('text-anchor', 'start');
			textEl.transform = new Matrix(1, 0, 0, 1, textX, textY);

			var svgText:SVGTextField = new SVGTextField(textEl);
			svgText.redraw();
			workArea.getContentLayer().addChild(svgText);

			// Wrap the text
			var maxWidth:Number = 480 - svgText.x;
			var text:String = textEl.text;
			var firstChar:uint = 0;
			svgText.text = '';
			for(var i:uint=0; i<text.length; ++i) {
				svgText.text += text.charAt(i);
				if(svgText.textWidth > maxWidth) {
					for(var j:uint = i; j>firstChar; --j) {
						var c:String = text.charAt(j);
						if(c.match(/\s/) != null) {
							var curText:String = svgText.text;
							svgText.text = curText.substring(0, j) + "\n" + curText.substring(j+1);
							firstChar = j+1;
							break;
						}
					}
				}
			}
			textEl.text = svgText.text;
			svgText.redraw();
		}

		private function installSVGData(data:ByteArray, rotationCenterX:int, rotationCenterY:int, isInsert:Boolean = false):void {
			function imagesLoaded(rootElem:SVGElement):void {
				if(isInsert) {
					var origChildren:Array = [];
					var contentLayer:Sprite = workArea.getContentLayer();
					while(contentLayer.numChildren) origChildren.push(contentLayer.removeChildAt(0));
				}

				Renderer.renderToSprite(workArea.getContentLayer(), rootElem);
				if (!isScene) {
					var xOffset:int = Math.ceil((ImageCanvas.canvasWidth / 2) - rotationCenterX);
					var yOffset:int = Math.ceil((ImageCanvas.canvasHeight / 2) - rotationCenterY);
					translateContents(xOffset, yOffset);
				}

				if(isInsert) {
					while(origChildren.length) contentLayer.addChildAt(origChildren.pop(), 0);
				}
			}

			if(!isInsert) workArea.clearContent();

			var importer:SVGImporter = new SVGImporter(XML(data));
			importer.loadAllImages(imagesLoaded);
		}

		public override function saveContent(E:Event = null, undoable:Boolean=true):void {
			var contentLayer:Sprite = workArea.getContentLayer();
			var svgData:ByteArray;

			if (isScene) {
				// save the contentLayer without shifting
				svgData = convertToSVG(contentLayer);
				targetCostume.setSVGData(svgData, false);
			} else {
				// shift costume contents back to (0, 0) before saving SVG data, then shift back to center
				var r:Rectangle = contentLayer.getBounds(contentLayer);
				var offsetX:int = Math.floor(r.x);
				var offsetY:int = Math.floor(r.y);

				translateContents(-offsetX, -offsetY);
				svgData = convertToSVG(contentLayer);
				targetCostume.setSVGData(svgData, false);
				translateContents(offsetX, offsetY);
				targetCostume.rotationCenterX = ImageCanvas.canvasWidth/2 - offsetX;
				targetCostume.rotationCenterY = ImageCanvas.canvasHeight/2 - offsetY;
				app.viewedObj().updateCostume();
			}
			recordForUndo(svgData, targetCostume.rotationCenterX, targetCostume.rotationCenterY);
			app.setSaveNeeded();
		}

		override public function canClearCanvas():Boolean {
			return workArea.getContentLayer().numChildren > 0;
		}

		override public function clearCanvas(ignore:* = null):void {
			if(isScene) {
				targetCostume.baseLayerData = ScratchCostume.emptyBackdropSVG();
				installSVGData(targetCostume.baseLayerData, targetCostume.rotationCenterX, targetCostume.rotationCenterY);
			}
			else {
				workArea.clearContent();
			}

			super.clearCanvas(ignore);
		}

		override public function translateContents(xOffset:Number, yOffset:Number):void {
			var contentLayer:Sprite = workArea.getContentLayer();
			for (var i:int = 0; i < contentLayer.numChildren; i++) {
				var obj:DisplayObject = contentLayer.getChildAt(i);
				if ('getElement' in obj) {
					var m:Matrix = obj.transform.matrix || new Matrix();
					m.translate(xOffset, yOffset);
					obj.transform.matrix = m;
				}
			}
		}

		private function convertToSVG(contentLayer:Sprite):ByteArray {
			var root:SVGElement = new SVGElement('svg', targetCostume.costumeName);
			for (var i:int = 0; i < contentLayer.numChildren; ++i) {
				var c:* = contentLayer.getChildAt(i);
				if ('getElement' in c) root.subElements.push(c.getElement());
			}
			return new SVGExport(root).svgData();
		}

		private function saveInitialBitmapForUndo(bm:BitmapData, name:String):void {
			var root:SVGElement = new SVGElement('svg', name);

			var imgEl:SVGElement = new SVGElement('image', name);
			imgEl.bitmap = bm;
			imgEl.setAttribute('x', 0);
			imgEl.setAttribute('y', 0);
			imgEl.setAttribute('width', bm.width);
			imgEl.setAttribute('height', bm.height);
			root.subElements.push(imgEl);
			var svgData:ByteArray = new SVGExport(root).svgData();

			recordForUndo(svgData, targetCostume.rotationCenterX, targetCostume.rotationCenterY);
		}

	// -----------------------------
	// Undo/Redo
	//------------------------------

		protected override function restoreUndoState(undoRec:Array):void {
			var id:String = null;
			if(toolMode == 'select')
				setToolMode('select', true);
			else if(currentTool is SVGEditTool && (currentTool as SVGEditTool).getObject()) {
				id = (currentTool as SVGEditTool).getObject().getElement().id;
			}

			installSVGData(undoRec[0], undoRec[1], undoRec[2]);

			// Try to find the element that was being edited.
			if(id) {
				var obj:ISVGEditable = getElementByID(id);
				if(obj) {
					(currentTool as SVGEditTool).setObject(obj);
					currentTool.refresh();
				}
				else
					(currentTool as SVGEditTool).setObject(null);
			}
		}

		private function getElementByID(id:String, layer:Sprite = null):ISVGEditable {
			if(!layer) layer = getContentLayer();
			for (var i:int = 0; i < layer.numChildren; ++i) {
				var c:* = layer.getChildAt(i);
				if(c is SVGGroup) {
					var obj:ISVGEditable = getElementByID(id, c as Sprite);
					if(obj) return obj;
				}
				else if(c is ISVGEditable && (c as ISVGEditable).getElement().id == id) {
					return c as ISVGEditable;
				}
			}
			return null;
		}
	}
}
