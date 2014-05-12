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
	import flash.text.*;
	import assets.Resources;
	import translation.Translator;

public class VariableSettings extends Sprite {

	public var isLocal:Boolean;

	public var isList:Boolean;
	private var isStage:Boolean;

	protected var globalButton:IconButton;
	private var globalLabel:TextField;
	protected var localButton:IconButton;
	protected var localLabel:TextField;

	public function VariableSettings(isList:Boolean, isStage:Boolean) {
		this.isList = isList;
		this.isStage = isStage;
		addLabels();
		addButtons();
		fixLayout();
		drawLine();
		updateButtons();
	}

	public static function strings():Array {
		return ['For this sprite only', 'For all sprites', 'list', 'variable'];
	}

	protected function addLabels():void {
		addChild(localLabel = Resources.makeLabel(
			Translator.map('For this sprite only'), CSS.normalTextFormat));

		addChild(globalLabel = Resources.makeLabel(
			Translator.map('For all sprites'), CSS.normalTextFormat));
	}

	protected function addButtons():void {
		function setLocal(b:IconButton):void { isLocal = true; updateButtons() }
		function setGlobal(b:IconButton):void { isLocal = false; updateButtons() }
		addChild(localButton = new IconButton(setLocal, null));
		addChild(globalButton = new IconButton(setGlobal, null));
	}

	protected function updateButtons():void {
		localButton.setOn(isLocal);
		localButton.setDisabled(false, 0.2);
		localLabel.alpha = 1;
		globalButton.setOn(!isLocal);
	}

	protected function fixLayout():void {
		var nextX:int = 0;
		var baseY:int = 10;

		globalButton.x = nextX;
		globalButton.y = baseY + 3;
		globalLabel.x = (nextX += 16);
		globalLabel.y = baseY;

		nextX += globalLabel.textWidth + 20;

		localButton.x = nextX;
		localButton.y = baseY + 3;
		localLabel.x = (nextX += 16);
		localLabel.y = baseY;

		nextX = 15;
		if (isStage) {
			localButton.visible = false;
			localLabel.visible = false;
			globalButton.x = nextX;
			globalLabel.x = nextX + 16;
		}
	}

	private function drawLine():void {
		var lineY:int = 36;
		var w:int = getRect(this).width;
		if (isStage) w += 10;
		var g:Graphics = graphics;
		g.clear();
		g.beginFill(0xD0D0D0);
		g.drawRect(0, lineY, w, 1);
		g.beginFill(0x909090);
		g.drawRect(0, lineY + 1, w, 1);
		g.endFill();
	}
}}