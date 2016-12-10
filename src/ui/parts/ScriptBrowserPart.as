package ui.parts {
  import scratch.*;
  import blocks.*;
  import flash.display.*;
  import flash.text.*;
  import uiwidgets.*;

public class ScriptBrowserPart extends UIPart {

  private var shape:Shape;
  private var listFrame:ScrollFrame;
  private var listPane:ScrollFrameContents;
  private var closeButton:Button;

  public function ScriptBrowserPart(app:Scratch) {
    this.app = app;

    addChild(shape = new Shape());

    addListFrame();

    fixLayout();
  }

  private function addListFrame():void {
    listPane = new ScrollFrameContents();
    listPane.color = CSS.tabColor;
    listFrame = new ScrollFrame();
    listFrame.setContents(listPane);
    addChild(listFrame);
  }

  public function setWidthHeight(w:int, h:int):void {
    this.w = w;
    this.h = h;
    fixLayout();
    redraw();
  }

  public function fixLayout():void {
    listFrame.x = 0;
    listFrame.y = 0;
    listFrame.setWidthHeight(w, h);
  }

  private function redraw():void {
    var g:Graphics = shape.graphics;
    g.clear();
    g.lineStyle(1, CSS.borderColor, 1, true);
    g.beginFill(CSS.tabColor);
    g.drawRect(0, 0, w, h);
    g.endFill();
  }

  public function selectedSpriteUpdated():void {
    listPane.y = 0; // Reset scroll
    updateContents();
  }

  public function updateContents():void {
    while (listPane.numChildren > 0) listPane.removeChildAt(0);

    var obj:ScratchObj = app.viewedObj();

    if (!obj) {
      return;
    }

    var nextY:int = 5;
    var nextX:int = 5;
    var rowHeight:int = 0;
    for each (var script:Block in getSortedScriptsFromObj(obj)) {
      var listener:Function = (function(block:Block):Function {
        return function():void {
          selectScript(block);
        };
      }(script));

      var topBlockDup = script.duplicate(obj.isClone, obj.isStage);
      while (topBlockDup.nextBlock) {
        topBlockDup.removeBlock(topBlockDup.nextBlock);
      }

      topBlockDup.draggable = false;
      topBlockDup.clickOverride = listener;

      if (topBlockDup.height > rowHeight) {
        rowHeight = topBlockDup.height;
      }

      if (nextX + topBlockDup.width + 5 > w) {
        nextY += rowHeight + 5;
        nextX = 5;
        rowHeight = 0;
      }

      topBlockDup.x = nextX;
      topBlockDup.y = nextY;

      nextX += topBlockDup.width + 5;

      listPane.addChild(topBlockDup);
    }
    listPane.updateSize();
  }

  public function selectScript(script:Block):void {
    app.selectScript(script);
  }

  public function getSortedScriptsFromObj(obj:ScratchObj):Array {
    var scripts:Array = obj.scripts.slice(0);

    return scripts.sort(function(a:Block, b:Block) {
      var aStr = a.getSummary();
      var bStr = b.getSummary();
      if (aStr < bStr) {
        return -1;
      } else if (aStr > bStr) {
        return 1;
      } else {
        return 0;
      }
    });
  }

}}
