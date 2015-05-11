/**
 * Created by shanemc on 4/28/15.
 */
package ui {
import flash.display.Sprite;
import flash.events.Event;
import org.gestouch.events.GestureEvent;
import org.gestouch.gestures.Gesture;
import org.gestouch.gestures.LongPressGesture;
import org.gestouch.gestures.TransformGesture;
import ui.dragdrop.DragAndDropMgr;
import ui.dragdrop.IDraggable;
import ui.events.PointerEvent;

public class BaseItem extends Sprite implements IDraggable {
	public static const ITEM_INTERACTIVE:String = 'itemInteractive';

	protected var interactive:Boolean;
	protected var selected:Boolean;
	private var longPressGesture:LongPressGesture;

	public function BaseItem() {
		super();

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
	public function isUI():Boolean { return false; }
	public function getIdentifier(strict:Boolean = false):String { return null; }
	public function getSpriteToDrag():Sprite { return null; }
}}
