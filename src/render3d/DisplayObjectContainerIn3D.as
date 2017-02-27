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

/**
 *   A display object container which renders in 3D instead
 *   @author Shane M. Clements, shane.m.clements@gmail.com
 */

import flash.display.Sprite;

public class DisplayObjectContainerIn3D extends Sprite {
	public static var texSizeMax:int = 2048;
	public static var texSize:int = 1024;
	public static var maxTextures:uint = 15;
SCRATCH::allow3d{
	import com.adobe.utils.*;

	import filters.FilterPack;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Stage3D;
	import flash.display.StageQuality;
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
	import flash.system.Capabilities;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Endian;

	private static const FX_PIXELATE:String = 'pixelate';
	private static const FX_COLOR:String = 'color';
	private static const FX_FISHEYE:String = 'fisheye';
	private static const FX_WHIRL:String = 'whirl';
	private static const FX_MOSAIC:String = 'mosaic';
	private static const FX_BRIGHTNESS:String = 'brightness';
	private static const FX_GHOST:String = 'ghost';

	// The elements of this array must match FilterPack.filterNames, but not necessarily in the same order.
	private static const effectNames:Array = [
		FX_PIXELATE, // since this is a two-component effect, put it first to guarantee alignment
		FX_COLOR, FX_FISHEYE, FX_WHIRL, FX_MOSAIC, FX_BRIGHTNESS, FX_GHOST];

	private var contextRequested:Boolean = false;
	private static var isIOS:Boolean = Capabilities.os.indexOf('iPhone') != -1;

	/** Context to create textures on */
	private var __context:Context3D;
	private var indexBuffer:IndexBuffer3D;
	private var vertexBuffer:VertexBuffer3D;
	private var currentShader:Program3D; // contains Program3D, vertex size, etc.
	private var shaderCache:Object; // mapping of shader config ID -> currentShader
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
	private var unrenderedChildren:Dictionary;
	private var stampsByID:Object;

	private var uiContainer:StageUIContainer;
	private var scratchStage:Sprite;
	private var stagePenLayer:DisplayObject;
	private var stage3D:Stage3D;
	private var pixelateAll:Boolean;
	private var statusCallback:Function;
	private var appScale:Number = 1;

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
		testBMs = [];
		textureCount = 0;
		childrenChanged = false;
		pixelateAll = false;
		unrenderedChildren = new Dictionary();
		stampsByID = {};
		loadShaders();
		makeBufferData();
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
			scratchStage.removeEventListener(Event.ENTER_FRAME, onRender);
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
			scratchStage.addEventListener(Event.ENTER_FRAME, onRender, false, 0, true);
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
//		scratchStage.stage.addEventListener(KeyboardEvent.KEY_DOWN, toggleTextureDebug, false, 0, true);
//		scratchStage.addEventListener(Event.ENTER_FRAME, onRender, false, 0, true);

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
//		scratchStage.removeEventListener(Event.ENTER_FRAME, onRender);

		onContextLoss(e);
		if (__context) {
			__context.dispose();
			__context = null;
		}
	}

	private static var originPt:Point = new Point();

	public function onStageResize(e:Event = null):void {
		scissorRect = null;
		if (scratchStage) {
			if (scratchStage.parent)
				appScale = scratchStage.stage.scaleX * scratchStage.root.scaleX * scratchStage.scaleX;

			if (uiContainer)
				uiContainer.transform.matrix = scratchStage.transform.matrix.clone();
		}
		setRenderView();
	}

	private var scissorRect:Rectangle;

