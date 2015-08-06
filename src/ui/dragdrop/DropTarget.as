/**
 * Created by shanemc on 9/15/14.
 */
package ui.dragdrop {
import flash.events.IEventDispatcher;

public interface DropTarget extends IEventDispatcher{
	function handleDrop(obj:Object):Boolean;
	//function isCompatible(obj:Object):Boolean;
}}
