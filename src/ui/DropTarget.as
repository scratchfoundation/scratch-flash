/**
 * Created by shanemc on 9/15/14.
 */
package ui {
import flash.events.Event;

public interface DropTarget {
	function handleDrop(obj:*):Boolean;
	function dispatchEvent(event:Event):void;
}
}
