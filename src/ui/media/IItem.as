package ui.media {
import ui.dragdrop.IDraggable;

public interface IItem extends IDraggable {
	function isUI():Boolean;
	function getIdentifier(strict:Boolean = false):String;
}}
