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

// Variable.as
// John Maloney, February 2010
//
// A variable is a name-value pair.

package interpreter {
	import util.JSON;

public class Variable {

	public var name:String;
	public var value:*;
	public var watcher:*;
	public var isPersistent:Boolean;
	// The following is the variable's position (1-based) in its owner's
	// variable list. If the variable is global (i.e.Stage) then negative.
	// This value is placed into a block's variableIndex to provide a very
	// quick way to reference the variable.
	// It cannot be relied upon if app.varsAreDirty is true.
	public var pos:int = 0;

	public function Variable(vName:String, initialValue:*, vPos:int) {
		name = vName;
		value = initialValue;
		pos = vPos;
	}

	public function writeJSON(json:util.JSON):void {
		json.writeKeyValue('name', name);
		json.writeKeyValue('value', value);
		json.writeKeyValue('isPersistent', isPersistent);
	}

}}
