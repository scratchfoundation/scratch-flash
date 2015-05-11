/**
 * Created by shanemc on 9/12/14.
 */
package ui.events {
import ui.dragdrop.*;
import flash.display.Sprite;

public class DragEvent extends PointerEvent {
	public static const DRAG_START:String   = 'dragStart';
	public static const DRAG_STOP:String    = 'dragStop';
	public static const DRAG_CANCEL:String  = 'dragCancel';
	public static const DRAG_OVER:String    = 'dragOver';
	public static const DRAG_MOVE:String    = 'dragMove';
	public static const DRAG_OUT:String     = 'dragOut';
	public static const DRAG_DROP:String    = 'dragDrop';
	private var _draggedObj:Sprite;
	private var _acceptedBy:DropTarget;
	public function DragEvent(type:String, obj:Sprite) {
		_draggedObj = obj;
		super(type, true, true);
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
}}
