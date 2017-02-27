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

package watchers {
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.text.*;
	import flash.utils.*;
	import interpreter.Interpreter;
	import scratch.ScratchObj;
	import translation.Translator;
	import util.JSON;
	import uiwidgets.*;

public class ListWatcher extends Sprite {

	private const titleFont:TextFormat = new TextFormat(CSS.font, 12, 0, true);
	private const cellNumFont:TextFormat = new TextFormat(CSS.font, 11, 0, false);
	private const SCROLLBAR_W:int = 10;

	public var listName:String = '';
	public var target:ScratchObj; // the ScratchObj that owns this list
	public var contents:Array = [];
	public var isPersistent:Boolean = false;

	private var frame:ResizeableFrame;
	private var title:TextField;
	private var elementCount:TextField;
	private var cellPane:Sprite;
	private var scrollbar:Scrollbar;
	private var addItemButton:IconButton;

	private var firstVisibleIndex:int;
	private var visibleCells:Array = [];
	private var visibleCellNums:Array = [];
	private var insertionIndex:int = -1; // where to add an item; -1 means to add it at the end

	private var cellPool:Array = []; // recycled cells
	private var cellNumPool:Array = []; // recycled cell numbers
	private var tempCellNum:TextField; // used to compute maximum cell number width

	private var lastAccess:Vector.<uint> = new Vector.<uint>();
	private var lastActiveIndex:int;
	private var contentsChanged:Boolean;
	private var isIdle:Boolean;
	private var limitedView:Boolean;

	public function ListWatcher(listName:String = 'List Title', contents:Array = null, target:ScratchObj = null, limitView:Boolean = false) {
		this.listName = listName;
		this.target = target;
		this.contents = (contents == null) ? [] : contents;
		limitedView = limitView;

		frame = new ResizeableFrame(0x949191, 0xC1C4C7, 14, false, 2);
		frame.setWidthHeight(50, 100);
		frame.showResizer();
		frame.minWidth = 80;
		frame.minHeight = 62;
		addChild(frame);

		title = createTextField(listName, titleFont);
		frame.addChild(title);

		cellPane = new Sprite();
		cellPane.mask = new Shape();
		cellPane.addChild(cellPane.mask);
		addChild(cellPane);

		scrollbar = new Scrollbar(10, 10, scrollToFraction);
		addChild(scrollbar);

		addItemButton = new IconButton(addItem, 'addItem');
		addChild(addItemButton);

		elementCount = createTextField(Translator.map('length') + ': 0', cellNumFont);
		frame.addChild(elementCount);

		setWidthHeight(100, 200);
		addEventListener(flash.events.FocusEvent.FOCUS_IN, gotFocus);
		addEventListener(flash.events.FocusEvent.FOCUS_OUT, lostFocus);
	}

	public static function strings():Array {
		return [
			'length', 'import', 'export', 'hide',
			'Which column do you want to import'];
	}

	public function toggleLimitedView(limitView:Boolean):void {
		limitedView = limitView;
	}
	public function updateTitleAndContents():void {
		// Called when opening a project.
		updateTitle();
		scrollToIndex(0);
	}

	public function updateTranslation():void { updateElementCount() }

	/* Dragging */

	public function objToGrab(evt:MouseEvent):ListWatcher { return this } // allow dragging

	/* Menu */

	public function menu(evt:MouseEvent):Menu {
		var m:Menu = new Menu();
		m.addItem('import', importList);
		m.addItem('export', exportList);
		m.addLine();
		m.addItem('hide', hide);
		return m;
	}

	private function importList():void {
		// Prompt user for a file name and import that file.
		// Each line of the file becomes a list item.
		function fileLoaded(event:Event):void {
			var file:FileReference = FileReference(event.target);
			var s:String = file.data.readUTFBytes(file.data.length);
			importLines(removeTrailingEmptyLines(s.split(/\r\n|[\r\n]/)));
		}

		Scratch.loadSingleFile(fileLoaded);
	}

	private function exportList():void {
		var file:FileReference = new FileReference();
		var s:String = contents.join('\n') + '\n';
		file.save(s, listName + '.txt');
	}

	private function hide():void {
		visible = false;
		Scratch.app.updatePalette(false);
	}

	// -----------------------------
	// Visual feedback for list changes
	//------------------------------

	private function removeTrailingEmptyLines(lines:Array):Array {
		while (lines.length && !lines[lines.length - 1]) lines.pop();
		return lines;
	}

	private function importLines(lines:Array):void {
		function gotColumn(s:String):void {
			var n:Number = parseInt(s);
			if (isNaN(n) || (n < 1) || (n > columnCount)) contents = lines;
			else contents = extractColumn(n, lines, delimiter);
			scrollToIndex(0);
		}
		var delimiter:String = guessDelimiter(lines);
		if (delimiter == null) { // single column (or empty)
			contents = lines;
			scrollToIndex(0);
			return;
		}
		var columnCount:int = lines[0].split(delimiter).length;
		DialogBox.ask(
			Translator.map('Which column do you want to import') + '(1-' + columnCount + ')?',
			'1', Scratch.app.stage, gotColumn);
	}

	private function guessDelimiter(lines:Array):String {
		// Guess the delimiter used to separate the fields in multicolumn data.
		// Return the delimiter or null if the data is not multicolumn.
		// Note: Assume we've found the right delimiter if it splits three
		// lines into the same number (greater than 1) of fields.

		if (lines.length == 0) return null;

		for each (var d:String in [',', '\t']) {
			var count1:int = lines[0].split(d).length;
			var count2:int = lines[Math.floor(lines.length / 2)].split(d).length;
			var count3:int = lines[lines.length - 1].split(d).length;
			if ((count1 > 1) && (count1 == count2) && (count1 == count3)) return d;
		}
		return null;
	}

	private function extractColumn(n:int, lines:Array, delimiter:String):Array {
		var result:Array = [];
		for each (var s:String in lines) {
			var cols:Array = s.split(delimiter);
			result.push((n <= cols.length) ? cols[n - 1] : '');
		}
		return result;
	}

	// -----------------------------
	// Visual feedback for list changes
	//------------------------------

	public function updateWatcher(i:int, readOnly:Boolean, interp:Interpreter):void {
		// Called by list primitives. Record access to entry at i and whether list contents have changed.
		// readOnly should be true for read operations, false for operations that change the list.
		// Note: To reduce the cost of list operations, this function merely records changes,
		// leaving the more time-consuming work of updating the visual feedback to step(), which
		// is called only once per frame.
		isIdle = false;
		if (!readOnly) contentsChanged = true;
		if (parent == null) visible = false;
		if (!visible) return;
		adjustLastAccessSize();
		if ((i < 1) || (i > lastAccess.length)) return;
		lastAccess[i - 1] = getTimer();
		lastActiveIndex = i - 1;
		interp.redraw();
	}

	public function prepareToShow():void {
		// Called before showing a list that has been hidden to update its contents.
		updateTitle();
		contentsChanged = true;
		isIdle = false;
		step();
	}

	public function step():void {
		// Update index highlights and contents if they have changed.
		if (isIdle) return;
		if (contentsChanged) {
			updateContents();
			updateScrollbar();
			contentsChanged = false;
		}
		if (contents.length == 0) {
			isIdle = true;
			return;
		}
		ensureVisible();
		updateIndexHighlights();
	}

	private function ensureVisible():void {
		var i:int = Math.max(0, Math.min(lastActiveIndex, contents.length - 1));
		if ((firstVisibleIndex <= i) && (i < (firstVisibleIndex + visibleCells.length))) {
			return; // index is already visible
		}
		firstVisibleIndex = i;
		updateContents();
		updateScrollbar();
	}

	private function updateIndexHighlights():void {
		// Highlight the cell number of all recently accessed cells currently visible.
		const fadeoutMSecs:int = 800;
		adjustLastAccessSize();
		var now:int = getTimer();
		isIdle = true; // try to be idle; set to false if any non-zero lastAccess value is found
		for (var i:int = 0; i < visibleCellNums.length; i++) {
			var lastAccessTime:int = lastAccess[firstVisibleIndex + i];
			if (lastAccessTime > 0) {
				isIdle = false;
				var msecsSinceAccess:int = now - lastAccessTime;
				if (msecsSinceAccess < fadeoutMSecs) {
					// Animate from yellow to black over fadeoutMSecs.
					var gray:int = 255 * ((fadeoutMSecs - msecsSinceAccess) / fadeoutMSecs);
					visibleCellNums[i].textColor = (gray << 16) | (gray << 8); // red + green = yellow
				} else {
					visibleCellNums[i].textColor = 0; // black
					lastAccess[firstVisibleIndex + i] = 0;
				}
			}
		}
	}

	private function adjustLastAccessSize():void {
		// Ensure that lastAccess is the same length as contents.
		if (lastAccess.length == contents.length) return;
		if (lastAccess.length < contents.length) {
			lastAccess = lastAccess.concat(new Vector.<uint>(contents.length - lastAccess.length));
		} else if (lastAccess.length > contents.length) {
			lastAccess = lastAccess.slice(0, contents.length);
		}
	}

	// -----------------------------
	// Add Item Button Support
	//------------------------------

	private function addItem(b:IconButton = null):void {
		// Called when addItemButton is clicked.
		if ((root is Scratch) && !(root as Scratch).editMode) return;
		if (insertionIndex < 0) insertionIndex = contents.length;
		contents.splice(insertionIndex, 0, '');
		updateContents();
		updateScrollbar();
		selectCell(insertionIndex);
	}

	private function gotFocus(e:FocusEvent):void {
		// When the user clicks on a cell, it gets keyboard focus.
		// Record that list index for possibly inserting a new cell.
		// Note: focus is lost when the addItem button is clicked.
		var newFocus:DisplayObject = e.target as DisplayObject;
		if (newFocus == null) return;
		insertionIndex = -1;
		for (var i:int = 0; i < visibleCells.length; i++) {
			if (visibleCells[i] == newFocus.parent) {
				insertionIndex = firstVisibleIndex + i + 1;
				return;
			}
		}
	}

	private function lostFocus(e:FocusEvent):void {
		// If another object is getting focus, clear insertionIndex.
		if (e.relatedObject != null) insertionIndex = -1;
	}

	// -----------------------------
	// Delete Item Button Support
	//------------------------------

	private function deleteItem(b:IconButton):void {
		var cell:ListCell = b.lastEvent.target.parent as ListCell;
		if (cell == null) return;
		for (var i:int = 0; i < visibleCells.length; i++) {
			var c:ListCell = visibleCells[i];
			if (c == cell) {
				var j:int = firstVisibleIndex + i;
				contents.splice(j, 1);
				if (j == contents.length && visibleCells.length == 1) {
					scrollToIndex(j - 1);
				} else {
					updateContents();
					updateScrollbar();
				}
				if (visibleCells.length) {
					selectCell(Math.min(j, contents.length - 1));
				}
				return;
			}
		}
	}

	// -----------------------------
	// Layout
	//------------------------------

	public function setWidthHeight(w:int, h:int):void {
		// Large (especially tall) list watchers can cause many, many list cells to be allocated, leading to delays.
		// Bound the size so that updateContents() won't cause long delays for long lists.
		var boundingObject:Object = this.parent || Scratch.app.stagePane || {width: 480, height: 360};
		x = Math.max(0, Math.min(x, boundingObject.width - frame.minWidth));
		y = Math.max(0, Math.min(y, boundingObject.height - frame.minHeight));
		w = Math.max(frame.minWidth, Math.min(w, boundingObject.width - x));
		h = Math.max(frame.minHeight, Math.min(h, boundingObject.height - y));

		frame.setWidthHeight(w, h);
		fixLayout();
	}

	public function fixLayout():void {
		// Called by ResizeableFrame, so must be public.
		title.x = Math.floor((frame.w - title.width) / 2);
		title.y = 2;

		elementCount.x = Math.floor((frame.w - elementCount.width) / 2);
		elementCount.y = frame.h - elementCount.height + 1;

		cellPane.x = 1;
		cellPane.y = 22;

		addItemButton.x = 2;
		addItemButton.y = frame.h - addItemButton.height - 2;

		var g:Graphics = (cellPane.mask as Shape).graphics;
		g.clear();
		g.beginFill(0);
		g.drawRect(0, 0, frame.w - 17, frame.h - 42);
		g.endFill();

		scrollbar.setWidthHeight(SCROLLBAR_W, cellPane.mask.height);
		scrollbar.x = frame.w - SCROLLBAR_W - 2;
		scrollbar.y = 20;

		updateContents();
		updateScrollbar();
	}

	// -----------------------------
	// List contents layout and scrolling
	//------------------------------

	private function scrollToFraction(n:Number):void {
		var old:int = firstVisibleIndex;
		n = Math.floor(n * contents.length);
		firstVisibleIndex = Math.max(0, Math.min(n, contents.length - 1));
		lastActiveIndex = firstVisibleIndex;
		if (firstVisibleIndex != old) updateContents();
	}

	private function scrollToIndex(i:int):void {
		var frac:Number = i / (contents.length - 1);
		firstVisibleIndex = -1; // force scrollToFraction() to always update contents
		scrollToFraction(frac);
		updateScrollbar();
	}

	private function updateScrollbar():void {
		var frac:Number = (firstVisibleIndex - 1) / (contents.length - 1);
		scrollbar.update(frac, visibleCells.length / contents.length);
	}

	public function updateContents():void {
//		var limitedCloudView:Boolean = isPersistent;
//		if (limitedCloudView &&
//			Scratch.app.isLoggedIn() && Scratch.app.editMode &&
//			(Scratch.app.projectOwner == Scratch.app.userName)) {
//				limitedCloudView = false; // only project owner can view cloud list contents
//		}
		var isEditable:Boolean = Scratch.app.editMode && !limitedView;
		updateElementCount();
		removeAllCells();
		visibleCells = [];
		visibleCellNums = [];
		var visibleHeight:int = cellPane.height;
		var cellNumRight:int = cellNumWidth() + 14;
		var cellX:int = cellNumRight;
		var cellW:int = cellPane.width - cellX - 1;
		var nextY:int = 0;
		for (var i:int = firstVisibleIndex; i < contents.length; i++) {
			var s:String = Watcher.formatValue(contents[i]);
			if (limitedView && (s.length > 8)) s = s.slice(0, 8) + '...';
			var cell:ListCell = allocateCell(s, cellW);
			cell.x = cellX;
			cell.y = nextY;
			cell.setEditable(isEditable);
			visibleCells.push(cell);
			cellPane.addChild(cell);

			var cellNum:TextField = allocateCellNum(String(i + 1));
			cellNum.x = cellNumRight - cellNum.width - 3;
			cellNum.y = nextY + int((cell.height - cellNum.height) / 2);
			cellNum.textColor = 0;
			visibleCellNums.push(cellNum);
			cellPane.addChild(cellNum);

			nextY += cell.height - 1;
			if (nextY > visibleHeight) break;
		}

		if(!contents.length) {
			var tf:TextField = createTextField(Translator.map('(empty)'), cellNumFont);
			tf.x = (frame.w - SCROLLBAR_W - tf.textWidth) / 2;
			tf.y = (visibleHeight - tf.textHeight) / 2;
			cellPane.addChild(tf);
		}
	}

	private function cellNumWidth():int {
		// Return the estimated maximum cell number width. We assume that a list
		// can display at most 20 elements, so we need enough width to display
		// firstVisibleIndex + 20. Take the log base 10 to get the number of digits
		// and measure the width of a textfield with that many zeros.
		if (tempCellNum == null) tempCellNum = createTextField('', cellNumFont);
		var digitCount:int = Math.log(firstVisibleIndex + 20) / Math.log(10);
		tempCellNum.text = '000000000000000'.slice(0, digitCount);
		return tempCellNum.textWidth;
	}

	private function removeAllCells():void {
		// Remove all children except the mask. Recycle ListCells and TextFields.
		while (cellPane.numChildren > 1) {
			var o:DisplayObject = cellPane.getChildAt(1);
			if (o is ListCell) cellPool.push(o);
			if (o is TextField) cellNumPool.push(o);
			cellPane.removeChildAt(1);
		}
	}

	private function allocateCell(s:String, width:int):ListCell {
		// Allocate a ListCell with the given contents and width.
		// Recycle one from the cell pool if possible.
		if (cellPool.length == 0) return new ListCell(s, width, textChanged, keyPress, deleteItem);
		var result:ListCell = cellPool.pop();
		result.setText(s, width);
		return result;
	}

	private function allocateCellNum(s:String):TextField {
		// Allocate a TextField for a cell number with the given contents.
		// Recycle one from the cell number pool if possible.
		if (cellNumPool.length == 0) return createTextField(s, cellNumFont);
		var result:TextField = cellNumPool.pop();
		result.text = s;
		result.width = result.textWidth + 5;
		return result;
	}

	private function createTextField(s:String, format:TextFormat):TextField {
		var tf:TextField = new TextField();
		tf.type = 'dynamic'; // not editable
		tf.selectable = false;
		tf.defaultTextFormat = format;
		tf.text = s;
		tf.height = tf.textHeight + 5
		tf.width = tf.textWidth + 5;
		return tf;
	}

	public function updateTitle():void {
		title.text = ((target == null) || (target.isStage)) ? listName : target.objName + ': ' + listName;
		title.width = title.textWidth + 5;
		title.x = Math.floor((frame.w - title.width) / 2);
	}

	private function updateElementCount():void {
		elementCount.text = Translator.map('length') + ': ' + contents.length;
		elementCount.width = elementCount.textWidth + 5;
		elementCount.x = Math.floor((frame.w - elementCount.width) / 2);
	}

	// -----------------------------
	// User Input (handle events for cell's TextField)
	//------------------------------

	private function textChanged(e:Event):void {
		// Triggered by editing the contents of a cell.
		// Copy the cell contents into the underlying list.
		var cellContents:TextField = e.target as TextField;
		for (var i:int = 0; i < visibleCells.length; i++) {
			var cell:ListCell = visibleCells[i];
			if (cell.tf == cellContents) {
				contents[firstVisibleIndex + i] = cellContents.text;
				return;
			}
		}
	}

	private function selectCell(i:int, scroll:Boolean = true):void {
		var j:int = i - firstVisibleIndex;
		if (j >= 0 && j < visibleCells.length) {
			visibleCells[j].select();
			insertionIndex = i + 1;
		} else if (scroll) {
			scrollToIndex(i);
			selectCell(i, false);
		}
	}

	private function keyPress(e:KeyboardEvent):void {
		// Respond to a key press on a cell.
		if (e.keyCode == 13) {
			if (e.shiftKey) insertionIndex--;
			addItem();
			return;
		}
		if (contents.length < 2) return; // only one cell, and it's already selected
		var direction:int =
			e.keyCode == 38 ? -1 :
			e.keyCode == 40 ? 1 :
			e.keyCode == 9 ? (e.shiftKey ? -1 : 1) : 0;
		if (direction == 0) return;
		var cellContents:TextField = e.target as TextField;
		for (var i:int = 0; i < visibleCells.length; i++) {
			var cell:ListCell = visibleCells[i];
			if (cell.tf == cellContents) {
				selectCell((firstVisibleIndex + i + direction + contents.length) % contents.length);
				return;
			}
		}
	}

	// -----------------------------
	// Saving
	//------------------------------

	public function writeJSON(json:util.JSON):void {
		json.writeKeyValue('listName', listName);
		json.writeKeyValue('contents', contents);
		json.writeKeyValue('isPersistent', isPersistent);
		json.writeKeyValue('x', x);
		json.writeKeyValue('y', y);
		json.writeKeyValue('width', width);
		json.writeKeyValue('height', height);
		json.writeKeyValue('visible', visible && (parent != null));
	}

	public function readJSON(obj:Object):void {
		listName = obj.listName;
		contents = obj.contents;
		isPersistent = (obj.isPersistent == undefined) ? false : obj.isPersistent; // handle old projects gracefully
		x = obj.x;
		y = obj.y;
		setWidthHeight(obj.width, obj.height);
		visible = obj.visible;
		updateTitleAndContents();
	}

}}
