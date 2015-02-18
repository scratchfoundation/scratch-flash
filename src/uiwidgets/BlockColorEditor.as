package uiwidgets {
import blocks.*;

import flash.display.*;
import flash.events.*;
import flash.geom.*;
import flash.net.*;
import flash.text.*;
import flash.utils.ByteArray;

import ui.parts.UIPart;

import util.*;

public class BlockColorEditor extends Sprite {

	private var base:Shape;
	private var blockShape:BlockShape;
	private var blockLabel:TextField;

	// category selector
	private var category:TextField;
	private var categoryName:TextField;

	// HSV controls
	private var hueBox:EditableLabel;
	private var satBox:EditableLabel;
	private var briBox:EditableLabel;

	private var hueSlider:Scrollbar;
	private var satSlider:Scrollbar;
	private var briSlider:Scrollbar;

	// current color
	private var hue:Number;
	private var sat:Number;
	private var bri:Number;

	public function BlockColorEditor() {
		addChild(base = new Shape());
		setWidthHeight(250, 430);

		addButtons();
		addCategorySelector();
		addBlockShape();
		addHSVControls();
		selectCategory('Motion');
	}

	private function setWidthHeight(w:int, h:int):void {
		var g:Graphics = base.graphics;
		g.clear();
		g.beginFill(CSS.white);
		g.drawRect(0, 0, w, h);
		g.endFill();
	}

	private function addButtons():void {
		var b:IconButton;
		addChild(b = UIPart.makeMenuButton('Load', loadColors, false, CSS.textColor));
		b.x = 5;
		b.y = 0;
		addChild(b = UIPart.makeMenuButton('Save', saveColors, false, CSS.textColor));
		b.x = 45;
		b.y = 0;
		addChild(b = UIPart.makeMenuButton('Apply', apply, false, CSS.textColor));
		b.x = 120;
		b.y = 31;
	}

	public function apply(b:IconButton):void {
		setCategoryColor(categoryName.text, Color.fromHSV(hue, sat, bri));
		Scratch.app.translationChanged();
	}

	private function setCategoryColor(catName:String, c:int):void {
		for each (var r:Array in Specs.categories) {
			if (r[1] == catName) r[2] = c;
			if ('Data' == catName) Specs.variableColor = c;
			if ('List' == catName) Specs.listColor = c;
			if ('More Blocks' == catName) Specs.procedureColor = c;
			if ('Parameter' == catName) Specs.parameterColor = c;
			if ('Extension' == catName) Specs.extensionsColor = c;
		}
	}

	public function loadColors(b:IconButton):void {
		function fileSelected(event:Event):void {
			if (fileList.fileList.length == 0) return;
			var file:FileReference = FileReference(fileList.fileList[0]);
			file.addEventListener(Event.COMPLETE, fileLoaded);
			file.load();
		}
		function fileLoaded(event:Event):void {
			var data:ByteArray = FileReference(event.target).data;
			var colors:Object = util.JSON.parse(data.toString());
			for (var k:String in colors) {
 				setCategoryColor(k, colors[k]);
			}
			selectCategory(categoryName.text);
 			Scratch.app.translationChanged();
 		}
		var fileList:FileReferenceList = new FileReferenceList();
		fileList.addEventListener(Event.SELECT, fileSelected);
		fileList.browse();
	}

	public function saveColors(b:IconButton):void {
		var s:String = '{\n';
		for each (var r:Array in Specs.categories) {
			if (r[0] != 0) s += '  "' + r[1] + '": 0x' + r[2].toString(16) + ',\n';
		}
		s = s.slice(0, s.length - 2) + '\n}\n'; // remove final comma
		new FileReference().save(s, 'scratch.colors');
	}

	private function addCategorySelector():void {
		category = makeLabel('Category:', 12, 120, 0, true);
		category.addEventListener(MouseEvent.MOUSE_OVER, categoryRollover);
		category.addEventListener(MouseEvent.MOUSE_OUT, categoryRollover);
		category.addEventListener(MouseEvent.MOUSE_DOWN, categoryMenu);

		categoryName = makeLabel('More Blocks', 12, 185, 0);
	}

	private function categoryRollover(evt:MouseEvent):void {
		category.textColor = (evt.type == MouseEvent.MOUSE_OVER) ? CSS.buttonLabelOverColor : CSS.textColor;
	}

	private function categoryMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(selectCategory);
		for each (var r:Array in Specs.categories) {
			if ((r[0] > 0) && (r[0] <= 20)) m.addItem(r[1]);
		}
		var p:Point = category.localToGlobal(new Point(0, 0));
		m.showOnStage(stage, p.x + 1, p.y + category.height - 1);
	}

	private function selectCategory(catName:String):void {
		categoryName.text = catName;
		var entry:Array = Specs.entryForCategory(catName);
		setColor(entry[2]);
	}

	private function addBlockShape():void {
		addChild(blockShape = new BlockShape(BlockShape.CmdShape, Specs.procedureColor));
		blockShape.setWidthAndTopHeight(95, 22, true);
		blockShape.x = 5;
		blockShape.y = 30;

		blockLabel = makeLabel('', 11, blockShape.x + 4, blockShape.y + 3);
		blockLabel.defaultTextFormat = new TextFormat('Arial', 11, 0xFFFFFF, true);
		blockLabel.text = 'block color test';
	}

	private function addHSVControls():void {
		makeLabel('Hue', 15, 35, 60, true);
		makeLabel('Sat.', 15, 110, 60, true);
		makeLabel('Bri.', 15, 185, 60, true);

		addChild(hueBox = new EditableLabel(hueTextChanged));
		addChild(satBox = new EditableLabel(satTextChanged));
		addChild(briBox = new EditableLabel(briTextChanged));

		addChild(hueSlider = new Scrollbar(10, 300, setHue));
		addChild(satSlider = new Scrollbar(10, 300, setSat));
		addChild(briSlider = new Scrollbar(10, 300, setBri));

		hueBox.setWidth(50);
		satBox.setWidth(50);
		briBox.setWidth(50);

		hueBox.x = 25;
		satBox.x = 100;
		briBox.x = 175;
		hueBox.y = satBox.y = briBox.y = 85;

		hueSlider.x = hueBox.x + 20;
		satSlider.x = satBox.x + 20;
		briSlider.x = briBox.x + 20;
		hueSlider.y = satSlider.y = briSlider.y = hueBox.y + 30;
		setColor(0x2F55A5);
	}

	private function setColor(c:int):void {
		var hsv:Array = Color.rgb2hsv(c);
		hue = hsv[0];
		sat = hsv[1];
		bri = hsv[2];
		update();
	}

	private function update():void {
		hue = hue % 360;
		if (hue < 0) hue += 360;
		sat = Math.max(0, Math.min(sat, 1));
		bri = Math.max(0, Math.min(bri, 1));

		blockShape.setColor(Color.fromHSV(hue, sat, bri));
		blockShape.redraw();

		hueBox.setContents('' + Math.round(hue));
		satBox.setContents('' + Math.round(100 * sat));
		briBox.setContents('' + Math.round(100 * bri));

		hueSlider.update(hue / 360, 0.08);
		satSlider.update(sat, 0.08);
		briSlider.update(bri, 0.08);
	}

	private function hueTextChanged():void {
		var n:Number = Number(hueBox.contents());
		if (n == n) hue = n;
		update();
	}

	private function satTextChanged():void {
		var n:Number = Number(satBox.contents());
		if (n == n) sat = n / 100;
		update();
	}

	private function briTextChanged():void {
		var n:Number = Number(briBox.contents());
		if (n == n) bri = n / 100;
		update();
	}

	private function setHue(n:Number):void { hue = 360 * n; update() }
	private function setSat(n:Number):void { sat = n; update() }
	private function setBri(n:Number):void { bri = n; update() }

	private function makeLabel(s:String, fontSize:int, x:int = 0, y:int = 0, bold:Boolean = false):TextField {
		var tf:TextField = new TextField();
		tf.selectable = false;
		tf.defaultTextFormat = new TextFormat(CSS.font, fontSize, CSS.textColor, bold);
		tf.autoSize = TextFieldAutoSize.LEFT;
		tf.text = s;
		tf.x = x;
		tf.y = y;
		addChild(tf);
		return tf;
	}

}}
