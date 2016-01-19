/*
 * Scratch Project Editor and Player
 * Copyright (C) 2014 Massachusetts Institute of Technology
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

package ui {
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.text.*;
	import flash.net.*;
	import assets.Resources;
	import blocks.*;
	import uiwidgets.*;
	import util.*;
	import translation.Translator;

public class SharingSpecEditor extends Sprite {

	private var base:Shape;
	private var row:Array = [];

	private var playLabel:TextField;
	private var linkLabel:TextField;
	private var faqLabel:TextField;
	private var shareLabel:TextField;
	private var shareImage:DisplayObject;

	private var toggleOn:Boolean;
	private var slotColor:int = 0xBBBDBF;
	private const labelColor:int = 0x8738bf; // 0x6c36b3; // 0x9c35b3;

	public function SharingSpecEditor() {
		addChild(base = new Shape());
		setWidthHeight(400, 260);

		addChild(playLabel = makeLabel('To play your video, download and install the',14));
		addChild(linkLabel = makeLinkLabel('VLC media player.',14,"http://www.videolan.org/vlc/index.html"));
		addChild(faqLabel = makeLinkLabel('Questions?',14,"https://scratch.mit.edu/info/faq/"));
		addChild(shareLabel = makeLabel('You can also share your video with others to let them see it!',14));
		addChild(shareImage = Resources.createDO("videoShare"));
		var h:Number = 160/shareImage.width*shareImage.height;
		shareImage.width = 160;
		shareImage.height = h;
		fixLayout();
	}

	private function setWidthHeight(w:int, h:int):void {
		var g:Graphics = base.graphics;
		g.clear();
		g.beginFill(CSS.white);
		g.drawRect(0, 0, w, h);
		g.endFill();
	}

	public function spec():String {
		var result:String = '';
		for each (var o:* in row) {
			if (o is TextField) result += ReadStream.escape(TextField(o).text);
			if ((result.length > 0) && (result.charAt(result.length - 1) != ' ')) result += ' ';
		}
		if ((result.length > 0) && (result.charAt(result.length - 1) == ' ')) result = result.slice(0, result.length - 1);
		return result;
	}

	private function makeLabel(s:String, fontSize:int,bold:Boolean = false):TextField {
		var tf:TextField = new TextField();
		tf.selectable = false;
		tf.defaultTextFormat = new TextFormat(CSS.font, fontSize, CSS.textColor,bold);
		tf.autoSize = TextFieldAutoSize.LEFT;
		tf.text = Translator.map(s);
		addChild(tf);
		return tf;
	}
	
	private function makeLinkLabel(s:String, fontSize:int,linkUrl:String=""):TextField {
		var tf:TextField = new TextField();
		tf.selectable = false;
		tf.defaultTextFormat = new TextFormat(CSS.font, fontSize, CSS.overColor);
		tf.autoSize = TextFieldAutoSize.LEFT;
		tf.htmlText = '<a href="event:' + linkUrl + '">' + Translator.map(s) + '</a>';
		addChild(tf);
		tf.addEventListener(TextEvent.LINK, linkClicked);
		function linkClicked(e:TextEvent):void {
		    navigateToURL(new URLRequest(e.text), "_blank");
		}
		return tf;
	}

	private function appendObj(o:DisplayObject):void {
		row.push(o);
		addChild(o);
		if (stage) {
			if (o is TextField) stage.focus = TextField(o);
		}
		fixLayout();
	}

	private function makeTextField(contents:String):TextField {
		var result:TextField = new TextField();
		result.borderColor = 0;
		result.backgroundColor = labelColor;
		result.background = true;
		result.type = TextFieldType.INPUT;
		result.defaultTextFormat = Block.blockLabelFormat;
		if (contents.length > 0) {
			result.width = 1000;
			result.text = contents;
			result.width = Math.max(10, result.textWidth + 2);
		} else {
			result.width = 27;
		}
		result.height = result.textHeight + 5;
		return result;
	}

	private function fixLayout(updateDelete:Boolean = true):void {
		playLabel.x = (this.width-playLabel.width-linkLabel.width)/2;
		playLabel.y = 0;
		
		linkLabel.x = playLabel.x+playLabel.width;
		linkLabel.y = 0;
		
		shareImage.x = (this.width-shareImage.width)/2-25;
		shareImage.y = 30;
		
		shareLabel.x = (this.width-shareLabel.width)/2;
		shareLabel.y = 24;
		
		faqLabel.x = (this.width-faqLabel.width)/2;
		faqLabel.y = 230;
		
		if (parent is DialogBox) DialogBox(parent).fixLayout();
	}
}}

