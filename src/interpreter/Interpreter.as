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

// Interpreter.as
// John Maloney, August 2009
// Revised, March 2010
//
// A simple yet efficient interpreter for blocks.
//
// Interpreters may seem mysterious, but this one is quite straightforward. Since every
// block knows which block (if any) follows it in a sequence of blocks, the interpreter
// simply executes the current block, then asks that block for the next block. The heart
// of the interpreter is the evalCmd() function, which looks up the opcode string in a
// dictionary (initialized by initPrims()) then calls the primitive function for that opcode.
// Control structures are handled by pushing the current state onto the active thread's
// execution stack and continuing with the first block of the substack. When the end of a
// substack is reached, the previous execution state is popped. If the substack was a loop
// body, control yields to the next thread. Otherwise, execution continues with the next
// block. If there is no next block, and no state to pop, the thread terminates.
//
// The interpreter does as much as it can within workTime milliseconds, then returns
// control. It returns control earlier if either (a) there are are no more threads to run
// or (b) some thread does a command that has a visible effect (e.g. "move 10 steps").
//
// To add a command to the interpreter, just add a new case to initPrims(). Command blocks
// usually perform some operation and return null, while reporters must return a value.
// Control structures are a little tricky; look at some of the existing control structure
// commands to get a sense of what to do.
//
// Clocks and time:
//
// The millisecond clock starts at zero when Flash is started and, since the clock is
// a 32-bit integer, it wraps after 24.86 days. Since it seems unlikely that one Scratch
// session would run that long, this code doesn't deal with clock wrapping.
// Since Scratch only runs at discrete intervals, timed commands may be resumed a few
// milliseconds late. These small errors accumulate, causing threads to slip out of
// synchronization with each other, a problem especially noticeable in music projects.
// This problem is addressed by recording the amount of time slippage and shortening
// subsequent timed commands slightly to "catch up".
// Delay times are rounded to milliseconds, and the minimum delay is a millisecond.