	public function setRenderView():void {
		var p:Point = scratchStage.localToGlobal(originPt);
		stage3D.x = p.x;
		stage3D.y = p.y;
		var width:uint = Math.ceil(480 * appScale);
		var height:uint = Math.ceil(360 * appScale);
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
			updateFilters(displayObject, null);
			delete spriteRenderOpts[displayObject];
		}
	}

	private function makeBufferData():void {
		indexData.clear();
		indexData.endian = Endian.LITTLE_ENDIAN;
		//indexData.length = 12;

		indexData.position = 0;
		indexData.writeShort(0);
		indexData.writeShort(1);
		indexData.writeShort(2);
		indexData.writeShort(2);
		indexData.writeShort(3);
		indexData.writeShort(0);

		vertexData.clear();
		vertexData.endian = Endian.LITTLE_ENDIAN;
		//vertexData.length = 80;

		// Top left
		vertexData.writeFloat(0);				// x
		vertexData.writeFloat(0);				// y
		vertexData.writeFloat(0);				// z - use index?
		vertexData.writeFloat(0);				// u
		vertexData.writeFloat(0);				// v
		// Bottom left
		vertexData.writeFloat(0);				// x
		vertexData.writeFloat(1);				// y
		vertexData.writeFloat(0);
		vertexData.writeFloat(0);				// u
		vertexData.writeFloat(1);				// v
		// Bottom right
		vertexData.writeFloat(1);				// x
		vertexData.writeFloat(1);				// y
		vertexData.writeFloat(0);
		vertexData.writeFloat(1);				// u
		vertexData.writeFloat(1);				// v
		// Top right
		vertexData.writeFloat(1);				// x
		vertexData.writeFloat(0);				// y
		vertexData.writeFloat(0);
		vertexData.writeFloat(1);				// u
		vertexData.writeFloat(0);				// v
	}

	private function checkBuffers():Boolean {
		if (__context) {
			if (indexBuffer == null) {
				var numIndices:int = 6; // two triangles to make a quad
				indexBuffer = __context.createIndexBuffer(numIndices);
//  			trace('uploading indexBuffer when indexData length = '+indexData.length);
				indexBuffer.uploadFromByteArray(indexData, 0, 0, numIndices);
			}

			if (vertexBuffer == null) {
				var numVertices:int = 4;
				var data32PerVertex:int = 5; // x,y,z,u,v
				vertexBuffer = __context.createVertexBuffer(numVertices, data32PerVertex);
//			    trace('uploading vertexBuffer when vertexData length = '+vertexData.length);
				vertexBuffer.uploadFromByteArray(vertexData, 0, 0, numVertices);

				uploadConstantValues();
			}

			return true;
		}
		else {
			indexBuffer = null;
			vertexBuffer = null;
			return false;
		}
	}

	private var childrenDrawn:int = 0;
	private var tlPoint:Point;

	private function draw():void {
		var textureDirty:Boolean = false;
		var numChildren:uint = scratchStage.numChildren;
		var i:int;
		var dispObj:DisplayObject;

		checkBuffers();

		if (childrenChanged) {
			if (debugTexture) {
				uiContainer.graphics.clear();
				uiContainer.graphics.lineStyle(2, 0xFFCCCC);
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

		if (textureDirty)
			packTextureBitmaps();

		// Generally the clear color will be replaced by the backdrop and/or pen layer.
		// However, it will show when we render partially-off-stage regions for getOtherRenderedChildren().
		// Filling these regions with white matches the behavior we get in 2D.
		__context.clear(1, 1, 1, 1);

		if (childrenChanged) {// || effectsChanged) {
			vertexData.position = 0;
			childrenDrawn = 0;
			setBlendFactors(true);
			var skipped:uint = 0;
			for (i = 0; i < numChildren; ++i) {
				dispObj = scratchStage.getChildAt(i);
				if (!dispObj.visible) {
					++skipped;
					continue;
				}
				if (drawChild(dispObj))
					++childrenDrawn;
			}
			//trace('drew '+childrenDrawn+' children (vertexData.length = '+vertexData.length+')');
		}

		for (var key:Object in unrenderedChildren)
			delete unrenderedChildren[key];
	}

	private var boundsDict:Dictionary = new Dictionary();
	private var drawMatrix:Matrix3D = new Matrix3D();

	private function drawChild(dispObj:DisplayObject):Boolean {
		const bounds:Rectangle = boundsDict[dispObj];
		if (!bounds)
			return false;

		const bmID:String = spriteBitmaps[dispObj];
		const renderOpts:Object = spriteRenderOpts[dispObj];
		var dw:Number = bounds.width * dispObj.scaleX;

//		var boundsX:Number = bounds.left, boundsY:Number = bounds.top;
//		var childRender:ChildRender = bitmapsByID[bmID] as ChildRender;
//		if(childRender && childRender.isPartial()) {
//			boundsX += childRender.inner_x * bounds.width;
//			boundsY += childRender.inner_y * bounds.height;
//			w *= childRender.inner_w;
//			h *= childRender.inner_h;
//		}

		// Pick the correct shader before setting its constants
		var effects:Object;
		var shaderID:int;
		if (renderOpts) {
			effects = renderOpts.effects;
			shaderID = renderOpts.shaderID;
			if (shaderID < 0) {
				shaderID = renderOpts.shaderID = calculateShaderID(effects);
			}
		}
		else {
			effects = null;
			shaderID = 0;
		}
		switchShaders(shaderID);

		// Setup the texture data
		const texIndex:int = textureIndexByID[bmID];
		const texture:ScratchTextureBitmap = textures[texIndex];
		const rect:Rectangle = texture.getRect(bmID);
		var useNearest:Boolean = pixelateAll || (renderOpts && dispObj.rotation % 90 == 0 && (closeTo(dw, rect.width) || renderOpts.bitmap != null));

		setTexture(texture, useNearest);

		setMatrix(dispObj, bounds);

		setFC5(rect, renderOpts, texture);

		var componentIndex:int = calculateEffects(dispObj, bounds, rect, renderOpts, effects);

		setEffectConstants(componentIndex);

		drawTriangles();

		return true;
	}

	private var currentTexture:ScratchTextureBitmap = null;
	private var currentTextureFilter:String = null;

	private function setTexture(texture:ScratchTextureBitmap, useNearest:Boolean):void {
		if (texture != currentTexture) {
			__context.setTextureAt(0, texture.getTexture(__context));
			currentTexture = texture;
		}

		var desiredTextureFilter:String = useNearest ? Context3DTextureFilter.NEAREST : Context3DTextureFilter.LINEAR;
		if (currentTextureFilter != desiredTextureFilter) {
			__context.setSamplerStateAt(0, Context3DWrapMode.CLAMP, desiredTextureFilter, Context3DMipFilter.MIPNONE);
			currentTextureFilter = desiredTextureFilter;
		}
	}

	private var matrixScratchpad:Vector.<Number> = new Vector.<Number>(16, true);
	private const DegreesToRadians:Number = (2 * Math.PI) / -360; // negative because Flash uses clockwise rotation
	private function setMatrix(dispObj:DisplayObject, bounds:Rectangle):void {
		var scale:Number = dispObj.scaleX;
		var theta:Number = dispObj.rotation * DegreesToRadians;
		var boundsTop:Number = bounds.top;
		var boundsLeft:Number = bounds.left;
		var boundsWidth:Number = bounds.width;
		var boundsHeight:Number = bounds.height;
		var cosThetaScale:Number = Math.cos(theta) * scale;
		var sinThetaScale:Number = Math.sin(theta) * scale;

		// scratchpad = Scale(bounds) * Translate(bounds) * Scale(dispObj) * Rotate(dispObj) * Translate(dispObj)
		matrixScratchpad[0] = boundsWidth * cosThetaScale;
		matrixScratchpad[1] = boundsWidth * -sinThetaScale;
		matrixScratchpad[4] = boundsHeight * sinThetaScale;
		matrixScratchpad[5] = boundsHeight * cosThetaScale;
		matrixScratchpad[10] = 1;
		matrixScratchpad[12] = dispObj.x + boundsTop * sinThetaScale + boundsLeft * cosThetaScale;
		matrixScratchpad[13] = dispObj.y + boundsTop * cosThetaScale - boundsLeft * sinThetaScale;
		matrixScratchpad[15] = 1;

		drawMatrix.rawData = matrixScratchpad;
		drawMatrix.append(projMatrix);

		__context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, drawMatrix, true);
	}

	private function setFC5(rect:Rectangle, renderOpts:Object, texture:ScratchTextureBitmap):void {
		var left:Number = rect.left / texture.width;
		var right:Number = rect.right / texture.width;
		var top:Number = rect.top / texture.height;
		var bottom:Number = rect.bottom / texture.height;
		if (renderOpts && renderOpts.costumeFlipped) {
			var tmp:Number = right;
			right = left;
			left = tmp;
		}

		FC[5][0] = left;
		FC[5][1] = top;
		FC[5][2] = right - left;
		FC[5][3] = bottom - top;
	}

	private function calculateEffects(dispObj:DisplayObject, bounds:Rectangle, rect:Rectangle, renderOpts:Object, effects:Object):int {
		var componentIndex:int = 4 * 6 + 0; // skip to register 6, component 0

		if (effects) {
			var scale:Number = dispObj.scaleX;
			var dw:Number = bounds.width * scale;
			var dh:Number = bounds.height * scale;
			var srcScale:Number = ('isStage' in dispObj && dispObj['isStage'] ? 1 : appScale);
			var srcWidth:Number = dw * srcScale; // Is this right?
			var srcHeight:Number = dh * srcScale;

			var effectValue:Number;

			if (!!(effectValue = effects[FX_PIXELATE])) {
				var pixelate:Number = (Math.abs(effectValue * scale) / 10) + 1;
				var pixelX:Number = (pixelate > 1 ? pixelate / rect.width : -1);
				var pixelY:Number = (pixelate > 1 ? pixelate / rect.height : -1);
				if (pixelate > 1) {
					pixelX *= rect.width / srcWidth;
					pixelY *= rect.height / srcHeight;
				}
				FC[componentIndex >> 2][(componentIndex++) & 3] = pixelX;
				FC[componentIndex >> 2][(componentIndex++) & 3] = pixelY;
				FC[4][1] = pixelX / 2;
				FC[4][2] = pixelY / 2;
			}

			if (!!(effectValue = effects[FX_COLOR])) {
				FC[componentIndex >> 2][(componentIndex++) & 3] = ((360.0 * effectValue) / 200.0) % 360.0;
			}

			if (!!(effectValue = effects[FX_FISHEYE])) {
				FC[componentIndex >> 2][(componentIndex++) & 3] = Math.max(0, (effectValue + 100) / 100);
			}

			if (!!(effectValue = effects[FX_WHIRL])) {
				FC[componentIndex >> 2][(componentIndex++) & 3] = (Math.PI * effectValue) / 180;
			}

			if (!!(effectValue = effects[FX_MOSAIC])) {
				effectValue = Math.round((Math.abs(effectValue) + 10) / 10);
				FC[componentIndex >> 2][(componentIndex++) & 3] = Math.floor(Math.max(1, Math.min(effectValue, Math.min(srcWidth, srcHeight))));
			}

			if (!!(effectValue = effects[FX_BRIGHTNESS])) {
				FC[componentIndex >> 2][(componentIndex++) & 3] = Math.max(-100, Math.min(effectValue, 100)) / 100;
			}

			if (!!(effectValue = effects[FX_GHOST])) {
				FC[componentIndex >> 2][(componentIndex++) & 3] = 1.0 - (Math.max(0, Math.min(effectValue, 100)) / 100.0);
			}
		}

		return componentIndex;
	}

	private function setEffectConstants(componentIndex:int):void {
		componentIndex = (componentIndex + 3) >> 2; // ceil(componentIndex / 4)
		for (var registerIndex:int = 4; registerIndex < componentIndex; ++registerIndex)
			__context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, registerIndex, FC[registerIndex]);
	}

	private function uploadConstantValues():void {
		__context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, FC[0]);
		__context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, FC[1]);
		__context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, FC[2]);
		__context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 3, FC[3]);

		// x, y, z
		__context.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
		// u, v
		__context.setVertexBufferAt(1, vertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_2);
	}

	private var currentBlendFactor:String;

	private function setBlendFactors(blend:Boolean):void {
		var newBlendFactor:String = blend ? Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA : Context3DBlendFactor.ZERO;
		if (newBlendFactor == currentBlendFactor) return;

		// Since we use pre-multiplied alpha, the source blend factor is always ONE
		__context.setBlendFactors(Context3DBlendFactor.ONE, newBlendFactor);
		currentBlendFactor = newBlendFactor;
	}

	private function drawTriangles():void {
		// draw the sprite
		__context.drawTriangles(indexBuffer, 0, 2);
	}

	private static function calculateShaderID(effects:Object):int {
		var shaderID:int = 0;
		if (effects) {
			var numEffects:int = effectNames.length;
			for (var i:int = 0; i < numEffects; ++i) {
				var effectName:String = effectNames[i];
				shaderID = (shaderID << 1) | (!!effects[effectName] ? 1 : 0);
			}
		}
		return shaderID;
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

	public function updateFilters(dispObj:DisplayObject, effects:Object):void {
		var spriteOpts:Object = spriteRenderOpts[dispObj] || (spriteRenderOpts[dispObj] = {});
		spriteOpts.effects = effects || {};
		spriteOpts.shaderID = -1; // recalculate at next draw time
	}

	// TODO: store multiple sizes of bitmaps?
	private static const maxScale:uint = 4;
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
		var dw:Number = bounds.width * dispObj.scaleX * Math.min(maxScale, appScale * scratchStage.stage.contentsScaleFactor);
		var dh:Number = bounds.height * dispObj.scaleY * Math.min(maxScale, appScale * scratchStage.stage.contentsScaleFactor);

		var effects:Object = null, s:Number = 0, srcWidth:Number = 0, srcHeight:Number = 0;
		var mosaic:uint;
		var scale:Number = 1;
		var isNew:Boolean = false;
		if (renderOpts) {
			effects = renderOpts.effects;
			if (renderOpts.bitmap != null) {
				isNew = !bitmapsByID[id];
				bitmapsByID[id] = renderOpts.bitmap;//renderOpts.sub_bitmap ? renderOpts.sub_bitmap : renderOpts.bitmap;

				return (isNew || unrenderedChildren[dispObj]);
			}
			else if (effects && FX_MOSAIC in effects) {
				s = renderOpts.isStage ? 1 : appScale;
				srcWidth = dw * s;
				srcHeight = dh * s;
				mosaic = Math.round((Math.abs(effects[FX_MOSAIC]) + 10) / 10);
				mosaic = Math.max(1, Math.min(mosaic, Math.min(srcWidth, srcHeight)));
				scale = 1 / mosaic;
			}
		}
		if (dispObj is Bitmap) {
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
//			trace(width +'x'+ height + ' vs '+bmd.width+'x'+bmd.height);
			if ((id.indexOf('bm') != 0 || !unrenderedChildren[dispObj]) && closeTo(bmd.width, width) && closeTo(bmd.height, height)) {
//					trace('USING existing bitmap: '+width +'x'+ height + '(Costume) vs '+bmd.width+'x'+bmd.height+'(BM)');
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
		drawMatrix.scale(dispObj.scaleX * scale * Math.min(maxScale, appScale * scratchStage.stage.contentsScaleFactor), dispObj.scaleY * scale * Math.min(maxScale, appScale * scratchStage.stage.contentsScaleFactor));
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
		bmd.drawWithQuality(dispObj, drawMatrix, null, null, null, false, StageQuality.BEST);

		dispObj.visible = oldVis;
		dispObj.alpha = oldAlpha;
		if ('img' in dispObj)
			(dispObj as Object).img.transform.colorTransform = oldImgTrans;

		if (flipped)
			(dispObj as Object).setRotationStyle('left-right');

		scratchStage.visible = false;
//trace(dispObj.parent.getChildIndex(dispObj)+' '+Dbg.printObj(dispObj)+' Rendered '+Dbg.printObj(bmd)+' with id: '+id+' @ '+bmd.width+'x'+bmd.height);
//trace('Original render size was '+bounds2);
		if (updateTexture && textureIndexByID.hasOwnProperty(id))
			textures[textureIndexByID[id]].updateBitmap(id, bmd);
		bitmapsByID[id] = bmd;

		//movedChildren[dispObj] = true;
		unrenderedChildren[dispObj] = false;
		return !updateTexture;
	}

	[inline]
	private function closeTo(a:Number, b:Number):Boolean {
		return Math.abs(a - b) < 2;
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
		var usedMaxTex:Boolean = false;
		var size:uint = texSize;
		while (true) {
			var unpackedBMs:Object = {};
			var bmsToPack:int = 0;

			for (var k:Object in bitmapsByID)
				if (k != penID) {// && (!textureIndexByID.hasOwnProperty(k) || textureIndexByID[k] < 0)) {
					unpackedBMs[k] = bitmapsByID[k];
					++bmsToPack;
				}

			//trace('pack textures! ('+bmsToPack+')');
			for (var i:int = 1; i < maxTextures && bmsToPack > 0; ++i) {
				if (i >= textures.length)
					textures.push(new ScratchTextureBitmap(size, size));

				var newTex:ScratchTextureBitmap = textures[i];
				var packedIDs:Array = newTex.packBitmaps(unpackedBMs);
				for (var j:int = 0; j < packedIDs.length; ++j) {
					//trace('packed bitmap '+packedIDs[j]+': '+bitmapsByID[packedIDs[j]].rect);
					textureIndexByID[packedIDs[j]] = i;
					delete unpackedBMs[packedIDs[j]];
				}
				bmsToPack -= packedIDs.length;
			}

			if (bmsToPack > 0) {
				if (!cleanedUnused) {
					cleanUpUnusedBitmaps();
					cleanedUnused = true;
				}
				else if (!usedMaxTex) {
					for (i = 1; i < textures.length; ++i) {
						textures[i].disposeTexture();
						textures[i].dispose();
						textures[i] = null;
					}
					textures.length = 1;

					size <<= 1;
					if (size >= texSizeMax) {
						usedMaxTex = true;
						size = texSizeMax;
					}
					trace('switching to larger textures (' + size + ')');
				}
				else {
					// Bail on 3D
					statusCallback(false);
					throw Error('Unable to fit all bitmaps into the textures!');
				}
			}
			else {
				if (debugTexture) {
//					uiContainer.graphics.clear();
//					uiContainer.graphics.lineStyle(1);
					var offset:Number = 0;
					for (i = 0; i < textures.length; ++i) {
						newTex = textures[i];
						if (i >= testBMs.length)
							testBMs.push(new Bitmap(newTex));
						var testBM:Bitmap = testBMs[i];
						testBM.scaleX = testBM.scaleY = 0.5;
						testBM.x = 380 + offset;

						var scale:Number = testBM.scaleX;
						var X:Number = testBM.x * scratchStage.root.scaleX;
//						trace('Debugging '+Dbg.printObj(newTex));
						//testBM.y = -900;
						testBM.bitmapData = newTex;
						scratchStage.stage.addChild(testBM);
						for (k in bitmapsByID) {
							if (i == textureIndexByID[k]) {
								var rect:Rectangle = newTex.getRect(k as String).clone();
								trace(rect);
//								uiContainer.graphics.drawRect(X + rect.x * scale, rect.y * scale, rect.width * scale, rect.height * scale);
							}
						}
						offset += testBM.width;
					}
				}

				break;
			}
		}

		currentTexture = null;
	}

	private var drawCount:uint = 0;
	//private var lastTime:int = 0;
	public function onRender(e:Event):void {
		if (!scratchStage) return;
		//trace('frame was '+(getTimer() - lastTime)+'ms.');
		//lastTime = getTimer();

		if (scratchStage.stage.stage3Ds[0] == null || __context == null || __context.driverInfo == "Disposed") {
			if (__context) __context.dispose();
			__context = null;
			onContextLoss();
			return;
		}

		draw();
		__context.present();
		++drawCount;

		// Invalidate cached renders
		for (var o:Object in cachedOtherRenderBitmaps)
			cachedOtherRenderBitmaps[o].inner_x = Number.NaN;
	}

	public function getRender(bmd:BitmapData):void {
		if (scratchStage.stage.stage3Ds[0] == null || __context == null || __context.driverInfo == "Disposed") {
			return;
		}

		if (!indexBuffer) checkBuffers();
		__context.configureBackBuffer(bmd.width, bmd.height, 0, false);
		draw();
		__context.drawToBitmapData(bmd);
		//__context.present();
		bmd.draw(uiContainer);
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
		var pScale:Number = appScale * scratchStage.stage.contentsScaleFactor;

		var changeBackBuffer:Boolean = isIOS || (bmd.width > scissorRect.width || bmd.height > scissorRect.height);
		if (changeBackBuffer) {
			projMatrix = createOrthographicProjectionMatrix(bmd.width, bmd.height, 0, 0);
			__context.configureBackBuffer(Math.max(32, bmd.width), Math.max(32, bmd.height), 0, false);
			pScale = 1;
		}

		dispObj.scaleX = width / Math.floor(bounds.width * pScale);
		dispObj.scaleY = height / Math.floor(bounds.height * pScale);

		var oldX:Number = dispObj.x;
		var oldY:Number = dispObj.y;
		dispObj.x = -bounds.x * dispObj.scaleX;
		dispObj.y = -bounds.y * dispObj.scaleY;

		__context.clear(0, 0, 0, 0);
		__context.setScissorRectangle(new Rectangle(0, 0, bmd.width + 1, bmd.height + 1));
		setBlendFactors(false);
		drawChild(dispObj);
		__context.drawToBitmapData(bmd);

		dispObj.x = oldX;
		dispObj.y = oldY;
		dispObj.scaleX = oldScaleX;
		dispObj.scaleY = oldScaleY;
		dispObj.rotation = rot;

		if (changeBackBuffer) {
			scissorRect = null;
			// Reset scissorRect and framebuffer size
			setupContext3D();
		}
		else {
			__context.setScissorRectangle(scissorRect);
		}

		if (!for_carry)
			stampsByID[id] = bmd;

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
		var scaleX:Number = appScale;
		var scaleY:Number = appScale;
		childTL.x *= skipObj.scaleX;
		childTL.y *= skipObj.scaleY;
		var oldProj:Matrix3D = projMatrix.clone();
		projMatrix.prependScale(scale / scaleX, scale / scaleY, 1);
		projMatrix.prependTranslation(-childTL.x, -childTL.y, 0);
		projMatrix.prependRotation(-rot, Vector3D.Z_AXIS);
		projMatrix.prependTranslation(-skipObj.x, -skipObj.y, 0);

		skipObj.visible = false;
		pixelateAll = true;
		__context.setScissorRectangle(cr.rect);
		draw();
		pixelateAll = false;
		skipObj.visible = vis;
		projMatrix = oldProj;
		__context.drawToBitmapData(cr);
		__context.setScissorRectangle(scissorRect);
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

	private var FC:Vector.<Vector.<Number>> = Vector.<Vector.<Number>>([
		Vector.<Number>([1, 2, 0, 0.5]), // FC0
		Vector.<Number>([Math.PI, 180, 60, 120]), // FC1
		Vector.<Number>([240, 3, 4, 5]), // FC2
		Vector.<Number>([6, 0.11, 0.09, 0.001]), // FC3
		Vector.<Number>([360, 0, 0, 0]), // FC4, partially available
		Vector.<Number>([0, 0, 0, 0]), // FC5, available
		Vector.<Number>([0, 0, 0, 0]), // FC6, available
		Vector.<Number>([0, 0, 0, 0]) // FC7, available
	]);

	private function setupContext3D(e:Event = null):void {
		if (!__context) {
			requestContext3D();
			return;
		}

		onStageResize();
		//__context.addEventListener(Event.ACTIVATE, setupContext3D);
		//__context.addEventListener(Event.DEACTIVATE, onContextLoss);

		__context.setDepthTest(false, Context3DCompareMode.ALWAYS);
		__context.enableErrorChecking = false;

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

	private var availableEffectRegisters:Array = [
		'fc6.xxxx', 'fc6.yyyy', 'fc6.zzzz', 'fc6.wwww',
		'fc7.xxxx', 'fc7.yyyy', 'fc7.zzzz', 'fc7.wwww'
	];
	private var vertexShaderParts:Array = [];
	private var fragmentShaderParts:Array = [];

	private function switchShaders(shaderID:int):void {
		var desiredShader:Program3D = shaderCache[shaderID];

		if (!desiredShader) {
			shaderCache[shaderID] = desiredShader = buildShader(shaderID);
		}

		if (currentShader != desiredShader) {
			currentShader = desiredShader;
			__context.setProgram(currentShader);
		}
	}

	private function buildShader(shaderID:int):Program3D {
		vertexShaderParts.length = 0;
		fragmentShaderParts.length = 0;
		var ri:int = 0;
		for (var i:int = 0, l:int = effectNames.length; i < l; ++i) {
			var effectName:String = effectNames[i];
			var isActive:Boolean = (shaderID & (1 << (l - i - 1))) != 0; // iterate bits "backwards" to match calculateShaderID
			fragmentShaderParts.push(['#define ENABLE_', effectName, ' ', int(isActive)].join(''));
			if (isActive) {
				if (effectName == FX_PIXELATE) {
					fragmentShaderParts.push('alias fc6.xyxy, FX_' + effectName);
					fragmentShaderParts.push('alias fc4.yzyz, FX_' + effectName + '_half');
					++ri; // consume an extra register in the fragment shader (we use both fc6.x and fc6.y)
				}
				else {
					fragmentShaderParts.push(['alias ', availableEffectRegisters[ri], ', FX_', effectName].join(''));
				}
				++ri;
			}
		}

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
		return program;
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
		else
			scratchStage.visible = false;

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
		stage3D.requestContext3D(Context3DRenderMode.AUTO, Context3DProfile.BASELINE);
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
			config.dispose();
		}
		shaderCache = {};
		currentShader = null;
		currentTexture = null;
		currentBlendFactor = null;
		currentTextureFilter = null;

		for (var i:int = 0; i < textures.length; ++i)
			(textures[i] as ScratchTextureBitmap).disposeTexture();

		if (vertexBuffer) {
			vertexBuffer.dispose();
			vertexBuffer = null;
		}

		if (indexBuffer) {
			indexBuffer.dispose();
			indexBuffer = null;
		}

		for (var id:String in bitmapsByID)
			if (bitmapsByID[id] is ChildRender)
				bitmapsByID[id].dispose();
		bitmapsByID = {};

		for (id in stampsByID)
			stampsByID[id].dispose();
		stampsByID = {};

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

	public function getUIContainer():Sprite {
		return uiContainer;
	}
}}
}

import flash.utils.getQualifiedClassName;

internal final class Dbg {
	public static function printObj(obj:*):String {
		var memoryHash:String;

		try {
			FakeClass(obj);
		}
		catch (e:Error) {
			memoryHash = String(e).replace(/.*([@|\$].*?) to .*$/gi, '$1');
		}

		return getQualifiedClassName(obj) + memoryHash;
	}
}

internal final class FakeClass {
}
