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

// VideoMotionPrims.as
// Tony Hwang and John Maloney, January 2011
//
// Video motion sensing primitives.

package primitives {
	import flash.display.*;
	import flash.geom.*;
	import flash.utils.*;
	import blocks.Block;
	import interpreter.*;
	import scratch.*;

public class VideoMotionPrims {

	public static var readMotionSensor:Function;

	private const toDegree:Number = 180 / Math.PI;
	private const WIDTH:int = 480;
	private const HEIGHT:int = 360;
	private const AMOUNT_SCALE:int = 100; // chosen empirically to give a range of roughly 0-100
	private const THRESHOLD:int = 10;
	private const WINSIZE:int = 8;

	private var app:Scratch;
	private var interp:Interpreter;

	private var gradA2Array:Vector.<Number> = new Vector.<Number>(WIDTH*HEIGHT,true);
	private var gradA1B2Array:Vector.<Number> = new Vector.<Number>(WIDTH*HEIGHT,true);
	private var gradB1Array:Vector.<Number> = new Vector.<Number>(WIDTH*HEIGHT,true);
	private var gradC2Array:Vector.<Number> = new Vector.<Number>(WIDTH*HEIGHT,true);
	private var gradC1Array:Vector.<Number> = new Vector.<Number>(WIDTH*HEIGHT,true);

	private var motionAmount:int;
	private var motionDirection:int;
	private var analysisDone:Boolean;

	private var frameNum:int;
	private var frameBuffer:BitmapData;
	private var curr:Vector.<uint>;
	private var prev:Vector.<uint>;

	public function VideoMotionPrims(app:Scratch, interpreter:Interpreter) {
		this.app = app;
		this.interp = interpreter;
		frameBuffer = new BitmapData(WIDTH, HEIGHT);
	}

	public function addPrimsTo(primTable:Dictionary):void {
		primTable['senseVideoMotion'] = primVideoMotion;
		readMotionSensor = getMotionOn;
	}

	private function primVideoMotion(b:Block):Number {
		var motionType:String = interp.arg(b, 0);
		var obj:ScratchObj = app.stagePane.objNamed(String(interp.arg(b, 1)));
		if ('this sprite' == interp.arg(b, 1)) obj = interp.targetObj();
		return getMotionOn(motionType, obj);
	}

	private function getMotionOn(motionType:String, obj:ScratchObj):Number {
		if (!obj) return 0;
		startMotionDetector();
		if (!analysisDone) analyzeFrame();
		if (obj.isStage) {
			if (motionType == 'direction') return motionDirection;
			if (motionType == 'motion') return Math.min(100, motionAmount);
		} else {
			var s:ScratchSprite = obj as ScratchSprite;
			if (analysisDone) getLocalMotion(s);
			if (motionType == 'direction') return s.localMotionDirection;
			if (motionType == 'motion') return Math.min(100, s.localMotionAmount);
		}
		return 0;
	}

	// start/stop getting step() calls from runtime:
	private function startMotionDetector():void { app.runtime.motionDetector = this }
	private function stopMotionDetector():void { app.runtime.motionDetector = null }

	public function step():void {
		frameNum++;
		var sprites:Array = app.stagePane.sprites();
		if (!(app.stagePane && app.stagePane.videoImage)) {
			prev = curr = null;
			motionAmount = motionDirection = 0;
			for (var i:int = 0; i < sprites.length; i++) {
				sprites[i].localMotionAmount = 0;
				sprites[i].localMotionDirection = 0;
			}
			analysisDone = true;
			stopMotionDetector();
			return;
		}
		var img:BitmapData = app.stagePane.videoImage.bitmapData;
		var scale:Number = Math.min(WIDTH / img.width, HEIGHT / img.height);
		var m:Matrix = new Matrix();
		m.scale(scale, scale);
		frameBuffer.draw(img, m);
		prev = curr;
		curr = frameBuffer.getVector(frameBuffer.rect);
		analysisDone = false;
	}

	private function getLocalMotion(s:ScratchSprite):void {
		if (!curr || !prev) {
			s.localMotionAmount = s.localMotionDirection = -1;
			return; // don't have two frames to analyze yet
		}
		if (s.localFrameNum != frameNum) {
			var i:int, j:int;
			var address:int;
			var activePixelNum:int;

			var A2:Number, A1B2:Number, B1:Number, C1:Number, C2:Number;
			var u:Number, v:Number, uu:Number, vv:Number;

			var boundingRect:Rectangle = s.bounds();		//bounding rectangle for sprite
			var xmin:Number = boundingRect.left;
			var xmax:Number = boundingRect.right;
			var ymin:Number = boundingRect.top;
			var ymax:Number = boundingRect.bottom;
			var scaleFactor:Number = 0;

			A2 = 0;
			A1B2 = 0;
			B1 = 0;
			C1 = 0;
			C2 = 0;
			activePixelNum = 0;
			for (i = ymin; i < ymax; i++) { // y
				for (j = xmin; j < xmax; j++) { // x
					if (j>0 && (j< WIDTH-1) && i>0 && (i< HEIGHT-1)
						&& ((s.bitmap().getPixel32(j-xmin,i-ymin) >> 24 & 0xff) == 0xff))
					{
						address = i * WIDTH + j;
						A2 += gradA2Array[address];
						A1B2 += gradA1B2Array[address];
						B1 += gradB1Array[address];
						C2 += gradC2Array[address];
						C1 += gradC1Array[address];
						scaleFactor++;
					}
				}
			}
			var delta:Number = (A1B2 * A1B2 - A2 * B1);
			if (delta) {
				// system is not singular - solving by Kramer method
				var deltaX:Number = -(C1 * A1B2 - C2 * B1);
				var deltaY:Number = -(A1B2 * C2 - A2 * C1);
				var Idelta:Number = 8 / delta;
				u = deltaX * Idelta;
				v = deltaY * Idelta;
			} else {
				// singular system - find optical flow in gradient direction
				var Norm:Number = (A1B2 + A2) * (A1B2 + A2) + (B1 + A1B2) * (B1 + A1B2);
				if (Norm) {
					var IGradNorm:Number = 8 / Norm;
					var temp:Number = -(C1 + C2) * IGradNorm;
					u = (A1B2 + A2) * temp;
					v = (B1 + A1B2) * temp;
				} else {
					u = v = 0;
				}
			}

			if (scaleFactor != 0){
				activePixelNum = scaleFactor; //store the area of the sprite in pixels
				scaleFactor /= (2*WINSIZE*2*WINSIZE);

				u= u/scaleFactor;
				v= v/scaleFactor;
			}

			s.localMotionAmount = Math.round(AMOUNT_SCALE * 2e-4 *activePixelNum * Math.sqrt((u * u) + (v * v))); // note 2e-4 *activePixelNum is an experimentally tuned threshold for my logitech Pro 9000 webcam - TTH
			if (s.localMotionAmount > 100) //clip all magnitudes greater than 100
				s.localMotionAmount = 100;
			if (s.localMotionAmount > (THRESHOLD/3)) {
				s.localMotionDirection = ((Math.atan2(v, u) * toDegree + 270) % 360) - 180; // Scratch direction
			}
			s.localFrameNum = frameNum;
		}
	}

	private function analyzeFrame():void {
		if (!curr || !prev) {
			motionAmount = motionDirection = -1;
			return; // don't have two frames to analyze yet
		}
		const winStep:int = WINSIZE * 2 + 1;
		const wmax:int = WIDTH - WINSIZE - 1;
		const hmax:int = HEIGHT - WINSIZE - 1;

		var i:int, j:int, k:int, l:int;
		var address:int;

		var A2:Number, A1B2:Number, B1:Number, C1:Number, C2:Number;
		var u:Number, v:Number, uu:Number, vv:Number, n:int;

		uu = vv = n = 0;
		for (i = WINSIZE + 1; i < hmax; i += winStep) { // y
			for (j = WINSIZE + 1; j < wmax; j += winStep) { // x
				A2 = 0;
				A1B2 = 0;
				B1 = 0;
				C1 = 0;
				C2 = 0;
				for (k = -WINSIZE; k <= WINSIZE; k++) { // y
					for (l = -WINSIZE; l <= WINSIZE; l++) { // x
						var gradX:int, gradY:int, gradT:int;

						address = (i + k) * WIDTH + j + l;
						gradX = (curr[address - 1] & 0xff) - (curr[address + 1] & 0xff);
						gradY = (curr[address - WIDTH] & 0xff) - (curr[address + WIDTH] & 0xff);
						gradT = (prev[address] & 0xff) - (curr[address] & 0xff);

						gradA2Array[address] = gradX*gradX;
						gradA1B2Array[address] = gradX*gradY;
						gradB1Array[address] = gradY*gradY;
						gradC2Array[address] = gradX*gradT;
						gradC1Array[address]= gradY*gradT;

						A2 += gradA2Array[address];
						A1B2 += gradA1B2Array[address];
						B1 += gradB1Array[address];
						C2 += gradC2Array[address];
						C1 += gradC1Array[address];
					}
				}
				var delta:Number = (A1B2 * A1B2 - A2 * B1);
				if (delta) {
					/* system is not singular - solving by Kramer method */
					var deltaX:Number = -(C1 * A1B2 - C2 * B1);
					var deltaY:Number = -(A1B2 * C2 - A2 * C1);
					var Idelta:Number = 8 / delta;
					u = deltaX * Idelta;
					v = deltaY * Idelta;
				} else {
					/* singular system - find optical flow in gradient direction */
					var Norm:Number = (A1B2 + A2) * (A1B2 + A2) + (B1 + A1B2) * (B1 + A1B2);
					if (Norm) {
						var IGradNorm:Number = 8 / Norm;
						var temp:Number = -(C1 + C2) * IGradNorm;
						u = (A1B2 + A2) * temp;
						v = (B1 + A1B2) * temp;
					} else {
						u = v = 0;
					}
				}
				if (-winStep < u && u < winStep && -winStep < v && v < winStep) {
					uu += u;
					vv += v;
					n++;
				}
			}
		}
		uu /= n ;
		vv /= n;
		motionAmount = Math.round(AMOUNT_SCALE * Math.sqrt((uu * uu) + (vv * vv)));
		if (motionAmount > THRESHOLD) {
			motionDirection = ((Math.atan2(vv, uu) * toDegree + 270) % 360) - 180; // Scratch direction
		}
		analysisDone = true;
	}

}}
