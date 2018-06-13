/*
 * Scratch Project Editor and Player
 * Copyright (C) 2015 Massachusetts Institute of Technology
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

package logging {
import util.CachedTimer;

public class LogEntry {
	public var timeStamp:Number;
	public var severity:int;
	public var messageKey:String;
	public var extraData:Object;

	public function LogEntry(severity:String, messageKey:String, extraData:Object = null) {
		setAll(severity, messageKey, extraData);
	}

	// Set all fields of this event
	public function setAll(severity:String, messageKey:String, extraData:Object = null):void {
		this.timeStamp = getCurrentTime();
		this.severity = LogLevel.LEVEL.indexOf(severity);
		this.messageKey = messageKey;
		this.extraData = extraData;
	}

	private static const tempDate:Date = new Date();
	private function makeTimeStampString():String {
		tempDate.time = timeStamp;
		return tempDate.toLocaleTimeString();
	}

	// Generate a string representing this event. Does not include extraData.
	public function toString():String {
		return [makeTimeStampString(), LogLevel.LEVEL[severity], messageKey].join(' | ');
	}

	private static const timerOffset:Number = new Date().time - CachedTimer.getFreshTimer();

	// Returns approximately the same value as "new Date().time" without GC impact
	public static function getCurrentTime():Number {
		return CachedTimer.getCachedTimer() + timerOffset;
	}
}
}
