/*
 * Scratch Project Editor and Player
 * Copyright (C) 2018 Massachusetts Institute of Technology
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

/**
 * Calling getTimer() is much more expensive in Flash 30 than in previous versions.
 * This class is meant to reduce the number of actual calls to getTimer() with minimal changes to existing code.
 */
public class CachedTimer {
	private static var dirty:Boolean = true;
	private static var cachedTimer:int;

	/**
	 * @return the last cached value of getTimer(). May return a fresh value if the cache has been invalidated.
	 */
	public static function getCachedTimer():int {
		return dirty ? getFreshTimer() : cachedTimer;
	}

	/**
	 * Clear the timer cache, forcing getCachedTimer() to get a fresh value next time. Use this at the top of a frame.
	 */
	public static function clearCachedTimer():void {
		dirty = true;
	}

	/**
	 * @return and cache the current value of getTimer().
	 * Use this if you need an accurate timer value in the middle of a frame.
	 */
	public static function getFreshTimer():int {
		cachedTimer = getTimer();
		dirty = false;
		return cachedTimer;
	}
}
}
