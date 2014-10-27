/**
 * VERSION: 2.54
 * DATE: 2011-04-26
 * AS3
 * UPDATES AND DOCS AT: http://www.greensock.com/autofitarea/
 **/
package com.greensock.layout {
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
/**
 * AutoFitArea allows you to define a rectangular area and then <code>attach()</code> DisplayObjects 
 * so that they automatically fill the area, scaling/stretching in any of the following modes: <code>STRETCH, 
 * PROPORTIONAL_INSIDE, PROPORTIONAL_OUTSIDE, NONE, WIDTH_ONLY,</code> or <code>HEIGHT_ONLY</code>. Horizontally 
 * align the attached DisplayObjects left, center, or right. Vertically align them top, center, or bottom.
 * AutoFitArea extends the <code>Shape</code> class, so you can alter the width/height/scaleX/scaleY/x/y 
 * properties of the AutoFitArea and then all of the attached objects will automatically be affected. 
 * Attach as many DisplayObjects as you want. To make visualization easy, you can set the <code>previewColor</code>
 * to any color and set the <code>preview</code> property to true in order to see the area on the stage
 * (or simply use it like a regular Shape by adding it to the display list with <code>addChild()</code>, but the 
 * <code>preview</code> property makes it simpler because it automatically ensures that it is behind 
 * all of its attached DisplayObjects in the stacking order).
 * <br /><br />
 * 
 * When you <code>attach()</code> a DisplayObject, you can define a minimum and maximum width and height.
 * AutoFitArea doesn't require that the DisplayObject's registration point be in its upper left corner
 * either. You can even set the <code>calculateVisible</code> parameter to true when attaching an object
 * so that AutoFitArea will ignore masked areas inside the DisplayObject (this is more processor-intensive, 
 * so beware).<br /><br />
 * 
 * For scaling, AutoFitArea alters the DisplayObject's <code>width</code> and/or <code>height</code>
 * properties unless it is rotated in which case it alters the DisplayObject's <code>transform.matrix</code> 
 * directly so that accurate stretching/skewing can be accomplished. <br /><br />
 * 
 * There is also a <code>LiquidArea</code> class that extends AutoFitArea and integrates with 
 * <a href="http://www.greensock.com/liquidstage/">LiquidStage</a> so that it automatically 
 * adjusts its size whenever the stage is resized. This makes it simple to create things like 
 * a background that proportionally fills the stage or a bar that always stretches horizontally 
 * to fill the stage but stays stuck to the bottom, etc.<br /><br />
 *	
 * @example Example AS3 code:<listing version="3.0">
import com.greensock.layout.~~;

//create a 300x100 rectangular area at x:50, y:70 that stretches when the stage resizes (as though its top left and bottom right corners are pinned to their corresponding PinPoints on the stage)
var area:AutoFitArea = new AutoFitArea(this, 50, 70, 300, 100);

//attach a "myImage" Sprite to the area and set its ScaleMode to PROPORTIONAL_OUTSIDE and crops the extra content that spills over the edges
area.attach(myImage, {scaleMode:ScaleMode.PROPORTIONAL_OUTSIDE, crop:true});

//if you'd like to preview the area visually, set preview to true (by default previewColor is red)
area.preview = true;
 
//attach a CHANGE event listener to the area
area.addEventListener(Event.CHANGE, onAreaUpdate);
function onAreaUpdate(event:Event):void {
	trace("updated AutoFitArea");
}

//to create an AutoFitArea exactly around a "myImage" DisplayObject so that it conforms its initial dimensions around the DisplayObject, use the static createAround() method:
var area:AutoFitArea = AutoFitArea.createAround(myImage);

</listing>
 *
 * 
 * <b>Copyright 2011, GreenSock. All rights reserved.</b> This work is subject to the license that came with your Club GreenSock membership and is <b>ONLY</b> to be used by corporate or "Shockingly Green" Club GreenSock members. To learn more about Club GreenSock, visit <a href="http://www.greensock.com/club/">http://www.greensock.com/club/</a>.
 * 
 * @author Jack Doyle, jack@greensock.com
 */	 
	public class AutoFitArea extends Shape {
		/** @private **/
		public static const version:Number = 2.54;
		
		/** @private **/
		private static var _bd:BitmapData;
		/** @private **/
		private static var _rect:Rectangle = new Rectangle(0, 0, 2800, 2800);
		/** @private **/
		private static var _matrix:Matrix = new Matrix();
		
		/** @private **/
		protected var _parent:DisplayObjectContainer;
		/** @private **/
		protected var _previewColor:uint;
		/** @private **/
		protected var _rootItem:AutoFitItem;
		/** @private **/
		protected var _hasListener:Boolean;
		/** @private **/
		protected var _preview:Boolean;
		/** @private **/
		protected var _tweenMode:Boolean;
		/** @private **/
		protected var _width:Number;
		/** @private **/
		protected var _height:Number;
		
		/**
		 * Constructor
		 * 
		 * @param parent The parent DisplayObjectContainer in which the AutoFitArea should be created. All objects that get attached must share the same parent.
		 * @param x x coordinate of the AutoFitArea's upper left corner
		 * @param y y coordinate of the AutoFitArea's upper left corner
		 * @param width width of the AutoFitArea
		 * @param height height of the AutoFitArea
		 * @param previewColor color of the AutoFitArea (which won't be seen unless you set preview to true or manually add it to the display list with addChild())
		 */
		public function AutoFitArea(parent:DisplayObjectContainer, x:Number=0, y:Number=0, width:Number=100, height:Number=100, previewColor:uint=0xFF0000) {
			super();
			super.x = x;
			super.y = y;
			if (parent == null) {
				throw new Error("AutoFitArea parent cannot be null");
			}
			_parent = parent;
			_width = width;
			_height = height;
			_redraw(previewColor);
		}
		
		/**
		 * Creates an AutoFitArea with its initial dimensions fit precisely around a target DisplayObject. It also attaches
		 * the target DisplayObject immediately.
		 * 
		 * @param target The target DisplayObject whose position and dimensions the AutoFitArea should match initially.
		 * @param vars An object used for defining various optional parameters (see below for list) - this is more readable and concise than defining 11 or more normal arguments. 
		 * 			   For example, <code>createAround(mc, {scaleMode:"proportionalOutside", crop:true});</code> instead of <code>createAround(mc, "proportionalOutside", "center", "center", true, 0, 99999999, 0, 99999999, false, NaN, false);</code>.
		 * 			   The following optional parameters are recognized:
		 * 				<ul>
		 * 					<li><b>scaleMode : String</b> - Determines how the target should be scaled to fit the area. Use the ScaleMode class constants: <code>STRETCH, PROPORTIONAL_INSIDE, PROPORTIONAL_OUTSIDE, NONE, WIDTH_ONLY,</code> or <code>HEIGHT_ONLY</code></li>
		 * 					<li><b>hAlign : String</b> - Horizontal alignment of the target inside the area. Use the AlignMode class constants: <code>LEFT</code>, <code>CENTER</code>, and <code>RIGHT</code>.</li>
		 * 					<li><b>vAlign : String</b> - Vertical alignment of the target inside the area. Use the AlignMode class constants: <code>TOP</code>, <code>CENTER</code>, and <code>BOTTOM</code>.</li>
		 * 					<li><b>crop : Boolean</b> - If true, a mask will be created and added to the display list so that the target will be cropped wherever it exceeds the bounds of the AutoFitArea.</li>
		 * 					<li><b>roundPosition : Boolean</b> - To force the target's x/y position to snap to whole pixel values, set <code>roundPosition</code> to <code>true</code> (it is <code>false</code> by default).</li>
		 * 					<li><b>customBoundsTarget : DisplayObject</b> - A DisplayObject that AutoFitArea/LiquidArea should use when measuring bounds instead of the <code>target</code>. For example, maybe the target contains 3 boxes arranged next to each other, left-to-right and instead of fitting ALL of those boxes into the area, you only want the center one fit into the area. In this case, you can define the customBoundsTarget as that center box so that the AutoFitArea/LiquidArea only uses it when calculating bounds. Make sure that the object is in the display list (its <code>visible</code> property can be set to false if you want to use an invisible object to define custom bounds).</li>
		 * 					<li><b>minWidth : Number</b> - Minimum width to which the target is allowed to scale</li>
		 * 					<li><b>maxWidth : Number</b> - Maximum width to which the target is allowed to scale</li>
		 * 					<li><b>minHeight : Number</b> - Minimum height to which the target is allowed to scale</li>
		 * 					<li><b>maxHeight : Number</b> - Maximum height to which the target is allowed to scale</li>
		 * 					<li><b>calculateVisible : Boolean</b> - If true, only the visible portions of the target will be taken into account when determining its position and scale which can be useful for objects that have masks applied (otherwise, Flash reports their width/height and getBounds() values including the masked portions). Setting <code>calculateVisible</code> to <code>true</code> degrades performance, so only use it when absolutely necessary.</li>
		 * 					<li><b>customAspectRatio : Number</b> - Normally if you set the <code>scaleMode</code> to <code>PROPORTIONAL_INSIDE</code> or <code>PROPORTIONAL_OUTSIDE</code>, its native (unscaled) dimensions will be used to determine the proportions (aspect ratio), but if you prefer to define a custom width-to-height ratio, use <code>customAspectRatio</code>. For example, if an item is 100 pixels wide and 50 pixels tall at its native size, the aspect ratio would be 100/50 or 2. If, however, you want it to be square (a 1-to-1 ratio), the <code>customAspectRatio</code> would be 1. </li>
		 * 					<li><b>previewColor : uint</b> - The preview color of the AutoFitArea (default is 0xFF0000). To preview, you must set the AutoFitArea's <code>visible</code> property to true (it is false by default).</li>
		 * 				</ul>
		 * @return An AutoFitArea instance
		 */
		public static function createAround(target:DisplayObject, vars:Object=null, ...args):AutoFitArea {
			if (vars == null || typeof(vars) == "string") {
				//sensed old method - parse the params for backwards compatibility
				vars = {scaleMode:vars || "proportionalInside",
						hAlign:args[0] || "center",
						vAlign:args[1] || "center",
						crop:Boolean(args[2]),
						minWidth:args[3] || 0,
						maxWidth:(isNaN(args[4]) ? 999999999 : args[4]),
						minHeight:args[5] || 0,
						maxHeight:(isNaN(args[6]) ? 999999999 : args[6]),
						calculateVisible:Boolean(args[8])};
			}
			var boundsTarget:DisplayObject = (vars.customBoundsTarget is DisplayObject) ? vars.customBoundsTarget : target;
			var previewColor:uint = isNaN(args[7]) ? (("previewColor" in vars) ? uint(vars.previewColor) : 0xFF0000) : args[7];
			var bounds:Rectangle = (vars.calculateVisible == true) ? getVisibleBounds(boundsTarget, target.parent) : boundsTarget.getBounds(target.parent);
			var afa:AutoFitArea = new AutoFitArea(target.parent, bounds.x, bounds.y, bounds.width, bounds.height, previewColor);
			afa.attach(target, vars);
			return afa;
		}
		
		/**
		 * Attaches a DisplayObject, causing it to automatically scale to fit the area in one of the
		 * following ScaleModes: <code>STRETCH, PROPORTIONAL_INSIDE, PROPORTIONAL_OUTSIDE, NONE, WIDTH_ONLY,</code> 
		 * or <code>HEIGHT_ONLY</code>. Horizontally and vertically align the object within the area as well.
		 * When the area resizes, all attached DisplayObjects will automatically be moved/scaled accordingly.
		 * 
		 * @param target The DisplayObject to attach and scale/stretch to fit within the area.
		 * @param vars An object used for defining various optional parameters (see below for list) - this is more readable and concise than defining 11 or more normal arguments. 
		 * 			   For example, <code>attach(mc, {scaleMode:"proportionalOutside", crop:true});</code> instead of <code>attach(mc, "proportionalOutside", "center", "center", true, 0, 99999999, 0, 99999999, false, NaN, false);</code>.
		 * 			   The following optional parameters are recognized:
		 * 				<ul>
		 * 					<li><b>scaleMode : String</b> - Determines how the target should be scaled to fit the area. Use the ScaleMode class constants: <code>STRETCH, PROPORTIONAL_INSIDE, PROPORTIONAL_OUTSIDE, NONE, WIDTH_ONLY,</code> or <code>HEIGHT_ONLY</code></li>
		 * 					<li><b>hAlign : String</b> - Horizontal alignment of the target inside the area. Use the AlignMode class constants: <code>LEFT</code>, <code>CENTER</code>, and <code>RIGHT</code>.</li>
		 * 					<li><b>vAlign : String</b> - Vertical alignment of the target inside the area. Use the AlignMode class constants: <code>TOP</code>, <code>CENTER</code>, and <code>BOTTOM</code>.</li>
		 * 					<li><b>crop : Boolean</b> - If true, a mask will be created and added to the display list so that the target will be cropped wherever it exceeds the bounds of the AutoFitArea.</li>
		 * 					<li><b>roundPosition : Boolean</b> - To force the target's x/y position to snap to whole pixel values, set <code>roundPosition</code> to <code>true</code> (it is <code>false</code> by default).</li>
		 * 					<li><b>customBoundsTarget : DisplayObject</b> - A DisplayObject that AutoFitArea/LiquidArea should use when measuring bounds instead of the <code>target</code>. For example, maybe the target contains 3 boxes arranged next to each other, left-to-right and instead of fitting ALL of those boxes into the area, you only want the center one fit into the area. In this case, you can define the customBoundsTarget as that center box so that the AutoFitArea/LiquidArea only uses it when calculating bounds. Make sure that the object is in the display list (its <code>visible</code> property can be set to false if you want to use an invisible object to define custom bounds).</li>
		 * 					<li><b>minWidth : Number</b> - Minimum width to which the target is allowed to scale</li>
		 * 					<li><b>maxWidth : Number</b> - Maximum width to which the target is allowed to scale</li>
		 * 					<li><b>minHeight : Number</b> - Minimum height to which the target is allowed to scale</li>
		 * 					<li><b>maxHeight : Number</b> - Maximum height to which the target is allowed to scale</li>
		 * 					<li><b>calculateVisible : Boolean</b> - If true, only the visible portions of the target will be taken into account when determining its position and scale which can be useful for objects that have masks applied (otherwise, Flash reports their width/height and getBounds() values including the masked portions). Setting <code>calculateVisible</code> to <code>true</code> degrades performance, so only use it when absolutely necessary.</li>
		 * 					<li><b>customAspectRatio : Number</b> - Normally if you set the <code>scaleMode</code> to <code>PROPORTIONAL_INSIDE</code> or <code>PROPORTIONAL_OUTSIDE</code>, its native (unscaled) dimensions will be used to determine the proportions (aspect ratio), but if you prefer to define a custom width-to-height ratio, use <code>customAspectRatio</code>. For example, if an item is 100 pixels wide and 50 pixels tall at its native size, the aspect ratio would be 100/50 or 2. If, however, you want it to be square (a 1-to-1 ratio), the <code>customAspectRatio</code> would be 1. </li>
		 * 				</ul>
		 */
		public function attach(target:DisplayObject, vars:Object=null, ...args):void { 
			if (target.parent != _parent) {
				throw new Error("The parent of the DisplayObject " + target.name + " added to AutoFitArea " + this.name + " doesn't share the same parent.");
			}
			if (vars == null || typeof(vars) == "string") {
				//sensed old method - parse the params for backwards compatibility
				vars = {scaleMode:vars || "proportionalInside",
						hAlign:args[0] || "center",
						vAlign:args[1] || "center",
						crop:Boolean(args[2]),
						minWidth:args[3] || 0,
						maxWidth:(isNaN(args[4]) ? 999999999 : args[4]),
						minHeight:args[5] || 0,
						maxHeight:(isNaN(args[6]) ? 999999999 : args[6]),
						calculateVisible:Boolean(args[7]),
						customAspectRatio:Number(args[8]),
						roundPosition:Boolean(args[9])};
			}
			
			release(target);
			_rootItem = new AutoFitItem(target, vars, _rootItem);
			if (vars != null && vars.crop == true) {
				var shape:Shape = new Shape();
				var bounds:Rectangle = this.getBounds(this);
				shape.graphics.beginFill(_previewColor, 1);
				shape.graphics.drawRect(bounds.x, bounds.y, bounds.width, bounds.height);
				shape.graphics.endFill();
				shape.visible = false;
				_parent.addChild(shape);
				_rootItem.mask = shape;
				target.mask = shape;
			}
			if (_preview) {
				this.preview = true;
			}
			update(null);
		}
		
		/**
		 * Releases control of an attached DisplayObject.
		 * 
		 * @param target The DisplayObject to release
		 * @return if the target was found and released, this value will be true. If the target isn't attached, it will be false.
		 */
		public function release(target:DisplayObject):Boolean {
			var item:AutoFitItem = getItem(target);
			if (item == null) {
				return false;
			}
			if (item.mask != null) {
				if (item.mask.parent) {
					item.mask.parent.removeChild(item.mask);
				}
				target.mask = null;
				item.mask = null;
			}
			if (item.next) {
				item.next.prev = item.prev;
			}
			if (item.prev) {
				item.prev.next = item.next;
			} else if (item == _rootItem) {
				_rootItem = item.next;
			}
			item.next = item.prev = null;
			item.boundsTarget = null;
			item.target = null;
			return true;
		}
		
		/**
		 * Returns an Array of all attached DisplayObjects.
		 * 
		 * @return An array of all attached objects
		 */
		public function getAttachedObjects():Array {
			var a:Array = [];
			var cnt:uint = 0;
			var item:AutoFitItem = _rootItem;
			while (item) {
				a[cnt++] = item.target;
				item = item.next;
			}
			return a;
		}
		
		/** @private **/
		protected function getItem(target:DisplayObject):AutoFitItem {
			var item:AutoFitItem = _rootItem;
			while (item) {
				if (item.target == target) {
					return item;
				}
				item = item.next;
			}
			return null;
		}
		
		
		/** 
		 * Forces the area to update, making any necessary adjustments to the scale/position of attached objects. 
		 * @param event An optional event (which is unused internally) - this makes it possible to have an ENTER_FRAME or some other listener call this method if, for example, you want the AutoFitArea to constantly update and make any adjustments to attached objects that may have resized or been manually moved.
		 **/
		public function update(event:Event=null):void {
			//create local variables to speed things up
			var width:Number = this.width;
			var height:Number = this.height;
			var x:Number = this.x;
			var y:Number = this.y;
			var matrix:Matrix = this.transform.matrix;
			
			var item:AutoFitItem = _rootItem;
			var w:Number, h:Number, tx:Number, ty:Number, target:DisplayObject, innerBounds:Rectangle, outerBounds:Rectangle, tRatio:Number, scaleMode:String, ratio:Number, angle:Number, sin:Number, cos:Number, m:Matrix, wScale:Number, hScale:Number, mPrev:Matrix;
			while (item) {
				target = item.target;
				scaleMode = item.scaleMode;
				
				if (scaleMode != ScaleMode.NONE) {
					
					//if the width or height is zero, we cannot effectively scale using multiplication/division, so make sure that the target is at least 1 pixel tall/wide before proceeding. Remember, it'll get adjusted back to what it should be later.
					if (scaleMode != ScaleMode.HEIGHT_ONLY && target.width == 0) {
						target.width = 1; 
					} 
					if (scaleMode != ScaleMode.WIDTH_ONLY && target.height == 0) {
						target.height = 1;
					}
					
					if (item.calculateVisible) {
						innerBounds = item.bounds = getVisibleBounds(item.boundsTarget, target);
						outerBounds = getVisibleBounds(item.boundsTarget, _parent);
					} else {
						innerBounds = item.boundsTarget.getBounds(target);
						outerBounds =  item.boundsTarget.getBounds(_parent);
					}
					tRatio = (item.hasCustomRatio) ? item.aspectRatio : innerBounds.width / innerBounds.height;
					
					m = target.transform.matrix;
					if (m.b != 0 || m.a == 0 || m.d == 0) {
						//if the width/height is zero, we cannot accurately measure the angle.
						if (m.a == 0 || m.d == 0) {
							m = target.transform.matrix = item.matrix;
						} else {
							//inline operations are about 10 times faster than doing item.matrix = m.clone();
							mPrev = item.matrix;
							mPrev.a = m.a;
							mPrev.b = m.b;
							mPrev.c = m.c;
							mPrev.d = m.d;
							mPrev.tx = m.tx;
							mPrev.ty = m.ty;
						}
						angle = Math.atan2(m.b, m.a);
						if (m.a < 0 && m.d >= 0) {
							if (angle <= 0) {
								angle += Math.PI;
							} else {
								angle -= Math.PI;
							}
						}
						sin = Math.sin(angle);
						if (sin < 0) {
							sin = -sin;
						}
						cos = Math.cos(angle);
						if (cos < 0) {
							cos = -cos;
						}
						tRatio = (tRatio * cos + sin) / (tRatio * sin + cos);
					}
					
					w = (width > item.maxWidth) ? item.maxWidth : (width < item.minWidth) ? item.minWidth : width;
					h = (height > item.maxHeight) ? item.maxHeight : (height < item.minHeight) ? item.minHeight : height;
					ratio = w / h;
					
					if ((tRatio < ratio && scaleMode == ScaleMode.PROPORTIONAL_INSIDE) || (tRatio > ratio && scaleMode == ScaleMode.PROPORTIONAL_OUTSIDE)) {
						w = h * tRatio;
						if (w == 0) {
							h = 0;
						} else if (w > item.maxWidth) {
							w = item.maxWidth;
							h = w / tRatio;
						} else if (w < item.minWidth) {
							w = item.minWidth;
							h = w / tRatio;
						}
					}
					if ((tRatio > ratio && scaleMode == ScaleMode.PROPORTIONAL_INSIDE) || (tRatio < ratio && scaleMode == ScaleMode.PROPORTIONAL_OUTSIDE)) {
						h = w / tRatio;
						if (h > item.maxHeight) {
							h = item.maxHeight;
							w = h * tRatio;
						} else if (h < item.minHeight) {
							h = item.minHeight;
							w = h * tRatio;
						}
					}
					
					if (w != 0 && h != 0) {
						wScale = w / outerBounds.width;
						hScale = h / outerBounds.height;
					} else {
						wScale = hScale = 0;
					}
					
					if (scaleMode != ScaleMode.HEIGHT_ONLY) {
						if (item.calculateVisible) {
							item.scaleVisibleWidth(wScale);
						} else if (m.b != 0) {
							m.a *= wScale;
							m.c *= wScale;
							target.transform.matrix = m;
						} else {
							target.width *= wScale;
						}
					}
					if (scaleMode != ScaleMode.WIDTH_ONLY) {
						if (item.calculateVisible) {
							item.scaleVisibleHeight(hScale);
						} else if (m.b != 0) {
							m.d *= hScale;
							m.b *= hScale;
							target.transform.matrix = m;
						} else {
							target.height *= hScale;
						}
					}
					
				}
				
				if (item.hasDrawNow) { //some components incorrectly report getBounds() until after we drawNow()
					Object(target).drawNow();
				}
				
				if (scaleMode != ScaleMode.NONE && innerBounds.x == 0 && innerBounds.y == 0) { //for optimization
					if (scaleMode != ScaleMode.HEIGHT_ONLY) {
						outerBounds.width = w;
					}
					if (scaleMode != ScaleMode.WIDTH_ONLY) {
						outerBounds.height = h;
					}
				} else {
					outerBounds = (item.calculateVisible) ? getVisibleBounds(item.boundsTarget, _parent) : item.boundsTarget.getBounds(_parent);
				}
				
				tx = target.x;
				ty = target.y;
				if (item.hAlign == AlignMode.LEFT) {
					tx += (x - outerBounds.x);
				} else if (item.hAlign == AlignMode.CENTER) {
					tx += (x - outerBounds.x) + ((width - outerBounds.width) * 0.5);
				} else if (item.hAlign == AlignMode.RIGHT) {
					tx += (x - outerBounds.x) + (width - outerBounds.width);
				}
				
				if (item.vAlign == AlignMode.TOP) {
					ty += (y - outerBounds.y);
				} else if (item.vAlign == AlignMode.CENTER) {
					ty += (y - outerBounds.y) + ((height - outerBounds.height) * 0.5);
				} else if (item.vAlign == AlignMode.BOTTOM) {
					ty += (y - outerBounds.y) + (height - outerBounds.height);
				}
				
				if (item.roundPosition) {
					tx = (tx + 0.5) >> 0; //much faster than Math.round()
					ty = (ty + 0.5) >> 0;
				}
				
				target.x = tx;
				target.y = ty;
				
				if (item.mask) {
					item.mask.transform.matrix = matrix;
				}
				
				item = item.next;
			}
			
			if (_hasListener) {
				dispatchEvent(new Event(Event.CHANGE));
			}
		}
		
		/** 
		 * Enables the area's tween mode; normally, any changes to the area's transform properties like 
		 * <code>x, y, scaleX, scaleY, width,</code> or <code>height</code> will force an immediate 
		 * <code>update()</code> call but when the area is in tween mode, that automatic <code>update()</code> 
		 * is suspended. This effects perfomance because if, for example, you tween the area's <code>x, y, width</code>, 
		 * and <code>height</code> properties simultaneously, <code>update()</code> would get called 4 times 
		 * each frame (once for each property) even though it only really needs to be called once after all 
		 * properties were updated inside the tween. So to maximize performance during a tween, it is best 
		 * to use the tween's <code>onStart</code> to call <code>enableTweenMode()</code> at the beginning 
		 * of the tween, use the tween's <code>onUpdate</code> to call the area's <code>update()</code> method, 
		 * and then the tween's <code>onComplete</code> to call <code>disableTweenMode()</code> like so:<br /><br /><code>
		 * 
		 * TweenLite.to(myArea, 3, {x:100, y:50, width:300, height:250, onStart:myArea.enableTweenMode, onUpdate:myArea.update, onComplete:myArea.disableTweenMode});</code>
		 **/
		public function enableTweenMode():void {
			_tweenMode = true;
		}
		
		/** 
		 * Disables the area's tween mode; normally, any changes to the area's transform properties like 
		 * <code>x, y, scaleX, scaleY, width,</code> or <code>height</code> will force an immediate 
		 * <code>update()</code> call but when the area is in tween mode, that automatic <code>update()</code> 
		 * is suspended. This effects perfomance because if, for example, you tween the area's <code>x, y, width</code>, 
		 * and <code>height</code> properties simultaneously, <code>update()</code> would get called 4 times 
		 * each frame (once for each property) even though it only really needs to be called once after all 
		 * properties were updated inside the tween. So to maximize performance during a tween, it is best 
		 * to use the tween's <code>onStart</code> to call <code>enableTweenMode()</code> at the beginning 
		 * of the tween, use the tween's <code>onUpdate</code> to call the area's <code>update()</code> method, 
		 * and then the tween's <code>onComplete</code> to call <code>disableTweenMode()</code> like so:<br /><br /><code>
		 * 
		 * TweenLite.to(myArea, 3, {x:100, y:50, width:300, height:250, onStart:myArea.enableTweenMode, onUpdate:myArea.update, onComplete:myArea.disableTweenMode});</code>
		 **/
		public function disableTweenMode():void {
			_tweenMode = false;
		}
		
		/**
		 * Allows you to add an <code>Event.CHANGE</code> event listener.
		 *  
		 * @param type Event type (<code>Event.CHANGE</code>)
		 * @param listener Listener function
		 * @param useCapture useCapture
		 * @param priority Priority level
		 * @param useWeakReference Use weak references
		 */
		override public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false):void {
			_hasListener = true;
			super.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		/** Destroys the instance by releasing all DisplayObjects, setting preview to false, and nulling references to the parent, ensuring that garbage collection isn't hindered. **/
		public function destroy():void {
			if (_preview) {
				this.preview = false;
			}
			var nxt:AutoFitItem;
			var item:AutoFitItem = _rootItem;
			while (item) {
				nxt = item.next;
				release(item.target);
				item = nxt;
			}
			if (_bd != null) {
				_bd.dispose();
				_bd = null;
			}
			_parent = null;
		}
		
		/** @private For objects with masks, the only way to accurately report the bounds of the visible areas is to use BitmapData. **/
		protected static function getVisibleBounds(target:DisplayObject, targetCoordinateSpace:DisplayObject):Rectangle {
			if (_bd == null) {
				_bd = new BitmapData(2800, 2800, true, 0x00FFFFFF);
			}
			var msk:DisplayObject = target.mask;
			target.mask = null;
			_bd.fillRect(_rect, 0x00FFFFFF);
			_matrix.tx = _matrix.ty = 0;
			var offset:Rectangle = target.getBounds(targetCoordinateSpace);
			var m:Matrix = (targetCoordinateSpace == target) ? _matrix : target.transform.matrix;
			m.tx -= offset.x;
			m.ty -= offset.y;
			_bd.draw(target, m, null, "normal", _rect, false);
			var bounds:Rectangle = _bd.getColorBoundsRect(0xFF000000, 0x00000000, false);
			bounds.x += offset.x;
			bounds.y += offset.y;
			target.mask = msk;
			return bounds;
		}
		
		/** @private **/
		protected function _redraw(color:uint):void {
			_previewColor = color;
			var g:Graphics = this.graphics;
			g.clear();
			g.beginFill(_previewColor, 1);
			g.drawRect(0, 0, _width, _height);
			g.endFill();
		}
		
//---- GETTERS / SETTERS ---------------------------------------------------------------------------
		
		/** @inheritDoc **/
		override public function set x(value:Number):void {
			super.x = value;
			if (!_tweenMode) {
				update();
			}
		}
		
		/** @inheritDoc **/
		override public function set y(value:Number):void {
			super.y = value;
			if (!_tweenMode) {
				update();
			}
		}
		
		/** @inheritDoc **/
		override public function set width(value:Number):void {
			super.width = value;
			if (!_tweenMode) {
				update();
			}
		}
		
		/** @inheritDoc **/
		override public function set height(value:Number):void {
			super.height = value;
			if (!_tweenMode) {
				update();
			}
		}
		
		/** @inheritDoc **/
		override public function set scaleX(value:Number):void {
			super.scaleX = value;
			update();
		}
		
		/** @inheritDoc **/
		override public function set scaleY(value:Number):void {
			super.scaleY = value;
			update();
		}
		
		/** @inheritDoc **/
		override public function set rotation(value:Number):void {
			trace("Warning: AutoFitArea instances should not be rotated.");
		}
		
		/** The preview color with which the area should be filled, making it easy to visualize on the stage. You will not see this color unless you set <code>preview</code> to true or manually add the area to the display list with addChild(). **/
		public function get previewColor():uint {
			return _previewColor;
		}
		public function set previewColor(value:uint):void {
			_redraw(value);
		}
		
		/** To see a visual representation of the area on the screen, set <code>preview</code> to <code>true</code>. Doing so will add the area to the display list behind any DisplayObjects that have been attached. **/
		public function get preview():Boolean {
			return _preview;
		}
		public function set preview(value:Boolean):void {
			_preview = value;
			if (this.parent == _parent) {
				_parent.removeChild(this);
			}
			if (value) {
				var level:uint = (_rootItem == null) ? 0 : 999999999;
				var index:uint;
				var item:AutoFitItem = _rootItem;
				while (item) {
					if (item.target.parent == _parent) {
						index = _parent.getChildIndex(item.target);
						if (index < level) {
							level = index;
						}
					}
					item = item.next;
				}
				_parent.addChildAt(this, level);
				this.visible = true;
			}
		}
		
	}
}

