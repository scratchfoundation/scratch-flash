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
	import flash.filters.DropShadowFilter;
	import flash.text.*;
	import flash.utils.Dictionary;
	import translation.Translator;
	import ui.parts.UIPart;

public class DialogBox extends Sprite {

	private var fields:Dictionary = new Dictionary();
	private var booleanFields:Dictionary = new Dictionary();
	public var widget:DisplayObject;
	private var w:int, h:int;
	public var leftJustify:Boolean;

	private var context:Dictionary;
	private var title:TextField;
	private var xButton:IconButton;
	protected var buttons:Array = [];
	private var labelsAndFields:Array = [];
	private var booleanLabelsAndFields:Array = [];
	private var textLines:Array = [];
	private var maxLabelWidth:int = 0;
	private var maxFieldWidth:int = 0;
	private var heightPerField:int = Math.max(makeLabel('foo').height, makeField(10).height) + 10;
	private const spaceAfterText:int = 18;
	private const blankLineSpace:int = 7;

	private var acceptFunction:Function; // if not nil, called when menu interaction is accepted
	private var cancelFunction:Function; // if not nil, called when menu interaction is canceled

	public function DialogBox(acceptFunction:Function = null, cancelFunction:Function = null) {
		this.acceptFunction = acceptFunction;
		this.cancelFunction = cancelFunction;
		addFilters();
		addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		addEventListener(MouseEvent.MOUSE_UP, mouseUp);
		addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
		addEventListener(FocusEvent.KEY_FOCUS_CHANGE, focusChange);
	}

	public static function ask(question:String, defaultAnswer:String, stage:Stage = null, resultFunction:Function = null, context:Dictionary = null):void {
		function done():void { if (resultFunction != null) resultFunction(d.fields['answer'].text) }
		var d:DialogBox = new DialogBox(done);
		d.addTitle(question);
		d.addField('answer', 120, defaultAnswer, false);
		d.addButton('OK', d.accept);
		if (context) d.updateContext(context);
		d.showOnStage(stage ? stage : Scratch.app.stage);
	}

	public static function confirm(question:String, stage:Stage = null, okFunction:Function = null, cancelFunction:Function = null, context:Dictionary = null):void {
		var d:DialogBox = new DialogBox(okFunction, cancelFunction);
		d.addTitle(question);
		d.addAcceptCancelButtons('OK');
		if (context) d.updateContext(context);
		d.showOnStage(stage ? stage : Scratch.app.stage);
	}

	public static function notify(title:String, msg:String, stage:Stage = null, leftJustify:Boolean = false, okFunction:Function = null, cancelFunction:Function = null, context:Dictionary = null):void {
		var d:DialogBox = new DialogBox(okFunction, cancelFunction);
		d.leftJustify = leftJustify;
		d.addTitle(title);
		d.addText(msg);
		d.addButton('OK', d.accept);
		if (context) d.updateContext(context);
		d.showOnStage(stage ? stage : Scratch.app.stage);
	}
	
	public static function close(title:String, msg:String = null, widget:DisplayObject = null, button:String = "OK", stage:Stage = null, okFunction:Function = null, cancelFunction:Function = null, context:Dictionary = null,inverted:Boolean = false):void {
		var d:DialogBox = new DialogBox(okFunction, cancelFunction);
		d.leftJustify = false;
		d.addTitle(title);
		if (widget) d.addWidget(widget);
		if (msg) d.addText(msg);
		if (inverted) d.addInvertedButton(button,d.accept);
		else d.addButton(button, d.accept);
		d.xButton = new IconButton(d.cancel,"close");
		d.addChild(d.xButton);
		if (context) d.updateContext(context);
		d.showOnStage(stage ? stage : Scratch.app.stage);
	}

