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

package util {

import flash.utils.getQualifiedClassName;
import flash.display.DisplayObjectContainer;
import flash.display.DisplayObject;

public class DebugUtils {

	public static function printTree(top:DisplayObject):String {
		var result:String = '';
		printSubtree(top, 0, result);
		return result;
	}

	private static function printSubtree(t:DisplayObject, indent:int, out:String):void {
		var tabs:String = '';
		for (var i:int = 0; i < indent; i++) tabs += '\t';
		out += tabs + getQualifiedClassName(t) + '\n';
		var container:DisplayObjectContainer = t as DisplayObjectContainer;
		if (container == null) return;
		for (i = 0; i < container.numChildren; i++) {
			printSubtree(container.getChildAt(i), indent + 1, out);
		}
	}

}}
