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

// SpriteInfoPart.as
// John Maloney, November 2011
//
// This part shows information about the currently selected object (the stage or a sprite).

package ui.parts {
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.text.*;
	import scratch.*;
	import translation.Translator;
	import uiwidgets.*;
	import util.DragClient;
	import watchers.ListWatcher;

public class SpriteInfoPart extends UIPart implements DragClient {

	private const readoutLabelFormat:TextFormat = new TextFormat(CSS.font, 12, 0xA6A8AB, true);
	private const readoutFormat:TextFormat = new TextFormat(CSS.font, 12, 0xA6A8AB);

	private var shape:Shape;

	// sprite info parts
	private var closeButton:IconButton;
	private	var thumbnail:Bitmap;
	private var spriteName:EditableLabel;

	private var xReadoutLabel:TextField;
	private var yReadoutLabel:TextField;
	private var xReadout:TextField;
	private var yReadout:TextField;

	private var dirLabel:TextField;
	private var dirReadout:TextField;
	private var dirWheel:Sprite;

	private var rotationStyleLabel:TextField;
	private var rotationStyleButtons:Array;

	private var draggableLabel:TextField;
	private var draggableButton:IconButton;

	private var showSpriteLabel:TextField;
	private var showSpriteButton:IconButton;

	private var lastX:Number, lastY:Number, lastDirection:Number, lastRotationStyle:String;
	private var lastSrcImg:DisplayObject;

	public function SpriteInfoPart(app:Scratch) {
		this.app = app;
		shape = new Shape();
		addChild(shape);
		addParts();
		updateTranslation();
	}

	public static function strings():Array {
		return ['direction:', 'rotation style:', 'can drag in player:', 'show:'];
	}

	public function updateTranslation():void {
		dirLabel.text = Translator.map('direction:');
		rotationStyleLabel.text = Translator.map('rotation style:');
		draggableLabel.text = Translator.map('can drag in player:');
		showSpriteLabel.text = Translator.map('show:');
		if (app.viewedObj()) refresh();
	}

	public function setWidthHeight(w:int, h:int):void {
		this.w = w;
		this.h = h;
		var g:Graphics = shape.graphics;
		g.clear();
		g.beginFill(CSS.white);
		g.drawRect(0, 0, w, h);
		g.endFill();
	}

	public function step():void { updateSpriteInfo() }

	public function refresh():void {
		spriteName.setContents(app.viewedObj().objName);
		updateSpriteInfo();
		if (app.stageIsContracted) layoutCompact();
		else layoutFullsize();
	}

	private function addParts():void {
		addChild(closeButton = new IconButton(closeSpriteInfo, 'backarrow'));
		closeButton.isMomentary = true;

		addChild(spriteName = new EditableLabel(nameChanged));
		spriteName.setWidth(200);

		addChild(thumbnail = new Bitmap());

		addChild(xReadoutLabel = makeLabel('x:', readoutLabelFormat));
		addChild(xReadout = makeLabel('-888', readoutFormat));

		addChild(yReadoutLabel = makeLabel('y:', readoutLabelFormat));
		addChild(yReadout = makeLabel('-888', readoutFormat));

		addChild(dirLabel = makeLabel('', readoutLabelFormat));
		addChild(dirWheel = new Sprite());
		dirWheel.addEventListener(MouseEvent.MOUSE_DOWN, dirMouseDown);
		addChild(dirReadout = makeLabel('-179', readoutFormat));

		addChild(rotationStyleLabel = makeLabel('', readoutLabelFormat));
		rotationStyleButtons = [
			new IconButton(rotate360, 'rotate360', null, true),
			new IconButton(rotateFlip, 'flip', null, true),
			new IconButton(rotateNone, 'norotation', null, true)];
		for each (var b:IconButton in rotationStyleButtons) addChild(b);

		addChild(draggableLabel = makeLabel('', readoutLabelFormat));
		addChild(draggableButton = new IconButton(toggleLock, 'checkbox'));
		draggableButton.disableMouseover();

		addChild(showSpriteLabel = makeLabel('', readoutLabelFormat));
		addChild(showSpriteButton = new IconButton(toggleShowSprite, 'checkbox'));
		showSpriteButton.disableMouseover();
	}

	private function layoutFullsize():void {
		dirLabel.visible = true;
		rotationStyleLabel.visible = true;

		closeButton.x = 5;
		closeButton.y = 5;

		thumbnail.x = 40;
		thumbnail.y = 8;

		var left:int = 150;

		spriteName.setWidth(228);
		spriteName.x = left;
		spriteName.y = 5;

		var nextY:int = spriteName.y + spriteName.height + 9;
		xReadoutLabel.x = left;
		xReadoutLabel.y = nextY;
		xReadout.x = xReadoutLabel.x + 15;
		xReadout.y = nextY;

		yReadoutLabel.x = left + 47;
		yReadoutLabel.y = nextY;
		yReadout.x = yReadoutLabel.x + 15;
		yReadout.y = nextY;

		// right aligned
		dirWheel.x = w - 38;
		dirWheel.y = nextY + 8;
		dirReadout.x = dirWheel.x - 47;
		dirReadout.y = nextY;
		dirLabel.x = dirReadout.x - dirLabel.textWidth - 5;
		dirLabel.y = nextY;

		nextY += 22;
		rotationStyleLabel.x = left;
		rotationStyleLabel.y = nextY;
		var buttonsX:int = rotationStyleLabel.x + rotationStyleLabel.width + 5;
		rotationStyleButtons[0].x = buttonsX;
		rotationStyleButtons[1].x = buttonsX + 28;
		rotationStyleButtons[2].x = buttonsX + 55;
		rotationStyleButtons[0].y = rotationStyleButtons[1].y = rotationStyleButtons[2].y = nextY;

		nextY += 22;
		draggableLabel.x = left;
		draggableLabel.y = nextY;
		draggableButton.x = draggableLabel.x + draggableLabel.textWidth + 10;
		draggableButton.y = nextY + 4;

		nextY += 22;
		showSpriteLabel.x = left;
		showSpriteLabel.y = nextY;
		showSpriteButton.x = showSpriteLabel.x + showSpriteLabel.textWidth + 10;
		showSpriteButton.y = nextY + 4;
	}

	private function layoutCompact():void {
		dirLabel.visible = false;
		rotationStyleLabel.visible = false;

		closeButton.x = 5;
		closeButton.y = 5;

		spriteName.setWidth(130);
		spriteName.x = 28;
		spriteName.y = 5;

		var left:int = 6;

		thumbnail.x = ((w - thumbnail.width) / 2) + 3;
		thumbnail.y = spriteName.y + spriteName.height + 10;

		var nextY:int = 125;
		xReadoutLabel.x = left;
		xReadoutLabel.y = nextY;
		xReadout.x = left + 15;
		xReadout.y = nextY;

		yReadoutLabel.x = left + 47;
		yReadoutLabel.y = nextY;
		yReadout.x = yReadoutLabel.x + 15;
		yReadout.y = nextY;

		// right aligned
		dirWheel.x = w - 18;
		dirWheel.y = nextY + 8;
		dirReadout.x = dirWheel.x - 47;
		dirReadout.y = nextY;

		nextY += 22;
		rotationStyleButtons[0].x = left;
		rotationStyleButtons[1].x = left + 33;
		rotationStyleButtons[2].x = left + 64;
		rotationStyleButtons[0].y = rotationStyleButtons[1].y = rotationStyleButtons[2].y = nextY;

		nextY += 22;
		draggableLabel.x = left;
		draggableLabel.y = nextY;
		draggableButton.x = draggableLabel.x + draggableLabel.textWidth + 10;
		draggableButton.y = nextY + 4;

		nextY += 22;
		showSpriteLabel.x = left;
		showSpriteLabel.y = nextY;
		showSpriteButton.x = showSpriteLabel.x + showSpriteLabel.textWidth + 10;
		showSpriteButton.y = nextY + 4;
	}

	private function closeSpriteInfo(ignore:*):void {
		var lib:LibraryPart = parent as LibraryPart;
		if (lib) lib.showSpriteDetails(false);
	}

	private function rotate360(ignore:*):void {
		var spr:ScratchSprite = app.viewedObj() as ScratchSprite;
		spr.rotationStyle = 'normal';
		spr.setDirection(spr.direction);
		app.setSaveNeeded();
	}

	private function rotateFlip(ignore:*):void {
		var spr:ScratchSprite = app.viewedObj() as ScratchSprite;
		var dir:Number = spr.direction;
		spr.setDirection(90);
		spr.rotationStyle = 'leftRight';
		spr.setDirection(dir);
		app.setSaveNeeded();
	}

	private function rotateNone(ignore:*):void {
		var spr:ScratchSprite = app.viewedObj() as ScratchSprite;
		var dir:Number = spr.direction;
		spr.setDirection(90);
		spr.rotationStyle = 'none';
		spr.setDirection(dir);
		app.setSaveNeeded();
	}

	private function toggleLock(b:IconButton):void {
		var spr:ScratchSprite = ScratchSprite(app.viewedObj());
		if (spr) {
			spr.isDraggable = b.isOn();
			app.setSaveNeeded();
		}
	}

	private function toggleShowSprite(b:IconButton):void {
		var spr:ScratchSprite = ScratchSprite(app.viewedObj());
		if (spr) {
			spr.visible = !spr.visible;
			spr.updateBubble();
			b.setOn(spr.visible);
			app.setSaveNeeded();
		}
	}

	private function updateSpriteInfo():void {
		// Update the sprite info. Do nothing if a field is already up to date (to minimize CPU load).
		var spr:ScratchSprite = app.viewedObj() as ScratchSprite;
		if (spr == null) return;
		updateThumbnail();
		if (spr.scratchX != lastX) {
			xReadout.text = String(Math.round(spr.scratchX));
			lastX = spr.scratchX;
		}
		if (spr.scratchY != lastY) {
			yReadout.text = String(Math.round(spr.scratchY));
			lastY = spr.scratchY;
		}
		if (spr.direction != lastDirection) {
			dirReadout.text = String(Math.round(spr.direction)) + '\u00B0';
			drawDirWheel(spr.direction);
			lastDirection = spr.direction;
		}
		if (spr.rotationStyle != lastRotationStyle) {
			updateRotationStyle();
			lastRotationStyle = spr.rotationStyle;
		}
		draggableButton.setOn(spr.isDraggable);
		showSpriteButton.setOn(spr.visible);
	}

	private function drawDirWheel(dir:Number):void {
		const DegreesToRadians:Number = (2 * Math.PI) / 360;
		var r:Number = 11;
		var g:Graphics = dirWheel.graphics;
		g.clear();

		// circle
		g.beginFill(0xFF, 0);
		g.drawCircle (0, 0, r + 5);
		g.endFill();
		g.lineStyle(2, 0xD0D0D0, 1, true);
		g.drawCircle (0, 0, r - 3);

		// direction pointer
	 	g.lineStyle(3, 0x006080, 1, true);
		g.moveTo(0, 0);
		var dx:Number = r * Math.sin(DegreesToRadians * (180 - dir));
		var dy:Number = r * Math.cos(DegreesToRadians * (180 - dir));
		g.lineTo(dx, dy);
	}

	private function nameChanged():void {
		app.runtime.renameSprite(spriteName.contents());
		spriteName.setContents(app.viewedObj().objName);
	}

	public function updateThumbnail():void {
		var targetObj:ScratchObj = app.viewedObj();
		if (targetObj == null) return;
		if (targetObj.img.numChildren == 0) return; // shouldn't happen

		var src:DisplayObject = targetObj.img.getChildAt(0);
		if (src == lastSrcImg) return; // thumbnail is up to date

		var c:ScratchCostume = targetObj.currentCostume();
		thumbnail.bitmapData = c.thumbnail(80, 80, targetObj.isStage);
		lastSrcImg = src;
	}

	private function updateRotationStyle():void {
		var targetObj:ScratchSprite = app.viewedObj() as ScratchSprite;
		if (targetObj == null) return;
		for (var i:int = 0; i < numChildren; i++) {
			var b:IconButton = getChildAt(i) as IconButton;
			if (b) {
				if (b.clickFunction == rotate360) b.setOn(targetObj.rotationStyle == 'normal');
				if (b.clickFunction == rotateFlip) b.setOn(targetObj.rotationStyle == 'leftRight');
				if (b.clickFunction == rotateNone) b.setOn(targetObj.rotationStyle == 'none');
			}
		}
	}

	// -----------------------------
	// Direction Wheel Interaction
	//------------------------------

	private function dirMouseDown(evt:MouseEvent):void { app.gh.setDragClient(this, evt) }

	public function dragBegin(evt:MouseEvent):void { dragMove(evt) }
	public function dragEnd(evt:MouseEvent):void { dragMove(evt) }

	public function dragMove(evt:MouseEvent):void {
		var spr:ScratchSprite = app.viewedObj() as ScratchSprite;
		if (!spr) return;
		var p:Point = dirWheel.localToGlobal(new Point(0, 0));
		var dx:int = evt.stageX - p.x;
		var dy:int = evt.stageY - p.y;
		if ((dx == 0) && (dy == 0)) return;
		var degrees:Number = 90 + ((180 / Math.PI) * Math.atan2(dy, dx));
		spr.setDirection(degrees);
	}

}}
