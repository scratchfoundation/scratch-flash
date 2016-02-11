/**
 * Created by Mallory on 9/18/15.
 */
package svgeditor.tools {

import assets.Resources;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.filters.ColorMatrixFilter;
import flash.filters.GlowFilter;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.ui.Mouse;
import flash.ui.MouseCursorData;
import flash.utils.ByteArray;
import flash.utils.Timer;
import flash.utils.setTimeout;
import grabcut.CModule;
import svgeditor.ImageEdit;
import svgeditor.objs.SegmentationEvent;
import svgeditor.objs.SegmentationState;
import flash.events.Event;




public class BitmapBackgroundTool extends BitmapPencilTool{


	static public const UPDATE_REQUIRED:String='got_mask';
	static private const SCALE_FACTOR:Number = .5;
	static private const SMOOTHING_ITERATIONS:int = 2;
	static private var STARTED_ASYNC:Boolean = false;
	static private const BUSY_CURSOR:String = "segmentationBusy";
	static private const BG_ISLAND_THRESHOLD:Number = 0.1;
	static private const OBJECT_ISLAND_THRESHOLD:Number = 0.1;
	static private const SEGMENT_STROKE_WIDTH:int = 6;
	static private const SEGMENT_OBJ_COLOR:uint = 0xFF0000FF;
	static private const SEGMENT_DISPLAY_COLOR:uint = 0xFF00FF00;

	private var segmentationRequired:Boolean = false;

	private var initialState:SegmentationState;
    private var previewFrameTimer:Timer = new Timer(100);
    private var previewFrameBackgrounds:Vector.<BitmapData> = new Vector.<BitmapData>();
    private var previewFrameIdx:int = 0;
    private var previewFrames:Vector.<BitmapData>;

	private var prevBrushColor:uint;
	private var prevAlpha:Number;
	private var prevStrokeWidth:int;
	private var segmentBrush:BitmapData;

	private var cursor:MouseCursorData = new MouseCursorData();

	private var firstPoint:Point;


    private function get bitmapLayerData():BitmapData
    {
        return editor.getWorkArea().getBitmap().bitmapData;
    }

	private function get segmentationLayer():Bitmap
	{
		return editor.getWorkArea().getSegmentation();
	}

	private function get segmentationLayerData():BitmapData{
		return editor.getWorkArea().getSegmentation().bitmapData;
	}

	private function get bitmapLayer():Bitmap
	{
		return editor.getWorkArea().getBitmap();
	}

	private function get segmentationState():SegmentationState
	{
		return editor.targetCostume.segmentationState;
	}

	public function BitmapBackgroundTool(editor:ImageEdit){
		if(!STARTED_ASYNC){
			CModule.startAsync();
			STARTED_ASYNC=true;
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
        );

        previewFrameTimer.addEventListener("timer", nextPreviewFrame);
		var frames:Vector.<BitmapData> = new Vector.<BitmapData>();
		frames.push(Resources.createBmp(BitmapBackgroundTool.BUSY_CURSOR).bitmapData);
		cursor.hotSpot = new Point(10,10);
		cursor.data = frames;
		Mouse.registerCursor(BitmapBackgroundTool.BUSY_CURSOR, cursor);
		super(editor, false)
	}


	//Overrides

	protected override function init():void{
		prevStrokeWidth = editor.getShapeProps().strokeWidth;
		prevBrushColor = editor.getShapeProps().color;
		prevAlpha = editor.getShapeProps().alpha;
		editor.setCurrentColor(SEGMENT_DISPLAY_COLOR, 1);
		editor.getShapeProps().strokeWidth = SEGMENT_STROKE_WIDTH;
		segmentBrush = makeBrush(SEGMENT_STROKE_WIDTH, SEGMENT_OBJ_COLOR);
		initialState = segmentationState;
		initState();
		segmentationState.unmarkedBitmap = bitmapLayerData.clone();
		STAGE.addEventListener(MouseEvent.CLICK, mouseClick, false, 0, true);
		super.init();
	}

	public override function refresh():void{
		segmentationState.unmarkedBitmap = bitmapLayerData.clone();
		segmentationState.costumeRect = bitmapLayerData.getColorBoundsRect(0xFF000000, 0x0, false)
	}


    protected override function shutdown():void{
		if(segmentationState != initialState)
			commitMask();
		segmentationState.eraseUndoHistory();
		editor.getShapeProps().strokeWidth = prevStrokeWidth;
		editor.setCurrentColor(prevBrushColor, prevAlpha);
		updateProperties();
		STAGE.removeEventListener(MouseEvent.CLICK, mouseClick);
        super.shutdown();

    }

	override protected function mouseDown(evt:MouseEvent):void{
        if (editor.getWorkArea().clickInBitmap(evt.stageX, evt.stageY)){
            previewFrameTimer.stop();
			firstPoint = penPoint();
			if(segmentationState.costumeRect.contains(firstPoint.x, firstPoint.y)){
				segmentationState.recordForUndo();
				editor.targetCostume.nextSegmentationState();
				segmentationRequired = true;
			}
        }
        super.mouseDown(evt);
    }

	private function mouseClick(evt:MouseEvent):void{
		var p:Point = penPoint();
		if((firstPoint && !segmentationState.costumeRect.contains(firstPoint.x, firstPoint.y) && editor.getWorkArea().clickInBitmap(evt.stageX, evt.stageY) && p && !segmentationState.costumeRect.contains(p.x, p.y))
		|| editor.clickedOutsideBitmap(evt)){
			if(segmentationState.lastMask){
				firstPoint = null;
				if (segmentationState.next == null) {
					segmentationState.recordForUndo();
				}
				editor.targetCostume.nextSegmentationState();
				commitMask(false);
				Scratch.app.setSaveNeeded()
				if(Mouse.supportsNativeCursor){
					Mouse.cursor = "arrow";
				}
				resetBrushes();
				moveFeedback();
			}
			else{
				segmentationState.reset();
				initState()
			}
		}
	}

	override protected function mouseUp(evt:MouseEvent):void{
		if(editor){
			if(segmentationRequired && editor.getWorkArea().clickInBitmap(evt.stageX, evt.stageY)){
				if(Mouse.supportsNativeCursor){
					Mouse.cursor = BitmapBackgroundTool.BUSY_CURSOR;
					Mouse.show();
				}
				//Render a frame to show the busy cursor before doing a segmentation
				setTimeout(getObjectMask,0);
				segmentationRequired = false;
			}
			resetBrushes();
		}
	}

	override protected function set lastPoint(p:Point):void{
		if(p != null){
			if(super.lastPoint == null){
				dispatchEvent(new Event(BitmapBackgroundTool.UPDATE_REQUIRED));
			}
			var px_left:int = Math.max(p.x, 0);
			var px_right:int = px_left + SEGMENT_STROKE_WIDTH;
			var py_top:int = Math.max(p.y, 0);
			var py_bottom:int = py_top + SEGMENT_STROKE_WIDTH;
			if( px_right > segmentationState.xMax){
				segmentationState.xMax = Math.min(px_right, bitmapLayerData.width);
			}
			if(py_bottom > segmentationState.yMax){
				segmentationState.yMax = Math.min(py_bottom, bitmapLayerData.height);
			}
			if(px_left < segmentationState.xMin){
				segmentationState.xMin = Math.min(px_left, bitmapLayerData.width - SEGMENT_STROKE_WIDTH);
			}
			if(py_top < segmentationState.yMin){
				segmentationState.yMin = Math.min(py_top, bitmapLayerData.height- SEGMENT_STROKE_WIDTH);
			}
		}
		super.lastPoint = p;
	}

	override protected function drawAtPoint(p:Point, targetCanvas:BitmapData=null, altBrush:BitmapData=null):void{
		targetCanvas = targetCanvas || segmentationLayerData;
        super.drawAtPoint(p, segmentationState.scribbleBitmap, segmentBrush);
		super.drawAtPoint(p, targetCanvas, altBrush);
	}

	private function nextPreviewFrame(event:TimerEvent):void{
        previewFrameIdx = (previewFrameIdx + 1) % previewFrameBackgrounds.length;
        segmentationLayerData.copyPixels(previewFrames[previewFrameIdx], previewFrames[previewFrameIdx].rect, new Point(0, 0));
    }


	//Segmentation State/Masking operations.  Methods that change the costumes segmentation and how it is displayed


	public function initState():void{
		previewFrameTimer.stop();
        segmentationLayerData.fillRect(segmentationLayerData.rect, 0);
        bitmapLayer.visible = true;
        segmentationLayer.visible = true;
        if(segmentationState.xMin < 0){
            segmentationState.xMin = bitmapLayerData.width
        }
        if(segmentationState.yMin < 0){
            segmentationState.yMin = bitmapLayerData.height;
        }
		segmentationState.scribbleBitmap = new BitmapData(bitmapLayerData.width, bitmapLayerData.height, true, 0x00000000);
		segmentationState.costumeRect = bitmapLayerData.getColorBoundsRect(0xFF000000, 0x0, false);
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



	public function commitMask(undoable:Boolean=true):void{
		previewFrameTimer.stop();
		bitmapLayer.visible = true;
		segmentationLayerData.fillRect(segmentationLayerData.rect, 0);
		segmentationState.reset();
		segmentationState.unmarkedBitmap = bitmapLayerData.clone();
		editor.saveContent(null, undoable);
		initState();
		dispatchEvent(new Event(BitmapBackgroundTool.UPDATE_REQUIRED));
	}

	public function refreshSegmentation():void{
        previewFrameTimer.stop();
		if(segmentationState.lastMask){
			setGreyscale();
			applyMask(segmentationState.lastMask, bitmapLayerData);
		}
		editor.saveContent(null, false);
	}

	public function restoreUnmarkedBitmap():void{
		previewFrameTimer.stop();
		segmentationLayerData.fillRect(segmentationLayerData.rect, 0);
		bitmapLayerData.copyPixels(segmentationState.unmarkedBitmap, segmentationState.unmarkedBitmap.rect, new Point(0,0));
		bitmapLayer.visible = true;
		editor.saveContent(null, false);
	}

	private function setGreyscale():void{
        bitmapLayer.visible = false;
        segmentationLayer.visible = true;
		applyPreviewMask(segmentationState.lastMask, segmentationLayerData);
        previewFrameTimer.start();
	}

	private function applyMask(maskBitmap:BitmapData, dest:BitmapData):void{
		dest.copyPixels(segmentationState.unmarkedBitmap, segmentationState.unmarkedBitmap.rect, new Point(0,0));
		if(maskBitmap){
			dest.threshold(maskBitmap, maskBitmap.rect, new Point(0,0), "==", 0x0, editor.isScene ? 0xFFFFFFFF : 0x0, 0xFF000000, false);
		}
	}

	//Utils used in the segmentation process for cropping and byte-level manipulation of costume/mask data

	private function cropRect():Rectangle{
		var cropX:int = segmentationState.xMin;
		var cropY:int = segmentationState.yMin;
		var cropWidth:int = segmentationState.xMax - segmentationState.xMin;
		var cropHeight:int = segmentationState.yMax - segmentationState.yMin;
		var drawRect:Rectangle = new Rectangle(cropX, cropY, cropWidth, cropHeight);
		var dx:int = Math.round(drawRect.width * .1);
		var dy:int = Math.round(drawRect.height * .1);
		drawRect.inflate(dx, dy);
		return bitmapLayerData.rect.intersection(drawRect.intersection(segmentationState.costumeRect));
	}

	private function cropAndScale(targetBitmap:BitmapData, rect:Rectangle):BitmapData{
		var croppedData:ByteArray = targetBitmap.getPixels(rect);
		croppedData.position = 0;
		var croppedBitmap:BitmapData = new BitmapData(rect.width, rect.height, true, 0x00ffffff);
		croppedBitmap.setPixels(croppedBitmap.rect, croppedData);
		var scaledBitmap:BitmapData = new BitmapData(croppedBitmap.width * .5, croppedBitmap.height * .5, true, 0x00ffffff);
		var m:Matrix = new Matrix();
		m.scale(SCALE_FACTOR, SCALE_FACTOR);
		scaledBitmap.draw(croppedBitmap, m);
		return scaledBitmap;
	}

	private static function argbToRgba(argbBytes:ByteArray):void{
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

	private static function rgbaToArgb(rgbaBytes:ByteArray):void{
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


	//The actual segmentation methods.  Get and format the data, pass it to the grabCut algorithm, do the post-processing, and display your results.

	private function getObjectMask():void {
		//Get a scaled down working bitmap and extract bytes
		var costumeRect:Rectangle = cropRect();
		if(costumeRect.x < 0 || costumeRect.y < 0 || costumeRect.width <= 0 || costumeRect.height <= 0){
			return;
		}
		var scaledWorkingBM:BitmapData = cropAndScale(segmentationState.unmarkedBitmap, costumeRect);
		var workingData:ByteArray= scaledWorkingBM.getPixels(scaledWorkingBM.rect);
		workingData.position = 0;
		//Scale the user's annotations in the same way, get the bytes
		var scaledScribbleBM:BitmapData = cropAndScale(segmentationState.scribbleBitmap, costumeRect);
		var scribbleData:ByteArray = scaledScribbleBM.getPixels(scaledScribbleBM.rect);
		scribbleData.position = 0;
		//Make pointers to arrays that the c++ code can use
		try{
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
	    	args.push(imgPtr, scribblePtr, scaledWorkingBM.height, scaledWorkingBM.width, 1);
			//get a function pointer to grabCut, call with args
			var func:int = CModule.getPublicSymbol("grabCut");
			//returns an exit_code:int which can be nice for debugging
			CModule.callI(func, args);
			//Start post processing, free our malloc'd memory
			function didGetObjectMask():void {
				var bmData:ByteArray = new ByteArray();
				//Extract mask bytes from the modified image buffer, convert to flash ARGB bytes
				CModule.readBytes(imgPtr, workingData.length, bmData);
				bmData.position=0;
				rgbaToArgb(bmData);
				//Remember, this needs to be scaled back up
				var scaledMaskBitmap:BitmapData = new BitmapData(scaledWorkingBM.width, scaledWorkingBM.height, true, 0x00ffffff);
				scaledMaskBitmap.setPixels(scaledMaskBitmap.rect, bmData);
				//Try to get rid of any holes/islands
        		var smoothedMask:BitmapData = removeIslands(scaledMaskBitmap, SMOOTHING_ITERATIONS);
				var m:Matrix = new Matrix();
				m.scale(1./SCALE_FACTOR,1./SCALE_FACTOR);
				var finalRect:Rectangle = cropRect();
				m.tx = finalRect.x;
				m.ty = finalRect.y;
				var maskBitmap:BitmapData = new BitmapData(bitmapLayerData.width, bitmapLayerData.height, true, 0x00ffffff);
				//Scale to original size
				maskBitmap.draw(smoothedMask, m);
				bmData.position = 0;
				segmentationState.lastMask = maskBitmap;
				//Show our hard earned results
				setGreyscale();
				function resetCursor():void{
					if(Mouse.supportsNativeCursor){
						Mouse.cursor = "arrow";
					}
				}
				//Same frame rendering thing
				setTimeout(resetCursor, 0);
				applyMask(segmentationState.lastMask, bitmapLayerData);
				editor.saveContent(null, false);
				dispatchEvent(new Event(BitmapBackgroundTool.UPDATE_REQUIRED));
			}
			didGetObjectMask();
		}
		finally {
			CModule.free(imgPtr);
			CModule.free(scribblePtr);
		}
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
}
}
