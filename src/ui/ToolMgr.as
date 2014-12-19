/**
 * Created by shanemc on 12/8/14.
 */
package ui {
import flash.display.DisplayObject;
import flash.display.Stage;
import flash.events.MouseEvent;
import flash.events.TouchEvent;

public class ToolMgr {
	static private var currentTool:ITool;
	static private var stage:Stage;

	static public function init(stage:Stage):void {
		ToolMgr.stage = stage;
	}

	static public function isToolActive():Boolean {
		return currentTool != null;
	}

	static private var toolArea:DisplayObject;
	static public function activateTool(tool:ITool, area:DisplayObject = null):Boolean {
		if (currentTool != null)
			return false;

		currentTool = tool;
		toolArea = area;
		addMouseListener();

		return true;
	}

	static public function deactivateTool(tool:ITool):Boolean {
		if (currentTool != tool)
			return false;

		currentTool = null;
		tool.shutdown();
		removeMouseListener();

		return true;
	}

	static private function addMouseListener():void {
		stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseHandler, true, 0, true);
		stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseHandler, true, 0, true);
		stage.addEventListener(MouseEvent.MOUSE_UP, mouseHandler, true, 0, true);

//		stage.addEventListener(TouchEvent.TOUCH_BEGIN, mouseHandler, true, 0, true);
//		stage.addEventListener(TouchEvent.TOUCH_MOVE, mouseHandler, true, 0, true);
//		stage.addEventListener(TouchEvent.TOUCH_END, mouseHandler, true, 0, true);
	}

	// TODO: Track touch ids and associate touch ids with tools.
	// http://help.adobe.com/en_US/as3/dev/WS1ca064e08d7aa93023c59dfc1257b16a3d6-7ffe.html

	static private function removeMouseListener():void {
		stage.removeEventListener(MouseEvent.MOUSE_DOWN, mouseHandler);
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseHandler);
		stage.removeEventListener(MouseEvent.MOUSE_UP, mouseHandler);
	}

	static private function mouseHandler(e:MouseEvent):void {
		if (currentTool && (!toolArea || toolArea.hitTestPoint(stage.mouseX, stage.mouseY, true))) {
			currentTool.mouseHandler(e);

			if (!currentTool || !currentTool.isSticky()) {
				e.stopImmediatePropagation();
				e.preventDefault();
			}
		}
	}
}}
