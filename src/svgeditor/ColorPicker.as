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

package svgeditor {
	import flash.display.*;
	import flash.events.*;
	import flash.filters.GlowFilter;
	import flash.geom.*;
	import flash.utils.Dictionary;
	import assets.Resources;
	import uiwidgets.*;
	import util.Color;

public class ColorPicker extends Sprite {

	private var editor:ImageEdit;
	private var drawPropsUI:DrawPropertyUI;
	private var gradientMode:Boolean;

	// UI elements
	private var palette:Sprite;
	private var wheelSelector:Shape;
	private var hsvColorPicker:Sprite;
	private var paletteSwitchButton:Sprite;
	private var primaryColorSwatch:Sprite;
	private var secondaryColorSwatch:Sprite;

	// Color mapping
	private var paletteDict:Dictionary;
	private var paletteReverseDict:Dictionary;

	// Selected and transparent color boxes in palette
	private var selectedColor:Sprite;
	private var transparentColor:Sprite;

	public function ColorPicker(editor:ImageEdit, drawPropsUI:DrawPropertyUI) {
		this.editor = editor;
		this.drawPropsUI = drawPropsUI;

		makeColorSwatches();
		makeEyeDropperButton();
		makeColorPalette();
		makeColorWheel();
		makePaletteSwitchButton();
		pickColor();
	}

	public static function strings():Array {
		return ['Pick up color'];
	}

	private function makeEyeDropperButton():void {
		function selectEyedropper(b:IconButton):void {
			editor.setToolMode(b.name);
			if (b && b.lastEvent) b.lastEvent.stopPropagation();
		}
		var ib:IconButton = new IconButton(
			selectEyedropper,
			ImageEdit.makeToolButton('eyedropper', true),
			ImageEdit.makeToolButton('eyedropper', false),
			true);
		editor.registerToolButton('eyedropper', ib);
		ib.x = primaryColorSwatch.x + 163;
		ib.y = 0;
		addChild(ib);
		SimpleTooltips.add(ib, {text: 'Pick up color', direction: 'top'});
	}

	private function makePaletteSwitchButton():void {
		paletteSwitchButton = new Sprite();

		var spr:Sprite = new Sprite();
		var bmp:Bitmap = Resources.createBmp('rainbowButton');
		spr.addChild(bmp);
		paletteSwitchButton.addChild(spr);

		spr = new Sprite();
		bmp = Resources.createBmp('swatchButton');
		spr.visible = false;
		spr.addChild(bmp);
		paletteSwitchButton.addChild(spr);

		paletteSwitchButton.addEventListener(MouseEvent.CLICK, switchPalettes);
		paletteSwitchButton.x = primaryColorSwatch.x;
		paletteSwitchButton.y = 64;
		addChild(paletteSwitchButton);
	}

	private function switchPalettes(evt:MouseEvent):void {
		palette.visible = !palette.visible;
		hsvColorPicker.visible = !palette.visible;
		paletteSwitchButton.getChildAt(0).visible = palette.visible;
		paletteSwitchButton.getChildAt(1).visible = !palette.visible;
		if (hsvColorPicker.visible) {
			//pickWheelColor();
		}
		SimpleTooltips.hideAll();
	}

	private function makeColorSwatches():void {
		function swapColors(e:*):void {
			var props:DrawProperties = drawPropsUI.settings;
			var tmp:int = props.rawColor;
			props.rawColor = props.rawSecondColor;
			props.rawSecondColor = tmp;
			drawPropsUI.sendChangeEvent();
			updateSwatches();
		}
		primaryColorSwatch = new Sprite();
		primaryColorSwatch.x = 0;
		primaryColorSwatch.y = 1;

		secondaryColorSwatch = new Sprite();
		secondaryColorSwatch.x = primaryColorSwatch.x + 11;
		secondaryColorSwatch.y = primaryColorSwatch.y + 11;
		addChild(secondaryColorSwatch); // behind primary
		addChild(primaryColorSwatch);

		primaryColorSwatch.addEventListener(MouseEvent.MOUSE_DOWN, swapColors);
		secondaryColorSwatch.addEventListener(MouseEvent.MOUSE_DOWN, swapColors);

		updateSwatches();
	}

	public function setGradientMode(flag:Boolean):void {
		// TODO: show or hide the gradient colors and preview
		gradientMode = flag;
	}

	public function pickColor():void {
		var color:Sprite = null;
		var a:Number = drawPropsUI.settings.alpha;
		if (a == 0.0) {
			color = transparentColor;
		} else {
			var col:uint = drawPropsUI.settings.color;
			color = paletteReverseDict[col];
		}
		updateSwatches();

		if (selectedColor) drawColorSelector(selectedColor); // clear the old color selection
		if (color) drawColorSelector(color, true); // highlight the new selection
		selectedColor = color;

		//if (hsvColorPicker.visible) pickWheelColor();
	}

	private function pickWheelColor():void {
		//trace('pickWheelColor()');
		// Convert current color to HSV to find it
		var hsv:Array = Color.rgb2hsv(drawPropsUI.settings.color);
		var bmp:Bitmap = hsvColorPicker.getChildAt(0) as Bitmap;
		setColorByHSVPos(new Point((bmp.bitmapData.width-1) * hsv[0] / 360, (bmp.bitmapData.height-1) * hsv[1]), false);

		// Now set the brightness
		(hsvColorPicker.getChildAt(1) as Slider).value = hsv[2];
		setHSVBrightness(hsv[2], false);
	}

	private function updateSwatches():void {
		var props:DrawProperties = drawPropsUI.settings;
		drawSwatch(primaryColorSwatch.graphics, props.color, props.alpha);
		drawSwatch(secondaryColorSwatch.graphics, props.secondColor, props.secondAlpha);
	}

	private const swatchSize:int = 25;

	private function drawSwatch(g:Graphics, color:uint, alpha:Number):void {
		const radius:int = 6;
		g.clear();
		// fill
		g.lineStyle(); // no border
		if (alpha == 0) color = 0xFFFFFF;
		g.beginFill(color);
		g.drawRoundRect(0, 0, swatchSize, swatchSize, radius, radius);
		g.endFill();
		// red slash for transparent
		if (alpha == 0) {
			const corner:int = swatchSize - 2;
			g.lineStyle(2, 0xFF0000);
			g.moveTo(corner, 2);
			g.lineTo(2, corner);
		}
		// light gray border
		g.lineStyle(2, 0xCCCCCC, 0.8, true);
		g.drawRoundRect(0, 0, swatchSize, swatchSize, radius, radius);
	}

	public function setCurrentColor(color:uint, alpha:Number, pick:Boolean = true):void {
		var argb:uint = (alpha * 255) << 24 | color;
		drawPropsUI.settings.color = argb;
		updateSwatches();
		// Highlight the color picked
		if (pick) {
			pickColor();
			if (hsvColorPicker.visible) pickWheelColor();
		}
	}

	private function setColor(e:MouseEvent):void {
		// Update fill and stroke buttons
		var color:uint = 0;
		var alpha:Number = 1.0;
		if (e.target != transparentColor) {
			color = paletteDict[e.target];
		} else {
			alpha = 0;
		}
		setCurrentColor(color, alpha);
		drawPropsUI.sendChangeEvent();
		//pickWheelColor();
	}

	/* Continuous Color Picker */

	private function makeColorWheel():void {
		makeHSVColorPicker(96, 94);
		addChild(hsvColorPicker);

		hsvColorPicker.x = primaryColorSwatch.getRect(this).right + 20;

		wheelSelector = new Shape();
		wheelSelector.graphics.lineStyle(2);
		wheelSelector.graphics.drawCircle(0, 0, 5);
		wheelSelector.x = 30;
		wheelSelector.y = 30;
		hsvColorPicker.addChild(wheelSelector);

		hsvColorPicker.addEventListener(MouseEvent.MOUSE_DOWN, setWheelColor);
		hsvColorPicker.visible = false;
	}

	private function makeHSVColorPicker(w:int, h:int):void {
		hsvColorPicker = new Sprite;
		var hueFactor:Number = 360 / w;
		var bmd:BitmapData = new BitmapData(w, h, false);
		for (var i:uint = 0; i < w; i++)
			for (var j:uint = 0; j < h; j++)
				bmd.setPixel(i, j, Color.fromHSV(i * hueFactor, j / h, 1));

		hsvColorPicker.addChild(new Bitmap(bmd));

		var slider:Slider = new Slider(6, h, setHSVBrightness);
		slider.slotColor = 0x202020;
		slider.slotColor2 = 0xD0D0D0;
		slider.setWidthHeight(6, h); // redraw with gradient
		slider.value = 1;
		slider.x = w + 5;
		slider.y = 0;
		hsvColorPicker.addChild(slider);
	}

	private function setHSVBrightness(value:Number, updateColor:Boolean = true):void {
		hsvColorPicker.getChildAt(0).transform.colorTransform = new ColorTransform(value, value, value);
		setColorByHSVPos(new Point(wheelSelector.x, wheelSelector.y), updateColor);
	}

	private function setWheelColor(evt:MouseEvent):void {
		if (evt.type == MouseEvent.MOUSE_DOWN) {
			stage.addEventListener(MouseEvent.MOUSE_MOVE, setWheelColor);
			stage.addEventListener(MouseEvent.MOUSE_UP, setWheelColor);
		} else if (evt.type == MouseEvent.MOUSE_UP) {
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, setWheelColor);
			stage.removeEventListener(MouseEvent.MOUSE_UP, setWheelColor);
		}
		if (evt.type != MouseEvent.MOUSE_UP) {
			setColorByHSVPos(new Point(hsvColorPicker.mouseX,hsvColorPicker.mouseY));
		}
	}

	private function setColorByHSVPos(pos:Point, updateColor:Boolean = true):void {
		var inBounds:Boolean = hsvColorPicker.getChildAt(0).getBounds(hsvColorPicker).contains(pos.x, pos.y);
		if (inBounds) {
			wheelSelector.visible = true;
			wheelSelector.x = pos.x;
			wheelSelector.y = pos.y;

			if (updateColor) {
				var b:BitmapData = new BitmapData(1, 1, true, 0);
				var m:Matrix = new Matrix();
				m.translate(-pos.x, -pos.y);
				b.draw(hsvColorPicker, m);
				setCurrentColor(b.getPixel32(0, 0), 1, false);
				drawPropsUI.sendChangeEvent();
			}
		}
	}

	/* New (Scratch 1.4 Color Palette */

	private const paletteSwatchW:int = 12;
	private const paletteSwatchH:int = 12;

	private function makeColorPalette():void {
		addChild(palette = new Sprite());

		paletteDict = new Dictionary();
		paletteReverseDict = new Dictionary();
		var leftSide:uint = primaryColorSwatch.getRect(this).right + 20;

		// Make the grey-scale colors
		const grays:Array = [0.0, 0.4, 0.5, 0.7, 0.8, 0.9, 1.0];
		var i:uint, sel:Sprite;
		var stride:uint = paletteSwatchW + 2;
		for (i = 0; i < grays.length; ++i) {
			sel = makeColorSelector( Color.fromHSV(0, 0, grays[i]) );
			sel.x = i * stride + leftSide;
			sel.y = 0;
			palette.addChild(sel);
		}

		// Make the transparent 'color'
		sel = makeColorSelector(0xFFFFFF, true);
		sel.x = i * stride + leftSide;
		palette.addChild(sel);
		++i;

		// Make the palette
		const hues:Array = [0, 35, 60, 140, 180, 225, 270, 315];
		const rowHeight:int = paletteSwatchH + 2;
		var y:Number = rowHeight;
		var h:Number, s:Number, v:Number;

		for each (s in [0.2, 0.4, 1]) {
			for each (h in hues) {
				sel = makeColorSelector( Color.fromHSV(h, s, 1.0) );
				sel.x = (i % hues.length) * stride + leftSide;
				sel.y = y;
				palette.addChild(sel);
				++i;
			}
			y += rowHeight;
		}

		for each (v in [0.8, 0.6, 0.4]) {
			for each (h in hues) {
				sel = makeColorSelector( Color.fromHSV(h, 1.0, v) );
				sel.x = (i % hues.length) * stride + leftSide;
				sel.y = y;
				palette.addChild(sel);
				++i;
			}
			y += rowHeight;
		}
	}

	private function makeColorSelector(color:uint, isTransparent:Boolean = false):Sprite {
		var s:Sprite = new Sprite();
		if (!isTransparent) {
			paletteDict[s] = color;
			paletteReverseDict[color] = s;
		} else {
			// don't add transparent to the dictionary
			transparentColor = s;
		}
		s.addEventListener(MouseEvent.MOUSE_DOWN, setColor);
		drawColorSelector(s);
		return s;
	}

	private function drawColorSelector(spr:Sprite, highlight:Boolean = false):void {
		highlight = false; // disable highlight

		var g:Graphics = spr.graphics;
		var color:uint = (spr == transparentColor ? 0xFFFFFF : paletteDict[spr]);
		var coords:Array = [0, 0, paletteSwatchW, paletteSwatchH];
		g.clear();
		if (spr == transparentColor) {
			g.lineStyle(2, 0xFF0000);
			g.moveTo(paletteSwatchW - 1, 1);
			g.lineTo(1, paletteSwatchH - 1);
		}

		if (highlight) g.lineStyle(2, 0, 1);
		else g.lineStyle(0, 0, 0);

		if (spr == transparentColor) g.beginFill(0, 0);
		else g.beginFill(color);

		g.drawRect.apply(g, coords);
		g.endFill();
		spr.filters = highlight ? [new GlowFilter(0xFFFFFF, 1, 5, 5)] : [];
		if (highlight) palette.setChildIndex(spr, 0);
	}

}}
