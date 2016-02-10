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

package svgeditor.tools  {
	import flash.display.*;
	import flash.events.*;
	import flash.filters.GlowFilter;
	import flash.geom.*;
	import flash.text.*;
	import flash.ui.*;
	import flash.utils.*;

	import svgeditor.*;
	import svgeditor.objs.*;

	public class ObjectTransformer extends SVGEditTool {
		private var toolsLayer:Sprite;
		private var contentLayer:Sprite;
		private var selectionContext:DisplayObject;
		private var targetObj:Selection;

		// Visual properties
		private static const dashLength:uint	= 3;
		private static const dashColor:uint		= 0xCCCCCC;
		private static const grpDashLength:uint	= 3;
		private static const grpDashColor:uint	= 0xfb9b00;
		private static const bmDashLength:uint	= 4;
		private static const bmDashColor:uint	= 0x0000FF;
		private static const resizeColor:uint	= 0x000000;
		private static const rotateColor:uint	= 0x666666;
		private static const moveColor:uint		= 0x00CC00;

		// Pseudo enum for handle types
		private static const HT_RESIZER:uint	= 0;
		private static const HT_ROTATOR:uint	= 1;
		private static const HT_MOVER:uint		= 2;

		// References to the manipulation handles
		private var topLeftHandle:Sprite;
		private var topHandle:Sprite;
		private var topRightHandle:Sprite;
		private var rightHandle:Sprite;
		private var bottomRightHandle:Sprite;
		private var bottomHandle:Sprite;
		private var bottomLeftHandle:Sprite;
		private var leftHandle:Sprite;
		private var rotateHandle:Sprite;
		private var moveHandle:Sprite;
		private var activeHandle:Sprite;
		private var scaleHandleDict:Dictionary;

		// State variables
		private var initialMatrix:Matrix;
		private var initialRotation:Number;
		private var initialRotation2:Number;
		private var moveOffset:Point;
		private var selectionRect:Rectangle;
		private var centerMoved:Boolean;
		private var copiedObjects:Array;
		private var dblClickTimer:Timer;
		private var preEditTF:TextField;
		private var isRefreshing:Boolean;
		private var isTransforming:Boolean;
		private var handleMoveCursor:Function;
		private var _isChanged:Boolean = false;

		public function get isChanged():Boolean{
			return _isChanged;
		}

		public function ObjectTransformer(ed:ImageEdit) {
			super(ed);
			activeHandle = null;
			toolsLayer = editor.getToolsLayer();
			contentLayer = editor.getContentLayer();
			selectionContext = contentLayer;

			scaleHandleDict = new Dictionary();
			topLeftHandle = makeHandle();
			scaleHandleDict[topLeftHandle] = 'topLeft';
			topHandle = makeHandle();
			scaleHandleDict[topHandle] = 'top';
			topRightHandle = makeHandle();
			scaleHandleDict[topRightHandle] = 'topRight';
			rightHandle = makeHandle();
			scaleHandleDict[rightHandle] = 'right';
			bottomRightHandle = makeHandle();
			scaleHandleDict[bottomRightHandle] = 'bottomRight';
			bottomHandle = makeHandle();
			scaleHandleDict[bottomHandle] = 'bottom';
			bottomLeftHandle = makeHandle();
			scaleHandleDict[bottomLeftHandle] = 'bottomLeft';
			leftHandle = makeHandle();
			scaleHandleDict[leftHandle] = 'left';
			rotateHandle = makeHandle(HT_ROTATOR);
			moveHandle = makeHandle(HT_MOVER);
			centerMoved = false;
			isTransforming = false;
			isRefreshing = false;
			handleMoveCursor = function(e:MouseEvent):void {
				toolCursorHandler(e, HT_MOVER);
			};

			// This rectangle is just test data
			selectionRect = new Rectangle(-5,-5,5,5);
		}

		override protected function init():void {
			if ((editor is BitmapEdit) && !targetObj) {
				cursorBMName = 'crosshairCursor';
				cursorHotSpot = new Point(8, 8);
			} else {
				cursorBMName = null;
			}
			super.init();
			function wasChanged():void{
				_isChanged = true;
			}
			addEventListener(Event.CHANGE, wasChanged, false, 0, true);
			editor.getWorkArea().addEventListener(MouseEvent.MOUSE_DOWN, selectionBoxHandler, false, 0, true);
			toggleHandles(false);
			alpha = 0.65;
		}

		public function reset():void{
			_isChanged=false;
		}

		override protected function shutdown():void {
			var stageObject:Stage = STAGE;

			// Remove event handlers
			removeSelectionEventHandlers();
			editor.getWorkArea().removeEventListener(MouseEvent.MOUSE_DOWN, selectionBoxHandler);
			stageObject.removeEventListener(MouseEvent.MOUSE_MOVE, selectionBoxHandler);
			stageObject.removeEventListener(MouseEvent.MOUSE_UP, selectionBoxHandler);

			select(null);
			setActive(false);
			super.shutdown();
		}

		override protected function edit(obj:ISVGEditable, event:MouseEvent):void {
			if(targetObj && targetObj.contains(obj as DisplayObject)) {
				if(event && (event.shiftKey || event.ctrlKey)) {
					targetObj.getObjs().splice(targetObj.getObjs().indexOf(obj), 1);
					if(targetObj.getObjs().length)
						select(targetObj);
					else
						select(null);
				}
				else {
					moveHandler(new MouseEvent(MouseEvent.MOUSE_DOWN));
				}
			}
			else {
				if (editor.revertToCreateTool(event)) return;
				if(targetObj && event && (event.shiftKey || event.ctrlKey)) {
					targetObj.getObjs().push(obj);
					select(targetObj);
				}
				else if(obj) {
					select(new Selection([obj]), true);
				}
				else {
					select(null);
				}

				dispatchEvent(new Event('select'));
			}
		}

		private function startDblClickTimer():void {
//trace('startDblClickTimer() - ' + (new Date()).getTime());
			clearPreEditTF();
			if(targetObj && targetObj.isTextField()) {
				dblClickTimer = new Timer(250);
				dblClickTimer.start();
				dblClickTimer.addEventListener(TimerEvent.TIMER, dblClickTimeout, false, 0, true);

//trace('Starting double click timer.');
				preEditTF = targetObj.getObjs()[0] as TextField;
				preEditTF.type = TextFieldType.INPUT;
				preEditTF.addEventListener(FocusEvent.FOCUS_IN, handleTextFocus, false, 0, true);
				STAGE.focus = null;
			}
		}

		private function handleTextFocus(e:FocusEvent):void {
//trace('got focus, changing to text mode. - ' + (new Date()).getTime());
			clearDblClickTimeout();
			clearPreEditTF(true);
			editor.setToolMode('text');
		}

		private function clearPreEditTF(edit:Boolean = false):void {
			if(preEditTF) {
				//trace('Clearing text field!');
				if(!edit) preEditTF.type = TextFieldType.DYNAMIC;

				preEditTF.removeEventListener(FocusEvent.FOCUS_IN, handleTextFocus);
				preEditTF = null;
			}
		}

		private function dblClickTimeout(event:TimerEvent = null):void {
//trace('dblClickTimeout() - ' + (new Date()).getTime());
			clearPreEditTF();
			clearDblClickTimeout();
		}

		private function clearDblClickTimeout():void {
//trace('clearDblClickTimeout() - ' + (new Date()).getTime());
			if(!dblClickTimer) return;

			dblClickTimer.removeEventListener(TimerEvent.TIMER, dblClickTimeout);
			dblClickTimer.stop();
			dblClickTimer = null;
		}

		private function getChildOfSelectionContext(obj:DisplayObject):DisplayObject {
			while(obj && obj.parent != contentLayer && obj.parent != selectionContext) obj = obj.parent;
			return obj;
		}

		public function select(obj:Selection, enableDrag:Boolean = false):void {
			if(targetObj == obj && obj) {
				if(enableDrag) {
					moveHandler(new MouseEvent(MouseEvent.MOUSE_DOWN));
				}

				selectionRect = targetObj.getBounds(this);
				centerMoved = false;
				showUI();

				return;
			}

			if(targetObj) {
				targetObj.toggleHighlight(false);
				targetObj.removeEventListener(MouseEvent.MOUSE_DOWN, moveHandler);
				// Remove the move cursor
//trace('removing events');
				targetObj.removeEventListener(MouseEvent.ROLL_OVER, handleMoveCursor);
				targetObj.removeEventListener(MouseEvent.ROLL_OUT, handleMoveCursor);
				targetObj.shutdown();
			}

			targetObj = obj;

			var e:Event = new Event('select');
			graphics.clear();
			toggleHandles(!!targetObj);
			if(targetObj) {
				targetObj.toggleHighlight(true);
				// Add to the display list of the object's parent
				targetObj.addEventListener(MouseEvent.MOUSE_DOWN, moveHandler, false, 0, true);
				// Add the move cursor
//trace('adding events');
				targetObj.addEventListener(MouseEvent.ROLL_OVER, handleMoveCursor, false, 0, true);
				targetObj.addEventListener(MouseEvent.ROLL_OUT, handleMoveCursor, false, 0, true);

				transform.matrix = new Matrix();
				rotation = targetObj.getRotation(contentLayer);
				selectionRect = targetObj.getBounds(this);
				centerMoved = false;
				showUI();

				if(enableDrag) {
					handleMoveCursor(new MouseEvent(MouseEvent.ROLL_OVER))
					moveHandler(new MouseEvent(MouseEvent.MOUSE_DOWN), true);
				}

				STAGE.addEventListener(KeyboardEvent.KEY_DOWN, keyPressed, false, 0, true);
			} else {
				STAGE.removeEventListener(KeyboardEvent.KEY_DOWN, keyPressed);
				transform.matrix = new Matrix();
			}

			if(targetObj && targetObj.getObjs().length == 1)
				object = targetObj.getObjs()[0];
			else
				object = null;

			// Dispatch the 'select' event if we aren't refreshing
			if(!isRefreshing && !isShuttingDown) dispatchEvent(e);

			if(!isShuttingDown && !targetObj && currentEvent is MouseEvent && currentEvent.type == MouseEvent.MOUSE_DOWN) {
				selectionBoxHandler(currentEvent);
			}
		}

		override public function setObject(obj:ISVGEditable):void {
			select(null);
			if(obj) {
				select(new Selection([obj]));
			}
		}

		override public function getObject():ISVGEditable {
			if(targetObj && targetObj.getObjs().length == 1)
				return targetObj.getObjs()[0];

			return null;
		}

		override public function refresh():void {
			if(!targetObj) return;

			var obj:Selection = new Selection(targetObj.getObjs());
			isRefreshing = true;
			select(null);
			select(obj);
			isRefreshing = false;
		}

		public function getSelection():Selection {
			return targetObj;
		}

		public function getSelectedElement():ISVGEditable {
			return (targetObj as ISVGEditable);
		}

		public function deleteSelection():void {
			if (editor is BitmapEdit) (editor as BitmapEdit).deletingSelection();

			if(targetObj) targetObj.remove();

			// Remove event handlers
			removeSelectionEventHandlers();

			select(null);
		}

		private function removeSelectionEventHandlers():void {
			var stageObject:Stage = STAGE;
			if (stageObject) {
				stageObject.removeEventListener(MouseEvent.MOUSE_UP, moveHandler);
				stageObject.removeEventListener(MouseEvent.MOUSE_UP, resizeHandler);
				stageObject.removeEventListener(MouseEvent.MOUSE_UP, rotateHandler);
				stageObject.removeEventListener(MouseEvent.MOUSE_MOVE, rotateHandler);
			}

			if (editor) {
				editor.removeEventListener(MouseEvent.MOUSE_MOVE, moveHandler);
				editor.removeEventListener(MouseEvent.MOUSE_MOVE, resizeHandler);
			}
		}

		private function keyPressed(e:KeyboardEvent):void {
			if(isShuttingDown || !editor.isActive()) return;
			if((STAGE.focus is TextField ||
				(STAGE.focus is SVGTextField && (STAGE.focus as SVGTextField).type == TextFieldType.INPUT))) return;

			var changed:Boolean = true;
			switch(e.keyCode) {
				case Keyboard.DELETE:
				case Keyboard.BACKSPACE:
					deleteSelection();
					break;
				case Keyboard.UP:
					--y;
					updateTarget();
					break;
				case Keyboard.DOWN:
					++y;
					updateTarget();
					break;
				case Keyboard.LEFT:
					--x;
					updateTarget();
					break;
				case Keyboard.RIGHT:
					++x;
					updateTarget();
					break;
				case 99:
					changed = false;
					if(e.ctrlKey) {
						// Copy
						//editor.setToolMode('clone');
					}
					break;
				/* TODO: Move to clone tool
				case 118:
					if(e.ctrlKey) {
						// Paste
						if(!copiedObjects || !copiedObjects.length) return;

						for(var i:uint=0; i<copiedObjects.length; ++i) {
							contentLayer.addChild(copiedObjects[i] as DisplayObject);
						}

						select(new Selection(copiedObjects));

						// Get another copy
						getCopyOfSelection();
					} else {
						changed = false;
					}
					break;
				*/
				case 103:
					// Group / Ungroup!
					var s:Selection = getSelection();
					if(s) {
						if(s.isGroup()) {
							s.ungroup();

							// TODO: highlight the separated elements
						}
						else s.group();
						select(s);
					} else {
						changed = false;
					}
					break;
				default:
					changed = false;
					break;
			}

			if(changed) {
				// The object changed!
				dispatchEvent(new Event(Event.CHANGE));
			}
		}

		// The little handle factory
		private function makeHandle(handleType:int = HT_RESIZER):Sprite {
			var spr:Sprite = new Sprite();
			var handler:Function = null;
			var color:uint = 0;
			switch(handleType) {
				case HT_RESIZER:
					color = resizeColor;
					handler = resizeHandler;
					break;
				case HT_ROTATOR:
					color = rotateColor;
					handler = rotateHandler;
					break;
				case HT_MOVER:
					color = moveColor;
					handler = moveHandler;
					break;
			}
			var handlerWrapper:Function = function(e:MouseEvent):void { toolCursorHandler(e, handleType); };
			spr.addEventListener(MouseEvent.ROLL_OVER, handlerWrapper, false, 0, true);
			spr.addEventListener(MouseEvent.ROLL_OUT, handlerWrapper, false, 0, true);

			// Draw the handle (just a circle)
			spr.graphics.lineStyle(1, color);
			spr.graphics.beginFill(0xFFFFFF);
			if(handleType == HT_ROTATOR || handleType == HT_MOVER)
				spr.graphics.drawCircle(0, 0, 4);
			else
				spr.graphics.drawRect(-3, -3, 6, 6);
			spr.graphics.endFill();
			spr.addEventListener(MouseEvent.MOUSE_DOWN, handler, false, 0, true);
			addChild(spr);

			return spr;
		}

		private function setActive(active:Boolean):void {
			isTransforming = active;
			editor.getToolsLayer().mouseEnabled = !active;
			editor.getToolsLayer().mouseChildren = !active;
			if(!active) editor.setCurrentCursor(null);
		}

		private function toolCursorHandler(e:MouseEvent, handleType:int):void {
			if(e.type == MouseEvent.ROLL_OUT) {
				// Keep the current operations cursor even if the mouse moves away from the handle
				if(!isTransforming) {
					//trace('removing cursor, no operation in progress');
					if(editor)
						editor.setCurrentCursor(null);
					else if(e.currentTarget)
						e.currentTarget.removeEventListener(e.type, arguments.callee);
				}
				return;
			}

			// Don't switch cursors while transforming
			if(isTransforming) {
				//trace('not changing cursor during operation');
				return;
			}
//trace('Setting cursor for ' + handleType);
			switch(handleType) {
				case HT_RESIZER:
					updateResizeCursor(e.target as Sprite);
					break;
				case HT_ROTATOR:
					editor.setCurrentCursor('rotateCursor', 'rotateCursor', new Point(10, 13));
					break;
				case HT_MOVER:
					editor.setCurrentCursor(MouseCursor.HAND);
					break;
			}
		}

		private function updateResizeCursor(handle:Sprite):void {
			var isDiagonal:Boolean = (scaleHandleDict[handle] as String).length > 6;
			var r:Rectangle = targetObj.getBounds(STAGE);
			var center:Point = new Point((r.left + r.right)/2, (r.top + r.bottom)/2);
			var up:Point = localToGlobal(new Point(handle.x, handle.y)).subtract(center);
			up.normalize(1);
			var rt:Point = new Point(-up.y, up.x);

			var len:Number = 14;
			var arrowRatio:Number = 0.4;
			var arrowWidth:Number = arrowRatio * len;
			var halfWidth:Number = 0.5 * arrowWidth;
			var beforeArrow:Number = (1 - arrowRatio) * len;
			var s:Sprite = new Sprite();
			s.graphics.lineStyle(2, 0x464b52);
			// Draw link between arrows
			s.graphics.moveTo(-beforeArrow * up.x, -beforeArrow * up.y);
			s.graphics.lineTo(beforeArrow * up.x, beforeArrow * up.y);

			// Draw arrows
			s.graphics.lineStyle(1, 0x464b52);
			if(isDiagonal) s.graphics.beginFill(0x464b52);
			s.graphics.moveTo(len * up.x, len * up.y);
			s.graphics.lineTo(beforeArrow * up.x + halfWidth * rt.x, beforeArrow * up.y + halfWidth * rt.y);
			s.graphics.lineTo(beforeArrow * up.x - halfWidth * rt.x, beforeArrow * up.y - halfWidth * rt.y);
			s.graphics.lineTo(len * up.x, len * up.y);
			if(isDiagonal) s.graphics.endFill();

			if(isDiagonal) s.graphics.beginFill(0x464b52);
			s.graphics.moveTo(-len * up.x, -len * up.y);
			s.graphics.lineTo(-beforeArrow * up.x + halfWidth * rt.x, -beforeArrow * up.y + halfWidth * rt.y);
			s.graphics.lineTo(-beforeArrow * up.x - halfWidth * rt.x, -beforeArrow * up.y - halfWidth * rt.y);
			s.graphics.lineTo(-len * up.x, -len * up.y);
			if(isDiagonal) s.graphics.endFill();

			s.filters = [new GlowFilter(0xFFFFFF, 0.6, 3, 3)];

			// Render the cursor and set it
			var curBM:BitmapData = new BitmapData(28, 28, true, 0);
			var m:Matrix = new Matrix();
			m.translate(14, 14);
			curBM.draw(s, m);
			editor.setCurrentCursor('resize', curBM, new Point(16, 16), false);
		}

		private function toggleHandles(vis:Boolean):void {
			for(var i:uint=0; i<numChildren; ++i) {
				getChildAt(i).visible = vis;
			}
		}

		private function resizeHandler(e:MouseEvent):void {
			switch(e.type) {
				case MouseEvent.MOUSE_DOWN:
					activeHandle = Sprite(e.target);
					editor.addEventListener(MouseEvent.MOUSE_MOVE, arguments.callee, false, 0, true);
					STAGE.addEventListener(MouseEvent.MOUSE_UP, arguments.callee, false, 0, true);
					e.stopPropagation();

					// Reset the center since we're resizing
					// TODO: move the "center" proportionally instead?
					centerMoved = false;
					targetObj.startResize(scaleHandleDict[activeHandle]);
					setActive(true);
					break;

				case MouseEvent.MOUSE_MOVE:
					targetObj.scaleByMouse(scaleHandleDict[activeHandle]);
					showUI();
					break;

				case MouseEvent.MOUSE_UP:
					setActive(false);
					editor.removeEventListener(MouseEvent.MOUSE_MOVE, arguments.callee);
					STAGE.removeEventListener(MouseEvent.MOUSE_UP, arguments.callee);
					removeEventListener(MouseEvent.MOUSE_DOWN, arguments.callee);
					activeHandle = null;
					targetObj.saveTransform();

					// The object changed!
					dispatchEvent(new Event(Event.CHANGE));
					break;
			}
		}

		private var movingHandle:Boolean = false;
		private var wasMoved:Boolean = false;
		private function moveHandler(e:MouseEvent, newSelection:Boolean = false):void {
			if(!stage) return;

			switch(e.type) {
				case MouseEvent.MOUSE_DOWN:
					if(!dblClickTimer)
						startDblClickTimer();

					if(!targetObj.canMoveByMouse())
						return;
					editor.addEventListener(MouseEvent.MOUSE_MOVE, arguments.callee, false, 0, true);
					STAGE.addEventListener(MouseEvent.MOUSE_UP, arguments.callee, false, 0, true);

					// If they are pressing shift and clicking on the move handle, allow the user
					// to move the handle (changing the center of rotation for the object)
					if(e.target == moveHandle && e.shiftKey) {
						moveOffset = null;
					} else {
						moveOffset = new Point(parent.mouseX - x, parent.mouseY - y);
					}
					wasMoved = false;//newSelection;
					setActive(true);
					e.stopImmediatePropagation();
					//break;

				case MouseEvent.MOUSE_MOVE:
					if(!editor.getCanvasLayer().getBounds(STAGE).containsPoint(new Point(STAGE.mouseX, STAGE.mouseY)))
						break;

					if(moveOffset) {
						x = parent.mouseX - moveOffset.x;
						y = parent.mouseY - moveOffset.y;
						if (editor is BitmapEdit) {
							var p:Point = toolsLayer.globalToLocal(localToGlobal(new Point(topLeftHandle.x, topLeftHandle.y)));
							var snapped:Point = editor.snapToGrid(p);
							x += snapped.x - p.x;
							y += snapped.y - p.y;
						}
						updateTarget();
					} else {
						moveHandle.x = mouseX;
						moveHandle.y = mouseY;
					}

					if(e.type == MouseEvent.MOUSE_MOVE) {
						wasMoved = true;
					}
					break;

				case MouseEvent.MOUSE_UP:
					setActive(false);
					centerMoved = (moveOffset == null);
					editor.removeEventListener(MouseEvent.MOUSE_MOVE, arguments.callee);
					STAGE.removeEventListener(MouseEvent.MOUSE_UP, arguments.callee);

					targetObj.saveTransform();

					// The object changed!
					if(wasMoved) {
						dispatchEvent(new Event(Event.CHANGE));
						dblClickTimeout();
					}
					break;
			}
		}

		private function rotateHandler(e:MouseEvent):void {
			switch(e.type) {
				case MouseEvent.MOUSE_DOWN:
					STAGE.addEventListener(MouseEvent.MOUSE_MOVE, arguments.callee, false, 0, true);
					STAGE.addEventListener(MouseEvent.MOUSE_UP, arguments.callee, false, 0, true);

					// Make sure we can rotate around the center of the selection
					e.stopPropagation();
					initialMatrix = transform.matrix.clone();
					initialRotation = Math.atan2(rotateHandle.y - moveHandle.y, rotateHandle.x - moveHandle.x);
					targetObj.startRotation(localToGlobal(new Point(moveHandle.x, moveHandle.y)));
					setActive(true);
					break;

				case MouseEvent.MOUSE_MOVE:
					// Rotate the ObjectTransformer ui
					var m:Matrix = initialMatrix.clone();
					transform.matrix = m;
					var rot:Number = Math.atan2(mouseY - moveHandle.y, mouseX - moveHandle.x);
					var c:Point = localToGlobal(new Point(moveHandle.x, moveHandle.y));
					c = parent.globalToLocal(c);
					m.tx -= c.x;
					m.ty -= c.y;
					m.rotate( rot - initialRotation );
					m.tx += c.x;
					m.ty += c.y;
					transform.matrix = m;

					// Rotate the selection
					targetObj.doRotation(rot - initialRotation);
					break;

				case MouseEvent.MOUSE_UP:
					setActive(false);
					STAGE.removeEventListener(MouseEvent.MOUSE_MOVE, arguments.callee);
					STAGE.removeEventListener(MouseEvent.MOUSE_UP, arguments.callee);
					targetObj.saveTransform();

					// The object changed!
					dispatchEvent(new Event(Event.CHANGE));
					break;
			}
		}

		private function updateTarget():void {
			if(targetObj) {
				var p:Point = localToGlobal(new Point(topLeftHandle.x, topLeftHandle.y));
				targetObj.setTLPosition(p);
			}
		}

		private function showUI():void {
			// Clear the graphics "canvas"
			graphics.clear();

			var pts:Object = targetObj.getGlobalBoundingPoints();
			var topLeft:Point = globalToLocal(pts.topLeft);
			var topRight:Point = globalToLocal(pts.topRight);
			var botLeft:Point = globalToLocal(pts.botLeft);
			var botRight:Point = globalToLocal(pts.botRight);

			//trace("drawing the box");
			// Draw the dashed box
			var dLen:uint = (targetObj.isGroup() ? grpDashLength : targetObj.isImage() ? bmDashLength : dashLength);
			var dCol:uint = (targetObj.isGroup() ? grpDashColor : targetObj.isImage() ? bmDashColor : dashColor);
			graphics.lineStyle(2, dCol);
			graphics.moveTo(topLeft.x, topLeft.y);
			graphics.lineTo(topRight.x, topRight.y);
			graphics.lineTo(botRight.x, botRight.y);
			graphics.lineTo(botLeft.x, botLeft.y);
			graphics.lineTo(topLeft.x, topLeft.y);
			//DashDrawer.drawPoly(graphics, [topLeft, topRight, botRight, botLeft], dLen, dCol);

			// Re-position the move handle
			if(!centerMoved) {
				moveHandle.x = (topLeft.x + botRight.x) / 2;
				moveHandle.y = (topLeft.y + botRight.y) / 2;
			}

			// Re-position the resize handles
			topLeftHandle.x = topLeft.x;
			topLeftHandle.y = topLeft.y;
			topRightHandle.x = topRight.x;
			topRightHandle.y = topRight.y;
			bottomLeftHandle.x = botLeft.x;
			bottomLeftHandle.y = botLeft.y;
			bottomRightHandle.x = botRight.x;
			bottomRightHandle.y = botRight.y;
			topHandle.x = (topLeft.x + topRight.x) / 2;
			topHandle.y = (topLeft.y + topRight.y) / 2;
			leftHandle.x = (topLeft.x + botLeft.x) / 2;
			leftHandle.y = (topLeft.y + botLeft.y) / 2;
			bottomHandle.x = (botLeft.x + botRight.x) / 2;
			bottomHandle.y = (botLeft.y + botRight.y) / 2;
			rightHandle.x = (topRight.x + botRight.x) / 2;
			rightHandle.y = (topRight.y + botRight.y) / 2;

			// Re-position the rotate handle
			var p:Point = new Point(topHandle.x - moveHandle.x, topHandle.y - moveHandle.y);
			p.normalize(20.0);
			rotateHandle.x = topHandle.x + p.x;
			rotateHandle.y = topHandle.y + p.y;


			// Draw a line to the rotator handle
			graphics.moveTo(topHandle.x, topHandle.y);
			graphics.lineTo(rotateHandle.x, rotateHandle.y);
			//DashDrawer.drawLine(graphics, new Point(topHandle.x, topHandle.y), new Point(rotateHandle.x, rotateHandle.y), dashLength, dashColor);
			x = y = 0;
		}

		private var selectionOrigin:Point;
		private function selectionBoxHandler(e:MouseEvent):void {
			if(selectionOrigin) {
				var p:Point = editor.snapToGrid(new Point(toolsLayer.mouseX, toolsLayer.mouseY));
				var left:Number = Math.min(selectionOrigin.x, p.x);
				var top:Number = Math.min(selectionOrigin.y, p.y);
				var right:Number = Math.max(selectionOrigin.x, p.x);
				var bottom:Number = Math.max(selectionOrigin.y, p.y);
				var rect:Rectangle = new Rectangle(left, top, right - left, bottom - top);
			}

			switch(e.type) {
				case MouseEvent.MOUSE_DOWN:
					// The editor will want to return to the rectangle or ellipse tool if the user clicks outside of the selection and the selection is holding a just-drawn rectangle or ellipse.
					if (editor.revertToCreateTool(e)) return;

					STAGE.addEventListener(MouseEvent.MOUSE_MOVE, arguments.callee, false, 0, true);
					STAGE.addEventListener(MouseEvent.MOUSE_UP, arguments.callee, false, 0, true);
					selectionOrigin = editor.snapToGrid(new Point(toolsLayer.mouseX, toolsLayer.mouseY));

					currentEvent = null;
					select(null);
					break;

				case MouseEvent.MOUSE_MOVE:
					toolsLayer.graphics.clear();
					if (editor is BitmapEdit) {
						toolsLayer.graphics.lineStyle(1, 0x404040);
						toolsLayer.graphics.drawRect(rect.x, rect.y, rect.width, rect.height);
					} else {
						DashDrawer.drawBox(toolsLayer.graphics, rect, 3, 0x0000FF);
					}
					break;

				case MouseEvent.MOUSE_UP:
					toolsLayer.graphics.clear();
					STAGE.removeEventListener(MouseEvent.MOUSE_MOVE, arguments.callee);
					STAGE.removeEventListener(MouseEvent.MOUSE_UP, arguments.callee);

					if (editor is BitmapEdit) {
						// Compute the selection rectangle relative to the bitmap content.
						var contentP:Point = contentLayer.globalToLocal(toolsLayer.localToGlobal(rect.topLeft));
						var scale:Number = editor.getWorkArea().getScale();
						// trace(contentP.x, contentP.y, rect.width, rect.height, scale);
						var r:Rectangle = new Rectangle(
							Math.floor(contentP.x * 2), Math.floor(contentP.y * 2),
							Math.ceil(rect.width / scale * 2), Math.ceil(rect.height / scale * 2));
						var selectedBM:SVGBitmap = (editor as BitmapEdit).getSelection(r);
						if (selectedBM) select(new Selection([selectedBM]));
					} else {
						attemptSelect(rect);
					}
					break;
			}
		}

		private function attemptSelect(rect:Rectangle):void {
			// Expand the rectangle (by 20% in every direction) in case they cut off a little of an element
			var w:Number = rect.width * 0.2;
			var h:Number = rect.height * 0.2;
			rect.top = rect.top - h;
			rect.bottom = rect.bottom + h;
			rect.left = rect.left - w;
			rect.right = rect.right + w;

			var foundObjs:Array = new Array();
			for(var i:int = 0; i<contentLayer.numChildren; ++i) {
				var obj:DisplayObject = DisplayObject(contentLayer.getChildAt(i));
				var objRect:Rectangle = obj.getRect(toolsLayer);
				if(obj is ISVGEditable && rect.containsRect(objRect) && foundObjs.indexOf(obj) == -1 && !(obj as ISVGEditable).getElement().isBackDropBG()) {
					foundObjs.push(obj);
				}
			}

			if(foundObjs.length > 0) {
				select(new Selection(foundObjs));
			} else {
				select(null);
			}
		}
	}
}
