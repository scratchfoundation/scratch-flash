/**
 * Created by shanemc on 4/27/15.
 */
package ui {
import flash.display.DisplayObjectContainer;
import flash.events.IEventDispatcher;

public interface IDisplayObject extends IEventDispatcher{
	function get parent():flash.display.DisplayObjectContainer;
	function get visible():Boolean;
	function set visible(value:Boolean):void;
	function get x():Number;
	function set x(value:Number):void;
	function get y():Number;
	function set y(value:Number):void;
	function get scaleX():Number;
	function set scaleX(value:Number):void;
	function get scaleY():Number;
	function set scaleY(value:Number):void;
	function get alpha():Number;
	function set alpha(value:Number):void;
	function get width():Number;
	function set width(value:Number):void;
	function get height():Number;
	function set height(value:Number):void;
}
}
