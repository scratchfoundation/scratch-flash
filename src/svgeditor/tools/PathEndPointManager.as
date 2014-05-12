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
	import flash.geom.Point;
	
	import svgeditor.ImageEdit;
	import svgeditor.objs.ISVGEditable;
	import svgeditor.objs.SVGGroup;
	import svgeditor.objs.SVGShape;
	import svgeditor.tools.PathAnchorPoint;
	
	import svgutils.SVGPath;

	public final class PathEndPointManager
	{
		static private var orb:Sprite;
		static private var endPoints:Array;
		static private var editor:ImageEdit;
		static private var toolsLayer:Sprite;

		static public function init(ed:ImageEdit):void {
			editor = ed;
			orb = new Sprite();
			orb.visible = false;
			orb.mouseEnabled = false;
			orb.mouseChildren = false;
			PathAnchorPoint.render(orb.graphics);
		}

		static public function updateOrb(highlight:Boolean, p:Point = null):void {
			orb.visible = true;
			if(p) {
				orb.x = p.x;
				orb.y = p.y;
			}
			PathAnchorPoint.render(orb.graphics, highlight);
		}

		static public function toggleEndPoint(vis:Boolean, pt:Point = null):void {
			orb.visible = vis;

			if(vis) {
				orb.x = pt.x;
				orb.y = pt.y;
				PathAnchorPoint.render(orb.graphics, false);
			}

			if(vis && !orb.parent)
				toolsLayer.addChildAt(orb, 0);
			else if(!vis && orb.parent)
				toolsLayer.removeChild(orb);
		}

		static public function makeEndPoints(obj:DisplayObject = null):void {
			toolsLayer = editor.getToolsLayer();
			removeEndPoints();

			endPoints = [];
			editor.getToolsLayer().mouseEnabled = false;
			var layer:Sprite;
			var skipObj:DisplayObject = null;
			if(obj is Sprite)
				layer = obj as Sprite;
			else {
				if(obj is ISVGEditable) {
					layer = obj.parent as Sprite;
					skipObj = obj;
				}
				else
					layer = editor.getContentLayer();
			}
			findEndPoints(layer, skipObj);
		}

		static public function removeEndPoints():void {
			for each(var endPoint:PathEndPoint in endPoints) {
				if (endPoint.parent == toolsLayer) toolsLayer.removeChild(endPoint);
			}
			endPoints = null;
			editor.getToolsLayer().mouseEnabled = true;
		}

		static private function findEndPoints(layer:Sprite, skipObj:DisplayObject = null):void {
			for (var i:int = 0; i < layer.numChildren; ++i) {
				var c:* = layer.getChildAt(i);
				if(c is SVGGroup) {
					findEndPoints(c as Sprite);
				}
				else if(c is SVGShape && c != skipObj) {
					var s:SVGShape = c as SVGShape;
					if(s.getElement().tag == 'path' && s.getElement().path && !s.getElement().path.isClosed()) {
						// TODO: Handle nested paths too
						var path:SVGPath = s.getElement().path;
						var ends:Array = path.getSegmentEndPoints(0);
						if(!ends[2]) {
							var p:Point = toolsLayer.globalToLocal(s.localToGlobal(path.getPos(ends[0])));
							endPoints.push(toolsLayer.addChild(new PathEndPoint(editor, s, p)));
							p = toolsLayer.globalToLocal(s.localToGlobal(path.getPos(ends[1])));
							endPoints.push(toolsLayer.addChild(new PathEndPoint(editor, s, p)));
						}
					}
				}
			}
		}
	}
}