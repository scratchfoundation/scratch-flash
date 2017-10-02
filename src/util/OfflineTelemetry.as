/**
 * Created by samohan on 9/18/17.
 */
package util {
import flash.net.InterfaceAddress;
import flash.net.NetworkInfo;
import flash.net.NetworkInterface;
import com.adobe.crypto.MD5;
import flash.crypto.generateRandomBytes;

public class OfflineTelemetry {
	public static function makeId():String {
		var timestamp:Number = (new Date()).time;
		var netInterfaces:Vector.<NetworkInterface> = NetworkInfo.networkInfo.findInterfaces();
		var addresses:Vector.<InterfaceAddress> = netInterfaces[1].addresses;
		var hashedIpAddress:String = MD5.hash(addresses[0].address + generateRandomBytes(16).toString());
		var hashedTimestamp:String = MD5.hash(timestamp.toString() + generateRandomBytes(16).toString());
		var randomHashedString:String = MD5.hash(generateRandomBytes(16).toString());
		return hashedIpAddress + "-" + hashedTimestamp + "-" + randomHashedString;
	}
}
}
