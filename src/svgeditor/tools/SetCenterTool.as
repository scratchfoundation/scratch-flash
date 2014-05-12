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
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	import svgeditor.ImageCanvas;
	import svgeditor.ImageEdit;

	public final class SetCenterTool extends SVGTool
	{
		private var canvasCenter:Point; // Used for reporting back the new offset
		private var localRect:Rectangle; // Used for drawing crosshairs
		private var active:Boolean;
		public function SetCenterTool(ed:ImageEdit) {
			super(ed);
			cursorBMName = 'setCenterOff';
			cursorHotSpot = new Point(8, 8);
			active = false;
		}

		override protected function init():void {
			super.init();
			editor.getToolsLayer().mouseEnabled = false;
			editor.getToolsLayer().mouseChildren = false;

			editor.getWorkArea().addEventListener(MouseEvent.MOUSE_DOWN, mouseDown, false, 0, true);
			refresh();
		}

		override protected function shutdown():void {
			editor.getToolsLayer().mouseEnabled = true;
			editor.getToolsLayer().mouseChildren = true;

			editor.getWorkArea().removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			editor.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			editor.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
			super.shutdown();
		}

		override public function refresh():void {
			var canvas:ImageCanvas = editor.getWorkArea();
			var r:Rectangle = canvas.getVisibleLayer().getRect(canvas.getVisibleLayer());
			canvasCenter = new Point(Math.round((r.right-r.left)/2), Math.round((r.bottom-r.top)/2));
			localRect = canvas.getVisibleLayer().getRect(this);

			if(!active) {
				var cp:Point = globalToLocal(canvas.getVisibleLayer().localToGlobal(canvasCenter));

				graphics.clear();
				if(localRect.containsPoint(cp)) {
					graphics.lineStyle(2);
					graphics.moveTo(localRect.left, cp.y);
					graphics.lineTo(localRect.right, cp.y);
					graphics.moveTo(cp.x, localRect.top);
					graphics.lineTo(cp.x, localRect.bottom);
				}
			}
		}

		private function mouseDown(e:MouseEvent):void {
			editor.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove, false, 0, true);
			editor.addEventListener(MouseEvent.MOUSE_UP, mouseUp, false, 0, true);
			mouseMove();
			active = true;
		}

		private function mouseMove(e:MouseEvent = null):void {
			graphics.clear();

			graphics.lineStyle(2);
			graphics.moveTo(localRect.left, mouseY);
			graphics.lineTo(localRect.right, mouseY);
			graphics.moveTo(mouseX, localRect.top);
			graphics.lineTo(mouseX, localRect.bottom);
		}

		private function mouseUp(e:MouseEvent):void {
			var canvas:ImageCanvas = editor.getWorkArea();
			var ox:int = Math.round(ImageCanvas.canvasWidth / 2 - canvas.getVisibleLayer().mouseX);
			var oy:int = Math.round(ImageCanvas.canvasHeight / 2 - canvas.getVisibleLayer().mouseY);
			editor.translateContents(ox, oy);
			editor.endCurrentTool();
		}
	}
}
