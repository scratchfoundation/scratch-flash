/**
 * VERSION: 0.6
 * DATE: 2012-01-20
 * AS3
 * UPDATES AND DOCS AT: http://www.greensock.com
 **/
package com.greensock {
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.geom.Transform;
/**
 * A BlitMask is basically a rectangular Sprite that acts as a high-performance mask for a DisplayObject
 * by caching a bitmap version of it and blitting only the pixels that should be visible at any given time,
 * although its <code>bitmapMode</code> can be turned off to restore interactivity in the DisplayObject 
 * whenever you want. When scrolling very large images or text blocks, a BlitMask can greatly improve 
 * performance, especially on mobile devices that have weaker processors. <br /><br />
 * 
 * Here are some of the conveniences BlitMask offers:<br />
 * <ul>
 * 		<li>Excellent scrolling performance</li>
 * 		<li>You don't need to do anything special with your target DisplayObject - move/scale/rotate it 
 * 			however you please and then <code>update()</code> the BlitMask and it syncs the pixels.
 * 			The BlitMask basically sits on top of the DisplayObject in the display list and you can 
 * 			move it independently too if you want.</li>
 * 		<li>Use the BlitMask's <code>scrollX</code> and <code>scrollY</code> properties to move the
 * 			target DisplayObject inside the masked area. For example, to scroll from top to bottom over 
 * 			the course of 2 seconds, simply do: <br /><code>myBlitMask.scrollY = 0;<br />
 * 			TweenLite.to(myBlitMask, 2, {scrollY:1});</code> </li>
 * 		<li>Use the "wrap" feature to make the bitmap wrap around to the opposite side when it scrolls 
 * 			off one of the edges (only in <code>bitmapMode</code> of course), as though the BlitMask is 
 * 			filled with a grid of bitmap copies of the target.</li>
 * 		<li>For maximum performance in bitmapMode, set <code>smoothing</code> to <code>false</code> or 
 * 			for maximum quality, set it to <code>true</code></li>
 * 		<li>You can toggle the <code>bitmapMode</code> to get either maximum performance or interactivity 
 * 			in the target DisplayObject anytime. (some other solutions out there are only viable for 
 * 			non-interactive bitmap content) </li>
 * 		<li>MouseEvents are dispatched by the BlitMask, so you can listen for clicks, rollovers, rollouts, etc.</li>
 * </ul>
 * 
 * @example Example AS3 code:<listing version="3.0">
 import com.greensock.~~;
 
 //create a 200x200 BlitMask positioned at x:20, y:50 to mask our "mc" object and turn smoothing on:
 var blitMask:BlitMask = new BlitMask(mc, 20, 50, 200, 200, true);
 
 //position mc at the top left of the BlitMask using the scrollX and scrollY properties
 blitMask.scrollX = 0;
 blitMask.scrollY = 0;
 
 //tween the scrollY to make mc scroll to the bottom over the course of 3 seconds and then turn off bitmapMode so that mc becomes interactive:
 TweenLite.to(blitMask, 3, {scrollY:1, onComplete:blitMask.disableBitmapMode});
 
 //or simply position mc manually and then call update() to sync the display:
 mc.x = 350;
 blitMask.update();
 
 </listing>
 * 
 * Notes:
 * <ul>
 * 		<li>BlitMasks themselves should not be rotated or scaled (although technically you can alter the scaleX and scaleY 
 * 			but doing so will only change the width or height instead). You can, of course, alter their x, y, width, 
 * 			or height properties as much as you want. </li>
 * 		<li>BlitMasks don't perform nearly as well in bitmapMode when the <code>target</code> is being scaled or rotated 
 * 			because it forces a flushing and recapture of the internal bitmap. BlitMasks are <b>MUCH</b> better when you are
 * 			simply changing x/y properties (scrolling) because it can reuse the same cached bitmap over and over.</li>
 * 		<li>If the target content is changing frequently (like if it has nested MovieClips that are animating on every frame),
 * 			you'd need to call update(null, true) each time you want the BlitMask to redraw itself to sync with the changes 
 * 			in the target, but that's a relatively expensive operation so it's not a great use case for BlitMask. You may
 * 			be better off just turning off bitmapMode during that animation sequence.</li>
 * </ul><br /><br />
 * 
 * <b>Copyright 2011-2012, GreenSock. All rights reserved.</b> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for corporate Club GreenSock members, the software agreement that was issued with the corporate membership.
 * 
 * @author Jack Doyle, jack@greensock.com
 **/
	public class BlitMask extends Sprite {
		/** @private **/
		public static var version:Number = 0.6;
		
		// In order to conserve memory and improve performance, we create a few instances of Rectangles, Sprites, Points, Matrices, and Arrays and reuse them rather than creating new instances over and over.
		/** @private **/
		protected static var _tempContainer:Sprite = new Sprite();
		/** @private **/
		protected static var _sliceRect:Rectangle = new Rectangle();
		/** @private **/
		protected static var _drawRect:Rectangle = new Rectangle();
		/** @private **/
		protected static var _destPoint:Point = new Point();
		/** @private **/
		protected static var _tempMatrix:Matrix = new Matrix();
		/** @private **/
		protected static var _emptyArray:Array = [];
		/** @private **/
		protected static var _colorTransform:ColorTransform = new ColorTransform();
		/** @private **/
		protected static var _mouseEvents:Array = [MouseEvent.CLICK, MouseEvent.DOUBLE_CLICK, MouseEvent.MOUSE_DOWN, MouseEvent.MOUSE_MOVE, MouseEvent.MOUSE_OUT, MouseEvent.MOUSE_OVER, MouseEvent.MOUSE_UP, MouseEvent.MOUSE_WHEEL, MouseEvent.ROLL_OUT, MouseEvent.ROLL_OVER];
		
		/** @private **/
		protected var _target:DisplayObject;
		/** @private **/
		protected var _fillColor:uint;
		/** @private **/
		protected var _smoothing:Boolean;
		/** @private **/
		protected var _width:Number;
		/** @private **/
		protected var _height:Number;
		/** @private **/
		protected var _bd:BitmapData;
		/** @private maximum number of pixels (minus one) that each BitmapData cell in the grid can be **/
		protected var _gridSize:int = 2879;
		/** @private **/
		protected var _grid:Array;
		/** @private **/
		protected var _bounds:Rectangle;
		/** @private **/
		protected var _clipRect:Rectangle;
		/** @private **/
		protected var _bitmapMode:Boolean;
		/** @private **/
		protected var _rows:int;
		/** @private **/
		protected var _columns:int;
		/** @private **/
		protected var _scaleX:Number;
		/** @private **/
		protected var _scaleY:Number;
		/** @private **/
		protected var _prevMatrix:Matrix;
		/** @private **/
		protected var _transform:Transform;
		/** @private **/
		protected var _prevRotation:Number;
		/** @private **/
		protected var _autoUpdate:Boolean;
		/** @private **/
		protected var _wrap:Boolean;
		/** @private **/
		protected var _wrapOffsetX:Number = 0;
		/** @private **/
		protected var _wrapOffsetY:Number = 0;
		
		/**
		 * Constructor
		 * 
		 * @param target The DisplayObject that will be masked by the BlitMask
		 * @param x x coorinate of the upper left corner of the BlitMask. If <code>smoothing</code> is <code>false</code>, the x coordinate will be rounded to the closest integer.
		 * @param y y coordinate of the upper right corner of the BlitMask
		 * @param width width of the BlitMask (in pixels)
		 * @param height height of the BlitMask (in pixels)
		 * @param smoothing If <code>false</code> (the default), the bitmap (and the BlitMask's x/y coordinates) will be rendered only on whole pixels which is faster in terms of processing. However, for the best quality and smoothest animation, set <code>smoothing</code> to <code>true</code>.
		 * @param autoUpdate If <code>true</code>, the BlitMask will automatically watch the <code>target</code> to see if its position/scale/rotation has changed on each frame (while <code>bitmapMode</code> is <code>true</code>) and if so, it will <code>update()</code> to make sure the BlitMask always stays synced with the <code>target</code>. This is the easiest way to use BlitMask but it is slightly less efficient than manually calling <code>update()</code> whenever you need to. Keep in mind that if you're tweening with TweenLite or TweenMax, you can simply set its <code>onUpdate</code> to the BlitMask's <code>update()</code> method to keep things synced. Like <code>onUpdate:myBlitMask.update</code>.
		 * @param fillColor The ARGB hexadecimal color that should fill the empty areas of the BlitMask. By default, it is transparent (0x00000000). If you wanted a red color, for example, it would be <code>0xFFFF0000</code>.
		 * @param wrap If <code>true</code>, the bitmap will be wrapped around to the opposite side when it scrolls off one of the edges (only in <code>bitmapMode</code> of course), like the BlitMask is filled with a grid of bitmap copies of the target. Use the <code>wrapOffsetX</code> and <code>wrapOffsetY</code> properties to affect how far apart the copies are from each other. 
		 */
		public function BlitMask(target:DisplayObject, x:Number=0, y:Number=0, width:Number=100, height:Number=100, smoothing:Boolean=false, autoUpdate:Boolean=false, fillColor:uint=0x00000000, wrap:Boolean=false) {
			super();
			if (width < 0 || height < 0) {
				throw new Error("A FlexBlitMask cannot have a negative width or height.");
			}
			_width = width;
			_height = height;
			_scaleX = _scaleY = 1;
			_smoothing = smoothing;
			_fillColor = fillColor;
			_autoUpdate = autoUpdate;
			_wrap = wrap;
			_grid = [];
			_bounds = new Rectangle();
			if (_smoothing) {
				super.x = x;
				super.y = y;
			} else { 
				super.x = (x < 0) ? (x - 0.5) >> 0 : (x + 0.5) >> 0;
				super.y = (y < 0) ? (y - 0.5) >> 0 : (y + 0.5) >> 0;
			}
			_clipRect = new Rectangle(0, 0, _gridSize + 1, _gridSize + 1);
			_bd = new BitmapData(width + 1, height + 1, true, _fillColor);
			_bitmapMode = true;
			this.target = target;
		}
		
		/** @private **/
		protected function _captureTargetBitmap():void {
			if (_bd == null || _target == null) { //must have been disposed, so don't update. 
				return;
			}
			
			_disposeGrid();
			
			//capturing when the target is masked (or has a scrollRect) can cause problems. 
			var prevMask:DisplayObject = _target.mask;
			if (prevMask != null) {
				_target.mask = null; 
			}
			var prevScrollRect:Rectangle = _target.scrollRect;
			if (prevScrollRect != null) {
				_target.scrollRect = null;
			}
			var prevFilters:Array = _target.filters;
			if (prevFilters.length != 0) {
				_target.filters = _emptyArray;
			}
			
			_grid = [];
			if (_target.parent == null) {
				_tempContainer.addChild(_target);
			}
			_bounds = _target.getBounds(_target.parent);
			var w:Number = 0;
			var h:Number = 0;
			_columns = Math.ceil(_bounds.width / _gridSize);
			_rows = Math.ceil(_bounds.height / _gridSize);
			var cumulativeHeight:Number = 0;
			var matrix:Matrix = _transform.matrix;
			var xOffset:Number = matrix.tx - _bounds.x;
			var yOffset:Number = matrix.ty - _bounds.y;
			if (!_smoothing) {
				xOffset = (xOffset + 0.5) >> 0;
				yOffset = (yOffset + 0.5) >> 0;
			}
			
			var bd:BitmapData, cumulativeWidth:Number;
			for (var row:int = 0; row < _rows; row++) {
				h = (_bounds.height - cumulativeHeight > _gridSize) ? _gridSize : _bounds.height - cumulativeHeight;
				matrix.ty = -cumulativeHeight + yOffset;
				cumulativeWidth = 0;
				_grid[row] = [];
				for (var column:int = 0; column < _columns; column++) {
					w = (_bounds.width - cumulativeWidth > _gridSize) ? _gridSize : _bounds.width - cumulativeWidth;
					_grid[row][column] = bd = new BitmapData(w + 1, h + 1, true, _fillColor);
					matrix.tx = -cumulativeWidth + xOffset;
					bd.draw(_target, matrix, null, null, _clipRect, _smoothing);
					cumulativeWidth += w;
				}
				cumulativeHeight += h;
			}
			
			if (_target.parent == _tempContainer) {
				_tempContainer.removeChild(_target);
			}
			
			if (prevMask != null) {
				_target.mask = prevMask;
			}
			if (prevScrollRect != null) {
				_target.scrollRect = prevScrollRect;
			}
			if (prevFilters.length != 0) {
				_target.filters = prevFilters;
			}
		}
		
		/** @private **/
		protected function _disposeGrid():void {
			var i:int = _grid.length, j:int, r:Array;
			while (--i > -1) {
				r = _grid[i];
				j = r.length;
				while (--j > -1) {
					BitmapData(r[j]).dispose();
				}
			}
		}
	
		/**
		 * Updates the BlitMask's internal bitmap to reflect the <code>target's</code> current position/scale/rotation. 
		 * This is a very important method that you'll need to call whenever visual or transformational changes are made 
		 * to the target so that the BlitMask remains synced with it. 
		 * 
		 * @param event An optional Event object (which isn't used at all internally) in order to make it easier to use <code>update()</code> as an event handler. For example, you could <code>addEventListener(Event.ENTER_FRAME, myBlitMask.update)</code> to make sure it is updated on every frame (although it would be more efficient to simply set <code>autoUpdate</code> to <code>true</code> in this case). 
		 * @param forceRecaptureBitmap Normally, the cached bitmap of the <code>target</code> is only recaptured if its scale or rotation changed because doing so is rather processor-intensive, but you can force a full update (and regeneration of the cached bitmap) by setting <code>forceRecaptureBitmap</code> to <code>true</code>.
		 */
		public function update(event:Event=null, forceRecaptureBitmap:Boolean=false):void {
			if (_bd == null) {
				return;
			} else if (_target == null) {
				_render();
			}  else if (_target.parent) {
				_bounds = _target.getBounds(_target.parent);
				if (this.parent != _target.parent) {
					_target.parent.addChildAt(this, _target.parent.getChildIndex(_target));
				}
			}
			if (_bitmapMode || forceRecaptureBitmap) {
				var m:Matrix = _transform.matrix;
				if (forceRecaptureBitmap || _prevMatrix == null || m.a != _prevMatrix.a || m.b != _prevMatrix.b || m.c != _prevMatrix.c || m.d != _prevMatrix.d) {
					_captureTargetBitmap();
					_render();
				} else if (m.tx != _prevMatrix.tx || m.ty != _prevMatrix.ty) {
					_render();
				} else if (_bitmapMode && _target != null) {
					this.filters = _target.filters;
					this.transform.colorTransform = _transform.colorTransform;
				}
				_prevMatrix = m;
			}
		}
		
		/** @private  **/
		protected function _render(xOffset:Number=0, yOffset:Number=0, clear:Boolean=true, limitRecursion:Boolean=false):void {
			//note: the code in this method was optimized for speed rather than readability or succinctness (since the whole point of this class is to help things perform better)
			if (clear) {
				_sliceRect.x = _sliceRect.y = 0;
				_sliceRect.width = _width + 1;
				_sliceRect.height = _height + 1;
				_bd.fillRect(_sliceRect, _fillColor);
				
				if (_bitmapMode && _target != null) {
					this.filters = _target.filters;
					this.transform.colorTransform = _transform.colorTransform;
				} else {
					this.filters = _emptyArray;
					this.transform.colorTransform = _colorTransform;
				}
			}
			
			if (_bd == null) {
				return;
			} else if (_rows == 0) { //sometimes (especially in Flex) objects take a frame or two to render in Flash and properly report their width/height. Before that, their width/height is typically 0. This works around that issue and forces a refresh if we didn't capture any pixels last time we did a capture.
				_captureTargetBitmap();
			}
			
			var x:Number = super.x + xOffset;
			var y:Number = super.y + yOffset;
			
			
			var wrapWidth:int = (_bounds.width + _wrapOffsetX + 0.5) >> 0;
			var wrapHeight:int = (_bounds.height + _wrapOffsetY + 0.5) >> 0;
			var g:Graphics = this.graphics;
			
			if (_bounds.width == 0 || _bounds.height == 0 || (_wrap && (wrapWidth == 0 || wrapHeight == 0)) || (!_wrap && (x + _width < _bounds.x || y + _height < _bounds.y || x > _bounds.right || y > _bounds.bottom))) {
				g.clear();
				g.beginBitmapFill(_bd);
				g.drawRect(0, 0, _width, _height);
				g.endFill();
				return;
			}
			
			var column:int = int((x - _bounds.x) / _gridSize);
			if (column < 0) {
				column = 0;
			}
			var row:int = int((y - _bounds.y) / _gridSize);
			if (row < 0) {
				row = 0;
			}
			
			var maxColumn:int = int(((x + _width) - _bounds.x) / _gridSize);
			if (maxColumn >= _columns) {
				maxColumn = _columns - 1;
			}
			var maxRow:uint = int(((y + _height) - _bounds.y) / _gridSize);
			if (maxRow >= _rows) {
				maxRow = _rows - 1;
			}
			
			var xNudge:Number = (_bounds.x - x) % 1;
			var yNudge:Number = (_bounds.y - y) % 1;
			
			if (y <= _bounds.y) {
				_destPoint.y = (_bounds.y - y) >> 0;
				_sliceRect.y = -1; //subtract 1 to make sure the whole image gets included - without this, a very slight vibration can occur on the edge during animation.
				
			} else {
				_destPoint.y = 0;
				_sliceRect.y = Math.ceil(y - _bounds.y) - (row * _gridSize) - 1; //subtract 1 to make sure the whole image gets included - without this, a very slight vibration can occur on the edge during animation.
				if (clear && yNudge != 0) {
					yNudge += 1;
				}
				
			}
			if (x <= _bounds.x) {
				_destPoint.x = (_bounds.x - x) >> 0;
				_sliceRect.x = -1; //subtract 1 to make sure the whole image gets included - without this, a very slight vibration can occur on the edge during animation.
				
			} else {
				_destPoint.x = 0;
				_sliceRect.x = Math.ceil(x - _bounds.x) - (column * _gridSize) - 1; //subtract 1 to make sure the whole image gets included - without this, a very slight vibration can occur on the edge during animation.
				if (clear && xNudge != 0) {
					xNudge += 1;
				}
			}
			
			if (_wrap && clear) {
				//make sure to offset appropriately so that we start drawing directly on the image. We must use consistent xNudge and yNudge values across all the recursive calls too, otherwise the copies may vibrate visually a bit as they move
				_render(Math.ceil((_bounds.x - x) / wrapWidth) * wrapWidth, Math.ceil((_bounds.y - y) / wrapHeight) * wrapHeight, false, false);
			} else if (_rows != 0) {
				var xDestReset:Number = _destPoint.x;
				var xSliceReset:Number = _sliceRect.x;
				var columnReset:int = column;
				var bd:BitmapData;
				while (row <= maxRow) {
					bd = _grid[row][0];
					_sliceRect.height = bd.height - _sliceRect.y;
					_destPoint.x = xDestReset;
					_sliceRect.x = xSliceReset;
					column = columnReset;
					while (column <= maxColumn) {
						bd = _grid[row][column];
						_sliceRect.width = bd.width - _sliceRect.x;
						
						_bd.copyPixels(bd, _sliceRect, _destPoint);
						
						_destPoint.x += _sliceRect.width - 1;
						_sliceRect.x = 0;
						column++;
					}
					_destPoint.y += _sliceRect.height - 1;
					_sliceRect.y = 0;
					row++;
				}
				
			}
			
			if (clear) {
				_tempMatrix.tx = xNudge - 1; //subtract 1 to compensate for the pixel we added above.
				_tempMatrix.ty = yNudge - 1;
				g.clear();
				g.beginBitmapFill(_bd, _tempMatrix, false, _smoothing);
				g.drawRect(0, 0, _width, _height);
				g.endFill();
			} else if (_wrap) {
				//if needed, recursively call _render() and adjust the offset(s) to wrap the bitmap.
				if (x + _width > _bounds.right) {
					_render(xOffset - wrapWidth, yOffset, false, true);
				} 
				if (!limitRecursion && y + _height > _bounds.bottom) {
					_render(xOffset, yOffset - wrapHeight, false, false);
				}
			}
		}
		
		/** 
		 * Sets the width and height of the BlitMask. 
		 * Keep in mind that a BlitMask should not be rotated or scaled. 
		 * You can also directly set the <code>width</code> or <code>height</code> properties. 
		 * 
		 * @param width The width of the BlitMask
		 * @param height The height of the BlitMask
		 * @see #width
		 * @see #height
		 **/
		public function setSize(width:Number, height:Number):void {
			if (_width == width && _height == height) {
				return;
			} else if (width < 0 || height < 0) {
				throw new Error("A BlitMask cannot have a negative width or height.");
			} else if (_bd != null) {
				_bd.dispose();
			}
			_width = width;
			_height = height;
			_bd = new BitmapData(width + 1, height + 1, true, _fillColor);
			_render();
		}
		
		/** @private **/
		protected function _mouseEventPassthrough(event:MouseEvent):void {
			if (this.mouseEnabled && (!_bitmapMode || this.hitTestPoint(event.stageX, event.stageY, false))) {
				dispatchEvent(event);
			}
		}
		
		/**
		 * Identical to setting <code>bitmapMode = true</code> but this method simplifies adding that
		 * functionality to tweens or using it as an event handler. For example, to enable bitmapMode at
		 * the beginning of a tween and then disable it when the tween completes, you could do: <br /><br /><code>
		 * 
		 * TweenLite.to(mc, 3, {x:400, onStart:myBlitMask.enableBitmapMode, onUpdate:myBlitMask.update, onComplete:myBlitMask.disableBitmapMode});
		 * </code>
		 * 
		 * @param event An optional Event that isn't used internally but makes it possible to use the method as an event handler like <code>addEventListener(MouseEvent.CLICK, myBlitMask.enableBitmapMode)</code>.
		 * @see #disableBitmapMode()
		 * @see #bitmapMode
		 */
		public function enableBitmapMode(event:Event=null):void {
			this.bitmapMode = true;
		}
		
		/**
		 * Identical to setting <code>bitmapMode = false</code> but this method simplifies adding that
		 * functionality to tweens or using it as an event handler. For example, to enable bitmapMode at
		 * the beginning of a tween and then disable it when the tween completes, you could do: <br /><br /><code>
		 * 
		 * TweenLite.to(mc, 3, {x:400, onStart:myBlitMask.enableBitmapMode, onUpdate:myBlitMask.update, onComplete:myBlitMask.disableBitmapMode});
		 * </code>
		 * 
		 * @param event An optional Event that isn't used internally but makes it possible to use the method as an event handler like <code>addEventListener(MouseEvent.CLICK, myBlitMask.disableBitmapMode)</code>.
		 * @see #enableBitmapMode()
		 * @see #bitmapMode
		 */
		public function disableBitmapMode(event:Event=null):void {
			this.bitmapMode = false;
		}
		
		/**
		 * Repositions the <code>target</code> so that it is visible within the BlitMask, as though <code>wrap</code>
		 * was enabled (this method is called automatically when <code>bitmapMode</code> is disabled while <code>wrap</code> 
		 * is <code>true</code>). For example, if you tween the <code>target</code> way off the edge of the BlitMask and
		 * have <code>wrap</code> enabled, it will appear to come back in from the other side even though the raw coordinates
		 * of the target would indicate that it is outside the BlitMask. If you want to force the coordinates to normalize 
		 * so that they reflect that wrapped position, simply call <code>normalizePosition()</code>. It will automatically 
		 * choose the coordinates that would maximize the visible portion of the target if a seam is currently showing.
		 **/
		public function normalizePosition():void {
			if (_target && _bounds) {
				var wrapWidth:int = (_bounds.width + _wrapOffsetX + 0.5) >> 0;
				var wrapHeight:int = (_bounds.height + _wrapOffsetY + 0.5) >> 0;
				var offsetX:Number = (_bounds.x - this.x) % wrapWidth;
				var offsetY:Number = (_bounds.y - this.y) % wrapHeight;
				
				if (offsetX > (_width + _wrapOffsetX) / 2) {
					offsetX -= wrapWidth;
				} else if (offsetX < (_width + _wrapOffsetX) / -2) {
					offsetX += wrapWidth;
				}
				if (offsetY > (_height + _wrapOffsetY) / 2) {
					offsetY -= wrapHeight;
				} else if (offsetY < (_height + _wrapOffsetY) / -2) {
					offsetY += wrapHeight;
				}
				
				_target.x += this.x + offsetX - _bounds.x;
				_target.y += this.y + offsetY - _bounds.y;
			}
		}
		
		/** Disposes of the BlitMask and its internal BitmapData instances, releasing them for garbage collection. **/
		public function dispose():void {
			if (_bd == null) { //already disposed.
				return;
			}
			_disposeGrid();
			_bd.dispose();
			_bd = null;
			this.bitmapMode = false;
			this.autoUpdate = false;
			if (_target != null) {
				_target.mask = null;
			}
			if (this.parent != null) {
				this.parent.removeChild(this);
			}
			this.target = null;
		}
	
//---- GETTERS / SETTERS --------------------------------------------------------------------
		
		/** 
		 * When <code>true</code>, the BlitMask optimizes itself for performance by setting the <code>target's</code> 
		 * <code>visible</code> property to <code>false</code> (greatly reducing the load on Flash's graphics rendering 
		 * routines) and uses its internally cached bitmap version of the <code>target</code> to redraw only the necessary
		 * pixels inside the masked area. Since only a bitmap version of the <code>target</code> is shown while in bitmapMode,
		 * the <code>target</code> won't be interactive. So if you have buttons and other objects that normally react to 
		 * MouseEvents, they won't while in bitmapMode. If you need the interactivity, simply set <code>bitmapMode</code>
		 * to <code>false</code> and then it will turn the <code>target's</code> <code>visible</code> property back to <code>true</code>
		 * and its <code>mask</code> property to the BlitMask itself. Typically it is best to turn bitmapMode on at least when you're 
		 * animating the <code>target</code> or the BlitMask itself, and then when the tween/animation is done and you need 
		 * interactivity, set bitmapMode back to false. For example: <br /><br /><code>
		 * 
		 * var bm:BlitMask = new BlitMask(mc, 0, 0, 300, 200, true);<br /><br />
		 * 
		 * TweenLite.to(mc, 3, {x:200, onUpdate:bm.update, onComplete:completeHandler});<br /><br />
		 * 
		 * function completeHandler():void {<br />
		 *     bm.bitmapMode = false;<br />
		 * }<br />
		 * </code><br /><br />
		 * 
		 * @see #enableBitmapMode()
		 * @see #disableBitmapMode()
		 **/
		public function get bitmapMode():Boolean {
			return _bitmapMode;
		}
		public function set bitmapMode(value:Boolean):void {
			if (_bitmapMode != value) {
				_bitmapMode = value;
				if (_target != null) {
					_target.visible = !_bitmapMode;
					update(null);
					if (_bitmapMode) {
						this.filters = _target.filters;
						this.transform.colorTransform = _transform.colorTransform;
						this.blendMode = _target.blendMode;
						_target.mask = null;
					} else {
						this.filters = _emptyArray;
						this.transform.colorTransform = _colorTransform;
						this.blendMode = "normal";
						this.cacheAsBitmap = false; //if cacheAsBitmap is true on both the _target and the FlexBlitMask instance, the transparent areas of the mask will be...well...transparent which isn't what we want when bitmapMode is false (it could hide visible areas unless update(null, true) is called regularly, like if the target has animated children and bitmapMode is false)
						_target.mask = this;
						if (_wrap) {
							normalizePosition();
						}
					}
					if (_bitmapMode && _autoUpdate) {
						this.addEventListener(Event.ENTER_FRAME, update, false, -10, true);
					} else {
						this.removeEventListener(Event.ENTER_FRAME, update);
					}
				}
			}
		}
		
		/** 
		 * If <code>true</code>, the BlitMask will automatically watch the <code>target</code> to see if 
		 * its position/scale/rotation has changed on each frame (while <code>bitmapMode</code> is <code>true</code>) 
		 * and if so, it will <code>update()</code> to make sure the BlitMask always stays synced with the <code>target</code>. 
		 * This is the easiest way to use BlitMask but it is slightly less efficient than manually calling <code>update()</code> 
		 * whenever you need to. Keep in mind that if you're tweening with TweenLite or TweenMax, you can simply set 
		 * its <code>onUpdate</code> to the BlitMask's <code>update()</code> method to keep things synced. 
		 * Like <code>onUpdate:myBlitMask.update</code>. 
		 **/
		public function get autoUpdate():Boolean {
			return _autoUpdate;
		}
		public function set autoUpdate(value:Boolean):void {
			if (_autoUpdate != value) {
				_autoUpdate = value;
				if (_bitmapMode && _autoUpdate) {
					this.addEventListener(Event.ENTER_FRAME, update, false, -10, true);
				} else {
					this.removeEventListener(Event.ENTER_FRAME, update);
				}
			}
		}
		
		/** The target DisplayObject that the BlitMask should mask **/
		public function get target():DisplayObject {
			return _target;
		}
		public function set target(value:DisplayObject):void {
			if (_target != value) {
				var i:int = _mouseEvents.length;
				if (_target != null) {
					while (--i > -1) {
						_target.removeEventListener(_mouseEvents[i], _mouseEventPassthrough);
					}
				}
				_target = value;
				if (_target != null) {
					i = _mouseEvents.length;
					while (--i > -1) {
						_target.addEventListener(_mouseEvents[i], _mouseEventPassthrough, false, 0, true);
					}
					_prevMatrix = null;
					_transform = _target.transform;
					_bitmapMode = !_bitmapMode; 
					this.bitmapMode = !_bitmapMode; //forces a refresh (applying the mask, doing an update(), etc.)
				} else {
					_bounds = new Rectangle();
				}
			}
		}
		
		/** x coordinate of the BlitMask (it will automatically be forced to whole pixel values if <code>smoothing</code> is <code>false</code>). **/
		override public function get x():Number {
			return super.x;
		}
		override public function set x(value:Number):void {
			if (_smoothing) {
				super.x = value;
			} else if (value >= 0) {
				super.x = (value + 0.5) >> 0;
			} else {
				super.x = (value - 0.5) >> 0;
			}
			if (_bitmapMode) {
				_render();
			}
		}
		
		/** y coordinate of the BlitMask (it will automatically be forced to whole pixel values if <code>smoothing</code> is <code>false</code>). **/
		override public function get y():Number {
			return super.y;
		}
		override public function set y(value:Number):void {
			if (_smoothing) {
				super.y = value;
			} else if (value >= 0) {
				super.y = (value + 0.5) >> 0;
			} else {
				super.y = (value - 0.5) >> 0;
			}
			if (_bitmapMode) {
				_render();
			}
		}
		
		/** Width of the BlitMask **/
		override public function get width():Number {
			return _width;
		}
		override public function set width(value:Number):void {
			setSize(value, _height);
		}
		
		/** Height of the BlitMask **/
		override public function get height():Number {
			return _height;
		}
		override public function set height(value:Number):void {
			setSize(_width, value);
		}
		
		/** scaleX (warning: altering the scaleX won't actually change its value - instead, it affects the <code>width</code> property accordingly) **/
		override public function get scaleX():Number {
			return 1;
		}
		override public function set scaleX(value:Number):void {
			var oldScaleX:Number = _scaleX;
			_scaleX = value;
			setSize(_width * (_scaleX / oldScaleX), _height);
		}
		
		/** scaleY (warning: altering the scaleY won't actually change its value - instead, it affects the <code>height</code> property accordingly) **/
		override public function get scaleY():Number {
			return 1;
		}
		override public function set scaleY(value:Number):void {
			var oldScaleY:Number = _scaleY;
			_scaleY = value;
			setSize(_width, _height * (_scaleY / oldScaleY));
		}
		
		/** Rotation of the BlitMask (always 0 because BlitMasks can't be rotated!) **/
		override public function set rotation(value:Number):void {
			if (value != 0) {
				throw new Error("Cannot set the rotation of a BlitMask to a non-zero number. BlitMasks should remain unrotated.");
			}
		}
		
		/** 
		 * Typically a value between 0 and 1 indicating the <code>target's</code> position in relation to the BlitMask 
		 * on the x-axis where 0 is at the beginning, 0.5 is scrolled to exactly the halfway point, and 1 is scrolled 
		 * all the way. This makes it very easy to animate the scroll. For example, to scroll from beginning to end 
		 * over 5 seconds, you could do: <br /><br /><code>
		 * 
		 * myBlitMask.scrollX = 0; <br />
		 * TweenLite.to(myBlitMask, 5, {scrollX:1});
		 * </code>
		 * @see #scrollY
		 **/
		public function get scrollX():Number {
			return (super.x - _bounds.x) / (_bounds.width - _width);
		}
		public function set scrollX(value:Number):void {
			if (_target != null && _target.parent) {
				_bounds = _target.getBounds(_target.parent);
				var dif:Number;
				dif = (super.x - (_bounds.width - _width) * value) - _bounds.x;
				_target.x += dif;
				_bounds.x += dif;
				if (_bitmapMode) {
					_render();
				}
			}
		}
		
		/** 
		 * Typically a value between 0 and 1 indicating the <code>target's</code> position in relation to the BlitMask 
		 * on the y-axis where 0 is at the beginning, 0.5 is scrolled to exactly the halfway point, and 1 is scrolled 
		 * all the way. This makes it very easy to animate the scroll. For example, to scroll from beginning to end 
		 * over 5 seconds, you could do: <br /><br /><code>
		 * 
		 * myBlitMask.scrollY = 0; <br />
		 * TweenLite.to(myBlitMask, 5, {scrollY:1});
		 * </code>
		 * @see #scrollX
		 **/
		public function get scrollY():Number {
			return (super.y - _bounds.y) / (_bounds.height - _height);
		}
		public function set scrollY(value:Number):void {
			if (_target != null && _target.parent) {
				_bounds = _target.getBounds(_target.parent);
				var dif:Number = (super.y - (_bounds.height - _height) * value) - _bounds.y;
				_target.y += dif;
				_bounds.y += dif;
				if (_bitmapMode) {
					_render();
				}
			}
		}
		
		/** 
		 * If <code>false</code> (the default), the bitmap (and the BlitMask's x/y coordinates) 
		 * will be rendered only on whole pixels which is faster in terms of processing. However, 
		 * for the best quality and smoothest animation, set <code>smoothing</code> to <code>true</code>. 
		 **/
		public function get smoothing():Boolean {
			return _smoothing;
		}
		public function set smoothing(value:Boolean):void {
			if (_smoothing != value) {
				_smoothing = value;
				_captureTargetBitmap();
				if (_bitmapMode) {
					_render();
				}
			}
		}
		
		/** 
		 * The ARGB hexadecimal color that should fill the empty areas of the BlitMask. By default, 
		 * it is transparent (0x00000000). If you wanted a red color, for example, it would be 
		 * <code>0xFFFF0000</code>. 
		 **/
		public function get fillColor():uint {
			return _fillColor;
		}
		public function set fillColor(value:uint):void {
			if (_fillColor != value) {
				_fillColor = value;
				if (_bitmapMode) {
					_render();
				}
			}
		}
		
		/** 
		 * If <code>true</code>, the bitmap will be wrapped around to the opposite side when it scrolls off 
		 * one of the edges (only in <code>bitmapMode</code> of course), like the BlitMask is filled with a 
		 * grid of bitmap copies of the target. Use the <code>wrapOffsetX</code> and <code>wrapOffsetY</code> 
		 * properties to affect how far apart the copies are from each other. You can reposition the 
		 * <code>target</code> anywhere and BlitMask will align the copies accordingly.
		 * @see #wrapOffsetX
		 * @see #wrapOffsetY
		 **/
		public function get wrap():Boolean {
			return _wrap;
		}
		public function set wrap(value:Boolean):void {
			if (_wrap != value) {
				_wrap = value;
				if (_bitmapMode) {
					_render();
				}
			}
		}
		
		/** 
		 * When <code>wrap</code> is <code>true</code>, <code>wrapOffsetX</code> controls how many pixels
		 * along the x-axis the wrapped copies of the bitmap are spaced. It is essentially the gap between
		 * the copies (although you can use a negative value or 0 to avoid any gap). 
		 * @see #wrap
		 * @see #wrapOffsetY
		 **/
		public function get wrapOffsetX():Number {
			return _wrapOffsetX;
		}
		public function set wrapOffsetX(value:Number):void {
			if (_wrapOffsetX != value) {
				_wrapOffsetX = value;
				if (_bitmapMode) {
					_render();
				}
			}
		}
		
		/** 
		 * When <code>wrap</code> is <code>true</code>, <code>wrapOffsetY</code> controls how many pixels
		 * along the y-axis the wrapped copies of the bitmap are spaced. It is essentially the gap between
		 * the copies (although you can use a negative value or 0 to avoid any gap). 
		 * @see #wrap
		 * @see #wrapOffsetX
		 **/
		public function get wrapOffsetY():Number {
			return _wrapOffsetY;
		}
		public function set wrapOffsetY(value:Number):void {
			if (_wrapOffsetY != value) {
				_wrapOffsetY = value;
				if (_bitmapMode) {
					_render();
				}
			}
		}
	
	}
}