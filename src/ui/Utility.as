/**
 * Created by shanemc on 4/2/15.
 */
package ui {
import flash.display.DisplayObject;

public class Utility {
	function Utility(){}

	public static function verticallyCenterElements(top:Number, ... elems):Number {
		var maxHeight:Number = 0;
		for(var i:int=0, l:int=elems.length; i<l; ++i) {
			var elem:DisplayObject = elems[i];
			maxHeight = Math.max(elem.height, maxHeight);
		}

		for(i=0, l=elems.length; i<l; ++i) {
			elem = elems[i];
			elem.y = top + (maxHeight - elem.height) * 0.5;
		}

		return top + maxHeight;
	}

	public static function cmToPixels(cm:Number):uint {
		return ScreenDetector.pixelsPerCM * cm;
	}
}
}
