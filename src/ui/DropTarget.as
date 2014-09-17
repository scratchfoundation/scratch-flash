/**
 * Created by shanemc on 9/15/14.
 */
package ui {
import flash.events.IEventDispatcher;

public interface DropTarget extends IEventDispatcher{
	function handleDrop(obj:*):uint;
}}
