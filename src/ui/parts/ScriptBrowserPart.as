package ui.parts {
  import scratch.*;
  import blocks.*;
  import flash.display.*;
  import uiwidgets.*;

public class ScriptBrowserPart extends UIPart {

  private var listFrame:ScrollFrame;
  private var listPane:ScrollFrameContents;
  private var closeButton:Button;

  public function ScriptBrowserPart(app:Scratch) {
    this.app = app;

    addListFrame();

    fixLayout();
  }

  private function addListFrame():void {
    listPane = new ScrollFrameContents();
    listPane.color = 0xEEEEEE;
    listFrame = new ScrollFrame();
    listFrame.setContents(listPane);
    addChild(listFrame);
  }

  public function setWidthHeight(w:int, h:int):void {
    this.w = w;
    this.h = h;
    fixLayout();
  }

  public function fixLayout():void {
    listFrame.x = 0;
    listFrame.y = 0;
    listFrame.setWidthHeight(w, h);
  }

  public function selectedSpriteUpdated():void {
    updateContents();
  }

  private function updateContents():void {
    while (listPane.numChildren > 0) listPane.removeChildAt(0);

    var obj:ScratchObj = app.viewedObj();

    if (!obj) {
      return;
    }

    var nextY:int = 5;
    var nextX:int = 5;
    var rowHeight:int = 0;
    for each (var script:Block in obj.scripts) {
      var listener:Function = (function(block:Block):Function {
        return function():void {
          selectScript(block);
        };
      }(script));

      var topBlockDup = script.duplicate(obj.isClone, obj.isStage);
      while (topBlockDup.nextBlock) {
        topBlockDup.removeBlock(topBlockDup.nextBlock);
      }

      topBlockDup.clickOverride = listener;

      if (topBlockDup.height > rowHeight) {
        rowHeight = topBlockDup.height;
      }

      if (nextX + topBlockDup.width + 5 > w) {
        nextY += rowHeight + 5;
        nextX = 5;
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

}}
