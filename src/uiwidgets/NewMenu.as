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
// Shane M. Clements
//
// A simple one-level text menu. Menus are built using addItem() and addLine() and
// invoked using showOnStage(). When the menu operation is complete, the client function
// is called, if it isn't null. If the client function is null but the selected item is
// a function, then that function is called. This allows you to create a menu whose
// elements are actions.

package uiwidgets {
import flash.display.*;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filters.DropShadowFilter;
import flash.geom.Point;
import flash.geom.Rectangle;

import scratch.BlockMenus;

import ui.Utility;

import util.Drawing;

public class NewMenu extends Sprite {
	static public const POSITION_BELOW:uint = 0;
	static public const POSITION_ABOVE:uint = 1;
	static public const POSITION_RIGHT:uint = 2;
	static public const POSITION_LEFT:uint = 3;
	protected var menuName:String = '';
	protected var targetObj:DisplayObject;
	protected var preferredPosition:uint;
	protected var itemHeight:uint;

	public function NewMenu(target:DisplayObject, iHeight:uint = 0, position:uint = POSITION_BELOW) {
		targetObj = target;
		preferredPosition = position;
		itemHeight = iHeight == 0 ? CSS.iconHeight : iHeight;
	}

	public function shouldTranslateItem(text:String):Boolean {
		return BlockMenus.shouldTranslateItemForMenu(text, menuName);
	}

	public function addItem(... elems):void {
		addChild(new NewMenuItem(this, elems));
	}

	public function addSeparator():void {
		addChild(new NewMenuItem(this));
	}

	public function addAction(... elems):void {
		var action:Function = elems.pop();
		if (!action) throw Error('Action function not found!');

		var mi:NewMenuItem = new NewMenuItem(this, elems);
		mi.addEventListener(MouseEvent.MOUSE_UP, action, false, 0, true);
		addChild(mi);
	}

	public function show():void {
		// check the location of the target object
		// can we place the menu on the preferred side?
		// draw the arrow and then the rest of the background
		placeItems();
		graphics.clear();
		targetObj.stage.addChild(this);

		const sh:uint = stage.stageHeight, sw:uint = stage.stageWidth;
		var tSpace:Rectangle = targetObj.getBounds(stage);
		var tCenter:Point = new Point(tSpace.x + tSpace.width/2, tSpace.y + tSpace.height/2);
		var r:Rectangle = getBounds(stage);
		r.inflate(CSS.smallPadding, CSS.smallPadding);
		drawItemBGs(r.width);

		// Try below
		r.x = tCenter.x - r.width/2;
		r.y = tSpace.bottom + CSS.bigPadding;
		var belowOk:Boolean = (r.bottom <= sh);

		// Try left
		r.x = tSpace.x - r.width - CSS.bigPadding;
		r.y = tCenter.y - r.height/2;
		var leftOk:Boolean = (r.x >= 0);

		drawBackground(r);

		stage.addEventListener(MouseEvent.MOUSE_DOWN, hide, false, 0, true);
	}

	public function hide(e:Event = null):void {
		if (e && e is MouseEvent) {
			var me:MouseEvent = e as MouseEvent;
			if (hitTestPoint(me.stageX, me.stageY, true)) return;
		}
		stage.removeEventListener(MouseEvent.MOUSE_DOWN, hide);
		stage.removeChild(this);
	}

	private function drawBackground(rect:Rectangle):void {
		var r:Rectangle = rect.clone();
		var p:Point = r.topLeft.clone();
		r.x = r.y = -CSS.smallPadding;
		var arrowSize:uint = CSS.bigPadding;
		var cornerRadius:uint = CSS.smallPadding;
		var g:Graphics = graphics;
		g.clear();
		g.lineStyle(CSS.thinBorder, CSS.borderColor);
		g.beginFill(CSS.panelColor);

		var d:Drawing = new Drawing(g, r.left+cornerRadius, r.top);

		// Start from the top
		d.line(r.right-cornerRadius, r.top);
		d.curve(r.right, r.top+cornerRadius);

		// Right
		d.line(r.right, r.top + r.height/2 - arrowSize/2);
		d.line(r.right + arrowSize, r.top + r.height/2);
		d.line(r.right, r.top + r.height/2 + arrowSize/2);
		d.line(r.right, r.bottom - cornerRadius);
		d.curve(r.right-cornerRadius, r.bottom);

		// Bottom
		d.line(r.left+cornerRadius, r.bottom);
		d.curve(r.left, r.bottom-cornerRadius);

		// Left
		d.line(r.left, r.top+cornerRadius);
		d.curve(r.left+cornerRadius, r.top);

//		g.moveTo(0, 0);
//		g.lineTo(-arrowSize, arrowSize/2);
//		g.lineTo(r.)
		x = p.x + CSS.smallPadding;
		y = p.y + CSS.smallPadding;
		filters = [new DropShadowFilter(4, 90, 0, 0.3)];
	}

	private function placeItems():void {
		for(var i:uint=0; i<numChildren; ++i) {
			var item:NewMenuItem = getChildAt(i) as NewMenuItem;
			if (item) {
				item.refreshText();
				item.y = i * itemHeight;
				item.graphics.clear();
			}
		}
	}

	private function drawItemBGs(w:uint):void {
		for(var i:uint=0; i<numChildren; ++i) {
			var item:NewMenuItem = getChildAt(i) as NewMenuItem;
			if (item) {
				var g:Graphics = item.graphics;
				g.clear();
				g.lineStyle(NaN);
				g.beginFill(0, 0);
				g.drawRect(-CSS.smallPadding, 0, w, itemHeight);
				g.endFill();
			}
		}
	}

	private function refreshText():void {
		for(var i:uint=0; i<numChildren; ++i) {
			var item:NewMenuItem = getChildAt(i) as NewMenuItem;
			if (item) item.refreshText();
		}
	}
}}
