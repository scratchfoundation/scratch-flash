/*
 * Scratch Project Editor and Player
 * Copyright (C) 2014 Massachusetts Institute of Technology
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

// Menu.as
// John Maloney, October 2009
//
// A simple one-level text menu. Menus are built using addItem() and addLine() and
// invoked using showOnStage(). When the menu operation is complete, the client function
// is called, if it isn't null. If the client function is null but the selected item is
// a function, then that function is called. This allows you to create a menu whose
// elements are actions.

package uiwidgets {
	import flash.display.*;
	import flash.events.*;
	import flash.filters.DropShadowFilter;
	import flash.geom.Point;
	import flash.utils.getTimer;
	import translation.TranslatableStrings;

public class Menu extends Sprite {

	// when stringCollectionMode is true menus are not displayed but strings are recorded for translation
	public static var stringCollectionMode:Boolean;

	public var clientFunction:Function; // if not null, called when menu interaction is done
	public var color:int;
	public var minWidth:int;
	public var itemHeight:int;

	public static var line:Object = new Object;
	private static var menuJustCreated:Boolean;

	private var menuName:String = '';
	private var allItems:Array = [];
	private var firstItemIndex:int = 0;
	private var maxHeight:int;
	private var maxScrollIndex:int;
	private var upArrow:Shape;
	private var downArrow:Shape;

	public function Menu(clientFunction:Function = null, menuName:String = '', color:int = 0xA0A0A0, itemHeight:int = 28) {
		this.clientFunction = clientFunction;
		this.menuName = menuName;
		this.color = color;
		this.itemHeight = itemHeight;
	}

	public function addItem(label:*, value:* = null, enabled:Boolean = true, checkmark:Boolean = false):void {
		var last:MenuItem = allItems.length ? allItems[allItems.length-1] : null;
		var newItem:MenuItem = new MenuItem(this, label, value, enabled);
		if ((!last || last.isLine()) && newItem.isLine()) return;
		newItem.showCheckmark(checkmark);
		allItems.push(newItem);
	}

	public function addLine():void {
		addItem(line);
	}

	public function showOnStage(stage:Stage, x:int = -1, y:int = -1):void {
		if (stringCollectionMode) {
			for each (var item:MenuItem in allItems) {
				// TODO: do we really want to remove parentheticals on all these?
				TranslatableStrings.add(item.getLabel(), true);
			}
			return;
		}
		removeMenusFrom(stage); // remove old menus
		if (allItems.length == 0) return;
		menuJustCreated = true;
		prepMenu(stage);
		scrollBy(0);
		this.x = (x > 0) ? x : stage.mouseX + 5;
		this.y = (y > 0) ? y : stage.mouseY - 5;
		// keep menu on screen
		this.x = Math.max(5, Math.min(this.x, stage.stageWidth - this.width - 8));
		this.y = Math.max(5, Math.min(this.y, stage.stageHeight - this.height - 8));
		// if under mouse, try to move right a bit so menu stays up
		if ((this.x < stage.mouseX) && (this.y < stage.mouseY)) {
			var newX:int = stage.mouseX + 6;
			if (newX < (stage.stageWidth - this.width)) this.x = newX;
		}
		stage.addChild(this);
		addEventListener(Event.ENTER_FRAME, step);
	}

	public static function dummyButton():IconButton {
		// Useful for exercising menus when collecting UI strings.
		var b:IconButton = new IconButton(null, null);
		b.lastEvent = new MouseEvent('dummy');
		return b;
	}

	public function selected(itemValue:*):void {
		stage.focus = null;
		// Run the clientFunction, if there is one. Otherwise, if itemValue is a function, run that.
		if (clientFunction != null) {
			clientFunction(itemValue);
		} else {
			if (itemValue is Function) itemValue();
		}
		if (parent != null) parent.removeChild(this);
	}

	static public function removeMenusFrom(o:DisplayObjectContainer):void {
		if (menuJustCreated) { menuJustCreated = false; return; }
		var i:int, menus:Array = [];
		for (i = 0; i < o.numChildren; i++) {
			if (o.getChildAt(i) is Menu) menus.push(o.getChildAt(i));
		}
		for (i = 0; i < menus.length; i++) {
			var m:Menu = Menu(menus[i]);
			if (m.parent != null) m.parent.removeChild(m);
		}
	}

	private function prepMenu(stage:Stage):void {
		var i:int, maxW:int = minWidth;
		var item:MenuItem;
		while (allItems.length && allItems[allItems.length-1].isLine()) allItems.pop();
		// translate strings
		for each (item in allItems) item.translate(menuName);
		// find the widest menu item...
		for each (item in allItems) maxW = Math.max(maxW, item.width);
		// then fix item sizes and layout
		var nextY:int = 0;
		for each (item in allItems) {
			item.setWidthHeight(maxW, itemHeight);
			item.y = nextY;
			nextY += item.height;
		}
		// compute max height
		maxHeight = Math.min(500, stage.stageHeight - 50);
		// compute max scrollIndex
		var totalH:int;
		for (maxScrollIndex = allItems.length - 1; maxScrollIndex > 0; maxScrollIndex--) {
			totalH += allItems[maxScrollIndex].height;
			if (totalH > maxHeight) break;
		}
		makeArrows(maxW);
		addShadowFilter();
	}

	private function makeArrows(w:int):void {
		upArrow = makeArrow(true);
		downArrow = makeArrow(false);
		upArrow.x = downArrow.x = (w / 2) - 2;
		upArrow.y = 2;
	}

	private function makeArrow(up:Boolean):Shape {
		var arrow:Shape = new Shape();
		var g:Graphics = arrow.graphics;
		g.beginFill(0xFFFFFF);
		if (up) {
			g.moveTo(0, 5);
			g.lineTo(5, 0);
			g.lineTo(10, 5);
		} else {
			g.moveTo(0, 0);
			g.lineTo(10, 0);
			g.lineTo(5, 5);
		}
		g.endFill();
		return arrow;
	}

	private var scrollMSecs:int = 40;
	private var lastTime:int;

	private function step(e:Event):void {
		const scrollInset:int = 6;
		if (parent == null) {
			removeEventListener(Event.ENTER_FRAME, step);
			return;
		}

		if ((getTimer() - lastTime) < scrollMSecs) return;
		lastTime = getTimer();

		var localY:int = this.globalToLocal(new Point(stage.mouseX, stage.mouseY)).y;
		if ((localY < (2 + scrollInset)) && (firstItemIndex > 0)) scrollBy(-1);
		if ((localY > (this.height - scrollInset)) && (firstItemIndex < maxScrollIndex)) scrollBy(1);
	}

	private function scrollBy(delta:int):void {
		firstItemIndex += delta;
		var nextY:int = 1;
		// remove any existing children
		while (this.numChildren > 0) this.removeChildAt(0);
		// add menu items
		for (var i:int = firstItemIndex; i < allItems.length; i++) {
			var item:MenuItem = allItems[i];
			addChild(item);
			item.x = 1;
			item.y = nextY;
			nextY += item.height;
			if (nextY > maxHeight) break;
		}
		// add up/down arrows, if needed
		if (firstItemIndex > 0) addChild(upArrow);
		var showDownArrow:Boolean = (allItems.length > 0) && !allItems[allItems.length - 1].parent;
		if (showDownArrow) {
			downArrow.y = this.height - 5;
			addChild(downArrow);
		}
	}

	private function addShadowFilter():void {
		var f:DropShadowFilter = new DropShadowFilter();
		f.blurX = f.blurY = 5;
		f.distance = 3;
		f.color = 0x333333;
		filters = [f];
	}

}}
