package ui.parts {
  import scratch.*;
  import blocks.*;
  import uiwidgets.*;

public class ScriptsBrowserListPart extends ScrollFrameContents {

  public var app:Scratch;

  public function ScriptsBrowserListPart(app:Scratch) {
    super();

    this.app = app;

    replaceContents();
  }

  private function replaceContents():void {
    while (numChildren > 0) removeChildAt(0);

    var obj:ScratchObj = app.viewedObj();

    if (!obj) {
      return;
    }

    var nextY:int = 3;
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

      topBlockDup.x = 7;
      topBlockDup.y = nextY;
      nextY += topBlockDup.height + 3;
      addChild(topBlockDup);
    }
  }

  public function selectScript(script:Block):void {
    app.selectScript(script);
  }

}}
