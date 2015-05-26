/**
 * Created by shanemc on 5/18/15.
 */
package ui {
import assets.Resources;

import blocks.Block;
import blocks.BlockIO;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.geom.Matrix;
import flash.geom.Rectangle;

import scratch.ScratchCostume;
import scratch.ScratchObj;
import scratch.ScratchSprite;
import ui.styles.ItemStyle;

// TODO: Cache bitmapdata renders by assetID / MD5 and dimensions
public class ThumbnailFactory {
	private var app:Scratch;
	public function ThumbnailFactory(app:Scratch) {
		this.app = app;
	}

	// Can create thumbnails for costumes, sprites, and sounds
	private static const cacheKey:String = '_id_drawn_';
	public function updateThumbnail(item:BaseItem, style:ItemStyle, skipCache:Boolean = false):void {
		var cacheID:String = getCacheID(item.data);
		if (!skipCache && item.data.extras && item.data.extras[cacheKey] == cacheID)
			return;

		item.setImage(renderThumbnail(item, style));

		if (!item.data.extras) item.data.extras = {};
		item.data.extras[cacheKey] = cacheID;
	}

	protected function getCacheID(data:ItemData):String {
		if (data.obj is ScratchObj)
			return (data.obj as ScratchObj).currentCostume().baseLayerMD5;
		else if (data.type == 'costume' || data.type == 'backdrop' || data.type == 'sound')
			return data.assetID;

		return data.assetID;
	}

	protected function renderThumbnail(item:BaseItem, style:ItemStyle):Bitmap {
		var type:String = item.data.type;
		var bmp:Bitmap;
		if (type == 'costume' || type == 'backdrop') {
			var costume:ScratchCostume = item.data.obj as ScratchCostume;
			bmp = new Bitmap(costume.thumbnail(style.imageWidth * getScaleFactor(),
					style.imageHeight * getScaleFactor(), type == 'backdrop'));
		}
		else if (type == 'sprite' || type == 'stage') {
			var scratchObj:ScratchObj = item.data.obj as ScratchObj;
			bmp = new Bitmap(scratchObj.currentCostume().thumbnail(style.imageWidth * getScaleFactor(),
					style.imageHeight * getScaleFactor(), type == 'stage'));
		}
		else if (type == 'script') {
			var obj:Array = item.data.obj;
			if (obj && obj.length) {
				var script:Block = BlockIO.arrayToStack(obj[0]);
				var r:Rectangle = script.getBounds(script);
				var centerX:Number = r.x + (r.width / 2);
				var centerY:Number = r.y + (r.height / 2);
				var bmd:BitmapData = new BitmapData(style.imageWidth * getScaleFactor(), style.imageHeight * getScaleFactor(), true, 0);
				var m:Matrix = new Matrix();
				var scale:Number = Math.min(bmd.width / script.width, bmd.height / script.height);
				m.scale(scale, scale);
				m.translate((bmd.width / 2) - (scale * centerX), (bmd.height / 2) - (scale * centerY));
				bmd.draw(script, m);
				bmp = new Bitmap(bmd);
			}
		}
		else if (type == 'sound') {
			bmp = Resources.createBmp('speakerOff');
		} else {
			bmp = getThumbnailForUnknown();
		}

		return bmp;
	}

	protected function getThumbnailForUnknown():Bitmap {
		return Resources.createBmp('questionMark');
	}

	protected function getScaleFactor():Number {
		return app.stage.contentsScaleFactor * app.scaleX;
	}
}}
