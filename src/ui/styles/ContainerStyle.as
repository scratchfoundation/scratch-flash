/**
 * Created by shanemc on 5/12/15.
 */
package ui.styles {
public class ContainerStyle {
	public var padding:uint;
	public var itemPadding:uint;
	public var animationDuration:Number; // seconds
	public function ContainerStyle(m:uint = 10, ip:uint = 10, animDuration:Number = 0.25) {
		padding = m;
		itemPadding = ip;
		animationDuration = animDuration;
	}
}}