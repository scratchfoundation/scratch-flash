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

package scratch {
	import flash.display.*;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.*;
	import blocks.Block;
	import translation.*;
	import uiwidgets.*;

public class ScratchComment extends Sprite {

	public var blockID:int;
	public var blockRef:Block;

	private const contentsFormat:TextFormat = new TextFormat(CSS.font, 12, CSS.textColor, false);
	private const titleFormat:TextFormat = new TextFormat(CSS.font, 12, CSS.textColor, true);
	private const arrowColor:int = 0x808080;
	private const bodyColor:int = 0xFFFFD2;
	private const titleBarColor:int = 0xFFFFA5;

	private var frame:ResizeableFrame;
	private var titleBar:Shape;
	private var expandButton:IconButton;
	private var title:TextField;
	private var contents:TextField;
	private var clipMask:Shape;
	private var isOpen:Boolean;
	private var expandedSize:Point;

	public function ScratchComment(s:String = null, isOpen:Boolean = true, width:int = 150, blockID:int = -1) {
		this.isOpen = isOpen;
		this.blockID = blockID;
		addFrame();
		addChild(titleBar = new Shape());
		addChild(clipMask = new Shape());
		addExpandButton();
		addTitle();
		addContents();
		contents.text = s || Translator.map('add comment here...');
		contents.mask = clipMask;
		frame.setWidthHeight(width, 200);
		expandedSize = new Point(width, 200);
		addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		fixLayout();
		setExpanded(isOpen);
	}

	public function objToGrab(evt:*):* { return this }

	public function fixLayout():void {
		contents.x = 5;
		contents.y = 20;
		var w:int = frame.w - contents.x - 6;
		var h:int = frame.h - contents.y - 2;
		contents.width = w;
		contents.height = h;

		var g:Graphics = clipMask.graphics;
		g.clear();
		g.beginFill(0xFFFF00);
		g.drawRect(contents.x, contents.y, w, h);

		drawTitleBar();
	}

	public function startEditText(): void {
		contents.setSelection(0, contents.text.length);
		stage.focus = contents;
	}

	private function drawTitleBar():void {
		// Draw darker yellow title area used when comment expanded.
		var g:Graphics = titleBar.graphics;
		g.clear();
		g.lineStyle();
		g.beginFill(titleBarColor);
		g.drawRoundRect(1, 1, frame.w - 1, 21, 11, 11);
		g.beginFill(bodyColor);
		g.drawRect(1, 18, frame.w - 1, 4);
	}

	public function toArray():Array {
		return [x, y, isOpen ? frame.width : expandedSize.x, isOpen ? frame.height : expandedSize.y, isOpen, blockID, contents.text];
	}

	public static function fromArray(a:Array):ScratchComment {
		var c:ScratchComment = new ScratchComment();
		c.x = a[0];
		c.y = a[1];
		c.blockID = a[5];
		c.contents.text = a[6];
		if (a[4]) {
			c.expandedSize = new Point(a[2], a[3]);
		} else {
			c.frame.setWidthHeight(a[2], a[3] == 19 ? 200 : a[3]);
		}
		c.setExpanded(a[4]);
		return c;
	}

	public function updateBlockID(blockList:Array):void {
		if (blockRef) {
			blockID = blockList.indexOf(blockRef);
		}
	}

	public function updateBlockRef(blockList:Array):void {
		if ((blockID >= 0) && (blockID < blockList.length)) {
			blockRef = blockList[blockID];
		}
	}

	/* Expand/Contract */

	public function isExpanded():Boolean { return isOpen }

	public function setExpanded(flag:Boolean):void {
		isOpen = flag;
		contents.visible = isOpen;
		titleBar.visible = isOpen;
		title.visible = !isOpen;
		expandButton.setOn(isOpen);
		if (flag) {
			frame.showResizer();
			frame.setColor(bodyColor);
			frame.setWidthHeight(expandedSize.x, expandedSize.y);
			if (parent) parent.addChild(this); // go to front
			fixLayout();
		} else {
			if (stage && stage.focus == contents) stage.focus = null; // give up focus
			expandedSize = new Point(frame.w, frame.h);
			updateTitleText();
			frame.hideResizer();
			frame.setWidthHeight(frame.w, 19);
			frame.setColor(titleBarColor);
		}
		var scriptsPane:ScriptsPane = parent as ScriptsPane;
		if (scriptsPane) scriptsPane.fixCommentLayout();
	}

	private function updateTitleText():void {
		const ellipses:String = '...';
		var maxW:int = frame.w - title.x - 5;
		var s:String = contents.text;
		var i:int = s.indexOf('\r');
		if (i > -1) s = s.slice(0, i);
		i = s.indexOf('\n');
		if (i > -1) s = s.slice(0, i);

		// Keep adding letters to the title until either
		// the entire first line fits or out of space
		i = 1;
		while (i < s.length) {
			title.text = s.slice(0, i) + ellipses;
			if (title.textWidth > maxW) {
				title.text = s.slice(0, i - 1) + ellipses;
				return;
			}
			i++;
		}
		title.text = s; // entire string fits; remove ellipses
	}

	/* Menu/Tool Operations */

	public function menu(evt:MouseEvent):Menu {
		var m:Menu = new Menu();
		var startX:Number = stage.mouseX;
		var startY:Number = stage.mouseY;
		m.addItem('duplicate', function():void {
			duplicateComment(stage.mouseX - startX, stage.mouseY - startY);
		});
		m.addItem('delete', deleteComment);
		return m;
	}

	public function handleTool(tool:String, evt:MouseEvent):void {
		if (tool == 'copy') duplicateComment(10, 5);
		if (tool == 'cut') deleteComment();
	}

	public function deleteComment():void {
		if (parent) parent.removeChild(this);
		Scratch.app.runtime.recordForUndelete(this, x, y, 0, Scratch.app.viewedObj());
		Scratch.app.scriptsPane.saveScripts();
	}

	public function duplicateComment(deltaX:Number, deltaY:Number):void {
		if (!parent) return;
		var dup:ScratchComment = new ScratchComment(contents.text, isOpen);
		dup.x = x + deltaX;
		dup.y = y + deltaY;
		parent.addChild(dup);
		Scratch.app.gh.grabOnMouseUp(dup);
	}

	private function mouseDown(evt:MouseEvent):void {
		// When open, clicks below the title bar set keyboard focus.
		if (isOpen && (evt.localY > 20)) {
			var end:int = contents.text.length;
			contents.setSelection(end, end);
			stage.focus = contents;
		}
	}

	/* Construction */

	private function addFrame():void {
		frame = new ResizeableFrame(CSS.borderColor, bodyColor, 11, false, 1);
		frame.minWidth = 100;
		frame.minHeight = 34;
		frame.showResizer();
		addChild(frame);
	}

	private function addTitle():void {
		title = new TextField();
		title.autoSize = TextFieldAutoSize.LEFT;
		title.selectable = false;
		title.defaultTextFormat = titleFormat;
		title.visible = false;
		title.x = 14;
		title.y = 1;
		addChild(title);
	}

	private function addContents():void {
		contents = new TextField();
		contents.type = 'input';
		contents.wordWrap = true;
		contents.multiline = true;
		contents.autoSize = TextFieldAutoSize.LEFT;
		contents.defaultTextFormat = contentsFormat;
		addChild(contents);
	}

	private function addExpandButton():void {
		function toggleExpand(b:IconButton):void { setExpanded(!isOpen) }
		expandButton = new IconButton(toggleExpand, expandIcon(true), expandIcon(false));
		expandButton.setOn(true);
		expandButton.disableMouseover();
		expandButton.x = 4;
		expandButton.y = 4;
		addChild(expandButton);
	}

	private function expandIcon(pointDown:Boolean):Shape {
		var icon:Shape = new Shape();
		var g:Graphics = icon.graphics;

		g.lineStyle();
		g.beginFill(arrowColor);
		if (pointDown) {
			g.moveTo(0, 2);
			g.lineTo(5.5, 8);
			g.lineTo(11, 2);
		} else {
			g.moveTo(2, 0);
			g.lineTo(8, 5.5);
			g.lineTo(2, 11);
		}
		g.endFill();
		return icon;
	}

}}
