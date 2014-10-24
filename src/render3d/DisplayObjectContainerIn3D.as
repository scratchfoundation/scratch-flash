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
import flash.system.Capabilities;
import flash.system.Capabilities;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Endian;

	private var contextRequested:Boolean = false;
	private static var isIOS:Boolean = Capabilities.os.indexOf('iPhone') != -1;

	/** Context to create textures on */
	private var __context:Context3D;
	private var program:Program3D;
	private var indexBuffer:IndexBuffer3D;
	private var vertexBuffer:VertexBuffer3D;
	private var shaderCache:Object; // mapping of shader config -> Program3D
	private var fragmentShaderAssembler:AGALMacroAssembler;
	private var vertexShaderAssembler:AGALMiniAssembler;
	private var fragmentShaderCode:String;
	private var spriteBitmaps:Dictionary;
	private var spriteRenderOpts:Dictionary;
	private var bitmapsByID:Object;

	/** Texture data */
	private var textures:Array;
	private var testBMs:Array;
	private var textureIndexByID:Object;
	private static var texSizeMax:int = 4096;
	private static var texSize:int = 1024;
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

	private var indexBufferUploaded:Boolean;
	private var vertexBufferUploaded:Boolean;
	private var uiContainer:StageUIContainer;
	private var scratchStage:Sprite;
	private var stagePenLayer:DisplayObject;
	private var stage3D:Stage3D;
	private var pixelateAll:Boolean;
	private var statusCallback:Function;
	private var appScale:Number = 1;

	private var effectRefs:Object;
	private var oldEffectRefs:Object;

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
		shaderCache = {};
		fragmentShaderAssembler = new AGALMacroAssembler();
		vertexShaderAssembler = new AGALMiniAssembler();
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
			if(scratchStage) {
			scratchStage.removeEventListener(Event.ADDED_TO_STAGE, addedToStage);
			scratchStage.removeEventListener(Event.ADDED, childAdded);
			scratchStage.removeEventListener(Event.REMOVED, childRemoved);
			scratchStage.removeEventListener(Event.REMOVED_FROM_STAGE, removedFromStage);
				if(scratchStage.stage)
				scratchStage.stage.removeEventListener(Event.RESIZE, onStageResize);
			scratchStage.cacheAsBitmap = true;
			(scratchStage as Object).img.cacheAsBitmap = true;
			scratchStage.visible = true;

				while(uiContainer.numChildren)
				scratchStage.addChild(uiContainer.getChildAt(0));

				for(var i:int=0; i<textures.length; ++i)
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
			if(scratchStage) {
			scratchStage.addEventListener(Event.ADDED_TO_STAGE, addedToStage, false, 0, true);
			scratchStage.addEventListener(Event.ADDED, childAdded, false, 0, true);
			scratchStage.addEventListener(Event.REMOVED, childRemoved, false, 0, true);
			scratchStage.addEventListener(Event.REMOVED_FROM_STAGE, removedFromStage, false, 0, true);
				if(scratchStage.stage)
				scratchStage.stage.addEventListener(Event.RESIZE, onStageResize, false, 0, true);
				if(__context) scratchStage.visible = false;
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
			if(e && e.target != scratchStage) return;
			scratchStage.parent.addChildAt(uiContainer, scratchStage.parent.getChildIndex(scratchStage)+1);
			for(var i:uint=0; i<scratchStage.numChildren; ++i) {
			var dispObj:DisplayObject = scratchStage.getChildAt(i);
				if(isUI(dispObj)) {
				uiContainer.addChild(dispObj);
				--i;
			}
				else if(!('img' in dispObj)) {
				// Set the bounds of any non-ScratchSprite display objects
				boundsDict[dispObj] = dispObj.getBounds(dispObj);
			}
		}
		uiContainer.transform.matrix = scratchStage.transform.matrix.clone();
		scratchStage.stage.addEventListener(Event.RESIZE, onStageResize, false, 0, true);
//		scratchStage.stage.addEventListener(KeyboardEvent.KEY_DOWN, toggleTextureDebug, false, 0, true);
		scratchStage.addEventListener(Event.ENTER_FRAME, onRender, false, 0, true);

		penPacked = false;
			if(!__context) {
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
			if(e.target != scratchStage) return;
		uiContainer.parent.removeChild(uiContainer);
			if(testBMs && testBMs.length) {
				for(var i:int=0; i<testBMs.length; ++i)
				scratchStage.stage.removeChild(testBMs[i]);
			testBMs = [];
		}

			for(var id:String in bitmapsByID)
				if(bitmapsByID[id] is ChildRender)
				bitmapsByID[id].dispose();
		bitmapsByID = {};

			for(var o:Object in cachedOtherRenderBitmaps)
			cachedOtherRenderBitmaps[o].dispose();

		cachedOtherRenderBitmaps = new Dictionary();

		//trace('Dying!');
		scratchStage.stage.removeEventListener(Event.RESIZE, onStageResize);
//			scratchStage.stage.removeEventListener(KeyboardEvent.KEY_DOWN, toggleTextureDebug);
		scratchStage.removeEventListener(Event.ENTER_FRAME, onRender);

		onContextLoss(e);
			if(__context) {
			__context.dispose();
			__context = null;
		}
	}

	private static var originPt:Point = new Point();

	public function onStageResize(e:Event = null):void {
		scissorRect = null;
		if(scratchStage) {
			if(scratchStage.parent)
				appScale = scratchStage.stage.scaleX *
						scratchStage.root.scaleX * scratchStage.scaleX;

			if(uiContainer)
			uiContainer.transform.matrix = scratchStage.transform.matrix.clone();
		}
		setRenderView();
	}

	private var scissorRect:Rectangle;

	public function setRenderView():void {
		var p:Point = scratchStage.localToGlobal(originPt);
		stage3D.x = p.x;
		stage3D.y = p.y;
		var width:uint = Math.ceil(480*appScale),
				height:uint = Math.ceil(360*appScale);
		var rect:Rectangle = new Rectangle(0, 0, width, height);
			if(stage3D.context3D && (!scissorRect || !scissorRect.equals(rect))) {
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
			if(e.target.parent != scratchStage) return;

		// Check special properties to determine if the child is UI or not
		var dispObj:DisplayObject = e.target as DisplayObject;
			if(isUI(dispObj)) {
			uiContainer.addChild(dispObj);
			//trace(Dbg.printObj(this)+': Child '+Dbg.printObj(e.target)+' ADDED to ui layer');
			return;
		}

		childrenChanged = true;
			if(!('img' in dispObj)) {
			// Set the bounds of any non-ScratchSprite display objects
			boundsDict[dispObj] = dispObj.getBounds(dispObj);
		}
//trace(Dbg.printObj(this)+': Child '+Dbg.printObj(e.target)+' ADDED');
	}

	private function isUI(dispObj:DisplayObject):Boolean {
		return ('target' in dispObj || 'answer' in dispObj || 'pointsLeft' in dispObj);
	}

	private function childRemoved(e:Event):void {
			if(e.target.parent != scratchStage) return;
		childrenChanged = true;
//trace(Dbg.printObj(this)+': Child '+Dbg.printObj(e.target)+' REMOVED');

		var bmID:String = spriteBitmaps[e.target];
			if(bmID) {
			delete spriteBitmaps[e.target];

//			if(bitmapsByID[bmID]) {
//				if(bitmapsByID[bmID] is ChildRender)
//					bitmapsByID[bmID].dispose();
//				delete bitmapsByID[bmID];
//			}
		}

			if(cachedOtherRenderBitmaps[e.target]) {
			cachedOtherRenderBitmaps[e.target].dispose();
			delete cachedOtherRenderBitmaps[e.target];
		}

			if(boundsDict[e.target])
			delete boundsDict[e.target];

		var displayObject:DisplayObject = e.target as DisplayObject;
		if (displayObject) {
			updateFilters(displayObject, {});
			delete spriteRenderOpts[displayObject];
		}
	}

	private function checkBuffers():void {
		var resized:Boolean = false;
		var numChildren:uint = scratchStage.numChildren;
		var vertexDataMinSize:int = numChildren * ovStride << 2;
			if(vertexDataMinSize > vertexData.length) {
			// Increase and fill in the index buffer
			var index:uint = indexData.length;
				var base:int = (index/12)*4;
			indexData.length = numChildren * 12;
			indexData.position = index;
			var numAdded:int = (indexData.length - index) / 12;
				for(var i:int=0; i<numAdded; ++i) {
				indexData.writeShort(base);
					indexData.writeShort(base+1);
					indexData.writeShort(base+2);
					indexData.writeShort(base+2);
					indexData.writeShort(base+3);
				indexData.writeShort(base);
				base += 4;
			}

			vertexData.length = ovStride * numChildren << 2;
			resized = true;
			//trace('indexData resized');
		}

			if(__context) {
				if(resized || indexBuffer == null) {
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

					vertexBuffer = __context.createVertexBuffer((indexData.length/12)*4, vStride);
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
			if(childrenChanged) {
				if(debugTexture) {
				uiContainer.graphics.clear();
				uiContainer.graphics.lineStyle(2, 0xFFCCCC);
			}
				for(i=0; i<numChildren; ++i) {
				dispObj = scratchStage.getChildAt(i);
					if(dispObj.visible)
					textureDirty = checkChildRender(dispObj) || textureDirty;
			}
		}
		else
				for(var child:Object in unrenderedChildren)
					if((child as DisplayObject).visible)
					textureDirty = checkChildRender(child as DisplayObject) || textureDirty;

			if(textureDirty) {
			packTextureBitmaps();
		}

			if(childrenChanged) {
			vertexData.position = 0;
			childrenDrawn = 0;
			var skipped:uint = 0;
				for(i=0; i<numChildren; ++i) {
				dispObj = scratchStage.getChildAt(i);
					if(!dispObj.visible) {
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
		for (var key:Object in unrenderedChildren)
			delete unrenderedChildren[key];

		var rebuildShader:Boolean = false;
		forEachEffect(function(effectName:String): void {
			if (!!oldEffectRefs[effectName] != !!effectRefs[effectName]) rebuildShader = true;
			oldEffectRefs[effectName] = effectRefs[effectName];
		});
		if (rebuildShader) {
			buildShaders();
		}
	}

	private function uploadBuffers(quadCount:uint):void {
			if(!indexBufferUploaded) {
			indexBuffer.uploadFromByteArray(indexData, 0, 0, indexData.length >> 1);
			//trace('indexBuffer uploaded');
			indexBufferUploaded = true;
		}
//			trace('Uploading buffers for '+quadCount+' children');
			vertexBuffer.uploadFromByteArray(vertexData, 0, 0, (indexData.length/12)*4);//quadCount*4);
		vertexBufferUploaded = true;
	}

	private var boundsDict:Dictionary = new Dictionary();

	private function drawChild(dispObj:DisplayObject):void {
		// Setup the geometry data
		var rot:Number = dispObj.rotation;
		const bounds:Rectangle = boundsDict[dispObj];
			if(!bounds)
			return;

		var dw:Number = bounds.width * dispObj.scaleX;
		var w:Number = dw;
		var dh:Number = bounds.height * dispObj.scaleY;
		var h:Number = dh;

		const bmID:String = spriteBitmaps[dispObj];
		const renderOpts:Object = spriteRenderOpts[dispObj];
		var roundLoc:Boolean = (rot % 90 == 0 && dispObj.scaleX == 1.0 && dispObj.scaleY == 1.0);
		var boundsX:Number = bounds.left, boundsY:Number = bounds.top;
		var childRender:ChildRender = bitmapsByID[bmID] as ChildRender;
			if(childRender && childRender.isPartial()) {
			boundsX += childRender.inner_x * bounds.width;
			boundsY += childRender.inner_y * bounds.height;
			w *= childRender.inner_w;
			h *= childRender.inner_h;
		}

			rot *= Math.PI/180;
		var cos:Number = Math.cos(rot);
		var sin:Number = Math.sin(rot);
		var TLx:Number = dispObj.x + (boundsX * cos - boundsY * sin) * dispObj.scaleX;
		var TLy:Number = dispObj.y + (boundsY * cos + boundsX * sin) * dispObj.scaleY;

		var cosW:Number = cos * w;
		var sinW:Number = sin * w;
		var cosH:Number = cos * h;
		var sinH:Number = sin * h;

			if(roundLoc) {
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
		const texIndex:int = textureIndexByID[bmID];
		const texture:ScratchTextureBitmap = textures[texIndex];
		const rect:Rectangle = texture.getRect(bmID);
			var forcePixelate:Boolean = pixelateAll || (renderOpts && rot % 90 == 0 && (w == rect.width || renderOpts.bitmap!=null));
		var left:Number = rect.left / texture.width;
		var right:Number = rect.right / texture.width;
		var top:Number = rect.top / texture.height;
		var bottom:Number = rect.bottom / texture.height;
			if(debugTexture) {
			uiContainer.graphics.moveTo(TLx, TLy);
			uiContainer.graphics.lineTo(TRx, TRy);
			uiContainer.graphics.lineTo(BRx, BRy);
			uiContainer.graphics.lineTo(BLx, BLy);
			uiContainer.graphics.lineTo(TLx, TLy);
		}
//if('objName' in dispObj && (dispObj as Object)['objName'] == 'delete_all') {
//	trace('bmd.rect: '+rect+'    dispObj @ ('+dispObj.x+','+dispObj.y+')');
//	trace(dispObj.parent.getChildIndex(dispObj) + ' ('+left+','+top+') -> ('+right+','+bottom+')');
//  trace('raw bounds: '+renderOpts.raw_bounds);
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
		const effects:Object = (renderOpts ? renderOpts.effects : null);
			if(effects) {
			var scale:Number = ('isStage' in dispObj && dispObj['isStage'] ? 1 : appScale);
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

			if(renderOpts && renderOpts.costumeFlipped) {
			var tmp:Number = right;
			right = left;
			left = tmp;
		}

		var pixelX:Number = (pixelate > 1 || forcePixelate ? pixelate / rect.width : -1);
		var pixelY:Number = (pixelate > 1 || forcePixelate ? pixelate / rect.height : -1);
			if(pixelate > 1) {
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
		vertexData.writeFloat(texIndex + 0.01);

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
		vertexData.writeFloat(texIndex + 0.02);

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
		vertexData.writeFloat(texIndex + 0.03);

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
		vertexData.writeFloat(texIndex + 0.04);
	}

		private function cleanUpUnusedBitmaps():void {
//trace('cleanupUnusedBitmaps()');
		var deletedBMs:Array = [];
		for (var k:Object in bitmapsByID) {
			var bmID:String = k as String;
			var isUsed:Boolean = false;

				for(var spr:Object in spriteBitmaps) {
					if(spriteBitmaps[spr] == bmID) {
					isUsed = true;
					break;
				}
			}

				if(!isUsed) {
//trace('Deleting bitmap '+bmID);
					if(bitmapsByID[bmID] is ChildRender)
					bitmapsByID[bmID].dispose();
				deletedBMs.push(bmID);
			}
		}

		for each(bmID in deletedBMs)
			delete bitmapsByID[bmID];
	}

	public function updateRender(dispObj:DisplayObject, renderID:String = null, renderOpts:Object = null):void {
		var setBounds:Boolean = false;
			if(renderID && spriteBitmaps[dispObj] != renderID) {
			spriteBitmaps[dispObj] = renderID;

			setBounds = true;
			unrenderedChildren[dispObj] = !bitmapsByID[renderID];
		}
			if(renderOpts) {
			var oldEffects:Object = spriteRenderOpts[dispObj] ? spriteRenderOpts[dispObj].effects : null;
//				var oldBM:BitmapData = spriteRenderOpts[dispObj] ? spriteRenderOpts[dispObj].bitmap : null;
			var opts:Object = spriteRenderOpts[dispObj] || (spriteRenderOpts[dispObj] = {});

				if(renderOpts.bounds) {
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

				for(var prop:String in renderOpts)
				opts[prop] = renderOpts[prop];
		}

//		if(renderOpts && renderOpts.costume) {
//			getB
//		}

		// Bitmaps can update their renders
			if(dispObj is Bitmap)
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
	private function forEachEffect(perEffect:Function): void {
		for (var i:int = 0; i < FilterPack.filterNames.length; ++i) {
			var effectName:String = FilterPack.filterNames[i];
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
				trace('Reference count negative for effect ' + effectName);
			}
			else if (newCount > spriteRenderOpts.length) {
				trace('Reference count too high for effect ' + effectName);
			}
		});
	}

	// TODO: store multiple sizes of bitmaps?
	private static const maxScale:uint = 4;
	private static var noTrans:ColorTransform = new ColorTransform();

	private function checkChildRender(dispObj:DisplayObject):Boolean {
		// TODO: Have updateRender send the new id instead of using ScratchSprite's internals
		var id:String = spriteBitmaps[dispObj];
			if(!id) {
				if('img' in dispObj) return false;
				id = spriteBitmaps[dispObj] = 'bm'+Math.random();
		}

//trace('checkChildRender() '+Dbg.printObj(dispObj)+' with id: '+id);
		var filters:Array = null;
		var renderOpts:Object = spriteRenderOpts[dispObj];
		var bounds:Rectangle = boundsDict[dispObj] || (boundsDict[dispObj] = renderOpts.bounds);
		var dw:Number = bounds.width * dispObj.scaleX * Math.min(maxScale, appScale * scratchStage.stage.contentsScaleFactor);
		var dh:Number =  bounds.height * dispObj.scaleY * Math.min(maxScale, appScale * scratchStage.stage.contentsScaleFactor);

		var effects:Object = null, s:Number = 0, srcWidth:Number = 0, srcHeight:Number = 0;
		var mosaic:uint;
		var scale:Number = 1;
		var isNew:Boolean = false;
			if(renderOpts) {
			effects = renderOpts.effects;
				if(renderOpts.bitmap != null) {
				isNew = !bitmapsByID[id];
				bitmapsByID[id] = renderOpts.bitmap;//renderOpts.sub_bitmap ? renderOpts.sub_bitmap : renderOpts.bitmap;

				return (isNew || unrenderedChildren[dispObj]);
			}
				else if(effects && 'mosaic' in effects) {
				s = renderOpts.isStage ? 1 : appScale;
				srcWidth = dw * s;
					srcHeight =  dh * s;
				mosaic = Math.round((Math.abs(effects["mosaic"]) + 10) / 10);
				mosaic = Math.max(1, Math.min(mosaic, Math.min(srcWidth, srcHeight)));
				scale = 1 / mosaic;
			}
		}
			else if(dispObj is Bitmap) { // Remove else to allow graphics effects on video layer
			isNew = !bitmapsByID[id];
			bitmapsByID[id] = (dispObj as Bitmap).bitmapData;
				if(unrenderedChildren[dispObj] && textureIndexByID.hasOwnProperty(id)) {
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
			if(bmd) {
			// If the bitmap changed or the sprite is now large than the stored render then re-render it
			//trace(width +'x'+ height + ' vs '+bmd.width+'x'+bmd.height);
				if((id.indexOf('bm') != 0 || !unrenderedChildren[dispObj]) && bmd.width >= width && bmd.height >= height) {
				//trace('USING existing bitmap');

				scratchStage.visible = false;
				return false;
			}
				else if(bmd is ChildRender) {
					if((bmd as ChildRender).needsResize(width, height)) {
					bmd.dispose();
					bmd = null;
				}
					else if((bmd as ChildRender).needsRender(dispObj, width, height, stagePenLayer)) {
					(bmd as ChildRender).reset(dispObj, stagePenLayer);
						if('clearCachedBitmap' in dispObj)
						(dispObj as Object).clearCachedBitmap();

						trace('Re-rendering part of large sprite! '+Dbg.printObj(dispObj));
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
			if(flipped) {
			(dispObj as Object).setRotationStyle("don't rotate");
			bounds = (dispObj as Object).getVisibleBounds(dispObj);
		}

		var width2:Number = Math.max(1, width);
		var height2:Number = Math.max(1, height);
		var updateTexture:Boolean = !!bmd;
			if(!bmd) bmd = new ChildRender(width2, height2, dispObj, stagePenLayer, bounds);
		else bmd.fillRect(bmd.rect, 0x00000000);

		var sX:Number = scale, sY:Number = scale;
		if(bmd is ChildRender) {
			sX *= (bmd as ChildRender).scaleX;
			sY *= (bmd as ChildRender).scaleY;
		}

		var drawMatrix:Matrix = new Matrix(1, 0, 0, 1, -bounds.x, -bounds.y);
			if(bmd is ChildRender && (bmd as ChildRender).isPartial())
			drawMatrix.translate(-(bmd as ChildRender).inner_x * bounds.width, -(bmd as ChildRender).inner_y * bounds.height);
		drawMatrix.scale(dispObj.scaleX * sX * Math.min(maxScale, appScale * scratchStage.stage.contentsScaleFactor), dispObj.scaleY * sY * Math.min(maxScale, appScale * scratchStage.stage.contentsScaleFactor));
		var oldAlpha:Number = dispObj.alpha;
		dispObj.alpha = 1;

		var oldImgTrans:ColorTransform = null;
			if('img' in dispObj) {
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
			if('img' in dispObj)
			(dispObj as Object).img.transform.colorTransform = oldImgTrans;

			if(flipped)
			(dispObj as Object).setRotationStyle('left-right');

		scratchStage.visible = false;
//trace(dispObj.parent.getChildIndex(dispObj)+' '+Dbg.printObj(dispObj)+' Rendered '+Dbg.printObj(bmd)+' with id: '+id+' @ '+bmd.width+'x'+bmd.height);
//trace('Original render size was '+bounds2);
			if(updateTexture && textureIndexByID.hasOwnProperty(id))
			textures[textureIndexByID[id]].updateBitmap(id, bmd);
		bitmapsByID[id] = bmd;

		//movedChildren[dispObj] = true;
		unrenderedChildren[dispObj] = false;
		return !updateTexture;
	}

	public function spriteIsLarge(dispObj:DisplayObject):Boolean {
		var id:String = spriteBitmaps[dispObj];
			if(!id) return false;
		var cr:ChildRender = bitmapsByID[id];
		return (cr && cr.isPartial());
	}

	public var debugTexture:Boolean = false;

	private function toggleTextureDebug(evt:KeyboardEvent):void {
			if(evt.ctrlKey && evt.charCode == 108) {
			debugTexture = !debugTexture;
		}
	}

	private var maxTextures:uint = 5;
	private function packTextureBitmaps():void {
		var penID:String = spriteBitmaps[stagePenLayer];
			if(textures.length < 1)
			textures.push(new ScratchTextureBitmap(512, 512));

			if(!penPacked && penID != null) {
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
			while(true) {
			var unpackedBMs:Object = {};
			var bmsToPack:int = 0;

			for (var k:Object in bitmapsByID)
					if(k != penID) {// && (!textureIndexByID.hasOwnProperty(k) || textureIndexByID[k] < 0)) {
					unpackedBMs[k] = bitmapsByID[k];
					++bmsToPack;
				}

			//trace('pack textures! ('+bmsToPack+')');
			for(var i:int=1; i<maxTextures && bmsToPack > 0; ++i) {
					if(i >= textures.length)
					textures.push(new ScratchTextureBitmap(size, size));

				var newTex:ScratchTextureBitmap = textures[i];
				var packedIDs:Array = newTex.packBitmaps(unpackedBMs);
					for(var j:int=0; j<packedIDs.length; ++j) {
					//trace('packed bitmap '+packedIDs[j]+': '+bitmapsByID[packedIDs[j]].rect);
					textureIndexByID[packedIDs[j]] = i;
					delete unpackedBMs[packedIDs[j]];
				}
				bmsToPack -= packedIDs.length;
			}

				if(bmsToPack > 0) {
					if(!cleanedUnused) {
						cleanUpUnusedBitmaps();
					cleanedUnused = true;
				}
				else if(!usedMaxTex) {
					for(i=1; i<textures.length; ++i) {
						textures[i].disposeTexture();
						textures[i].dispose();
						textures[i] = null;
					}
					textures.length = 1;

					size <<= 1;
					if(size >= texSizeMax) {
						usedMaxTex = true;
						size = texSizeMax;
					}
					trace('switching to larger textures ('+size+')');
				}
				else {
					// Bail on 3D
					statusCallback(false);
					throw Error('Unable to fit all bitmaps into the textures!');
				}
			}
			else {
				if(debugTexture) {
//					uiContainer.graphics.clear();
//					uiContainer.graphics.lineStyle(1);
					var offset:Number = 0;
					for(i=0; i<textures.length; ++i) {
						newTex = textures[i];
						if(i >= testBMs.length)
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
							if(i == textureIndexByID[k]) {
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
	}

	private var drawCount:uint = 0;
	//private var lastTime:int = 0;
	private function onRender(e:Event):void {
			if(!scratchStage) return;
		//trace('frame was '+(getTimer() - lastTime)+'ms.');
		//lastTime = getTimer();

			if(scratchStage.stage.stage3Ds[0] == null || __context == null ||
				__context.driverInfo == "Disposed") {
				if(__context) __context.dispose();
			__context = null;
			onContextLoss();
			return;
		}

		//trace('Drawing!');
			if(!indexBuffer) checkBuffers();
		draw();
		render(childrenDrawn);
		__context.present();
		++drawCount;

		// Invalidate cached renders
			for(var o:Object in cachedOtherRenderBitmaps)
			cachedOtherRenderBitmaps[o].inner_x = Number.NaN;
	}

	public function getRender(bmd:BitmapData):void {
		if (scratchStage.stage.stage3Ds[0] == null || __context == null ||
				__context.driverInfo == "Disposed") {
			return;
		}

			if(!indexBuffer) checkBuffers();
		draw();
		__context.configureBackBuffer(bmd.width, bmd.height, 0, false);
		render(childrenDrawn);
		__context.drawToBitmapData(bmd);
		//__context.present();
		//bmd.draw(uiContainer);
		scissorRect = null;
		setRenderView();
	}

	private var emptyStamp:BitmapData = new BitmapData(1, 1, true, 0);

	public function getRenderedChild(dispObj:DisplayObject, width:Number, height:Number, for_carry:Boolean = false):BitmapData {
			if(dispObj.parent != scratchStage || !__context)
			return emptyStamp;

			if(!spriteBitmaps[dispObj] || unrenderedChildren[dispObj] || !bitmapsByID[spriteBitmaps[dispObj]]) {
				if(checkChildRender(dispObj)) {
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
			if(iw<1 || ih<1) return emptyStamp;

			if(stampsByID[id] && !for_carry) {
			var changed:Boolean = (stampsByID[id].width != iw || stampsByID[id].height != ih);
				if(!changed) {
				var old_fx:Object = stampsByID[id].effects;
				var prop:String;
					if(old_fx) {
						for(prop in old_fx) {
							if(prop == 'ghost') continue;
							if(old_fx[prop] == 0 && !effects) continue;
							if(!effects || old_fx[prop] != effects[prop]) {
							changed = true;
							break;
						}
					}
				}
				else {
						for(prop in effects) {
							if(prop == 'ghost') continue;
							if(effects[prop] != 0) {
							changed = true;
							break;
						}
					}
				}
			}

				if(!changed)
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
		if(changeBackBuffer) {
			projMatrix = createOrthographicProjectionMatrix(bmd.width, bmd.height, 0, 0);
			__context.configureBackBuffer(bmd.width, bmd.height, 0, false);
			pScale = 1;
		}

		dispObj.scaleX = width / Math.floor(bounds.width * dispObj.scaleX * pScale);
		dispObj.scaleY = height / Math.floor(bounds.height * dispObj.scaleY * pScale);

		var oldX:Number = dispObj.x;
		var oldY:Number = dispObj.y;
		dispObj.x = -bounds.x * dispObj.scaleX;
		dispObj.y = -bounds.y * dispObj.scaleY;
		vertexData.position = 0;
		drawChild(dispObj);
		dispObj.x = oldX;
		dispObj.y = oldY;
		dispObj.scaleX = oldScaleX;
		dispObj.scaleY = oldScaleY;
		dispObj.rotation = rot;

			if(vertexData.position == 0)
			return bmd;

		// TODO: Find out why the index buffer isn't uploaded sometimes
		indexBufferUploaded = false;
		uploadBuffers(1);

			__context.setScissorRectangle(new Rectangle(0, 0, bmd.width+1, bmd.height+1));
		render(1, false);
		__context.drawToBitmapData(bmd);

			if(changeBackBuffer) {
			scissorRect = null;
			// Reset scissorRect and framebuffer size
			setupContext3D();
		}
		else {
			__context.setScissorRectangle(scissorRect);
		}

			if(!for_carry) stampsByID[id] = bmd;
		return bmd;
	}

//	private var testTouchBM:Bitmap;
	private var cachedOtherRenderBitmaps:Dictionary;

	public function getOtherRenderedChildren(skipObj:DisplayObject, scale:Number):BitmapData {
			if(skipObj.parent != scratchStage)
			return null;

		var bounds:Rectangle = boundsDict[skipObj];
			var width:uint = Math.ceil(bounds.width  * skipObj.scaleX * scale);
			var height:uint = Math.ceil(bounds.height  * skipObj.scaleY * scale);
		var cr:ChildRender = cachedOtherRenderBitmaps[skipObj];
			if(cr && cr.width == width && cr.height == height) {
			// TODO: Can we efficiently cache this?  we'd have to check every other position / effect / etc
				if(cr.inner_x == skipObj.x && cr.inner_y == skipObj.y && cr.inner_w == skipObj.rotation)
				return cr;
			else
				cr.fillRect(cr.rect, 0x00000000);  // Is this necessary?
		}
		else {
				if(cr) cr.dispose();
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
		draw();
		pixelateAll = false;
		skipObj.visible = vis;
		__context.setScissorRectangle(cr.rect);
		render(childrenDrawn);
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

	private const FC0:Vector.<Number> = Vector.<Number>([1, 2, 0, 0.5]);
	private const FC1:Vector.<Number> = Vector.<Number>([3.1415926535, 180, 60, 120]);
	private const FC2:Vector.<Number> = Vector.<Number>([240, 3, 4, 5]);
	private const FC3:Vector.<Number> = Vector.<Number>([6, 0.11, 0.09, 0.001]);
	private const FC4:Vector.<Number> = Vector.<Number>([360, 0, 0, 0]);

	public function render(quadCount:uint, blend:Boolean = true):void {
		// assign shader program
		__context.setProgram(program);
		__context.clear(0, 0, 0, 0);

		// assign texture to texture sampler 0
		//__context.setScissorRectangle(getChildAt(0).getRect(stage));
		for(var i:int=0; i<maxTextures; ++i) {
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

			if(blend)
			__context.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
		else
			__context.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ZERO);

		// draw all sprites
		//trace('Drawing '+quadCount+' children');
			__context.drawTriangles(indexBuffer, 0, quadCount*2);
		//trace('finished drawing() - '+drawCount);

		//childrenChanged = false;
		//movedChildren = new Dictionary();
	}

	private function setupContext3D(e:Event = null):void {
			if(!__context) {
			requestContext3D();
			return;
		}

		setRenderView();
		//__context.addEventListener(Event.ACTIVATE, setupContext3D);
		//__context.addEventListener(Event.DEACTIVATE, onContextLoss);

		__context.setDepthTest(false, Context3DCompareMode.ALWAYS);
		__context.enableErrorChecking = true;

		buildShaders();

		indexBuffer = __context.createIndexBuffer(indexData.length >> 1);
		//trace('indexBuffer created');
		indexBufferUploaded = false;
			vertexBuffer = __context.createVertexBuffer((indexData.length/12)*4, vStride);
		vertexBufferUploaded = false;
		tlPoint = scratchStage.localToGlobal(originPt);
	}

	private function loadShaders():void {
		[Embed(source='shaders/vertex.agal', mimeType='application/octet-stream')] const VertexShader:Class;
		[Embed(source='shaders/fragment.agal', mimeType='application/octet-stream')] const FragmentShader:Class;

		function getUTF(embed:ByteArray):String {
			return embed.readUTFBytes(embed.length);
		}

		vertexShaderAssembler.assemble(Context3DProgramType.VERTEX, getUTF(new VertexShader()));
		fragmentShaderCode = getUTF(new FragmentShader());
	}

	private function buildShaders():void {

		// TODO: Bind the minimal number of textures and track the count. The shader must use every bound sampler.
		const maxTextureNum:int = 5; // index of the last texture in use

		var shaderID:int = maxTextureNum;
		forEachEffect(function(effectName:String): void {
			shaderID = (shaderID << 1) | (effectRefs[effectName] > 0 ? 1 : 0);
		});

		program = shaderCache[shaderID];
		if (!program) {
			var shaderParts:Array = ['#define MAXTEXTURE ' + maxTextureNum];

			forEachEffect(function(effectName:String): void {
				shaderParts.push(['#define EFFECT_', effectName, ' ', (effectRefs[effectName] > 0 ? '1' : '0')].join(''));
			});

			shaderParts.push(fragmentShaderCode);

			var completeFragmentShaderCode:String = shaderParts.join('\n');

			fragmentShaderAssembler.assemble(Context3DProgramType.FRAGMENT, completeFragmentShaderCode);
			program = shaderCache[shaderID] = __context.createProgram();
			program.upload(vertexShaderAssembler.agalcode, fragmentShaderAssembler.agalcode);
		}
/*
		fragmentShaderAssembler.assemble( Context3DProgramType.FRAGMENT,
				// Move the texture coordinates into the sub-texture space
						"mul ft0.xyzw, v0.xyxy, v1.xyxy\n" +
						"add ft0.xy, ft0.xy, v0.zw\n" +

						"frc ft3.xyzw, v3.wwww\n"+
						"sub ft3.x, v3.w, ft3.x\n"+

						"seq ft5, ft3.x, fc0.z\n"+	// Use texture 0?
						"tex ft2, ft0, fs0 <2d,clamp,linear,nomip>\n"+
						"mul ft2, ft2, ft5\n"+
						"mov ft1, ft2\n"+

						"seq ft5, ft3.x, fc0.x\n"+	// Use texture 1?
						"tex ft2, ft0, fs1 <2d,clamp,linear,nomip>\n"+
						"mul ft2, ft2, ft5\n"+
						"add ft1, ft1, ft2\n"+

						"seq ft5, ft3.x, fc0.y\n"+	// Use texture 2?
						"tex ft2, ft0, fs2 <2d,clamp,linear,nomip>\n"+
						"mul ft2, ft2, ft5\n"+
						"add ft1, ft1, ft2\n"+

						"seq ft5, ft3.x, fc2.y\n"+	// Use texture 3?
						"tex ft2, ft0, fs3 <2d,clamp,linear,nomip>\n"+
						"mul ft2, ft2, ft5\n"+
						"add ft1, ft1, ft2\n"+

						"seq ft5, ft3.x, fc2.z\n"+	// Use texture 4?
						"tex ft2, ft0, fs4 <2d,clamp,linear,nomip>\n"+
						"mul ft2, ft2, ft5\n"+
						"add ft1, ft1, ft2\n" +

						// De-multiply the alpha
						"seq ft3.y, ft1.w, fc0.z\n"+ //int alpha_eq_zero = (alpha == 0);	alpha_eq_zero	= ft3.y
						"sne ft3.z, ft1.w, fc0.z\n"+ //int alpha_neq_zero = (alpha != 0);	alpha_neq_zero	= ft3.z
						"mul ft3.x, fc3.w, ft3.y\n"+ //tiny = 0.000001 * alpha_eq_zero;		tiny		= ft3.x
						"add ft1.w, ft1.w, ft3.x\n"+ //alpha = alpha + tiny;				Avoid division by zero, alpha != 0
						"div ft2.xyz, ft1.xyz, ft1.www\n"+ //new_rgb = rgb / alpha
						"mul ft2.xyz, ft2.xyz, ft3.zzz\n"+ //new_rgb = new_rgb * alpha_neq_zero

						"mul ft1.xyz, ft1.xyz, ft3.yyy\n"+ //rgb = rgb * alpha_eq_zero
						"add ft1.xyz, ft1.xyz, ft2.xyz\n"+ //rgb = rgb + new_rgb

					// Clamp the color
						"sat oc, ft1\n"

				//"tex oc, ft0, fs0 <2d,clamp,linear,nomip>\n"
		);
*/
	}

	private function context3DCreated(e:Event):void {
			if(!contextRequested) {
			onContextLoss(e);
		}

		contextRequested = false;
			if(!scratchStage) {
			__context = null;
			(e.currentTarget as Stage3D).context3D.dispose();
			return;
		}
		else
			scratchStage.visible = false;

		__context = (e.currentTarget as Stage3D).context3D;
			if(__context.driverInfo.toLowerCase().indexOf('software') > -1) {
				if(!callbackCalled) {
				callbackCalled = true;
				statusCallback(false);
			}
			setStage(null, null);

			return;
		}

		setupContext3D();
			if(scratchStage.visible)
			scratchStage.visible = false;

			if(!callbackCalled) {
			callbackCalled = true;
			statusCallback(true);
		}
	}

	private var callbackCalled:Boolean;


	private function requestContext3D():void {
			if(contextRequested || !stage3D) return;

		stage3D.addEventListener(Event.CONTEXT3D_CREATE, context3DCreated, false, 0, true);
		stage3D.addEventListener(ErrorEvent.ERROR, onStage3DError, false, 0, true);
		stage3D.requestContext3D(Context3DRenderMode.AUTO);
		contextRequested = true;
	}

	private function onStage3DError(e:Event):void {
		scratchStage.visible = true;
			if(!callbackCalled) {
			callbackCalled = true;
			statusCallback(false);
		}
		setStage(null, null);
	}

	private function onContextLoss(e:Event = null):void {
		for (var config:Object in shaderCache) {
			shaderCache[config].dispose();
		}
		shaderCache = {};

			for(var i:int=0; i<textures.length; ++i)
			(textures[i] as ScratchTextureBitmap).disposeTexture();

			if(vertexBuffer) {
			vertexBuffer.dispose();
			vertexBuffer = null;
		}

			if(indexBuffer) {
			//trace('disposing of indexBuffer!');
			indexBuffer.dispose();
			//trace('indexBuffer disposed');
			indexBuffer = null;
		}

			for(var id:String in bitmapsByID)
				if(bitmapsByID[id] is ChildRender)
				bitmapsByID[id].dispose();
		bitmapsByID = {};

			for(id in stampsByID)
			stampsByID[id].dispose();
		stampsByID = {};

		indexBufferUploaded = false;
		vertexBufferUploaded = false;
		scissorRect = null;

			if(!e) requestContext3D();
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
			sRawData[0] = 2.0/width;
		sRawData[1] = 0;
		sRawData[4] = 0;
			sRawData[5] = -2.0/height;
			sRawData[12] = -(2*x + width) / width;
			sRawData[13] = (2*y + height) / height;
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
