/**
 * Created by shanemc on 5/4/15.
 */
package uiwidgets {
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import translation.Translator;

public class SimpleTextField extends TextField {
	// Stores the untranslated text when the TextField displays translated text
	protected var origText:String = null;
	public function SimpleTextField(str:String, format:TextFormat = null, context:* = null) {
		super();
		autoSize = TextFieldAutoSize.LEFT;
		selectable = false;
		defaultTextFormat = new TextFormat(CSS.font, CSS.normalTextFormat.size, 0x808080);
		if (!(context is NewMenu) || (context as NewMenu).shouldTranslateItem(str))
			origText = str;
		else
			text = str;

		refreshText();
	}

	public function refreshText():void {
		if (origText != null)
			text = Translator.map(origText);
	}
}}
