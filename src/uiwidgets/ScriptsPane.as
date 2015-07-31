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

// ScriptsPane.as
// John Maloney, August 2009
//
// A ScriptsPane is a working area that holds blocks and stacks. It supports the
// logic that highlights possible drop targets as a block is being dragged and
// decides what to do when the block is dropped.

package uiwidgets {
	import flash.display.*;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import blocks.*;
	import scratch.*;
	import flash.geom.Rectangle;
	import ui.media.MediaInfo;
	import ui.parts.ScriptsPart;

public class ScriptsPane extends ScrollFrameContents {

	private const INSERT_NORMAL:int = 0;
	private const INSERT_ABOVE:int = 1;
	private const INSERT_SUB1:int = 2;
	private const INSERT_SUB2:int = 3;
	private const INSERT_WRAP:int = 4;

	public var app:Scratch;
	public var padding:int = 10;

	private var viewedObj:ScratchObj;
	private var commentLines:Shape;

	private var possibleTargets:Array = [];
	private var nearestTarget:Array = [];
	private var feedbackShape:BlockShape;

	public function ScriptsPane(app:Scratch) {
		this.app = app;
		addChild(commentLines = new Shape());
		hExtra = vExtra = 40;
		createTexture();
		addFeedbackShape();
	}

	private function createTexture():void {
		const alpha:int = 0x90 << 24;
		const bgColor:int = alpha | 0xD7D7D7;
		const c1:int = alpha | 0xCBCBCB;
		const c2:int = alpha | 0xC8C8C8;
		texture = new BitmapData(23, 23, true, bgColor);
		texture.setPixel(11, 0, c1);
		texture.setPixel(10, 1, c1);
		texture.setPixel(11, 1, c2);
		texture.setPixel(12, 1, c1);
		texture.setPixel(11, 2, c1);
		texture.setPixel(0, 11, c1);
		texture.setPixel(1, 10, c1);
		texture.setPixel(1, 11, c2);
		texture.setPixel(1, 12, c1);
		texture.setPixel(2, 11, c1);
	}

	public function viewScriptsFor(obj:ScratchObj):void {
		if (viewedObj==obj) return;  // already viewing this
		// View the blocks for the given object.
		saveScripts(false);
		while (numChildren > 0) {
			var child:DisplayObject = removeChildAt(0);
			child.cacheAsBitmap = false;
		}
		addChild(commentLines);
		viewedObj = obj;
		if (viewedObj != null) {
			var blockList:Array = viewedObj.allBlocks();
			for each (var b:Block in viewedObj.scripts) {
				b.cacheAsBitmap = true;
				addChild(b);
			}
			for each (var c:ScratchComment in viewedObj.scriptComments) {
				c.updateBlockRef(blockList);
				addChild(c);
			}
		}
		fixCommentLayout();
		updateSize();
		if (viewedObj) { // use last known position
			x = viewedObj.scriptsPosX;
			y = viewedObj.scriptsPosY;
			checkHighlightState(); // may want to show/hide highlight widget
		} else {
			x = y = 0; // reset scroll offset
		}
		(parent as ScrollFrame).updateScrollbars();
	}

	public function saveScripts(saveNeeded:Boolean = true):void {
		// Save the blocks in this pane in the viewed objects scripts list.
		if (viewedObj == null) return;
		viewedObj.scripts.splice(0); // remove all
		viewedObj.scriptComments.splice(0); // remove all
		for (var i:int = 0; i < numChildren; i++) {
			var o:* = getChildAt(i);
			if (o is Block) viewedObj.scripts.push(o);
			if (o is ScratchComment) viewedObj.scriptComments.push(o);
		}
		var blockList:Array = viewedObj.allBlocks();
		for each (var c:ScratchComment in viewedObj.scriptComments) {
			c.updateBlockID(blockList);
		}
		if (saveNeeded) app.setSaveNeeded();
		fixCommentLayout();
	}

	public function prepareToDrag(b:Block):void {
		findTargetsFor(b);
		nearestTarget = null;
		b.scaleX = b.scaleY = scaleX;
		addFeedbackShape();
	}

	public function prepareToDragComment(c:ScratchComment):void {
		c.scaleX = c.scaleY = scaleX;
	}

	public function draggingDone():void {
		hideFeedbackShape();
		possibleTargets = [];
		nearestTarget = null;
	}

	public function updateFeedbackFor(b:Block):void {

		function updateHeight(): void {
			var h:int = BlockShape.EmptySubstackH;
			if (nearestTarget != null) {
				var t:* = nearestTarget[1];
				var o:Block = null;
				switch (nearestTarget[2]) {
					case INSERT_NORMAL:
						o = t.nextBlock;
						break;
					case INSERT_WRAP:
						o = t;
						break;
					case INSERT_SUB1:
						o = t.subStack1;
						break;
					case INSERT_SUB2:
						o = t.subStack2;
						break;
				}
				if (o) {
					h = o.height;
					if (!o.bottomBlock().isTerminal) h -= BlockShape.NotchDepth;
				}
			}
			b.previewSubstack1Height(h);
		}

		function updateFeedbackShape() : void {
			var t:* = nearestTarget[1];
			var localP:Point = globalToLocal(nearestTarget[0]);
			feedbackShape.x = localP.x;
			feedbackShape.y = localP.y;
			feedbackShape.visible = true;
			if (b.isReporter) {
				if (t is Block) feedbackShape.copyFeedbackShapeFrom(t, true);
				if (t is BlockArg) feedbackShape.copyFeedbackShapeFrom(t, true);
			} else {
				var insertionType:int = nearestTarget[2];
				var wrapH:int = (insertionType == INSERT_WRAP) ? t.getRect(t).height : 0;
				var isInsertion:Boolean = (insertionType != INSERT_ABOVE) && (insertionType != INSERT_WRAP);
				feedbackShape.copyFeedbackShapeFrom(b, false, isInsertion, wrapH);
			}
		}

		if (mouseX + x >= 0) {
			nearestTarget = nearestTargetForBlockIn(b, possibleTargets);
			if (nearestTarget != null) {
				updateFeedbackShape();
			} else {
				hideFeedbackShape();
			}
			if (b.base.canHaveSubstack1() && !b.subStack1) {
				updateHeight();
			}
		}
		else {
			nearestTarget = null;
			hideFeedbackShape();
		}

		fixCommentLayout();
	}

	public function allStacks():Array {
		var result:Array = [];
		for (var i:int = 0; i < numChildren; i++) {
			var child:DisplayObject = getChildAt(i);
			if (child is Block) result.push(child);
		}
		return result;
	}

	private function blockDropped(b:Block):void {
		if (nearestTarget == null) {
			b.cacheAsBitmap = true;
		} else {
			if(app.editMode) b.hideRunFeedback();
			b.cacheAsBitmap = false;
			if (b.isReporter) {
				Block(nearestTarget[1].parent).replaceArgWithBlock(nearestTarget[1], b, this);
			} else {
				var targetCmd:Block = nearestTarget[1];
				switch (nearestTarget[2]) {
				case INSERT_NORMAL:
					targetCmd.insertBlock(b);
					break;
				case INSERT_ABOVE:
					targetCmd.insertBlockAbove(b);
					break;
				case INSERT_SUB1:
					targetCmd.insertBlockSub1(b);
					break;
				case INSERT_SUB2:
					targetCmd.insertBlockSub2(b);
					break;
				case INSERT_WRAP:
					targetCmd.insertBlockAround(b);
					break;
				}
			}
		}
		if (b.op == Specs.PROCEDURE_DEF) app.updatePalette();
		app.runtime.blockDropped(b);
	}

	public function findTargetsFor(b:Block):void {
		possibleTargets = [];
		var bEndWithTerminal:Boolean = b.bottomBlock().isTerminal;
		var bCanWrap:Boolean = b.base.canHaveSubstack1() && !b.subStack1; // empty C or E block
		var p:Point;
		for (var i:int = 0; i < numChildren; i++) {
			var child:DisplayObject = getChildAt(i);
			if (child is Block) {
				var target:Block = Block(child);
				if (b.isReporter) {
					if (reporterAllowedInStack(b, target)) findReporterTargetsIn(target);
				} else {
					if (!target.isReporter) {
						if (!bEndWithTerminal && !target.isHat) {
							// b is a stack ending with a non-terminal command block and target
							// is not a hat so the bottom block of b can connect to top of target
							p = target.localToGlobal(new Point(0, -(b.height - BlockShape.NotchDepth)));
							possibleTargets.push([p, target, INSERT_ABOVE]);
						}
						if (bCanWrap && !target.isHat) {
							p = target.localToGlobal(new Point(-BlockShape.SubstackInset, -(b.base.substack1y() - BlockShape.NotchDepth)));
							possibleTargets.push([p, target, INSERT_WRAP]);
						}
						if (!b.isHat) findCommandTargetsIn(target, bEndWithTerminal && !bCanWrap);
					}
				}
			}
		}
	}

	private function reporterAllowedInStack(r:Block, stack:Block):Boolean {
		// True if the given reporter block can be inserted in the given stack.
		// Procedure parameter reporters can only be added to a block definition
		// that defines parameter.
return true; // xxx disable this check for now; it was causing confusion at Scratch@MIT conference
		if (r.op != Specs.GET_PARAM) return true;
		var top:Block = stack.topBlock();
		return (top.op == Specs.PROCEDURE_DEF) && (top.parameterNames.indexOf(r.spec) > -1);
	}

	private function findCommandTargetsIn(stack:Block, endsWithTerminal:Boolean):void {
		var target:Block = stack;
		while (target != null) {
			var p:Point = target.localToGlobal(new Point(0, 0));
			if (!target.isTerminal && (!endsWithTerminal || target.nextBlock == null)) {
				// insert stack after target block:
				// target block must not be a terminal
				// if stack does not end with a terminal, it can be inserted between blocks
				// otherwise, it can only inserted after the final block of the substack
				p = target.localToGlobal(new Point(0, target.base.nextBlockY() - 3));
				possibleTargets.push([p, target, INSERT_NORMAL]);
			}
			if (target.base.canHaveSubstack1() && (!endsWithTerminal || target.subStack1 == null)) {
				p = target.localToGlobal(new Point(15, target.base.substack1y()));
				possibleTargets.push([p, target, INSERT_SUB1]);
			}
			if (target.base.canHaveSubstack2() && (!endsWithTerminal || target.subStack2 == null)) {
				p = target.localToGlobal(new Point(15, target.base.substack2y()));
				possibleTargets.push([p, target, INSERT_SUB2]);
			}
			if (target.subStack1 != null) findCommandTargetsIn(target.subStack1, endsWithTerminal);
			if (target.subStack2 != null) findCommandTargetsIn(target.subStack2, endsWithTerminal);
			target = target.nextBlock;
		}
	}

	private function findReporterTargetsIn(stack:Block):void {
		var b:Block = stack, i:int;
		while (b != null) {
			for (i = 0; i < b.args.length; i++) {
				var o:DisplayObject = b.args[i];
				if ((o is Block) || (o is BlockArg)) {
					var p:Point = o.localToGlobal(new Point(0, 0));
					possibleTargets.push([p, o, INSERT_NORMAL]);
					if (o is Block) findReporterTargetsIn(Block(o));
				}
			}
			if (b.subStack1 != null) findReporterTargetsIn(b.subStack1);
			if (b.subStack2 != null) findReporterTargetsIn(b.subStack2);
			b = b.nextBlock;
		}
	}

	private function addFeedbackShape():void {
		if (feedbackShape == null) feedbackShape = new BlockShape();
		feedbackShape.setWidthAndTopHeight(10, 10);
		hideFeedbackShape();
		addChild(feedbackShape);
	}

	private function hideFeedbackShape():void {
		feedbackShape.visible = false;
	}

	private function nearestTargetForBlockIn(b:Block, targets:Array):Array {
		var threshold:int = b.isReporter ? 15 : 30;
		var i:int, minDist:int = 100000;
		var nearest:Array;
		var bTopLeft:Point = new Point(b.x, b.y);
		var bBottomLeft:Point = new Point(b.x, b.y + b.height - 3);

		for (i = 0; i < targets.length; i++) {
			var item:Array = targets[i];
			var diff:Point = bTopLeft.subtract(item[0]);
			var dist:Number = Math.abs(diff.x / 2) + Math.abs(diff.y);
			if ((dist < minDist) && (dist < threshold) && dropCompatible(b, item[1])) {
				minDist = dist;
				nearest = item;
			}
		}
		return (minDist < threshold) ? nearest : null;
	}

	private function dropCompatible(droppedBlock:Block, target:DisplayObject):Boolean {
		const menusThatAcceptReporters:Array = [
			'broadcast', 'costume', 'backdrop', 'scene', 'sound',
			'spriteOnly', 'spriteOrMouse', 'spriteOrStage', 'touching'];
		if (!droppedBlock.isReporter) return true; // dropping a command block
		if (target is Block) {
			if (Block(target).isEmbeddedInProcHat()) return false;
			if (Block(target).isEmbeddedParameter()) return false;
		}
		var dropType:String = droppedBlock.type;
		var targetType:String = target is Block ? Block(target.parent).argType(target).slice(1) : BlockArg(target).type;
		if (targetType == 'm') {
			if (Block(target.parent).type == 'h') return false;
			return menusThatAcceptReporters.indexOf(BlockArg(target).menuName) > -1;
		}
		if (targetType == 'b') return dropType == 'b';
		return true;
	}

	/* Dropping */

	public function handleDrop(obj:*):Boolean {
		var localP:Point = globalToLocal(new Point(obj.x, obj.y));

		var info:MediaInfo = obj as MediaInfo;
		if (info) {
			if (!info.scripts) return false;
			localP.x += info.thumbnailX();
			localP.y += info.thumbnailY();
			addStacksFromBackpack(info, localP);
			return true;
		}

		var b:Block = obj as Block;
		var c:ScratchComment = obj as ScratchComment;
		if (!b && !c) return false;

		obj.x = Math.max(5, localP.x);
		obj.y = Math.max(5, localP.y);
		obj.scaleX = obj.scaleY = 1;
		addChild(obj);
		if (b) blockDropped(b);
		if (c) {
			c.blockRef = blockAtPoint(localP); // link to the block under comment top-left corner, or unlink if none
		}
		saveScripts();
		updateSize();
		if (c) fixCommentLayout();
		return true;
	}

	private function addStacksFromBackpack(info:MediaInfo, dropP:Point):void {
		if (!info.scripts) return;
		var forStage:Boolean = app.viewedObj() && app.viewedObj().isStage;
		for each (var a:Array in info.scripts) {
			if (a.length < 1) continue;
			var blockOrComment:* =
				(a[0] is Array) ?
					BlockIO.arrayToStack(a, forStage) :
					ScratchComment.fromArray(a);
			blockOrComment.x = dropP.x;
			blockOrComment.y = dropP.y;
			addChild(blockOrComment);
			if (blockOrComment is Block) blockDropped(blockOrComment);
		}
		saveScripts();
		updateSize();
		fixCommentLayout();
	}

	private function blockAtPoint(p:Point):Block {
		// Return the block at the given point (local) or null.
		var result:Block;
		for each (var stack:Block in allStacks()) {
			stack.allBlocksDo(function(b:Block):void {
				if (!b.isReporter) {
					var r:Rectangle = b.getBounds(parent);
					if (r.containsPoint(p) && ((p.y - r.y) < b.base.substack1y())) result = b;
				}
			});
		}
		return result;
	}

	/* Menu */

	public function menu(evt:MouseEvent):Menu {
		var x:Number = mouseX;
		var y:Number = mouseY;
		function newComment():void { addComment(null, x, y) }
		var m:Menu = new Menu();
		m.addItem('clean up', cleanUp);
		m.addItem('add comment', newComment);
		return m;
	}

	public function setScale(newScale:Number):void {
		x *= newScale / scaleX;
		y *= newScale / scaleY;
		newScale = Math.max(1/6, Math.min(newScale, 6.0));
		scaleX = scaleY = newScale;
		updateSize();
	}

	/* Comment Support */

	public function addComment(b:Block = null, x:Number = 50, y:Number = 50):void {
		var c:ScratchComment = new ScratchComment();
		c.blockRef = b;
		c.x = x;
		c.y = y;
		addChild(c);
		saveScripts();
		updateSize();
		c.startEditText();
	}

	public function fixCommentLayout():void {
		const commentLineColor:int = 0xFFFF80;
		var g:Graphics = commentLines.graphics;
		g.clear();
		g.lineStyle(2, commentLineColor);
		for (var i:int = 0; i < numChildren; i++) {
			var c:ScratchComment = getChildAt(i) as ScratchComment;
			if (c && c.blockRef) updateCommentConnection(c, g);
		}
	}

	private function updateCommentConnection(c:ScratchComment, g:Graphics):void {
		// Update the position of the given comment based on the position of the
		// block it references and update the line connecting it to that block.
		if (!c.blockRef) return;

		// update comment position
		var blockP:Point = globalToLocal(c.blockRef.localToGlobal(new Point(0, 0)));
		var top:Block = c.blockRef.topBlock();
		var topP:Point = globalToLocal(top.localToGlobal(new Point(0, 0)));
		c.x = c.isExpanded() ?
			topP.x + top.width + 15 :
			blockP.x + c.blockRef.base.width + 10;
		c.y = blockP.y + (c.blockRef.base.substack1y() - 20) / 2;
		if (c.blockRef.isHat) c.y = blockP.y + c.blockRef.base.substack1y() - 25;

		// draw connecting line
		var lineY:int = c.y + 10;
		g.moveTo(blockP.x + c.blockRef.base.width, lineY);
		g.lineTo(c.x, lineY);
	}

	/* Stack cleanup */

	private function cleanUp():void {
		// Clean up the layout of stacks and blocks in the scripts pane.
		// Steps:
		//	1. Collect stacks and sort by x
		//	2. Assign stacks to columns such that the y-ranges of all stacks in a column do not overlap
		//	3. Compute the column widths
		//	4. Move stacks into place

		var stacks:Array = stacksSortedByX();
		var columns:Array = assignStacksToColumns(stacks);
		var columnWidths:Array = computeColumnWidths(columns);

		var nextX:int = padding;
		for (var i:int = 0; i < columns.length; i++) {
			var col:Array = columns[i];
			var nextY:int = padding;
			for each (var b:Block in col) {
				b.x = nextX;
				b.y = nextY;
				nextY += b.height + padding;
			}
			nextX += columnWidths[i] + padding;
		}
		saveScripts();
	}

	private function stacksSortedByX():Array {
		// Get all stacks and sorted by x.
		var stacks:Array = [];
		for (var i:int = 0; i < numChildren; i++) {
			var o:* = getChildAt(i);
			if (o is Block) stacks.push(o);
		}
		stacks.sort(function (b1:Block, b2:Block):int {return b1.x - b2.x }); // sort by increasing x
		return stacks;
	}

	private function assignStacksToColumns(stacks:Array):Array {
		// Assign stacks to columns. Assume stacks is sorted by increasing x.
		// A stack is placed in the first column where it does not overlap vertically with
		// another stack in that column. New columns are created as needed.
		var columns:Array = [];
		for each (var b:Block in stacks) {
			var assigned:Boolean = false;
			for each (var c:Array in columns) {
				if (fitsInColumn(b, c)) {
					assigned = true;
					c.push(b);
					break;
				}
			}
			if (!assigned) columns.push([b]); // create a new column for this stack
		}
		return columns;
	}

	private function fitsInColumn(b:Block, c:Array):Boolean {
		var bTop:int = b.y;
		var bBottom:int = bTop + b.height;
		for each (var other:Block in c) {
			if (!((other.y > bBottom) || ((other.y + other.height) < bTop))) return false;
		}
		return true;
	}

	private function computeColumnWidths(columns:Array):Array {
		var widths:Array = [];
		for each (var c:Array in columns) {
			c.sort(function (b1:Block, b2:Block):int {return b1.y - b2.y }); // sort by increasing y
			var w:int = 0;
			for each (var b:Block in c) w = Math.max(w, b.width);
			widths.push(w);
		}
		return widths;
	}

    /* stack ordering for highlighting */
    // bit messy at the mo - gotta be a better way...

    private function leftmostBlockObjPos(blkobjs:Array):int {
        var result:Object=blkobjs[0];
        var pos:int = 0;
        var leftPos:int = 0;
        // find index of block with minimum X position
        for each (var obj:Object in blkobjs) {
            if (obj.x<result.x) {
                result = obj;
                leftPos = pos;
            }
            pos++;
        }
        return leftPos;
    }

    private function stackYOrderedBlockObjs(blkobjs:Array):Array {
        // not exactly the most elegant sorting algorithm ever written... :/
        var result:Array=[];
        if (blkobjs.length>0) {
            var maxObj:Object = blkobjs[0];
            var minObj:Object = maxObj;
            // find min & max Y positions for parent stacks of the blocks
            for each (var blkobj:Object in blkobjs) {
                if (blkobj.stack.y>maxObj.stack.y) maxObj = blkobj;
                else if (blkobj.stack.y<minObj.stack.y) minObj = blkobj;
            }
            // add all blocks with same minimum Y for their stack
            for each (blkobj in blkobjs) {
                if (blkobj.stack.y==minObj.stack.y) result.push(blkobj.block);
            }
            // keep doing above until all blocks included
            while (result.length<blkobjs.length) {
                // this limit to prevents taking blocks that have already been included
                var topObj:Object = maxObj;
                for each (blkobj in blkobjs) {
                    if (blkobj.stack.y<topObj.stack.y && blkobj.stack.y>minObj.stack.y) topObj = blkobj;
                }
                minObj = topObj;
                for each (blkobj in blkobjs) {
                    if (blkobj.stack.y==minObj.stack.y) result.push(blkobj.block);
                }
            }
            
        }
        return result;
    }

    public function orderBlocks(blocks:Array):Array {
        var result:Array = [];
        var remaining:Array = [];
        for each (var blk:Block in blocks) {
            // this is a 'block object' which contains info about a highlighted
            // block in a form we can use for the sorting in terms of stacks
            var obj:Object = {};
            obj.x = blk.x;    // will contain x pos of block in scripts pane
            obj.y = blk.y;    // will contain y pos of block in scripts pane
            obj.block = blk;  // reference to current block
            while (blk.parent is Block) {
                blk = blk.parent as Block;
                obj.x += blk.x;
                obj.y += blk.y;
            }
            obj.stack = blk;  // reference to top-of-stack block
            remaining.push(obj);
        }
        while (remaining.length>0) {
            var objsToAdd:Array = [];
            var leftPos:int = leftmostBlockObjPos(remaining);
            var pos:int = 0;
            var leftObj:Object = remaining[leftPos];
            var cutoff:Number = leftObj.x+Math.min(400,leftObj.block.base.width)+100; // fairly arbitrary cutoff...
            var sameStack:Block = remaining[pos].stack;
            // go back to first block in same stack
            while (leftPos>0 && remaining[leftPos-1].stack==sameStack) leftPos--;
            // go through blocks in same stack, looking for rightmost cutoff
            while (leftPos<remaining.length && remaining[leftPos].stack==sameStack) {
                leftObj = remaining[leftPos];
                cutoff = Math.max(cutoff,leftObj.x+Math.min(400,leftObj.block.base.width)+100);
                leftPos++;
            }
            while (pos<remaining.length) {
                if (remaining[pos].x<cutoff) {
                    // go back to first block in same stack
                    sameStack = remaining[pos].stack;
                    while (pos>0 && remaining[pos-1].stack==sameStack) pos--;
                    // add more blocks in the same stack
                    while (pos<remaining.length && remaining[pos].stack==sameStack) {
                        objsToAdd.push(remaining[pos]);
                        remaining.splice(pos,1);
                    }
                } else {
                    pos++;
                }
            }
            result = result.concat(stackYOrderedBlockObjs(objsToAdd));
        }
        return result;
    }

	/* jumping to a block in scripts pane */

    public function jumpToBlock(b:Block):void {
		var sf:ScrollFrame = this.parent as ScrollFrame;
		if (!b || !sf) return;
		var stack:Block = b;
		var boffx:Number = b.x;
		var boffy:Number = b.y;
		while (stack.parent is Block) {
			stack = stack.parent as Block;
			boffx += stack.x;
			boffy += stack.y;
		}
		if (stack.parent as ScriptsPane != this) return;
        var vw:Number = Math.max(40,sf.visibleW()-25);
		var vh:Number = Math.max(70,sf.visibleH()-35);
		// take into account if block is wider/longer than (half of) viewport
        var bw:Number = Math.min(b.base.width*scaleX,vw*0.5);
        var bh:Number = Math.min(b.base.height*scaleY,vh*0.5);
        // offset for block itself
		boffx = boffx*scaleX + x - 5;
		boffy = boffy*scaleY + y - 5;
        // offset for start of stack containing block
        var soffx:Number = stack.x*scaleX + x - 6; // why does it need one extra?
		var soffy:Number = stack.y*scaleY + y - 5;
		// want to move so start of stack is visible, unless that means block is off bottom/right
		var bx:Number = (boffx-soffx<0.65*vw) ? soffx : boffx-0.65*vw;
		var by:Number = (boffy-soffy<0.75*vh) ? soffy : boffy-0.75*vh;
        vw -= bw;
        vh -= bh;
        if (boffx>-250 && boffy>-200 && boffx<vw+250 && boffy<vh+200) {
            // don't move view at all if block is already within script pane...
            if (boffx>0 && boffy>0 && boffx<vw && boffy<vh ) return;
            // ...but if it's not far outside view then move just enough to see it
            bx = boffx>vw ? boffx-vw+5 : boffx<0 ? boffx-5 : 0;
            by = boffy>vh ? boffy-vh+5 : boffy<0 ? boffy-5 : 0;
        }
		if (bx!=0 || by!=0) {
			x -= bx;
			y -= by;
			sf.constrainScroll();
			sf.updateScrollbars();
		}
	}

	/* Block highlighting */

	private static var highlightBlocks:Array = [];
	private static var highlightBlock:Block = null;

	private function firstHighlightBlockInObj(o:ScratchObj):Block {
		for each (var b:Block in highlightBlocks) {
			if (b.getOwnerObj()==o) return b;
		}
		return null;
	}

	private function newHighlightState(doJump:Boolean=true):void {
		var sp:ScriptsPart = this.parent.parent as ScriptsPart;
		if (!sp) return;  // never happens?
		if (!highlightBlock) {
			sp.hideHighlightWidget();
		} else {
			if (doJump) {
				jumpToBlock(highlightBlock);
				app.runtime.startBlinkingHighlight(highlightBlock);
			}
			sp.showHighlightWidget();
		}
	}

	private function checkHighlightState(doJump:Boolean=true):void {
		if (!highlightBlock || highlightBlock.getOwnerObj()!=app.viewedObj()) {
			highlightBlock = firstHighlightBlockInObj(app.viewedObj());
		}
		newHighlightState(doJump);
	}

	public function showBlockHighlights(blocklist:Array,curBlk:Block=null,clearOld:Boolean=true):void {
		if (clearOld) clearBlockHighlights(false);
		if (blocklist.length>0) {
			for each( var b:Block in blocklist) b.showBlockHighlight();
		}
		highlightBlocks = blocklist.concat(highlightBlocks);
		if (curBlk && curBlk.getOwnerObj()==app.viewedObj() && highlightBlocks.indexOf(curBlk)>-1) {
			highlightBlock = curBlk;
			newHighlightState(false);  // scriptspane doesn't need to jump to block
		} else {
			highlightBlock = firstHighlightBlockInObj(app.viewedObj());
			newHighlightState();
		}
	}

	public function clearBlockHighlights(setState:Boolean=true):void {
		app.runtime.clearBlinkingHighlight();
		for each (var o:ScratchObj in app.stagePane.allObjects()) {
			if (!o.isClone) {
				for each (var stack:Block in o.scripts) {
					stack.allBlocksDo(function (b:Block):void {
						b.hideBlockHighlight();
					});
				}
			}
		}
		highlightBlocks = [];
		highlightBlock = null;
		if (setState) newHighlightState();
	}

	public function prevHighlightBlock(curBlk:Block):void {
		if (highlightBlocks.length<1) return;
		if (!curBlk) curBlk = highlightBlock;
		if (!curBlk || curBlk.getOwnerObj()!=app.viewedObj()) {
			highlightBlock = firstHighlightBlockInObj(app.viewedObj());
		} else {
			var pos:int = highlightBlocks.indexOf(curBlk);
			if (pos<0) return;
			var o:ScratchObj = curBlk.getOwnerObj();
			if (!o) return;
			pos--;
			if (pos<0) pos += highlightBlocks.length;
			while (highlightBlocks[pos].getOwnerObj()!=o) {
				pos--;
				if (pos<0) pos += highlightBlocks.length;
			}
			highlightBlock = highlightBlocks[pos];
		}
		newHighlightState()
	}

	public function nextHighlightBlock(curBlk:Block):void {
		if (highlightBlocks.length<1) return;
		if (!curBlk) curBlk = highlightBlock;
		if (!curBlk || curBlk.getOwnerObj()!=app.viewedObj()) {
			highlightBlock = firstHighlightBlockInObj(app.viewedObj());
		} else {
			var pos:int = highlightBlocks.indexOf(curBlk);
			if (pos<0) return;
			var o:ScratchObj = curBlk.getOwnerObj();
			if (!o) return;
			pos = (pos+1) % highlightBlocks.length;
			while (highlightBlocks[pos].getOwnerObj()!=o) {
				pos = (pos+1) % highlightBlocks.length;
			}
			highlightBlock = highlightBlocks[pos];
		}
		newHighlightState()
	}

}}
