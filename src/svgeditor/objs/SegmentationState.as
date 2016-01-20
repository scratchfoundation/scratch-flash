/**
 * Created by Mallory on 10/22/15.
 */
package svgeditor.objs {
import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.utils.ByteArray;

import svgeditor.ImageEdit;

public class SegmentationState {
	public static var id:int = 0;
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

	public var myID:int;

	public function SegmentationState() {
		myID=id;
		id++;
		reset();
	}

	public function clone():SegmentationState{
		var clone:SegmentationState = new SegmentationState();
		if(scribbleBitmap)
			clone.scribbleBitmap = scribbleBitmap.clone();
		if(unmarkedBitmap)
			clone.unmarkedBitmap = unmarkedBitmap.clone();
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
        xMin = -1;
        yMin = -1;
        xMax = 0;
        yMax = 0;
	}

	public function eraseUndoHistory():void{
		prev = next = null;
	}

}
}
