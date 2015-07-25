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
	import flash.display.Sprite;

public class HighlightWidget extends Sprite {

	private var app:Scratch;

	private var prev:IconButton;
	private var clear:IconButton;
	private var next:IconButton;

	public function HighlightWidget(app:Scratch) {
		this.app = app;
		addChild(prev = new IconButton(highlightPrev, 'prev'));
		addChild(next = new IconButton(highlightNext, 'next'));
		addChild(clear = new IconButton(highlightClear, 'clear'));
		prev.x = 0;
		clear.x = 26;
		clear.y = 5;
		next.x = 32;
		prev.isMomentary = true;
		clear.isMomentary = true;
		next.isMomentary = true;
		// not sure about these since they feel a bit 'in the way' - but just 'cos it's so simple to do...
		SimpleTooltips.add(prev, {text: 'previous highlight', direction: 'top'});
		SimpleTooltips.add(next, {text: 'next highlight', direction: 'top'});
		SimpleTooltips.add(clear, {text: 'clear highlights', direction: 'top'});
	}

	public function hiding():void { // chance to remove any tooltips
		SimpleTooltips.hideAll();
	}

	// I think the tooltips just get in the way once a button is clicked...
	private function highlightPrev(b:IconButton):void {
		SimpleTooltips.hideAll();
		app.scriptsPane.prevHighlightBlock(null);
	}
	private function highlightClear(b:IconButton):void {
		SimpleTooltips.hideAll();
		app.scriptsPane.clearBlockHighlights();
		app.highlightSprites([]);
	}
	private function highlightNext(b:IconButton):void {
		SimpleTooltips.hideAll();
		app.scriptsPane.nextHighlightBlock(null);
	}

}}
