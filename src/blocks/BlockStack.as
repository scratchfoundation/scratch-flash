/**
 * Created by shanemc on 7/15/15.
 */
package blocks {
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.Sprite;
import flash.filters.GlowFilter;
import flash.geom.Point;

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
		x = b.x;
		y = b.y;
		b.x = b.y = 0;
		addChild(b);

		firstBlock = b;
		var nextBlock:Block = b.nextBlock;
		while (nextBlock) {
			addChild(nextBlock);
			nextBlock = nextBlock.nextBlock;
		}
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

	public function saveOriginalState():void {
		originalParent = parent;
		if (parent) {
			var b:Block = parent as Block;
			if (b == null) {
				originalRole = ROLE_ABSOLUTE;
			} else if (firstBlock.isReporter) {
				originalRole = ROLE_EMBEDDED;
				originalIndex = b.args.indexOf(this);
			} else if (b.nextBlock == firstBlock) {
				originalRole = ROLE_NEXT;
			} else if (b.subStack1 == firstBlock) {
				originalRole = ROLE_SUBSTACK1;
			} else if (b.subStack2 == firstBlock) {
				originalRole = ROLE_SUBSTACK2;
			}
			originalPosition = localToGlobal(new Point(0, 0));
		} else {
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
