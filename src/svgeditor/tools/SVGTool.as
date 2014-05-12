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
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import svgeditor.ImageEdit;
	import svgeditor.objs.*;
	
	import svgutils.SVGPath;

	public class SVGTool extends Sprite
	{
		protected var editor:ImageEdit;
		protected var isShuttingDown:Boolean;
		protected var currentEvent:MouseEvent;
		protected var cursorBMName:String;
		protected var cursorName:String;
		protected var cursorHotSpot:Point;
		protected var touchesContent:Boolean;

		public function SVGTool(ed:ImageEdit) {
			editor = ed;
			isShuttingDown = false;
			touchesContent = false;

			addEventListener(Event.ADDED_TO_STAGE, addedToStage);
			addEventListener(Event.REMOVED, removedFromStage);
		}

		public function refresh():void {}

		protected function init():void {
			if(cursorBMName && cursorHotSpot)
				editor.setCurrentCursor(cursorBMName, cursorBMName, cursorHotSpot);
			else if(cursorName)
				editor.setCurrentCursor(cursorName);
		}

		protected function shutdown():void {
			editor.setCurrentCursor(null);
			editor = null;
		}

		public final function interactsWithContent():Boolean {
			return touchesContent;
		}

		public function cancel():void {
			if(parent) parent.removeChild(this);
		}

		private function addedToStage(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, addedToStage);
			init();
		}

		private function removedFromStage(e:Event):void {
			if(e.target != this) return;

			removeEventListener(Event.REMOVED, removedFromStage);
			isShuttingDown = true;
			shutdown();
		}

		protected function getEditableUnderMouse(includeGroups:Boolean = true):ISVGEditable {
			return staticGetEditableUnderMouse(editor, includeGroups, this);
		}

		static public function staticGetEditableUnderMouse(editor:ImageEdit, includeGroups:Boolean = true, currentTool:SVGTool = null):ISVGEditable {
			if(!editor.stage) return null;

			var objs:Array = editor.stage.getObjectsUnderPoint(new Point(editor.stage.mouseX, editor.stage.mouseY));

			// Select the top object that is ISVGEditable
			if(objs.length) {
				// Try to find the topmost element whose parent is the selection context
				for(var i:int = objs.length - 1; i>=0; --i) {
					var rawObj:DisplayObject = objs[i];
					var obj:DisplayObject = getChildOfSelectionContext(rawObj, editor);

					// If we're not including groups and a group was selected, try to select the object under
					// the mouse if it's parent is the group found.
					if(!includeGroups && obj is SVGGroup && rawObj.parent is SVGGroup && rawObj is ISVGEditable)
						obj = rawObj;

					var isPaintBucket:Boolean = (currentTool is PaintBucketTool || currentTool is PaintBrushTool);
					var isOT:Boolean = (currentTool is ObjectTransformer);
					if(obj is ISVGEditable && (includeGroups || !(obj is SVGGroup)) && (isPaintBucket || !(obj as ISVGEditable).getElement().isBackDropBG())) {
						return (obj as ISVGEditable);
					}
				}
			}

			return null;
		}

		static private function getChildOfSelectionContext(obj:DisplayObject, editor:ImageEdit):DisplayObject {
			var contentLayer:Sprite = editor.getContentLayer();
			while(obj && obj.parent != contentLayer) obj = obj.parent;
			return obj;
		}

		// Used by the PathEditTool and PathTool
		protected function getContinuableShapeUnderMouse(strokeWidth:Number):Object {
			// Hide the current path so we don't get that
			var obj:ISVGEditable = getEditableUnderMouse(false);
			
			if(obj is SVGShape) {
				var s:SVGShape = obj as SVGShape;
				var path:SVGPath = s.getElement().path;
				var segment:Array = path.getSegmentEndPoints(0);
				var isClosed:Boolean = segment[2];
				var otherWidth:Number = s.getElement().getAttribute('stroke-width', 1);
				var w:Number = (strokeWidth + otherWidth) / 2;
				if(!isClosed) {
					var m:Point = new Point(s.mouseX, s.mouseY);
					var p:Point = null;
					if(path.getPos(segment[0]).subtract(m).length < w) {
						return {index: segment[0], bEnd: false, shape: (obj as SVGShape)};
					}
					else if(path.getPos(segment[1]).subtract(m).length < w) {
						return {index: segment[1], bEnd: true, shape: (obj as SVGShape)};
					}
				}
			}
			
			return null;
		}
	}
}
