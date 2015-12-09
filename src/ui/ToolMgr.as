/**
 * Created by shanemc on 12/8/14.
 */
package ui {
import flash.display.DisplayObject;
import flash.display.Stage;
import flash.utils.Dictionary;

import ui.events.PointerEvent;

public class ToolMgr {
	static private var currentTools:Dictionary = new Dictionary(true);
	static private var areaTools:Dictionary = new Dictionary(true);
	static private var toolAreas:Dictionary = new Dictionary(true);
	static private var stage:Stage;

	static public function init(stage:Stage):void {
		ToolMgr.stage = stage;
		addListeners();
	}

	static public function isToolActive(touchID:int):Boolean {
		return currentTools[touchID] !== undefined;
	}

	static public function activateTool(tool:ITool, context:*):Boolean {
		var event:PointerEvent = context as PointerEvent;
		if (event && !isToolActive(event.pointerID)) {
			currentTools[event.pointerID] = tool;
		}
		else if (context is DisplayObject) {
			toolAreas[tool] = context;
		}
		else {
			return false;
		}


		return true;
	}

	static public function deactivateTool(tool:ITool):Boolean {
		var touchID:int = -1;
		for(var tid:String in currentTools)
			if (currentTools[tid] == tool) {
				touchID = int(tid);
				break;
			}

		if (touchID == -1)
			return false;

		delete currentTools[touchID];
		delete toolAreas[touchID];
		tool.shutdown();

		return true;
	}

	static private function addListeners():void {
		stage.addEventListener(PointerEvent.POINTER_DOWN, mouseHandler, true, 0, true);
		stage.addEventListener(PointerEvent.POINTER_MOVE, mouseHandler, true, 0, true);
		stage.addEventListener(PointerEvent.POINTER_UP, mouseHandler, true, Number.MAX_VALUE, true);
	}

	static private function mouseHandler(e:PointerEvent):void {
		var currentTool:ITool = currentTools[e.pointerID];
		var isAreaTool:Boolean = false;
		if (!currentTool) {
			currentTool = areaTools[e.pointerID];
			isAreaTool = !!currentTool;
		}

		if (!currentTool && e.type == PointerEvent.POINTER_DOWN) {
			for each (var tool:ITool in toolAreas) {
				if (toolAreas[tool].hitTestPoint(e.stageX, e.stageY, true)) {
					currentTool = areaTools[e.pointerID] = tool;
					isAreaTool = true;
					break;
				}
			}
		}

		if (currentTool) {
			var shouldDispatch:Boolean = (!isAreaTool || e.type == PointerEvent.POINTER_DOWN || toolAreas[currentTool].hitTestPoint(e.stageX, e.stageY, true));
			if (shouldDispatch && currentTool.mouseHandler(e)) {
				e.stopImmediatePropagation();
				e.preventDefault();
			}

			if (isAreaTool && e.type == PointerEvent.POINTER_UP)
				delete areaTools[e.pointerID];
		}
	}
}}
