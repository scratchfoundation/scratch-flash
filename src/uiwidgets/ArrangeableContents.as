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
import flash.utils.setTimeout;

import scratch.ScratchSprite;

import ui.BaseItem;
import ui.dragdrop.DragAndDropMgr;
import ui.dragdrop.DropTarget;
import ui.events.DragEvent;
import ui.styles.ContainerStyle;
import ui.styles.ItemStyle;

public class ArrangeableContents extends ScrollFrameContents implements DropTarget {
	public static const TYPE_GRID:uint = 0;
	public static const TYPE_STRIP_HORIZONTAL:uint = 1;
	public static const TYPE_STRIP_VERTICAL:uint = 2;

	public static const ORDER_CHANGE:String = 'orderChange';
	public static const CONTENT_CHANGE:String = 'contentChange';
//	private static const leftBehindAlpha:Number = 0.6;
	public static const defaultStyle:ContainerStyle = new ContainerStyle();

	// Fixed state variables
	private var type:uint = 0;
	protected var itemStyle:ItemStyle;
	protected var style:ContainerStyle = defaultStyle;

	// Dynamic state variables
	private var w:uint = 100;
	private var h:uint = 100;
	private var selectedItem:BaseItem;
	private var editMode:Boolean;
	public function ArrangeableContents(iStyle:ItemStyle, t:uint = TYPE_GRID, cStyle:ContainerStyle = null) {
		type = t;
		itemStyle = iStyle;
		if (cStyle) style = cStyle;
		setWidthHeight(w, h);

		addEventListener(DragEvent.DRAG_DROP, dragAndDropHandler);
		addEventListener(DragEvent.DRAG_START, dragAndDropHandler);
		addEventListener(DragEvent.DRAG_STOP, dragAndDropHandler);
		addEventListener(DragEvent.DRAG_CANCEL, dragAndDropHandler);
		addEventListener(DragEvent.DRAG_OVER, dragAndDropHandler);
		addEventListener(DragEvent.DRAG_MOVE, dragAndDropHandler);
		addEventListener(DragEvent.DRAG_OUT, dragAndDropHandler);
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
//					dup = findMatchingItem(mi);
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
//					dup = findMatchingItem(mi);
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
					dup = findMatchingItem(mi);
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
		if(mi && (mi.parent == this || !!(mi = findMatchingItem(mi)))) {
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

	private function findMatchingItem(obj:BaseItem):BaseItem {
		return findItemByID(obj.getIdentifier(true), true);
	}

	public function findItemByID(id:String, strict:Boolean = false):BaseItem {
		if (!id) return null;

		for (var i:int = 0; i < numChildren; i++) {
			var item:BaseItem = getChildAt(i) as BaseItem;
			if (item && item.getIdentifier(strict) == id) return item;
		}

		return null;
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
		arrangeItems();
		x = y = 0; // reset scroll offset
	}

	private function getIndexFromPoint(pt:Point, forAdding:Boolean = false):int {
		var loc:Point = globalToLocal(pt);
		var i:int = 0;
		var item:BaseItem;
		if (type == TYPE_STRIP_HORIZONTAL) {
			for each(item in allItems()) {
				if (item.x + item.width / 2 > loc.x)
					return forAdding ? getChildIndex(item)  : i;
				++i;
			}
		}
		else if (type == TYPE_STRIP_VERTICAL) {
			for each(item in allItems()) {
				if (item.y + item.height / 2 > loc.y)
					return forAdding ? getChildIndex(item) : i;
				++i;
			}
		}
		else {
			// Grid layout
			var itemPadding:uint = style.itemPadding;
			var px:Number = loc.x - style.padding;
			var py:Number = loc.y - style.padding;
			var realWidth:int = w - style.padding * 2;
			var itemWidth:uint = itemStyle.frameWidth;
			var itemHeight:uint = itemStyle.frameHeight;
			var rowLen:int = realWidth / (itemWidth + itemPadding);
			var extraPadding:int = (realWidth - rowLen * (itemWidth + itemPadding)) / rowLen;
			var index:int = Math.max(0, Math.min(rowLen-1, Math.floor(px / (itemWidth + itemPadding + extraPadding))) +
													rowLen * Math.floor(py / (itemHeight + itemPadding)));
			var items:Vector.<BaseItem> = allItems();
			if (items.length && ((index < items.length && !items[index].isUI()) || index == items.length))
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
		this.w = w;
		this.h = h;
		arrangeItems();
	}

	protected function getInteractiveContent():Vector.<BaseItem> {
		var items:Vector.<BaseItem> = new Vector.<BaseItem>();
		for (var i:int = 0; i < numChildren; i++) {
			var item:BaseItem = getChildAt(i) as BaseItem;
			if (item && item.visible && item.isInteractive()) items.push(item);
		}
		return items;
	}

	public function allItems(includeUI:Boolean = true):Vector.<BaseItem> {
		var items:Vector.<BaseItem> = new Vector.<BaseItem>();
		for (var i:int = 0; i < numChildren; i++) {
			var item:BaseItem = getChildAt(i) as BaseItem;
			if (item && item.visible && (includeUI || !item.isUI())) items.push(item);
		}
		return items;
	}

	public function arrangeItems(animate:Boolean = false):void {
		if (contentChanged) {
			dispatchEvent(new Event(orderChanged ? ORDER_CHANGE : CONTENT_CHANGE));
			contentChanged = false;
			orderChanged = false;
		}

		if (numChildren > 0) {
			allItems().forEach(getPlacementFunc(animate));
			if (!animate)
				refreshBackground();
			else
				setTimeout(refreshBackground, style.animationDuration * 1000);
		}
		else
			refreshBackground();
	}

	protected function refreshBackground():void {
		graphics.clear();
		super.setWidthHeight(w, Math.max(h, height + style.padding * 2));
	}

	// Return a function that places items and iterates to the next position with each call
	private function getPlacementFunc(animate:Boolean):Function {
		var nextX:int;
		var nextY:int;
		var itemWidth:uint = itemStyle.frameWidth;
		var itemHeight:uint = itemStyle.frameHeight;
		var itemPadding:uint = style.itemPadding;
		if (type == TYPE_STRIP_HORIZONTAL) {
			nextX = style.padding;
			nextY = Math.floor((h - itemHeight) / 2);
			return function(item:BaseItem, index:int, arr:Vector.<BaseItem>):void {
				// Jump another position if we're on the dropPos
				if (index == dropPos) arguments.callee(null, -2, arr);
				if (item) moveItem(item, nextX, nextY, animate);
				nextX += itemWidth + itemPadding;
			};
		}
		else if (type == TYPE_STRIP_VERTICAL) {
			nextX = Math.floor((w - itemWidth) / 2);
			nextY = style.padding;
			return function(item:BaseItem, index:int, arr:Vector.<BaseItem>):void {
				// Jump another position if we're on the dropPos
				if (index == dropPos) arguments.callee(null, -2, arr);
				if (item) moveItem(item, nextX, nextY, animate);
				nextY += itemHeight + itemPadding;
			};
		}

		nextX = style.padding;
		nextY = style.padding;
		var realWidth:int = w - style.padding * 2;
		var colCount:int = (realWidth + itemPadding) / (itemWidth + itemPadding);
		var extraPadding:int = colCount > 1 ? (realWidth + itemPadding - colCount * (itemWidth + itemPadding)) / (colCount-1) : 0;
		return function(item:BaseItem, index:int, arr:Vector.<BaseItem>):void {
			// Jump another position if we're on the dropPos
			if (index == dropPos) arguments.callee(null, -2, arr);
			if (item) moveItem(item, nextX, nextY, animate);

			nextX += itemWidth + itemPadding + extraPadding;
			if (nextX > w - (itemWidth + style.padding)) {
				nextX = style.padding;
				nextY += itemHeight + itemPadding;
			}
		};
	}

	[inline]
	private function moveItem(item:BaseItem, x:Number, y:Number, animate:Boolean = false):void {
		if (animate) {
			TweenLite.to(item, style.animationDuration, {
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