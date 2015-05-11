/**
 * Created by shanemc on 4/28/15.
 */
package ui.events {
import flash.events.MouseEvent;

public class PointerEvent extends MouseEvent {
	public static const LONG_HOLD_DURATION:uint = 500;
	public static const TAP:String = 'pointerTap';
	public static const DOUBLE_TAP:String = 'pointerDoubleTap';
	public function PointerEvent(type:String, localX:Number = 0, localY:Number = 0) {
		super(type, true, false, localX, localY);
	}
}
}
