package ui {
  import flash.display.*;
  import ui.parts.ScriptsBrowserListPart;
  import uiwidgets.*;

public class ScriptBrowserDialog extends DialogBox {

  private var listFrame:ScrollFrame;

  public var app:Scratch;

  public function ScriptBrowserDialog(app:Scratch) {
    super();

    this.app = app;

    addTitle('Script Browser');

    var container:Sprite = new Sprite();
    addWidget(container);

    listFrame = new ScrollFrame();
    listFrame.setWidthHeight(300, 300);
    listFrame.setContents(new ScriptsBrowserListPart(this.app));
    listFrame.allowHorizontalScrollbar = false;
    container.addChild(listFrame);

    var b:Button = new Button('Close', closeDialog);
    buttons.push(b);
    addChild(b);
  }

  public function closeDialog():void {
    if (parent) parent.removeChild(this);
  }

}}
