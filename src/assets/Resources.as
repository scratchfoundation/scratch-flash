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

package assets {
	import flash.display.*;
	import flash.text.*;

public class Resources {

	public static function createBmp(resourceName:String):Bitmap {
		var resourceClass:Class = Resources[resourceName];
		if (!resourceClass) {
			trace('missing resource: ', resourceName);
			return new Bitmap(new BitmapData(10, 10, false, 0x808080));
		}
		return new resourceClass();
	}
	
	public static function createDO(resourceName:String):DisplayObject {
		var resourceClass:Class = Resources[resourceName];
		if (!resourceClass) {
			trace('missing resource: ', resourceName);
			return new Bitmap(new BitmapData(10, 10, false, 0x808080));
		}
		return new resourceClass();
	}

	public static function makeLabel(s:String, fmt:TextFormat, x:int = 0, y:int = 0):TextField {
		// Create a non-editable text field for use as a label.
		// Note: Although labels not related to bitmaps, this was a handy
		// place to put this function.
		var tf:TextField = new TextField();
		tf.autoSize = TextFieldAutoSize.LEFT;
		tf.selectable = false;
		tf.defaultTextFormat = fmt;
		tf.text = s;
		tf.x = x;
		tf.y = y;
		return tf;
	}

	public static function chooseFont(fontList:Array):String {
		// Return the first available font in the given list or '_sans' if none of the fonts exist.
		// Font names are case sensitive.
		var availableFonts:Array = [];
		for each (var f:Font in Font.enumerateFonts(true)) availableFonts.push(f.fontName);

		for each (var fName:String in fontList) {
			if (availableFonts.indexOf(fName) > -1) return fName;
		}
		return '_sans';
	}

	// Embedded fonts
	[Embed(source='fonts/DonegalOne-Regular.ttf', fontName='Donegal', embedAsCFF = 'false', advancedAntiAliasing = 'true')] private static const Font1:Class;
	[Embed(source='fonts/GloriaHallelujah.ttf', fontName='Gloria', embedAsCFF = 'false', advancedAntiAliasing = 'true')] private static const Font2:Class;
	[Embed(source='fonts/Helvetica-Bold.ttf', fontName='Helvetica', embedAsCFF = 'false', advancedAntiAliasing = 'true')] private static const Font3:Class;
	[Embed(source='fonts/MysteryQuest-Regular.ttf', fontName='Mystery', embedAsCFF = 'false', advancedAntiAliasing = 'true')] private static const Font4:Class;
	[Embed(source='fonts/PermanentMarker.ttf', fontName='Marker', embedAsCFF = 'false', advancedAntiAliasing = 'true')] private static const Font5:Class;
	[Embed(source='fonts/Scratch.ttf', fontName='Scratch', embedAsCFF = 'false', advancedAntiAliasing = 'true')] private static const Font6:Class;

	// Block Icons (2x resolution to look better when scaled)
	[Embed(source='blocks/flagIcon.png')] private static const flagIcon:Class;
	[Embed(source='blocks/stopIcon.png')] private static const stopIcon:Class;
	[Embed(source='blocks/turnLeftIcon.png')] private static const turnLeftIcon:Class;
	[Embed(source='blocks/turnRightIcon.png')] private static const turnRightIcon:Class;

	// Cursors
	[Embed(source='cursors/copyCursor.png')] private static const copyCursor:Class;
	[Embed(source='cursors/crosshairCursor.gif')] private static const crosshairCursor:Class;
	[Embed(source='cursors/cutCursor.png')] private static const cutCursor:Class;
	[Embed(source='cursors/growCursor.png')] private static const growCursor:Class;
	[Embed(source='cursors/helpCursor.png')] private static const helpCursor:Class;
	[Embed(source='cursors/shrinkCursor.png')] private static const shrinkCursor:Class;
	[Embed(source='cursors/mouseCircle.png')] private static const mouseCircle:Class;
	[Embed(source='cursors/segmentationBusyCursor.png')] private static const segmentationBusy:Class;
	[Embed(source='UI/paint/zoomInCursor.png')] private static const zoomInCursor:Class;
	
	[Embed(source='cursors/videoCursor.svg')] private static const videoCursor:Class;

	// Top bar
	[Embed(source='UI/topbar/scratchlogoOff.png')] private static const scratchlogoOff:Class;
	[Embed(source='UI/topbar/scratchlogoOn.png')] private static const scratchlogoOn:Class;
	[Embed(source='UI/topbar/scratchx-logo.png')] private static const scratchxlogo:Class;
	[Embed(source='UI/topbar/copyTool.png')] private static const copyTool:Class;
	[Embed(source='UI/topbar/cutTool.png')] private static const cutTool:Class;
	[Embed(source='UI/topbar/growTool.png')] private static const growTool:Class;
	[Embed(source='UI/topbar/helpTool.png')] private static const helpTool:Class;
	[Embed(source='UI/topbar/languageButtonOff.png')] private static const languageButtonOff:Class;
	[Embed(source='UI/topbar/languageButtonOn.png')] private static const languageButtonOn:Class;
	[Embed(source='UI/topbar/myStuffOff.gif')] private static const myStuffOff:Class;
	[Embed(source='UI/topbar/myStuffOn.gif')] private static const myStuffOn:Class;
	[Embed(source='UI/topbar/projectPageFlip.png')] private static const projectPageFlip:Class;
	[Embed(source='UI/topbar/openInScratch.png')] private static const openInScratch:Class;
	[Embed(source='UI/topbar/shrinkTool.png')] private static const shrinkTool:Class;

	// Buttons
	[Embed(source='UI/buttons/addItemOff.gif')] private static const addItemOff:Class;
	[Embed(source='UI/buttons/addItemOn.gif')] private static const addItemOn:Class;
	[Embed(source='UI/buttons/backarrowOff.png')] private static const backarrowOff:Class;
	[Embed(source='UI/buttons/backarrowOn.png')] private static const backarrowOn:Class;
	[Embed(source='UI/buttons/checkboxOff.gif')] private static const checkboxOff:Class;
	[Embed(source='UI/buttons/checkboxOn.gif')] private static const checkboxOn:Class;
	[Embed(source='UI/buttons/closeOff.gif')] private static const closeOff:Class;
	[Embed(source='UI/buttons/closeOn.gif')] private static const closeOn:Class;
	[Embed(source='UI/buttons/deleteItemOff.png')] private static const deleteItemOff:Class;
	[Embed(source='UI/buttons/deleteItemOn.png')] private static const deleteItemOn:Class;
	[Embed(source='UI/buttons/extensionHelpOff.png')] private static const extensionHelpOff:Class;
	[Embed(source='UI/buttons/extensionHelpOn.png')] private static const extensionHelpOn:Class;
	[Embed(source='UI/buttons/flipOff.png')] private static const flipOff:Class;
	[Embed(source='UI/buttons/flipOn.png')] private static const flipOn:Class;
	[Embed(source='UI/buttons/fullScreenOff.png')] private static const fullscreenOff:Class;
	[Embed(source='UI/buttons/fullScreenOn.png')] private static const fullscreenOn:Class;
	[Embed(source='UI/buttons/greenFlagOff.png')] private static const greenflagOff:Class;
	[Embed(source='UI/buttons/greenFlagOn.png')] private static const greenflagOn:Class;
	[Embed(source='UI/buttons/norotationOff.png')] private static const norotationOff:Class;
	[Embed(source='UI/buttons/norotationOn.png')] private static const norotationOn:Class;
	[Embed(source='UI/buttons/playOff.png')] private static const playOff:Class;
	[Embed(source='UI/buttons/playOn.png')] private static const playOn:Class;
	[Embed(source='UI/buttons/redoOff.png')] private static const redoOff:Class;
	[Embed(source='UI/buttons/redoOn.png')] private static const redoOn:Class;
	[Embed(source='UI/buttons/revealOff.gif')] private static const revealOff:Class;
	[Embed(source='UI/buttons/revealOn.gif')] private static const revealOn:Class;
	[Embed(source='UI/buttons/rotate360Off.png')] private static const rotate360Off:Class;
	[Embed(source='UI/buttons/rotate360On.png')] private static const rotate360On:Class;
	[Embed(source='UI/buttons/spriteInfoOff.png')] private static const spriteInfoOff:Class;
	[Embed(source='UI/buttons/spriteInfoOn.png')] private static const spriteInfoOn:Class;
	[Embed(source='UI/buttons/stopOff.png')] private static const stopOff:Class;
	[Embed(source='UI/buttons/stopOn.png')] private static const stopOn:Class;
	[Embed(source='UI/buttons/toggleOff.gif')] private static const toggleOff:Class;
	[Embed(source='UI/buttons/toggleOn.gif')] private static const toggleOn:Class;
	[Embed(source='UI/buttons/undoOff.png')] private static const undoOff:Class;
	[Embed(source='UI/buttons/undoOn.png')] private static const undoOn:Class;
	[Embed(source='UI/buttons/unlockedOff.png')] private static const unlockedOff:Class;
	[Embed(source='UI/buttons/unlockedOn.png')] private static const unlockedOn:Class;
	[Embed(source='UI/buttons/stopVideoOff.gif')] private static const stopVideoOff:Class;
	[Embed(source='UI/buttons/stopVideoOn.gif')] private static const stopVideoOn:Class;

	// Misc UI Elements
	[Embed(source='UI/misc/hatshape.png')] private static const hatshape:Class;
	[Embed(source='UI/misc/playerStartFlag.png')] private static const playerStartFlag:Class;
	[Embed(source='UI/misc/promptCheckButton.png')] private static const promptCheckButton:Class;
	[Embed(source='UI/misc/questionMark.png')] private static const questionMark:Class;
	[Embed(source='UI/misc/removeItem.png')] private static const removeItem:Class;
	[Embed(source='UI/misc/speakerOff.png')] private static const speakerOff:Class;
	[Embed(source='UI/misc/speakerOn.png')] private static const speakerOn:Class;

	// New Backdrop Buttons
	[Embed(source='UI/newbackdrop/cameraSmallOff.png')] private static const cameraSmallOff:Class;
	[Embed(source='UI/newbackdrop/cameraSmallOn.png')] private static const cameraSmallOn:Class;
	[Embed(source='UI/newbackdrop/importSmallOff.png')] private static const importSmallOff:Class;
	[Embed(source='UI/newbackdrop/importSmallOn.png')] private static const importSmallOn:Class;
	[Embed(source='UI/newbackdrop/landscapeSmallOff.png')] private static const landscapeSmallOff:Class;
	[Embed(source='UI/newbackdrop/landscapeSmallOn.png')] private static const landscapeSmallOn:Class;
	[Embed(source='UI/newbackdrop/paintbrushSmallOff.png')] private static const paintbrushSmallOff:Class;
	[Embed(source='UI/newbackdrop/paintbrushSmallOn.png')] private static const paintbrushSmallOn:Class;

	// New Sprite Buttons
	[Embed(source='UI/newsprite/cameraOff.png')] private static const cameraOff:Class;
	[Embed(source='UI/newsprite/cameraOn.png')] private static const cameraOn:Class;
	[Embed(source='UI/newsprite/importOff.png')] private static const importOff:Class;
	[Embed(source='UI/newsprite/importOn.png')] private static const importOn:Class;
	[Embed(source='UI/newsprite/landscapeOff.png')] private static const landscapeOff:Class;
	[Embed(source='UI/newsprite/landscapeOn.png')] private static const landscapeOn:Class;
	[Embed(source='UI/newsprite/libraryOff.png')] private static const libraryOff:Class;
	[Embed(source='UI/newsprite/libraryOn.png')] private static const libraryOn:Class;
	[Embed(source='UI/newsprite/paintbrushOff.png')] private static const paintbrushOff:Class;
	[Embed(source='UI/newsprite/paintbrushOn.png')] private static const paintbrushOn:Class;

	// New Sound Buttons
	[Embed(source='UI/newsound/recordOff.png')] private static const recordOff:Class;
	[Embed(source='UI/newsound/recordOn.png')] private static const recordOn:Class;
	[Embed(source='UI/newsound/soundlibraryOff.png')] private static const soundlibraryOff:Class;
	[Embed(source='UI/newsound/soundlibraryOn.png')] private static const soundlibraryOn:Class;

	// Sound Editing
	[Embed(source='UI/sound/forwardOff.png')] private static const forwardSndOff:Class;
	[Embed(source='UI/sound/forwardOn.png')] private static const forwardSndOn:Class;
	[Embed(source='UI/sound/pauseOff.png')] private static const pauseSndOff:Class;
	[Embed(source='UI/sound/pauseOn.png')] private static const pauseSndOn:Class;
	[Embed(source='UI/sound/playOff.png')] private static const playSndOff:Class;
	[Embed(source='UI/sound/playOn.png')] private static const playSndOn:Class;
	[Embed(source='UI/sound/recordOff.png')] private static const recordSndOff:Class;
	[Embed(source='UI/sound/recordOn.png')] private static const recordSndOn:Class;
	[Embed(source='UI/sound/rewindOff.png')] private static const rewindSndOff:Class;
	[Embed(source='UI/sound/rewindOn.png')] private static const rewindSndOn:Class;
	[Embed(source='UI/sound/stopOff.png')] private static const stopSndOff:Class;
	[Embed(source='UI/sound/stopOn.png')] private static const stopSndOn:Class;

	// Paint
	[Embed(source='UI/paint/swatchesOff.png')] private static const swatchesOff:Class;
	[Embed(source='UI/paint/swatchesOn.png')] private static const swatchesOn:Class;
	[Embed(source='UI/paint/wheelOff.png')] private static const wheelOff:Class;
	[Embed(source='UI/paint/wheelOn.png')] private static const wheelOn:Class;

	[Embed(source='UI/paint/noZoomOff.png')] private static const noZoomOff:Class;
	[Embed(source='UI/paint/noZoomOn.png')] private static const noZoomOn:Class;
	[Embed(source='UI/paint/zoomInOff.png')] private static const zoomInOff:Class;
	[Embed(source='UI/paint/zoomInOn.png')] private static const zoomInOn:Class;
	[Embed(source='UI/paint/zoomOutOff.png')] private static const zoomOutOff:Class;
	[Embed(source='UI/paint/zoomOutOn.png')] private static const zoomOutOn:Class;

	[Embed(source='UI/paint/wicon.png')] private static const WidthIcon:Class;
	[Embed(source='UI/paint/hicon.png')] private static const HeightIcon:Class;

	[Embed(source='UI/paint/canvasGrid.gif')] private static const canvasGrid:Class;
	[Embed(source='UI/paint/segmentationAnimation/first.png')] private static const first:Class;
	[Embed(source='UI/paint/segmentationAnimation/second.png')] private static const second:Class;
	[Embed(source='UI/paint/segmentationAnimation/third.png')] private static const third:Class;
	[Embed(source='UI/paint/segmentationAnimation/fourth.png')] private static const fourth:Class;
	[Embed(source='UI/paint/segmentationAnimation/fifth.png')] private static const fifth:Class;
	[Embed(source='UI/paint/segmentationAnimation/sixth.png')] private static const sixth:Class;
	[Embed(source='UI/paint/segmentationAnimation/seventh.png')] private static const seventh:Class;
	[Embed(source='UI/paint/segmentationAnimation/eighth.png')] private static const eighth:Class;
	[Embed(source='UI/paint/colorWheel.png')] private static const colorWheel:Class;
	[Embed(source='UI/paint/swatchButton.png')] private static const swatchButton:Class;
	[Embed(source='UI/paint/rainbowButton.png')] private static const rainbowButton:Class;

	// Paint Tools
	[Embed(source='UI/paint/ellipseOff.png')] private static const ellipseOff:Class;
	[Embed(source='UI/paint/ellipseOn.png')] private static const ellipseOn:Class;
	[Embed(source='UI/paint/cropOff.png')] private static const cropOff:Class;
	[Embed(source='UI/paint/cropOn.png')] private static const cropOn:Class;
	[Embed(source='UI/paint/flipHOff.gif')] private static const flipHOff:Class;
	[Embed(source='UI/paint/flipHOn.gif')] private static const flipHOn:Class;
	[Embed(source='UI/paint/flipVOff.gif')] private static const flipVOff:Class;
	[Embed(source='UI/paint/flipVOn.gif')] private static const flipVOn:Class;
	[Embed(source='UI/paint/pathOff.png')] private static const pathOff:Class;
	[Embed(source='UI/paint/pathOn.png')] private static const pathOn:Class;
	[Embed(source='UI/paint/pencilCursor.gif')] private static const pencilCursor:Class;
	[Embed(source='UI/paint/textOff.png')] private static const textOff:Class;
	[Embed(source='UI/paint/textOn.png')] private static const textOn:Class;
	[Embed(source='UI/paint/selectOff.png')] private static const selectOff:Class;
	[Embed(source='UI/paint/selectOn.png')] private static const selectOn:Class;
	[Embed(source='UI/paint/rotateCursor.png')] private static const rotateCursor:Class;
	[Embed(source='UI/paint/eyedropperOff.png')] private static const eyedropperOff:Class;
	[Embed(source='UI/paint/eyedropperOn.png')] private static const eyedropperOn:Class;
	[Embed(source='UI/paint/setCenterOn.gif')] private static const setCenterOn:Class;
	[Embed(source='UI/paint/setCenterOff.gif')] private static const setCenterOff:Class;
	[Embed(source='UI/paint/rectSolidOn.png')] private static const rectSolidOn:Class;
	[Embed(source='UI/paint/rectSolidOff.png')] private static const rectSolidOff:Class;
	[Embed(source='UI/paint/rectBorderOn.png')] private static const rectBorderOn:Class;
	[Embed(source='UI/paint/rectBorderOff.png')] private static const rectBorderOff:Class;
	[Embed(source='UI/paint/ellipseSolidOn.png')] private static const ellipseSolidOn:Class;
	[Embed(source='UI/paint/ellipseSolidOff.png')] private static const ellipseSolidOff:Class;
	[Embed(source='UI/paint/ellipseBorderOn.png')] private static const ellipseBorderOn:Class;
	[Embed(source='UI/paint/ellipseBorderOff.png')] private static const ellipseBorderOff:Class;

	// Vector
	[Embed(source='UI/paint/vectorRectOff.png')] private static const vectorRectOff:Class;
	[Embed(source='UI/paint/vectorRectOn.png')] private static const vectorRectOn:Class;
	[Embed(source='UI/paint/vectorEllipseOff.png')] private static const vectorEllipseOff:Class;
	[Embed(source='UI/paint/vectorEllipseOn.png')] private static const vectorEllipseOn:Class;
	[Embed(source='UI/paint/vectorLineOff.png')] private static const vectorLineOff:Class;
	[Embed(source='UI/paint/vectorLineOn.png')] private static const vectorLineOn:Class;
	[Embed(source='UI/paint/patheditOff.png')] private static const patheditOff:Class;
	[Embed(source='UI/paint/patheditOn.png')] private static const patheditOn:Class;
	[Embed(source='UI/paint/groupOff.png')] private static const groupOff:Class;
	[Embed(source='UI/paint/groupOn.png')] private static const groupOn:Class;
	[Embed(source='UI/paint/ungroupOff.png')] private static const ungroupOff:Class;
	[Embed(source='UI/paint/ungroupOn.png')] private static const ungroupOn:Class;
	[Embed(source='UI/paint/frontOff.png')] private static const frontOff:Class;
	[Embed(source='UI/paint/frontOn.png')] private static const frontOn:Class;
	[Embed(source='UI/paint/backOn.png')] private static const backOn:Class;
	[Embed(source='UI/paint/backOff.png')] private static const backOff:Class;
	[Embed(source='UI/paint/paintbrushOff.png')] private static const vpaintbrushOff:Class;
	[Embed(source='UI/paint/paintbrushOn.png')] private static const vpaintbrushOn:Class;

	// Bitmap
	[Embed(source='UI/paint/rectOff.png')] private static const rectOff:Class;
	[Embed(source='UI/paint/rectOn.png')] private static const rectOn:Class;
	[Embed(source='UI/paint/paintbucketOn.png')] private static const paintbucketOn:Class;
	[Embed(source='UI/paint/paintbucketOff.png')] private static const paintbucketOff:Class;

	[Embed(source='UI/paint/editOff.png')] private static const editOff:Class;
	[Embed(source='UI/paint/editOn.png')] private static const editOn:Class;

	[Embed(source='UI/paint/sliceOn.png')] private static const sliceOn:Class;
	[Embed(source='UI/paint/sliceOff.png')] private static const sliceOff:Class;
	[Embed(source='UI/paint/wandOff.png')] private static const wandOff:Class;
	[Embed(source='UI/paint/wandOn.png')] private static const wandOn:Class;

	[Embed(source='UI/paint/eraserOn.png')] private static const eraserOn:Class;
	[Embed(source='UI/paint/eraserOff.png')] private static const eraserOff:Class;
	[Embed(source='UI/paint/saveOn.png')] private static const saveOn:Class;
	[Embed(source='UI/paint/saveOff.png')] private static const saveOff:Class;
	[Embed(source='UI/paint/cloneOff.png')] private static const cloneOff:Class;
	[Embed(source='UI/paint/cloneOn.png')] private static const cloneOn:Class;
	[Embed(source='UI/paint/lassoOn.png')] private static const lassoOn:Class;
	[Embed(source='UI/paint/lassoOff.png')] private static const lassoOff:Class;
	[Embed(source='UI/paint/lineOn.png')] private static const lineOn:Class;
	[Embed(source='UI/paint/lineOff.png')] private static const lineOff:Class;

	[Embed(source='UI/paint/bitmapBrushOff.png')] private static const bitmapBrushOff:Class;
	[Embed(source='UI/paint/bitmapBrushOn.png')] private static const bitmapBrushOn:Class;
	[Embed(source='UI/paint/bitmapEllipseOff.png')] private static const bitmapEllipseOff:Class;
	[Embed(source='UI/paint/bitmapEllipseOn.png')] private static const bitmapEllipseOn:Class;
	[Embed(source='UI/paint/bitmapPaintbucketOff.png')] private static const bitmapPaintbucketOff:Class;
	[Embed(source='UI/paint/bitmapPaintbucketOn.png')] private static const bitmapPaintbucketOn:Class;
	[Embed(source='UI/paint/bitmapRectOff.png')] private static const bitmapRectOff:Class;
	[Embed(source='UI/paint/bitmapRectOn.png')] private static const bitmapRectOn:Class;
	[Embed(source='UI/paint/bitmapSelectOff.png')] private static const bitmapSelectOff:Class;
	[Embed(source='UI/paint/bitmapSelectOn.png')] private static const bitmapSelectOn:Class;
	[Embed(source='UI/paint/magicEraserOn.png')] private static const magicEraserOn:Class;
	[Embed(source='UI/paint/magicEraserOff.png')] private static const magicEraserOff:Class;
	[Embed(source='UI/paint/bitmapStampOff.png')] private static const bitmapStampOff:Class;
	[Embed(source='UI/paint/bitmapStampOn.png')] private static const bitmapStampOn:Class;
	[Embed(source='UI/paint/bitmapTextOff.png')] private static const bitmapTextOff:Class;
	[Embed(source='UI/paint/bitmapTextOn.png')] private static const bitmapTextOn:Class;
	
	//Recording
	[Embed(source='StopArrow.png')] private static const stopArrow:Class;
	[Embed(source='VideoShare.svg')] private static const videoShare:Class;

	[Embed(source='UI/paint/moreInfoOff.png')] private static const moreInfoOff:Class;
	[Embed(source='UI/paint/moreInfoOn.png')] private static const moreInfoOn:Class;
}}
