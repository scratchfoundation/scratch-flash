/**
 * Created by shanemc on 12/8/14.
 */
package ui {
import ui.events.PointerEvent;

public interface ITool {
	function shutdown():void;
	function mouseHandler(e:PointerEvent):Boolean;
}}
