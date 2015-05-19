/**
 * Created by shanemc on 5/18/15.
 */
package ui {
import assets.Resources;

import blocks.Block;
import blocks.BlockIO;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.geom.Matrix;
import flash.geom.Rectangle;

import scratch.ScratchCostume;
import scratch.ScratchSprite;
import ui.styles.ItemStyle;

public class ThumbnailFactory {
	private var app:Scratch;
	public function ThumbnailFactory(app:Scratch) {
		this.app = app;
	}

	// Can create thumbnails for costumes, sprites, and sounds
	private static const cacheID:String = '_id_drawn_';
	public function updateThumbnail(item:BaseItem, style:ItemStyle):void {
		if (item.data.extras && item.data.extras[cacheID] == item.data.id)
			return;

		var type:String = item.data.type;
		var bmp:Bitmap;
		if (type == 'costume' || type == 'backdrop') {
			var obj:ScratchCostume = item.data.obj;
			bmp = new Bitmap(obj.thumbnail(style.imageWidth * getScaleFactor(),
					style.imageHeight * getScaleFactor(), type == 'backdrop'));
		}
		else if (type == 'sprite' || type == 'stage') {
			var obj:ScratchSprite = item.data.obj;
			bmp = new Bitmap(obj.currentCostume().thumbnail(style.imageWidth * getScaleFactor(),
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
			bmp = Resources.createBmp('questionMark');
		}

		item.setImage(bmp);

		if (!item.data.extras) item.data.extras = {};
		item.data.extras[cacheID] = item.data.id;
	}

	public function refresh(item:BaseItem, style:ItemStyle):void {

	}

	protected function getScaleFactor():Number {
		return app.stage.contentsScaleFactor * app.scaleX;
	}
}}
