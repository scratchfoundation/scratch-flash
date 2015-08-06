/**
 * Created by shanemc on 7/15/15.
 */
package blocks {
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.Sprite;
import flash.events.Event;
import flash.filters.GlowFilter;
import flash.geom.Point;

import uiwidgets.ScriptsPane;

public class BlockStack extends Sprite {
	public var firstBlock:Block;

	private static var ROLE_NONE:int = 0;
	private static var ROLE_ABSOLUTE:int = 1;
	private static var ROLE_EMBEDDED:int = 2;
	private static var ROLE_NEXT:int = 3;
	private static var ROLE_SUBSTACK1:int = 4;
	private static var ROLE_SUBSTACK2:int = 5;

	private var originalParent:DisplayObjectContainer, originalRole:int, originalIndex:int, originalPosition:Point;

	public function BlockStack(b:Block) {
		var pb:Block = b.prevBlock || b.parent as Block;
		if (pb) {
			saveOriginalState(b);
			pb.removeBlock(b);
			b.prevBlock = null;
		}
		addChild(b);
		setFirstBlock(b);
		if (pb)
			pb.topBlock().fixStackLayout();

		addEventListener(Event.REMOVED, handleRemove);
		cacheAsBitmap = true;
	}

	public function setFirstBlock(b:Block):void {
		if (firstBlock)
			while (numChildren) removeChildAt(0);

		firstBlock = b;
		if (b.x || b.y) {
			x += b.x;
			y += b.y;
			b.x = 0;
			b.y = 0;
		}
		addBlocks(b);
	}

	private function addBlocks(b:Block):void {
		while (b) {
			addChild(b);
			addBlocks(b.subStack1);
			addBlocks(b.subStack2);
			b = b.nextBlock;
		}
	}

	public function removeBlocks(b:Block):void {
		while (b) {
			if (b.parent == this) removeChild(b);
			removeBlocks(b.subStack1);
			removeBlocks(b.subStack2);
			b = b.nextBlock;
		}
	}

	private function handleRemove(e:Event):void {
		if (e.target == firstBlock)
			firstBlock = null;
	}

	public function objToGrab(e:Event):* {
		return this;
	}

	public function allBlocksDo(f:Function):void {
		firstBlock.allBlocksDo(f);
	}

	public function showRunFeedback():void {
		if (filters && filters.length > 0) {
			for each (var f:* in filters) {
				if (f is GlowFilter) return;
			}
		}
		filters = runFeedbackFilters().concat(filters || []);
	}

	public function hideRunFeedback():void {
		if (filters && filters.length > 0) {
			var newFilters:Array = [];
			for each (var f:* in filters) {
				if (!(f is GlowFilter)) newFilters.push(f);
			}
			filters = newFilters;
		}
	}

	private function runFeedbackFilters():Array {
		// filters for showing that a stack is running
		var f:GlowFilter = new GlowFilter(0xfeffa0);
		f.strength = 2;
		f.blurX = f.blurY = 12;
		f.quality = 3;
		return [f];
	}

	public function saveOriginalState(b:Block = null):void {
		if (b) {
			originalParent = b.parent as Block || b.prevBlock || parent;
			var p:Block = b.parent as Block;
			var pb:Block = b.prevBlock as Block;
			if (p && b.isReporter) {
				originalRole = ROLE_EMBEDDED;
				originalIndex = p.args.indexOf(b);
			}
			else if (pb) {
				if (pb.nextBlock == b) {
					originalRole = ROLE_NEXT;
				}
				else if (pb.subStack1 == b) {
					originalRole = ROLE_SUBSTACK1;
				}
				else if (pb.subStack2 == b) {
					originalRole = ROLE_SUBSTACK2;
				}
			}
			originalPosition = b.localToGlobal(new Point(0, 0));
		}
		else if (parent is ScriptsPane) {
			originalRole = ROLE_ABSOLUTE;
			originalPosition = localToGlobal(new Point(0, 0));
			originalParent = parent;
		}
		else {
			originalRole = ROLE_NONE;
			originalPosition = null;
		}
	}

	public function restoreOriginalState():void {
		var b:Block = originalParent as Block;
		scaleX = scaleY = 1;
		switch (originalRole) {
			case ROLE_NONE:
				if (parent) parent.removeChild(this);
				break;
			case ROLE_ABSOLUTE:
				originalParent.addChild(this);
				var p:Point = originalParent.globalToLocal(originalPosition);
				x = p.x;
				y = p.y;
				break;
			case ROLE_EMBEDDED:
				b.replaceArgWithBlock(b.args[originalIndex], firstBlock, Scratch.app.scriptsPane);
				break;
			case ROLE_NEXT:
				b.insertBlock(firstBlock);
				break;
			case ROLE_SUBSTACK1:
				b.insertBlockSub1(firstBlock);
				break;
			case ROLE_SUBSTACK2:
				b.insertBlockSub2(firstBlock);
				break;
		}
	}

	public function originalPositionIn(p:DisplayObject):Point {
		return originalPosition && p.globalToLocal(originalPosition);
	}
}
}
