/**
 * Created by shanemc on 5/18/15.
 */
package ui {
public class ItemData {
	public var type:String;
	public var name:String;
	public var obj:*;
	public var assetID:String;
	public var extras:Object;
	public function ItemData(objType:String, objName:String, md5:String, object:*, extraData:Object = null) {
		type = objType;
		name = objName;
		assetID = md5;
		obj = object;
		extras = extraData;
	}

	public function identifier(strict:Boolean = false):String {
		return assetID + (strict ? name : '');
	}

	public function clone():ItemData {
		var extrasCopy:Object;
		if (extras) {
			extrasCopy = {};
			for (var prop:String in extras)
				if (prop.charAt(0) != '_') // ignore special props
					extrasCopy[prop] = extras[prop];
		}
		return new ItemData(type, name, assetID, obj, extrasCopy);
	}
}}