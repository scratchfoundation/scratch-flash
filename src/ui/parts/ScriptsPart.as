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

// ScriptsPart.as
// John Maloney, November 2011
//
// This part holds the palette and scripts pane for the current sprite (or stage).

package ui.parts {
	import flash.display.*;
	import ui.parts.base.BaseScriptsPart;

public class ScriptsPart extends BaseScriptsPart {

	public function ScriptsPart(app:Scratch) {
		super(app);
	}

	override public function setWidthHeight(w:int, h:int):void {
		super.setWidthHeight(w, h);
		fixlayout();
		redraw();
	}

	protected function fixlayout():void {
		selector.x = 1;
		selector.y = 5;
		paletteFrame.x = selector.x;
		paletteFrame.y = selector.y + selector.height + 2;
		paletteFrame.setWidthHeight(selector.width + 1, h - paletteFrame.y - 2); // 5
		scriptsFrame.x = selector.x + selector.width + 2;
		scriptsFrame.y = selector.y + 1;
		scriptsFrame.setWidthHeight(w - scriptsFrame.x - 5, h - scriptsFrame.y - 5);
		spriteWatermark.x = w - 60;
		spriteWatermark.y = scriptsFrame.y + 10;
		xyDisplay.x = spriteWatermark.x + 1;
		xyDisplay.y = spriteWatermark.y + 43;
		zoomWidget.x = w - zoomWidget.width - 15;
		zoomWidget.y = h - zoomWidget.height - 15;
	}

	protected function redraw():void {
		var paletteW:int = paletteFrame.visibleW();
		var paletteH:int = paletteFrame.visibleH();
		var scriptsW:int = scriptsFrame.visibleW();
		var scriptsH:int = scriptsFrame.visibleH();

		var g:Graphics = shape.graphics;
		g.clear();
		g.lineStyle(1, CSS.borderColor, 1, true);
		g.beginFill(CSS.tabColor);
		g.drawRect(0, 0, w, h);
		g.endFill();

		var lineY:int = selector.y + selector.height;
		var darkerBorder:int = CSS.borderColor - 0x141414;
		var lighterBorder:int = 0xF2F2F2;
		g.lineStyle(1, darkerBorder, 1, true);
		hLine(g, paletteFrame.x + 8, lineY, paletteW - 20);
		g.lineStyle(1, lighterBorder, 1, true);
		hLine(g, paletteFrame.x + 8, lineY + 1, paletteW - 20);

		g.lineStyle(1, darkerBorder, 1, true);
		g.drawRect(scriptsFrame.x - 1, scriptsFrame.y - 1, scriptsW + 1, scriptsH + 1);
	}

	private function hLine(g:Graphics, x:int, y:int, w:int):void {
		g.moveTo(x, y);
		g.lineTo(x + w, y);
	}
}}
