/**
 * Created by shanemc on 9/18/14.
 */
package ui.parts.base {

public interface IImagesPart {
	function updateTranslation():void;
	function setWidthHeight(w:uint, h:uint):void;
	function refreshUndoButtons():void;
	function useBitmapEditor(enable:Boolean):void;
	function usingBitmapEditor():Boolean;
	function enableTools(enabled:Boolean):void;
	function convertToBitmap():void;
	function convertToVector():void;
	function refresh(fromEditor:Boolean = false):void;
	function setXY(x:Number, y:Number):void;
	function selectCostume():void;
	function step():void;
	function shutdownEditor():void;
}}