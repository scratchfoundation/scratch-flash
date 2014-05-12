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

package ui {
	import flash.display.*;
	import flash.filters.DropShadowFilter;
	import flash.text.*;
	import assets.Resources;
	import translation.Translator;

public class LoadProgress extends Sprite {

	private const titleFormat:TextFormat = new TextFormat(CSS.font, 18, CSS.textColor);
	private const infoFormat:TextFormat = new TextFormat(CSS.font, 12, CSS.textColor);
	private const grooveColor:int = 0xB9BBBD;

	private var bkg:Shape;
	private var titleField:TextField;
	private var infoField:TextField;
	private var groove:Shape;
	private var progressBar:Shape;

	public function LoadProgress():void {
		addBackground(310, 120);
		addChild(titleField = Resources.makeLabel('', titleFormat, 20, bkg.height - 61));
		addChild(infoField = Resources.makeLabel('', infoFormat, 20, bkg.height - 35));

		addChild(groove = new Shape());
		addChild(progressBar = new Shape());
		groove.x = progressBar.x = 30;
		groove.y = progressBar.y = 25;

		drawBar(groove.graphics, grooveColor, 250, 22)
	}

	public function getTitle():String { return titleField.text }

	public function setTitle(s:String):void {
		titleField.text = Translator.map(s);
		titleField.x = (bkg.width - titleField.textWidth) / 2;
		infoField.text = ''; // clear old info when title changes
	}

	public function setInfo(s:String):void {
		infoField.text = Translator.map(s);
		infoField.x = (bkg.width - infoField.textWidth) / 2;
	}

	public function setProgress(p:Number):void {
		drawBar(progressBar.graphics, CSS.overColor, Math.floor(groove.width * p), groove.height);
	}

	private function addBackground(w:int, h:int):void {
		addChild(bkg = new Shape());

		var g:Graphics = bkg.graphics;
		g.clear();
		g.lineStyle(1, CSS.borderColor, 1, true);
		g.beginFill(0xFFFFFF);
		g.drawRoundRect(0, 0, w, h, 24, 24);
		g.endFill();

		var f:DropShadowFilter = new DropShadowFilter();
		f.blurX = f.blurY = 8;
		f.distance = 5;
		f.alpha = 0.75;
		f.color = 0x333333;
		bkg.filters = [f];
	}

	private function drawBar(g:Graphics, c:uint, w:int, h:int):void {
		var radius:int = h / 2;
		g.clear();
		g.beginFill(c);
		g.drawRoundRect(0, 0, w, h, radius, radius);
		g.endFill();
	}

}}
