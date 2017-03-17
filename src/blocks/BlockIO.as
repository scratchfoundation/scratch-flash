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

// BlockIO.as
// John Maloney, September 2010
//
// Convert blocks and stacks to/from an array structure or JSON string format.
// The array structure format captures the meaning of scripts in a compact form that
// is independent of the internal representation and is easy to convert to/from JSON.

package blocks {
	import scratch.*;
	import util.*;
	import translation.*;

public class BlockIO {

	public static function stackToString(b:Block):String {
		return util.JSON.stringify(stackToArray(b));
	}

	public static function stringToStack(s:String, forStage:Boolean = false):Block {
		return arrayToStack(util.JSON.parse(s) as Array, forStage);
	}

	public static function stackToArray(b:Block):Array {
		// Return an array structure representing this entire stack.
		if (b == null) return null;
		var result:Array = [];
		while (b != null) {
			result.push(blockToArray(b));
			b = b.nextBlock;
		}
		return result;
	}

	public static function arrayToStack(cmdList:Array, forStage:Boolean = false):Block {
		// Return the stack represented by an array structure.
		var topBlock:Block, lastBlock:Block;
		for each (var cmd:Array in cmdList) {
			var b:Block = null;
			try { b = arrayToBlock(cmd, '', forStage) } catch (e:*) { b = new Block('undefined') }
			if (topBlock == null) topBlock = b;
			if (lastBlock != null) lastBlock.insertBlock(b);
			lastBlock = b;
		}
		return topBlock;
	}

	private static function blockToArray(b:Block):Array {
		// Return an array structure for this block.
		var result:Array = [b.op];
		if (b.op == Specs.GET_VAR) return [Specs.GET_VAR, b.spec];		// variable reporter
		if (b.op == Specs.GET_LIST) return [Specs.GET_LIST, b.spec];	// list reporter
		if (b.op == Specs.GET_PARAM) return [Specs.GET_PARAM, b.spec, b.type]; // parameter reporter
		if (b.op == Specs.PROCEDURE_DEF)								// procedure definition
			return [Specs.PROCEDURE_DEF, b.spec, b.parameterNames, b.defaultArgValues, b.warpProcFlag];
		if (b.op == Specs.CALL) result = [Specs.CALL, b.spec];			// procedure call - arguments follow spec
		for each (var a:* in b.normalizedArgs()) {
			// Note: arguments are always saved in normalized (i.e. left-to-right) order
			if (a is Block) result.push(blockToArray(a));
			if (a is BlockArg) {
				var argVal:* = BlockArg(a).argValue;
				if (argVal is ScratchObj) {
					// convert a Scratch sprite/stage reference to a name string
					argVal = ScratchObj(argVal).objName;
				}
				result.push(argVal);
			}
		}
		if (b.base.canHaveSubstack1()) result.push(stackToArray(b.subStack1));
		if (b.base.canHaveSubstack2()) result.push(stackToArray(b.subStack2));
		return result;
	}

	private static function arrayToBlock(cmd:Array, undefinedBlockType:String, forStage:Boolean = false):Block {
		// Make a block from an array of form: <op><arg>*

		if (cmd[0] == 'getUserName') Scratch.app.usesUserNameBlock = true;

		var special:Block = specialCmd(cmd, forStage);
		if (special) { special.fixArgLayout(); return special }

		var b:Block;
		b = convertOldCmd(cmd);
		if (b) { b.fixArgLayout(); return b }

		if (cmd[0] == Specs.CALL) {
			b = new Block(cmd[1], '', Specs.procedureColor, Specs.CALL);
			cmd.splice(0, 1);
		} else {
			var spec:Array = specForCmd(cmd, undefinedBlockType);
			var label:String = spec[0];
			if(forStage && spec[3] == 'whenClicked') label = 'when Stage clicked';
			b = new Block(label, spec[1], Specs.blockColor(spec[2]), spec[3]);
		}

		var args:Array = argsForCmd(cmd, b.args.length, b.rightToLeft);
		var substacks:Array = substacksForCmd(cmd, b.args.length);
		var hadSpriteRef:Boolean;
		for (var i:int = 0; i < args.length; i++) {
			var a:* = args[i];
			if (a is ScratchObj) {
				a = ScratchObj(a).objName; // convert a Scratch 1.4 sprite reference to a sprite name
				hadSpriteRef = true;
			}
			b.setArg(i, a);
		}
		if (substacks[0] && (b.base.canHaveSubstack1())) b.insertBlockSub1(substacks[0]);
		if (substacks[1] && (b.base.canHaveSubstack2())) b.insertBlockSub2(substacks[1]);
		// if hadSpriteRef is true, don't call fixMouseEdgeRefs() to avoid converting references
		// to sprites named 'mouse' or 'edge' to '_mouse_' or '_edge_'.
		if (!hadSpriteRef) fixMouseEdgeRefs(b);
		b.fixArgLayout();
		return b;
	}

	public static function specForCmd(cmd:Array, undefinedBlockType:String):Array {
		// Return the block specification for the given command.
		var op:String = cmd[0];
		if (op == '\\\\') op = '%'; // convert old Squeak modulo operator
		for each (var entry:Array in Specs.commands) {
			if (entry[3] == op) return entry;
		}
		var extensionSpec:Array = Scratch.app.extensionManager.specForCmd(op);
		if (extensionSpec) return extensionSpec;

		var spec:String = 'undefined';
		for (var i:int = 1; i < cmd.length; i++) spec += ' %n'; // add placeholder arg slots
		return [spec, undefinedBlockType, 0, op]; // no match found
	}

	private static function argsForCmd(cmd:Array, numArgs:uint, reverseArgs:Boolean):Array {
		// Return an array of zero or more arguments for the given command.
		// Arguments may be literal values or reporter blocks (expressions).
		var result:Array = [];
		for (var i:int = 1; i <= numArgs; i++) {
			var a:* = cmd[i];
			if (a is Array) {
				// block
				result.push(arrayToBlock(a, 'r'));
			} else {
				// literal value
				result.push(a);
			}
		}
		if (reverseArgs) result.reverse();
		return result;
	}

	private static function substacksForCmd(cmd:Array, numArgs:uint):Array {
		// Return an array of zero or more substacks for the given command.
		var result:Array = [];
		for (var i:int = 1 + numArgs; i < cmd.length; i++) {
			var a:* = cmd[i];
			if (a == null) result.push(null); // null indicates an empty stack
			else result.push(arrayToStack(a));
		}
		return result;
	}

	private static const controlColor:int = Specs.blockColor(Specs.controlCategory);

	private static function specialCmd(cmd:Array, forStage:Boolean):Block {
		// If the given command is special (e.g. a reporter or old-style a hat blocK), return a block for it.
		// Otherwise, return null.
		var b:Block;
		switch (cmd[0]) {
		case Specs.GET_VAR:
			return new Block(cmd[1], 'r', Specs.variableColor, Specs.GET_VAR);
		case Specs.GET_LIST:
			return new Block(cmd[1], 'r', Specs.listColor, Specs.GET_LIST);
		case Specs.PROCEDURE_DEF:
			b = new Block('', 'p', Specs.procedureColor, Specs.PROCEDURE_DEF);
			b.parameterNames = cmd[2];
			b.defaultArgValues = cmd[3];
			if (cmd.length > 4) b.warpProcFlag = cmd[4];
			b.setSpec(cmd[1]);
			b.fixArgLayout();
			return b;
		case Specs.GET_PARAM:
			var paramType:String = (cmd.length >= 3) ? cmd[2] : 'r';
			return new Block(cmd[1], paramType, Specs.parameterColor, Specs.GET_PARAM);
		case 'changeVariable':
			var varOp:String = cmd[2];
			if (varOp == Specs.SET_VAR) {
				b = new Block('set %m.var to %s', ' ', Specs.variableColor, Specs.SET_VAR);
			} else if (varOp == Specs.CHANGE_VAR) {
				b = new Block('change %m.var by %n', ' ', Specs.variableColor, Specs.CHANGE_VAR);
			}
			if (b == null) return null;
			var arg:* = cmd[3];
			if (arg is Array) arg = arrayToBlock(arg, 'r');
			b.setArg(0, cmd[1]);
			b.setArg(1, arg);
			return b;
		case 'EventHatMorph':
			if (cmd[1] == 'Scratch-StartClicked') {
				return new Block('when @greenFlag clicked', 'h', controlColor, 'whenGreenFlag');
			}
			b = new Block('when I receive %m.broadcast', 'h', controlColor, 'whenIReceive');
			b.setArg(0, cmd[1]);
			return b;
		case 'MouseClickEventHatMorph':
			b = new Block('when I am clicked', 'h', controlColor, 'whenClicked');
			return b;
		case 'KeyEventHatMorph':
			b = new Block('when %m.key key pressed', 'h', controlColor, 'whenKeyPressed');
			b.setArg(0, cmd[1]);
			return b;
		case 'stopScripts':
			var type:String = (cmd[1].indexOf('other scripts') == 0) ? ' ' : 'f'; // block type depends on menu arg
			b = new Block('stop %m.stop', type, controlColor, 'stopScripts');
			if (type == ' ') {
				if(forStage) cmd[1] = 'other scripts in stage';
				else cmd[1] = 'other scripts in sprite';
			}
			b.setArg(0, cmd[1]);
			return b;
		}
		return null;
	}

	private static function convertOldCmd(cmd:Array):Block {
		// If the given command is one of a handful of old Scratch blocks,
		// covert it to it's new form and return it. Otherwise, return null.
		var b:Block;
		var controlColor:int = Specs.blockColor(Specs.controlCategory);
		var looksColor:int = Specs.blockColor(Specs.looksCategory);
		var operatorsColor:int = Specs.blockColor(Specs.operatorsCategory);

		switch (cmd[0]) {
		case 'abs':
			b = new Block('%m.mathOp of %n', 'r', operatorsColor, 'computeFunction:of:');
			b.setArg(0, 'abs');
			b.setArg(1, convertArg(cmd[1]));
			return b;
		case 'sqrt':
			b = new Block('%m.mathOp of %n', 'r', operatorsColor, 'computeFunction:of:');
			b.setArg(0, 'sqrt');
			b.setArg(1, convertArg(cmd[1]));
			return b;
		case 'doReturn':
			b = new Block('stop %m.stop', 'f', controlColor, 'stopScripts');
			b.setArg(0, 'this script');
			return b;
		case 'stopAll':
			b = new Block('stop %m.stop', 'f', controlColor, 'stopScripts');
			b.setArg(0, 'all');
			return b;
		case 'showBackground:':
			b = new Block('switch backdrop to %m.backdrop', ' ', looksColor, 'startScene');
			b.setArg(0, convertArg(cmd[1]));
			return b;
		case 'nextBackground':
			b = new Block('next background', ' ', looksColor, 'nextScene');
			return b;
		case 'doForeverIf':
			var ifBlock:Block = new Block('if %b then', 'c', controlColor, 'doIf');
			ifBlock.setArg(0, convertArg(cmd[1]));
			if (cmd[2] is Array) ifBlock.insertBlockSub1(arrayToStack(cmd[2]));
			ifBlock.fixArgLayout();

			b = new Block('forever', 'cf', controlColor, 'doForever');
			b.insertBlockSub1(ifBlock);
			return b;
		}
		return null;
	}

	private static function convertArg(arg:*):* {
		// If arg is an array, convert it to a block. Otherwise, return it unchanged.
		return (arg is Array) ? arrayToBlock(arg, 'r') : arg;
	}

	private static function fixMouseEdgeRefs(b:Block):void {
		var refCmds:Array = [
			'createCloneOf', 'distanceTo:', 'getAttribute:of:',
			'gotoSpriteOrMouse:', 'pointTowards:', 'touching:'];
		if (refCmds.indexOf(b.op) < 0) return;
		var arg:BlockArg;
		if ((b.args.length == 1) && (b.getNormalizedArg(0) is BlockArg)) arg = b.getNormalizedArg(0);
		if ((b.args.length == 2) && (b.getNormalizedArg(1) is BlockArg)) arg = b.getNormalizedArg(1);
		if (arg) {
			var oldVal:String = arg.argValue;
			if (oldVal == 'edge' || oldVal == '_edge_') arg.setArgValue('_edge_', Translator.map('edge'));
			if (oldVal == 'mouse' || oldVal == '_mouse_') arg.setArgValue('_mouse_', Translator.map('mouse-pointer'));
			if (oldVal == '_myself_') arg.setArgValue('_myself_', Translator.map('myself'));
			if (oldVal == '_stage_') arg.setArgValue('_stage_', Translator.map('Stage'));
			if (oldVal == '_random_') arg.setArgValue('_random_', Translator.map('random position'));
		}
	}

}}
