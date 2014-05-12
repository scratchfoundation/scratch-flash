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

// BlockPalette.as
// John Maloney, August 2009
//
// A BlockPalette holds the blocks for the selected category.
// The mouse handling code detects when a Block's parent is a BlocksPalette and
// creates a copy of that block when it is dragged out of the palette.

package ui {
	import blocks.Block;
	import uiwidgets.*;
	import scratch.ScratchComment;

public class BlockPalette extends ScrollFrameContents {

	public const isBlockPalette:Boolean = true;

	public function BlockPalette():void {
		super();
		this.color = 0xE0E0E0;
	}

	public function handleDrop(obj:*):Boolean {
		// Delete blocks and stacks dropped onto the palette.
		var app:Scratch = root as Scratch;
		var c:ScratchComment = obj as ScratchComment;
		if (c) {
			c.x = c.y = 20; // postion for undelete
			c.deleteComment();
			return true;
		}
		var b:Block = obj as Block;
		if (b) {
			if ((b.op == Specs.PROCEDURE_DEF) && hasCallers(b, app)) {
				DialogBox.notify('Cannot Delete', 'To delete a block definition, first remove all uses of the block.', stage);
				return false;
			}
			if (b.parent) b.parent.removeChild(b);
			b.restoreOriginalPosition(); // restore position in case block is undeleted
			Scratch.app.runtime.recordForUndelete(b, b.x, b.y, 0, Scratch.app.viewedObj());
			app.scriptsPane.saveScripts();
			app.updatePalette();
			return true;
		}
		return false;
	}

	private function hasCallers(def:Block, app:Scratch):Boolean {
		var callCount:int;
		for each (var stack:Block in app.viewedObj().scripts) {
			// for each block in stack
			stack.allBlocksDo(function (b:Block):void {
				if ((b.op == Specs.CALL) && (b.spec == def.spec)) callCount++;
			});
		}
		return callCount > 0;
	}

	public static function strings():Array {
		return ['Cannot Delete', 'To delete a block definition, first remove all uses of the block.'];
	}

}}
