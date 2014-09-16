/**
 * Created by shanemc on 9/12/14.
 */
package util {
import flash.display.DisplayObject;
import flash.events.Event;
import ui.DropTarget;

public class DragEvent extends Event {
	public static const DRAG_START:String   = 'dragStart';
	public static const DRAG_STOP:String    = 'dragStop';
	public static const DRAG_OVER:String    = 'dragOver';
	public static const DRAG_MOVE:String    = 'dragMove';
	public static const DRAG_OUT:String     = 'dragOut';
	public static const DRAG_DROP:String     = 'dragDrop';
	private var _draggedObj:DisplayObject;
	private var _acceptedBy:DropTarget;
	public function DragEvent(type:String, obj:DisplayObject) {
		_draggedObj = obj;
		super(type, true, true);

		// DragEvents won't propagate and are only dispatched on DropTargets
		stopPropagation();
	}

	public function get draggedObject():DisplayObject {
		return _draggedObj;
	}

	public function dropAcceptedBy():DropTarget {
		return _acceptedBy;
	}

	public function acceptDrop():void {
		_acceptedBy = currentTarget as DropTarget;
		stopImmediatePropagation();
	}
}
}
