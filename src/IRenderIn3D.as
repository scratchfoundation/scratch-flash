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

// IRenderIn3D.as
// Shane M. Clements, November 2013
//
// Interface for 3D rendering layer

package {
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.events.Event;

public interface IRenderIn3D {SCRATCH::allow3d{
	function setStage(stage:Sprite, penLayer:DisplayObject):void;
	function getUIContainer():Sprite;
	function getRenderedChild(dispObj:DisplayObject, width:Number, height:Number, for_carry:Boolean = false):BitmapData;
	function getOtherRenderedChildren(skipObj:DisplayObject, scale:Number):BitmapData;
	function updateRender(dispObj:DisplayObject, renderID:String = null, renderOpts:Object = null):void;
	function updateFilters(dispObj:DisplayObject, effects:Object):void;
	function updateGeometry(dispObj:DisplayObject):void;
	function onStageResize(e:Event = null):void;
	function getRender(bmd:BitmapData):void;
	function setStatusCallback(callback:Function):void;
	function spriteIsLarge(dispObj:DisplayObject):Boolean;
}}
}
