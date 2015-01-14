/**
 * Created by shanemc on 12/8/14.
 */
package ui {
import flash.display.DisplayObject;
import flash.display.Stage;
import flash.events.MouseEvent;
import flash.events.TouchEvent;
import flash.utils.Dictionary;

public class ToolMgr {
	static private var currentTools:Dictionary = new Dictionary(true);
	static private var toolAreas:Dictionary = new Dictionary(true);
	static private var stage:Stage;

	static public function init(stage:Stage):void {
		ToolMgr.stage = stage;
	}

	static public function isToolActive():Boolean {
		return currentTools[ScratchTablet.currentTouchID] !== undefined;
	}

	static public function activateTool(tool:ITool, area:DisplayObject = null):Boolean {
		if (isToolActive())
			return false;

		currentTools[ScratchTablet.currentTouchID] = tool;
		if (area)
			toolAreas[ScratchTablet.currentTouchID] = area;
		addMouseListener();

		return true;
	}

	static public function deactivateTool(tool:ITool):Boolean {
		if (currentTools[ScratchTablet.currentTouchID] != tool)
			return false;

		delete currentTools[ScratchTablet.currentTouchID];
		delete toolAreas[ScratchTablet.currentTouchID]
		tool.shutdown();
		removeMouseListener();

		return true;
	}

	static private function addMouseListener():void {
		stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseHandler, true, 0, true);
		stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseHandler, true, 0, true);
		stage.addEventListener(MouseEvent.MOUSE_UP, mouseHandler, true, 0, true);

//		stage.addEventListener(TouchEvent.TOUCH_BEGIN, touchHandler, true, 0, true);
//		stage.addEventListener(TouchEvent.TOUCH_MOVE, touchHandler, true, 0, true);
//		stage.addEventListener(TouchEvent.TOUCH_END, touchHandler, true, 0, true);
	}

	static private function touchHandler(e:TouchEvent):void {
		trace(e);
	}

		// TODO: Track touch ids and associate touch ids with tools.
	// http://help.adobe.com/en_US/as3/dev/WS1ca064e08d7aa93023c59dfc1257b16a3d6-7ffe.html

	static private function removeMouseListener():void {
		stage.removeEventListener(MouseEvent.MOUSE_DOWN, mouseHandler);
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseHandler);
		stage.removeEventListener(MouseEvent.MOUSE_UP, mouseHandler);
	}

	static private function mouseHandler(e:MouseEvent):void {
//		trace(e);
		var currentTool:ITool = currentTools[ScratchTablet.currentTouchID];
		var toolArea:DisplayObject = toolAreas[ScratchTablet.currentTouchID];
		if (currentTool && (!toolArea || toolArea.hitTestPoint(e.stageX, e.stageY, true))) {
			currentTool.mouseHandler(e);

			if (!currentTool) {//} || !currentTool.isSticky()) {
				e.stopImmediatePropagation();
				e.preventDefault();
			}
		}
	}
}}
