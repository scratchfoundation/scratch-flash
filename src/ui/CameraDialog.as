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

package ui {
	import flash.display.*;
	import flash.media.*;
	import translation.Translator;
	import uiwidgets.*;

public class CameraDialog extends DialogBox {

	private var saveFunc:Function;
	private var picture:Bitmap;
	private var video:Video;

	public static function strings():Array {
		return ['Camera', 'Save', 'Close'];
	}

	public function CameraDialog(saveFunc:Function) {	
		super();
		this.saveFunc = saveFunc;

		addTitle(Translator.map('Camera'));

		var container:Sprite = new Sprite();
		addWidget(container);
	
		picture = new Bitmap();
		picture.bitmapData = new BitmapData(320, 240, true);
		picture.visible = false;
		container.addChild(picture);

		video = new Video(320, 240);
		video.smoothing = true;
		video.attachCamera(Camera.getCamera());
		container.addChild(video);

		var b:Button;
		addChild(b = new Button(Translator.map('Save'), savePicture));
		buttons.push(b);		
		addChild(b = new Button(Translator.map('Close'), closeDialog));
		buttons.push(b);		
	}

	private function savePicture():void {
		picture.bitmapData.draw(video);
		if (saveFunc != null) (saveFunc(picture.bitmapData.clone()));
	}

	public function closeDialog():void {
		if (video) video.attachCamera(null);
		if (parent) parent.removeChild(this);
	}

}}
