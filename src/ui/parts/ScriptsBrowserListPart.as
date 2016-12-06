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
    var nextY:int = 3;
    for each (var script:Block in obj.scripts) {
      var listener = (function(block:Block):Function {
        return function():void {
          selectScript(block);
        };
      }(script));

      var b:Button = new Button(script.op, listener);
      b.x = 7;
      b.y = nextY;
      nextY += b.height + 3;
      addChild(b);
    }
  }

  public function selectScript(script:Block) {
    app.selectScript(script);
  }

}}
