/**
 * Created by shanemc on 5/18/15.
 */
package ui {
public class ItemData {
	public var type:String;
	public var name:String;
	public var obj:*;
	public var id:String;
	public var extras:Object;
	public function ItemData(objType:String, objName:String, assetID:String, object:*, extras:Object = null) {
		type = objType;
		name = objName;
		id = assetID;
		obj = object;
		extras = extras;
	}

	public function identifier(strict:Boolean = false):String {
		return type + id + (strict ? name : '');
	}
}}