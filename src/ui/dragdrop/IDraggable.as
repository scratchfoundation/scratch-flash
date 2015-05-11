/**
 * Created by shanemc on 12/9/14.
 */
package ui.dragdrop {
import flash.display.Sprite;
import ui.IDisplayObject;

public interface IDraggable extends IDisplayObject {
	function getSpriteToDrag():Sprite;
}}
