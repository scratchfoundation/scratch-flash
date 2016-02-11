/**
 * Created by Mallory on 10/22/15.
 */
package svgeditor.objs {
import flash.display.BitmapData;
import flash.geom.Rectangle;

import svgeditor.BitmapEdit;

public class SegmentationState {
	public var scribbleBitmap:BitmapData;
	public var unmarkedBitmap:BitmapData;
	public var costumeRect:Rectangle;
	public var lastMask:BitmapData;

	public var next:SegmentationState = null;
	public var prev:SegmentationState = null;

	public var xMin:int;
	public var yMin:int;
	public var xMax:int;
	public var yMax:int;

	public function SegmentationState() {
		reset();
	}

	public function clone():SegmentationState{
		var clone:SegmentationState = new SegmentationState();
		//Scribble, mask, and bounding rect must be cloned as a snapshot of the current state.
		//We can get away with storing a reference to unmarked bitmap and only updating
		//on mask commits
		if(scribbleBitmap)
			clone.scribbleBitmap = scribbleBitmap.clone();
		if(unmarkedBitmap)
			clone.unmarkedBitmap = unmarkedBitmap;
		if(costumeRect)
			clone.costumeRect = costumeRect.clone();
		if(lastMask)
			clone.lastMask = lastMask.clone();
		clone.next = next;
		clone.prev = prev;
		clone.xMax = xMax;
		clone.xMin = xMin;
		clone.yMax = yMax;
		clone.yMin = yMin;
		return clone
	}

	public function recordForUndo():void{
		next = clone();
		next.next = null;
		next.prev = this;
	}

	public function canUndo():Boolean{
		return prev != null;
	}

	public function canRedo():Boolean{
		return next != null;
	}

	public function reset():void{
		scribbleBitmap = null;
		lastMask = null;
		next = null;
        xMin = -1;
        yMin = -1;
        xMax = 0;
        yMax = 0;
	}

	public function eraseUndoHistory():void{
		prev = next = null;
	}

	public function flip(vertical:Boolean):void{
		scribbleBitmap = BitmapEdit.flipBitmap(vertical, scribbleBitmap);
		lastMask = BitmapEdit.flipBitmap(vertical, lastMask);
		unmarkedBitmap = BitmapEdit.flipBitmap(vertical, unmarkedBitmap);
		costumeRect.x = unmarkedBitmap.width - costumeRect.x - costumeRect.width;
		costumeRect.y = unmarkedBitmap.height - costumeRect.y - costumeRect.height;
	}
}
}
