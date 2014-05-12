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
	import flash.events.*;
	import flash.geom.*;
	
	import svgeditor.*;
	import svgeditor.objs.*;
	
	import svgutils.SVGElement;

	public final class PaintBrushTool extends SVGEditTool
	{
		private var shapeUnderMouse:ISVGEditable;
		private var overStroke:Boolean;
		public function PaintBrushTool(svgEditor:ImageEdit) {
			super(svgEditor);
			cursorBMName = 'vpaintbrushOff';
//			cursorHotSpot = new Point(6,20);
			cursorHotSpot = new Point(17,16); // for Champika's paint bucket (experimental)
		}

		override protected function edit(obj:ISVGEditable, event:MouseEvent):void {
			// Use the shapeObj
			if(shapeUnderMouse) {
				dispatchEvent(new Event(Event.CHANGE)); // save after doing the fill change
				shapeUnderMouse = null;
			}
		}

		override protected function init():void {
			super.init();
			editor.getContentLayer().addEventListener(MouseEvent.ROLL_OVER, rollOver, false, 0, true);
			editor.getContentLayer().addEventListener(MouseEvent.ROLL_OUT, rollOut, false, 0, true);
		}

		override protected function shutdown():void {
			editor.getContentLayer().removeEventListener(MouseEvent.ROLL_OVER, rollOver);
			editor.getContentLayer().removeEventListener(MouseEvent.ROLL_OUT, rollOut);
			editor.getContentLayer().removeEventListener(MouseEvent.MOUSE_MOVE, previewColorChange);
			super.shutdown();
		}

		private function rollOver(e:MouseEvent):void {
			editor.getContentLayer().addEventListener(MouseEvent.MOUSE_MOVE, previewColorChange, false, 0, true);
			previewColorChange(e);
			//timer.start();
		}

		private function rollOut(e:MouseEvent):void {
			editor.getContentLayer().removeEventListener(MouseEvent.MOUSE_MOVE, previewColorChange);
			previewColorChange();
		}

		private var oldStrokeW:*;
		private var oldStrokeO:*;
		private var oldStroke:*;
		private var oldFill:*;
		private var isOverStroke:Boolean;
		private function previewColorChange(e:MouseEvent = null):void {
			var obj:ISVGEditable = e ? getEditableUnderMouse(false) : null;
			if(!(obj is SVGShape || obj is SVGTextField)) obj = null;

			var elem:SVGElement;
			if(shapeUnderMouse && shapeUnderMouse != obj) {
				elem = shapeUnderMouse.getElement();
				elem.setAttribute('fill', oldFill);
				elem.setAttribute('stroke', oldStroke);
				elem.setAttribute('stroke-width', oldStrokeW);				
				elem.setAttribute('stroke-opacity', oldStrokeO);
				shapeUnderMouse.redraw();
			}

			if(obj) {
				var val:* = getFillValue(obj);
				var alpha:Number = editor.getShapeProps().alpha;
				elem = obj.getElement();
				if(shapeUnderMouse != obj) {
					oldFill = elem.getAttribute('fill');
					oldStroke = elem.getAttribute('stroke');
					oldStrokeW = elem.getAttribute('stroke-width');
					oldStrokeO = elem.getAttribute('stroke-opacity', 1);
				}

				if(!elem.isBackDropFill() && !(obj is SVGTextField)) {
					elem.setAttribute('fill', 'none');
					elem.setAttribute('stroke-opacity', 1);
					if(oldStroke == 'none' || oldStrokeW < 2) {
						elem.setAttribute('stroke', 'black');
						if(oldStrokeW < 2 || oldStrokeW == null)
							elem.setAttribute('stroke-width', 2);
					}
					obj.redraw(true);
					isOverStroke = (obj as DisplayObject).hitTestPoint(stage.mouseX, stage.mouseY, true);
				}
				else {
					isOverStroke = false;
				}

				if(isOverStroke) {
					if(alpha>0 || val is SVGElement) {
						elem.setAttribute('stroke', val);
						elem.setAttribute('stroke-opacity', alpha);
					}
					else
						elem.setAttribute('stroke-opacity', 0);
					elem.setAttribute('fill', oldFill);
				}
				else {
					if(alpha>0 || val is SVGElement)
						elem.setAttribute('fill', val);
					else
						elem.setAttribute('fill', 'none');
					elem.setAttribute('stroke-opacity', oldStrokeO);
					elem.setAttribute('stroke', oldStroke);
					elem.setAttribute('stroke-width', oldStrokeW);
				}
				obj.redraw();
			}

			shapeUnderMouse = obj;
		}

		private function getFillValue(obj:ISVGEditable):* {
			// If the fill is solid or the element isn't a shape, return the color
			if(editor.getShapeProps().fillType == 'solid' || !(obj is SVGShape))
				return SVGElement.colorToHex(editor.getShapeProps().color);

			// Create the gradient element
			var tagName:String = editor.getShapeProps().fillType == 'radial' ?
				'radialGradient' : 'linearGradient';
			var grad:SVGElement = new SVGElement(tagName, 'grad' + Math.floor(Math.random()*1000));
			if(tagName == 'radialGradient') {
				var b:Rectangle = (obj as DisplayObject).getBounds(obj as DisplayObject);
				var tl:Point = b.topLeft;
				var mp:Point = new Point((obj as DisplayObject).mouseX, (obj as DisplayObject).mouseY);
				var fx:Number = (mp.x - tl.x) / b.width;
				var fy:Number = (mp.y - tl.y) / b.height;
				var rx:Number = (Math.floor(fx * 10000) / 100);
				var ry:Number = (Math.floor(fy * 10000) / 100);
				grad.setAttribute('cx', rx + '%');
				grad.setAttribute('cy', ry + '%');
				grad.setAttribute('r', (65 + 1.3*Math.max(Math.abs(rx-50), Math.abs(ry-50)))+'%');
			}
			else {
				grad.setAttribute('x1', '0%');
				grad.setAttribute('y1', '0%');
				if(editor.getShapeProps().fillType == 'linearHorizontal') {
					grad.setAttribute('x2', '100%');
					grad.setAttribute('y2', '0%');
				}
				else {
					grad.setAttribute('x2', '0%');
					grad.setAttribute('y2', '100%');
				}
			}

			// Now indicate the colors for the gradient
			var props:DrawProperties = editor.getShapeProps();
			var stop:SVGElement = new SVGElement('stop');
			stop.setAttribute('offset', 0);
			stop.setAttribute('stop-color', SVGElement.colorToHex(props.alpha > 0 ? props.color : props.secondColor));
			stop.setAttribute('stop-opacity', props.alpha);
			grad.subElements.push(stop);
			stop = new SVGElement('stop');
			stop.setAttribute('offset', 1);
			stop.setAttribute('stop-color', SVGElement.colorToHex(props.secondAlpha > 0 ? props.secondColor: props.color));
			stop.setAttribute('stop-opacity', props.secondAlpha);
			grad.subElements.push(stop);
			return grad;
		}
	}
}