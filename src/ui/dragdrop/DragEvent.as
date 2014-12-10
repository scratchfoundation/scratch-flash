/**
 * Created by shanemc on 9/12/14.
 */
package ui.dragdrop {
import flash.display.Sprite;
import flash.events.Event;

public class DragEvent extends Event {
	public static const DRAG_START:String   = 'dragStart';
	public static const DRAG_STOP:String    = 'dragStop';
	public static const DRAG_CANCEL:String  = 'dragCancel';
	public static const DRAG_OVER:String    = 'dragOver';
	public static const DRAG_MOVE:String    = 'dragMove';
	public static const DRAG_OUT:String     = 'dragOut';
	public static const DRAG_DROP:String    = 'dragDrop';
	private var _draggedObj:Sprite;
	private var _acceptedBy:DropTarget;
	private var _prevented:Boolean;
	public function DragEvent(type:String, obj:Sprite) {
		_draggedObj = obj;
		super(type, true, true);

		// DragEvents won't propagate and are only dispatched on DropTargets
		//if (type != DRAG_START) stopPropagation();
	}

	public function get draggedObject():Sprite {
		return _draggedObj;
	}

	public function dropAcceptedBy():DropTarget {
		return _acceptedBy;
	}

	public function acceptDrop():void {
		_acceptedBy = currentTarget as DropTarget;
		stopImmediatePropagation();
	}

	override public function preventDefault():void {
		_prevented = true;
	}

	public function wasPrevented():Boolean {
		return _prevented;
	}
}
}
