/**
 * Created by Mallory on 10/22/15.
 */
package svgeditor.objs {
import flash.display.BitmapData;
import flash.geom.Point;
import flash.utils.ByteArray;

import svgeditor.ImageEdit;

public class SegmentationState {

	public var mode:String;
	public var scribbleBitmap:BitmapData;
	public var unmarkedBitmap:BitmapData;
	//Similar to a costume's undo stack, elements are [mask:BitmapData, scribble:BitmapData] pairs
	private var maskList:Array;
	private var maskListIndex:int;
	public function get lastMask():BitmapData{
		if(maskListIndex < 0){
			return null;
		}
		return maskList[maskListIndex][0];
	}
	public var xMin:int;
	public var yMin:int;
	public var xMax:int;
	public var yMax:int;
	public var isBlank:Boolean;

	public function SegmentationState() {
        reset();
	}

	public function recordForUndo(mask:BitmapData):void{
		while(maskListIndex < maskList.length - 1){
			maskList.pop();
		}
		maskListIndex = maskList.length;
		maskList.push([mask, scribbleBitmap.clone()]);
	}

	public function canUndo():Boolean{
		return maskListIndex >= 0;
	}

	public function canRedo():Boolean{
		return maskListIndex < maskList.length - 1;
	}

	public function reset():void{
		mode = 'object';
		scribbleBitmap = null;
		maskList = [];
		maskListIndex = -1;
        xMin = -1;
        yMin = -1;
        xMax = 0;
        yMax = 0;
		isBlank = true;
	}

	public function undo():void{
		--maskListIndex;
		if(maskListIndex >= 0){
			var prevScribble:BitmapData = maskList[maskListIndex][1];
			scribbleBitmap.copyPixels(prevScribble, prevScribble.rect,new Point(0,0));
		}
		else{
			scribbleBitmap.fillRect(scribbleBitmap.rect, 0x0);
		}
	}

	public function redo():void{
		++maskListIndex;
		var nextScribble:BitmapData = maskList[maskListIndex][1];
		scribbleBitmap.copyPixels(nextScribble, nextScribble.rect, new Point(0,0));
		}

}
}
