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

	private var contextRequested:Boolean = false;

	/** Context to create textures on */
	private var __context:Context3D;
	private var program:Program3D;
	private var indexBuffer:IndexBuffer3D;
	private var vertexBuffer:VertexBuffer3D;
	private var fragmentShaderAssembler:AGALMiniAssembler;
	private var vertexShaderAssembler:AGALMiniAssembler;
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

	/**
	 *   Make the texture
	 *   @param context Context to create textures on
	 *   @param sprite Sprite to use for the texture
	 *   @param bgColor Background color of the texture
	 */
	public function DisplayObjectContainerIn3D() {
		uiContainer = new StageUIContainer();
		uiContainer.graphics.lineStyle(1);
		spriteBitmaps = new Dictionary();
		spriteRenderOpts = new Dictionary();
		fragmentShaderAssembler = new AGALMiniAssembler();
		vertexShaderAssembler = new AGALMiniAssembler();
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
		scratchStage.stage.addEventListener(Event.RESIZE, onStageResize, false, 0, true);
//			scratchStage.stage.addEventListener(KeyboardEvent.KEY_DOWN, toggleTextureDebug, false, 0, true);
		scratchStage.addEventListener(Event.ENTER_FRAME, onRender, false, 0, true);

		penPacked = false;
		if (!__context) {
			checkBuffers();
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

	// 5 for x/y/z/u/v + 4 for u0/v0/w/h +
	// 9 for alpha, mosaic, pixelation x, pixelation y, whirlRadians, hue, saturation, brightness, texture index
	private var vStride:uint = 18;
	private var ovStride:uint = 4 * vStride;

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
	}

	public function getUIContainer():Sprite {
		return uiContainer;
	}

	private function checkBuffers():void {
		var resized:Boolean = false;
		var numChildren:uint = scratchStage.numChildren;
		var vertexDataMinSize:int = numChildren * ovStride << 2;
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

			vertexData.length = ovStride * numChildren << 2;
			resized = true;
			//trace('indexData resized');
		}

		if (__context) {
			if (resized || indexBuffer == null) {
				if (vertexBuffer) {
					vertexBuffer.dispose();
					vertexBuffer = null;
					indexBuffer.dispose();
					//trace('indexBuffer disposed');
					indexBuffer = null;
				}

				indexBuffer = __context.createIndexBuffer(indexData.length >> 1);
				//trace('indexBuffer created');
				indexBuffer.uploadFromByteArray(indexData, 0, 0, indexData.length >> 1);
				indexBufferUploaded = true;
				//trace('indexBuffer uploaded');

				vertexBuffer = __context.createVertexBuffer((indexData.length / 12) * 4, vStride);
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
		checkBuffers();

		var textureDirty:Boolean = false;
		var numChildren:uint = scratchStage.numChildren;
		var i:int;
		var dispObj:DisplayObject;
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

		if (childrenChanged) {
			vertexData.position = 0;
			childrenDrawn = 0;
			var skipped:uint = 0;
			for (i = 0; i < numChildren; ++i) {
				dispObj = scratchStage.getChildAt(i);
				if (!dispObj.visible) {
					//trace('Skipping hidden '+Dbg.printObj(dispObj));
					++skipped;
					continue;
				}
				drawChild(dispObj);
				++childrenDrawn;
			}
			//if(skipped>0) trace('Skipped rendering '+skipped+' hidden children.');
//trace(vertexData);
		}

		uploadBuffers(childrenDrawn);

//		if(childrenChanged) {
//			trace(indexData);
//			trace(vertexData);
//		}
		//childrenChanged = false;
		movedChildren = new Dictionary();
		unrenderedChildren = new Dictionary();
	}

	private function uploadBuffers(quadCount:uint):void {
		if (!indexBufferUploaded) {
			indexBuffer.uploadFromByteArray(indexData, 0, 0, indexData.length >> 1);
			//trace('indexBuffer uploaded');
			indexBufferUploaded = true;
		}
//			trace('Uploading buffers for '+quadCount+' children');
		vertexBuffer.uploadFromByteArray(vertexData, 0, 0, (indexData.length / 12) * 4);//quadCount*4);
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
//			var forcePixelate:Boolean = pixelateAll || (renderOpts && renderOpts.bitmap && rot % 90 == 0);

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

		//trace('UpdateTextureCoords() '+Dbg.printObj(dispObj)+'  -  '+rect);
		//if(dispObj is ScratchSprite) trace(rect + ' ' + w + ','+h);
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
//if('objName' in dispObj && (dispObj as Object)['objName'] == 'delete_all') {
//	trace('bmd.rect: '+rect+'    dispObj @ ('+dispObj.x+','+dispObj.y+')');
//	trace('bounds: '+bounds);
//	trace('raw bounds: '+renderOpts.raw_bounds);
//}

		// Setup the shader data
		var alpha:Number = dispObj.alpha;
		//trace('dispObj.visible = '+dispObj.visible+'    alpha = '+alpha);
		var mosaic:Number = 1;
		var pixelate:Number = 1;
		var radians:Number = 0;
		var hueShift:Number = 0;
		var brightnessShift:Number = 0;
		var fisheye:Number = 1;
		//trace('dispObj = '+Dbg.printObj(dispObj));
		var effects:Object = (renderOpts ? renderOpts.effects : null);
		if (effects) {
			var scale:Number = ('isStage' in dispObj && dispObj['isStage'] ? 1 : scratchStage.scaleX);
			var srcWidth:Number = dw * scale; // Is this right?
			var srcHeight:Number = dh * scale;
			hueShift = ((360.0 * effects["color"]) / 200.0) % 360.0;

			var n:Number = Math.max(0, Math.min(effects['ghost'], 100));
			alpha = 1.0 - (n / 100.0);

			mosaic = Math.round((Math.abs(effects["mosaic"]) + 10) / 10);
			mosaic = Math.floor(Math.max(1, Math.min(mosaic, Math.min(srcWidth, srcHeight))));
			pixelate = (Math.abs(effects["pixelate"] * scale) / 10) + 1;
			radians = (Math.PI * (effects["whirl"])) / 180;
			fisheye = Math.max(0, (effects["fisheye"] + 100) / 100);
			brightnessShift = Math.max(-100, Math.min(effects["brightness"], 100)) / 100;
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
		vertexData.writeFloat(TLx);				// x
		vertexData.writeFloat(TLy);				// y
		vertexData.writeFloat(0);				// z - use index?
		vertexData.writeFloat(0);				// u
		vertexData.writeFloat(0);				// v
		vertexData.writeFloat(left);			// u0
		vertexData.writeFloat(top);				// v0
		vertexData.writeFloat(right - left);	// w
		vertexData.writeFloat(bottom - top); 	// h
		vertexData.writeFloat(alpha);
		vertexData.writeFloat(mosaic);
		vertexData.writeFloat(pixelX);
		vertexData.writeFloat(pixelY);
		vertexData.writeFloat(radians);
		vertexData.writeFloat(hueShift);
		vertexData.writeFloat(fisheye);
		vertexData.writeFloat(brightnessShift);
		vertexData.writeFloat(texIndex);

		vertexData.writeFloat(BLx);				// x
		vertexData.writeFloat(BLy);				// y
		vertexData.writeFloat(0);
		vertexData.writeFloat(0);				// u
		vertexData.writeFloat(1);				// v
		vertexData.writeFloat(left);			// u0
		vertexData.writeFloat(top);				// v0
		vertexData.writeFloat(right - left);	// w
		vertexData.writeFloat(bottom - top); 	// h
		vertexData.writeFloat(alpha);
		vertexData.writeFloat(mosaic);
		vertexData.writeFloat(pixelX);
		vertexData.writeFloat(pixelY);
		vertexData.writeFloat(radians);
		vertexData.writeFloat(hueShift);
		vertexData.writeFloat(fisheye);
		vertexData.writeFloat(brightnessShift);
		vertexData.writeFloat(texIndex);

		vertexData.writeFloat(BRx);				// x
		vertexData.writeFloat(BRy);				// y
		vertexData.writeFloat(0);
		vertexData.writeFloat(1);				// u
		vertexData.writeFloat(1);				// v
		vertexData.writeFloat(left);			// u0
		vertexData.writeFloat(top);				// v0
		vertexData.writeFloat(right - left);	// w
		vertexData.writeFloat(bottom - top); 	// h
		vertexData.writeFloat(alpha);
		vertexData.writeFloat(mosaic);
		vertexData.writeFloat(pixelX);
		vertexData.writeFloat(pixelY);
		vertexData.writeFloat(radians);
		vertexData.writeFloat(hueShift);
		vertexData.writeFloat(fisheye);
		vertexData.writeFloat(brightnessShift);
		vertexData.writeFloat(texIndex);

		vertexData.writeFloat(TRx);				// x
		vertexData.writeFloat(TRy);				// y
		vertexData.writeFloat(0);
		vertexData.writeFloat(1);				// u
		vertexData.writeFloat(0);				// v
		vertexData.writeFloat(left);			// u0
		vertexData.writeFloat(top);				// v0
		vertexData.writeFloat(right - left);	// w
		vertexData.writeFloat(bottom - top); 	// h
		vertexData.writeFloat(alpha);
		vertexData.writeFloat(mosaic);
		vertexData.writeFloat(pixelX);
		vertexData.writeFloat(pixelY);
		vertexData.writeFloat(radians);
		vertexData.writeFloat(hueShift);
		vertexData.writeFloat(fisheye);
		vertexData.writeFloat(brightnessShift);
		vertexData.writeFloat(texIndex);
	}

	private function cleanUpUnusedBitmaps():void {
//trace('cleanUpUnusedBitmaps()');
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
//trace('Deleting bitmap '+bmID);
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

	public function updateFilters(dispObj:DisplayObject, effects:Object):void {
		if (spriteRenderOpts[dispObj]) spriteRenderOpts[dispObj].effects = effects;
		else spriteRenderOpts[dispObj] = {effects: effects};
	}

	public function updateGeometry(dispObj:DisplayObject):void {
//trace('updateGeometry!');
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

//trace('checkChildRender() '+Dbg.printObj(dispObj)+' with id: '+id);
		var filters:Array = null;
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
			else if (effects && 'mosaic' in effects) {
				s = scale * (renderOpts.isStage ? 1 : scratchStage.scaleX);
				srcWidth = dw * s;
				srcHeight = dh * s;
				mosaic = Math.round((Math.abs(effects["mosaic"]) + 10) / 10);
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

		//trace('Drawing!');
		if (!indexBuffer) checkBuffers();
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
						if (prop == 'ghost') continue;
						if (old_fx[prop] == 0 && !effects) continue;
						if (!effects || old_fx[prop] != effects[prop]) {
							changed = true;
							break;
						}
					}
				}
				else {
					for (prop in effects) {
						if (prop == 'ghost') continue;
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
		uploadBuffers(1);

		var changeBackBuffer:Boolean = (bmd.width > scissorRect.width || bmd.height > scissorRect.height);
		if (changeBackBuffer) {
			var newW:int = Math.max(scissorRect.width, bmd.width), newH:int = Math.max(scissorRect.height, bmd.height);
			projMatrix = createOrthographicProjectionMatrix(newW, newH, 0, 0);
			__context.configureBackBuffer(newW, newH, 0, false);
		}

		__context.setScissorRectangle(new Rectangle(0, 0, bmd.width + 1, bmd.height + 1));
		render(1, false);
		__context.drawToBitmapData(bmd);

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
		var scaleX:Number = scratchStage.scaleX * scratchStage.stage.scaleX;
		var scaleY:Number = scratchStage.scaleY * scratchStage.stage.scaleY;
		childTL.x *= skipObj.scaleX;
		childTL.y *= skipObj.scaleY;
		var oldProj:Matrix3D = projMatrix.clone();
		projMatrix.prependScale(scale / scaleX, scale / scaleY, 1);
		projMatrix.prependTranslation(-childTL.x, -childTL.y, 0);
		projMatrix.prependRotation(-rot, Vector3D.Z_AXIS);
		projMatrix.prependTranslation(-skipObj.x, -skipObj.y, 0);

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
	private const FC1:Vector.<Number> = Vector.<Number>([3.1415926535, 180, 60, 120]);
	private const FC2:Vector.<Number> = Vector.<Number>([240, 3, 4, 5]);
	private const FC3:Vector.<Number> = Vector.<Number>([6, 0.11, 0.09, 0.001]);
	private const FC4:Vector.<Number> = Vector.<Number>([360, 0, 0, 0]);

	public function render(quadCount:uint, blend:Boolean = true):void {
		// assign shader program
		__context.setProgram(program);

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

		// w, h, alpha, mosaic
		__context.setVertexBufferAt(2, vertexBuffer, 7, Context3DVertexBufferFormat.FLOAT_4);

		// pixelate_x, pixelate_y, whirlRadians, {unused}
		__context.setVertexBufferAt(3, vertexBuffer, 11, Context3DVertexBufferFormat.FLOAT_3);

		// hueShift, saturation, brightness, texture index
		__context.setVertexBufferAt(4, vertexBuffer, 14, Context3DVertexBufferFormat.FLOAT_4);

		if (blend)
			__context.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
		else
			__context.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ZERO);

		// draw all sprites
		//trace('Drawing '+quadCount+' children');
		__context.clear(0, 0, 0, 0);
		__context.drawTriangles(indexBuffer, 0, quadCount * 2);
		//trace('finished drawing() - '+drawCount);

		//childrenChanged = false;
		//movedChildren = new Dictionary();
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

		program = __context.createProgram();
		setupShaders();
		program.upload(vertexShaderAssembler.agalcode, fragmentShaderAssembler.agalcode);
		indexBuffer = __context.createIndexBuffer(indexData.length >> 1);
		//trace('indexBuffer created');
		indexBufferUploaded = false;
		vertexBuffer = __context.createVertexBuffer((indexData.length / 12) * 4, vStride);
		vertexBufferUploaded = false;
		tlPoint = scratchStage.localToGlobal(originPt);
	}

	private function setupShaders():void {
		vertexShaderAssembler.assemble(Context3DProgramType.VERTEX,
						"m44 op, va0, vc0\n" + // pos to clipspace
						"mov v0, va1\n" + // copy u,v, u0, v0
						"mov v1, va2\n" + // copy w, h, alpha, mosaic
						"mov v2, va3\n" + // copy p_x, p_y, whirlRadians, (push fisheye here?)
						"mov v3, va4\n" // copy hueShift, fisheye, brightness, texture index
		);

		fragmentShaderAssembler.assemble(Context3DProgramType.FRAGMENT,
			// FC0 = (1, 2, 0, 0.5)
			/*** Mosaic effect ***/
			"mul ft0.xyzw, v0.xyxy, v1.wwww\n" +
			"frc ft0.xyzw, ft0.xyzw\n" +

			/*** Pixelate effect ***/
			// Do xy = int(xy / pixels) * pixels
			"div ft2.xyzw, ft0.xyxy, v2.xyxy\n" +
			"frc ft1.xyzw, ft2.xyzw\n" +
			"sub ft2.xyzw, ft2.xyzw, ft1.xyzw\n" +
			"mul ft2.xyzw, ft2.xyzw, v2.xyxy\n" +

			// Get the middle pixel
			"div ft1.xyxy, v2.xyxy, fc0.yyyy\n" +
			"add ft2.xyzw, ft2.xyxy, ft1.xyxy\n" +

			// Use the pixelated UV?
			"sge ft1.x, v2.x, fc0.z\n" + // is pixelate_x >= 0?
			"mul ft2.xyzw, ft2.xyzw, ft1.xxxx\n" + // then use the pixelated UV
			"slt ft1.x, v2.x, fc0.z\n" + // is pixelate_x < 0?
			"mul ft0.xyzw, ft0.xyzw, ft1.xxxx\n" + // then use the pixelated UV
			"add ft0.xyzw, ft0.xyzw, ft2.xyzw\n" + // Add them together

			/*** Whirl effect ***/
			"mov ft0.zwzw, fc0.zzzz\n" +
			"mov ft4.xyzw, ft0.xyzw\n" +
			"sub ft0.xy, ft0.xy, fc0.ww\n" + // ft0.xy = vec
			"dp3 ft1.yyy, ft0.xyz, ft0.xyz\n" +
			"sqt ft1.x, ft1.y\n" + // ft.x = d, len(uv) from center of texture (0.5, 0.5)
			"div ft1.y, ft1.x, fc0.w\n" + // radius = 0.5 (to the edge)
			"sub ft1.y, fc0.x, ft1.y\n" + // ft1.y = factor

			"mul ft1.z, ft1.y, ft1.y\n" +
			"mul ft1.z, ft1.z, v2.z\n" + // ft1.z = a, using v2.w for whirlRadians
			"sin ft2.xyzw, ft1.zzzz\n" + // ft2.x = sinAngle
			"cos ft2.yyyy, ft1.zzzz\n" + // ft2.y = cosAngle

			"mul ft2.z, ft0.x, ft2.y\n" + // ft2.z = vec.x * cosAngle
			"mul ft2.w, ft0.y, ft2.x\n" + // ft2.w = vec.y * sinAngle
			"sub ft3.xyzw, ft2.zzzz, ft2.wwww\n" +

			"mul ft2.z, ft0.x, ft2.x\n" + // ft2.z = vec.x * sinAngle
			"mul ft2.w, ft0.y, ft2.y\n" + // ft2.w = vec.y * cosAngle
			"add ft3.yyyy, ft2.zzzz, ft2.wwww\n" +
			"add ft3.xy, ft3.xy, fc0.ww\n" + // ft3.y = p.y

			"sge ft1.y, ft1.x, fc0.w\n" +
			"mul ft4.xy, ft4.xy, ft1.yy\n" +
			"slt ft1.y, ft1.x, fc0.w\n" +
			"mul ft0.xy, ft3.xy, ft1.yy\n" +
			"add ft0.xy, ft4.xy, ft0.xy\n" +

			"sat ft0.xy, ft0.xy\n" +

			/*** Fisheye effect ***/ // fisheye = v3.y
			"sub ft1.xy, ft0.xy, fc0.ww\n" + // ft0.xy = vec = (uv - [0.5,0.5])
			"div ft2.xy, ft1.xy, fc0.ww\n" + // vec = vec / [0.5, 0.5]
			"mov ft2.zw, fc0.zz\n" +
			"dp3 ft1.yyy, ft2.xyz, ft2.xyz\n" + // ft1.y = length(vec)^2
			"sqt ft1.x, ft1.y\n" + // ft.x = length(vec)

			// Prevent divide by zero
			"seq ft3.y, ft1.x, fc0.z\n" + //int len_eq_zero = (v == 0);
			"mul ft3.x, fc3.w, ft3.y\n" + //tiny = 0.000001 * len_eq_zero; = ft3.x
			"add ft1.x, ft1.x, ft3.x\n" + //len = len + tiny;

			"div ft2.xy, ft2.xy, ft1.xx\n" + // vec2 = vec / len;
			"pow ft1.y, ft1.x, v3.y\n" + // r = pow(len, scaledPower);
			"mul ft2.xy, ft2.xy, ft1.yy\n" + // coords = center + (r * vec2 * center);
			"mul ft2.xy, ft2.xy, fc0.ww\n" +
			"add ft2.xy, ft2.xy, fc0.ww\n" +

			"sge ft1.x, ft1.y, fc0.x\n" +
			"mul ft0.xy, ft0.xy, ft1.xx\n" +
			"slt ft1.y, ft1.y, fc0.x\n" +
			"mul ft2.xy, ft2.xy, ft1.yy\n" +
			"add ft0.xy, ft2.xy, ft0.xy\n" +

			/*** Move the texture coordinates into the sub-texture space ***/
			"mul ft0.xyzw, ft0.xyzw, v1.xyxy\n" +
			"add ft0.xy, ft0.xy, v0.zw\n" +

			/*** Select texture to use ***/
			// Get the texture pixel using ft0.xy as the coordinates
			"seq ft5, v3.w, fc0.z\n" +	// Use texture 0?
			"tex ft1, ft0, fs0 <2d,clamp,linear,nomip>\n" +
			"mul ft1, ft1, ft5\n" +

			"seq ft5, v3.w, fc0.x\n" +	// Use texture 1?
			"tex ft2, ft0, fs1 <2d,clamp,linear,nomip>\n" +
			"mul ft2, ft2, ft5\n" +
			"add ft1, ft1, ft2\n" +

			"seq ft5, v3.w, fc0.y\n" +	// Use texture 2?
			"tex ft3, ft0, fs2 <2d,clamp,linear,nomip>\n" +
			"mul ft3, ft3, ft5\n" +
			"add ft1, ft1, ft3\n" +

			"seq ft5, v3.w, fc2.y\n" +	// Use texture 3?
			"tex ft4, ft0, fs3 <2d,clamp,linear,nomip>\n" +
			"mul ft4, ft4, ft5\n" +
			"add ft1, ft1, ft4\n" +

			"seq ft5, v3.w, fc2.z\n" +	// Use texture 4?
			"tex ft4, ft0, fs4 <2d,clamp,linear,nomip>\n" +
			"mul ft4, ft4, ft5\n" +
			"add ft1, ft1, ft4\n" +

			"seq ft5, v3.w, fc2.w\n" +	// Use texture 5?
			"tex ft4, ft0, fs5 <2d,clamp,linear,nomip>\n" +
			"mul ft4, ft4, ft5\n" +
			"add ft1, ft1, ft4\n" +

			/*** ft1 == (r, g, b, a) ***/
			// Now de-multiply the color values that Flash pre-multiplied
			// TODO: De-multiply the color values BEFORE texture atlasing
			"seq ft3.y, ft1.w, fc0.z\n" + //int alpha_eq_zero = (alpha == 0);	alpha_eq_zero	= ft3.y
			"sne ft3.z, ft1.w, fc0.z\n" + //int alpha_neq_zero = (alpha != 0);	alpha_neq_zero	= ft3.z
			"mul ft3.x, fc3.w, ft3.y\n" + //tiny = 0.000001 * alpha_eq_zero;		tiny		= ft3.x
			"add ft1.w, ft1.w, ft3.x\n" + //alpha = alpha + tiny;				Avoid division by zero, alpha != 0
			"div ft2.xyz, ft1.xyz, ft1.www\n" + //new_rgb = rgb / alpha
			"mul ft2.xyz, ft2.xyz, ft3.zzz\n" + //new_rgb = new_rgb * alpha_neq_zero

			"mul ft1.xyz, ft1.xyz, ft3.yyy\n" + //rgb = rgb * alpha_eq_zero
			"add ft1.xyz, ft1.xyz, ft2.xyz\n" + //rgb = rgb + new_rgb

			// Clamp the color
			"sat ft1, ft1\n" +

			/*** Color effect ***/
			// compute h, s, v														dst		= ft1
			//				float v = max(r, max(g, b));
			"max ft2.z, ft1.y, ft1.z\n" + //float v = max(dst.g, dst.b);				v		= ft2.z
			"max ft2.z, ft1.x, ft2.z\n" + //v = max(dst.r, v);

			//				float span = v - min(r, min(g, b));
			"min ft2.w, ft1.y, ft1.z\n" + //float span =  min(dst.g, dst.b);			span	= ft2.w
			"min ft2.w, ft1.x, ft2.w\n" + //span = min(dst.r, span);
			"sub ft2.w, ft2.z, ft2.w\n" + //span = v - span;

			//				if (span == 0.0) {
			//					h = s = 0.0;
			//				} else {
			//					if (r == v) h = 60.0 * ((g - b) / span);
			//					else if (g == v) h = 120.0 + (60.0 * ((b - r) / span));
			//					else if (b == v) h = 240.0 + (60.0 * ((r - g) / span));
			//					s = span / v;
			//				}
			"seq ft3.y, ft2.z, fc0.z\n" + //int v_eq_zero = (v == 0);
			"mul ft3.x, fc3.w, ft3.y\n" + //tiny = 0.000001 * v_eq_zero;				tiny	= ft3.x
			"add ft2.z, ft2.z, ft3.x\n" + //v = v + tiny;					Avoid division by zero, v != 0

			"seq ft3.y, ft2.w, fc0.z\n" + //int span_eq_zero = (span == 0);		span_eq_zero= ft3.y
			"sne ft2.y, ft2.w, fc0.z\n" + //int span_not_zero = (span != 0.0); span_not_zero	= ft2.y
			"seq ft3.y, ft1.x, ft2.z\n" + //int r_eq_v = (dst.r == v);				r_eq_v	= ft3.y
			"sne ft4.x, ft1.x, ft2.z\n" + //int r_not_v = (dst.r != v);				r_not_v	= ft4.x
			"seq ft3.z, ft1.y, ft2.z\n" + //int g_eq_v = (dst.g == v);				g_eq_v	= ft3.z
			"mul ft3.z, ft3.z, ft4.x\n" + //g_eq_v = g_eq_v * r_not_v
			"seq ft3.w, ft1.z, ft2.z\n" + //int b_eq_v = (dst.b == v);				b_eq_v	= ft3.w
			"add ft4.y, ft3.y, ft3.z\n" + //int not_g_eq_v_or_r_eq_v = r_eq_v + g_eq_v	not_g_eq_v_or_r_eq_v	= ft4.y
			"seq ft4.y, ft4.y, fc0.z\n" + //not_g_eq_v_or_r_eq_v = (not_g_eq_v_or_r_eq_v == 0)
			"mul ft3.w, ft3.w, ft4.y\n" + //b_eq_v = b_eq_v * not_g_eq_v_or_r_eq_v	// (b==v) is only valid when the other two are not

			"mul ft3.x, fc3.w, ft3.y\n" + //tiny = 0.000001 * span_eq_zero;			tiny	= ft3.x
			"add ft2.w, ft2.w, ft3.x\n" + //span = span + tiny;					Avoid division by zero, span != 0

			"mul ft3.y, ft3.y, ft2.y\n" + //r_eq_v = r_eq_v * span_not_zero;
			"mul ft3.z, ft3.z, ft2.y\n" + //g_eq_v = g_eq_v * span_not_zero;
			"mul ft3.w, ft3.w, ft2.y\n" + //b_eq_v = b_eq_v * span_not_zero;

			"div ft4.x, fc1.z, ft2.w\n" + //float 60_div_span = 60 / span;		60_div_span	= ft4.x
			"sub ft4.y, ft1.y, ft1.z\n" + //float h_r_eq_v = dst.g - dst.b;		h_r_eq_v	= ft4.y
			"mul ft4.y, ft4.y, ft4.x\n" + //h_r_eq_v = h_r_eq_v * 60_div_span;
			"mul ft4.y, ft4.y, ft3.y\n" + //h_r_eq_v = h_r_eq_v * r_eq_v;

			"sub ft4.z, ft1.z, ft1.x\n" + //float h_g_eq_v = dst.b - dst.r;		h_g_eq_v	= ft4.z
			"mul ft4.z, ft4.z, ft4.x\n" + //h_g_eq_v = h_g_eq_v * 60_div_span;
			"add ft4.z, ft4.z, fc1.w\n" + //h_g_eq_v = h_g_eq_v + 120;
			"mul ft4.z, ft4.z, ft3.z\n" + //h_g_eq_v = h_g_eq_v * g_eq_v;

			"sub ft4.w, ft1.x, ft1.y\n" + //float h_b_eq_v = dst.r - dst.g;		h_b_eq_v	= ft4.w
			"mul ft4.w, ft4.w, ft4.x\n" + //h_b_eq_v = h_b_eq_v * 60_div_span;
			"add ft4.w, ft4.w, fc2.x\n" + //h_b_eq_v = h_b_eq_v + 240;
			"mul ft4.w, ft4.w, ft3.w\n" + //h_b_eq_v = h_b_eq_v * b_eq_v;

			/*** ft2 == (h, s, v) ***/
			"mov ft2.x, ft4.y\n" +		 //float h = h_r_eq_v;							h	= ft2.x
			"add ft2.x, ft2.x, ft4.z\n" + //h = h + h_g_eq_v;
			"add ft2.x, ft2.x, ft4.w\n" + //h = h + h_b_eq_v;

			"div ft3.z, ft2.w, ft2.z\n" + //float s_span_not_zero = span / v; s_span_not_zero= ft3.z
			"mul ft2.y, ft3.z, ft2.y\n" + //float s = s_span_not_zero * span_not_zero;	s	= ft2.y

			//				if (hueShift != 0.0 && v < 0.11) { v = 0.11; s = 1.0; }
			/*** ft3 is now free ***/  // Check this section for accuracy / mistakes
			"sne ft3.y, v3.x, fc0.z\n" + //int hs_not_zero = (hueShift != 0.0);	hs_not_zero	= ft3.y
			"slt ft3.z, ft2.z, fc3.y\n" + //int v_lt_0_11 = (v < 0.11);			v_lt_0_11	= ft3.z
			"mul ft3.z, ft3.z, ft3.y\n" + //v_lt_0_11 = v_lt_0_11 * hs_not_zero;
			"seq ft3.w, ft3.z, fc0.z\n" + //int !v_lt_0_11						!v_lt_0_11	= ft3.w

			"mul ft2.z, ft2.z, ft3.w\n" + //v  = v * !v_lt_0_11
			"mul ft3.x, fc3.y, ft3.z\n" + //float vv = 0.11 * v_lt_0_11;					vv	= ft3.x
			"add ft2.z, ft2.z, ft3.x\n" + //v = v + vv;

			"mul ft2.y, ft2.y, ft3.w\n" + //s  = s * !v_lt_0_11
			"add ft2.y, ft2.y, ft3.z\n" + //s = s + v_lt_0_11;

			//				if (hueShift != 0.0 && s < 0.09) s = 0.09;
			"slt ft3.w, ft2.y, fc3.z\n" + //int s_lt_0_09 = (s < 0.09);			s_lt_0_09	= ft3.w
			"mul ft3.w, ft3.w, ft3.y\n" + //s_lt_0_09 = s_lt_0_09 * hs_not_zero;
			"seq ft3.z, ft3.w, fc0.z\n" + //int !s_lt_0_09						!s_lt_0_09	= ft3.z

			"mul ft2.y, ft2.y, ft3.z\n" + //s  = s * !s_lt_0_09
			"mul ft3.x, fc3.z, ft3.w\n" + //float ss = 0.09 * s_lt_0_09;					ss	= ft3.x
			"add ft2.y, ft2.y, ft3.x\n" + //s = s + ss;

			//				if (hueShift != 0.0 && (v == 0.11 || s == 0.09)) h = 0.0;
			"seq ft4.x, ft2.z, fc3.y\n" + //int v_eq_0_11 = (v == 0.11);			v_eq_0_11	= ft4.x
			"seq ft4.y, ft2.y, fc3.z\n" + //int s_eq_0_09 = (s == 0.09);			s_eq_0_09	= ft4.y
			"add ft4.z, ft4.x, ft4.y\n" + //int v_eq_0_11_or_s_eq_0_09 = v_eq_0_11 + s_eq_0_09;	v_eq_0_11_or_s_eq_0_09 = ft4.z
			"mul ft4.z, ft4.z, ft3.y\n" + //v_eq_0_11_or_s_eq_0_09 = v_eq_0_11_or_s_eq_0_09 * hs_not_zero;

			// Multiply h by !v_eq_0_11_or_s_eq_0_09. if v_eq_0_11_or_s_eq_0_09 is true, then h=0, otherwise it's untouched.
			"seq ft4.z, ft4.z, fc0.z\n" + //v_eq_0_11_or_s_eq_0_09 = !v_eq_0_11_or_s_eq_0_09
			"mul ft2.x, ft2.x, ft4.z\n" + //h = h * (!v_eq_0_11_or_s_eq_0_09);

			//				h = mod(h + hueShift, 360.0);
			"add ft2.x, ft2.x, v3.x\n" + //h = h + hueShift;
			"div ft2.x, ft2.x, fc4.x\n" + //h = h / 360;
			"frc ft2.x, ft2.x\n" + //h = frc h;
			"mul ft2.x, ft2.x, fc4.x\n" + //h = h * 360;

			//				if (h < 0.0) h += 360.0;
			"slt ft4.y, ft2.x, fc0.z\n" + //int h_lt_0 = (h < 0.0);					h_lt_0	= ft4.y
			"mul ft4.x, fc4.x, ft4.y\n" + //float hh = 360 * h_lt_0;						hh	= ft4.x
			"add ft2.x, ft2.x, ft4.x\n" + //h = h + hh;

			//				s = max(0.0, min(s, 1.0));
			"sat ft2.y, ft2.y\n" + //s = sat(s);

			//				v = max(0.0, min(v + brightnessShift, 1.0));
			"add ft2.z, ft2.z, v3.z\n" + //v = v + brightnessShift;
			"sat ft2.z, ft2.z\n" + //v = sat(v);

			//				int i = int(floor(h / 60.0));
			//				float f = (h / 60.0) - float(i);
			"div ft3.x, ft2.x, fc1.z\n" + //float h_div_60 =  h / 60;			h_div_60	= ft3.x
			"frc ft3.y, ft3.x\n" + //float f = frc(h_div_60);							f	= ft3.y
			"sub ft3.x, ft3.x, ft3.y\n" + //float i = h_div_60 - f;						i	= ft3.x

			//				float p = v * (1.0 - s);
			//				float q = v * (1.0 - (s * f));
			//				float t = v * (1.0 - (s * (1.0 - f)));
			/*** ft5 = [p, q, t, v] ***/
			"sub ft5.x, fc0.x, ft2.y\n" + //ft5.x = 1.0 - s; // p
			"mul ft5.x, ft5.x, ft2.z\n" + //ft5.x = ft5.x * v;
			"mul ft5.y, ft2.y, ft3.y\n" + //ft5.y = (s * f); // q
			"sub ft5.y, fc0.x, ft5.y\n" + //ft5.y = 1.0 - ft5.y;
			"mul ft5.y, ft5.y, ft2.z\n" + //ft5.y = ft5.y * v;
			"sub ft5.z, fc0.x, ft3.y\n" + //ft5.z = 1.0 - f; // t
			"mul ft5.z, ft2.y, ft5.z\n" + //ft5.z = s * ft5.z;
			"sub ft5.z, fc0.x, ft5.z\n" + //ft5.z = 1.0 - ft5.z;
			"mul ft5.z, ft5.z, ft2.z\n" + //ft5.z = ft5.z * v;
			"mov ft5.w, ft2.z\n" + //mov ft5.w, v; // v

			/*** FIX i to be an integer on Intel Graphics 3000 with Chrome Pepper Flash ***/
			"add ft3.x, ft3.x, fc0.w\n" + // fix i?
			"frc ft3.y, ft3.x\n" + // fix i?
			"sub ft3.x, ft3.x, ft3.y\n" + // fix i?

			"seq ft3.y, ft3.x, fc0.z\n" + //int i_eq_0 = (i == 0);					i_eq_0	= ft3.y
			"mul ft3.y, ft3.y, fc3.x\n" + //i_eq_0 = i_eq_0 * 6;
			"add ft3.x, ft3.x, ft3.y\n" + //i = i + i_eq_0;  -- Now i is only 1,2,3,4,5, or 6

			"seq ft3.y, ft3.x, fc0.x\n" + //int i_eq_1 = (i == 1);					i_eq_1	= ft3.y
			"seq ft3.z, ft3.x, fc0.y\n" + //int i_eq_2 = (i == 2);					i_eq_2	= ft3.z
			"seq ft3.w, ft3.x, fc2.y\n" + //int i_eq_3 = (i == 3);					i_eq_3	= ft3.w
			"seq ft4.x, ft3.x, fc2.z\n" + //int i_eq_4 = (i == 4);					i_eq_4	= ft4.x
			"seq ft4.y, ft3.x, fc2.w\n" + //int i_eq_5 = (i == 5);					i_eq_5	= ft4.y
			"seq ft4.z, ft3.x, fc3.x\n" + //int i_eq_6 = (i == 6);					i_eq_6	= ft4.z

			// Write to ft7.w ?
			//				if ((i == 0) || (i == 6)) dst.rgb = float3(v, t, p);
			"mul ft7.xyz, ft4.zzz, ft5.wzx\n" + //ft7 = i_eq_6 * ft5.wzx

			//				else if (i == 1) dst.rgb = float3(q, v, p);
			"mul ft6.xyz, ft3.yyy, ft5.ywx\n" + //ft6 = i_eq_1 * ft5.ywx
			"add ft7.xyz, ft7.xyz, ft6.xyz\n" + //ft7 = ft7 + ft6

			//				else if (i == 2) dst.rgb = float3(p, v, t);
			"mul ft6.xyz, ft3.zzz, ft5.xwz\n" + //ft6 = i_eq_2 * ft5.xwz
			"add ft7.xyz, ft7.xyz, ft6.xyz\n" + //ft7 = ft7 + ft6

			//				else if (i == 3) dst.rgb = float3(p, q, v);
			"mul ft6.xyz, ft3.www, ft5.xyw\n" + //ft6 = i_eq_3 * ft5.xyw
			"add ft7.xyz, ft7.xyz, ft6.xyz\n" + //ft7 = ft7 + ft6

			//				else if (i == 4) dst.rgb = float3(t, p, v);
			"mul ft6.xyz, ft4.xxx, ft5.zxw\n" + //ft6 = i_eq_4 * ft5.zxw
			"add ft7.xyz, ft7.xyz, ft6.xyz\n" + //ft7 = ft7 + ft6

			//				else if (i == 5) dst.rgb = float3(v, p, q);
			"mul ft6.xyz, ft4.yyy, ft5.wxy\n" + //ft6 = i_eq_5 * ft5.wxy
			"add ft7.xyz, ft7.xyz, ft6.xyz\n" + //ft7 = ft7 + ft6

			"sat ft1.xyz, ft7.xyz\n" +			// Move the shifted color into ft1

			/*** Ghost effect ***/
			"mul ft1.w, ft1.w, v1.z\n" +	// varying alpha in v1.z
			"mov oc, ft1\n" // fill ft0.x with v0.x and ft0.w with v0.w
		);
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