	// Updates the context for variable substitution in the dialog's text, or sets it if there was none before.
	// Make sure any text values in the context are already translated: they will not be translated here.
	// Calling this will update the text of the dialog immediately.
	public function updateContext(c:Dictionary):void {
		if (!context) context = new Dictionary();
		for (var key:String in c) {
			context[key] = c[key];
		}
		for (var i:int = 0; i < numChildren; ++i) {
			var f:VariableTextField = getChildAt(i) as VariableTextField;
			if (f) {
				f.applyContext(context);
			}
		}
	}

	public function addTitle(s:String):void {
		title = makeLabel(Translator.map(s), true);
		addChild(title);
	}

	public function addText(text:String):void {
		for each (var s:String in text.split('\n')) {
			var line:TextField = makeLabel(Translator.map(s));
			addChild(line);
			textLines.push(line);
		}
	}

	public function addWidget(o:DisplayObject):void {
		widget = o;
		addChild(o);
	}

	public function addField(fieldName:String, width:int, defaultValue:* = null, showLabel:Boolean = true):void {
		var l:TextField = null;
		if (showLabel) {
			l = makeLabel(Translator.map(fieldName) + ':');
			addChild(l);
		}
		var f:TextField = makeField(width);
		if (defaultValue != null) f.text = defaultValue;
		addChild(f);
		fields[fieldName] = f;
		labelsAndFields.push([l, f]);
	}

	public function addBoolean(fieldName:String, defaultValue:Boolean = false, isRadioButton:Boolean = false):void {
		var l:TextField = makeLabel(Translator.map(fieldName) + ':');
		addChild(l);
		var f:IconButton = isRadioButton ?
			new IconButton(null, null, null, true) :
			new IconButton(null, getCheckMark(true), getCheckMark(false));
		if (defaultValue) f.turnOn(); else f.turnOff();
		addChild(f);
		booleanFields[fieldName] = f;
		booleanLabelsAndFields.push([l, f]);
	}

	private function getCheckMark(b:Boolean):Sprite{
		var spr:Sprite = new Sprite();
		var g:Graphics = spr.graphics;
		g.clear();
		g.beginFill(0xFFFFFF);
		g.lineStyle(1, 0x929497, 1, true);
		g.drawRoundRect(0, 0, 17, 17, 3, 3);
		g.endFill();
		if (b) {
			g.lineStyle(2, 0x4c4d4f, 1, true);
			g.moveTo(3,7);
			g.lineTo(5,7);
			g.lineTo(8,13);
			g.lineTo(14,3);
		}
		return spr;
	}

	public function addAcceptCancelButtons(acceptLabel:String = null,cancelLabel:String='Cancel'):void {
		// Add a cancel button and an optional accept button with the given label.
		if (acceptLabel != null) addButton(acceptLabel, accept);
		addButton(cancelLabel, cancel);
	}

	public function addButton(label:String, action:Function):void {
		function doAction():void {
			remove();
			if (action != null) action();
		}
		var b:Button = new Button(Translator.map(label), doAction);
		addChild(b);
		buttons.push(b);
	}
	
	public function addInvertedButton(label:String, action:Function):void {
		function doAction():void {
			remove();
			if (action != null) action();
		}
		var b:ButtonInverted = new ButtonInverted(Translator.map(label), doAction);
		addChild(b);
		buttons.push(b);
	}

	public function showOnStage(stage:Stage, center:Boolean = true):void {
		fixLayout();
		if (center) {
			x = (stage.stageWidth - width) / 2;
			y = (stage.stageHeight - height) / 2;
		} else {
			x = stage.mouseX + 10;
			y = stage.mouseY + 10;
		}
		x = Math.max(0, Math.min(x, stage.stageWidth - width));
		y = Math.max(0, Math.min(y, stage.stageHeight - height));
		stage.addChild(this);
		if (labelsAndFields.length > 0) {
			// note: doesn't work when testing from FlexBuilder; works when deployed
			stage.focus = labelsAndFields[0][1];
		}
	}