import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.Shape;
import flash.geom.Matrix;
import flash.geom.Rectangle;

internal class AutoFitItem {
	public var target:DisplayObject;
	public var scaleMode:String;
	public var hAlign:String;
	public var vAlign:String;
	public var minWidth:Number;
	public var maxWidth:Number;
	public var minHeight:Number;
	public var maxHeight:Number;
	public var aspectRatio:Number;
	public var mask:Shape;
	public var matrix:Matrix;
	public var hasCustomRatio:Boolean;
	public var roundPosition:Boolean;
	
	public var next:AutoFitItem;
	public var prev:AutoFitItem;
	
	public var calculateVisible:Boolean;
	public var boundsTarget:DisplayObject;
	public var bounds:Rectangle;
	public var hasDrawNow:Boolean;
	
	/** @private **/
	public function AutoFitItem(target:DisplayObject, vars:Object, next:AutoFitItem) {
		this.target = target;
		if (vars == null) {
			vars = {};
		}
		this.scaleMode = 	vars.scaleMode || "proportionalInside";
		this.hAlign = 		vars.hAlign || "center";
		this.vAlign = 		vars.vAlign || "center";
		this.minWidth = 	Number(vars.minWidth) || 0;
		this.maxWidth = 	isNaN(vars.maxWidth) ? 999999999 : Number(vars.maxWidth);
		this.minHeight = 	Number(vars.minHeight) || 0;
		this.maxHeight = 	isNaN(vars.maxHeight) ? 999999999 : Number(vars.maxHeight);
		this.roundPosition = Boolean(vars.roundPosition);
		this.boundsTarget = (vars.customBoundsTarget is DisplayObject) ? vars.customBoundsTarget : this.target;
		this.matrix = target.transform.matrix;
		this.calculateVisible = Boolean(vars.calculateVisible);
		this.hasDrawNow = this.target.hasOwnProperty("drawNow");
		if (this.hasDrawNow) {
			Object(this.target).drawNow(); //just to make sure we're starting with the correct values if it's a component.
		}
		if (!isNaN(vars.customAspectRatio)) {
			this.aspectRatio = vars.customAspectRatio;
			this.hasCustomRatio = true;
		}
		if (next) {
			next.prev = this;
			this.next = next;
		}
	}
	
