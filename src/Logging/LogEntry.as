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

package Logging {
import flash.utils.getTimer;

public class LogEntry {
	public var severity:String;
	public var messageKey:String;
	public var extraData:Object;
	public var timeStamp:Number;

	public function LogEntry(severity:String, messageKey:String, extraData:Object = null) {
		setAll(severity, messageKey, extraData);
	}

	// Set all fields of this event
	public function setAll(severity:String, messageKey:String, extraData:Object = null):void {
		if (LogLevel.LEVEL.indexOf(severity) < 0) {
			Scratch.app.logMessage("LogEntry got invalid severity", {severity: severity, messageKey: messageKey});
		}
		this.severity = severity;
		this.messageKey = messageKey;
		this.extraData = extraData;
		this.timeStamp = getCurrentTime();
	}

	private static const tempDate:Date = new Date();

	public function toJSON():Object {
		tempDate.time = timeStamp;
		var dateString:String = tempDate.toString();
		if (extraData) {
			return {timeStamp: dateString, message: messageKey, extraData: extraData};
		}
		else {
			return {timeStamp: dateString, message: messageKey};
		}
	}

	private static const timerOffset:Number = new Date().time - getTimer();

	// Returns approximately the same value as "new Date().time" without GC impact
	public static function getCurrentTime():Number {
		return getTimer() + timerOffset;
	}
}
}
