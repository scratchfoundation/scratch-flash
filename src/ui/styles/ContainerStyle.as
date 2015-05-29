/**
 * Created by shanemc on 5/12/15.
 */
package ui.styles {
public class ContainerStyle {
	public static const TYPE_GRID:uint = 0;
	public static const TYPE_STRIP_HORIZONTAL:uint = 1;
	public static const TYPE_STRIP_VERTICAL:uint = 2;

	public var padding:uint;
	public var itemPadding:uint;
	public var animationDuration:Number; // seconds
	public var layout:uint;
	public function ContainerStyle(m:uint = 10, ip:uint = 10, l:uint = TYPE_GRID, animDuration:Number = 0.25) {
		padding = m;
		itemPadding = ip;
		layout = l;
		animationDuration = animDuration;
	}

	public function clone():ContainerStyle {
		return new ContainerStyle(padding, itemPadding, layout, animationDuration);
	}
}}