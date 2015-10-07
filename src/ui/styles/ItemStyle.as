/**
 * Created by shanemc on 5/12/15.
 */
package ui.styles {
public class ItemStyle {
	public var frameWidth:uint;
	public var frameHeight:uint;
	public var imageWidth:uint;
	public var imageHeight:uint;
	public var imageMargin:uint;
	public var hasInfo:Boolean;
	public var centerText:Boolean;
	public function ItemStyle(fw:uint = 81, fh:uint = 94, iw:uint = 68, ih:uint = 51, im:uint = 10,
	                          info:Boolean = false, centText:Boolean = true) {
		frameWidth = fw;
		frameHeight = fh;
		imageWidth = iw;
		imageHeight = ih;
		imageMargin = im;
		centerText = centText;
		hasInfo = info;
	}
}}