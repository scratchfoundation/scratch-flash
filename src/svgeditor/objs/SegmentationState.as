/**
 * Created by Mallory on 10/22/15.
 */
package svgeditor.objs {
import flash.display.BitmapData;
import flash.utils.ByteArray;

import svgeditor.ImageEdit;

public class SegmentationState {

	public var isGreyscale:Boolean;
	public var mode:String;
	public var scribbleBitmap:BitmapData;
	public var lastMask:ByteArray;
	public var xMin:int;
	public var yMin:int;
	public var xMax:int;
	public var yMax:int;

	public function SegmentationState() {
        reset();
	}

	public function reset():void{
		isGreyscale = false;
		mode = 'object';
		scribbleBitmap = null;
		lastMask = null;
        xMin = -1;
        yMin = -1;
        xMax = 0;
        yMax = 0;
	}

}
}