package interpreter {
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	import flash.geom.Point;
	import blocks.*;
	import primitives.*;
	import scratch.*;
	import sound.*;

public class Interpreter {

	public var activeThread:Thread;				// current thread
	public var currentMSecs:int = getTimer();	// millisecond clock for the current step
	public var turboMode:Boolean = false;

	private var app:Scratch;
	private var primTable:Dictionary;		// maps opcodes to functions
	private var threads:Array = [];			// all threads
	private var yield:Boolean;				// set true to indicate that active thread should yield control
	private var startTime:int;				// start time for stepThreads()
	private var doRedraw:Boolean;
	private var isWaiting:Boolean;

	private const warpMSecs:int = 500;		// max time to run during warp
	private var warpThread:Thread;			// thread that is in warp mode
	private var warpBlock:Block;			// proc call block that entered warp mode

	private var bubbleThread:Thread;			// thread for reporter bubble
	public var askThread:Thread;				// thread that opened the ask prompt

	protected var debugFunc:Function;

	public function Interpreter(app:Scratch) {
		this.app = app;
		initPrims();
//		checkPrims();
	}

	public function targetObj():ScratchObj { return ScratchObj(activeThread.target) }
	public function targetSprite():ScratchSprite { return activeThread.target as ScratchSprite }

	/* Threads */

	public function doYield():void { isWaiting = true; yield = true }
	public function redraw():void { if (!turboMode) doRedraw = true }

	public function yieldOneCycle():void {
		// Yield control but proceed to the next block. Do nothing in warp mode.
		// Used to ensure proper ordering of HTTP extension commands.
		if (activeThread == warpThread) return;
		if (activeThread.firstTime) {
			redraw();
			yield = true;
			activeThread.firstTime = false;
		}
	}

	public function threadCount():int { return threads.length }

	public function toggleThread(b:Block, targetObj:*, startupDelay:int = 0):void {
		var i:int, newThreads:Array = [], wasRunning:Boolean = false;
		for (i = 0; i < threads.length; i++) {
			if ((threads[i].topBlock == b) && (threads[i].target == targetObj)) {
				wasRunning = true;
			} else {
				newThreads.push(threads[i]);
			}
		}
		threads = newThreads;
		if (wasRunning) {
			if (app.editMode) b.hideRunFeedback();
			clearWarpBlock();
		} else {
			var topBlock:Block = b;
			if (b.isReporter) {
				// click on reporter shows value in bubble
				if (bubbleThread) {
					toggleThread(bubbleThread.topBlock, bubbleThread.target);
				}
				var reporter:Block = b;
				var interp:Interpreter = this;
				b = new Block("%s", "", -1);
				b.opFunction = function(b:Block):void {
					var p:Point = reporter.localToGlobal(new Point(0, 0));
					app.showBubble(String(interp.arg(b, 0)), p.x, p.y, reporter.getRect(app.stage).width);
				};
				b.args[0] = reporter;
			}
			if (app.editMode) topBlock.showRunFeedback();
			var t:Thread = new Thread(b, targetObj, startupDelay);
			if (topBlock.isReporter) bubbleThread = t;
			t.topBlock = topBlock;
			threads.push(t);
			app.threadStarted();
		}
	}

	public function showAllRunFeedback():void {
		for each (var t:Thread in threads) {
			t.topBlock.showRunFeedback();
		}
	}

	public function isRunning(b:Block, targetObj:ScratchObj):Boolean {
		for each (var t:Thread in threads) {
			if ((t.topBlock == b) && (t.target == targetObj)) return true;
		}
		return false;
	}

	public function startThreadForClone(b:Block, clone:*):void {
		threads.push(new Thread(b, clone));
	}

	public function stopThreadsFor(target:*, skipActiveThread:Boolean = false):void {
		for (var i:int = 0; i < threads.length; i++) {
			var t:Thread = threads[i];
			if (skipActiveThread && (t == activeThread)) continue;
			if (t.target == target) {
				if (t.tmpObj is ScratchSoundPlayer) {
					(t.tmpObj as ScratchSoundPlayer).stopPlaying();
				}
				t.stop();
			}
		}
		if ((activeThread.target == target) && !skipActiveThread) yield = true;
	}

	public function restartThread(b:Block, targetObj:*):Thread {
		// used by broadcast, click hats, and when key pressed hats
		// stop any thread running on b, then start a new thread on b
		var newThread:Thread = new Thread(b, targetObj);
		var wasRunning:Boolean = false;
		for (var i:int = 0; i < threads.length; i++) {
			if ((threads[i].topBlock == b) && (threads[i].target == targetObj)) {
				if (askThread == threads[i]) app.runtime.clearAskPrompts();
				threads[i] = newThread;
				wasRunning = true;
			}
		}
		if (!wasRunning) {
			threads.push(newThread);
			if (app.editMode) b.showRunFeedback();
			app.threadStarted();
		}
		return newThread;
	}

	public function stopAllThreads():void {
		threads = [];
		if (activeThread != null) activeThread.stop();
		clearWarpBlock();
		app.runtime.clearRunFeedback();
		doRedraw = true;
	}

	public function stepThreads():void {
		startTime = getTimer();
		var workTime:int = (0.75 * 1000) / app.stage.frameRate; // work for up to 75% of one frame time
		doRedraw = false;
		currentMSecs = getTimer();
		if (threads.length == 0) return;
		while ((currentMSecs - startTime) < workTime) {
			if (warpThread && (warpThread.block == null)) clearWarpBlock();
			var threadStopped:Boolean = false;
			var runnableCount:int = 0;
			for each (activeThread in threads) {
				isWaiting = false;
				stepActiveThread();
				if (activeThread.block == null) threadStopped = true;
				if (!isWaiting) runnableCount++;
			}
			if (threadStopped) {
				var newThreads:Array = [];
				for each (var t:Thread in threads) {
					if (t.block != null) newThreads.push(t);
					else if (app.editMode) {
						if (t == bubbleThread) bubbleThread = null;
						t.topBlock.hideRunFeedback();
					}
				}
				threads = newThreads;
				if (threads.length == 0) return;
			}
			currentMSecs = getTimer();
			if (doRedraw || (runnableCount == 0)) return;
		}
	}

	private function stepActiveThread():void {
		if (activeThread.block == null) return;
		if (activeThread.startDelayCount > 0) { activeThread.startDelayCount--; doRedraw = true; return; }
		if (!(activeThread.target.isStage || (activeThread.target.parent is ScratchStage))) {
			// sprite is being dragged
			if (app.editMode) {
				// don't run scripts of a sprite that is being dragged in edit mode, but do update the screen
				doRedraw = true;
				return;
			}
		}
		yield = false;
		while (true) {
			if (activeThread == warpThread) currentMSecs = getTimer();
			evalCmd(activeThread.block);
			if (yield) {
				if (activeThread == warpThread) {
					if ((currentMSecs - startTime) > warpMSecs) return;
					yield = false;
					continue;
				} else return;
			}

			if (activeThread.block != null)
				activeThread.block = activeThread.block.nextBlock;

			while (activeThread.block == null) { // end of block sequence
				if (!activeThread.popState()) return; // end of script
				if ((activeThread.block == warpBlock) && activeThread.firstTime) { // end of outer warp block
					clearWarpBlock();
					activeThread.block = activeThread.block.nextBlock;
					continue;
				}
				if (activeThread.isLoop) {
					if (activeThread == warpThread) {
						if ((currentMSecs - startTime) > warpMSecs) return;
					} else return;
				} else {
					if (activeThread.block.op == Specs.CALL) activeThread.firstTime = true; // in case set false by call
					activeThread.block = activeThread.block.nextBlock;
				}
			}
		}
	}

	private function clearWarpBlock():void {
		warpThread = null;
		warpBlock = null;
	}

	/* Evaluation */
	public function evalCmd(b:Block):* {
		if (!b) return 0; // arg() and friends can pass null if arg index is out of range
		var op:String = b.op;
		if (b.opFunction == null) {
			if (op.indexOf('.') > -1) b.opFunction = app.extensionManager.primExtensionOp;
			else b.opFunction = (primTable[op] == undefined) ? primNoop : primTable[op];
		}

		// TODO: Optimize this into a cached check if the args *could* block at all
		if(b.args.length && checkBlockingArgs(b)) {
			doYield();
			return null;
		}

		// Debug code
		if(debugFunc != null)
			debugFunc(b);

		return b.opFunction(b);
	}

	// Returns true if the thread needs to yield while data is requested
	public function checkBlockingArgs(b:Block):Boolean {
		// Do any of the arguments request data?  If so, start any requests and yield.
		var shouldYield:Boolean = false;
		var args:Array = b.args;
		for(var i:uint=0; i<args.length; ++i) {
			var barg:Block = args[i] as Block;
			if(barg) {
				if(checkBlockingArgs(barg))
					shouldYield = true;

				// Don't start a request if the arguments for it are blocking
				else if(barg.isRequester && barg.requestState < 2) {
					if(barg.requestState == 0) evalCmd(barg);
					shouldYield = true;
				}
			}
		}

		return shouldYield;
	}

	public function arg(b:Block, i:int):* {
		var args:Array = b.args;
		if (b.rightToLeft) { i = args.length - i - 1; }
		return (b.args[i] is BlockArg) ?
			BlockArg(args[i]).argValue : evalCmd(Block(args[i]));
	}

	public function numarg(b:Block, i:int):Number {
		var args:Array = b.args;
		if (b.rightToLeft) { i = args.length - i - 1; }
		var n:Number = (args[i] is BlockArg) ?
			Number(BlockArg(args[i]).argValue) : Number(evalCmd(Block(args[i])));

		if (n != n) return 0; // return 0 if NaN (uses fast, inline test for NaN)
		return n;
	}

	public function boolarg(b:Block, i:int):Boolean {
		if (b.rightToLeft) { i = b.args.length - i - 1; }
		var o:* = (b.args[i] is BlockArg) ? BlockArg(b.args[i]).argValue : evalCmd(Block(b.args[i]));
		if (o is Boolean) return o;
		if (o is String) {
			var s:String = o;
			if ((s == '') || (s == '0') || (s.toLowerCase() == 'false')) return false
			return true; // treat all other strings as true
		}
		return Boolean(o); // coerce Number and anything else
	}

	public static function asNumber(n:*):Number {
		// Convert n to a number if possible. If n is a string, it must contain
		// at least one digit to be treated as a number (otherwise a string
		// containing only whitespace would be consider equal to zero.)
		if (typeof(n) == 'string') {
			var s:String = n as String;
			var len:uint = s.length;
			for (var i:int = 0; i < len; i++) {
				var code:uint = s.charCodeAt(i);
				if (code >= 48 && code <= 57) return Number(s);
			}
			return NaN; // no digits found; string is not a number
		}
		return Number(n);
	}

	private function startCmdList(b:Block, isLoop:Boolean = false, argList:Array = null):void {
		if (b == null) {
			if (isLoop) yield = true;
			return;
		}
		activeThread.isLoop = isLoop;
		activeThread.pushStateForBlock(b);
		if (argList) activeThread.args = argList;
		evalCmd(activeThread.block);
	}

	/* Timer */

	public function startTimer(secs:Number):void {
		var waitMSecs:int = 1000 * secs;
		if (waitMSecs < 0) waitMSecs = 0;
		activeThread.tmp = currentMSecs + waitMSecs; // end time in milliseconds
		activeThread.firstTime = false;
		doYield();
	}

	public function checkTimer():Boolean {
		// check for timer expiration and clean up if expired. return true when expired
		if (currentMSecs >= activeThread.tmp) {
			// time expired
			activeThread.tmp = 0;
			activeThread.tmpObj = null;
			activeThread.firstTime = true;
			return true;
		} else {
			// time not yet expired
			doYield();
			return false;
		}
	}

	/* Primitives */

	public function isImplemented(op:String):Boolean {
		return primTable[op] != undefined;
	}

	public function getPrim(op:String):Function { return primTable[op] }

	private function initPrims():void {
		primTable = new Dictionary();
		// control
		primTable["whenGreenFlag"]		= primNoop;
		primTable["whenKeyPressed"]		= primNoop;
		primTable["whenClicked"]		= primNoop;
		primTable["whenSceneStarts"]	= primNoop;
		primTable["wait:elapsed:from:"]	= primWait;
		primTable["doForever"]			= function(b:*):* { startCmdList(b.subStack1, true); };
		primTable["doRepeat"]			= primRepeat;
		primTable["broadcast:"]			= function(b:*):* { broadcast(arg(b, 0), false); }
		primTable["doBroadcastAndWait"]	= function(b:*):* { broadcast(arg(b, 0), true); }
		primTable["whenIReceive"]		= primNoop;
		primTable["doForeverIf"]		= function(b:*):* { if (arg(b, 0)) startCmdList(b.subStack1, true); else yield = true; };
		primTable["doForLoop"]			= primForLoop;
		primTable["doIf"]				= function(b:*):* { if (arg(b, 0)) startCmdList(b.subStack1); };
		primTable["doIfElse"]			= function(b:*):* { if (arg(b, 0)) startCmdList(b.subStack1); else startCmdList(b.subStack2); };
		primTable["doWaitUntil"]		= function(b:*):* { if (!arg(b, 0)) yield = true; };
		primTable["doWhile"]			= function(b:*):* { if (arg(b, 0)) startCmdList(b.subStack1, true); };
		primTable["doUntil"]			= function(b:*):* { if (!arg(b, 0)) startCmdList(b.subStack1, true); };
		primTable["doReturn"]			= primReturn;
		primTable["stopAll"]			= function(b:*):* { app.runtime.stopAll(); yield = true; };
		primTable["stopScripts"]		= primStop;
		primTable["warpSpeed"]			= primOldWarpSpeed;

		// procedures
		primTable[Specs.CALL]			= primCall;

		// variables
		primTable[Specs.GET_VAR]		= primVarGet;
		primTable[Specs.SET_VAR]		= primVarSet;
		primTable[Specs.CHANGE_VAR]		= primVarChange;
		primTable[Specs.GET_PARAM]		= primGetParam;

		// edge-trigger hat blocks
		primTable["whenDistanceLessThan"]	= primNoop;
		primTable["whenSensorConnected"]	= primNoop;
		primTable["whenSensorGreaterThan"]	= primNoop;
		primTable["whenTiltIs"]				= primNoop;

		addOtherPrims(primTable);
	}

	protected function addOtherPrims(primTable:Dictionary):void {
		// other primitives
		new Primitives(app, this).addPrimsTo(primTable);
	}

	private function checkPrims():void {
		var op:String;
		var allOps:Array = ["CALL", "GET_VAR", "NOOP"];
		for each (var spec:Array in Specs.commands) {
			if (spec.length > 3) {
				op = spec[3];
				allOps.push(op);
				if (primTable[op] == undefined) trace("Unimplemented: " + op);
			}
		}
		for (op in primTable) {
			if (allOps.indexOf(op) < 0) trace("Not in specs: " + op);
		}
	}

	public function primNoop(b:Block):void { }

	private function primForLoop(b:Block):void {
		var list:Array = [];
		var loopVar:Variable;

		if (activeThread.firstTime) {
			if (!(arg(b, 0) is String)) return;
			var listArg:* = arg(b, 1);
			if (listArg is Array) {
				list = listArg as Array;
			}
			if (listArg is String) {
				var n:Number = Number(listArg);
				if (!isNaN(n)) listArg = n;
			}
			if ((listArg is Number) && !isNaN(listArg)) {
				var last:int = int(listArg);
				if (last >= 1) {
					list = new Array(last - 1);
					for (var i:int = 0; i < last; i++) list[i] = i + 1;
				}
			}
			loopVar = activeThread.target.lookupOrCreateVar(arg(b, 0));
			activeThread.args = [list, loopVar];
			activeThread.tmp = 0;
			activeThread.firstTime = false;
		}

		list = activeThread.args[0];
		loopVar = activeThread.args[1];
		if (activeThread.tmp < list.length) {
			loopVar.value = list[activeThread.tmp++];
			startCmdList(b.subStack1, true);
		} else {
			activeThread.args = null;
			activeThread.tmp = 0;
			activeThread.firstTime = true;
		}
	}

	private function primOldWarpSpeed(b:Block):void {
		// Semi-support for old warp block: run substack at normal speed.
		if (b.subStack1 == null) return;
		startCmdList(b.subStack1);
	}

	private function primRepeat(b:Block):void {
		if (activeThread.firstTime) {
			var repeatCount:Number = Math.max(0, Math.min(Math.round(numarg(b, 0)), 2147483647)); // clip to range: 0 to 2^31-1
			activeThread.tmp = repeatCount;
			activeThread.firstTime = false;
		}
		if (activeThread.tmp > 0) {
			activeThread.tmp--; // decrement count
			startCmdList(b.subStack1, true);
		} else {
			activeThread.firstTime = true;
		}
	}

	private function primStop(b:Block):void {
		var type:String = arg(b, 0);
		if (type == 'all') { app.runtime.stopAll(); yield = true }
		if (type == 'this script') primReturn(b);
		if (type == 'other scripts in sprite') stopThreadsFor(activeThread.target, true);
		if (type == 'other scripts in stage') stopThreadsFor(activeThread.target, true);
	}

	private function primWait(b:Block):void {
		if (activeThread.firstTime) {
			startTimer(numarg(b, 0));
			redraw();
		} else checkTimer();
	}

	// Broadcast and scene starting

	public function broadcast(msg:String, waitFlag:Boolean):void {
		var pair:Array;
		if (activeThread.firstTime) {
			var receivers:Array = [];
			var newThreads:Array = [];
			msg = msg.toLowerCase();
			var findReceivers:Function = function (stack:Block, target:ScratchObj):void {
				if ((stack.op == "whenIReceive") && (stack.args[0].argValue.toLowerCase() == msg)) {
					receivers.push([stack, target]);
				}
			}
			app.runtime.allStacksAndOwnersDo(findReceivers);
			// (re)start all receivers
			for each (pair in receivers) newThreads.push(restartThread(pair[0], pair[1]));
			if (!waitFlag) return;
			activeThread.tmpObj = newThreads;
			activeThread.firstTime = false;
		}
		var done:Boolean = true;
		for each (var t:Thread in activeThread.tmpObj) { if (threads.indexOf(t) >= 0) done = false }
		if (done) {
			activeThread.tmpObj = null;
			activeThread.firstTime = true;
		} else {
			yield = true;
		}
	}

	public function startScene(sceneName:String, waitFlag:Boolean):void {
		var pair:Array;
		if (activeThread.firstTime) {
			function findSceneHats(stack:Block, target:ScratchObj):void {
				if ((stack.op == "whenSceneStarts") && (stack.args[0].argValue == sceneName)) {
					receivers.push([stack, target]);
				}
			}
			var receivers:Array = [];
			app.stagePane.showCostumeNamed(sceneName);
			redraw();
			app.runtime.allStacksAndOwnersDo(findSceneHats);
			// (re)start all receivers
			var newThreads:Array = [];
			for each (pair in receivers) newThreads.push(restartThread(pair[0], pair[1]));
			if (!waitFlag) return;
			activeThread.tmpObj = newThreads;
			activeThread.firstTime = false;
		}
		var done:Boolean = true;
		for each (var t:Thread in activeThread.tmpObj) { if (threads.indexOf(t) >= 0) done = false }
		if (done) {
			activeThread.tmpObj = null;
			activeThread.firstTime = true;
		} else {
			yield = true;
		}
	}

	// Procedure call/return

	private var tmpArgList:Array = [];
	private function primCall(b:Block):void {
		// Call a procedure. Handle recursive calls and "warp" procedures.
		// The activeThread.firstTime flag is used to mark the first call
		// to a procedure running in warp mode. activeThread.firstTime is
		// false for subsequent calls to warp mode procedures.

		// Lookup the procedure and cache for future use
		var obj:ScratchObj = activeThread.target;
		var spec:String = b.spec;
		var proc:Block = obj.procCache[spec];
		if (!proc) {
			proc = obj.lookupProcedure(spec);
			obj.procCache[spec] = proc;
		}
		if (!proc) return;

		if (warpThread) {
			activeThread.firstTime = false;
			if ((currentMSecs - startTime) > warpMSecs) yield = true;
		} else {
			if (proc.warpProcFlag) {
				// Start running in warp mode.
				warpBlock = b;
				warpThread = activeThread;
				activeThread.firstTime = true;
			}
			else if (activeThread.isRecursiveCall(b, proc)) {
				yield = true;
			}
		}
		var argCount:int = proc.parameterNames.length;

		tmpArgList.length = argCount;
		for (var i:int = 0; i < argCount; ++i) tmpArgList[i] = arg(b, i);
		startCmdList(proc, false, tmpArgList);
	}

	private function primReturn(b:Block):void {
		// Return from the innermost procedure. If not in a procedure, stop the thread.
		var didReturn:Boolean = activeThread.returnFromProcedure();
		if (!didReturn) {
			activeThread.stop();
			yield = true;
		}
	}

	// Variable Primitives
	// Optimization: to avoid the cost of looking up the variable every time,
	// a reference to the Variable object is cached in the target object.

	private function primVarGet(b:Block):* {
		var v:Variable = activeThread.target.varCache[b.spec];
		if (v == null) {
			v = activeThread.target.varCache[b.spec] = activeThread.target.lookupOrCreateVar(b.spec);
			if (v == null) return 0;
		}
		// XXX: Do we need a get() for persistent variables here ?
		return v.value;
	}

	protected function primVarSet(b:Block):Variable {
		var name:String = arg(b, 0);
		var v:Variable = activeThread.target.varCache[name];
		if (!v) {
			v = activeThread.target.varCache[name] = activeThread.target.lookupOrCreateVar(name);
			if (!v) return null;
		}
		var oldvalue:* = v.value;
		v.value = arg(b, 1);
		return v;
	}

	protected function primVarChange(b:Block):Variable {
		var name:String = arg(b, 0);
		var v:Variable = activeThread.target.varCache[name];
		if (!v) {
			v = activeThread.target.varCache[name] = activeThread.target.lookupOrCreateVar(name);
			if (!v) return null;
		}
		v.value = Number(v.value) + numarg(b, 1);
		return v;
	}

	private function primGetParam(b:Block):* {
		if (b.parameterIndex < 0) {
			var proc:Block = b.topBlock();
			if (proc.parameterNames) b.parameterIndex = proc.parameterNames.indexOf(b.spec);
			if (b.parameterIndex < 0) return 0;
		}
		if ((activeThread.args == null) || (b.parameterIndex >= activeThread.args.length)) return 0;
		return activeThread.args[b.parameterIndex];
	}

}}
