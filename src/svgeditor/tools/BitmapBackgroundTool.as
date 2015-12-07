/**
 * Created by Mallory on 9/18/15.
 */
package svgeditor.tools {

import assets.Resources;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.BitmapData;
import flash.display.Graphics;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.filters.BitmapFilterType;
import flash.filters.GlowFilter;
import flash.filters.GradientGlowFilter;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.ui.Mouse;
import flash.utils.ByteArray;
import flash.utils.Dictionary;
import flash.utils.Timer;

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


	static public const GOTMASK:String='got_mask';

	static private const SCALE_FACTOR:Number = .5;
	static private var startedAsync:Boolean = false;

    private var bgIDs:Array;

    private var borderPoints:Vector.<Point>;
	private var segmentationRequired:Boolean = false;
    private var workingScribble:BitmapData;


    private var timer:Timer = new Timer(100);
    private var previewFrameBackgrounds:Vector.<BitmapData> = new Vector.<BitmapData>();
    private var previewFrameIdx:int = 0;
    private var previewFrames:Vector.<BitmapData>;

	private function get isObjectMode():Boolean{
		return editor.targetCostume.segmentationState.mode == 'object';
	}

	private function get isGreyscale():Boolean{
		if(!editor) return false;
		return editor.targetCostume.segmentationState.isGreyscale;
	}

	private function set isGreyscale(val:Boolean):void{
		if(editor){
			editor.targetCostume.segmentationState.isGreyscale = val;
		}
	}

	private function get lastMask():ByteArray{
		return editor.targetCostume.segmentationState.lastMask;
	}

	private function set lastMask(val:ByteArray):void{
		editor.targetCostume.segmentationState.lastMask = val;
	}

	private function get scribbleBitmap():BitmapData{
		return editor.targetCostume.segmentationState.scribbleBitmap;
	}

	private function set scribbleBitmap(val:BitmapData):void{
		editor.targetCostume.segmentationState.scribbleBitmap = val;
	}

	private function get xMin():int{
		return editor.targetCostume.segmentationState.xMin;
	}

	private function set xMin(val:int):void{
		editor.targetCostume.segmentationState.xMin = val;
	}

	private function get xMax():int{
		return editor.targetCostume.segmentationState.xMax;
	}

	private function set xMax(val:int):void{
		editor.targetCostume.segmentationState.xMax = val;
	}

	private function get yMin():int{
		return editor.targetCostume.segmentationState.yMin;
	}

	private function set yMin(val:int):void{
		editor.targetCostume.segmentationState.yMin = val;
	}

	private function get yMax():int{
		return editor.targetCostume.segmentationState.yMax;
	}

	private function set yMax(val:int):void{
		editor.targetCostume.segmentationState.yMax = val;
	}

    private function get workingBitmap():BitmapData
    {
        return editor.getWorkArea().getBitmap().bitmapData;
    }

	public function BitmapBackgroundTool(editor:ImageEdit){
		if(!startedAsync){
//            var console:FlasccConsole = new FlasccConsole();
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
        timer.addEventListener("timer", nextPreviewFrame);
		super(editor, false)
	}

    private function nextPreviewFrame(event:TimerEvent):void{
        previewFrameIdx = (previewFrameIdx + 1) % previewFrameBackgrounds.length;
        workingScribble.copyPixels(previewFrames[previewFrameIdx], previewFrames[previewFrameIdx].rect, new Point(0, 0));
    }

	public function loadState():void{
        workingScribble = editor.getWorkArea().getSegmentation().bitmapData;
        workingScribble.fillRect(workingScribble.rect, 0);
        editor.getWorkArea().getBitmap().visible = true;
        editor.getWorkArea().getSegmentation().visible = true;
        if(xMin < 0){
            xMin = editor.getWorkArea().width;
        }
        if(yMin < 0){
            yMin - editor.getWorkArea().height;
        }
		if(isGreyscale){
		    setGreyscale();
		}
		else if(scribbleBitmap){
			workingScribble.draw(scribbleBitmap);
		}
		else{
		    scribbleBitmap = new BitmapData(workingBitmap.width, workingBitmap.height, true, 0x00000000);
		}
	}

    protected override function shutdown():void{
        workingScribble.fillRect(workingScribble.rect, 0);
        editor.getWorkArea().visible = true;
        timer.stop();
        super.shutdown();
    }

	override protected function mouseUp(evt:MouseEvent):void{
		if(lastPoint && segmentationRequired){
			getObjectMask();
			segmentationRequired = false;
		}
		resetBrushes();
	}

    override protected function mouseDown(evt:MouseEvent):void{
        if (editor.getWorkArea().clickInBitmap(evt.stageX, evt.stageY)){
            timer.stop();
        }
        super.mouseDown(evt);
    }

	override protected function set lastPoint(p:Point):void{
		if(p != null){
			if(p.x > xMax){
				xMax = p.x
			}
			if(p.y > yMax){
				yMax = p.y
			}
			if(p.x < xMin){
				xMin = p.x
			}
			if(p.y < yMin){
				yMin = p.y
			}
			if(!isObjectMode || lastMask){
				segmentationRequired = true;
			}
		}
		super.lastPoint = p;
	}

	override protected function drawAtPoint(p:Point, targetCanvas:BitmapData=null, altBrush:BitmapData=null):void{
		targetCanvas = targetCanvas || workingScribble;
        super.drawAtPoint(p, scribbleBitmap, altBrush);
		super.drawAtPoint(p, targetCanvas, altBrush);
	}

	private function applyPreviewMask(maskBytes:ByteArray, dest:BitmapData):void{
		var workingBytes:ByteArray = workingBitmap.clone().getPixels(workingBitmap.rect);
		for(var i:int =0; i < workingBytes.length/4; i++){
            var pxID:int = i * 4;
            var x:int = i % workingBitmap.width;
            var y:int = Math.floor(i / workingBitmap.width);
	    	if(maskBytes[pxID] == 0){
                var average:int = (workingBytes[pxID + 1] + workingBytes[pxID + 2] + workingBytes[pxID + 3]) / 3
                workingBytes[pxID] = Math.min(workingBytes[pxID], 150);
                workingBytes[pxID + 1] = average;
                workingBytes[pxID + 2] = average;
                workingBytes[pxID + 3] = average;
		    }
			else{
				trace("NON ZERO IN MASK!");
			}
        }

		workingBytes.position = 0;
		var glowObject:BitmapData = workingBitmap.clone();
        applyMask(maskBytes, glowObject);
        dest.setPixels(dest.rect, workingBytes);
        previewFrames = new Vector.<BitmapData>();
        previewFrameIdx = 0;
        glowObject.applyFilter(glowObject, glowObject.rect, new Point(0,0), new GlowFilter(0xffff4d, 1.0, 4.0, 4.0, 255, 1, false, true));
        for each(var bg:BitmapData in previewFrameBackgrounds){
            var frame:BitmapData = dest.clone();
            glowObject.copyPixels(bg, bg.rect, new Point(0, 0), glowObject);
            frame.draw(glowObject);
            previewFrames.push(frame);
        }
        dest.copyPixels(previewFrames[previewFrameIdx], previewFrames[previewFrameIdx].rect, new Point(0, 0));
	}

    private function applyMask(maskBytes:ByteArray, dest:BitmapData):void{
		var workingBytes:ByteArray = workingBitmap.clone().getPixels(workingBitmap.rect);
		for(var i:int = 0; i<workingBytes.length/4; i++){
			var pxID:int = i * 4;

			if(maskBytes[pxID] == 0){
		        workingBytes[pxID] = 0;
			}
		}
		workingBytes.position = 0;
        dest.setPixels(dest.rect, workingBytes)
	}

    private function reMask(segmentBitmap:BitmapData):BitmapData {
        var maskBytes:ByteArray = segmentBitmap.getPixels(segmentBitmap.rect);
        var newMask:BitmapData = new BitmapData(segmentBitmap.width, segmentBitmap.height, true, 0x00ffffff);
        var newMaskBytes:ByteArray = newMask.getPixels(newMask.rect);
        for (var i:int = 0; i < newMaskBytes.length / 4; i++) {
            var pxID:int = i * 4;
            if (bgIDs.indexOf(maskBytes[pxID + 3]) >= 0) {
                newMaskBytes[pxID] = 0;
                newMaskBytes[pxID + 1] = 0;
                newMaskBytes[pxID + 2] = 0;
                newMaskBytes[pxID + 3] = 0;
            }
            else{
                newMaskBytes[pxID] = 255;
                newMaskBytes[pxID + 1] = 255;
                newMaskBytes[pxID + 2] = 255;
                newMaskBytes[pxID + 3] = 255;
            }
        }
		newMaskBytes.position = 0;
		newMask.setPixels(newMask.rect, newMaskBytes);
		return newMask;
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
		return cropX() + (xMax - xMin) + 10 < workingBitmap.width ? (xMax - xMin) + 10 : workingBitmap.width - xMin;
	}

	private function cropHeight():int{
		return cropY() + (yMax - yMin) + 10 < workingBitmap.height ? (yMax - yMin) + 10 : workingBitmap.height - yMin;
	}

	private function cropX():int{
		return Math.max(xMin - 10, 0);
	}

	private function cropY():int{
		return Math.max(yMin - 10, 0);
	}

	private function getObjectMask():void {
		var scaledWorkingBM:BitmapData = cropAndScale(workingBitmap);
		var workingData:ByteArray= scaledWorkingBM.getPixels(scaledWorkingBM.rect);
		var args:Vector.<int> = new Vector.<int>();
		var imgPtr:int = CModule.malloc(workingData.length);
		workingData.position = 0;
		argbToRgba(workingData);
		CModule.writeBytes(imgPtr, workingData.length, workingData);
		var scribblePtr:int = CModule.malloc(workingData.length);
		var scaledScribbleBM:BitmapData = cropAndScale(scribbleBitmap);
		var scribbleData:ByteArray = scaledScribbleBM.getPixels(scaledScribbleBM.rect);
		scribbleData.position = 0;
		argbToRgba(scribbleData);
		CModule.writeBytes(scribblePtr, scribbleData.length, scribbleData);
	    args.push(imgPtr, scribblePtr, scaledWorkingBM.height, scaledWorkingBM.width, 1)
		var func:int = CModule.getPublicSymbol("grabCut")
		var result:int = CModule.callI(func, args);
		didGetObjectMask(result, imgPtr, workingData.length, scaledWorkingBM.width, scaledWorkingBM.height);
		CModule.free(imgPtr);
		CModule.free(scribblePtr);
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

	private function didGetObjectMask(retVal:*, imgPtr:int, imgLength:int, width:int, height:int):void {
		var bmData:ByteArray= new ByteArray();
		CModule.readBytes(imgPtr, imgLength, bmData);
		bmData.position=0;
		rgbaToArgb(bmData);
		var scaledMaskBitmap:BitmapData = new BitmapData(width, height, true, 0x00ffffff);
		scaledMaskBitmap.setPixels(scaledMaskBitmap.rect, bmData);
        removeIslands(scaledMaskBitmap);
        removeIslands(scaledMaskBitmap);
		var m:Matrix = new Matrix();
		m.scale(1./SCALE_FACTOR,1./SCALE_FACTOR);
		m.tx = cropX();
		m.ty = cropY();
		var maskBitmap:BitmapData = new BitmapData(workingBitmap.width, workingBitmap.height, true, 0x00ffffff);
		maskBitmap.draw(scaledMaskBitmap, m);
		bmData.position = 0;
		lastMask = maskBitmap.getPixels(maskBitmap.rect);
		setGreyscale();
		dispatchEvent(new Event(BitmapBackgroundTool.GOTMASK));
	}

    private function removeIslands(maskBitmap:BitmapData):void{
        var resultBitmap:BitmapData = new BitmapData(maskBitmap.width, maskBitmap.height, true, 0x00ffffff);
        var objectSegments:Array = new Array();
        var bgSegments:Array = new Array();
        bgIDs = [0xff];
        var segmentId:uint = 0;
        for(var j:int = 0; j<maskBitmap.height; j++ ){
            for(var i:int = 0; i<maskBitmap.width; i++ ){
                if(resultBitmap.getPixel32(i,j) != 0){
                    continue
                }
                var segment:uint = maskBitmap.getPixel32(i,j);
                (segment == 0 ? bgSegments : objectSegments)[segmentId] = floodFill(maskBitmap, resultBitmap, segment, 0xff000000 + segmentId, i, j);
//                trace("SEGMENT: ", segmentId, segment == 0);
//                trace("SIZE", (segment == 0 ? bgSegments : objectSegments)[segmentId]);
//                trace("AT: ", i, ",", j);
                segmentId++;
            }
        }
        var bgMax:uint = 0;
        for each(var bgElem:* in bgSegments){
            bgMax = Math.max(bgMax, bgElem as uint);
        }
        for(var bgIdx:* in bgSegments){
           if(bgSegments[bgIdx as uint] > bgMax * 0.1){
               bgIDs.push(bgIdx as uint);
           }
        }
        var objMax:uint = 0;
        for each(var objElem:* in objectSegments){
            objMax = Math.max(objMax, objElem as uint);
        }
        for(var objIdx:* in objectSegments){
            if(objectSegments[objIdx as uint] < objMax * 0.1){
                bgIDs.push(objIdx as uint);
            }
        }
		maskBitmap.copyPixels(reMask(resultBitmap), resultBitmap.rect, new Point(0,0));
    }

    private function floodFill(maskBitmap:BitmapData, processedBitmap:BitmapData, segment:uint, segmentId:uint, x:uint, y:uint):uint{
        processedBitmap.setPixel32(x, y, segmentId)
        var componentSize:uint = 1;
        var points:Array = new Array();
        points.push(new Point(x,y));
        while(!points.length == 0){
            var current:Point = points.pop();
            for(var i:int=-1; i<=1; i++){
                for(var j:int=-1; j<=1; j++){
					var cx:int = current.x + i;
                    var cy:int = current.y + j;
                    if(cx < 0 || cx >= maskBitmap.width ||
                       cy < 0 || cy >= maskBitmap.height ||
                       maskBitmap.getPixel32(cx, cy) != segment ||
                       processedBitmap.getPixel32(cx, cy) == segmentId)
                    {
                        continue;
                    }
                    processedBitmap.setPixel32(cx, cy, segmentId);
                    points.push(new Point(cx, cy));
                    componentSize++;
                }
            }
        }
        return componentSize;
    }

	public function refreshGreyscale():void{
		if(!lastMask) return;
		if(isGreyscale) {
			setFullColor();
		}
		else{
			setGreyscale();
		}
	}

	private function setFullColor():void{
        timer.stop();
        workingScribble.fillRect(workingScribble.rect, 0);
        workingScribble.draw(scribbleBitmap);
		editor.getWorkArea().getBitmap().visible = true;
        editor.getWorkArea().getSegmentation().visible = true;
		isGreyscale = false;
	}

	private function setGreyscale():void{
        editor.getWorkArea().getBitmap().visible = false;
        editor.getWorkArea().getSegmentation().visible = true;
        workingScribble.fillRect(workingScribble.rect, 0);
		applyPreviewMask(lastMask, workingScribble);
        timer.start();
		isGreyscale = true;
	}

	public function restoreUnmarked():void{
        timer.stop();
        workingScribble.fillRect(workingScribble.rect, 0);
        editor.getWorkArea().getBitmap().visible = true;
	}

	public function commitMask():void{
		if(lastMask) {
            timer.stop();
            editor.getWorkArea().getBitmap().visible = true;
			applyMask(lastMask, workingBitmap);
            editor.targetCostume.segmentationState.reset();
            loadState();
	///		workingScribble.fillRect(scribbleBitmap.rect, 0x00000000);
    ///        scribbleBitmap.fillRect(scribbleBitmap.rect, 0x00000000);
	///		lastMask = null;
	///		isGreyscale = false;
			editor.saveContent();
		}
	}
}
}
