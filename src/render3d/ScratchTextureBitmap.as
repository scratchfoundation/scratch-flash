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
import flash.display.BitmapData;

public class ScratchTextureBitmap extends BitmapData
{SCRATCH::allow3d{

	import flash.display3D.*;
	import flash.display3D.textures.Texture;
	import flash.geom.Rectangle;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import org.villekoskela.utils.RectanglePacker;

	private static var indexOfIDs:Array;

	private var rectPacker:RectanglePacker;
	private var texture:Texture;
	private var rectangles:Object;
	private var dirty:Boolean;
	public function ScratchTextureBitmap(width:int, height:int, transparent:Boolean=true, fillColor:uint=4.294967295E9)
	{
		super(width, height, transparent, fillColor);
		rectPacker = new RectanglePacker(width, height);
		rectangles = {};
		dirty = false;
	}

	public function getTexture(context:Context3D):Texture {
		if(!texture) {
			texture = context.createTexture(width, height, Context3DTextureFormat.BGRA, true);
			dirty = true;
		}

		if(dirty)
			texture.uploadFromBitmapData(this);

		dirty = false;
		return texture;
	}

	public function disposeTexture():void {
		if(texture) {
			texture.dispose();
			texture = null;
		}
	}

	// Returns an array of bitmap ids packed and rendered
	private var tmpPt:Point = new Point();
	public function packBitmaps(bitmapsByID:Object):Array {
		fillRect(this.rect, 0x00000000);  // Removing this speeds up texture repacking but creates edge rendering artifacts
		rectPacker.reset(width, height);
		indexOfIDs = [];

		var i:uint=0;
		for (var k:Object in bitmapsByID) {
			var bmd:BitmapData = bitmapsByID[k];
			// Add a small margin around the bitmaps
			rectPacker.insertRectangle(bmd.width+1, bmd.height+1, i);

			indexOfIDs.push(k);
			++i;
		}

		rectPacker.packRectangles();

		// Render the packed bitmaps
		var rect:Rectangle;
		var m:Matrix = new Matrix();
		rectangles = {};
		var packedIDs:Array = [];
		for (i=0; i<rectPacker.rectangleCount; ++i) {
			var bmID:String = indexOfIDs[rectPacker.getRectangleId(i)];
			rectangles[bmID] = rectPacker.getRectangle(i, null);
			// Remove the small margin around the bitmaps
			rect = rectangles[bmID];
			rect.width = rect.width - 1;
			rect.height = rect.height - 1;
			rect = rect.clone();
			//trace('Made rectangle for '+bmID+' to '+rect);
			tmpPt.x = rect.x; tmpPt.y = rect.y;
			rect.x = rect.y = 0;
			bmd = bitmapsByID[bmID];
			//trace('Copying pixels from bitmap with id: '+bmID+' @ '+bmd.width+'x'+bmd.height+'  -  '+tmpPt);
			m.tx = tmpPt.x;
			m.ty = tmpPt.y;
			draw(bmd, m);

			if(bmd is ChildRender) {
				rectangles[bmID].width = (bmd as ChildRender).renderWidth;
				rectangles[bmID].height = (bmd as ChildRender).renderHeight;
			}

			delete bitmapsByID[bmID];
			packedIDs.push(bmID);
		}

		dirty = true;

		return packedIDs;
	}

	public function getRect(id:String):Rectangle {
		return rectangles[id];
	}

	public function updateBitmap(id:String, bmd:BitmapData):void {
		var rect:Rectangle = rectangles[id];
		if(!rect) throw new Error("bitmap id not found");
		if(Math.ceil(rect.width) != bmd.width || Math.ceil(rect.height) != bmd.height) throw new Error("bitmap dimensions don't match existing rectangle");

		rect = rect.clone();
		tmpPt.x = rect.x; tmpPt.y = rect.y;
		rect.x = rect.y = 0;
//trace('Copying pixels from '+Dbg.printObj(bmd)+' with id: '+id+' @ '+bmd.width+'x'+bmd.height+'  -  '+pt);
		copyPixels(bmd, rect, tmpPt, null, null, false);
		dirty = true;
	}
}}
}


internal final class Dbg
{
	import flash.utils.getQualifiedClassName;
	public static function printObj(obj:*):String
	{
		var memoryHash:String;

		try
		{
			FakeClass(obj);
		}
		catch (e:Error)
		{
			memoryHash = String(e).replace(/.*([@|\$].*?) to .*$/gi, '$1');
		}

		return flash.utils.getQualifiedClassName(obj) + memoryHash;
	}
}

internal final class FakeClass { }
