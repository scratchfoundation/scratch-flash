/**
 * Created by shanemc on 12/9/14.
 */
package ui.dragdrop {
import flash.display.Sprite;
import flash.events.IEventDispatcher;

public interface IDraggable extends IEventDispatcher {
	function getSpriteToDrag():Sprite;
}}
