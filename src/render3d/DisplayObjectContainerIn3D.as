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

package render3d {

import flash.display.Sprite;

/**
 *   A display object container which renders in 3D instead
 *   @author Shane M. Clements, shane.m.clements@gmail.com
 */
public class DisplayObjectContainerIn3D extends Sprite implements IRenderIn3D {SCRATCH::allow3d{

	import com.adobe.utils.*;

	import filters.FilterPack;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Stage3D;
	import flash.display3D.*;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Endian;

	private static const FX_COLOR:String = 'color';
	private static const FX_FISHEYE:String = 'fisheye';
	private static const FX_WHIRL:String = 'whirl';
	private static const FX_PIXELATE:String = 'pixelate';
	private static const FX_MOSAIC:String = 'mosaic';
	private static const FX_BRIGHTNESS:String = 'brightness';
	private static const FX_GHOST:String = 'ghost';

	// The elements of this array must match FilterPack.filterNames, but not necessarily in the same order.
	private static const effectNames:Array = [
		FX_PIXELATE, // since this is a two-component effect, put it first to guarantee alignment
		FX_COLOR, FX_FISHEYE, FX_WHIRL, FX_MOSAIC, FX_BRIGHTNESS, FX_GHOST];

	private var contextRequested:Boolean = false;

	/** Context to create textures on */
	private var __context:Context3D;
	private var indexBuffer:IndexBuffer3D;
	private var vertexBuffer:VertexBuffer3D;
	private var shaderConfig:Object; // contains Program3D, vertex size, etc.
	private var shaderCache:Object; // mapping of shader config ID -> shaderConfig
	private var vertexShaderCode:String;
	private var fragmentShaderCode:String;
	private var fragmentShaderAssembler:AGALMacroAssembler;
	private var vertexShaderAssembler:AGALMacroAssembler;
	private var spriteBitmaps:Dictionary;
	private var spriteRenderOpts:Dictionary;
	private var bitmapsByID:Object;

	/** Texture data */
	private var textures:Array;
	private var testBMs:Array;
	private var textureIndexByID:Object;
	private static var texSize:int = 2048;
	private var penPacked:Boolean;

	/** Triangle index data */
	//private var indexData:Vector.<uint> = new <uint>[];
	private var indexData:ByteArray = new ByteArray();

	/** Vertex data for all sprites */
	//private var vertexData:Vector.<Number> = new <Number>[];
	private var vertexData:ByteArray = new ByteArray();
	private var projMatrix:Matrix3D;

	private var textureCount:int;
	private var childrenChanged:Boolean;
	private var movedChildren:Dictionary;
	private var unrenderedChildren:Dictionary;
	private var stampsByID:Object;

	private var indexBufferUploaded:Boolean;
	private var vertexBufferUploaded:Boolean;
	private var uiContainer:StageUIContainer;
	private var scratchStage:Sprite;
	private var globalScale:Number;
	private var stagePenLayer:DisplayObject;
	private var stage3D:Stage3D;
	private var pixelateAll:Boolean;
	private var statusCallback:Function;

	private var effectRefs:Object;
	private var oldEffectRefs:Object;

	/**
	 *   Make the texture
	 */
	public function DisplayObjectContainerIn3D() {
		if (effectNames.length != FilterPack.filterNames.length) {
			Scratch.app.logMessage(
					'Effect list mismatch', {effectNames: effectNames, filterPack: FilterPack.filterNames});
		}
		uiContainer = new StageUIContainer();
		uiContainer.graphics.lineStyle(1);
		spriteBitmaps = new Dictionary();
		spriteRenderOpts = new Dictionary();
		shaderCache = {};
		fragmentShaderAssembler = new AGALMacroAssembler();
		vertexShaderAssembler = new AGALMacroAssembler();
		bitmapsByID = {};
		textureIndexByID = {};
		textures = [];
		cachedOtherRenderBitmaps = new Dictionary();
		penPacked = false;
		globalScale = 1.0;
		testBMs = [];
		textureCount = 0;
		childrenChanged = false;
		pixelateAll = false;
		movedChildren = new Dictionary();
		unrenderedChildren = new Dictionary();
		stampsByID = {};
		indexData.endian = Endian.LITTLE_ENDIAN;
		vertexData.endian = Endian.LITTLE_ENDIAN;
		indexBufferUploaded = false;
		vertexBufferUploaded = false;
		effectRefs = {};
		oldEffectRefs = {};
		loadShaders();
	}

	public function setStatusCallback(callback:Function):void {
		statusCallback = callback;
	}

	public function setStage(stage:Sprite, penLayer:DisplayObject):void {
		if (scratchStage) {
			scratchStage.removeEventListener(Event.ADDED_TO_STAGE, addedToStage);
			scratchStage.removeEventListener(Event.ADDED, childAdded);
			scratchStage.removeEventListener(Event.REMOVED, childRemoved);
			scratchStage.removeEventListener(Event.REMOVED_FROM_STAGE, removedFromStage);
			if (scratchStage.stage)
				scratchStage.stage.removeEventListener(Event.RESIZE, onStageResize);
			scratchStage.cacheAsBitmap = true;
			(scratchStage as Object).img.cacheAsBitmap = true;
			scratchStage.visible = true;

			while (uiContainer.numChildren)
				scratchStage.addChild(uiContainer.getChildAt(0));

			for (var i:int = 0; i < textures.length; ++i)
				textures[i].disposeTexture();
			textures.length = 0;

			spriteBitmaps = new Dictionary();
			spriteRenderOpts = new Dictionary();
			boundsDict = new Dictionary();
			cachedOtherRenderBitmaps = new Dictionary();
			stampsByID = {};
			cleanUpUnusedBitmaps();
		}

		scratchStage = stage;
		stagePenLayer = penLayer;
		if (scratchStage) {
			scratchStage.addEventListener(Event.ADDED_TO_STAGE, addedToStage, false, 0, true);
			scratchStage.addEventListener(Event.ADDED, childAdded, false, 0, true);
			scratchStage.addEventListener(Event.REMOVED, childRemoved, false, 0, true);
			scratchStage.addEventListener(Event.REMOVED_FROM_STAGE, removedFromStage, false, 0, true);
			if (scratchStage.stage)
				scratchStage.stage.addEventListener(Event.RESIZE, onStageResize, false, 0, true);
			if (__context) scratchStage.visible = false;
			scratchStage.cacheAsBitmap = false;
			(scratchStage as Object).img.cacheAsBitmap = true;
			forEachEffect(function(effectName:String): void {
				effectRefs[effectName] = oldEffectRefs[effectName] = 0;
			});
		}
		else {
			stage3D.removeEventListener(Event.CONTEXT3D_CREATE, context3DCreated);
		}
	}

	private function addedToStage(e:Event = null):void {
		if (e && e.target != scratchStage) return;
		globalScale = ('contentsScaleFactor' in scratchStage.stage ? scratchStage.stage['contentsScaleFactor'] : 1.0);

		scratchStage.parent.addChildAt(uiContainer, scratchStage.parent.getChildIndex(scratchStage) + 1);
		for (var i:uint = 0; i < scratchStage.numChildren; ++i) {
			var dispObj:DisplayObject = scratchStage.getChildAt(i);
			if (isUI(dispObj)) {
				uiContainer.addChild(dispObj);
				--i;
			}
			else if (!('img' in dispObj)) {
				// Set the bounds of any non-ScratchSprite display objects
				boundsDict[dispObj] = dispObj.getBounds(dispObj);
			}
		}
		uiContainer.transform.matrix = scratchStage.transform.matrix.clone();
		uiContainer.scrollRect = scratchStage.scrollRect;
		scratchStage.stage.addEventListener(Event.RESIZE, onStageResize, false, 0, true);
//			scratchStage.stage.addEventListener(KeyboardEvent.KEY_DOWN, toggleTextureDebug, false, 0, true);
		scratchStage.addEventListener(Event.ENTER_FRAME, onRender, false, 0, true);

		penPacked = false;
		if (!__context) {
			stage3D = scratchStage.stage.stage3Ds[0];
			callbackCalled = false;
			requestContext3D();
		}
		else setRenderView();

		//childrenChanged = true;
		tlPoint = scratchStage.localToGlobal(originPt);
	}

	private function removedFromStage(e:Event):void {
		if (e.target != scratchStage) return;
		uiContainer.parent.removeChild(uiContainer);
		if (testBMs && testBMs.length) {
			for (var i:int = 0; i < testBMs.length; ++i)
				scratchStage.stage.removeChild(testBMs[i]);
			testBMs = [];
		}

		for (var id:String in bitmapsByID)
			if (bitmapsByID[id] is ChildRender)
				bitmapsByID[id].dispose();
		bitmapsByID = {};

		for (var o:Object in cachedOtherRenderBitmaps)
			cachedOtherRenderBitmaps[o].dispose();

		cachedOtherRenderBitmaps = new Dictionary();

		//trace('Dying!');
		scratchStage.stage.removeEventListener(Event.RESIZE, onStageResize);
//			scratchStage.stage.removeEventListener(KeyboardEvent.KEY_DOWN, toggleTextureDebug);
		scratchStage.removeEventListener(Event.ENTER_FRAME, onRender);

		onContextLoss(e);
		if (__context) {
			__context.dispose();
			__context = null;
		}
	}

	private static var originPt:Point = new Point();

	public function onStageResize(e:Event = null):void {
		scissorRect = null;
		if (uiContainer && scratchStage)
			uiContainer.transform.matrix = scratchStage.transform.matrix.clone();
		setRenderView();
	}

	private var scissorRect:Rectangle;

	public function setRenderView():void {
		var p:Point = scratchStage.localToGlobal(originPt);
		stage3D.x = p.x;
		stage3D.y = p.y;
		var width:uint = Math.ceil(480 * scratchStage.scaleX), height:uint = Math.ceil(360 * scratchStage.scaleX);
		var rect:Rectangle = new Rectangle(0, 0, width, height);
		if (stage3D.context3D && (!scissorRect || !scissorRect.equals(rect))) {
			scissorRect = rect;
			projMatrix = createOrthographicProjectionMatrix(480, 360, 0, 0);
			stage3D.context3D.setScissorRectangle(scissorRect);
			stage3D.context3D.configureBackBuffer(width, height, 0, false, true);
//trace('Setting backbuffer and scissor rectangle');
			// Re-render stuff that may have changed size
			childrenChanged = true;
		}
	}

	private function childAdded(e:Event):void {
		if (e.target.parent != scratchStage) return;

		// Check special properties to determine if the child is UI or not
		var dispObj:DisplayObject = e.target as DisplayObject;
		if (isUI(dispObj)) {
			uiContainer.addChild(dispObj);
			//trace(Dbg.printObj(this)+': Child '+Dbg.printObj(e.target)+' ADDED to ui layer');
			return;
		}

		childrenChanged = true;
		if (!('img' in dispObj)) {
			// Set the bounds of any non-ScratchSprite display objects
			boundsDict[dispObj] = dispObj.getBounds(dispObj);
		}
//trace(Dbg.printObj(this)+': Child '+Dbg.printObj(e.target)+' ADDED');
	}

	private function isUI(dispObj:DisplayObject):Boolean {
		return ('target' in dispObj || 'answer' in dispObj || 'pointsLeft' in dispObj);
	}

	private function childRemoved(e:Event):void {
		if (e.target.parent != scratchStage) return;
		childrenChanged = true;
//trace(Dbg.printObj(this)+': Child '+Dbg.printObj(e.target)+' REMOVED');

		var bmID:String = spriteBitmaps[e.target];
		if (bmID) {
			delete spriteBitmaps[e.target];

//			if(bitmapsByID[bmID]) {
//				if(bitmapsByID[bmID] is ChildRender)
//					bitmapsByID[bmID].dispose();
//				delete bitmapsByID[bmID];
//			}
		}

		if (cachedOtherRenderBitmaps[e.target]) {
			cachedOtherRenderBitmaps[e.target].dispose();
			delete cachedOtherRenderBitmaps[e.target];
		}

		if (boundsDict[e.target])
			delete boundsDict[e.target];

		var displayObject:DisplayObject = e.target as DisplayObject;
		if (displayObject) {
			updateFilters(displayObject, {});
			delete spriteRenderOpts[displayObject];
		}
	}

	public function getUIContainer():Sprite {
		return uiContainer;
	}

	private function checkBuffers():void {
		var resized:Boolean = false;
		var numChildren:uint = scratchStage.numChildren;
		var vertexDataMinSize:int = numChildren * 4 * shaderConfig.vertexSizeBytes * 2; // 4 verts per child
		if (vertexDataMinSize > vertexData.length) {
			// Increase and fill in the index buffer
			var index:uint = indexData.length;
			var base:int = (index / 12) * 4;
			indexData.length = numChildren * 12;
			indexData.position = index;
			var numAdded:int = (indexData.length - index) / 12;
			for (var i:int = 0; i < numAdded; ++i) {
				indexData.writeShort(base);
				indexData.writeShort(base + 1);
				indexData.writeShort(base + 2);
				indexData.writeShort(base + 2);
				indexData.writeShort(base + 3);
				indexData.writeShort(base);
				base += 4;
			}

			vertexData.length = vertexDataMinSize;
			resized = true;
		}

		if (__context) {
			if (resized)  {
				if (indexBuffer) {
					indexBuffer.dispose();
					indexBuffer = null;
				}
				if (vertexBuffer) {
					vertexBuffer.dispose();
					vertexBuffer = null;
				}
			}

			if (indexBuffer == null) {
				indexBuffer = __context.createIndexBuffer(indexData.length >> 1);
				indexBuffer.uploadFromByteArray(indexData, 0, 0, indexData.length >> 1);
				indexBufferUploaded = true;
			}

			if (vertexBuffer == null) {
				//trace('creating vertexBuffer when indexData length = '+indexData.length);
				vertexBuffer = __context.createVertexBuffer((indexData.length / 12) * 4, shaderConfig.vertexComponents);
				vertexBufferUploaded = false;
			}
		}
		else {
			indexBufferUploaded = false;
			vertexBufferUploaded = false;
		}
	}

	private var childrenDrawn:int = 0;
	private var tlPoint:Point;

	private function draw():void {
		var textureDirty:Boolean = false;
		var numChildren:uint = scratchStage.numChildren;
		var i:int;
		var dispObj:DisplayObject;

		var effectsChanged:Boolean = false;
		forEachEffect(function(effectName:String): void {
			if (!!oldEffectRefs[effectName] != !!effectRefs[effectName]) effectsChanged = true;
			oldEffectRefs[effectName] = effectRefs[effectName];
		});

		if (effectsChanged)
			switchShaders();

		checkBuffers();

		if (childrenChanged) {
			if (debugTexture) {
				uiContainer.graphics.clear();
				uiContainer.graphics.lineStyle(1);
			}
			for (i = 0; i < numChildren; ++i) {
				dispObj = scratchStage.getChildAt(i);
				if (dispObj.visible)
					textureDirty = checkChildRender(dispObj) || textureDirty;
			}
		}
		else
			for (var child:Object in unrenderedChildren)
				if ((child as DisplayObject).visible)
					textureDirty = checkChildRender(child as DisplayObject) || textureDirty;

		if (textureDirty) {
			// TODO: put the pen layer into a 512x512 texture to be resent each frame
			packTextureBitmaps();
		}

		if (childrenChanged || effectsChanged) {
			vertexData.position = 0;
			childrenDrawn = 0;
			var skipped:uint = 0;
			for (i = 0; i < numChildren; ++i) {
				dispObj = scratchStage.getChildAt(i);
				if (!dispObj.visible) {
					++skipped;
					continue;
				}
				drawChild(dispObj);
				++childrenDrawn;
			}
			//trace('drew '+childrenDrawn+' children (vertexData.length = '+vertexData.length+')');
		}
//		trace('quadCount = '+childrenDrawn);
//		trace('numChildren = '+scratchStage.numChildren);
//		trace('vertexComponents = '+shaderConfig.vertexComponents);
//		trace('vertexData.length = '+vertexData.length);
//		trace('indexData.length = '+indexData.length);

		movedChildren = new Dictionary();
		unrenderedChildren = new Dictionary();
	}

	private function uploadBuffers():void {
		if (!indexBufferUploaded) {
//			trace('uploading indexBuffer when indexData length = '+indexData.length);
			indexBuffer.uploadFromByteArray(indexData, 0, 0, indexData.length >> 1);
			indexBufferUploaded = true;
		}
//		trace('uploading vertexBuffer when indexData length = '+indexData.length);
//		trace('uploadFromByteArray(vertexData, 0, 0, '+((indexData.length / 12) * 4)+')');
		vertexBuffer.uploadFromByteArray(vertexData, 0, 0, (indexData.length / 12) * 4);
		vertexBufferUploaded = true;
	}

	private var boundsDict:Dictionary = new Dictionary();

	private function drawChild(dispObj:DisplayObject):void {
		// Setup the geometry data
		var rot:Number = dispObj.rotation;
		var bounds:Rectangle = boundsDict[dispObj];
		if (!bounds)
			return;

		var dw:Number = bounds.width * dispObj.scaleX;
		var w:Number = dw * scaleX;
		var dh:Number = bounds.height * dispObj.scaleY;
		var h:Number = dh * scaleY;

		var bmID:String = spriteBitmaps[dispObj];
		var renderOpts:Object = spriteRenderOpts[dispObj];
		var roundLoc:Boolean = (rot % 90 == 0 && dispObj.scaleX == 1.0 && dispObj.scaleY == 1.0);

		var boundsX:Number = bounds.left, boundsY:Number = bounds.top;
		var childRender:ChildRender = bitmapsByID[bmID] as ChildRender;
		if (childRender && childRender.isPartial()) {
			boundsX += childRender.inner_x * bounds.width;
			boundsY += childRender.inner_y * bounds.height;
			w *= childRender.inner_w;
			h *= childRender.inner_h;
		}

		rot *= Math.PI / 180;
		var cos:Number = Math.cos(rot);
		var sin:Number = Math.sin(rot);
		var TLx:Number = dispObj.x + (boundsX * cos - boundsY * sin) * dispObj.scaleX;
		var TLy:Number = dispObj.y + (boundsY * cos + boundsX * sin) * dispObj.scaleY;

		var cosW:Number = cos * w;
		var sinW:Number = sin * w;
		var cosH:Number = cos * h;
		var sinH:Number = sin * h;

		if (roundLoc) {
			TLx = Math.round(TLx);
			TLy = Math.round(TLy);
		}

		var TRx:Number = TLx + cosW;
		var TRy:Number = TLy + sinW;

		var BRx:Number = TLx + cosW - sinH;
		var BRy:Number = TLy + sinW + cosH;

		var BLx:Number = TLx - sinH;
		var BLy:Number = TLy + cosH;

		// Setup the texture data
		var texIndex:int = textureIndexByID[bmID];
		var texture:ScratchTextureBitmap = textures[texIndex];
		var rect:Rectangle = texture.getRect(bmID);
		var forcePixelate:Boolean = pixelateAll || (renderOpts && rot % 90 == 0 && (w == rect.width || renderOpts.bitmap != null));
		var left:Number = rect.left / texture.width;
		var right:Number = rect.right / texture.width;
		var top:Number = rect.top / texture.height;
		var bottom:Number = rect.bottom / texture.height;
		if (debugTexture) {
			uiContainer.graphics.moveTo(TLx, TLy);
			uiContainer.graphics.lineTo(TRx, TRy);
			uiContainer.graphics.lineTo(BRx, BRy);
			uiContainer.graphics.lineTo(BLx, BLy);
			uiContainer.graphics.lineTo(TLx, TLy);
		}

		// Setup the shader data
		var alpha:Number = dispObj.alpha;
		var mosaic:Number = 1;
		var pixelate:Number = 1;
		var radians:Number = 0;
		var hueShift:Number = 0;
		var brightnessShift:Number = 0;
		var fisheye:Number = 1;
		var effects:Object = (renderOpts ? renderOpts.effects : null);
		if (effects) {
			var scale:Number = ('isStage' in dispObj && dispObj['isStage'] ? 1 : scratchStage.scaleX);
			var srcWidth:Number = dw * scale; // Is this right?
			var srcHeight:Number = dh * scale;
			hueShift = ((360.0 * effects[FX_COLOR]) / 200.0) % 360.0;

			var n:Number = Math.max(0, Math.min(effects[FX_GHOST], 100));
			alpha = 1.0 - (n / 100.0);

			mosaic = Math.round((Math.abs(effects[FX_MOSAIC]) + 10) / 10);
			mosaic = Math.floor(Math.max(1, Math.min(mosaic, Math.min(srcWidth, srcHeight))));
			pixelate = (Math.abs(effects[FX_PIXELATE] * scale) / 10) + 1;
			radians = (Math.PI * (effects[FX_WHIRL])) / 180;
			fisheye = Math.max(0, (effects[FX_FISHEYE] + 100) / 100);
			brightnessShift = Math.max(-100, Math.min(effects[FX_BRIGHTNESS], 100)) / 100;
		}

		if (renderOpts && renderOpts.costumeFlipped) {
			var tmp:Number = right;
			right = left;
			left = tmp;
		}

		var pixelX:Number = (pixelate > 1 || forcePixelate ? pixelate / rect.width : -1);
		var pixelY:Number = (pixelate > 1 || forcePixelate ? pixelate / rect.height : -1);
		if (pixelate > 1) {
			pixelX *= rect.width / srcWidth;
			pixelY *= rect.height / srcHeight;
		}

		var perQuadData:ByteArray = new ByteArray();
		perQuadData.endian = Endian.LITTLE_ENDIAN;
		perQuadData.writeFloat(left);			// u0
		perQuadData.writeFloat(top);			// v0
		perQuadData.writeFloat(right - left);	// w
		perQuadData.writeFloat(bottom - top); 	// h
		perQuadData.writeFloat(texIndex);
		if (shaderConfig.effectActive[FX_PIXELATE]) {
			perQuadData.writeFloat(pixelX);
			perQuadData.writeFloat(pixelY);
		}
		if (shaderConfig.effectActive[FX_COLOR]) perQuadData.writeFloat(hueShift);
		if (shaderConfig.effectActive[FX_FISHEYE]) perQuadData.writeFloat(fisheye);
		if (shaderConfig.effectActive[FX_WHIRL]) perQuadData.writeFloat(radians);
		if (shaderConfig.effectActive[FX_MOSAIC]) perQuadData.writeFloat(mosaic);
		if (shaderConfig.effectActive[FX_BRIGHTNESS]) perQuadData.writeFloat(brightnessShift);
		if (shaderConfig.effectActive[FX_GHOST]) perQuadData.writeFloat(alpha);

		vertexData.writeFloat(TLx);				// x
		vertexData.writeFloat(TLy);				// y
		vertexData.writeFloat(0);				// z - use index?
		vertexData.writeFloat(0);				// u
		vertexData.writeFloat(0);				// v
		vertexData.writeBytes(perQuadData);

		vertexData.writeFloat(BLx);				// x
		vertexData.writeFloat(BLy);				// y
		vertexData.writeFloat(0);
		vertexData.writeFloat(0);				// u
		vertexData.writeFloat(1);				// v
		vertexData.writeBytes(perQuadData);

		vertexData.writeFloat(BRx);				// x
		vertexData.writeFloat(BRy);				// y
		vertexData.writeFloat(0);
		vertexData.writeFloat(1);				// u
		vertexData.writeFloat(1);				// v
		vertexData.writeBytes(perQuadData);

		vertexData.writeFloat(TRx);				// x
		vertexData.writeFloat(TRy);				// y
		vertexData.writeFloat(0);
		vertexData.writeFloat(1);				// u
		vertexData.writeFloat(0);				// v
		vertexData.writeBytes(perQuadData);
	}

	private function cleanUpUnusedBitmaps():void {
		var deletedBMs:Array = [];
		for (var k:Object in bitmapsByID) {
			var bmID:String = k as String;
			var isUsed:Boolean = false;

			for (var spr:Object in spriteBitmaps) {
				if (spriteBitmaps[spr] == bmID) {
					isUsed = true;
					break;
				}
			}

			if (!isUsed) {
				if (bitmapsByID[bmID] is ChildRender)
					bitmapsByID[bmID].dispose();
				deletedBMs.push(bmID);
			}
		}

		for each(bmID in deletedBMs)
			delete bitmapsByID[bmID];
	}

	public function updateRender(dispObj:DisplayObject, renderID:String = null, renderOpts:Object = null):void {
		var setBounds:Boolean = false;
		if (renderID && spriteBitmaps[dispObj] != renderID) {
			spriteBitmaps[dispObj] = renderID;

			setBounds = true;
			unrenderedChildren[dispObj] = !bitmapsByID[renderID];
		}
		if (renderOpts) {
			var oldEffects:Object = spriteRenderOpts[dispObj] ? spriteRenderOpts[dispObj].effects : null;
//				var oldBM:BitmapData = spriteRenderOpts[dispObj] ? spriteRenderOpts[dispObj].bitmap : null;
			var opts:Object = spriteRenderOpts[dispObj] || (spriteRenderOpts[dispObj] = {});

			if (renderOpts.bounds) {
				boundsDict[dispObj] = (renderOpts.raw_bounds && renderOpts.bitmap ? renderOpts.raw_bounds : renderOpts.bounds);
				// Handle bitmaps that need cropping
//				if(renderOpts.raw_bounds) {
//					var bm:BitmapData = renderOpts.bitmap;
//					var oldBM:BitmapData = opts.sub_bitmap;
//					if(bm) {
//						var w:int = Math.ceil(b.width), h:int = Math.ceil(b.height);
//						if(oldBM && oldBM != bm && (w != oldBM.width || h != oldBM.height)) {
//							oldBM.dispose();
//							oldBM = opts.sub_bitmap = null;
//						}
//
//						if(!oldBM && (w < bm.width || h < bm.height)) {
//							var cropR:Rectangle = b.clone();
//							var rawBounds:Rectangle = renderOpts.raw_bounds;
//							cropR.offset(-rawBounds.x, -rawBounds.y);
//
//							var cropped:BitmapData = new BitmapData(w, h, true, 0);
//							cropped.copyPixels(bm, cropR, new Point(0, 0));
//							opts.sub_bitmap = cropped;
//						}
//					}
//					else if(oldBM) {
//						oldBM.dispose();
//						opts.sub_bitmap = null;
//					}
//				}
			}

			for (var prop:String in renderOpts)
				opts[prop] = renderOpts[prop];
		}

//		if(renderOpts && renderOpts.costume) {
//			getB
//		}

		// Bitmaps can update their renders
		if (dispObj is Bitmap)
			unrenderedChildren[dispObj] = true;
	}

	public function updateCostume(dispObj:DisplayObject, costume:DisplayObject):void {
		var rawBounds:Rectangle = costume.getBounds(costume);
		var c:Object = costume as Object;
		var s:Shape = c.getShape();
		var bounds:Rectangle = s.getBounds(s);
		var boundsOffset:Point = bounds.topLeft.subtract(rawBounds.topLeft);
	}

//	private var costumeBounds:Object = {};
//	private function getBoundsFromCostume(costume:DisplayObject):void {
//		var c:Object = costume as Object;
//		if(!costumeBounds[c.baseLayerMD5]) {
//			var rawBounds:Rectangle = costume.getBounds(costume);
//			var s:Shape = c.getShape();
//			var bounds:Rectangle = s.getBounds(s);
//			var boundsOffset:Point = bounds.topLeft.subtract(rawBounds.topLeft);
//
//		}
//	}

	// Calls perEffect(effectName:String) for each supported effect name.
	private static function forEachEffect(perEffect:Function): void {
		for (var i:int = 0; i < effectNames.length; ++i) {
			var effectName:String = effectNames[i];
			perEffect(effectName);
		}
	}

	public function updateFilters(dispObj:DisplayObject, effects:Object):void {
		var spriteOpts:Object = spriteRenderOpts[dispObj] || (spriteRenderOpts[dispObj] = {});
		var spriteEffects:Object = spriteOpts.effects || (spriteOpts.effects = {});

		forEachEffect(function(effectName:String):void {
			if (spriteEffects[effectName]) effectRefs[effectName] -= 1;
			spriteEffects[effectName] = (effects && effectName in effects) ? effects[effectName] : 0;
			if (spriteEffects[effectName]) effectRefs[effectName] += 1;

			var newCount:int = effectRefs[effectName];
			if (newCount < 0) {
				Scratch.app.logMessage('Reference count negative for effect ' + effectName);
			}
			else if (newCount > spriteRenderOpts.length) {
				Scratch.app.logMessage('Reference count too high for effect ' + effectName);
			}
		});
	}

	public function updateGeometry(dispObj:DisplayObject):void {
		movedChildren[dispObj] = true;
	}

	// TODO: store multiple sizes of bitmaps?
	private static var noTrans:ColorTransform = new ColorTransform();

	private function checkChildRender(dispObj:DisplayObject):Boolean {
		// TODO: Have updateRender send the new id instead of using ScratchSprite's internals
		var id:String = spriteBitmaps[dispObj];
		if (!id) {
			if ('img' in dispObj) return false;
			id = spriteBitmaps[dispObj] = 'bm' + Math.random();
		}

		var renderOpts:Object = spriteRenderOpts[dispObj];
		var bounds:Rectangle = boundsDict[dispObj] || (boundsDict[dispObj] = renderOpts.bounds);
		var dw:Number = bounds.width * dispObj.scaleX * scratchStage.scaleX;
		var dh:Number = bounds.height * dispObj.scaleY * scratchStage.scaleY;

		var effects:Object = null, s:Number = 0, srcWidth:Number = 0, srcHeight:Number = 0;
		var mosaic:uint;
		var scale:Number = globalScale;
		var isNew:Boolean = false;
		if (renderOpts) {
			effects = renderOpts.effects;
			if (renderOpts.bitmap != null) {
				isNew = !bitmapsByID[id];
				bitmapsByID[id] = renderOpts.bitmap;//renderOpts.sub_bitmap ? renderOpts.sub_bitmap : renderOpts.bitmap;

				return (isNew || unrenderedChildren[dispObj]);
			}
			else if (effects && FX_MOSAIC in effects) {
				s = scale * (renderOpts.isStage ? 1 : scratchStage.scaleX);
				srcWidth = dw * s;
				srcHeight = dh * s;
				mosaic = Math.round((Math.abs(effects[FX_MOSAIC]) + 10) / 10);
				mosaic = Math.max(1, Math.min(mosaic, Math.min(srcWidth, srcHeight)));
				scale = scale / mosaic;
			}
		}
		else if (dispObj is Bitmap) { // Remove else to allow graphics effects on video layer
			isNew = !bitmapsByID[id];
			bitmapsByID[id] = (dispObj as Bitmap).bitmapData;
			if (unrenderedChildren[dispObj] && textureIndexByID.hasOwnProperty(id)) {
//trace('Should re-render '+Dbg.printObj(dispObj)+' with id '+id);
				var texture:ScratchTextureBitmap = textures[textureIndexByID[id]];
				texture.updateBitmap(id, bitmapsByID[id]);
			}

			return isNew;
		}

		// Hacky but should work
		scratchStage.visible = true;
		var width:Number = dw * scale;
		var height:Number = dh * scale;
		var bmd:BitmapData = bitmapsByID[id];
		if (bmd) {
			// If the bitmap changed or the sprite is now large than the stored render then re-render it
			//trace(bounds2 + ' vs '+bmd.width+'x'+bmd.height);
			if ((id.indexOf('bm') != 0 || !unrenderedChildren[dispObj]) && bmd.width >= width && bmd.height >= height) {
				//trace('USING existing bitmap');

				scratchStage.visible = false;
				return false;
			}
			else if (bmd is ChildRender) {
				if ((bmd as ChildRender).needsResize(width, height)) {
					bmd.dispose();
					bmd = null;
				}
				else if ((bmd as ChildRender).needsRender(dispObj, width, height, stagePenLayer)) {
					(bmd as ChildRender).reset(dispObj, stagePenLayer);
					if ('clearCachedBitmap' in dispObj)
						(dispObj as Object).clearCachedBitmap();

					trace('Re-rendering part of large sprite! ' + Dbg.printObj(dispObj));
				}
				else {
					scratchStage.visible = false;
					return false;
				}
			}
		}

		// Take the snapshot
		// TODO: Remove ability to use sub-renders because it breaks image effects like whirls, mosaic, and fisheye
		// OR disable whirl, mosaic, and fisheye for subrendered sprites
		var flipped:Boolean = renderOpts && renderOpts.costumeFlipped;
		if (flipped) {
			(dispObj as Object).setRotationStyle("don't rotate");
			bounds = (dispObj as Object).getVisibleBounds(dispObj);
		}

		var width2:Number = Math.max(1, width);
		var height2:Number = Math.max(1, height);
		var updateTexture:Boolean = !!bmd;
		if (!bmd) bmd = new ChildRender(width2, height2, dispObj, stagePenLayer, bounds);
		else bmd.fillRect(bmd.rect, 0x00000000);

		if (bmd is ChildRender)
			scale *= (bmd as ChildRender).scale;

		var drawMatrix:Matrix = new Matrix(1, 0, 0, 1, -bounds.x, -bounds.y);
		if (bmd is ChildRender && (bmd as ChildRender).isPartial())
			drawMatrix.translate(-(bmd as ChildRender).inner_x * bounds.width, -(bmd as ChildRender).inner_y * bounds.height);
		drawMatrix.scale(dispObj.scaleX * scale * scratchStage.scaleX, dispObj.scaleY * scale * scratchStage.scaleY);
		var oldAlpha:Number = dispObj.alpha;
		dispObj.alpha = 1;

		var oldImgTrans:ColorTransform = null;
		if ('img' in dispObj) {
			oldImgTrans = (dispObj as Object).img.transform.colorTransform;
			(dispObj as Object).img.transform.colorTransform = noTrans;
		}

		// Render to bitmap!
		var oldVis:Boolean = dispObj.visible;
		dispObj.visible = false;
		dispObj.visible = true;
//if('objName' in dispObj)
//trace(Dbg.printObj(dispObj)+' ('+(dispObj as Object).objName+' - '+id+') rendered @ '+bmd.width+'x'+bmd.height+'  --  '+bounds+' -- '+(dispObj as Object).getVisibleBounds(dispObj));
		bmd.draw(dispObj, drawMatrix, null, null, null, false);

		dispObj.visible = oldVis;
		dispObj.alpha = oldAlpha;
		if ('img' in dispObj)
			(dispObj as Object).img.transform.colorTransform = oldImgTrans;

		if (flipped)
			(dispObj as Object).setRotationStyle('left-right');

		scratchStage.visible = false;
//trace('Rendered bitmap with id '+id);

//trace(Dbg.printObj(dispObj)+' Rendered '+Dbg.printObj(bmd)+' with id: '+id+' @ '+bmd.width+'x'+bmd.height);
//trace('Original render size was '+bounds2);
		if (updateTexture && textureIndexByID.hasOwnProperty(id))
			textures[textureIndexByID[id]].updateBitmap(id, bmd);
		bitmapsByID[id] = bmd;

		//movedChildren[dispObj] = true;
		unrenderedChildren[dispObj] = false;
		return !updateTexture;
	}

	public function spriteIsLarge(dispObj:DisplayObject):Boolean {
		var id:String = spriteBitmaps[dispObj];
		if (!id) return false;
		var cr:ChildRender = bitmapsByID[id];
		return (cr && cr.isPartial());
	}

	public var debugTexture:Boolean = false;

	private function toggleTextureDebug(evt:KeyboardEvent):void {
		if (evt.ctrlKey && evt.charCode == 108) {
			debugTexture = !debugTexture;
		}
	}

	private function packTextureBitmaps():void {
		var penID:String = spriteBitmaps[stagePenLayer];
		if (textures.length < 1)
			textures.push(new ScratchTextureBitmap(512, 512));

		if (!penPacked && penID != null) {
			var bmList:Object = {};
			bmList[penID] = bitmapsByID[penID];

			// TODO: Can we fit other small textures with the pen layer into the first bitmap?
			(textures[0] as ScratchTextureBitmap).packBitmaps(bmList);
			textureIndexByID[penID] = 0;
			penPacked = true;
		}

		var cleanedUnused:Boolean = false;
		while (true) {
			var unpackedBMs:Object = {};
			var bmsToPack:int = 0;

			for (var k:Object in bitmapsByID)
				if (k != penID) {// && (!textureIndexByID.hasOwnProperty(k) || textureIndexByID[k] < 0)) {
					unpackedBMs[k] = bitmapsByID[k];
					++bmsToPack;
				}

			//trace('pack textures! ('+bmsToPack+')');
			for (var i:int = 1; i < 6 && bmsToPack > 0; ++i) {
				if (i >= textures.length)
					textures.push(new ScratchTextureBitmap(texSize, texSize));

				var newTex:ScratchTextureBitmap = textures[i];
				var packedIDs:Array = newTex.packBitmaps(unpackedBMs);
				for (var j:int = 0; j < packedIDs.length; ++j) {
					//trace('packed bitmap '+packedIDs[j]+': '+bitmapsByID[packedIDs[j]].rect);
					textureIndexByID[packedIDs[j]] = i;
					delete unpackedBMs[packedIDs[j]];
				}
				bmsToPack -= packedIDs.length;
			}

			if (debugTexture) {
				var offset:Number = 0;
				for (i = 0; i < textures.length; ++i) {
					newTex = textures[i];
					if (i >= testBMs.length)
						testBMs.push(new Bitmap(newTex));
					var testBM:Bitmap = testBMs[i];
					//testBM.scaleX = testBM.scaleY = 0.5;
					testBM.x = offset;
//						trace('Debugging '+Dbg.printObj(newTex));
					testBM.y = -900;
					testBM.bitmapData = newTex;
					scratchStage.stage.addChild(testBM);
					for (k in bitmapsByID) {
						if (i == textureIndexByID[k]) {
							var rect:Rectangle = newTex.getRect(k as String).clone();
							uiContainer.graphics.drawRect(testBM.x + rect.x * testBM.scaleX, rect.y * testBM.scaleX, rect.width * testBM.scaleX, rect.height * testBM.scaleX);
						}
					}
					offset += testBM.width;
				}
			}

			if (bmsToPack > 0) {
				if (!cleanedUnused) {
					cleanUpUnusedBitmaps();
					cleanedUnused = true;
				}
				else {
					// Bail on 3D
					statusCallback(false);
					throw Error('Unable to fit all bitmaps into the textures!');
				}
			}
			else {
				break;
			}
		}
	}

	private var drawCount:uint = 0;
	//private var lastTime:int = 0;
	private function onRender(e:Event):void {
		if (!scratchStage) return;
		//trace('frame was '+(getTimer() - lastTime)+'ms.');
		//lastTime = getTimer();

		if (scratchStage.stage.stage3Ds[0] == null || __context == null ||
				__context.driverInfo == "Disposed") {
			if (__context) __context.dispose();
			__context = null;
			onContextLoss();
			return;
		}

		draw();
		render(childrenDrawn);
		__context.present();
		++drawCount;

		// Invalidate cached renders
		for (var o:Object in cachedOtherRenderBitmaps)
			cachedOtherRenderBitmaps[o].inner_x = Number.NaN;
	}

	public function getRender(bmd:BitmapData):void {
		if (scratchStage.stage.stage3Ds[0] == null || __context == null ||
				__context.driverInfo == "Disposed") {
			return;
		}

		if (!indexBuffer) checkBuffers();
		draw();
		__context.configureBackBuffer(bmd.width, bmd.height, 0, false);
		render(childrenDrawn);
		__context.drawToBitmapData(bmd);
		//bmd.draw(uiContainer);
		scissorRect = null;
		setRenderView();
	}

	private var emptyStamp:BitmapData = new BitmapData(1, 1, true, 0);

	public function getRenderedChild(dispObj:DisplayObject, width:Number, height:Number, for_carry:Boolean = false):BitmapData {
		if (dispObj.parent != scratchStage || !__context)
			return emptyStamp;

		if (!spriteBitmaps[dispObj] || unrenderedChildren[dispObj] || !bitmapsByID[spriteBitmaps[dispObj]]) {
			if (checkChildRender(dispObj)) {
				packTextureBitmaps();
				checkBuffers();
			}
		}

		// Check if we can use the cached stamp
		var renderOpts:Object = spriteRenderOpts[dispObj];
		var effects:Object = renderOpts ? renderOpts.effects : null;
		var id:String = spriteBitmaps[dispObj];
		var iw:int = Math.ceil(Math.round(width * 100) / 100);
		var ih:int = Math.ceil(Math.round(height * 100) / 100);
		if (iw < 1 || ih < 1) return emptyStamp;

		if (stampsByID[id] && !for_carry) {
			var changed:Boolean = (stampsByID[id].width != iw || stampsByID[id].height != ih);
			if (!changed) {
				var old_fx:Object = stampsByID[id].effects;
				var prop:String;
				if (old_fx) {
					for (prop in old_fx) {
						if (prop == FX_GHOST) continue;
						if (old_fx[prop] == 0 && !effects) continue;
						if (!effects || old_fx[prop] != effects[prop]) {
							changed = true;
							break;
						}
					}
				}
				else {
					for (prop in effects) {
						if (prop == FX_GHOST) continue;
						if (effects[prop] != 0) {
							changed = true;
							break;
						}
					}
				}
			}

			if (!changed)
				return stampsByID[id];
		}

		var bmd:BitmapData = new SpriteStamp(iw, ih, effects);
		var rot:Number = dispObj.rotation;
		dispObj.rotation = 0;
		var oldScaleX:Number = dispObj.scaleX;
		var oldScaleY:Number = dispObj.scaleY;
		var bounds:Rectangle = boundsDict[dispObj];
		dispObj.scaleX *= width / Math.floor(bounds.width * dispObj.scaleX * scratchStage.scaleX * globalScale);
		dispObj.scaleY *= height / Math.floor(bounds.height * dispObj.scaleY * scratchStage.scaleY * globalScale);

		var oldX:Number = dispObj.x;
		var oldY:Number = dispObj.y;
		dispObj.x = -bounds.x * dispObj.scaleX;
		dispObj.y = -bounds.y * dispObj.scaleY;
		vertexData.position = 0;
		//pixelateAll = true;
		drawChild(dispObj);
		//pixelateAll = false;
		dispObj.x = oldX;
		dispObj.y = oldY;
		dispObj.scaleX = oldScaleX;
		dispObj.scaleY = oldScaleY;
		dispObj.rotation = rot;

		if (vertexData.position == 0)
			return bmd;

		// TODO: Find out why the index buffer isn't uploaded sometimes
		indexBufferUploaded = false;
		uploadBuffers();

		var changeBackBuffer:Boolean = (bmd.width > scissorRect.width || bmd.height > scissorRect.height);
		if (changeBackBuffer) {
			var newW:int = Math.max(scissorRect.width, bmd.width), newH:int = Math.max(scissorRect.height, bmd.height);
			projMatrix = createOrthographicProjectionMatrix(newW, newH, 0, 0);
			__context.configureBackBuffer(newW, newH, 0, false);
		}

		__context.setScissorRectangle(new Rectangle(0, 0, bmd.width + 1, bmd.height + 1));
		render(1, false);
		__context.drawToBitmapData(bmd);
		// TODO: Fix bright edges of renders
//		trace('Edge pixel: 0x'+bmd.getPixel32(bmd.width - 1, bmd.height - 1).toString(16).toUpperCase());

		if (changeBackBuffer) {
			scissorRect = null;
			// Reset scissorRect and framebuffer size
			setupContext3D();
		}
		else
			__context.setScissorRectangle(scissorRect);

		if (!for_carry) stampsByID[id] = bmd;
		return bmd;
	}

//	private var testTouchBM:Bitmap;
	private var cachedOtherRenderBitmaps:Dictionary;

	public function getOtherRenderedChildren(skipObj:DisplayObject, scale:Number):BitmapData {
		if (skipObj.parent != scratchStage)
			return null;

		var bounds:Rectangle = boundsDict[skipObj];
		var width:uint = Math.ceil(bounds.width * skipObj.scaleX * scale);
		var height:uint = Math.ceil(bounds.height * skipObj.scaleY * scale);
		var cr:ChildRender = cachedOtherRenderBitmaps[skipObj];
		if (cr && cr.width == width && cr.height == height) {
			// TODO: Can we efficiently cache this?  we'd have to check every other position / effect / etc
			if (cr.inner_x == skipObj.x && cr.inner_y == skipObj.y && cr.inner_w == skipObj.rotation)
				return cr;
			else
				cr.fillRect(cr.rect, 0x00000000);  // Is this necessary?
		}
		else {
			if (cr) cr.dispose();
			cr = cachedOtherRenderBitmaps[skipObj] = new ChildRender(width, height, skipObj, stagePenLayer, bounds);
		}

		var vis:Boolean = skipObj.visible;
		var rot:Number = skipObj.rotation;

		var childTL:Point = bounds.topLeft;
		var scaleX:Number = scratchStage.scaleX * scratchStage.stage.scaleX * globalScale;
		var scaleY:Number = scratchStage.scaleY * scratchStage.stage.scaleY * globalScale;
		childTL.x *= skipObj.scaleX;
		childTL.y *= skipObj.scaleY;
		var oldProj:Matrix3D = projMatrix.clone();
		projMatrix.prependScale(scale / scaleX, scale / scaleY, 1);
		projMatrix.prependTranslation(Math.floor(-childTL.x), Math.floor(-childTL.y), 0);
		projMatrix.prependRotation(-rot, Vector3D.Z_AXIS);
		projMatrix.prependTranslation(Math.floor(-skipObj.x), Math.floor(-skipObj.y), 0);

		skipObj.visible = false;
		pixelateAll = true;
		draw();
		pixelateAll = false;
		skipObj.visible = vis;
		__context.setScissorRectangle(cr.rect);
		render(childrenDrawn);
		__context.setScissorRectangle(scissorRect);
		projMatrix = oldProj;
		__context.drawToBitmapData(cr);
//		if(!testTouchBM) {
//			testTouchBM = new Bitmap(cr);
//			scratchStage.stage.addChild(testTouchBM);
//		}
//		testTouchBM.bitmapData = cr;
		cr.inner_x = skipObj.x;
		cr.inner_y = skipObj.y;
		cr.inner_w = skipObj.rotation;
		//trace(drawCount + '  Rendered everything except '+Dbg.printObj(skipObj));
		return cr;
	}

	private const FC0:Vector.<Number> = Vector.<Number>([1, 2, 0, 0.5]);
	private const FC1:Vector.<Number> = Vector.<Number>([Math.PI, 180, 60, 120]);
	private const FC2:Vector.<Number> = Vector.<Number>([240, 3, 4, 5]);
	private const FC3:Vector.<Number> = Vector.<Number>([6, 0.11, 0.09, 0.001]);
	private const FC4:Vector.<Number> = Vector.<Number>([360, 0, 0, 0]);

	private var registersUsed:int = 0;
	public function render(quadCount:uint, blend:Boolean = true):void {
		// assign shader program
		__context.setProgram(shaderConfig.program);

		// assign texture to texture sampler 0
		//__context.setScissorRectangle(getChildAt(0).getRect(stage));
		for (var i:int = 0; i < 6; ++i) {
			var tIdx:int = (i >= textures.length ? 0 : i);
			__context.setTextureAt(i, (textures[tIdx] as ScratchTextureBitmap).getTexture(__context));
		}

		__context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, projMatrix, true);

		// Constants for the fragment shader
		__context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, FC0);
		__context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, FC1);
		__context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, FC2);
		__context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 3, FC3);
		__context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 4, FC4);

		// x, y, z, {unused}
		__context.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);

		// u, v, u0, v0
		__context.setVertexBufferAt(1, vertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_4);

		// w, h, texture index, {unused}
		__context.setVertexBufferAt(2, vertexBuffer, 7, Context3DVertexBufferFormat.FLOAT_3);

		// allocate space for the rest of the effects, packed as tightly as possible
		var registerIndex:int = 3;
		var bufferPosition:int = 10;
		while (bufferPosition < shaderConfig.vertexComponents) {
			var format:String;
			switch (shaderConfig.vertexComponents - bufferPosition) {
				case 1:
					format = Context3DVertexBufferFormat.FLOAT_1;
					break;
				case 2:
					format = Context3DVertexBufferFormat.FLOAT_2;
					break;
				case 3:
					format = Context3DVertexBufferFormat.FLOAT_3;
					break;
				default: // 4 or more
					format = Context3DVertexBufferFormat.FLOAT_4;
					break;
			}
			__context.setVertexBufferAt(registerIndex, vertexBuffer, bufferPosition, format);
			++registerIndex;
			bufferPosition += 4; // bufferPosition could be incorrect when we leave this loop but that's currently OK.
		}

		// null out the remaining registers
		for (; registerIndex < registersUsed; ++registerIndex) {
			__context.setVertexBufferAt(registerIndex, null);
		}
		if (registersUsed < registerIndex) {
			registersUsed = registerIndex;
		}

		if (blend)
			__context.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
		else
			__context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);

		uploadBuffers();

		// draw all sprites
		__context.clear(0, 0, 0, 0);
		__context.drawTriangles(indexBuffer, 0, quadCount * 2);
	}

	private function setupContext3D(e:Event = null):void {
		if (!__context) {
			requestContext3D();
			return;
		}

		setRenderView();
		//__context.addEventListener(Event.ACTIVATE, setupContext3D);
		//__context.addEventListener(Event.DEACTIVATE, onContextLoss);

		__context.setDepthTest(false, Context3DCompareMode.ALWAYS);
		__context.enableErrorChecking = true;

		switchShaders();

		tlPoint = scratchStage.localToGlobal(originPt);
	}

	private function loadShaders():void {
		[Embed(source='shaders/vertex.agal', mimeType='application/octet-stream')] const VertexShader:Class;
		[Embed(source='shaders/fragment.agal', mimeType='application/octet-stream')] const FragmentShader:Class;

		function getUTF(embed:ByteArray):String {
			return embed.readUTFBytes(embed.length);
		}

		vertexShaderCode = getUTF(new VertexShader());
		fragmentShaderCode = getUTF(new FragmentShader());
	}

	private function switchShaders():void {
		// Number of 32-bit values associated with each effect
		// Must be kept in sync with FilterPack.filterNames, vertex format setup, and vertex buffer fill.
		const effectVertexComponents:Object = {
			pixelate: 2,
			color: 1,
			fisheye: 1,
			whirl: 1,
			mosaic: 1,
			brightness: 1,
			ghost: 1
		};

		var availableEffectRegisters:Array = [
			'v2.xxxx', 'v2.yyyy', 'v2.zzzz', 'v2.wwww',
			'v3.xxxx', 'v3.yyyy', 'v3.zzzz', 'v3.wwww'
		];

		// TODO: Bind the minimal number of textures and track the count. The shader must use every bound sampler.
		const maxTextureNum:int = 5; // index of the last texture in use

		var shaderID:int = maxTextureNum;
		forEachEffect(function(effectName:String): void {
			shaderID = (shaderID << 1) | (effectRefs[effectName] > 0 ? 1 : 0);
		});

		shaderConfig = shaderCache[shaderID];
		if (!shaderConfig) {
			var vertexShaderParts:Array = [];
			var fragmentShaderParts:Array = ['#define MAXTEXTURE ' + maxTextureNum];

			var numEffects: int = 0;
			var vertexComponents: int = 10; // x, y, z, u, v, u0, v0, w, h, texture index
			var effectActive:Object = {};
			forEachEffect(function(effectName:String): void {
				var isActive:Boolean = effectRefs[effectName] > 0;
				numEffects += int(isActive);
				effectActive[effectName] = isActive;
				fragmentShaderParts.push(['#define ENABLE_', effectName, ' ', int(isActive)].join(''));
				if (isActive) {
					vertexComponents += effectVertexComponents[effectName];
					if (effectName == FX_PIXELATE) {
						fragmentShaderParts.push('alias v2.xyxy, FX_' + effectName);
						++numEffects; // consume an extra register in the vertex shader
						availableEffectRegisters.shift(); // consume an extra register in the fragment shader
					}
					else {
						fragmentShaderParts.push(['alias ', availableEffectRegisters[0], ', FX_', effectName].join(''));
					}
					availableEffectRegisters.shift();
				}
			});

			vertexShaderParts.push('#define ACTIVE_EFFECTS '+numEffects);

			vertexShaderParts.push(vertexShaderCode);
			fragmentShaderParts.push(fragmentShaderCode);

			var completeVertexShaderCode:String = vertexShaderParts.join('\n');
			var completeFragmentShaderCode:String = fragmentShaderParts.join('\n');

			vertexShaderAssembler.assemble(Context3DProgramType.VERTEX, completeVertexShaderCode);
			if (vertexShaderAssembler.error.length > 0) {
				Scratch.app.logMessage('Error building vertex shader: ' + vertexShaderAssembler.error);
			}

			fragmentShaderAssembler.assemble(Context3DProgramType.FRAGMENT, completeFragmentShaderCode);
			if (fragmentShaderAssembler.error.length > 0) {
				Scratch.app.logMessage('Error building fragment shader: ' + fragmentShaderAssembler.error);
			}
			var program:Program3D = __context.createProgram();
			program.upload(vertexShaderAssembler.agalcode, fragmentShaderAssembler.agalcode);

			shaderCache[shaderID] = shaderConfig = {
				program: program,
				vertexComponents: vertexComponents,
				vertexSizeBytes: 4 * vertexComponents,
				effectActive: effectActive
			};
		}

		// Throw away the old vertex buffer: it probably has the wong data size per vertex
		if (vertexBuffer != null) {
			vertexBuffer.dispose();
			vertexBuffer = null;
		}
	}

	private function context3DCreated(e:Event):void {
		if (!contextRequested) {
			onContextLoss(e);
		}

		contextRequested = false;
		if (!scratchStage) {
			__context = null;
			(e.currentTarget as Stage3D).context3D.dispose();
			return;
		}
		else {
			scratchStage.visible = false;
			if (scratchStage.stage)
				globalScale = ('contentsScaleFactor' in scratchStage.stage ? scratchStage.stage['contentsScaleFactor'] : 1.0);
		}

		__context = (e.currentTarget as Stage3D).context3D;
		if (__context.driverInfo.toLowerCase().indexOf('software') > -1) {
			if (!callbackCalled) {
				callbackCalled = true;
				statusCallback(false);
			}
			setStage(null, null);

			return;
		}

		setupContext3D();
		if (scratchStage.visible)
			scratchStage.visible = false;

		if (!callbackCalled) {
			callbackCalled = true;
			statusCallback(true);
		}
	}

	private var callbackCalled:Boolean;


	private function requestContext3D():void {
		if (contextRequested || !stage3D) return;

		stage3D.addEventListener(Event.CONTEXT3D_CREATE, context3DCreated, false, 0, true);
		stage3D.addEventListener(ErrorEvent.ERROR, onStage3DError, false, 0, true);
		stage3D.requestContext3D(Context3DRenderMode.AUTO);
		contextRequested = true;
	}

	private function onStage3DError(e:Event):void {
		scratchStage.visible = true;
		if (!callbackCalled) {
			callbackCalled = true;
			statusCallback(false);
		}
		setStage(null, null);
	}

	private function onContextLoss(e:Event = null):void {
		for each(var config:Object in shaderCache) {
			config.program.dispose();
		}
		shaderCache = {};

		for (var i:int = 0; i < textures.length; ++i)
			(textures[i] as ScratchTextureBitmap).disposeTexture();

		if (vertexBuffer) {
			vertexBuffer.dispose();
			vertexBuffer = null;
		}

		if (indexBuffer) {
			//trace('disposing of indexBuffer!');
			indexBuffer.dispose();
			//trace('indexBuffer disposed');
			indexBuffer = null;
		}

		for (var id:String in bitmapsByID)
			if (bitmapsByID[id] is ChildRender)
				bitmapsByID[id].dispose();
		bitmapsByID = {};

		for (id in stampsByID)
			stampsByID[id].dispose();
		stampsByID = {};

		indexBufferUploaded = false;
		vertexBufferUploaded = false;
		scissorRect = null;

		if (!e) requestContext3D();
	}

	private static var sRawData:Vector.<Number> =
			new <Number>[1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];

	private function createOrthographicProjectionMatrix(width:Number, height:Number, x:Number, y:Number):Matrix3D {
		// this is a projection matrix that gives us an orthographic view of the world (meaning there's no perspective effect)
		// the view is defined with (0,0) being in the middle,
		//	(-viewWidth / 2, -viewHeight / 2) at the top left,
		// 	(viewWidth / 2, viewHeight / 2) at the bottom right,
		//	and 'near' and 'far' giving limits to the range of z values for objects to appear.
		var m:Matrix3D = new Matrix3D();
		sRawData[0] = 2.0 / width;
		sRawData[1] = 0;
		sRawData[4] = 0;
		sRawData[5] = -2.0 / height;
		sRawData[12] = -(2 * x + width) / width;
		sRawData[13] = (2 * y + height) / height;
		m.copyRawDataFrom(sRawData);
		return m;
	}
}}
}

internal final class Dbg {
	public static function printObj(obj:*):String {
		var memoryHash:String;

		try {
			FakeClass(obj);
		}
		catch (e:Error) {
			memoryHash = String(e).replace(/.*([@|\$].*?) to .*$/gi, '$1');
		}

		return flash.utils.getQualifiedClassName(obj) + memoryHash;
	}
}

internal final class FakeClass {
}
