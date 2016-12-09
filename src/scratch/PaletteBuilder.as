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

// PaletteBuilder.as
// John Maloney, September 2010
//
// PaletteBuilder generates the contents of the blocks palette for a given
// category, including the blocks, buttons, and watcher toggle boxes.

package scratch {
import blocks.*;

import extensions.*;

import flash.display.*;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.ColorTransform;
import flash.net.*;
import flash.text.*;

import translation.Translator;

import ui.ProcedureSpecEditor;
import ui.media.MediaLibrary;
import ui.parts.UIPart;

import uiwidgets.*;

public class PaletteBuilder {

	protected var app:Scratch;
	protected var nextY:int;

	public function PaletteBuilder(app:Scratch) {
		this.app = app;
	}

	public static function strings():Array {
		return [
			'Stage selected:', 'No motion blocks',
			'Make a Block', 'Make a List', 'Make a Variable',
			'New List', 'List name', 'New Variable', 'Variable name',
			'New Block', 'Add an Extension'];
	}

	public function showBlocksForCategory(selectedCategory:int, scrollToOrigin:Boolean, shiftKey:Boolean = false):void {
		if (app.palette == null) return;
		app.palette.clear(scrollToOrigin);
		nextY = 7;

		if (selectedCategory == Specs.dataCategory) return showDataCategory();
		if (selectedCategory == Specs.myBlocksCategory) return showMyBlocksPalette(shiftKey);

		var catName:String = Specs.categories[selectedCategory][1];
		var catColor:int = Specs.blockColor(selectedCategory);
		if (app.viewedObj() && app.viewedObj().isStage) {
			// The stage has different blocks for some categories:
			var stageSpecific:Array = ['Control', 'Looks', 'Motion', 'Pen', 'Sensing'];
			if (stageSpecific.indexOf(catName) != -1) selectedCategory += 100;
			if (catName == 'Motion') {
				addItem(makeLabel(Translator.map('Stage selected:')));
				nextY -= 6;
				addItem(makeLabel(Translator.map('No motion blocks')));
				return;
			}
		}
		addBlocksForCategory(selectedCategory, catColor);
		updateCheckboxes();
	}

	private function addBlocksForCategory(category:int, catColor:int):void {
		var cmdCount:int;
		var targetObj:ScratchObj = app.viewedObj();
		for each (var spec:Array in Specs.commands) {
			if ((spec.length > 3) && (spec[2] == category)) {
				var blockColor:int = (app.interp.isImplemented(spec[3])) ? catColor : 0x505050;
				var defaultArgs:Array = targetObj.defaultArgsFor(spec[3], spec.slice(4));
				var label:String = spec[0];
				if (targetObj.isStage && spec[3] == 'whenClicked') label = 'when Stage clicked';
				var block:Block = new Block(label, spec[1], blockColor, spec[3], defaultArgs);
				var showCheckbox:Boolean = isCheckboxReporter(spec[3]);
				if (showCheckbox) addReporterCheckbox(block);
				addItem(block, showCheckbox);
				cmdCount++;
			} else {
				if ((spec.length == 1) && (cmdCount > 0)) nextY += 10 * spec[0].length; // add some space
				cmdCount = 0;
			}
		}
	}

	protected function addItem(o:DisplayObject, hasCheckbox:Boolean = false):void {
		o.x = hasCheckbox ? 23 : 6;
		o.y = nextY;
		app.palette.addChild(o);
		app.palette.updateSize();
		nextY += o.height + 5;
	}

	private function makeLabel(label:String):TextField {
		var t:TextField = new TextField();
		t.autoSize = TextFieldAutoSize.LEFT;
		t.selectable = false;
		t.background = false;
		t.text = label;
		t.setTextFormat(CSS.normalTextFormat);
		return t;
	}

	private function showMyBlocksPalette(shiftKey:Boolean):void {
		// show creation button, hat, and call blocks
		var catColor:int = Specs.blockColor(Specs.procedureColor);
		addItem(new Button(Translator.map('Make a Block'), makeNewBlock, false, '/help/studio/tips/blocks/make-a-block/'));
		var definitions:Array = app.viewedObj().procedureDefinitions();
		if (definitions.length > 0) {
			nextY += 5;
			for each (var proc:Block in definitions) {
				var b:Block = new Block(proc.spec, ' ', Specs.procedureColor, Specs.CALL, proc.defaultArgValues);
				addItem(b);
			}
			nextY += 5;
		}

		addExtensionButtons();
		for each (var ext:* in app.extensionManager.enabledExtensions()) {
			addExtensionSeparator(ext);
			addBlocksForExtension(ext);
		}

		updateCheckboxes();
	}

	protected function addExtensionButtons():void {
		addAddExtensionButton();
		if (Scratch.app.isExtensionDevMode) {
			var extensionDevManager:ExtensionDevManager = Scratch.app.extensionManager as ExtensionDevManager;
			if (extensionDevManager) {
				addItem(extensionDevManager.makeLoadExperimentalExtensionButton());
			}
		}
	}

	protected function addAddExtensionButton():void {
		addItem(new Button(Translator.map('Add an Extension'), showAnExtension, false, '/help/studio/tips/blocks/add-an-extension/'));
	}

	private function showDataCategory():void {
		var catColor:int = Specs.variableColor;
		var getSpec:String = Specs.GET_VAR;

		// variable buttons, reporters, and set/change blocks
		addItem(new Button(Translator.map('Make a Variable'), makeVariable));

		function addBlocks(names:Array):void {
			for each (var n:String in names) {
				addVariableCheckbox(n, getSpec === Specs.GET_LIST);
				addItem(new Block(n, 'r', catColor, getSpec), true);
			}
		}

		var anyVars:Boolean = false;

		if (!(app.viewedObj().isStage)) {
			var localVarNames:Array = app.viewedObj().varNames();
			if (localVarNames.length > 0) {
				addBlocks(localVarNames);
				addSeparator();
				anyVars = true;
			}
		}

		var stageVarNames:Array = app.stageObj().varNames();
		if (stageVarNames.length > 0) {
			addBlocks(stageVarNames);
			anyVars = true;
		}

		if (anyVars) {
			nextY += 10;
			addBlocksForCategory(Specs.dataCategory, catColor);
			nextY += 15;
		}

		// lists
		catColor = Specs.listColor;
		getSpec = Specs.GET_LIST;
		addItem(new Button(Translator.map('Make a List'), makeList));

		var anyLists:Boolean = false;

		if (!(app.viewedObj().isStage)) {
			var localListNames:Array = app.viewedObj().listNames();
			if (localListNames.length > 0) {
				addBlocks(localListNames);
				addSeparator();
				anyLists = true;
			}
		}

		var stageListNames:Array = app.stageObj().listNames();
		if (stageListNames.length > 0) {
			addBlocks(stageListNames);
			nextY += 10;
			anyLists = true;
		}

		if (anyLists) {
			addBlocksForCategory(Specs.listCategory, catColor);
		}

		updateCheckboxes();
	}

	protected function createVar(name:String, varSettings:VariableSettings):* {
		var obj:ScratchObj = (varSettings.isLocal) ? app.viewedObj() : app.stageObj();
		if (obj.hasName(name)) {
			DialogBox.notify("Cannot Add", "That name is already in use.");
			return;
		}
		var variable:* = (varSettings.isList ? obj.lookupOrCreateList(name) : obj.lookupOrCreateVar(name));

		app.runtime.showVarOrListFor(name, varSettings.isList, obj);
		app.setSaveNeeded();

		return variable;
	}

	private function makeVariable():void {
		function makeVar2():void {
			var n:String = d.getField('Variable name').replace(/^\s+|\s+$/g, '');
			if (n.length == 0) return;

			createVar(n, varSettings);
		}

		var d:DialogBox = new DialogBox(makeVar2);
		var varSettings:VariableSettings = makeVarSettings(false, app.viewedObj().isStage);
		d.addTitle('New Variable');
		d.addField('Variable name', 150);
		d.addWidget(varSettings);
		d.addAcceptCancelButtons('OK');
		d.showOnStage(app.stage);
	}

	private function makeList():void {
		function makeList2(d:DialogBox):void {
			var n:String = d.getField('List name').replace(/^\s+|\s+$/g, '');
			if (n.length == 0) return;

			createVar(n, varSettings);
		}

		var d:DialogBox = new DialogBox(makeList2);
		var varSettings:VariableSettings = makeVarSettings(true, app.viewedObj().isStage);
		d.addTitle('New List');
		d.addField('List name', 150);
		d.addWidget(varSettings);
		d.addAcceptCancelButtons('OK');
		d.showOnStage(app.stage);
	}

	protected function makeVarSettings(isList:Boolean, isStage:Boolean):VariableSettings {
		return new VariableSettings(isList, isStage);
	}

	private function makeNewBlock():void {
		function addBlockHat(dialog:DialogBox):void {
			var spec:String = specEditor.spec().replace(/^\s+|\s+$/g, '');
			if (spec.length == 0) return;
			var newHat:Block = new Block(spec, 'p', Specs.procedureColor, Specs.PROCEDURE_DEF);
			newHat.parameterNames = specEditor.inputNames();
			newHat.defaultArgValues = specEditor.defaultArgValues();
			newHat.warpProcFlag = specEditor.warpFlag();
			newHat.setSpec(spec);
			newHat.x = 10 - app.scriptsPane.x + Math.random() * 100;
			newHat.y = 10 - app.scriptsPane.y + Math.random() * 100;
			app.scriptsPane.addChild(newHat);
			app.scriptsPane.saveScripts();
			app.runtime.updateCalls();
			app.updatePalette();
			app.setSaveNeeded();
		}

		var specEditor:ProcedureSpecEditor = new ProcedureSpecEditor('', [], false);
		var d:DialogBox = new DialogBox(addBlockHat);
		d.addTitle('New Block');
		d.addWidget(specEditor);
		d.addAcceptCancelButtons('OK');
		d.showOnStage(app.stage, true);
		specEditor.setInitialFocus();
	}

	private function showAnExtension():void {
		function addExt(ext:ScratchExtension):void {
			if (ext.isInternal) {
				app.extensionManager.setEnabled(ext.name, true);
			} else {
				app.extensionManager.loadCustom(ext);
			}
			app.updatePalette();
		}

		var lib:MediaLibrary = app.getMediaLibrary('extension', addExt);
		lib.open();
	}

	protected function addReporterCheckbox(block:Block):void {
		var b:IconButton = new IconButton(toggleWatcher, 'checkbox');
		b.disableMouseover();
		var targetObj:ScratchObj = isSpriteSpecific(block.op) ? app.viewedObj() : app.stagePane;
		b.clientData = {
			type: 'reporter',
			targetObj: targetObj,
			cmd: block.op,
			block: block,
			color: block.base.color
		};
		b.x = 6;
		b.y = nextY + 5;
		app.palette.addChild(b);
	}

	protected function isCheckboxReporter(op:String):Boolean {
		const checkboxReporters:Array = [
			'xpos', 'ypos', 'heading', 'costumeIndex', 'scale', 'volume', 'timeAndDate',
			'backgroundIndex', 'sceneName', 'tempo', 'answer', 'timer', 'soundLevel', 'isLoud',
			'sensor:', 'sensorPressed:', 'senseVideoMotion', 'xScroll', 'yScroll',
			'getDistance', 'getTilt'];
		return checkboxReporters.indexOf(op) > -1;
	}

	private function isSpriteSpecific(op:String):Boolean {
		const spriteSpecific:Array = ['costumeIndex', 'xpos', 'ypos', 'heading', 'scale', 'volume'];
		return spriteSpecific.indexOf(op) > -1;
	}

	private function getBlockArg(b:Block, i:int):String {
		var arg:BlockArg = b.args[i] as BlockArg;
		if (arg) return arg.argValue;
		return '';
	}

	private function addVariableCheckbox(varName:String, isList:Boolean):void {
		var b:IconButton = new IconButton(toggleWatcher, 'checkbox');
		b.disableMouseover();
		var targetObj:ScratchObj = app.viewedObj();
		if (isList) {
			if (targetObj.listNames().indexOf(varName) < 0) targetObj = app.stagePane;
		} else {
			if (targetObj.varNames().indexOf(varName) < 0) targetObj = app.stagePane;
		}
		b.clientData = {
			type: 'variable',
			isList: isList,
			targetObj: targetObj,
			varName: varName
		};
		b.x = 6;
		b.y = nextY + 5;
		app.palette.addChild(b);
	}

	private function toggleWatcher(b:IconButton):void {
		var data:Object = b.clientData;
		if (data.block) {
			switch (data.block.op) {
				case 'senseVideoMotion':
					data.targetObj = getBlockArg(data.block, 1) == 'Stage' ? app.stagePane : app.viewedObj();
				case 'sensor:':
				case 'sensorPressed:':
				case 'timeAndDate':
					data.param = getBlockArg(data.block, 0);
					break;
			}
		}
		var showFlag:Boolean = !app.runtime.watcherShowing(data);
		app.runtime.showWatcher(data, showFlag);
		b.setOn(showFlag);
		app.setSaveNeeded();
	}

	private function updateCheckboxes():void {
		for (var i:int = 0; i < app.palette.numChildren; i++) {
			var b:IconButton = app.palette.getChildAt(i) as IconButton;
			if (b && b.clientData) {
				b.setOn(app.runtime.watcherShowing(b.clientData));
			}
		}
	}

	protected function getExtensionMenu(ext:ScratchExtension):Menu {
		function showAbout():void {
			if (ext.isInternal) {
				// Internal extensions are handled specially by tip-bar.js
				app.showTip('ext:' + ext.name);
			}
			else if (ext.url) {
				// Open in the tips window if the URL starts with /info/ and another tab otherwise
				if (ext.url.indexOf('/info/') === 0) app.showTip(ext.url);
				else if (ext.url.indexOf('http') === 0) navigateToURL(new URLRequest(ext.url));
				else DialogBox.notify('Extensions', 'Unable to load about page: the URL given for extension "' + ext.displayName + '" is not formatted correctly.');
			}
		}

		function hideExtension():void {
			app.extensionManager.setEnabled(ext.name, false);
			app.updatePalette();
		}

		var m:Menu = new Menu();
		m.addItem(Translator.map('About') + ' ' + ext.displayName + ' ' + Translator.map('extension') + '...', showAbout, !!ext.url);
		m.addItem('Remove extension blocks', hideExtension);

		var extensionDevManager:ExtensionDevManager = Scratch.app.extensionManager as ExtensionDevManager;

		if (!ext.isInternal && extensionDevManager) {
			m.addLine();
			var localFileName:String = extensionDevManager.getLocalFileName(ext);
			if (localFileName) {
				if (extensionDevManager.isLocalExtensionDirty()) {
					m.addItem('Load changes from ' + localFileName, function ():void {
						extensionDevManager.loadLocalCode();
					});
				}
				m.addItem('Disconnect from ' + localFileName, function ():void {
					extensionDevManager.stopWatchingExtensionFile();
				});
			}
		}

		return m;
	}

	protected const pwidth:int = 215;

	protected function addExtensionSeparator(ext:ScratchExtension):void {
		function extensionMenu(ignore:*):void {
			var m:Menu = getExtensionMenu(ext);
			m.showOnStage(app.stage);
		}

		nextY += 7;

		var titleButton:IconButton = UIPart.makeMenuButton(ext.displayName, extensionMenu, true, CSS.textColor);
		titleButton.x = 5;
		titleButton.y = nextY;
		app.palette.addChild(titleButton);

		addLineForExtensionTitle(titleButton, ext);

		var indicator:IndicatorLight = new IndicatorLight(ext);
		indicator.addEventListener(MouseEvent.CLICK, function (e:Event):void {
			Scratch.app.showTip('extensions');
		}, false, 0, true);
		app.extensionManager.updateIndicator(indicator, ext);
		indicator.x = pwidth - 40;
		indicator.y = nextY + 2;
		app.palette.addChild(indicator);

		nextY += titleButton.height + 10;

		var extensionDevManager:ExtensionDevManager = Scratch.app.extensionManager as ExtensionDevManager;
		if (extensionDevManager) {
			// Show if this extension is being updated by a file
			var fileName:String = extensionDevManager.getLocalFileName(ext);
			if (fileName) {
				var extensionEditStatus:TextField = UIPart.makeLabel('Connected to ' + fileName, CSS.normalTextFormat, 8, nextY - 5);
				app.palette.addChild(extensionEditStatus);

				nextY += extensionEditStatus.textHeight + 3;
			}
		}
	}

	[Embed(source='../assets/reload.png')]
	private static const reloadIcon:Class;

	protected function addLineForExtensionTitle(titleButton:IconButton, ext:ScratchExtension):void {
		var x:int = titleButton.width + 12;
		var w:int = pwidth - x - 48;
		var extensionDevManager:ExtensionDevManager = Scratch.app.extensionManager as ExtensionDevManager;
		var dirty:Boolean = extensionDevManager && extensionDevManager.isLocalExtensionDirty(ext);
		if (dirty)
			w -= 15;
		addLine(x, nextY + 9, w);

		if (dirty) {
			var reload:Bitmap = new reloadIcon();
			reload.scaleX = 0.75;
			reload.scaleY = 0.75;
			var reloadBtn:Sprite = new Sprite();
			reloadBtn.addChild(reload);
			reloadBtn.x = x + w + 6;
			reloadBtn.y = nextY + 2;
			app.palette.addChild(reloadBtn);
			SimpleTooltips.add(reloadBtn, {
				text: 'Click to load changes (running old code from ' + extensionDevManager.getLocalCodeDate() + ')',
				direction: 'top'
			});

			reloadBtn.addEventListener(MouseEvent.MOUSE_DOWN, function (e:MouseEvent):void {
				SimpleTooltips.hideAll();
				extensionDevManager.loadLocalCode();
			});

			reloadBtn.addEventListener(MouseEvent.ROLL_OVER, function (e:MouseEvent):void {
				reloadBtn.transform.colorTransform = new ColorTransform(2, 2, 2);
			});

			reloadBtn.addEventListener(MouseEvent.ROLL_OUT, function (e:MouseEvent):void {
				reloadBtn.transform.colorTransform = new ColorTransform();
			});
		}
	}

	private function addBlocksForExtension(ext:ScratchExtension):void {
		var blockColor:int = Specs.extensionsColor;
		var opPrefix:String = ext.useScratchPrimitives ? '' : ext.name + ExtensionManager.extensionSeparator;
		for each (var spec:Array in ext.blockSpecs) {
			if (spec.length >= 3) {
				var op:String = opPrefix + spec[2];
				var defaultArgs:Array = spec.slice(3);
				var block:Block = new Block(spec[1], spec[0], blockColor, op, defaultArgs);
				var showCheckbox:Boolean = (block.isReporter && !block.isRequester && defaultArgs.length == 0);
				if (showCheckbox) addReporterCheckbox(block);
				addItem(block, showCheckbox);
			} else {
				if (spec.length == 1) nextY += 10 * spec[0].length; // add some space
			}
		}
	}

	protected function addLine(x:int, y:int, w:int):void {
		const light:int = 0xF2F2F2;
		const dark:int = CSS.borderColor - 0x141414;
		var line:Shape = new Shape();
		var g:Graphics = line.graphics;

		g.lineStyle(1, dark, 1, true);
		g.moveTo(0, 0);
		g.lineTo(w, 0);

		g.lineStyle(1, light, 1, true);
		g.moveTo(0, 1);
		g.lineTo(w, 1);
		line.x = x;
		line.y = y;
		app.palette.addChild(line);
	}

	private function addSeparator():void {
		nextY += 4;
		addLine(6, nextY, pwidth - 30);
		nextY += 8;
	}

}
}
