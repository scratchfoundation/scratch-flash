/**
 * Created by shanemc on 9/23/14.
 */
package ui.parts.base {
import scratch.ScratchSound;

public interface ISoundsPart {
	function updateTranslation():void;
	function setWidthHeight(w:uint, h:uint):void;
	function refresh():void;
	function setXY(x:Number, y:Number):void;
	function selectSound(sound:ScratchSound):void;
	function shutdownEditor():void;
	function recordSound(b:* = null):void;
}}
