package ui.parts {
  import flash.display.*;
  import ui.parts.ScriptsBrowserListPart;
  import uiwidgets.*;

public class ScriptBrowserPart extends UIPart {

  private var listFrame:ScrollFrame;
  private var closeButton:Button;

  public function ScriptBrowserPart(app:Scratch) {
    this.app = app;

    addListFrame();

    fixLayout();
  }

  private function addListFrame():void {
    listFrame = new ScrollFrame();
    listFrame.setWidthHeight(300, 300);
    listFrame.allowHorizontalScrollbar = false;
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
    listFrame.setContents(new ScriptsBrowserListPart(app));
  }

}}
