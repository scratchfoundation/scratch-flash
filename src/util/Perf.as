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

package util {
import flash.utils.getTimer;

public class Perf {

	private static var totalStart:uint;
	private static var lapStart:uint;
	private static var lapTotal:uint;

	public static function start(msg:String = null):void {
		if (!msg) msg = 'Perf.start';
		Scratch.app.log(msg);
		totalStart = lapStart = getTimer();
		lapTotal = 0;
	}

	public static function clearLap():void {
		lapStart = getTimer();
	}

	public static function lap(msg:String = ""):void {
		if (totalStart == 0) return; // not monitoring performance
		var lapMSecs:uint = getTimer() - lapStart;
		Scratch.app.log('  ' + msg + ': ' + lapMSecs + ' msecs');
		lapTotal += lapMSecs;
		lapStart = getTimer();
	}

	public static function end():void {
		if (totalStart == 0) return; // not monitoring performance
		var totalMSecs:uint = getTimer() - totalStart;
		var unaccountedFor:uint = totalMSecs - lapTotal;
		Scratch.app.log('Total: ' + totalMSecs + ' msecs; unaccounted for: ' + unaccountedFor + ' msecs (' + int((100 * unaccountedFor) / totalMSecs) + '%)');
		totalStart = lapStart = lapTotal = 0;
	}
}}
