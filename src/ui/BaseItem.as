/**
 * Created by shanemc on 4/28/15.
 */
package ui {
import assets.Resources;

import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.events.Event;
import flash.text.TextField;

import org.gestouch.events.GestureEvent;
import org.gestouch.gestures.Gesture;
import org.gestouch.gestures.LongPressGesture;
import org.gestouch.gestures.TransformGesture;
import ui.dragdrop.DragAndDropMgr;
import ui.dragdrop.IDraggable;
import ui.events.PointerEvent;
import ui.styles.ItemStyle;

public class BaseItem extends Sprite implements IDraggable {
	private static var thumbnailFactory:ThumbnailFactory;
	public static function setFactory(factory:ThumbnailFactory):void { thumbnailFactory = factory; }

	public static const ITEM_INTERACTIVE:String = 'itemInteractive';

	public var data:ItemData;
	protected var image:DisplayObject;
	protected var interactive:Boolean;
	protected var selected:Boolean;
	protected var style:ItemStyle;
	protected var label:TextField;

	public function BaseItem(s:ItemStyle, itemData:ItemData) {
		style = s;
		data = itemData;
		thumbnailFactory.updateThumbnail(this, s);
		addText();

		setupInteractions();
	}

	public function setImage(img:DisplayObject):void {
		if (image && image.parent) removeChild(image);
		addChild(image = img);

		image.x = (style.frameWidth - image.width) / 2;
		image.y = style.imageMargin;
	}

	public function refresh():void {
		thumbnailFactory.updateThumbnail(this, style);
	}

	protected function addText():void {
		label = Resources.makeLabel('', CSS.thumbnailFormat);
		var imageBottom:uint = style.imageHeight + 2* style.imageMargin;
		label.y = imageBottom + (style.frameHeight - imageBottom - label.height)/2;
		addChild(label);
	}

	public function remove():void {
		longPressGesture.dispose();
		if (parent) parent.removeChild(this);
	}

	public function setSelected(sel:Boolean):void {
		selected = sel;
	}

	public function setInteractive(inter:Boolean):void {
		if (inter == interactive) return;

		interactive = inter;
		if(inter) dispatchEvent(new Event(ITEM_INTERACTIVE, true));
	}

	// Consider these "abstract" because they should / can be overridden
	public function isUI():Boolean { return data.obj == null; }
	public function getIdentifier(strict:Boolean = false):String { return data.identifier(strict); }
	public function getSpriteToDrag():Sprite {
		return new BaseItem(style, data)
	}

	private var longPressGesture:LongPressGesture;
	protected function setupInteractions():void {
		longPressGesture = new LongPressGesture(this);
		longPressGesture.minPressDuration = PointerEvent.LONG_HOLD_DURATION;
		longPressGesture.addEventListener(GestureEvent.GESTURE_BEGAN, gestureRecognized);

		var dragGesture:TransformGesture = new TransformGesture(this);
		dragGesture.gestureShouldBeginCallback = shouldDragBegin;
		DragAndDropMgr.setDraggable(this, true, dragGesture);
	}

	protected function shouldDragBegin(gesture:Gesture):Boolean {
		return interactive;
	}

	private function gestureRecognized(event:GestureEvent):void {
		if (interactive) return;

		setInteractive(true);
	}
}}
