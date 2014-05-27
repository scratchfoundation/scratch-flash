/*
 * Scratch Project Editor and Player
 * Copyright (C) 2014 Massachusetts Institute of Technology
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General License for more details.
 *
 * You should have received a copy of the GNU General License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

// IScriptsPart.as
// Shane Clements, March 2014
//
// This is an interface for the part that holds the palette and scripts pane for the current sprite (or stage).

package ui.parts.base {
public interface ILibraryPart {
	function showVideoButton():void;
	function step():void;
	function refresh():void;
	function highlight(sprites:Array):void;
	function showSpriteDetails(flag:Boolean):void;
	function setWidthHeight(w:int, h:int):void;
	function setXY(x:Number, y:Number):void;
	function updateTranslation():void;
	function get x():Number;
	function get y():Number;
}}
