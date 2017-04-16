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

// RenderedVariable.as
// Anders Lindén, February 2015
//
// A RenderedVariable object is having a short lifetime and is only used to
// couple name with the scope, so that global variables can appear underlined

package {
	public class RenderedVariable {
		public var name:String;
		public var local:Boolean;
		public function RenderedVariable(name:String, local:Boolean):void {
			this.name = name;
			this.local = local;
		}
	}
}
