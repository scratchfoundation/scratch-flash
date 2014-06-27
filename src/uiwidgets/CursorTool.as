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

package uiwidgets {
	import flash.display.*;
	import flash.events.*;
	import flash.geom.Point;
	import flash.system.Capabilities;
	import flash.ui.*;
	import assets.Resources;

public class CursorTool {

	public static var tool:String; // null or one of: copy, cut, grow, shrink, help

	private static var app:Scratch;
	private static var currentCursor:Bitmap;
	private static var offsetX:int;
	private static var offsetY:int;
	private static var registeredCursors:Object = {};

	public static function setTool(toolName:String):void {
		hideSoftwareCursor();
		tool = toolName;
		app.enableEditorTools(tool == null);
		if (tool == null) return;
		switch(tool) {
		case 'copy':
			showSoftwareCursor(Resources.createBmp('copyCursor'));
			break;
		case 'cut':
			showSoftwareCursor(Resources.createBmp('cutCursor'));
			break;
		case 'grow':
			showSoftwareCursor(Resources.createBmp('growCursor'));
			break;
		case 'shrink':
			showSoftwareCursor(Resources.createBmp('shrinkCursor'));
			break;
		case 'help':
			showSoftwareCursor(Resources.createBmp('helpCursor'));
			break;
		case 'draw':
			showSoftwareCursor(Resources.createBmp('pencilCursor'));
			break;
		default:
			tool = null;
		}
		mouseMove(null);
	}

	private static function hideSoftwareCursor():void {
		// Hide the current cursor and revert to using the hardware cursor.
		if (currentCursor && currentCursor.parent) currentCursor.parent.removeChild(currentCursor);
		currentCursor = null;
		Mouse.cursor = MouseCursor.AUTO;
		Mouse.show();
	}

	private static function showSoftwareCursor(bm:Bitmap, offsetX:int = 999, offsetY:int = 999):void {
		if (bm) {
			if (currentCursor && currentCursor.parent) currentCursor.parent.removeChild(currentCursor);
			currentCursor = new Bitmap(bm.bitmapData);
			CursorTool.offsetX = (offsetX <= bm.width) ? offsetX : (bm.width / 2);
			CursorTool.offsetY = (offsetY <= bm.height) ? offsetY : (bm.height / 2);
			app.stage.addChild(currentCursor);
			Mouse.hide();
			mouseMove(null);
		}
	}

	public static function init(app:Scratch):void {
		CursorTool.app = app;
		app.stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
		app.stage.addEventListener(Event.MOUSE_LEAVE, mouseLeave);
	}

	private static function mouseMove(ignore:*):void {
		if (currentCursor) {
			Mouse.hide();
			currentCursor.x = app.mouseX - offsetX;
			currentCursor.y = app.mouseY - offsetY;
		}
	}

	private static function mouseLeave(ignore:*):void { Mouse.cursor = MouseCursor.AUTO; Mouse.show() }

	public static function setCustomCursor(name:String, bmp:BitmapData = null, hotSpot:Point = null, reuse:Boolean = true):void {
		const standardCursors:Array = ['arrow', 'auto', 'button', 'hand', 'ibeam'];

		if (tool) return; // don't let point editor cursors override top bar tools

		hideSoftwareCursor();
		if (standardCursors.indexOf(name) != -1) { Mouse.cursor = name; return; }

		if (('' == name) && !reuse) {
			// disposable cursors for bitmap pen and eraser (sometimes they are too large for hardware cursor)
			showSoftwareCursor(new Bitmap(bmp), hotSpot.x, hotSpot.y);
			return;
		}

		var saved:Array = registeredCursors[name];
		if (saved && reuse) {
			if (isLinux()) showSoftwareCursor(new Bitmap(saved[0]), saved[1].x, saved[1].y);
			else Mouse.cursor = name; // use previously registered hardware cursor
			return;
		}

		if (bmp && hotSpot) {
			registeredCursors[name] = [bmp, hotSpot];
			if (isLinux()) showSoftwareCursor(new Bitmap(bmp), hotSpot.x, hotSpot.y);
			else registerHardwareCursor(name, bmp, hotSpot);
		}
	}

	private static function isLinux():Boolean {
		var os:String = Capabilities.os;
		if (os.indexOf('Mac OS') > -1) return false;
		if (os.indexOf('Win') > -1) return false;
		return true;
	}

	private static function registerHardwareCursor(name:String, bmp:BitmapData, hotSpot:Point):void {
		var images:Vector.<BitmapData> = new Vector.<BitmapData>(1, true);
		images[0] = bmp;

		var cursorData:MouseCursorData = new MouseCursorData();
		cursorData.data = images;
		cursorData.hotSpot = hotSpot;
		Mouse.registerCursor(name, cursorData);
	}

}}
