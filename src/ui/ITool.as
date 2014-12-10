/**
 * Created by shanemc on 12/8/14.
 */
package ui {
import flash.display.Stage;
import flash.events.MouseEvent;

public interface ITool {
	function shutdown():void;
	function mouseHandler(e:MouseEvent):void;
	function isSticky():Boolean;
}}
