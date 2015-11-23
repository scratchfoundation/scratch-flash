/**
 * Created by Mallory on 9/18/15.
 */
package svgeditor.tools {
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.BitmapData;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filters.GlowFilter;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.ui.Mouse;
import flash.utils.ByteArray;

import grabcut.CModule;
import scratch.ScratchCostume;

import svgeditor.ImageCanvas;

import svgeditor.ImageEdit;
import svgeditor.objs.SegmentationState;

import uiwidgets.EditableLabel;

import util.Base64Encoder;

public class BitmapBackgroundTool extends BitmapPencilTool{


	static public const GOTMASK:String='got_mask';

	static private const SCALE_FACTOR:Number = .5;
	static private var startedAsync:Boolean = false;

    private var borderPoints:Vector.<Point>;
	private var segmentationRequired:Boolean = false;
    private var workingScribble:BitmapData;

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
			CModule.startAsync();
			startedAsync=true;
		}
		super(editor, false)
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
        super.shutdown();
    }

	override protected function mouseUp(evt:MouseEvent):void{
		if(lastPoint && segmentationRequired){
			getObjectMask();
			segmentationRequired = false;
		}
		resetBrushes();
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

    private function pixelIdx(x:int, y:int):int{
        if(x < 0 || x >= workingBitmap.width || y < 0 || y >= workingBitmap.height)
        {
            return -1;
        }
        return ((y * workingBitmap.width) + x) * 4;
    }


	private function applyPreviewMask(maskBytes:ByteArray, dest:BitmapData):void{
		var workingBytes:ByteArray = workingBitmap.clone().getPixels(workingBitmap.rect);
		for(var i:int =0; i < workingBytes.length/4; i++){
			    var pxIdx:int = i * 4;
	    		if(maskBytes[pxIdx] == 0){
                    var average:int = (workingBytes[pxIdx + 1] + workingBytes[pxIdx + 2] + workingBytes[pxIdx + 3]) / 3
                    workingBytes[pxIdx] = Math.min(workingBytes[pxIdx], 150);
                    workingBytes[pxIdx + 1] = average;
                    workingBytes[pxIdx + 2] = average;
                    workingBytes[pxIdx + 3] = average;
		    }
        }
		workingBytes.position = 0;
		var glowObject:BitmapData = workingBitmap.clone();
        applyMask(lastMask, glowObject);
        dest.setPixels(dest.rect, workingBytes);
        glowObject.applyFilter(glowObject, glowObject.rect, new Point(0,0), new GlowFilter(16711680, 1.0, 6.0, 6.0, 2, 1, false, true));
        dest.draw(glowObject);
	}

    private function isBorderPx(maskBytes:ByteArray, pxIdx:int, w:int, h:int):Boolean{
        var left:int = pxIdx - 4;
        var right:int = pxIdx + 4;
        var above:int =  pxIdx - (4 * workingBitmap.width)
        var below:int = pxIdx + (4 * workingBitmap.width);
        if(maskBytes[pxIdx] == 0){
            if(pxIdx % w >= 4  && maskBytes[left] != 0){
                return true;
            }
            if(pxIdx % w < w - 4 && maskBytes[right] != 0){
                return true;
            }
            if(Math.floor(pxIdx / w) > 0 && maskBytes[above] != 0){
                return true;
            }
            if(Math.floor(pxIdx / w) < h && maskBytes[below] != 0){
                return true;
            }
        }
        else{
            if(pxIdx % w <= 4 || maskBytes[left] == 0){
                return true;
            }
            if(pxIdx % w > w - 4 || maskBytes[right] == 0){
                return true;
            }
            if(Math.floor(pxIdx / w) <= 0 || maskBytes[above] == 0){
                return true;
            }
            if(Math.floor(pxIdx / w) >= h|| maskBytes[below] == 0){
                return true;
            }
        }
        return false;

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
		isGreyscale = true;
	}

	public function restoreUnmarked():void{
        workingScribble.fillRect(workingScribble.rect, 0);
        editor.getWorkArea().getBitmap().visible = true;
	}

	public function commitMask():void{
		if(lastMask) {
            editor.getWorkArea().getBitmap().visible = true;
			applyMask(lastMask, workingBitmap);
			workingScribble.fillRect(scribbleBitmap.rect, 0x00000000);
            scribbleBitmap.fillRect(scribbleBitmap.rect, 0x00000000);
			lastMask = null;
			isGreyscale = false;
			editor.saveContent();
		}
	}
}
}
