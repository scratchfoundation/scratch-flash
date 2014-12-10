/**
 * Created by shanemc on 12/8/14.
 */
package ui.dragdrop {
import flash.display.Sprite;
import flash.events.Event;

public class DraggableSprite extends Sprite implements IDraggable{
	public function DraggableSprite() {
		addEventListener(Event.ADDED_TO_STAGE, addedToStage, false, 0, true);
		addEventListener(Event.REMOVED, removedFromStage, false, 0, true);
	}

	private function addedToStage(e:Event):void {
		if(e.target != this) return;
		//removeEventListener(Event.ADDED_TO_STAGE, addedToStage);

		if (mouseEnabled)
			DragAndDropMgr.setDraggable(this);
	}

	private function removedFromStage(e:Event):void {
		if(e.target != this) return;
		//removeEventListener(Event.REMOVED, removedFromStage);
		if (mouseEnabled)
			DragAndDropMgr.setDraggable(this, false);
	}

	public function getSpriteToDrag():Sprite {
		return null;
	}
}}
