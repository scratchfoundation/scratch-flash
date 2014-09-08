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
	import assets.Resources;

	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.text.*;
	import flash.ui.*;
	import flash.utils.ByteArray;

	import scratch.*;

	import svgeditor.*;
	import svgeditor.objs.*;
	import svgeditor.tools.*;

	import svgutils.*;

	import translation.Translator;

	import ui.media.MediaInfo;
	import ui.parts.ImagesPart;

	import uiwidgets.*;

	import util.ProjectIO;

	public class ImageEdit extends Sprite {

		public var app:Scratch;
		public var imagesPart:ImagesPart;
		public var targetCostume:ScratchCostume;
		public var isScene:Boolean;

		protected var toolMode:String;
		protected var currentTool:SVGTool;
		protected var drawPropsUI:DrawPropertyUI;
		protected var toolButtons:Object;
		protected var toolButtonsLayer:Sprite;
		protected var w:int, h:int;
		protected var workArea:ImageCanvas;

		private var uiLayer:Sprite;
		private var toolsLayer:Sprite;
		private var svgEditorMask:Shape;
		private var currentCursor:String;

		public function ImageEdit(app:Scratch, imagesPart:ImagesPart) {
			this.app = app;
			this.imagesPart = imagesPart;

			// Create the layers from back to front
			toolsLayer = new Sprite();
			workArea = new ImageCanvas(100, 100, this);
			addChild(workArea);
			addChild(toolsLayer);
			addChild(uiLayer = new Sprite());

			svgEditorMask = new Shape();
			mask = svgEditorMask;
			addChild(svgEditorMask);

			toolButtons = new Object();
			toolButtonsLayer = new Sprite();
			uiLayer.addChild(toolButtonsLayer);

			app.stage.addEventListener(KeyboardEvent.KEY_DOWN, stageKeyDownHandler, false, 0, true);
			workArea.getContentLayer().addEventListener(MouseEvent.MOUSE_OVER, workAreaMouseHandler);
			workArea.getContentLayer().addEventListener(MouseEvent.MOUSE_OUT, workAreaMouseHandler);

			createTools();
			addDrawPropsUI();

			// Set default shape properties
			var initialColors:DrawProperties = new DrawProperties();
			initialColors.color = 0xFF000000;
			initialColors.strokeWidth = 2;
			initialColors.filledShape = (this is BitmapEdit);
			drawPropsUI.updateUI(initialColors);

			selectHandler();
		}

		public static function strings():Array {
			var result:Array = ['Shift:', 'Select and duplicate'];
			var toolEntries:Array = SVGEdit.tools.concat(BitmapEdit.bitmapTools);
			for each (var entry:Object in toolEntries) {
				if (entry) {
					if (entry.desc) result.push(entry.desc);
					if (entry.shiftDesc) result.push(entry.shiftDesc);
				}
			}
			return result;
		}

		public function editingScene():Boolean { return isScene }
		public function getCanvasLayer():Sprite { return workArea.getInteractionLayer() }
		public function getContentLayer():Sprite { return workArea.getContentLayer() }
		public function getShapeProps():DrawProperties { return drawPropsUI.settings }
		public function setShapeProps(props:DrawProperties):void { drawPropsUI.settings = props }
		public function getStrokeSmoothness():Number { return drawPropsUI.getStrokeSmoothness() }
		public function getToolsLayer():Sprite { return toolsLayer }
		public function getWorkArea():ImageCanvas { return workArea }

		public function handleDrop(obj:*):Boolean {
			function insertCostume(c:ScratchCostume):void { addCostume(c, dropPoint) }
			function insertSprite(spr:ScratchSprite):void { addCostume(spr.currentCostume(), dropPoint) }
			var dropPoint:Point;
			var item:MediaInfo = obj as MediaInfo;
			if (item) {
				dropPoint = workArea.getContentLayer().globalToLocal(new Point(stage.mouseX, stage.mouseY));
				var projIO:ProjectIO = new ProjectIO(app);
				if (item.mycostume) insertCostume(item.mycostume);
				else if (item.mysprite) insertSprite(item.mysprite);
				else if ('image' == item.objType) projIO.fetchImage(item.md5, item.objName, item.objWidth, insertCostume);
				else if ('sprite' == item.objType) projIO.fetchSprite(item.md5, insertSprite);
				return true;
			}
			return false;
		}

		public function refreshCurrentTool():void {
			if(currentTool) currentTool.refresh();
		}

		protected function selectHandler(event:Event = null):void {}

		private function workAreaMouseHandler(event:MouseEvent):void {
			if(event.type == MouseEvent.MOUSE_OVER && currentCursor != null) {
				CursorTool.setCustomCursor(currentCursor);
			} else {
				CursorTool.setCustomCursor(MouseCursor.AUTO);
			}

			// Capture mouse down before anyone else in case there is a global tool running
			if(event.type == MouseEvent.MOUSE_OVER && CursorTool.tool)
				workArea.getContentLayer().addEventListener(MouseEvent.MOUSE_DOWN, workAreaMouseDown, true, 1, true);
			else
				workArea.getContentLayer().removeEventListener(MouseEvent.MOUSE_DOWN, workAreaMouseDown);
		}

		private var globalToolObject:ISVGEditable;
		private function workAreaMouseDown(event:MouseEvent):void {
			if(!CursorTool.tool) {
				globalToolObject = null;
				return;
			}

			// BitmapEdit will have to make sure that you can't use the global tools on the
			// raw bitmap, only on the selected marquee (sub-bitmap?)
			var editable:ISVGEditable = SVGTool.staticGetEditableUnderMouse(this);
			if(editable) {
				var obj:DisplayObject = editable as DisplayObject;
				if(CursorTool.tool == 'grow' || CursorTool.tool == 'shrink') {
					var rect:Rectangle = obj.getBounds(obj);
					var center:Point = obj.parent.globalToLocal(obj.localToGlobal(Point.interpolate(rect.topLeft, rect.bottomRight, 0.5)));

					var m:Matrix = obj.transform.matrix.clone();
					if(CursorTool.tool == 'grow')
						m.scale(1.05, 1.05);
					else
						m.scale(0.95, 0.95);
					obj.transform.matrix = m;

					rect = obj.getBounds(obj);
					var ofs:Point = center.subtract(obj.parent.globalToLocal(obj.localToGlobal(Point.interpolate(rect.topLeft, rect.bottomRight, 0.5))));
					obj.x += ofs.x;
					obj.y += ofs.y;
					(obj as ISVGEditable).getElement();
					event.stopImmediatePropagation();
					workArea.addEventListener(MouseEvent.MOUSE_MOVE, workAreaMouseMove, false, 0, true);
					globalToolObject = editable;
				}
				else if(CursorTool.tool == 'cut') {
					app.clearTool();
					// If we're removing the currently selected object then deselect it before removing it
					if(currentTool is SVGEditTool && (currentTool as SVGEditTool).getObject() == editable)
						setToolMode('select', true);
					obj.parent.removeChild(obj);
				}
				else if(CursorTool.tool == 'copy') {
					app.clearTool();
					setToolMode('clone', true);
					getCanvasLayer().dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN));
				}

				if(currentTool) currentTool.refresh();
				saveContent();
			}
			else {
				globalToolObject = null;
			}
		}

		public function setWidthHeight(w:int, h:int):void {
			// Adjust my size and layout to the given width and height.
			// Note: SVGEdit overrides this method to move the tools on the right side.
			this.w = w;
			this.h = h;

			var g:Graphics = svgEditorMask.graphics;
			g.clear();
			g.beginFill(0xF0F000);
			g.drawRect(0, 0, w, h + 5);
			g.endFill();

			drawPropsUI.setWidthHeight(w, 106);
			drawPropsUI.x = 0;
			drawPropsUI.y = h - drawPropsUI.height;

			var leftMargin:uint = 44;
			var rightMargin:uint = 30;
			workArea.resize(w - leftMargin - rightMargin, h - drawPropsUI.height - 12);
			workArea.x = leftMargin;

			refreshCurrentTool();
		}

		public function enableTools(enabled:Boolean):void {
			uiLayer.mouseChildren = enabled;
			uiLayer.alpha = enabled ? 1.0 : 0.6;
		}

		public function isActive():Boolean {
			// Return true if the editor is currently showing.
			if (!root) return false; // Note: The editor is removed from the display tree when it is inactive.
			if (CursorTool.tool) return false;
			return !app.mediaLibrary;
		}

		protected var clipBoard:*;

		protected function stageKeyDownHandler(event:KeyboardEvent):Boolean {
			if(!isActive()) return true;
			if(stage && (stage.focus is TextField ||
				(stage.focus is SVGTextField && (stage.focus as SVGTextField).type == TextFieldType.INPUT))) return true;

			if(event.keyCode == 27) {
				// Maybe empty the selection when in BitmapEdit
				setToolMode('select');
				return true;
			}
			else if(toolMode != 'select' && currentTool is SVGEditTool && (event.keyCode == Keyboard.DELETE || event.keyCode == Keyboard.BACKSPACE)) {
				// Delete the object being edited
				if (this is BitmapEdit) return true;

				var et:SVGEditTool = currentTool as SVGEditTool;
				var dObj:DisplayObject = et.getObject() as DisplayObject;
				if(dObj) {
					et.setObject(null);
					dObj.parent.removeChild(dObj);
					saveContent();
				}
				return true;
			}
			else if(event.keyCode == 90 && event.ctrlKey) {
				// Undo (ctrl-z) / Redo (ctrl-shift-z)
				if(event.shiftKey) redo();
				else undo();
			}
			else if(event.keyCode == 67 && event.ctrlKey) {
				var s:Selection = null;
				if(currentTool is ObjectTransformer) {
					s = (currentTool as ObjectTransformer).getSelection();
				}
				else if(currentTool is SVGEditTool) {
					var obj:ISVGEditable = (currentTool as SVGEditTool).getObject();
					if(obj)
						s = new Selection([obj]);
				}

				if(s) {
					clipBoard = s.cloneObjs(workArea.getContentLayer());
					return true;
				}
			}
			else if(event.keyCode == 86 && event.ctrlKey && clipBoard is Array) {
				endCurrentTool();
				setToolMode('clone');
				(currentTool as CloneTool).pasteFromClipboard(clipBoard);
			}

			return false;
		}

		public function updateShapeUI(obj:ISVGEditable):void {
			if(obj is SVGShape) {
				var el:SVGElement = obj.getElement();
				var props:DrawProperties = drawPropsUI.settings;

				var stroke:String = el.getAttribute('stroke');
				props.strokeWidth = stroke == 'none' ? 0 : parseFloat(el.getAttribute('stroke-width'));

				// Don't try to update the current selection
				drawPropsUI.updateUI(props);
			}
		}

		// Must be overridden and return an array like this:
		/*[
			{ name: 'select',		desc: 'Select' },
			null, // Space
			{ name: 'path',			desc: 'Pencil' },
		]*/
		protected function getToolDefs():Array { return [] }

		// May be overridden to return an array like this:
		/*['tool1', 'tool3']*/
		protected function getImmediateToolList():Array { return [] }

		private function createTools():void {
			var space:int = (this is BitmapEdit) ? 4 : 2; // normal space between buttons
			var extraSpace:int = (this is BitmapEdit) ? 20 : 8;
			var buttonSize:Point = (this is BitmapEdit) ? new Point(37, 33) : new Point(24, 22);
			var tools:Array = getToolDefs();
			var immediateTools:Array = getImmediateToolList();
			var ib:IconButton;
			var dy:Number = 0;
			var ttDirection:String = (this is SVGEdit ? 'left' : 'right');
			for (var i:int=0; i< tools.length; ++i) {
				if (tools[i] == null) dy += extraSpace;
				else {
					var toolName:String = tools[i].name;
					var isImmediate:Boolean = (immediateTools && immediateTools.indexOf(toolName) > -1);
					var iconName:String = toolName;
					if ('bitmapBrush' == toolName) iconName = 'bitmapBrush';
					if ('bitmapEraser' == toolName) iconName = 'eraser';
					if ('bitmapSelect' == toolName) iconName = 'bitmapSelect';
					if ('ellipse' == toolName) iconName = 'bitmapEllipse';
					if ('paintbucket' == toolName) iconName = 'bitmapPaintbucket';
					if ('rect' == toolName) iconName = 'bitmapRect';
					if ('text' == toolName) iconName = 'bitmapText';

					ib = new IconButton(
						isImmediate ? handleImmediateTool : selectTool,
						makeToolButton(iconName, true, buttonSize),
						makeToolButton(iconName, false, buttonSize),
						!isImmediate);
					registerToolButton(toolName, ib);
					ib.isMomentary = isImmediate;
					toolButtonsLayer.addChild(ib);
					ib.y = dy;

					// Group and ungroup are in the same location
					// Add data to the tools array to indicate this?
					if(toolName != 'group')
						dy += ib.height + space;
				}
			}
			updateTranslation();
		}

		public function updateTranslation():void {
			var direction:String = (this is SVGEdit ? 'left' : 'right');
			for each (var tool:* in getToolDefs()) {
				if (!tool) continue;
				var text:String = Translator.map(tool.desc);
				if (tool.shiftDesc) {
					text += ' (' + Translator.map('Shift:') + ' ' + Translator.map(tool.shiftDesc) + ')';
				}
				SimpleTooltips.add(toolButtons[tool.name], {text: text, direction: direction});
			}
			if (drawPropsUI) drawPropsUI.updateTranslation();
		}

		private function addDrawPropsUI():void {
			drawPropsUI = new DrawPropertyUI(this);
			drawPropsUI.x = 200;
			drawPropsUI.y = h - drawPropsUI.height - 40;
			drawPropsUI.addEventListener(DrawPropertyUI.ONCHANGE, onColorChange);
			drawPropsUI.addEventListener(DrawPropertyUI.ONFONTCHANGE, onFontChange);
			uiLayer.addChild(drawPropsUI);
		}

		public function registerToolButton(toolName:String, ib:IconButton):void {
			ib.name = toolName;
			toolButtons[toolName] = ib;
		}

		public function translateContents(x:Number, y:Number):void {}

		public function handleImmediateTool(btn:IconButton):void {
			if(!btn) return;

			var s:Selection = null;
			if(currentTool) {
				if(toolMode == 'select')
					s = (currentTool as ObjectTransformer).getSelection();
				else if(currentTool is SVGEditTool && (currentTool as SVGEditTool).getObject())
					s = new Selection([(currentTool as SVGEditTool).getObject()]);
			}

			var shiftKey:Boolean = (btn.lastEvent && btn.lastEvent.shiftKey);
			var p:Point = null;
			switch(btn.name) {
				case 'zoomIn':
					var r:Rectangle = workArea.getVisibleLayer().getRect(stage);
					workArea.zoom(new Point(Math.round((r.right+r.left)/2), Math.round((r.bottom+r.top)/2)));

					// Center around the selection if we have one
					if(s) {
						r = s.getBounds(stage);
						workArea.centerAround(new Point(Math.round((r.right+r.left)/2), Math.round((r.bottom+r.top)/2)));
					}

					currentTool.refresh();
					if(toolButtons[toolMode]) toolButtons[toolMode].turnOn();
					break;
				case 'zoomOut':
					workArea.zoomOut();
					currentTool.refresh();
					if(toolButtons[toolMode]) toolButtons[toolMode].turnOn();
					break;
				case 'noZoom':
					workArea.zoom();
					currentTool.refresh();
					if(toolButtons[toolMode]) toolButtons[toolMode].turnOn();
					break;
				default:
					runImmediateTool(btn.name, shiftKey, s);
			}

			// Shutdown temporary selection
			if(toolMode != 'select' && s) {
				s.shutdown();
			}

			btn.turnOff();
			if(btn.lastEvent) {
				btn.lastEvent.stopPropagation();
			}
		}

		protected function runImmediateTool(name:String, shiftKey:Boolean, s:Selection):void {}

		// Override in SVGEdit to add more logic
		protected function onColorChange(e:Event):void {
			var sel:Selection;
			if (toolMode == 'select') {
				sel = (currentTool as ObjectTransformer).getSelection();
				if (sel) {
					sel.setShapeProperties(drawPropsUI.settings);
					currentTool.refresh();
					saveContent();
				}
				return;
			}
			if (toolMode == 'eraser' && (currentTool is EraserTool)) {
				(currentTool as EraserTool).updateIcon();
			}
			if (currentTool is ObjectTransformer) {
				sel = (currentTool as ObjectTransformer).getSelection();
				if (sel) sel.setShapeProperties(drawPropsUI.settings);
			}
			if (currentTool is TextTool) {
				var obj:ISVGEditable = (currentTool as TextTool).getObject();
				if (obj) {
					obj.getElement().applyShapeProps(drawPropsUI.settings);
					obj.redraw();
				}
			}
		}

		private function onFontChange(e:Event):void {
			var sel:Selection;
			var obj:ISVGEditable;
			var fontName:String = drawPropsUI.settings.fontName;
			if (toolMode == 'select') {
				sel = (currentTool as ObjectTransformer).getSelection();
				if (sel) {
					for each (obj in sel.getObjs()) {
						if (obj is SVGTextField) obj.getElement().setFont(fontName);
						obj.redraw();
					}
				}
			} else if (currentTool is TextTool) {
				obj = (currentTool as TextTool).getObject();
				if (obj) {
					obj.getElement().setFont(fontName);
					obj.redraw();
				}
			}
			currentTool.refresh();
			saveContent();
		}

		protected function fromHex(s:String):uint {
			if(!s) return 0;
			else return uint('0x' + s.substr(1));
		}

		static public function makeToolButton(str:String, b:Boolean, buttonSize:Point = null):Sprite {
			var bmp:Bitmap = (b ? Resources.createBmp(str +'On') : Resources.createBmp(str +'Off'));
			return buttonFrame(bmp, b, buttonSize);
		}

		static public function buttonFrame(bmp:DisplayObject, b:Boolean, buttonSize:Point = null):Sprite {
			var frameW:int = buttonSize ? buttonSize.x : bmp.width;
			var frameH:int = buttonSize ? buttonSize.y : bmp.height;

			var result:Sprite = new Sprite();
			var g:Graphics = result.graphics;
			g.clear();
			g.lineStyle(0.5, CSS.borderColor, 1, true);
			if (b) {
				g.beginFill(CSS.overColor, 0.7);
				bmp.alpha = 0.9;
			} else {
				var matr:Matrix = new Matrix();
				matr.createGradientBox(frameW, frameH, Math.PI / 2, 0, 0);
				g.beginGradientFill(GradientType.LINEAR, CSS.titleBarColors, [100, 100], [0x00, 0xFF], matr);
			}
			g.drawRoundRect(0, 0, frameW, frameH, 8);
			g.endFill();

			bmp.x = (frameW - bmp.width) / 2;
			bmp.y = (frameH - bmp.height) / 2;

			result.addChild(bmp);
			return result;
		}

		private function selectTool(btn:IconButton):void {
			var newMode:String = (btn ? btn.name : 'select');
			setToolMode(newMode);

			if(btn && btn.lastEvent) {
				btn.lastEvent.stopPropagation();
			}
		}

		public function setToolMode(newMode:String, bForce:Boolean = false):void {
			if(newMode == toolMode && !bForce) return;

			var toolChanged:Boolean = true;//!currentTool || (immediateTools.indexOf(newMode) == -1);
			var s:Selection = null;
			if(currentTool) {
				if(toolMode == 'select' && newMode != 'select')
					s = (currentTool as ObjectTransformer).getSelection();

				// If the next mode is not immediate, shut down the current tool
				if(toolChanged) {
					if(currentTool.parent)
						toolsLayer.removeChild(currentTool);

					if(currentTool is SVGEditTool)
						currentTool.removeEventListener('select', selectHandler);

					currentTool.removeEventListener(Event.CHANGE, saveContent);
					currentTool = null;
					var btn:IconButton = toolButtons[toolMode];
					if(btn) btn.turnOff();
					toolChanged = true;
				}
			}

			switch(newMode) {
				case 'select': currentTool = new ObjectTransformer(this); break;
				case 'pathedit': currentTool = new PathEditTool(this); break;
				case 'path': currentTool = new PathTool(this); break;
				case 'vectorLine':
				case 'line': currentTool = new PathTool(this, true); break;
				case 'vectorEllipse':
				case 'ellipse': currentTool = new EllipseTool(this); break;
				case 'vectorRect':
				case 'rect': currentTool = new RectangleTool(this); break;
				case 'text': currentTool = new TextTool(this); break;
				case 'eraser': currentTool = new EraserTool(this); break;
				case 'clone': currentTool = new CloneTool(this); break;
				case 'eyedropper': currentTool = new EyeDropperTool(this); break;
				case 'vpaintbrush':	currentTool = new PaintBrushTool(this); break;
				case 'setCenter': currentTool = new SetCenterTool(this); break;
				// Add bitmap tools here....
				case 'bitmapBrush': currentTool = new BitmapPencilTool(this, false); break;
				case 'bitmapEraser': currentTool = new BitmapPencilTool(this, true); break;
				case 'bitmapSelect': currentTool = new ObjectTransformer(this); break;
				case 'paintbucket': currentTool = new PaintBucketTool(this); break;
			}

			if(currentTool is SVGEditTool) {
				currentTool.addEventListener('select', selectHandler, false, 0, true);
				if(currentTool is ObjectTransformer && s) (currentTool as ObjectTransformer).select(s);
			}

			// Setup the drawing properties for the next tool
			updateDrawPropsForTool(newMode);

			if(toolChanged) {
				if(currentTool) {
					toolsLayer.addChild(currentTool);
					btn = toolButtons[newMode];
					if(btn) btn.turnOn();
				}

				workArea.toggleContentInteraction(currentTool.interactsWithContent());
				toolMode = newMode;

				// Pass the selected path to the path edit tool OR
				// Pass the selected text element to the text tool
				if(currentTool is PathEditTool || currentTool is TextTool) {
					(currentTool as SVGEditTool).editSelection(s);
				}

				// Listen for any changes to the content
				currentTool.addEventListener(Event.CHANGE, saveContent, false, 0, true);
			}

			// Make sure the tool selected is visible!
			if(toolButtons.hasOwnProperty(newMode) && currentTool)
				(toolButtons[newMode] as IconButton).setDisabled(false);
		}

		protected function updateDrawPropsForTool(newMode:String):void {
			if(newMode == 'rect' || newMode == 'vectorRect' || newMode == 'ellipse' || newMode == 'vectorEllipse')
				drawPropsUI.toggleShapeUI(true, newMode == 'ellipse' || newMode == 'vectorEllipse');
			else
				drawPropsUI.toggleShapeUI(false);

			drawPropsUI.toggleFillUI(newMode == 'vpaintbrush' || newMode == 'paintbucket');
			drawPropsUI.showSmoothnessUI(newMode == 'path');
			if(newMode == 'path') {
				var strokeWidth:Number = drawPropsUI.settings.strokeWidth;
				if(isNaN(strokeWidth) || strokeWidth < 0.25) {
					var props:DrawProperties = drawPropsUI.settings;
					props.strokeWidth = 2;
					drawPropsUI.settings = props;
				}
			}

			drawPropsUI.showFontUI('text' == newMode);

			var strokeModes:Array = [
				'bitmapBrush', 'line', 'rect', 'ellipse',
				'select', 'pathedit', 'path', 'vectorLine', 'vectorRect', 'vectorEllipse'];
			var eraserModes:Array = ['bitmapEraser', 'eraser'];
			drawPropsUI.showStrokeUI(
				strokeModes.indexOf(newMode) > -1,
				eraserModes.indexOf(newMode) > -1
			);
		}

		public function setCurrentColor(col:uint, alpha:Number):void {
			drawPropsUI.setCurrentColor(col, alpha);
		}

		public function endCurrentTool(nextObject:* = null):void {
			setToolMode((this is SVGEdit) ? 'select' : 'bitmapSelect');

			// If the tool wasn't canceled and an object was created then select it
			if (nextObject && (nextObject is Selection || nextObject.parent)) {
				var s:Selection = (nextObject is Selection ? nextObject: new Selection([nextObject]));
				(currentTool as ObjectTransformer).select(s);
			}
			saveContent();
		}

	//---------------------------------
	// Costume edit and save
	//---------------------------------

		public function editCostume(c:ScratchCostume, forStage:Boolean, force:Boolean = false):void {
			// Edit the given ScratchCostume
			if ((targetCostume == c) && !force) return; // already editing

			targetCostume = c;
			isScene = forStage;
			if (toolButtons['setCenter']) (toolButtons['setCenter'] as IconButton).setDisabled(isScene);
			loadCostume(targetCostume);
			if (imagesPart) imagesPart.refreshUndoButtons();

			if(currentTool is SVGEditTool)
				(currentTool as SVGEditTool).setObject(null);
			else
				currentTool.refresh();

			workArea.zoom();
			if(!isScene) {
				var r:Rectangle = workArea.getVisibleLayer().getRect(stage);
				workArea.zoom(new Point(Math.round((r.right+r.left)/2), Math.round((r.bottom+r.top)/2)));
			}
		}

		protected function loadCostume(c:ScratchCostume):void {} // replace contents with the given costume
		public function addCostume(c:ScratchCostume, where:Point):void {} // add costume to existing contents

		// MUST call app.setSaveNeeded();
		public function saveContent(E:Event = null):void {}

		public function shutdown():void {
			// Called before switching costumes. Should commit any operations that were in
			// progress (e.g. entering text). Forcing a re-select of the current tool should work.
			setToolMode(toolMode, true);
		}

	//---------------------------------
	// Zooming
	//---------------------------------

		public function getZoomAndScroll():Array { return workArea.getZoomAndScroll() }
		public function setZoomAndScroll(zoomAndScroll:Array):void { return workArea.setZoomAndScroll(zoomAndScroll) }
		public function updateZoomReadout():void { if (drawPropsUI) drawPropsUI.updateZoomReadout() }

	// -----------------------------
	// Stamp and Flip Buttons
	//------------------------------

		public function stamp():void {}

		public function flipContent(vertical:Boolean):void {
			var sel:Selection;
			if (currentTool is ObjectTransformer) {
				sel = (currentTool as ObjectTransformer).getSelection();
			}
			if (sel) {
				sel.flip(vertical);
				currentTool.refresh();
				currentTool.dispatchEvent(new Event(Event.CHANGE));
			} else flipAll(vertical);
		}

		protected function flipAll(vertical:Boolean):void {}

	// -----------------------------
	// Clearing
	//------------------------------

		public function canClearCanvas():Boolean { return false }

		// MUST call super
		public function clearCanvas(ignore:* = null):void {
			if(currentTool is SVGEditTool)
				(currentTool as SVGEditTool).setObject(null);
			else
				currentTool.refresh();

			saveContent();
		}

	// -----------------------------
	// Undo/Redo
	//------------------------------

		public function canUndo():Boolean {
			return targetCostume &&
					(targetCostume.undoList.length > 0) &&
					(targetCostume.undoListIndex > 0);
		}

		public function canRedo():Boolean {
			return targetCostume &&
					(targetCostume.undoList.length > 0) &&
					(targetCostume.undoListIndex < (targetCostume.undoList.length - 1));
		}

		public function undo(ignore:* = null):void {
			clearSelection();
			if (canUndo()) {
				var undoRec:Array = targetCostume.undoList[--targetCostume.undoListIndex];
				installUndoRecord(undoRec);
			}
		}

		public function redo(ignore:* = null):void {
			clearSelection();
			if (canRedo()) {
				var undoRec:Array = targetCostume.undoList[++targetCostume.undoListIndex];
				installUndoRecord(undoRec);
			}
		}

		private function clearSelection():void {
			if (this is BitmapEdit) {
				var ot:Boolean = currentTool as ObjectTransformer;
				var tt:Boolean = currentTool is TextTool;
				if (ot || tt) {
					shutdown();
					if (ot) {
						targetCostume.undoList.pop(); // remove last entry (added by shutdown)
						targetCostume.undoListIndex--;
					}
				}
			}
		}

		protected final function recordForUndo(imgData:*, rotationCenterX:int, rotationCenterY:int):void {
			if (!targetCostume) return;
			if (targetCostume.undoListIndex < targetCostume.undoList.length) {
				targetCostume.undoList = targetCostume.undoList.slice(0, targetCostume.undoListIndex + 1);
			}
			targetCostume.undoListIndex = targetCostume.undoList.length;
			targetCostume.undoList.push([imgData, rotationCenterX, rotationCenterY]);
			imagesPart.refreshUndoButtons();
		}

		private function installUndoRecord(undoRec:Array):void {
			// Load image editor from the given undo state array.

			var data:* = undoRec[0];
			imagesPart.useBitmapEditor(data is BitmapData);
			if (imagesPart.editor != this) { // switched editors
				imagesPart.editor.targetCostume = targetCostume;
				imagesPart.editor.isScene = isScene;
			}
			targetCostume.rotationCenterX = undoRec[1];
			targetCostume.rotationCenterY = undoRec[2];
			if (data is ByteArray) targetCostume.setSVGData(data, false);
			if (data is BitmapData) targetCostume.setBitmapData(data, undoRec[1], undoRec[2]);

			imagesPart.editor.restoreUndoState(undoRec);
			imagesPart.refreshUndoButtons();
		}

		protected function restoreUndoState(undoRec:Array):void { }

		// -----------------------------
		// Cursor Tool Support
		//------------------------------

		private function workAreaMouseMove(event:MouseEvent):void {
			if(CursorTool.tool) {
				var editable:ISVGEditable = SVGTool.staticGetEditableUnderMouse(this);
				if(editable && editable == globalToolObject) {
					return;
				}
			}
			globalToolObject = null;
			workArea.removeEventListener(MouseEvent.MOUSE_MOVE, workAreaMouseMove);
			app.clearTool();
		}

		public function setCurrentCursor(name:String, bmp:* = null, hotSpot:Point = null, reuse:Boolean = true):void {
			//trace('setting cursor to '+name);
			if (name == null || [MouseCursor.HAND, MouseCursor.BUTTON].indexOf(name) > -1) {
				currentCursor = (name == null ? MouseCursor.AUTO : name);
				CursorTool.setCustomCursor(currentCursor);
			} else {
				if (bmp is String) bmp = Resources.createBmp(name).bitmapData;
				CursorTool.setCustomCursor(name, bmp, hotSpot, reuse);
				currentCursor = name;
			}

			// When needed for display, pass the alias to the existing cursor property
			if (stage && workArea.getInteractionLayer().hitTestPoint(stage.mouseX, stage.mouseY, true) &&
				!uiLayer.hitTestPoint(stage.mouseX, stage.mouseY, true)) {
				CursorTool.setCustomCursor(currentCursor);
			} else {
				CursorTool.setCustomCursor(MouseCursor.AUTO);
			}
		}

		public function snapToGrid(toolsP:Point):Point {
			// Overridden by BitmapEdit to snap to the nearest pixel.
			return toolsP;
		}

	}
}
