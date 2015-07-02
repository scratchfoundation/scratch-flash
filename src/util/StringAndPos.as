/**
 * Created by shanemc on 6/25/15.
 */
package util {
public class StringAndPos {
	public var str:String;
	public var pos:uint;
	public function StringAndPos(s:String) {
		str = s;
	}

	static private var plusCode:uint = '+'.charCodeAt(0);
	static private var minusCode:uint = '-'.charCodeAt(0);
	static private var zeroCode:uint = '0'.charCodeAt(0);
	static private var nineCode:uint = '9'.charCodeAt(0);
	static private var dotCode:uint = '.'.charCodeAt(0);
	static private var eCode:uint = 'e'.charCodeAt(0);
	static private var ECode:uint = 'E'.charCodeAt(0);
	// Original RegEx: /(?:\+|-)?\d+(?:\.\d+)?(?:e(?:\+|-)?\d+)?/g
	public function getNextNumber(end:int = -1, fallback:Number = Number.NaN):Number {
		var last:uint = (end == -1 ? str.length - 1 : end - 1);
		if (pos > last) return fallback;

		var spos:uint = pos;
		var c:uint = str.charCodeAt(pos);
		var n:uint;

		// find the first numeric characters
		while ((c < zeroCode || c > nineCode) && pos < last)
			c = str.charCodeAt(++pos);

		if (pos == last && (c < zeroCode || c > nineCode)) {
			++pos;
			return fallback;
		}

		var negative:Boolean = false;
		var start:uint = pos;
		if (pos > spos) {
			// Check for a +/- sign
			var prev:uint = str.charCodeAt(pos-1);
			if (prev == plusCode || prev == minusCode) {
				--start;
				negative = (prev == minusCode);
			}
		}

		// process numeric characters
		var val:Number = 0;
		while (c >= zeroCode && c <= nineCode && pos < last) {
			val = val * 10 + (c - zeroCode);
			c = str.charCodeAt(++pos);
		}

		if (c >= zeroCode && c <= nineCode && pos == last) {
			val = val * 10 + (c - zeroCode);
		}

		// process decimals?
		var div:Number = 1;
		if (c == dotCode && pos < last) {
			n = str.charCodeAt(pos + 1);
			if (n >= zeroCode && n <= nineCode) {
				++pos; // pass the dot
				div = 10;
				val = val * 10 + (n - zeroCode);
				c = str.charCodeAt(++pos); // pass the first digit
				while (c >= zeroCode && c <= nineCode && pos < last) {
					div *= 10;
					val = val * 10 + (c - zeroCode);
					c = str.charCodeAt(++pos);
				}

				if (c >= zeroCode && c <= nineCode && pos == last) {
					div *= 10;
					val = val * 10 + (c - zeroCode);
				}
			}
		}

		// process standard form? e.g. 1.234e12 (implement?)
		var pow:int = 0;
		if (pos < last && (c == eCode || c == ECode)) {
			var npos:uint = pos+1;
			n = str.charCodeAt(npos);
			var eneg:Boolean = false;
			if ((n == plusCode || n == minusCode) && npos < last) {
				eneg = (n == minusCode);
				n = str.charCodeAt(++npos);
			}

			if (n >= zeroCode && n <= nineCode && npos < last) {
				pos = npos; // pass the 'e' and any +/- sign
				pow = pow * 10 + (n - zeroCode);
				c = str.charCodeAt(++pos); // pass the first digit
				while (c >= zeroCode && c <= nineCode && pos < last) {
					pow = pow * 10 + (c - zeroCode);
					c = str.charCodeAt(++pos);
				}

				if (c >= zeroCode && c <= nineCode && pos == last)
					pow = pow * 10 + (c - zeroCode);

				if (eneg)
					pow = -pow;
			}
		}

		//return Number(str.substring(start, pos == last ? ++pos : pos));
		if (pos == last) ++pos;

		var v:Number = (negative ? -val : val) / div;
		if (pow != 0) v *= Math.pow(10, pow);
		return v;
	}

	static private var aCode:uint = 'a'.charCodeAt(0);
	static private var ACode:uint = 'A'.charCodeAt(0);
	static private var zCode:uint = 'z'.charCodeAt(0);
	static private var ZCode:uint = 'Z'.charCodeAt(0);
	// Orig RegEx: /[A-DF-Za-df-z][^A-Za-df-z]*/g
	public function getNextCommandEnd():int {
		var len:uint = str.length;
		var c:uint;
		var start:int = -1;
		var cpos:uint = pos;
		do {
			c = str.charCodeAt(cpos++);
			if ((c>=aCode && c<=zCode && c!=eCode) || (c>=ACode && c<=ZCode && c!=ECode)) {
				start = cpos - 1;
				break;
			}
		} while (cpos < len);

		if (start == -1)
			return -1;

		pos = start;
		do {
			c = str.charCodeAt(cpos++);
			if ((c>=aCode && c<=zCode && c!=eCode) || (c>=ACode && c<=ZCode && c!=ECode))
				return cpos - 1;
		} while (cpos < len);

		return len;
	}
}}