	public static function findDialogBoxes(targetTitle:String, stage:Stage):Array {
		// Return an array of all dialogs on the stage with the given title.
		// If the given title is null then return all dialogs.
		var result:Array = [];
		if (targetTitle) targetTitle = Translator.map(targetTitle);
		for (var i:int = 0; i < stage.numChildren; i++) {
			var d:DialogBox = stage.getChildAt(i) as DialogBox;
			if (d) {
				if (targetTitle) {
					if (d.title && (d.title.text == targetTitle)) result.push(d);
				} else {
					result.push(d);
				}
			}
		}
		return result;
	}

	public function accept():void {
		if (acceptFunction != null) acceptFunction(this);
		remove();
	}

	public function cancel(e:* = null):void {
		if (cancelFunction != null) cancelFunction(this);
		remove();
	}

	public function getField(fieldName:String):* {
		if (fields[fieldName] != null) return fields[fieldName].text;
		if (booleanFields[fieldName] != null) return booleanFields[fieldName].isOn();
		return null;
	}

	public function setPasswordField(fieldName:String, flag:Boolean = true):void {
		var field:* = fields[fieldName];
		if (field is TextField) {
			(field as TextField).displayAsPassword = flag;
		}
	}

	private function remove():void {
		if (parent != null) parent.removeChild(this);
	}

	private function makeLabel(s:String, forTitle:Boolean = false):TextField {
		const normalFormat:TextFormat = new TextFormat(CSS.font, 14, CSS.textColor);
		var result:VariableTextField = new VariableTextField();
		result.autoSize = TextFieldAutoSize.LEFT;
		result.selectable = false;
		result.background = false;
		result.setText(s, context);
		result.setTextFormat(forTitle ? CSS.titleFormat : normalFormat);
		return result;
	}

	private function makeField(width:int):TextField {
		var result:TextField = new TextField();
		result.selectable = true;
		result.type = TextFieldType.INPUT;
		result.background = true;
		result.border = true;
		result.defaultTextFormat = CSS.normalTextFormat;
		result.width = width;
		result.height = result.defaultTextFormat.size + 8;

		result.backgroundColor = 0xFFFFFF;
		result.borderColor = CSS.borderColor;

		return result;
	}

	public function fixLayout():void {
		var label:TextField;
		var i:int, totalW:int;
		fixSize();
		var fieldX:int = maxLabelWidth + 17;
		var fieldY:int = 15;
		if (title != null) {
			title.x = (w - title.width) / 2;
			title.y = 5;
			fieldY = title.y + title.height + 20;
		}
		if (xButton != null) {
			xButton.x = this.width-20;
			xButton.y = 10;
		}
		// fields
		for (i = 0; i < labelsAndFields.length; i++) {
			label = labelsAndFields[i][0];
			var field:TextField = labelsAndFields[i][1];
			if (label != null) {
				label.x = fieldX - 5 - label.width;
				label.y = fieldY;
			}
			field.x = fieldX;
			field.y = fieldY + 1;
			fieldY += heightPerField;
		}
		// widget
		if (widget != null) {
			widget.x = (width - widget.width) / 2;
			widget.y = fieldY; // (title != null) ? title.y + title.height + 10 : 10;
			fieldY = widget.y + widget.height + 15;
		}
		// boolean fields
		for (i = 0; i < booleanLabelsAndFields.length; i++) {
			label = booleanLabelsAndFields[i][0];
			var ib:IconButton = booleanLabelsAndFields[i][1];
			if (label != null) {
				label.x = fieldX - 5 - label.width;
				label.y = fieldY + 5;
			}
			ib.x = fieldX - 2;
			ib.y = fieldY + 5;
			fieldY += heightPerField;
		}
		// text lines
		for each (var line:TextField in textLines) {
			line.x = leftJustify ? 15 : (w - line.width) / 2;
			line.y = fieldY;
			fieldY += line.height;
			if (line.text.length == 0) fieldY += blankLineSpace;
		}
		if (textLines.length > 0) fieldY += spaceAfterText;
		// buttons
		if (buttons.length > 0) {
			totalW = (buttons.length - 1) * 10;
			for (i = 0; i < buttons.length; i++) totalW += buttons[i].width;
			var buttonX:int = (w - totalW) / 2;
			var buttonY:int = h - (buttons[0].height + 15);
			for (i = 0; i < buttons.length; i++) {
				buttons[i].x = buttonX;
				buttons[i].y = buttonY;
				buttonX += buttons[i].width + 10;
			}
		}
	}

