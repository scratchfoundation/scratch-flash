/**
 * Created by Mallory on 9/18/15.
 */
package svgeditor.tools {

import assets.Resources;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.BitmapData;
import flash.display.BitmapData;
import flash.display.BitmapDataChannel;
import flash.display.Graphics;
import flash.events.Event;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.filters.BitmapFilterType;
import flash.filters.ColorMatrixFilter;
import flash.filters.GlowFilter;
import flash.filters.GradientGlowFilter;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.ui.Mouse;
import flash.ui.MouseCursorData;
import flash.ui.MouseCursorData;
import flash.utils.ByteArray;
import flash.utils.Dictionary;
import flash.utils.Timer;
import flash.utils.setTimeout;

import grabcut.vfs.ISpecialFile
import grabcut.CModule;

import scratch.ScratchCostume;

import svgeditor.ImageCanvas;

import svgeditor.ImageEdit;
import svgeditor.objs.FlasccConsole;
import svgeditor.objs.SegmentationState;

import uiwidgets.EditableLabel;

import util.Base64Encoder;


import flash.display.Sprite;
import flash.text.TextField;
import flash.events.Event;




public class BitmapBackgroundTool extends BitmapPencilTool{


	static public const UPDATE_REQUIRED:String='got_mask';
	static private const SCALE_FACTOR:Number = .5;
	static private var startedAsync:Boolean = false;
	static private const BUSY_CURSOR:String = "segmentationBusy";
	static private const BG_ISLAND_THRESHOLD:Number = 0.1;
	static private const OBJECT_ISLAND_THRESHOLD:Number = 0.1;

	private var segmentationRequired:Boolean = false;
    private var workingScribble:BitmapData;

    private var previewFrameTimer:Timer = new Timer(100);
    private var previewFrameBackgrounds:Vector.<BitmapData> = new Vector.<BitmapData>();
    private var previewFrameIdx:int = 0;
    private var previewFrames:Vector.<BitmapData>;

	private var cursor:MouseCursorData = new MouseCursorData();

    private function get workingBitmap():BitmapData
    {
        return editor.getWorkArea().getBitmap().bitmapData;
    }

	private function get segmentationState():SegmentationState
	{
		return editor.targetCostume.segmentationState;
	}

	public function BitmapBackgroundTool(editor:ImageEdit){
		if(!startedAsync){
			//Use a custom console object for getting stdout from the segmentation algorithm
//          var console:FlasccConsole = new FlasccConsole();
//			CModule.vfs.console = console;
//            console.SampleApplication();
			CModule.startAsync();
//            editor.addChild(console);
			startedAsync=true;
		}
        previewFrameBackgrounds.push(
            Resources.createBmp("first").bitmapData,
            Resources.createBmp("second").bitmapData,
            Resources.createBmp("third").bitmapData,
            Resources.createBmp("fourth").bitmapData,
            Resources.createBmp("fifth").bitmapData,
            Resources.createBmp("sixth").bitmapData,
            Resources.createBmp("seventh").bitmapData,
            Resources.createBmp("eighth").bitmapData
        )
        previewFrameTimer.addEventListener("timer", nextPreviewFrame);
		var frames:Vector.<BitmapData> = new Vector.<BitmapData>();
		frames.push(Resources.createBmp(BitmapBackgroundTool.BUSY_CURSOR).bitmapData);
		cursor.hotSpot = new Point(10,10);
		cursor.data = frames;
		Mouse.registerCursor(BitmapBackgroundTool.BUSY_CURSOR, cursor);
		super(editor, false)
	}

    private function nextPreviewFrame(event:TimerEvent):void{
        previewFrameIdx = (previewFrameIdx + 1) % previewFrameBackgrounds.length;
        workingScribble.copyPixels(previewFrames[previewFrameIdx], previewFrames[previewFrameIdx].rect, new Point(0, 0));
    }

	public function loadState():void{
		previewFrameTimer.stop();
        workingScribble = editor.getWorkArea().getSegmentation().bitmapData;
        workingScribble.fillRect(workingScribble.rect, 0);
        editor.getWorkArea().getBitmap().visible = true;
        editor.getWorkArea().getSegmentation().visible = true;
        if(segmentationState.xMin < 0){
            segmentationState.xMin = editor.getWorkArea().width;
        }
        if(segmentationState.yMin < 0){
            segmentationState.yMin = editor.getWorkArea().height;
        }
		if(segmentationState.isGreyscale){
		    setGreyscale();
		}
		else if(segmentationState.scribbleBitmap){
			workingScribble.draw(segmentationState.scribbleBitmap);
		}
		else{
		    segmentationState.scribbleBitmap = new BitmapData(workingBitmap.width, workingBitmap.height, true, 0x00000000);
		}
	}

    protected override function shutdown():void{
        workingScribble.fillRect(workingScribble.rect, 0);
        editor.getWorkArea().visible = true;
        previewFrameTimer.stop();
		if(segmentationState.lastMask){
			applyMask(segmentationState.lastMask, workingBitmap);
			editor.saveContent();
		}
        super.shutdown();
    }

	override protected function mouseUp(evt:MouseEvent):void{
		if(lastPoint && segmentationRequired){
			if(Mouse.supportsNativeCursor){

				Mouse.cursor = BitmapBackgroundTool.BUSY_CURSOR;
				Mouse.show();
			}
			setTimeout(getObjectMask,0);
			segmentationRequired = false;
		}
		resetBrushes();
	}

    override protected function mouseDown(evt:MouseEvent):void{
        if (editor.getWorkArea().clickInBitmap(evt.stageX, evt.stageY)){
            previewFrameTimer.stop();
        }
        super.mouseDown(evt);
    }

	override protected function set lastPoint(p:Point):void{
		if(p != null){
			if(super.lastPoint == null){
				segmentationState.isBlank = false;
				dispatchEvent(new Event(BitmapBackgroundTool.UPDATE_REQUIRED));
			}
			if(p.x > segmentationState.xMax){
				segmentationState.xMax = p.x
			}
			if(p.y > segmentationState.yMax){
				segmentationState.yMax = p.y
			}
			if(p.x < segmentationState.xMin){
				segmentationState.xMin = p.x
			}
			if(p.y < segmentationState.yMin){
				segmentationState.yMin = p.y
			}
			if(!(segmentationState.mode == "object") || segmentationState.lastMask){
				segmentationRequired = true;
			}
		}
		super.lastPoint = p;
	}

	override protected function drawAtPoint(p:Point, targetCanvas:BitmapData=null, altBrush:BitmapData=null):void{
		targetCanvas = targetCanvas || workingScribble;
        super.drawAtPoint(p, segmentationState.scribbleBitmap, altBrush);
		super.drawAtPoint(p, targetCanvas, altBrush);
	}

	private function applyPreviewMask(maskBitmap:BitmapData, dest:BitmapData):void{
		dest.fillRect(dest.rect, 0x0);
		var fgBitmap:BitmapData = dest.clone();
		var upperLeft:Point = new Point(0, 0);
		var greyscaleMatrix:Array = [.33, .33, .33, 0, 0,
							   		 .33, .33, .33, 0, 0,
									 .33, .33, .33, 0, 0,
									 0, 0, 0, .75, 0
									];
		dest.applyFilter(segmentationState.unmarkedBitmap, segmentationState.unmarkedBitmap.rect, upperLeft, new ColorMatrixFilter(greyscaleMatrix));
		fgBitmap.copyPixels(segmentationState.unmarkedBitmap, segmentationState.unmarkedBitmap.rect, upperLeft, maskBitmap, upperLeft, true);
		dest.draw(fgBitmap);
        previewFrames = new Vector.<BitmapData>();
        previewFrameIdx = 0;
        fgBitmap.applyFilter(fgBitmap, fgBitmap.rect, new Point(0,0), new GlowFilter(0xffff4d, 1.0, 4.0, 4.0, 255, 1, false, true));
        for each(var bg:BitmapData in previewFrameBackgrounds){
            var frame:BitmapData = dest.clone();
            fgBitmap.copyPixels(bg, bg.rect, new Point(0, 0), fgBitmap);
            frame.draw(fgBitmap);
            previewFrames.push(frame);
        }
        dest.copyPixels(previewFrames[previewFrameIdx], previewFrames[previewFrameIdx].rect, upperLeft);
	}

    private function applyMask(maskBitmap:BitmapData, dest:BitmapData):void{
		dest.copyPixels(segmentationState.unmarkedBitmap, segmentationState.unmarkedBitmap.rect, new Point(0,0));
		if(!maskBitmap){
			dest.copyChannel(segmentationState.unmarkedBitmap, segmentationState.unmarkedBitmap.rect, new Point(0,0), BitmapDataChannel.ALPHA, BitmapDataChannel.ALPHA);
		}
		else{
			dest.threshold(maskBitmap, maskBitmap.rect, new Point(0,0), "==", 0x0, 0x0, 0xFF000000, false);
		}
	}

	private function cropAndScale(targetBitmap:BitmapData):BitmapData{
		var cropRect:Rectangle = new Rectangle(cropX(), cropY(), cropWidth(), cropHeight());
		var croppedData:ByteArray = targetBitmap.getPixels(cropRect);
		croppedData.position = 0;
		var croppedBitmap:BitmapData = new BitmapData(cropWidth(), cropHeight(), true, 0x00ffffff);
		croppedBitmap.setPixels(croppedBitmap.rect, croppedData);
		var scaledBitmap:BitmapData = new BitmapData(croppedBitmap.width * .5, croppedBitmap.height * .5, true, 0x00ffffff);
		var m:Matrix = new Matrix();
		m.scale(SCALE_FACTOR, SCALE_FACTOR);
		scaledBitmap.draw(croppedBitmap, m);
		return scaledBitmap;
	}

	private function cropWidth():int{
		return cropX() + (segmentationState.xMax - segmentationState.xMin) + 10 < workingBitmap.width ?
			(segmentationState.xMax - segmentationState.xMin) + 10 : workingBitmap.width - segmentationState.xMin;
	}

	private function cropHeight():int{
		return cropY() + (segmentationState.yMax - segmentationState.yMin) + 10 < workingBitmap.height ?
		(segmentationState.yMax - segmentationState.yMin) + 10 : workingBitmap.height - segmentationState.yMin;
	}

	private function cropX():int{
		return Math.max(segmentationState.xMin - 10, 0);
	}

	private function cropY():int{
		return Math.max(segmentationState.yMin - 10, 0);
	}

	private function argbToRgba(argbBytes:ByteArray):void{
		for(var i:int =0 ; i < argbBytes.length/4; i++){
			//RGBA to ARGB
			var pxID:int = i * 4;
			var alpha:int = argbBytes[pxID];
			var red:int = argbBytes[pxID + 1];
			var green:int = argbBytes[pxID + 2];
			var blue:int = argbBytes[pxID + 3];
			argbBytes[pxID] = red;
			argbBytes[pxID + 1] = green;
			argbBytes[pxID + 2] = blue;
			argbBytes[pxID + 3] = alpha;
		}
	}

	private function rgbaToArgb(rgbaBytes:ByteArray):void{
		for(var i:int =0 ; i < rgbaBytes.length/4; i++){
			//RGBA to ARGB
			var pxID:int = i * 4;
			var red:int = rgbaBytes[pxID];
			var green:int = rgbaBytes[pxID + 1];
			var blue:int = rgbaBytes[pxID + 2];
			var alpha:int = rgbaBytes[pxID + 3];
			rgbaBytes[pxID] = alpha;
			rgbaBytes[pxID + 1] = red;
			rgbaBytes[pxID + 2] = green;
			rgbaBytes[pxID + 3] = blue;
		}
	}

	private function getObjectMask():void {
		//Get a scaled down working bitmap and extract bytes
		var scaledWorkingBM:BitmapData = cropAndScale(segmentationState.unmarkedBitmap);
		var workingData:ByteArray= scaledWorkingBM.getPixels(scaledWorkingBM.rect);
		workingData.position = 0;
		//Scale the user's annotations in the same way, get the bytes
		var scaledScribbleBM:BitmapData = cropAndScale(segmentationState.scribbleBitmap);
		var scribbleData:ByteArray = scaledScribbleBM.getPixels(scaledScribbleBM.rect);
		scribbleData.position = 0;
		//Make pointers to arrays that the c++ code can use
		var imgPtr:int = CModule.malloc(workingData.length);
		var scribblePtr:int = CModule.malloc(workingData.length);
		//Convert from crazy flash ARGB to RGBA
		argbToRgba(workingData);
		argbToRgba(scribbleData);
		//Fill the arrays with data
		CModule.writeBytes(imgPtr, workingData.length, workingData);
		CModule.writeBytes(scribblePtr, scribbleData.length, scribbleData);
		//construct array of args for the c++ function
		var args:Vector.<int> = new Vector.<int>();
	    args.push(imgPtr, scribblePtr, scaledWorkingBM.height, scaledWorkingBM.width, 1)
		//get a function pointer to grabCut, call with args
		var func:int = CModule.getPublicSymbol("grabCut")
		var result:int = CModule.callI(func, args);
		//Start post processing, free our malloc'd memory
		function didGetObjectMask():void {
			var bmData:ByteArray= new ByteArray();
			//Extract mask bytes from the modified image buffer, convert to flash ARGB bytes
			CModule.readBytes(imgPtr, workingData.length, bmData);
			bmData.position=0;
			rgbaToArgb(bmData);
			//Remember, this needs to be scaled back up
			var scaledMaskBitmap:BitmapData = new BitmapData(scaledWorkingBM.width, scaledWorkingBM.height, true, 0x00ffffff);
			scaledMaskBitmap.setPixels(scaledMaskBitmap.rect, bmData);
			//Try to get rid of any holes/islands
        	var smoothedMask:BitmapData = removeIslands(scaledMaskBitmap, 2);
			var m:Matrix = new Matrix();
			m.scale(1./SCALE_FACTOR,1./SCALE_FACTOR);
			m.tx = cropX();
			m.ty = cropY();
			var maskBitmap:BitmapData = new BitmapData(workingBitmap.width, workingBitmap.height, true, 0x00ffffff);
			//Scale to original size
			maskBitmap.draw(smoothedMask, m);
			bmData.position = 0;
			segmentationState.lastMask = maskBitmap
			//Show our hard earned results
			setGreyscale();
			dispatchEvent(new Event(BitmapBackgroundTool.UPDATE_REQUIRED));
			function resetCursor():void{
				if(Mouse.supportsNativeCursor){
					Mouse.cursor = "arrow";
				}
			}
			setTimeout(resetCursor, 0);
			applyMask(segmentationState.lastMask, workingBitmap);
			editor.saveContent();
	}
		didGetObjectMask();
		CModule.free(imgPtr);
		CModule.free(scribblePtr);
	}



    private function removeIslands(maskBitmap:BitmapData, iterations:int):BitmapData{
		//Look for small pieces of object or background, tag them, reassign them as necessary, and create
		//a new mask based on this.  Iterate n times to remove nested pieces.
		iterations--;
		if(iterations < 0){
			return maskBitmap;
		}
        var resultBitmap:BitmapData = new BitmapData(maskBitmap.width, maskBitmap.height, true, 0x00ffffff);
        var objectSegments:Array = new Array();
        var bgSegments:Array = new Array();
        var bgIDs:Array = [];
        var segmentId:uint = 1;
        for(var j:int = 0; j<maskBitmap.height; j++ ){
            for(var i:int = 0; i<maskBitmap.width; i++ ){
                if(resultBitmap.getPixel(i,j) != 0){
                    continue
                }
                var segment:uint = maskBitmap.getPixel(i,j);
				(segment == 0 ? bgSegments : objectSegments)[segmentId] = tagComponent(maskBitmap, resultBitmap, segmentId, segment, i, j);
                segmentId *= 2;
				if(segmentId >= 0x00FFFFFF){
					break;
				}
            }
			if(segmentId >= 0x00FFFFFF){
				break;
			}
        }
		//Now that we know component sizes, switch small ones to the opposite segment
		//Note that if pieces are nested, you will end up with an erroneous swap, requiring another iteration
        var bgMax:uint = 0;
        for each(var bgElem:* in bgSegments){
            bgMax = Math.max(bgMax, bgElem as uint);
        }
        for(var bgIdx:* in bgSegments){
           if(bgSegments[bgIdx as uint] > bgMax * BG_ISLAND_THRESHOLD){
               bgIDs.push(bgIdx as uint);
           }
        }
        var objMax:uint = 0;
        for each(var objElem:* in objectSegments){
            objMax = Math.max(objMax, objElem as uint);
        }
        for(var objIdx:* in objectSegments){
            if(objectSegments[objIdx as uint] < objMax * OBJECT_ISLAND_THRESHOLD){
                bgIDs.push(objIdx as uint);
            }
        }
		var bgMask:uint = 0x0;
		for each(var bgID:uint in bgIDs){
			bgMask = bgMask | bgID;
		}
		maskBitmap.fillRect(maskBitmap.rect, 0x00FFFFFF);
		maskBitmap.threshold(resultBitmap, resultBitmap.rect, new Point(0,0), '==', 0x0, 0xFFFFFFFF, bgMask);
		return removeIslands(maskBitmap, iterations);

    }

	private function tagComponent(maskBitmap:BitmapData, resultBitmap:BitmapData, segmentID:uint, segment:uint, x:uint, y:uint):uint{
		//Tag the component starting at this point with the given ID, copy to result, return component size
		var tagColor:uint = 0xff000000 + segmentID;
		maskBitmap.floodFill(x, y, tagColor);
		return resultBitmap.threshold(maskBitmap, maskBitmap.rect, new Point(0,0), "==", tagColor, tagColor, 0xFFFFFFFF);
	}

	private function setGreyscale():void{
        editor.getWorkArea().getBitmap().visible = false;
        editor.getWorkArea().getSegmentation().visible = true;
		applyPreviewMask(segmentationState.lastMask, workingScribble);
        previewFrameTimer.start();
		segmentationState.isGreyscale = true;
	}

	public function restoreUnmarked():void{
        previewFrameTimer.stop();
        workingScribble.fillRect(workingScribble.rect, 0);
		workingBitmap.copyPixels(segmentationState.unmarkedBitmap, segmentationState.unmarkedBitmap.rect,new Point(0,0));
        editor.getWorkArea().getBitmap().visible = true;
		editor.saveContent();
	}

	public function commitMask():void{
		if(segmentationState.lastMask) {
            previewFrameTimer.stop();
            editor.getWorkArea().getBitmap().visible = true;
			applyMask(segmentationState.lastMask, workingBitmap);
			editor.saveContent();
		}
	}
}
}
