/**
 * Created by shanemc on 4/28/15.
 */
package ui.events {
import flash.display.DisplayObject;
import flash.display.InteractiveObject;
import flash.display.Stage;
import flash.events.MouseEvent;
import flash.events.TouchEvent;
import flash.geom.Point;

public class PointerEvent extends MouseEvent {
	static public const LONG_HOLD_DURATION:uint = 500;
	static public const TAP:String = 'tap';
	static public const DOUBLE_TAP:String = 'doubleTap';

	static public const POINTER_DOWN:String = 'pointerDown';
	static public const POINTER_MOVE:String = 'pointerMove';
	static public const POINTER_UP:String = 'pointerUp';

	public var pointerID:int;
	public var pointerType:String;

	static private const touchToPointer:Object = {
		'touchBegin': 'pointerDown',
		'touchMove': 'pointerMove',
		'touchEnd': 'pointerUp'
	};
	static private var stage:Stage;
	public function PointerEvent(type:String, localX:Number = 0, localY:Number = 0, touchID:int = 0) {
		super(type, true, false, localX, localY);
		pointerID = touchID;
		pointerType = touchID == -1 ? 'mouse' : 'touch';
	}

	static private var pt:Point = new Point;
	static private function convertEvent(event:*):void {
		var mEvt:MouseEvent = event as MouseEvent;
		var tEvt:TouchEvent = event as TouchEvent;
		var e:PointerEvent;
		if (mEvt && mEvt.type.indexOf('mouse') == 0) {
			e = new PointerEvent('pointer'+mEvt.type.substr(5), mEvt.localX, mEvt.localY);
			pt.x = mEvt.stageX;
			pt.y = mEvt.stageY;
		}
		else if(tEvt && touchToPointer.hasOwnProperty(tEvt.type)) {
			e = new PointerEvent(touchToPointer[tEvt.type], tEvt.localX, tEvt.localY, tEvt.touchPointID);
			pt.x = tEvt.stageX;
			pt.y = tEvt.stageY;
		}
		else
			throw Error('Cannot convert event to PointerEvent!');

		if (e.type == 'pointerDown')
			activePointers[e.pointerID] = true;

		var target:DisplayObject = capturedPointers[e.pointerID];

		if (!target) {
			var objs:Array = stage.getObjectsUnderPoint(pt);
			if (objs.length) {
				var dObj:DisplayObject = objs[objs.length - 1];
				while ((!(dObj is InteractiveObject) || !(dObj as InteractiveObject).mouseEnabled || !(dObj as InteractiveObject).hasEventListener(e.type)) && dObj != Scratch.app)
					dObj = dObj.parent;
				target = dObj;
			}
		}

		if (target) {
			pt = target.globalToLocal(pt);
			e.localX = pt.x;
			e.localY = pt.y;
			target.dispatchEvent(e);
			//event.stopImmediatePropagation();
		}

		if (e.type == 'pointerUp') {
			delete activePointers[e.pointerID];
			delete capturedPointers[e.pointerID];
		}
	}

	static public function init(s:Stage):void {
		stage = s;
		stage.addEventListener(MouseEvent.MOUSE_DOWN, convertEvent, true, 0, true);
		stage.addEventListener(MouseEvent.MOUSE_MOVE, convertEvent, true, 0, true);
		stage.addEventListener(MouseEvent.MOUSE_UP, convertEvent, true, Number.MAX_VALUE, true);
		stage.addEventListener(TouchEvent.TOUCH_BEGIN, convertEvent, true, 0, true);
		stage.addEventListener(TouchEvent.TOUCH_MOVE, convertEvent, true, 0, true);
		stage.addEventListener(TouchEvent.TOUCH_END, convertEvent, true, Number.MAX_VALUE, true);
	}

	static private var capturedPointers:Object = {};
	static private var activePointers:Object = {};
	static public function setPointerCapture(elem:DisplayObject, pointerID:int):void {
		if (!(pointerID in activePointers)) throw new Error('InvalidPointerId');
		if (!elem || !elem.stage) throw new Error('InvalidStateError');

		if (pointerID in activePointers)
			capturedPointers[pointerID] = elem;
	}

	static public function releasePointerCapture(elem:DisplayObject, pointerID:int):void {
		if (!(pointerID in activePointers)) throw new Error('InvalidPointerId');

		if (capturedPointers[pointerID] == elem)
			delete capturedPointers[pointerID];
	}
}}