	private function fixSize():void {
		var i:int, totalW:int;
		w = h = 0;
		// title
		if (title != null) {
			w = Math.max(w, title.width);
			h += 10 + title.height;
		}
		// fields
		maxLabelWidth = 0;
		maxFieldWidth = 0;
		for (i = 0; i < labelsAndFields.length; i++) {
			var r:Array = labelsAndFields[i];
			if (r[0] != null) maxLabelWidth = Math.max(maxLabelWidth, r[0].width);
			maxFieldWidth = Math.max(maxFieldWidth, r[1].width);
			h += heightPerField;
		}
		// boolean fields
		for (i = 0; i < booleanLabelsAndFields.length; i++) {
			r = booleanLabelsAndFields[i];
			if (r[0] != null) maxLabelWidth = Math.max(maxLabelWidth, r[0].width);
			maxFieldWidth = Math.max(maxFieldWidth, r[1].width);
			h += heightPerField;
		}
		w = Math.max(w, maxLabelWidth + maxFieldWidth + 5);
		// widget
		if (widget != null) {
			w = Math.max(w, widget.width);
			h += 10 + widget.height;
		}
		// text lines
		for each (var line:TextField in textLines) {
			w = Math.max(w, line.width);
			h += line.height;
			if (line.length == 0) h += blankLineSpace;
		}
		if (textLines.length > 0) h += spaceAfterText;
		// buttons
		totalW = 0;
		for (i = 0; i < buttons.length; i++) totalW += buttons[i].width + 10;
		w = Math.max(w, totalW);
		if (buttons.length > 0) h += buttons[0].height + 15;
		if ((labelsAndFields.length > 0) || (booleanLabelsAndFields.length > 0)) h += 15;
		w += 30;
		h += 10;
		drawBackground();
	}

	private function drawBackground():void {
		var titleBarColors:Array = [0xE0E0E0, 0xD0D0D0]; // old: CSS.titleBarColors;
		var borderColor:int = 0xB0B0B0; // old: CSS.borderColor;
		var g:Graphics = graphics;
		g.clear();
		UIPart.drawTopBar(g, titleBarColors, UIPart.getTopBarPath(w, h), w, CSS.titleBarH, borderColor);
		g.lineStyle(0.5, borderColor, 1, true);
		g.beginFill(0xFFFFFF);
		g.drawRect(0, CSS.titleBarH, w - 1, h - CSS.titleBarH - 1);
	}

	private function addFilters():void {
		var f:DropShadowFilter = new DropShadowFilter();

		f.blurX = f.blurY = 8;
		f.distance = 5;
		f.alpha = 0.75;
		f.color = 0x333333;
		filters = [f];
	}

	/* Events */

	private function focusChange(evt:Event):void {
		evt.preventDefault();
		if (labelsAndFields.length == 0) return;
		var focusIndex:int = -1;
		for (var i:int = 0; i < labelsAndFields.length; i++) {
			if (stage.focus == labelsAndFields[i][1]) focusIndex = i;
		}
		focusIndex++;
		if (focusIndex >= labelsAndFields.length) focusIndex = 0;
		stage.focus = labelsAndFields[focusIndex][1];
	}

	private function mouseDown(evt:MouseEvent):void {if (evt.target == this || evt.target == title) startDrag();}
	private function mouseUp(evt:MouseEvent):void { stopDrag() }

	private function keyDown(evt:KeyboardEvent):void {
		if ((evt.keyCode == 10) || (evt.keyCode == 13)) accept();
		if (evt.keyCode == 27) cancel();
	}

}}
