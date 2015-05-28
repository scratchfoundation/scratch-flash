/**
 * Created by shanemc on 4/28/15.
 */
package ui {
import flash.display.Bitmap;
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
import assets.Resources;

public class BaseItem extends Sprite implements IDraggable {
	private static var thumbnailFactory:ThumbnailFactory;
	public static function setFactory(factory:ThumbnailFactory):void { thumbnailFactory = factory; }

	public static const ITEM_INTERACTIVE:String = 'itemInteractive';

	public var data:ItemData;
	protected var image:Bitmap;
	protected var interactive:Boolean;
	protected var selected:Boolean;
	protected var style:ItemStyle;
	protected var label:TextField;
	protected var info:TextField;

	public function BaseItem(s:ItemStyle, itemData:ItemData) {
		style = s;
		data = itemData;
		addText();
		refresh();
		setupInteractions();
	}

	public function setImage(img:Bitmap):void {
		if (image && image.parent) removeChild(image);
		addChild(image = img);

		var tAspect:Number = style.imageWidth / style.imageHeight;
		if (image.bitmapData) {
			var scale:Number;
			if (image.width / image.height > tAspect)
				scale = style.imageWidth / image.width;
			else
				scale = style.imageHeight / image.height;

			image.scaleX = image.scaleY = scale;
		}

		image.x = (style.frameWidth - image.width) / 2;
		image.y = style.imageMargin;
	}

	public function refresh(forceRender:Boolean = false):void {
		thumbnailFactory.updateThumbnail(this, style, forceRender);

		// Update text
		setText(label, data.name);

		if (style.hasInfo && data.extras)
			setText(info, data.extras.info);
	}

	protected function addText():void {
		label = Resources.makeLabel('', CSS.thumbnailFormat);
		label.selectable = false;
		addChild(label);

		var imageBottom:uint = style.imageHeight + 2 * style.imageMargin;
		var textAreaHeight:uint = style.frameHeight - imageBottom;
		if (style.hasInfo) {
			// Split the text area in two
			textAreaHeight /= 2;
			label.y = imageBottom + (textAreaHeight - Number(label.defaultTextFormat.size))/2;
			info = Resources.makeLabel('', CSS.thumbnailExtraInfoFormat);
			info.selectable = false;
			info.y = imageBottom + textAreaHeight + (textAreaHeight - Number(info.defaultTextFormat.size))/2;
			addChild(info);
		}
		else {
			label.y = imageBottom + (textAreaHeight - Number(label.defaultTextFormat.size))/2;
		}
	}

	protected function setText(tf:TextField, s:String):void {
		if (s == null) s = '';
		if (tf.text == s) return;

		// Set the text of the given TextField, truncating if necessary.
		var desiredWidth:int = style.frameWidth - CSS.tinyPadding;
		tf.text = s;
		while ((tf.textWidth > desiredWidth) && (s.length > 0)) {
			s = s.substring(0, s.length - 1);
			tf.text = s + '\u2026'; // truncated name with ellipses
		}

		tf.x = (style.frameWidth - tf.textWidth) / 2;
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

	public function isInteractive():Boolean {
		return interactive;
	}

	public function duplicate():BaseItem {
		var newData:Object = {};
		for (var prop:String in data)
			newData[prop] = data[prop];

		return new BaseItem(style, data.clone());
	}

	// Consider these "abstract" because they should / can be overridden
	public function isUI():Boolean { return data.type == 'ui'; }
	public function getIdentifier(strict:Boolean = false):String { return data.identifier(strict); }
	public function getSpriteToDrag():Sprite {
		var dup:BaseItem = duplicate();
		dup.label.visible = false;
		dup.scaleX = dup.scaleY = transform.concatenatedMatrix.a;
		return dup;
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
