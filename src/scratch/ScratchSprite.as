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

// ScratchSprite.as
// John Maloney, April 2010
//
// A Scratch sprite object. State specific to sprites includes: position, direction,
// rotation style, size, draggability, and pen state.

package scratch {
import filters.FilterPack;

import flash.display.*;
import flash.events.*;
import flash.geom.*;
import flash.net.FileReference;
import flash.utils.*;

import interpreter.Variable;

import logging.LogLevel;

import translation.Translator;

import uiwidgets.Menu;

import util.*;

import watchers.ListWatcher;

public class ScratchSprite extends ScratchObj {

	public var scratchX:Number;
	public var scratchY:Number;
	public var direction:Number = 90;
	public var rotationStyle:String = 'normal'; // 'normal', 'leftRight', 'none'

	public var isDraggable:Boolean = false;
	public var indexInLibrary:int;
	public var bubble:TalkBubble;

	public var penIsDown:Boolean;
	public var penWidth:Number = 1;
	public var penHue:Number = 120; // blue
	public var penShade:Number = 50; // full brightness and saturation
	public var penColorCache:Number = 0xFF;

	private var cachedBitmap:BitmapData;	// current costume, rotated & scaled
	private var cachedBounds:Rectangle;		// bounds of non-transparent cachedBitmap in stage coords

	public var localMotionAmount:int = -2;
	public var localMotionDirection:int = -2;
	public var localFrameNum:int;

	public var spriteInfo:Object = {};
	private var geomShape:Shape;

	public function ScratchSprite(name:String = null) {
		objName = Scratch.app.stagePane.unusedSpriteName(name || Translator.map('Sprite1'));
		filterPack = new FilterPack(this);
		initMedia();
		img = new Sprite();
		img.cacheAsBitmap = true;
		addChild(img);
		geomShape = new Shape();
		geomShape.visible = false;
		img.addChild(geomShape);
		showCostume(0);
		setScratchXY(0, 0);
	}

	private function initMedia():void {
		var graySquare:BitmapData = new BitmapData(4, 4, true, 0x808080);
		costumes.push(new ScratchCostume(Translator.map('costume1'), graySquare));
		sounds.push(new ScratchSound(Translator.map('pop'), new Pop()));
		sounds[0].prepareToSave();
	}

	public function setInitialCostume(c:ScratchCostume):void {
		costumes = [c];
		showCostume(0);
	}

	public function setRotationStyle(newRotationStyle:String):void {
		var oldDir:Number = direction;
		setDirection(90);
		if ('all around' == newRotationStyle) rotationStyle = 'normal';
		if ('left-right' == newRotationStyle) rotationStyle = 'leftRight';
		if ("don't rotate" == newRotationStyle) rotationStyle = "none";
		setDirection(oldDir);
	}

	public function duplicate():ScratchSprite {
		var dup:ScratchSprite = new ScratchSprite();
		dup.initFrom(this, false);
		return dup;
	}

	public function initFrom(spr:ScratchSprite, forClone:Boolean):void {
		// Copy all the state from the given sprite. Used by both
		// the clone block and duplicate().
		var i:int;

		// Copy variables and lists.
		for (i = 0; i < spr.variables.length; i++) {
			var v:Variable = spr.variables[i];
			variables.push(new Variable(v.name, v.value));
		}
		for (i = 0; i < spr.lists.length; i++) {
			var lw:ListWatcher = spr.lists[i];
			var lwDup:ListWatcher;
			lists.push(lwDup = new ListWatcher(lw.listName, lw.contents.concat(), spr));
			lwDup.visible = false;
		}

		if (forClone) {
			// Clones share scripts and sounds with the original sprite.
			scripts = spr.scripts;
			sounds = spr.sounds;
		} else {
			for (i = 0; i < spr.scripts.length; i++) scripts.push(spr.scripts[i].duplicate(forClone));
			sounds = spr.sounds.concat();
		}

		// To support vector costumes, every sprite must have its own costume copies, even clones.
		costumes = [];
		for each (var c:ScratchCostume in spr.costumes) costumes.push(c.duplicate());
		currentCostumeIndex = spr.currentCostumeIndex;

		objName = spr.objName;
		volume = spr.volume;
		instrument = spr.instrument;
		filterPack = spr.filterPack.duplicateFor(this);

		visible = spr.visible;
		scratchX = spr.scratchX;
		scratchY = spr.scratchY;
		direction = spr.direction;
		rotationStyle = spr.rotationStyle;
		isClone = forClone;
		isDraggable = spr.isDraggable;
		indexInLibrary = 100000;

		penIsDown = spr.penIsDown;
		penWidth = spr.penWidth;
		penHue = spr.penHue;
		penShade = spr.penShade;
		penColorCache = spr.penColorCache;

		showCostume(spr.currentCostumeIndex);
		setDirection(spr.direction);
		setScratchXY(spr.scratchX, spr.scratchY);
		setSize(spr.getSize());
		applyFilters();
	}

	override protected function updateImage():void {
		// Make sure to update the shape
		if(geomShape.parent) img.removeChild(geomShape);
		super.updateImage();
		if(bubble) updateBubble();
	}

	public function setScratchXY(newX:Number, newY:Number):void {
		scratchX = isFinite(newX) ? newX : newX > 0 ? 1e6 : -1e6;
		scratchY = isFinite(newY) ? newY : newY > 0 ? 1e6 : -1e6;
		x = 240 + Math.round(scratchX);
		y = 180 - Math.round(scratchY);
		updateBubble();
	}

	static private var stageRect:Rectangle = new Rectangle(0, 0, 480, 360);
	static private var emptyRect:Rectangle = new Rectangle(0, 0, 0, 0);
	static private var edgeBox:Rectangle = new Rectangle(0, 0, 480, 360);
	public function keepOnStage():void {
		var myBox:Rectangle;
		if(width == 0 && height == 0) {
			emptyRect.x = x;
			emptyRect.y = y;
			myBox = emptyRect;
		}
		else {
			myBox = geomShape.getRect(parent);
			if(myBox.width == 0 || myBox.height == 0) {
				myBox.x = x;
				myBox.y = y;
			}
			myBox.inflate(3, 3);
		}

		if(stageRect.containsRect(myBox)) return;

		var inset:int = Math.min(18, Math.min(myBox.width, myBox.height) / 2);
		edgeBox.x = edgeBox.y = inset;
		inset += inset;
		edgeBox.width = 480 - inset;
		edgeBox.height = 360 - inset;
		if (myBox.intersects(edgeBox)) return; // sprite is sufficiently on stage
		if (myBox.right < edgeBox.left)
			scratchX = Math.ceil(scratchX + (edgeBox.left - myBox.right));
		if (myBox.left > edgeBox.right)
			scratchX = Math.floor(scratchX + (edgeBox.right - myBox.left));
		if (myBox.bottom < edgeBox.top)
			scratchY = Math.floor(scratchY + (myBox.bottom - edgeBox.top));
		if (myBox.top > edgeBox.bottom)
			scratchY = Math.ceil(scratchY + (myBox.top - edgeBox.bottom));
		setScratchXY(scratchX, scratchY);
	}

	public function setDirection(d:Number):void {
		if ((d * 0) != 0) return; // d is +/-Infinity or NaN
		var wasFlipped:Boolean = isCostumeFlipped();
		d = d % 360;
		if (d < 0) d += 360;
		direction = (d > 180) ? d - 360 : d;
		if ('normal' == rotationStyle) {
			rotation = (direction - 90) % 360;
		} else {
			rotation = 0;
			if ('none' == rotationStyle && !wasFlipped) return;
			if (('leftRight' == rotationStyle) && (isCostumeFlipped() == wasFlipped)) return;
		}

		if(!Scratch.app.isIn3D) updateImage();
		adjustForRotationCenter();
		if(wasFlipped != isCostumeFlipped())
			updateRenderDetails(1);
	}

	protected override function adjustForRotationCenter():void {
		super.adjustForRotationCenter();
		geomShape.scaleX = img.getChildAt(0).scaleX;
	}

	public function getSize():Number { return 100 * scaleX; }

	public function setSize(percent:Number):void {
		var origW:int = img.width;
		var origH:int = img.height;
		var minScale:Number = Math.min(1, Math.max(5 / origW, 5 / origH));
		var maxScale:Number = Math.min((1.5 * 480) / origW, (1.5 * 360) / origH);
		scaleX = scaleY = Math.max(minScale, Math.min(percent / 100.0, maxScale));
		clearCachedBitmap();
		updateBubble();
	}

	public function setPenSize(n:Number):void {
		penWidth = Math.max(1, Math.min(Math.round(n), 255)); // 255 is the maximum line with supported by Flash
	}

	public function setPenColor(c:Number):void {
		var hsv:Array = Color.rgb2hsv(c);
		penHue = (200 * hsv[0]) / 360 ;
		penShade = 50 * hsv[2];  // not quite right; doesn't account for saturation
		penColorCache = c;
	}

	public function setPenHue(n:Number):void {
		penHue = n % 200;
		if (penHue < 0) penHue += 200;
		updateCachedPenColor();
	}

	public function setPenShade(n:Number):void {
		penShade = n % 200;
		if (penShade < 0) penShade += 200;
		updateCachedPenColor();
	}

	private function updateCachedPenColor():void {
		var c:int = Color.fromHSV((penHue * 180) / 100, 1, 1);
		var shade:Number = (penShade > 100) ? 200 - penShade : penShade; // range 0..100
		if (shade < 50) {
			penColorCache = Color.mixRGB(0, c, (10 + shade) / 60);
		} else {
			penColorCache = Color.mixRGB(c, 0xFFFFFF, (shade - 50) / 60);
		}
	}

	public function isCostumeFlipped():Boolean {
		return (rotationStyle == 'leftRight') && (direction < 0);
	}

	public override function clearCachedBitmap():void {
		super.clearCachedBitmap();
		cachedBitmap = null;
		cachedBounds = null;

		if(!geomShape.parent) {
			geomShape.graphics.copyFrom(currentCostume().getShape().graphics);
			var currDO:DisplayObject = img.getChildAt(0);
			geomShape.scaleX = currDO.scaleX;
			geomShape.scaleY = currDO.scaleY;
			geomShape.x = currDO.x;
			geomShape.y = currDO.y;
			geomShape.rotation = currDO.rotation;
			img.addChild(geomShape);
		}
	}

	public override function hitTestPoint(globalX:Number, globalY:Number, shapeFlag:Boolean = true):Boolean {
		if ((!visible) || (img.transform.colorTransform.alphaMultiplier == 0)) return false;
		var p:Point = parent.globalToLocal(new Point(globalX, globalY));
		var myRect:Rectangle = bounds();
		if (!myRect.containsPoint(p)) return false;
		return shapeFlag ? bitmap(true).hitTest(myRect.topLeft, 1, p) : true;
	}

	public override function getBounds(space:DisplayObject):Rectangle {
		//if(space == this && geomShape.parent) img.removeChild(geomShape);
		var b:Rectangle = getChildAt(0).getBounds(space);
		//img.addChild(geomShape);
		return b;
	}

	public function bounds():Rectangle {
		// return the bounding rectangle of my visible pixels (scaled and rotated)
		// in the coordinate system of my parent (i.e. the stage)
		if (cachedBounds == null) bitmap(); // computes cached bounds
		var result:Rectangle = cachedBounds.clone();
		result.offset(x, y);
//		trace('old code bounds: '+result+'     new code bounds: '+geomShape.getBounds(parent));
//		return geomShape.getBounds(parent);
		return result;
	}

//	private var testBM:Bitmap = new Bitmap();
//	private var testSpr:Sprite = new Sprite();
	public function bitmap(forTest:Boolean = false):BitmapData {
		if (cachedBitmap != null && (!forTest || !Scratch.app.isIn3D))
			return cachedBitmap;

		// compute cachedBitmap
		// Note: cachedBitmap must be drawn with alpha=1 to allow the sprite/color touching tests to work
		var m:Matrix = new Matrix();
		m.rotate((Math.PI * rotation) / 180);
		m.scale(scaleX, scaleY);
		var b:Rectangle = (!Scratch.app.render3D || currentCostume().bitmap) ? img.getChildAt(0).getBounds(this) : getVisibleBounds(this);
		var r:Rectangle = transformedBounds(b, m);

		// returns true if caller should immediately return cachedBitmap
		var self:ScratchSprite = this;
		function bitmap2d():Boolean {
			if ((r.width == 0) || (r.height == 0)) { // empty costume: use an invisible 1x1 bitmap
				cachedBitmap = new BitmapData(1, 1, true, 0);
				cachedBounds = cachedBitmap.rect;
				return true;
			}

			var oldTrans:ColorTransform = img.transform.colorTransform;
			img.transform.colorTransform = new ColorTransform(1, 1, 1, 1, oldTrans.redOffset, oldTrans.greenOffset, oldTrans.blueOffset, 0);
			cachedBitmap = new BitmapData(Math.max(int(r.width), 1), Math.max(int(r.height), 1), true, 0);
			m.translate(-r.left, -r.top);
			cachedBitmap.draw(self, m);
			img.transform.colorTransform = oldTrans;
			return false;
		}

		if (SCRATCH::allow3d) {
			if (Scratch.app.isIn3D) {
				var oldGhost:Number = filterPack.getFilterSetting('ghost');
				filterPack.setFilter('ghost', 0);
				updateEffectsFor3D();
				var bm:BitmapData = Scratch.app.render3D.getRenderedChild(this, b.width * scaleX, b.height * scaleY);
				filterPack.setFilter('ghost', oldGhost);
				updateEffectsFor3D();
//	    		if(objName == 'Tank 2 down bumper ') {
//		    		if(!testSpr.parent) {
//			    		testBM.filters = [new GlowFilter(0xFF00FF, 0.8)];
//				    	testBM.y = 360; testBM.x = 15;
//					    testSpr.addChild(testBM);
//  					testBM.scaleX = testBM.scaleY = 4;
//	    				testSpr.mouseChildren = testSpr.mouseEnabled = false;
//		    			stage.addChild(testSpr);
//			    	}
//				    testSpr.graphics.clear();
//  				testSpr.graphics.lineStyle(1);
//	    			testSpr.graphics.drawRect(testBM.x, testBM.y, bm.width * testBM.scaleX, bm.height * testBM.scaleY);
//		    		testBM.bitmapData = bm;
//			    }

				if (rotation != 0) {
					m = new Matrix();
					m.rotate((Math.PI * rotation) / 180);
					b = transformedBounds(bm.rect, m);
					cachedBitmap = new BitmapData(Math.max(int(b.width), 1), Math.max(int(b.height), 1), true, 0);
					m.translate(-b.left, -b.top);
					cachedBitmap.draw(bm, m);
				}
				else {
					cachedBitmap = bm;
				}
			}
			else {
				if (bitmap2d()) return cachedBitmap;
			}
		}
		else {
			if (bitmap2d()) return cachedBitmap;
		}

		cachedBounds = cachedBitmap.rect;

		// crop cachedBitmap and record cachedBounds
		// Note: handles the case where cropR is empty
		var cropR:Rectangle = cachedBitmap.getColorBoundsRect(0xFF000000, 0, false);
		if ((cropR.width > 0) && (cropR.height > 0)) {
			var cropped:BitmapData = new BitmapData(Math.max(int(cropR.width), 1), Math.max(int(cropR.height), 1), true, 0);
			cropped.copyPixels(cachedBitmap, cropR, new Point(0, 0));
			cachedBitmap = cropped;
			cachedBounds = cropR;
		}

		cachedBounds.offset(r.x, r.y);
		return cachedBitmap;
	}

	private function transformedBounds(r:Rectangle, m:Matrix):Rectangle {
		// Return the rectangle that encloses the corners of r when transformed by m.
		var p1:Point = m.transformPoint(r.topLeft);
		var p2:Point = m.transformPoint(new Point(r.right, r.top));
		var p3:Point = m.transformPoint(new Point(r.left, r.bottom));
		var p4:Point = m.transformPoint(r.bottomRight);
		var xMin:Number, xMax:Number, yMin:Number, yMax:Number;
		xMin = Math.min(p1.x, p2.x, p3.x, p4.x);
		yMin = Math.min(p1.y, p2.y, p3.y, p4.y);
		xMax = Math.max(p1.x, p2.x, p3.x, p4.x);
		yMax = Math.max(p1.y, p2.y, p3.y, p4.y);
		var newR:Rectangle = new Rectangle(xMin, yMin, xMax - xMin, yMax - yMin);
		return newR;
	}

	public override function defaultArgsFor(op:String, specDefaults:Array):Array {
		if ('gotoX:y:' == op) return [Math.round(scratchX), Math.round(scratchY)];
		if ('glideSecs:toX:y:elapsed:from:' == op) return [1, Math.round(scratchX), Math.round(scratchY)];
		if ('setSizeTo:' == op) return [Math.round(getSize() * 10) / 10];
		if ((['startScene', 'startSceneAndWait', 'whenSceneStarts'].indexOf(op)) > -1) {
			var stg:ScratchStage = parent as ScratchStage;
			if (stg) return [stg.costumes[stg.costumes.length - 1].costumeName];
		}
		if ('senseVideoMotion' == op) return ['motion', 'this sprite'];
		return super.defaultArgsFor(op, specDefaults);
	}

	/* Dragging */

	public function objToGrab(evt:MouseEvent):ScratchSprite { return this } // allow dragging

	/* Menu */

	public function menu(evt:MouseEvent):Menu {
		var m:Menu = new Menu();
		m.addItem('info', showDetails);
		m.addLine();
		m.addItem('duplicate', duplicateSprite);
		m.addItem('delete', deleteSprite);
		m.addLine();
		m.addItem('save to local file', saveToLocalFile);
		return m;
	}

	public function handleTool(tool:String, evt:MouseEvent):void {
		if (tool == 'copy') duplicateSprite(true);
		if (tool == 'cut') deleteSprite();
		if (tool == 'grow') growSprite();
		if (tool == 'shrink') shrinkSprite();
		if (tool == 'help') Scratch.app.showTip('scratchUI');
	}

	private function growSprite():void { setSize(getSize() + 5); Scratch.app.updatePalette() }
	private function shrinkSprite():void { setSize(getSize() - 5); Scratch.app.updatePalette() }

	public function duplicateSprite(grab:Boolean = false):void {
		var dup:ScratchSprite = duplicate();
		dup.objName = unusedSpriteName(objName);
		if (!grab) {
			dup.setScratchXY(
				int(Math.random() * 400) - 200,
				int(Math.random() * 300) - 150);
		}
		if (parent != null) {
			parent.addChild(dup);
			var app:Scratch = root as Scratch;
			if (app) {
				app.setSaveNeeded();
				app.updateSpriteLibrary();
				if (grab) app.gh.grabOnMouseUp(dup);
			}
		}
	}

	public function showDetails():void {
		var app:Scratch = Scratch.app;
		app.selectSprite(this);
		app.libraryPart.showSpriteDetails(true);
	}

	public function unusedSpriteName(baseName:String):String {
		var stg:ScratchStage = parent as ScratchStage;
		return stg ? stg.unusedSpriteName(baseName) : baseName;
	}

	public function deleteSprite():void {
		if (parent != null) {
			var app:Scratch = Scratch.app;
			app.runtime.recordForUndelete(this, scratchX, scratchY, 0, app.stagePane);
			hideBubble();

			// Force redisplay (workaround for flash display update bug)
			if(!Scratch.app.isIn3D) {
				parent.visible = false;
				parent.visible = true;
			}

			parent.removeChild(this);
			if (app) {
				app.stagePane.removeObsoleteWatchers();
				var sprites:Array = app.stagePane.sprites();
				if (sprites.length > 0) {
					// Pick the sprite just before the deleted sprite in the sprite library to select next.
					sprites.sortOn('indexInLibrary');
					var nextSelection:ScratchSprite = sprites[0];
					for each (var spr:ScratchSprite in sprites) {
						if (spr.indexInLibrary > this.indexInLibrary) break;
						else nextSelection = spr;
					}
					app.selectSprite(nextSelection);
				} else {
					// If there are no sprites, select the stage.
					app.selectSprite(app.stagePane);
				}
				app.setSaveNeeded();
				app.updateSpriteLibrary();
			}
		}
	}

	private function saveToLocalFile():void {
		function success():void {
			Scratch.app.log(LogLevel.INFO, 'sprite saved to file', {filename: file.name});
		}
		var zipData:ByteArray = new ProjectIO(Scratch.app).encodeSpriteAsZipFile(copyToShare());
		var defaultName:String = objName + '.sprite2';
		var file:FileReference = new FileReference();
		file.addEventListener(Event.COMPLETE, success);
		file.save(zipData, defaultName);
	}

	public function copyToShare():ScratchSprite {
		// Return a copy of the current sprite set up to be shared.
		var dup:ScratchSprite = new ScratchSprite();
		dup.initFrom(this, false);
		dup.setScratchXY(0, 0);
		dup.visible = true;
		return dup;
	}

	/* talk/think bubble support */

	public function showBubble(s:*, type:String, source:Object, isAsk:Boolean = false):void {
		hideBubble();
		if (s == null) s = 'NULL';
		if (s is Number) {
			if ((Math.abs(s) >= 0.01) && (int(s) != s)) {
				s = s.toFixed(2); // 2 digits after decimal point
			} else {
				s = s.toString();
			}
		}
		if (!(s is String)) s = s.toString();
		if (s.length == 0) return;
		bubble = new TalkBubble(s, type, isAsk ? 'ask' : 'say', source);
		parent.addChild(bubble);
		updateBubble();
	}

	public function hideBubble():void {
		if (bubble == null) return;
		bubble.parent.removeChild(bubble);
		bubble = null;
	}

	public function updateBubble():void {
		if (bubble == null) return;
		if (bubble.visible != visible) bubble.visible = visible;
		if (!visible) return;
		var pad:int = 3;
		var stageL:int = pad;
		var stageR:int = STAGEW - pad;
		var stageH:int = STAGEH;
		var r:Rectangle = bubbleRect();

		// decide which side of the sprite the bubble should be on
		var bubbleOnRight:Boolean = bubble.pointsLeft;
		if (bubbleOnRight && ((r.x + r.width + bubble.width) > stageR)) bubbleOnRight = false;
		if (!bubbleOnRight && ((r.x - bubble.width) < 0)) bubbleOnRight = true;

		if (bubbleOnRight) {
			bubble.setDirection('left');
			bubble.x = r.x + r.width;
		} else {
			bubble.setDirection('right');
			bubble.x = r.x - bubble.width;
		}

		// make sure bubble stays on screen
		if ((bubble.x + bubble.width) > stageR) bubble.x = stageR - bubble.width;
		if (bubble.x < stageL) bubble.x = stageL;
		bubble.y = Math.max(r.y - bubble.height, pad);
		if ((bubble.y + bubble.height) > stageH) {
			bubble.y = stageH - bubble.height;
		}
	}

	private function bubbleRect():Rectangle {
		// Answer a rectangle to be used for position a talk/think bubble, based on
		// the bounds of the non-transparent pixels along the top edge of this sprite.
		var myBM:BitmapData = bitmap();
		var h:int = 8; // strip height

		// compute bounds
		var p:Point = Scratch.app.stagePane.globalToLocal(localToGlobal(new Point(0, 0)));
		if (cachedBounds == null) bitmap(); // computes cached bounds
		var myBounds:Rectangle = cachedBounds.clone();
		myBounds.offset(p.x, p.y);

		var topStrip:BitmapData = new BitmapData(myBM.width, h, true, 0);
		topStrip.copyPixels(myBM, myBM.rect, new Point(0, 0));
		var r:Rectangle = topStrip.getColorBoundsRect(0xFF000000, 0, false);
		if ((r.width == 0) || (r.height == 0)) return myBounds;
		return new Rectangle(myBounds.x + r.x, myBounds.y, r.width, 10);
	}

	/* Saving */

	public override function writeJSON(json:util.JSON):void {
		super.writeJSON(json);
		json.writeKeyValue('scratchX', scratchX);
		json.writeKeyValue('scratchY', scratchY);
		json.writeKeyValue('scale', scaleX);
		json.writeKeyValue('direction', direction);
		json.writeKeyValue('rotationStyle', rotationStyle);
		json.writeKeyValue('isDraggable', isDraggable);
		json.writeKeyValue('indexInLibrary', indexInLibrary);
		json.writeKeyValue('visible', visible);
		json.writeKeyValue('spriteInfo', spriteInfo);
	}

	public override function readJSON(jsonObj:Object):void {
		super.readJSON(jsonObj);
		scratchX = jsonObj.scratchX;
		scratchY = jsonObj.scratchY;
		scaleX = scaleY = jsonObj.scale;
		direction = jsonObj.direction;
		rotationStyle = jsonObj.rotationStyle;
		isDraggable = jsonObj.isDraggable;
		indexInLibrary = jsonObj.indexInLibrary;
		visible = jsonObj.visible;
		spriteInfo = jsonObj.spriteInfo ? jsonObj.spriteInfo : {};
		setScratchXY(scratchX, scratchY);
	}

	public function getVisibleBounds(space:DisplayObject):Rectangle {
		if(space == this) {
			var rot:Number = rotation;
			rotation = 0;
		}

		if(!geomShape.parent) {
			img.addChild(geomShape);
			geomShape.x = img.getChildAt(0).x;
			geomShape.scaleX = img.getChildAt(0).scaleX;
		}

		var b:Rectangle = geomShape.getRect(space);

		if(space == this) {
			rotation = rot;
			b.inflate(2, 2);
			b.offset(-1, -1);
		}

		return b;
	}

	public function prepareToDrag():void {
		// Force rendering with PixelBender for a dragged sprite
		applyFilters(true);
	}

	public override function stopDrag():void {
		super.stopDrag();
		applyFilters();
	}
}}
