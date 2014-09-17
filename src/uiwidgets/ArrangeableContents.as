/**
 * Created by shanemc on 9/12/14.
 */
package uiwidgets {
import flash.display.DisplayObject;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Point;
import ui.EditableItem;
import ui.media.MediaInfo;
import util.DragEvent;

public class ArrangeableContents extends ScrollFrameContents {
	public static const TYPE_GRID:uint = 0;
	public static const TYPE_STRIP_HORIZONTAL:uint = 1;
	public static const TYPE_STRIP_VERTICAL:uint = 2;

	// Fixed state variables
	private var type:uint = 0;
	private var itemPadding:uint = 5;

	// Dynamic state variables
	private var w:uint;
	private var h:uint;
	private var selectedItem:EditableItem;
	private var editMode:Boolean;
	public function ArrangeableContents(w:uint, h:uint, t:uint = TYPE_GRID) {
		type = t;
		setWidthHeight(w, h);

		addEventListener(DragEvent.DRAG_DROP, dragAndDropHandler);
		addEventListener(MediaInfoTablet.TOUCH_LONG_HOLD, onLongHold);
	}

	private function onLongHold(e:Event):void {
		setEditMode(true);
	}

	private function setEditMode(enable:Boolean):void {
		if (editMode == enable) return;

		// Enter edit mode
		editMode = enable;
		for (var i:int=0, l:int=numChildren; i<l; ++i) {
			var item:EditableItem = getChildAt(i) as EditableItem;
			if (item) item.toggleEditMode(enable);
		}

		if (editMode)
			stage.addEventListener(MouseEvent.MOUSE_DOWN, cancelEditMode);
		else
			stage.removeEventListener(MouseEvent.MOUSE_DOWN, cancelEditMode);
	}

	private function cancelEditMode(event:Event):void {
		if (getBounds(this).contains(mouseX, mouseY)) {
			var dObj:DisplayObject = event.target as DisplayObject;
			while (dObj != stage && dObj != this) {
				// If we find a MediaInfo in the target's ancestry then don't cancel edit mode
				// since the user may be trying to drag items around
				if (dObj is MediaInfo) return;
				dObj = dObj.parent ? dObj.parent : stage;
			}
		}

		setEditMode(false);
	}

	public function dragAndDropHandler(event:DragEvent):void {

	}

//	public function handleDrop(obj:*):Boolean {
//		if(obj is MediaInfoTablet && getItemIndex(obj as MediaInfoTablet) > -1) {
//			// Determine drop location and adjust the index
//			addChild(obj);
//			return true;
//		}
//
//		return false;
//	}

	// Select an item
	private function onTap(e:Event):void {
		if (editMode || selectedItem == e.target) return;
		if (selectedItem) selectedItem.toggleSelected(false);

		selectedItem = e.target as EditableItem;
		if (selectedItem) selectedItem.toggleSelected(true);
	}

	public function addContent(item:MediaInfo, where:* = null):void {
		if (where is Point) {
			// TODO: Update for other layouts
			var loc:Point = globalToLocal(where as Point);
			var i:int = 0;
			if (type == TYPE_STRIP_HORIZONTAL) {
				for (; i < numChildren; ++i)
					if (getChildAt(i) is MediaInfo && getChildAt(i).x + getChildAt(i).width / 2 > loc.x)
						break;
			}
			else if (type == TYPE_STRIP_VERTICAL) {
				for (; i < numChildren; ++i)
					if (getChildAt(i) is MediaInfo && getChildAt(i).y + getChildAt(i).height / 2 > loc.y)
						break;
			}
			else {
				// TODO: Make this work for grid layouts
				for (; i < numChildren; ++i)
					if (getChildAt(i) is MediaInfo && getChildAt(i).y + getChildAt(i).height / 2 > loc.y)
						break;
			}
			addChildAt(item, i);
		}
		else if (where is Number && where >= 0) addChildAt(item, where as Number);
		else addChild(item);

		if (item is EditableItem) (item as EditableItem).toggleEditMode(editMode);
	}

	public function removeContent(which):void {
		if (which is MediaInfo)
			removeChild(which as MediaInfo);
		else if (which is Number)
			removeChildAt(which as Number);
		else
			throw new ArgumentError();
	}

	public function removeAllItems():void {
		// TODO: Fix to only remove children that are itemClass instances?
		while (numChildren > 0) removeContent(0);
	}

	override public function setWidthHeight(w:Number, h:Number):void {
		super.setWidthHeight(w, h);

		this.w = w;
		this.h = h;
		arrangeItems();
	}

	public function allItems():Array {
		var items:Array = [];
		for (var i:int = 0; i < numChildren; i++) {
			var item:MediaInfo = getChildAt(i) as MediaInfo;
			if (item) items.push(item);
		}
		return items;
	}

	public function arrangeItems():void {
		if (numChildren == 0) return;

		var nextX:int;
		var nextY:int;
		var i:int;
		var item:MediaInfoTablet;
		if (type == TYPE_STRIP_HORIZONTAL) {
			nextX = itemPadding * 2;
			nextY = Math.floor((h - MediaInfo.frameHeight)/2);
			for each (item in allItems()) {
				item.x = nextX;
				item.y = nextY;
				nextX += MediaInfo.frameWidth + itemPadding;
			}
		}
		else if (type == TYPE_STRIP_VERTICAL) {
			nextX = Math.floor((w - MediaInfo.frameWidth) / 2);
			nextY = itemPadding * 2;
			for each (item in allItems()) {
				item.x = nextX;
				item.y = nextY;
				nextY += MediaInfo.frameHeight + itemPadding;
			}
		}
		else if (type == TYPE_GRID) {
			nextX = itemPadding * 2;
			nextY = Math.floor((h - MediaInfo.frameHeight)/2);
			for each (item in allItems()) {
				item.x = nextX;
				item.y = nextY;
				nextX += MediaInfo.frameWidth + itemPadding;
				if (nextX > w - MediaInfo.frameWidth) {
					nextX = itemPadding * 2;
					nextY += MediaInfo.frameHeight + itemPadding;
				}
			}
		}
	}
}
}
