/**
 * Created by Mallory on 9/18/15.
 */
package svgeditor.tools {
import flash.display.BitmapData;
import flash.display.BitmapData;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.utils.ByteArray;

import grabcut.CModule;

import grabcut._grabCut;

import scratch.ScratchCostume;

import svgeditor.ImageCanvas;

import svgeditor.ImageEdit;

import util.Base64Encoder;

public class BitmapBackgroundTool extends BitmapPencilTool{

	static public const BACKGROUND:int = -16711681;
	static public const APPLY:int = -16760833
	static public const OBJECT:int = 1;


	private var backgroundPoints:Vector.<Point> = new Vector.<Point>();
	private var objectPoints:Vector.<Point> = new Vector.<Point>();
	private var segmentationRequired:Boolean = false;
	private var unmarkedBitmap:BitmapData = null;
	private var lastMask:ByteArray = null;

	public function BitmapBackgroundTool(editor:ImageEdit, eraseMode:Boolean = false){
		super(editor, eraseMode)

	}

	override protected function mouseDown(evt:MouseEvent):void{
		if(!unmarkedBitmap){
			unmarkedBitmap = editor.getWorkArea().getBitmap().bitmapData.clone();
		}
		super.mouseDown(evt);
	}

	override protected function set lastPoint(p:Point):void{
		var color:int = getBrushColor();
		if(p != null){
			segmentationRequired = true;
			var scaledClick:Point = new Point(p.x/2, p.y/2);
			(getBrushColor() == BitmapBackgroundTool.BACKGROUND ? backgroundPoints : objectPoints).push(scaledClick);
			}
		super.lastPoint = p;
	}

	override protected function mouseUp(evt:MouseEvent):void{
		if(lastPoint && segmentationRequired && getBrushColor() == BitmapBackgroundTool.BACKGROUND && backgroundPoints.length > 0){
			getObjectMask();
			segmentationRequired = false;
		}
		if(getBrushColor() == BitmapBackgroundTool.APPLY){
			if(editor){
			var targetBM:BitmapData = editor.getWorkArea().getBitmap().bitmapData;
			targetBM.setPixels(targetBM.rect, applyMask(lastMask));
			}
		}
		super.mouseUp(evt);
	}

	private function applyPreviewMask(maskBytes:ByteArray):ByteArray{
		var workingBytes:ByteArray = unmarkedBitmap.clone().getPixels(unmarkedBitmap.rect);
		for(var i:int = 0; i<workingBytes.length/4; i++){
			var pxID:int = i * 4;
			if(maskBytes[pxID] == 0){
				var average:int = (workingBytes[pxID+1] + workingBytes[pxID+2]+workingBytes[pxID+3])/3
				workingBytes[pxID] = Math.min(workingBytes[pxID], 150);
				workingBytes[pxID + 1] = average;
				workingBytes[pxID + 2] = average;
				workingBytes[pxID + 3] = average;
			}
			else{
				workingBytes[pxID + 1] = Math.min(255, workingBytes[pxID + 1] + 100);
			}
		}
		workingBytes.position = 0;
		return workingBytes;
	}

	private function applyMask(maskBytes:ByteArray):ByteArray{
		var workingBytes:ByteArray = unmarkedBitmap.clone().getPixels(unmarkedBitmap.rect);
		for(var i:int = 0; i<workingBytes.length/4; i++){
			var pxID:int = i * 4;
			if(maskBytes[pxID] == 0){
				workingBytes[pxID] = 0;
			}
		}
		workingBytes.position = 0;
		return workingBytes;
	}

	private function getObjectMask():void {
		var workingBM:BitmapData = ScratchCostume.scaleForScratch(editor.getWorkArea().getBitmap().bitmapData);
		var workingData:ByteArray= workingBM.getPixels(workingBM.rect);
		var fgPts:String = JSON.stringify(objectPoints);
		var bgPts:String = JSON.stringify(backgroundPoints);
		//editor.app.externalCall("JSGetMinCut", didGetObjectMask, workingData, fgPts, bgPts, workingBM.width, workingBM.height);
		var args:Vector.<int> = new Vector.<int>();
		var imgPtr:int = CModule.malloc(workingData.length);
		workingData.position = 0;
		CModule.writeBytes(imgPtr, workingData.length, workingData);
		var scribblePtr:int = CModule.malloc(workingData.length);
		workingData.position = 0;
		CModule.writeBytes(scribblePtr, workingData.length, workingData);
		args.push(imgPtr, scribblePtr, workingBM.width, workingBM.height, 1)
		var func:int = CModule.getPublicSymbol("grabCut")
		CModule.callI(func, args);
		CModule.free(imgPtr);
		CModule.free(scribblePtr);
	}



	private function didGetObjectMask(retVal:*):void {
		var targetBM:BitmapData = editor.getWorkArea().getBitmap().bitmapData;
		var bmData:ByteArray = Base64Encoder.decode(String(retVal));
		lastMask = bmData;
		targetBM.setPixels(targetBM.rect, this.applyPreviewMask(bmData));
	}

}
}