	/** @private **/
	public function setVisibleWidth(value:Number):void {
		var m:Matrix = this.target.transform.matrix;
		if ((m.a == 0 && m.c == 0) || (m.d == 0 && m.b == 0)) {
			m.a = this.matrix.a;
			m.c = this.matrix.c;
		}
		var curWidth:Number = (m.a < 0) ? -m.a * this.bounds.width : m.a * this.bounds.width;
		curWidth += (m.c < 0) ? -m.c * this.bounds.height : m.c * this.bounds.height;
		if (curWidth != 0) {
			var scale:Number = value / curWidth;
			m.a *= scale;
			m.c *= scale;
			this.target.transform.matrix = m;
			if (value != 0) {
				this.matrix = m;
			}
		}
	}
	
	/** @private **/
	public function setVisibleHeight(value:Number):void {
		var m:Matrix = this.target.transform.matrix;
		if ((m.a == 0 && m.c == 0) || (m.d == 0 && m.b == 0)) {
			m.b = this.matrix.b;
			m.d = this.matrix.d;
		}
		var curHeight:Number = (m.b < 0) ? -m.b * this.bounds.width : m.b * this.bounds.width;
		curHeight += (m.d < 0) ? -m.d * this.bounds.height : m.d * this.bounds.height;
		if (curHeight != 0) {
			var scale:Number = value / curHeight;
			m.b *= scale;
			m.d *= scale;
			this.target.transform.matrix = m;
			if (value != 0) {
				this.matrix = m;
			}
		}
	}
	
	/** @private **/
	public function scaleVisibleWidth(value:Number):void {
		var m:Matrix = this.target.transform.matrix;
		m.a *= value;
		m.c *= value;
		this.target.transform.matrix = m;
		if (value != 0) {
			this.matrix = m;
		}
	}
	
	/** @private **/
	public function scaleVisibleHeight(value:Number):void {
		var m:Matrix = this.target.transform.matrix;
		m.b *= value;
		m.d *= value;
		this.target.transform.matrix = m;
		if (value != 0) {
			this.matrix = m;
		}
	}
	
}