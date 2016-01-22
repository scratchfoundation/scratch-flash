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

// IconButton.as
// John Maloney, December 2010
//
// An IconButton is a button that draws itself using an image. An optional second
// image can be used to display the on/off state of the button. If the 'isRadioButton'
// flag is set, then turning on one IconButton will turn off all other IconButton
// children of its parent that also have 'isRadioButton' set. (That is, only one of
// the radio button children of a given parent can be on.) The optional clickFunction
// is called when the user clicks on the IconButton.

package uiwidgets {
import assets.Resources;

import flash.display.*;
import flash.events.MouseEvent;
import flash.text.*;

public class IconButton extends Sprite {

	public var clickFunction:Function;
	public var isRadioButton:Boolean; // if true then other button children of my parent will be turned off when I'm
                                      // turned on
	public var isMomentary:Boolean; // if true then button does not remain on when clicked
	public var lastEvent:MouseEvent;
	public var clientData:*;

	private var buttonIsOn:Boolean;
	private var mouseIsOver:Boolean;
	private var onImage:DisplayObject;
	private var offImage:DisplayObject;

	public function IconButton(clickFunction:Function, onImageOrName:*, offImageObj:DisplayObject = null,
	                           isRadioButton:Boolean = false) {
		this.clickFunction = clickFunction;
		this.isRadioButton = isRadioButton;
		useDefaultImages();
		setImage(onImageOrName, offImageObj);
		addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		addEventListener(MouseEvent.MOUSE_OVER, mouseOver);
		addEventListener(MouseEvent.MOUSE_OUT, mouseOut);
		mouseChildren = false;
	}

	public function actOnMouseUp():void {
		removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		addEventListener(MouseEvent.MOUSE_UP, mouseDown);
	}

	public function disableMouseover():void {
		removeEventListener(MouseEvent.MOUSE_OVER, mouseOver);
		removeEventListener(MouseEvent.MOUSE_OUT, mouseOut);
	}

	public function setImage(onImageObjOrName:*, offImageObj:DisplayObject = null):void {
		if (onImageObjOrName is String) {
			// specify on/off images by asset name
			var assetName:String = onImageObjOrName;
			onImage = Resources.createBmp(assetName + 'On');
			offImage = Resources.createBmp(assetName + 'Off');
		}
		else if (onImageObjOrName is DisplayObject) {
			// on/off images are supplied
			onImage = onImageObjOrName as DisplayObject;
			offImage = (offImageObj == null) ? onImage : offImageObj; // offImage is optional
		}
		redraw();
	}

	public function turnOff():void {
		if (!buttonIsOn) return;
		buttonIsOn = false;
		redraw();
	}

	public function turnOn():void {
		if (buttonIsOn) return;
		buttonIsOn = true;
		redraw();
	}

	public function setOn(flag:Boolean):void {
		if (flag) turnOn();
		else turnOff();
	}

	public function isOn():Boolean { return buttonIsOn }
	public function right():int { return x + width }
	public function bottom():int { return y + height }

	public function isDisabled():Boolean { return alpha < 1 };
	public function setDisabled(disabledFlag:Boolean, disabledAlpha:Number = 0.0,
	                            disabledImg:DisplayObject = null):void {
		alpha = disabledFlag ? disabledAlpha : 1;
		if (disabledFlag) {
			mouseIsOver = false;
			turnOff();
		}
		if (disabledImg) {
			offImage = disabledImg;
			redraw();
		}
		mouseEnabled = !disabledFlag;
	};

	public function setLabel(s:String, onColor:int, offColor:int, dropDownArrow:Boolean = false):void {
		// Set my off/on images to the given string and colors.
		// If dropDownArrow, add a drop-down arrow after the label.
		setImage(
				makeLabelSprite(s, offColor, dropDownArrow), makeLabelSprite(s, onColor, dropDownArrow));
		isMomentary = true;
	}

	private function makeLabelSprite(s:String, labelColor:int, dropDownArrow:Boolean):Sprite {
		var label:TextField = Resources.makeLabel(s, CSS.topBarButtonFormat);
		label.textColor = labelColor;
		var img:Sprite = new Sprite();
		img.addChild(label);
		if (dropDownArrow) img.addChild(menuArrow(label.textWidth + 6, 6, labelColor));
		return img;
	}

	private function menuArrow(x:int, y:int, c:int):Shape {
		var arrow:Shape = new Shape();
		var g:Graphics = arrow.graphics;
		g.beginFill(c);
		g.lineTo(8, 0);
		g.lineTo(4, 6)
		g.lineTo(0, 0);
		g.endFill();
		arrow.x = x;
		arrow.y = y;
		return arrow;
	}

	private function redraw():void {
		var img:DisplayObject = buttonIsOn ? onImage : offImage;
		if (mouseIsOver && !buttonIsOn) img = onImage;
		while (numChildren > 0) removeChildAt(0);
		addChild(img);
		// Make the entire button rectangle be mouse-sensitive:
		graphics.clear();
		graphics.beginFill(0xA0, 0); // invisible but mouse-sensitive; min size 10x10
		graphics.drawRect(0, 0, Math.max(10, img.width), Math.max(10, img.height));
		graphics.endFill();
	}

	private function mouseDown(e:MouseEvent):void {
		if (isDisabled()) return;
		if (CursorTool.tool == 'help') return; // ignore mouseDown events with help tool (this doesn't apply to
	                                           // 'actOnMouseUp' buttons)
		if (isRadioButton) {
			if (buttonIsOn) return;  // user must click on another radio button to turn this button off
			turnOffOtherRadioButtons();
		}
		buttonIsOn = !buttonIsOn;
		redraw();
		if (clickFunction != null) {
			lastEvent = e;
			clickFunction(this);
			lastEvent = null;
		}
		if (isMomentary) buttonIsOn = false;
		else mouseIsOver = false;
		redraw();
	}

	private function mouseOver(evt:MouseEvent):void {
		if (!isDisabled()) {
			mouseIsOver = true;
			redraw()
		}
	}
	private function mouseOut(evt:MouseEvent):void {
		if (!isDisabled()) {
			mouseIsOver = false;
			redraw()
		}
	}

	private function turnOffOtherRadioButtons():void {
		if (parent == null) return;
		for (var i:int = 0; i < parent.numChildren; i++) {
			var b:* = parent.getChildAt(i);
			if ((b is IconButton) && (b.isRadioButton) && (b != this)) b.turnOff();
		}
	}

	private function useDefaultImages():void {
		// Use default images (empty and filled circles, appropriate for a radio button)
		const color:int = 0x373737;
		offImage = new Sprite();
		var g:Graphics = Sprite(offImage).graphics;
		g.lineStyle(1, color);
		g.beginFill(0, 0); // transparent fill allows button to get mouse clicks
		g.drawCircle(6, 6, 6);
		onImage = new Sprite();
		g = Sprite(onImage).graphics;
		g.lineStyle(1, color);
		g.beginFill(0, 0); // transparent fill allows button to get mouse clicks
		g.drawCircle(6, 6, 6);
		g.beginFill(color);
		g.drawCircle(6, 6, 4);
		g.endFill();
	}

}
}
