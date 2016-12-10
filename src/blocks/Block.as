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

// Block.as
// John Maloney, August 2009
//
// A Block is a graphical object representing a program statement (command)
// or function (reporter). A stack is a sequence of command blocks, where
// the following command and any nested commands (e.g. within a loop) are
// children. Blocks come in a variety of shapes and usually have some
// combination of label strings and arguments (also children).
//
// The Block class manages block shape, labels, arguments, layout, and
// block sequence. It also supports generation of the labels and argument
// sequence from a specification string (e.g. "%n + %n") and type (e.g. reporter).

package blocks {
import assets.Resources;

import extensions.ExtensionManager;

import flash.display.*;
import flash.events.*;
import flash.filters.GlowFilter;
import flash.geom.*;
import flash.net.URLLoader;
import flash.text.*;

import scratch.*;

import translation.Translator;

import uiwidgets.*;

import util.*;

public class Block extends Sprite {

	private const minCommandWidth:int = 36;
	private const minHatWidth:int = 80;
	private const minLoopWidth:int = 80;

	public static var argTextFormat:TextFormat;
	public static var blockLabelFormat:TextFormat;
	private static var vOffset:int;

//	private static const blockLabelFormat:TextFormat = new TextFormat('LucidaBoldEmbedded', 10, 0xFFFFFF, true);
	private static var useEmbeddedFont:Boolean = false;

	public static var MenuHandlerFunction:Function;	// optional function to handle block and blockArg menus

	public var spec:String;
	public var type:String;
	public var op:String = "";
	public var opFunction:Function;
	public var args:Array = [];
	public var defaultArgValues:Array = [];
	public var parameterIndex:int = -1;	// cache of parameter index, used by GET_PARAM block
	public var parameterNames:Array;	// used by procedure definition hats; null for other blocks
	public var warpProcFlag:Boolean;	// used by procedure definition hats to indicate warp speed
	public var rightToLeft:Boolean;
	public var draggable:Boolean;

	public var isHat:Boolean = false;
	public var isAsyncHat:Boolean = false;
	public var isReporter:Boolean = false;
	public var isTerminal:Boolean = false;	// blocks that end a stack like "stop" or "forever"

	// Blocking operations
	public var isRequester:Boolean = false;
	public var forceAsync:Boolean = false;	// We've forced requester-like treatment on a non-requester block.
	public var requestState:int = 0;		// 0 - no request made, 1 - awaiting response, 2 - data ready
	public var response:* = null;
	public var requestLoader:URLLoader = null;

	public var nextBlock:Block;
	public var subStack1:Block;
	public var subStack2:Block;

	public var base:BlockShape;

	private var suppressLayout:Boolean; // used to avoid extra layouts during block initialization
	private var labelsAndArgs:Array = [];
	private var argTypes:Array = [];
	private var elseLabel:TextField;

	private var indentTop:int = 2, indentBottom:int = 3;
	private var indentLeft:int = 4, indentRight:int = 3;

	private static var ROLE_NONE:int = 0;
	private static var ROLE_ABSOLUTE:int = 1;
	private static var ROLE_EMBEDDED:int = 2;
	private static var ROLE_NEXT:int = 3;
	private static var ROLE_SUBSTACK1:int = 4;
	private static var ROLE_SUBSTACK2:int = 5;

	private var originalParent:DisplayObjectContainer, originalRole:int, originalIndex:int, originalPosition:Point;

	public function Block(spec:String, type:String = " ", color:int = 0xD00000, op:* = 0, defaultArgs:Array = null) {
		this.spec = Translator.map(spec);
		this.type = type;
		this.op = op;

		if ((Specs.CALL == op) ||
			(Specs.GET_LIST == op) ||
			(Specs.GET_PARAM == op) ||
			(Specs.GET_VAR == op) ||
			(Specs.PROCEDURE_DEF == op) ||
			('proc_declaration' == op)) {
				this.spec = spec; // don't translate var/list/param reporters
		}

		if (color == -1) return; // copy for clone; omit graphics

		var shape:int;
		if ((type == " ") || (type == "") || (type == "w")) {
			base = new BlockShape(BlockShape.CmdShape, color);
			indentTop = 3;
		} else if (type == "b") {
			base = new BlockShape(BlockShape.BooleanShape, color);
			isReporter = true;
			forceAsync = Scratch.app.extensionManager.shouldForceAsync(op);
			isRequester = forceAsync;
			indentLeft = 9;
			indentRight = 7;
		} else if (type == "r" || type == "R") {
			this.type = 'r';
			base = new BlockShape(BlockShape.NumberShape, color);
			isReporter = true;
			forceAsync = (type == 'r') && Scratch.app.extensionManager.shouldForceAsync(op);
			isRequester = (type == 'R') || forceAsync;
			indentTop = 2;
			indentBottom = 2;
			indentLeft = 6;
			indentRight = 4;
		} else if (type == "h" || type == 'H') {
			base = new BlockShape(BlockShape.HatShape, color);
			isHat = true;
			forceAsync = (type == 'h') && Scratch.app.extensionManager.shouldForceAsync(op);
			isAsyncHat = (type == 'H') || forceAsync;
			indentTop = 12;
		}
		else if (type == "c") {
			base = new BlockShape(BlockShape.LoopShape, color);
		} else if (type == "cf") {
			base = new BlockShape(BlockShape.FinalLoopShape, color);
			isTerminal = true;
		} else if (type == "e") {
			base = new BlockShape(BlockShape.IfElseShape, color);
			addChild(elseLabel = makeLabel(Translator.map('else')));
		} else if (type == "f") {
			base = new BlockShape(BlockShape.FinalCmdShape, color);
			isTerminal = true;
			indentTop = 5;
		} else if (type == "o") { // cmd outline for proc definition
			base = new BlockShape(BlockShape.CmdOutlineShape, color);
			base.filters = []; // no bezel
			indentTop = 3;
		} else if (type == "p") {
			base = new BlockShape(BlockShape.ProcHatShape, color);
			isHat = true;
		} else {
			base = new BlockShape(BlockShape.RectShape, color);
		}
		addChildAt(base, 0);
		setSpec(this.spec, defaultArgs);
		draggable = true;

		addEventListener(FocusEvent.KEY_FOCUS_CHANGE, focusChange);
	}

	public function setSpec(newSpec:String, defaultArgs:Array = null):void {
		for each (var o:DisplayObject in labelsAndArgs) {
			if (o.parent != null) o.parent.removeChild(o);
		}
		spec = newSpec;
		if (op == Specs.PROCEDURE_DEF) {
			// procedure hat: make an icon from my spec and use that as the label
			indentTop = 20;
			indentBottom = 5;
			indentLeft = 5;
			indentRight = 5;

			labelsAndArgs = [];
			argTypes = [];
			var label:TextField = makeLabel(Translator.map('define'));
			labelsAndArgs.push(label);
			var b:Block;
			labelsAndArgs.push(b = declarationBlock());
		} else if (op == Specs.GET_VAR || op == Specs.GET_LIST) {
			labelsAndArgs = [makeLabel(spec)];
		} else {
			const loopBlocks:Array = ['doForever', 'doForeverIf', 'doRepeat', 'doUntil'];
			base.hasLoopArrow = (loopBlocks.indexOf(op) >= 0);
			addLabelsAndArgs(spec, base.color);
		}
		rightToLeft = Translator.rightToLeft;
		if (rightToLeft) {
			if (['+', '-', '*', '/', '%'].indexOf(op) > -1) rightToLeft = Translator.rightToLeftMath;
			if (['>', '<'].indexOf(op) > -1) rightToLeft = false; // never change order of comparison ops
		}
		if (rightToLeft) {
			// reverse specs that don't start with arg specifier or an ASCII character
			labelsAndArgs.reverse();
			argTypes.reverse();
			if (defaultArgs) defaultArgs.reverse();
		}
		for each (var item:* in labelsAndArgs) addChild(item);
		if (defaultArgs) setDefaultArgs(defaultArgs);
		fixArgLayout();
	}

	public function get broadcastMsg():String {
		for each (var arg:Object in args) {
			if (arg is BlockArg && arg.menuName == "broadcast") {
				return arg.argValue;
			}
		}

		return null;
	}

	public function set broadcastMsg(listName:String):void {
		for each (var arg:Object in args) {
			if (arg is BlockArg && arg.menuName == "broadcast") {
				arg.setArgValue(listName);
			}
		}
	}

	// Convert a left-to-right argument index into a current argument index:
	// - If the block is LTR, then return the index as it is,
	// - Otherwise count back from the end to return the new index.
	public function getNormalizedArgIndex(ltrIndex:int):int {
		return rightToLeft ? args.length - 1 - ltrIndex : ltrIndex;
	}

	// Retrieve the argument which would have the given index in LTR mode,
	// regardless of whether this block is currently LTR or RTL.
	public function getNormalizedArg(ltrIndex:int):* {
		return args[getNormalizedArgIndex(ltrIndex)];
	}

	public function normalizedArgs():Array {
		return rightToLeft ? args.concat().reverse() : args;
	}

	public function changeOperator(newOp:String):void {
		// Used to switch among a family of related operators (e.g. +, -, *, and /).
		// Note: This does not deal with translation, so it only works for symbolic operators.
		for each (var item:* in labelsAndArgs) {
			if ((item is TextField) && (item.text == op)) item.text = newOp;
		}
		op = newOp;
		opFunction = null;
		fixArgLayout();
	}

	public static function setFonts(labelSize:int, argSize:int, boldFlag:Boolean, vOffset:int):void {
		var font:String = Resources.chooseFont([
			'Lucida Grande', 'Verdana', 'Arial', 'DejaVu Sans']);
		blockLabelFormat = new TextFormat(font, labelSize, 0xFFFFFF, boldFlag);
		argTextFormat = new TextFormat(font, argSize, 0x505050, false);
		Block.vOffset = vOffset;
	}

	private function declarationBlock():Block {
		// Create a block representing a procedure declaration to be embedded in a
		// procedure definition header block. For each formal parameter, embed a
		// reporter for that parameter.
		var b:Block = new Block(spec, "o", Specs.procedureColor, 'proc_declaration');
		if (!parameterNames) parameterNames = [];
		for (var i:int = 0; i < parameterNames.length; i++) {
			var argType:String = (typeof(defaultArgValues[i]) == 'boolean') ? 'b' : 'r';
			var pBlock:Block = new Block(parameterNames[i], argType, Specs.parameterColor, Specs.GET_PARAM);
			pBlock.parameterIndex = i;
			b.setArg(i, pBlock);
		}
		b.fixArgLayout();
		return b;
	}

	public function isProcDef():Boolean { return op == Specs.PROCEDURE_DEF }

	public function isEmbeddedInProcHat():Boolean {
		return (parent is Block) &&
			(Block(parent).op == Specs.PROCEDURE_DEF) &&
			(this != Block(parent).nextBlock);
	}

	public function isEmbeddedParameter():Boolean {
		if ((op != Specs.GET_PARAM) || !(parent is Block)) return false;
		return Block(parent).op == 'proc_declaration';
	}

	public function isInPalette():Boolean {
		var o:DisplayObject = parent;
		while (o) {
			if ('isBlockPalette' in o) return true;
			o = o.parent;
		}
		return false;
	}

	public function setTerminal(flag:Boolean):void {
		// Used to change the "stop" block shape.
		removeChild(base);
		isTerminal = flag;
		var newShape:int = isTerminal ? BlockShape.FinalCmdShape : BlockShape.CmdShape;
		base = new BlockShape(newShape, base.color);
		addChildAt(base, 0);
		fixArgLayout();
	}

	private function addLabelsAndArgs(spec:String, c:int):void {
		var specParts:Array = ReadStream.tokenize(spec), i:int;
		labelsAndArgs = [];
		argTypes = [];
		for (i = 0; i < specParts.length; i++) {
			var o:DisplayObject = argOrLabelFor(specParts[i], c);
			labelsAndArgs.push(o);
			var argType:String = 'icon';
			if (o is BlockArg) argType = specParts[i];
			if (o is TextField) argType = 'label';
			argTypes.push(argType);
		}
	}

	public function argType(arg:DisplayObject):String {
		var i:int = labelsAndArgs.indexOf(arg);
		return i == -1 ? '' : argTypes[i];
	}

	public function allBlocksDo(f:Function):void {
		f(this);
		for each (var arg:* in args) {
			if (arg is Block) arg.allBlocksDo(f);
		}
		if (subStack1 != null) subStack1.allBlocksDo(f);
		if (subStack2 != null) subStack2.allBlocksDo(f);
		if (nextBlock != null) nextBlock.allBlocksDo(f);
	}

	public function showRunFeedback():void {
		if (filters && filters.length > 0) {
			for each (var f:* in filters) {
				if (f is GlowFilter) return;
			}
		}
		filters = runFeedbackFilters().concat(filters || []);
	}

	public function hideRunFeedback():void {
		if (filters && filters.length > 0) {
			var newFilters:Array = [];
			for each (var f:* in filters) {
				if (!(f is GlowFilter)) newFilters.push(f);
			}
			filters = newFilters;
		}
	}

	private function runFeedbackFilters():Array {
		// filters for showing that a stack is running
		var f:GlowFilter = new GlowFilter(0xfeffa0);
		f.strength = 2;
		f.blurX = f.blurY = 12;
		f.quality = 3;
		return [f];
	}

	public function saveOriginalState():void {
		originalParent = parent;
		if (parent) {
			var b:Block = parent as Block;
			if (b == null) {
				originalRole = ROLE_ABSOLUTE;
			} else if (isReporter) {
				originalRole = ROLE_EMBEDDED;
				originalIndex = b.args.indexOf(this);
			} else if (b.nextBlock == this) {
				originalRole = ROLE_NEXT;
			} else if (b.subStack1 == this) {
				originalRole = ROLE_SUBSTACK1;
			} else if (b.subStack2 == this) {
				originalRole = ROLE_SUBSTACK2;
			}
			originalPosition = localToGlobal(new Point(0, 0));
		} else {
			originalRole = ROLE_NONE;
			originalPosition = null;
		}
	}

	public function restoreOriginalState():void {
		var b:Block = originalParent as Block;
		scaleX = scaleY = 1;
		switch (originalRole) {
		case ROLE_NONE:
			if (parent) parent.removeChild(this);
			break;
		case ROLE_ABSOLUTE:
			originalParent.addChild(this);
			var p:Point = originalParent.globalToLocal(originalPosition);
			x = p.x;
			y = p.y;
			break;
		case ROLE_EMBEDDED:
			b.replaceArgWithBlock(b.args[originalIndex], this, Scratch.app.scriptsPane);
			break;
		case ROLE_NEXT:
			b.insertBlock(this);
			break;
		case ROLE_SUBSTACK1:
			b.insertBlockSub1(this);
			break;
		case ROLE_SUBSTACK2:
			b.insertBlockSub2(this);
			break;
		}
	}

	public function originalPositionIn(p:DisplayObject):Point {
		return originalPosition && p.globalToLocal(originalPosition);
	}

	private function setDefaultArgs(defaults:Array):void {
		collectArgs();
		for (var i:int = 0; i < Math.min(args.length, defaults.length); i++) {
			var argLabel:String = null;
			var v:* = defaults[i];
			if (v is BlockArg) v = BlockArg(v).argValue;
			if ('_edge_' == v) argLabel = Translator.map('edge');
			if ('_mouse_' == v) argLabel = Translator.map('mouse-pointer');
			if ('_myself_' == v) argLabel = Translator.map('myself');
			if ('_stage_' == v) argLabel = Translator.map('Stage');
			if ('_random_' == v) argLabel = Translator.map('random position');
			if (args[i] is BlockArg) args[i].setArgValue(v, argLabel);
		}
		defaultArgValues = defaults;
	}

	public function setArg(i:int, newArg:*):void {
		// called on newly-created block (assumes argument being set is a BlockArg)
		// newArg can be either a reporter block or a literal value (string, number, etc.)
		collectArgs();
		if (i >= args.length) return;
		var oldArg:BlockArg = args[i];
		if (newArg is Block) {
			labelsAndArgs[labelsAndArgs.indexOf(oldArg)] = newArg;
			args[i] = newArg;
			removeChild(oldArg);
			addChild(newArg);
		} else {
			oldArg.setArgValue(newArg);
		}
	}

	public function fixExpressionLayout():void {
		// fix expression layout up to the enclosing command block
		var b:Block = this;
		while (b.isReporter) {
			b.fixArgLayout();
			if (b.parent is Block) b = Block(b.parent)
			else return;
		}
		if (b is Block) b.fixArgLayout();
	}

	public function fixArgLayout():void {
		var item:DisplayObject, i:int;
		if (suppressLayout) return;
		var x:int = indentLeft - indentAjustmentFor(labelsAndArgs[0]);
		var maxH:int = 0;
		for (i = 0; i < labelsAndArgs.length; i++) {
			item = labelsAndArgs[i];
			// Next line moves the argument of if and if-else blocks right slightly:
			if ((i == 1) && !(argTypes[i] == 'label')) x = Math.max(x, 30);
			item.x = x;
			maxH = Math.max(maxH, item.height);
			x += item.width + 2;
			if (argTypes[i] == 'icon') x += 3;
		}
		x -= indentAjustmentFor(labelsAndArgs[labelsAndArgs.length - 1]);

		for (i = 0; i < labelsAndArgs.length; i++) {
			item = labelsAndArgs[i];
			item.y = indentTop + ((maxH - item.height) / 2) + vOffset;
			if ((item is BlockArg) && (!BlockArg(item).numberType)) item.y += 1;
		}

		if ([' ', '', 'o'].indexOf(type) >= 0) x = Math.max(x, minCommandWidth); // minimum width for command blocks
		if (['c', 'cf', 'e'].indexOf(type) >= 0) x = Math.max(x, minLoopWidth); // minimum width for C and E blocks
		if (['h'].indexOf(type) >= 0) x = Math.max(x, minHatWidth); // minimum width for hat blocks
		if (elseLabel) x = Math.max(x, indentLeft + elseLabel.width + 2);

		base.setWidthAndTopHeight(x + indentRight, indentTop + maxH + indentBottom);
		if ((type == "c") || (type == "e")) fixStackLayout();
		base.redraw();
		fixElseLabel();
		collectArgs();
	}

	private function indentAjustmentFor(item:*):int {
		var itemType:String = '';
		if (item is Block) itemType = Block(item).type;
		if (item is BlockArg) itemType = BlockArg(item).type;
		if ((type == 'b') && (itemType == 'b')) return 4;
		if ((type == 'r') && ((itemType == 'r') || (itemType == 'd') || (itemType == 'n'))) return 2;
		return 0;
	}

	public function fixStackLayout():void {
		var b:Block = this;
		while (b != null) {
			if (b.base.canHaveSubstack1()) {
				var substackH:int = BlockShape.EmptySubstackH;
				if (b.subStack1) {
					b.subStack1.fixStackLayout();
					b.subStack1.x = BlockShape.SubstackInset;
					b.subStack1.y = b.base.substack1y();
					substackH = b.subStack1.getRect(b).height;
					if (b.subStack1.bottomBlock().isTerminal) substackH += BlockShape.NotchDepth;
				}
				b.base.setSubstack1Height(substackH);
				substackH = BlockShape.EmptySubstackH;
				if (b.subStack2) {
					b.subStack2.fixStackLayout();
					b.subStack2.x = BlockShape.SubstackInset;
					b.subStack2.y = b.base.substack2y();
					substackH = b.subStack2.getRect(b).height;
					if (b.subStack2.bottomBlock().isTerminal) substackH += BlockShape.NotchDepth;
				}
				b.base.setSubstack2Height(substackH);
				b.base.redraw();
				b.fixElseLabel();
			}
			if (b.nextBlock != null) {
				b.nextBlock.x = 0;
				b.nextBlock.y = b.base.nextBlockY();
			}
			b = b.nextBlock;
		}
	}

	private function fixElseLabel():void {
		if (elseLabel) {
			var metrics:TextLineMetrics = elseLabel.getLineMetrics(0);
			var dy:int = (metrics.ascent + metrics.descent) / 2;
			elseLabel.x = 4;
			elseLabel.y = base.substack2y() - 11 - dy + vOffset;
		}
	}

	public function previewSubstack1Height(h:int):void {
		base.setSubstack1Height(h);
		base.redraw();
		fixElseLabel();
		if (nextBlock) nextBlock.y = base.nextBlockY();
	}

	public function duplicate(forClone:Boolean, forStage:Boolean = false):Block {
		var newSpec:String = spec;
		if (op == 'whenClicked') newSpec = forStage ? 'when Stage clicked' : 'when this sprite clicked';
		var dup:Block = new Block(newSpec, type, (int)(forClone ? -1 : base.color), op);
		dup.isRequester = isRequester;
		dup.forceAsync = forceAsync;
		dup.parameterNames = parameterNames;
		dup.defaultArgValues = defaultArgValues;
		dup.warpProcFlag = warpProcFlag;
		if (forClone) {
			dup.copyArgsForClone(args);
		} else {
			dup.copyArgs(args);
			if (op == 'stopScripts' && args[0] is BlockArg) {
				if(args[0].argValue.indexOf('other scripts') == 0) {
					if (forStage) dup.args[0].setArgValue('other scripts in stage');
					else dup.args[0].setArgValue('other scripts in sprite');
				}
			}
		}
		if (nextBlock != null) dup.addChild(dup.nextBlock = nextBlock.duplicate(forClone, forStage));
		if (subStack1 != null) dup.addChild(dup.subStack1 = subStack1.duplicate(forClone, forStage));
		if (subStack2 != null) dup.addChild(dup.subStack2 = subStack2.duplicate(forClone, forStage));
		if (!forClone) {
			dup.x = x;
			dup.y = y;
			dup.fixExpressionLayout();
			dup.fixStackLayout();
		}
		return dup;
	}

	private function copyArgs(srcArgs:Array):void {
		// called on a newly created block that is being duplicated to copy the
		// argument values and/or expressions from the source block's arguments
		var i:int;
		collectArgs();
		for (i = 0; i < srcArgs.length; i++) {
			var argToCopy:* = srcArgs[i];
			if (argToCopy is BlockArg) {
				var arg:BlockArg = argToCopy;
				BlockArg(args[i]).setArgValue(arg.argValue, arg.labelOrNull());
			}
			if (argToCopy is Block) {
				var newArg:Block = Block(argToCopy).duplicate(false);
				var oldArg:* = args[i];
				labelsAndArgs[labelsAndArgs.indexOf(oldArg)] = newArg;
				args[i] = newArg;
				removeChild(oldArg);
				addChild(newArg);
			}
		}
	}

	private function copyArgsForClone(srcArgs:Array):void {
		// called on a block that is being cloned.
		args = [];
		for (var i:int = 0; i < srcArgs.length; i++) {
			var argToCopy:* = srcArgs[i];
			if (argToCopy is BlockArg) {
				var a:BlockArg = new BlockArg(argToCopy.type, -1);
				a.argValue = argToCopy.argValue;
				args.push(a);
			}
			if (argToCopy is Block) {
				args.push(Block(argToCopy).duplicate(true));
			}
		}
		for each (var arg:DisplayObject in args) addChild(arg); // fix for cloned proc bug xxx
	}

	private function collectArgs():void {
		var i:int;
		args = [];
		if (isRequester && requestState == 2) {
			// Assume this means that our args have changed. See https://github.com/LLK/scratchx/issues/61
			requestState = 0;
		}
		for (i = 0; i < labelsAndArgs.length; i++) {
			var a:* = labelsAndArgs[i];
			if ((a is Block) || (a is BlockArg)) args.push(a);
		}
	}

	public function removeBlock(b:Block):void {
		if (b.parent == this) removeChild(b);
		if (b == nextBlock) {
			nextBlock = null;
		}
		if (b == subStack1) subStack1 = null;
		if (b == subStack2) subStack2 = null;
		if (b.isReporter) {
			var i:int = labelsAndArgs.indexOf(b);
			if (i < 0) return;
			var newArg:DisplayObject = argOrLabelFor(argTypes[i], base.color);
			labelsAndArgs[i] = newArg;
			addChild(newArg);
			fixExpressionLayout();

			// Cancel any outstanding requests (for blocking reporters, isRequester=true)
			if(b.requestLoader)
				b.requestLoader.close();
		}
		topBlock().fixStackLayout();
		SCRATCH::allow3d { Scratch.app.runtime.checkForGraphicEffects(); }
	}

	public function insertBlock(b:Block):void {
		var oldNext:Block = nextBlock;

		if (oldNext != null) removeChild(oldNext);

		addChild(b);
		nextBlock = b;
		if (oldNext != null) b.appendBlock(oldNext);

		topBlock().fixStackLayout();
	}

	public function insertBlockAbove(b:Block):void {
		b.x = this.x;
		b.y = this.y - b.height + BlockShape.NotchDepth;
		parent.addChild(b);
		b.bottomBlock().insertBlock(this);
	}

	public function insertBlockAround(b:Block):void {
		b.x = this.x - BlockShape.SubstackInset;
		b.y = this.y - b.base.substack1y(); //  + BlockShape.NotchDepth;
		parent.addChild(b);
		parent.removeChild(this);
		b.addChild(this);
		b.subStack1 = this;
		b.fixStackLayout();
	}

	public function insertBlockSub1(b:Block):void {
		var old:Block = subStack1;
		if (old != null) old.parent.removeChild(old);

		addChild(b);
		subStack1 = b;
		if (old != null) b.appendBlock(old);
		topBlock().fixStackLayout();
	}

	public function insertBlockSub2(b:Block):void {
		var old:Block = subStack2;
		if (old != null) removeChild(old);

		addChild(b);
		subStack2 = b;
		if (old != null) b.appendBlock(old);
		topBlock().fixStackLayout();
	}

	public function replaceArgWithBlock(oldArg:DisplayObject, b:Block, pane:DisplayObjectContainer):void {
		var i:int = labelsAndArgs.indexOf(oldArg);
		if (i < 0) return;

		// remove the old argument
		removeChild(oldArg);
		labelsAndArgs[i] = b;
		addChild(b);
		fixExpressionLayout();

		if (oldArg is Block) {
			// leave old block in pane
			var o:Block = owningBlock();
			var p:Point = pane.globalToLocal(o.localToGlobal(new Point(o.width + 5, (o.height - oldArg.height) / 2)));
			oldArg.x = p.x;
			oldArg.y = p.y;
			pane.addChild(oldArg);
		}
		topBlock().fixStackLayout();
	}

	private function appendBlock(b:Block):void {
		if (base.canHaveSubstack1() && !subStack1) {
			insertBlockSub1(b);
		} else {
			var bottom:Block = bottomBlock();
			bottom.addChild(b);
			bottom.nextBlock = b;
		}
	}

	private function owningBlock():Block {
		var b:Block = this;
		while (true) {
			if (b.parent is Block) {
				b = Block(b.parent);
				if (!b.isReporter) return b; // owning command block
			} else {
				return b; // top-level reporter block
			}
		}
		return b; // never gets here
	}

	public function topBlock():Block {
		var result:DisplayObject = this;
		while (result.parent is Block) result = result.parent;
		return Block(result);
	}

	public function bottomBlock():Block {
		var result:Block = this;
		while (result.nextBlock!= null) result = result.nextBlock;
		return result;
	}

	private function argOrLabelFor(s:String, c:int):DisplayObject {
		// Possible token formats:
		//	%<single letter>
		//	%m.<menuName>
		//	@<iconName>
		//	label (any string with no embedded white space that does not start with % or @)
		//	a token consisting of a single % or @ character is also a label
		if (s.length >= 2 && s.charAt(0) == "%") { // argument spec
			var argSpec:String = s.charAt(1);
			if (argSpec == "b") return new BlockArg("b", c);
			if (argSpec == "c") return new BlockArg("c", c);
			if (argSpec == "d") return new BlockArg("d", c, true, s.slice(3));
			if (argSpec == "m") return new BlockArg("m", c, false, s.slice(3));
			if (argSpec == "n") return new BlockArg("n", c, true);
			if (argSpec == "s") return new BlockArg("s", c, true);
		} else if (s.length >= 2 && s.charAt(0) == "@") { // icon spec
			var icon:* = Specs.IconNamed(s.slice(1));
			return (icon) ? icon : makeLabel(s);
		}
		return makeLabel(ReadStream.unescape(s));
	}

	private function makeLabel(label:String):TextField {
		var text:TextField = new TextField();
		text.autoSize = TextFieldAutoSize.LEFT;
		text.selectable = false;
		text.background = false;
		text.defaultTextFormat = blockLabelFormat;
		text.text = label;
		if (useEmbeddedFont) {
			text.antiAliasType = AntiAliasType.ADVANCED;
			text.embedFonts = true;
		}
		text.mouseEnabled = false;
		return text;
	}

	/* Menu */

	public function menu(evt:MouseEvent):void {
		// Note: Unlike most menu() methods, this method invokes
		// the menu itself rather than returning a menu to the caller.
		if (MenuHandlerFunction == null) return;
		if (isEmbeddedInProcHat()) MenuHandlerFunction(null, parent);
		else MenuHandlerFunction(null, this);
	}

	public function handleTool(tool:String, evt:MouseEvent):void {
		if (isEmbeddedParameter()) return;
		if (!isInPalette()) {
			if ('copy' == tool) duplicateStack(10, 5);
			if ('cut' == tool) deleteStack();
		}
		if (tool == 'help') showHelp();
	}

	public function showHelp():void {
		var extName:String = ExtensionManager.unpackExtensionName(op);
		if (extName) {
			if (Scratch.app.extensionManager.isInternal(extName)) {
				Scratch.app.showTip('ext:' + extName);
			}
			else {
				DialogBox.notify(
						'Help Missing',
						'There is no documentation available for experimental extension "' + extName + '".',
						Scratch.app.stage);
			}
		}
		else {
			Scratch.app.showTip(op);
		}
	}

	public function duplicateStack(deltaX:Number, deltaY:Number):void {
		if (isProcDef() || op == 'proc_declaration') return; // don't duplicate procedure definition
		var forStage:Boolean = Scratch.app.viewedObj() && Scratch.app.viewedObj().isStage;
		var newStack:Block = BlockIO.stringToStack(BlockIO.stackToString(this), forStage);
		var p:Point = localToGlobal(new Point(0, 0));
		newStack.x = p.x + deltaX;
		newStack.y = p.y + deltaY;
		Scratch.app.gh.grabOnMouseUp(newStack);
	}

	public function deleteStack():Boolean {
		if (op == 'proc_declaration') {
			return (parent as Block).deleteStack();
		}
		var app:Scratch = Scratch.app;
		var top:Block = topBlock();
		if (op == Specs.PROCEDURE_DEF && app.runtime.allCallsOf(spec, app.viewedObj(), false).length) {
			DialogBox.notify('Cannot Delete', 'To delete a block definition, first remove all uses of the block.', stage);
			return false;
		}
		if (top == this && app.interp.isRunning(top, app.viewedObj())) {
			app.interp.toggleThread(top, app.viewedObj());
		}
		// TODO: Remove any waiting reporter data in the Scratch.app.extensionManager
		if (parent is Block) Block(parent).removeBlock(this);
		else if (parent) parent.removeChild(this);

		// Remove from the Scratch object that holds the block, if it's in the
		// object's script array
		var obj:ScratchObj = app.viewedObj();
		var index:int = obj.scripts.indexOf(this);
		if (index >= 0) {
			obj.scripts.splice(index, 1);
		}

		this.cacheAsBitmap = false;
		// set position for undelete
		x = top.x;
		y = top.y;
		if (top != this) x += top.width + 5;
		app.runtime.recordForUndelete(this, x, y, 0, app.viewedObj());
		app.scriptsPane.saveScripts();
		SCRATCH::allow3d { app.runtime.checkForGraphicEffects(); }
		app.updatePalette();
		return true;
	}

	public function attachedCommentsIn(scriptsPane:ScriptsPane):Array {
		var allBlocks:Array = [];
		allBlocksDo(function (b:Block):void {
			allBlocks.push(b);
		});
		var result:Array = []
		if (!scriptsPane) return result;
		for (var i:int = 0; i < scriptsPane.numChildren; i++) {
			var c:ScratchComment = scriptsPane.getChildAt(i) as ScratchComment;
			if (c && c.blockRef && allBlocks.indexOf(c.blockRef) != -1) {
				result.push(c);
			}
		}
		return result;
	}

	public function addComment():void {
		var scriptsPane:ScriptsPane = topBlock().parent as ScriptsPane;
		if (scriptsPane) scriptsPane.addComment(this);
	}

	/* Dragging */

	public function objToGrab(evt:MouseEvent):Block {
		if (!draggable) return null;
		if (isEmbeddedParameter() || isInPalette()) return duplicate(false, Scratch.app.viewedObj() is ScratchStage);
		return this;
	}

	/* Events */

	public var clickOverride:Function;

	public function click(evt:MouseEvent):void {
		if (clickOverride) {
			clickOverride();
			return;
		}

		if (editArg(evt)) return;
		Scratch.app.runtime.interp.toggleThread(topBlock(), Scratch.app.viewedObj(), 1);
	}

	public function demo():void{
		//make a test duplicate and exec
		var b:Block = this.duplicate(false);
		b.nextBlock = null;
		b.visible = false;
		Scratch.app.runtime.interp.toggleThread(b, Scratch.app.viewedObj(), 1);
	}

	public function doubleClick(evt:MouseEvent):void {
		if (editArg(evt)) return;
		Scratch.app.runtime.interp.toggleThread(topBlock(), Scratch.app.viewedObj(), 1);
	}

	private function editArg(evt:MouseEvent):Boolean {
		var arg:BlockArg = evt.target as BlockArg;
		if (!arg) arg = evt.target.parent as BlockArg;
		if (arg && arg.isEditable && (arg.parent == this)) {
			arg.startEditing();
			return true;
		}
		return false;
	}

	private function focusChange(evt:FocusEvent):void {
		evt.preventDefault();
		if (evt.target.parent.parent != this) return; // make sure the target TextField is in this block, not a child block
		if (args.length == 0) return;
		var i:int, focusIndex:int = -1;
		for (i = 0; i < args.length; i++) {
			if (args[i] is BlockArg && stage.focus == args[i].field) focusIndex = i;
		}
		var target:Block = this;
		var delta:int = evt.shiftKey ? -1 : 1;
		i = focusIndex + delta;
		for (;;) {
			if (i >= target.args.length) {
				var p:Block = target.parent as Block;
				if (p) {
					i = p.args.indexOf(target);
					if (i != -1) {
						i += delta;
						target = p;
						continue;
					}
				}
				if (target.subStack1) {
					target = target.subStack1;
				} else if (target.subStack2) {
					target = target.subStack2;
				} else {
					var t:Block = target;
					target = t.nextBlock;
					while (!target) {
						var tp:Block = t.parent as Block;
						var b:Block = t;
						while (tp && tp.nextBlock == b) {
							b = tp;
							tp = tp.parent as Block;
						}
						if (!tp) return;
						target = tp.subStack1 == b && tp.subStack2 ? tp.subStack2 : tp.nextBlock;
						t = tp;
					}
				}
				i = 0;
			} else if (i < 0) {
				p = target.parent as Block;
				if (!p) return;
				i = p.args.indexOf(target);
				if (i != -1) {
					i += delta;
					target = p;
					continue;
				}
				var nested:Block = p.nextBlock == target ? p.subStack2 || p.subStack1 : p.subStack2 == target ? p.subStack1 : null;
				if (nested) {
					for (;;) {
						nested = nested.bottomBlock();
						var n2:Block = nested.subStack1 || nested.subStack2;
						if (!n2) break;
						nested = n2;
					}
					target = nested;
				} else {
					target = p;
				}
				i = target.args.length - 1;
			} else {
				if (target.args[i] is Block) {
					target = target.args[i];
					i = evt.shiftKey ? target.args.length - 1 : 0;
				} else {
					var a:BlockArg = target.args[i] as BlockArg;
					if (a && a.field && a.isEditable) {
						a.startEditing();
						return;
					}
					i += delta;
				}
			}
		}
	}

	public function getSummary():String {
		var s:String = type == "r" ? "(" : type == "b" ? "<" : "";
		var space:Boolean = false;
		for each (var x:DisplayObject in labelsAndArgs) {
			if (space) {
				s += " ";
			}
			space = true;
			var ba:BlockArg, b:Block, tf:TextField;
			if ((ba = x as BlockArg)) {
				s += ba.numberType ? "(" : "[";
				s += ba.argValue;
				if (!ba.isEditable) s += " v";
				s += ba.numberType ? ")" : "]";
			} else if ((b = x as Block)) {
				s += b.getSummary();
			} else if ((tf = x as TextField)) {
				s += TextField(x).text;
			} else {
				s += "@";
			}
		}
		if (base.canHaveSubstack1()) {
			s += "\n" + (subStack1 ? indent(subStack1.getSummary()) : "");
			if (base.canHaveSubstack2()) {
				s += "\n" + elseLabel.text;
				s += "\n" + (subStack2 ? indent(subStack2.getSummary()) : "");
			}
			s += "\n" + Translator.map("end");
		}
		if (nextBlock) {
			s += "\n" + nextBlock.getSummary();
		}
		s += type == "r" ? ")" : type == "b" ? ">" : "";
		return s;
	}

	protected static function indent(s:String):String {
		return s.replace(/^/gm, "    ");
	}

}}
