/**
 * Created by shanemc on 9/12/14.
 */
package uiwidgets {
import com.greensock.TweenLite;
import com.greensock.easing.Linear;
import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.events.Event;
import flash.geom.Point;
import scratch.ScratchSprite;

import ui.BaseItem;
import ui.Utility;
import ui.dragdrop.DragAndDropMgr;
import ui.dragdrop.DropTarget;
import ui.events.DragEvent;
import ui.styles.ItemStyle;

public class ArrangeableContents extends ScrollFrameContents implements DropTarget {
	public static const TYPE_GRID:uint = 0;
	public static const TYPE_STRIP_HORIZONTAL:uint = 1;
	public static const TYPE_STRIP_VERTICAL:uint = 2;

	public static const ORDER_CHANGE:String = 'orderChange';
	public static const CONTENT_CHANGE:String = 'contentChange';
//	private static const leftBehindAlpha:Number = 0.6;
	private static const animationDuration:Number = 0.25;

	// Fixed state variables
	private var type:uint = 0;
	private var itemPadding:uint = Utility.cmToPixels(0.1);
	protected var itemStyle:ItemStyle;

	// Dynamic state variables
	private var w:uint = 100;
	private var h:uint = 100;
	private var selectedItem:BaseItem;
	private var editMode:Boolean;
	public function ArrangeableContents(iStyle:ItemStyle, t:uint = TYPE_GRID, padding:int = -1) {
		type = t;
		itemStyle = iStyle;
		if (padding > -1) itemPadding = padding;
		setWidthHeight(w, h);

		addEventListener(DragEvent.DRAG_DROP, dragAndDropHandler);
		addEventListener(DragEvent.DRAG_START, dragAndDropHandler);
		addEventListener(DragEvent.DRAG_STOP, dragAndDropHandler);
		addEventListener(DragEvent.DRAG_CANCEL, dragAndDropHandler);
		addEventListener(DragEvent.DRAG_OVER, dragAndDropHandler);
		addEventListener(DragEvent.DRAG_MOVE, dragAndDropHandler);
		addEventListener(DragEvent.DRAG_OUT, dragAndDropHandler);
	}

	public function setItemPadding(padding:uint):void {
		itemPadding = padding;
		arrangeItems();
	}

	override public function updateSize():void {
		super.updateSize();

		arrangeItems();
	}

	// Move items out of the way of a dragging item
	private var dropPos:int = -1;
	private var ignoredObj:*;
	private function dragAndDropHandler(event:DragEvent):void {
		var mi:BaseItem;
		var dup:BaseItem;
		switch(event.type) {
			case DragEvent.DRAG_START:
				event.target.visible = false;
				arrangeItems(true);
				break;

			case DragEvent.DRAG_OVER:
				mi = event.draggedObject as BaseItem;
				if (!mi) {
					var spr:ScratchSprite = event.draggedObject as ScratchSprite;
					if (spr)
						mi = Scratch.app.createMediaInfo(spr.duplicate()) as BaseItem;
				}
//				if (mi) {
//					dup = findItemByMediaInfo(mi);
//					if (dup) {
//						if ((mi  as MediaInfoOnline).fromBackpack) {
//							dup.visible = false;
//							arrangeItems(true);
//						}
//						else {
//							// TODO: when do we ignore?
//							//ignoredObj = event.draggedObject;
//						}
//					}
//				}
			case DragEvent.DRAG_MOVE:
				if (ignoredObj == event.draggedObject) break;

				dropPos = getIndexFromPoint(event.draggedObject.localToGlobal(new Point(event.draggedObject.width/2, event.draggedObject.height/2)));
				arrangeItems(true);
				break;

			case DragEvent.DRAG_STOP:
			case DragEvent.DRAG_OUT:
				mi = event.draggedObject as BaseItem;
//				if (mi && (mi as MediaInfoOnline).fromBackpack) {
//					dup = findItemByMediaInfo(mi);
//					if (dup) {
//						dup.visible = true;
//						dup.alpha = event.type == DragEvent.DRAG_OUT ? leftBehindAlpha : 1;
//					}
//				}
				ignoredObj = null;
				dropPos = -1;
				arrangeItems(true);
				break;

			case DragEvent.DRAG_CANCEL:
				mi = event.draggedObject as BaseItem;
				if (mi) {
					dup = findItemByMediaInfo(mi);
					if (dup) {
						dup.visible = true;
						dup.alpha = 1;
					}
				}
				break;

			case DragEvent.DRAG_DROP: // Handled by handleDrop right now
		}
	}

	// Used for re-arranging items
	// Override for custom dropping actions
	public function handleDrop(obj:*):Boolean {
		// Accept the drop if we're re-arranging items OR we already have that item as identified by MD5
		var mi:BaseItem = obj as BaseItem;
		if(mi && (mi.parent == this || !!(mi = findItemByMediaInfo(mi)))) {
			mi.visible = true;
			if (mi.parent != this || dropPos > -1)
				addContent(mi, dropPos);
			dropPos = -1;
			arrangeItems();
			return true;
		}

		// TODO: is this correct?
		return true;
	}

	private function findItemByMediaInfo(obj:BaseItem):BaseItem {
		if (!obj.getIdentifier()) return null;

		for (var i:int = 0; i < numChildren; i++) {
			var item:BaseItem = getChildAt(i) as BaseItem;
			if (itemsMatch(item, obj)) return item;
		}

		return null;
	}

	protected function itemsMatch(obj1:BaseItem, obj2:BaseItem):Boolean {
		return obj1 && obj2 && obj1.getIdentifier(true) == obj2.getIdentifier(true);
	}

	// Select an item
	private function onTap(e:Event):void {
		if (editMode || selectedItem == e.target) return;
		if (selectedItem) selectedItem.setSelected(false);

		selectedItem = e.target as BaseItem;
		if (selectedItem) selectedItem.setSelected(true);
	}

	private var contentChanged:Boolean;
	private var orderChanged:Boolean;
	public function addContent(item:BaseItem, where:* = null):void {
		orderChanged = (item.parent == this);

		if (where is Number && where >= 0) addChildAt(item as DisplayObject, where as Number);
		else if (dropPos > -1) {
			var index:int = (dropPos < numChildren) ? getChildIndex(allItems()[dropPos]) : numChildren;
			addChildAt(item as DisplayObject, index);
			dropPos = -1;
		}
		else addChild(item as DisplayObject);

		contentChanged = true;
	}

	protected function replaceContents(newItems:Array):void {
		removeAllItems();
		for each (var item:BaseItem in newItems)
			addContent(item);

		contentChanged = false;
		orderChanged = false;
		updateSize();
		x = y = 0; // reset scroll offset
	}

	private function getIndexFromPoint(pt:Point, forAdding:Boolean = false):int {
		var loc:Point = globalToLocal(pt);
		var i:int = 0;
		var mi:BaseItem;
		if (type == TYPE_STRIP_HORIZONTAL) {
			for each(mi in allItems()) {
				if (mi.x + mi.width / 2 > loc.x)
					return forAdding ? getChildIndex(mi as DisplayObject)  : i;
				++i;
			}
		}
		else if (type == TYPE_STRIP_VERTICAL) {
			for each(mi in allItems()) {
				if (mi.y + mi.height / 2 > loc.y)
					return forAdding ? getChildIndex(mi as DisplayObject) : i;
				++i;
			}
		}
		else {
			// Grid layout
			var px:Number = loc.x - itemPadding * 2;
			var py:Number = loc.y - itemPadding * 2;
			var realWidth:int = w - itemPadding * 4;
			var itemWidth:uint = itemStyle.frameWidth;
			var itemHeight:uint = itemStyle.frameHeight;
			var rowLen:int = realWidth / (itemWidth + itemPadding);
			var extraPadding:int = (realWidth - rowLen * (itemWidth + itemPadding)) / rowLen;
			var index:int = Math.max(0, Math.min(rowLen-1, Math.floor(px / (itemWidth + itemPadding + extraPadding))) +
													rowLen * Math.floor(py / (itemHeight + itemPadding)));
			var items:Array = allItems();
			if (items.length && ((index < items.length && items[index].objType != 'ui') || index == items.length))
				return forAdding ?
						(index < items.length ? getChildIndex(items[index]) : numChildren) :
						index;

			return -1;
		}

		return forAdding ? numChildren : i;
	}

	public function removeContent(which:*):void {
		if (which is DisplayObject)
			DragAndDropMgr.setDraggable(removeChild(which as DisplayObject) as Sprite, false);
		else if (which is Number)
			DragAndDropMgr.setDraggable(removeChildAt(which as Number) as Sprite, false);
		else
			throw new ArgumentError();

		contentChanged = true;
	}

	public function removeAllItems():void {
		// TODO: Fix to only remove children that are itemClass instances?
		while (numChildren > 0) DragAndDropMgr.setDraggable(removeChildAt(0) as Sprite, false);
		dropPos = -1;
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
			var item:BaseItem = getChildAt(i) as BaseItem;
			if (item && item.visible) items.push(item);
		}
		return items;
	}

	public function arrangeItems(animate:Boolean = false):void {
		if (contentChanged) {
			dispatchEvent(new Event(orderChanged ? ORDER_CHANGE : CONTENT_CHANGE));
			contentChanged = false;
			orderChanged = false;
		}
		if (numChildren == 0) return;

		allItems().forEach(getPlacementFunc(animate));
	}

	// Return a function that places items and iterates to the next position with each call
	private function getPlacementFunc(animate:Boolean):Function {
		var nextX:int;
		var nextY:int;
		var itemWidth:uint = itemStyle.frameWidth;
		var itemHeight:uint = itemStyle.frameHeight;
		if (type == TYPE_STRIP_HORIZONTAL) {
			nextX = itemPadding;
			nextY = Math.floor((h - itemHeight) / 2);
			return function(item:BaseItem, index:int, arr:Array):void {
				// Jump another position if we're on the dropPos
				if (index == dropPos) arguments.callee(null, -2, arr);
				if (item) moveItem(item, nextX, nextY, animate);
				nextX += itemWidth + itemPadding;
			};
		}
		else if (type == TYPE_STRIP_VERTICAL) {
			nextX = Math.floor((w - itemWidth) / 2);
			nextY = itemPadding;
			return function(item:BaseItem, index:int, arr:Array):void {
				// Jump another position if we're on the dropPos
				if (index == dropPos) arguments.callee(null, -2, arr);
				if (item) moveItem(item, nextX, nextY, animate);
				nextY += itemHeight + itemPadding;
			};
		}

		nextX = itemPadding;
		nextY = itemPadding;
		var realWidth:int = w - itemPadding * 2;
		var colCount:int = realWidth / (itemWidth + itemPadding);
		var extraPadding:int = (realWidth - colCount * (itemWidth + itemPadding)) / colCount;
		return function(item:BaseItem, index:int, arr:Array):void {
			// Jump another position if we're on the dropPos
			if (index == dropPos) arguments.callee(null, -2, arr);
			if (item) moveItem(item, nextX, nextY, animate);

			nextX += itemWidth + itemPadding + extraPadding;
			if (nextX > w - (itemWidth + itemPadding)) {
				nextX = itemPadding * 2;
				nextY += itemHeight + itemPadding;
			}
		};
	}

	[inline]
	private function moveItem(item:BaseItem, x:Number, y:Number, animate:Boolean = false):void {
		if (animate) {
			TweenLite.to(item, animationDuration, {
				x: x,
				y: y,
				ease: Linear
			});
		}
		else {
			item.x = x;
			item.y = y;
		}
	}
}}