package com.adobe.utils.macro
{
	/**
	 * Class to record information about all the aliases in an AGAL
	 * shader. Typically a program is interested in making sure all
	 * the needed constants are set in the constant pool. If isConstant()
	 * return true, then the x,y,z,w members contain the values required
	 * for the shader to run correctly.
	 */
	public class AGALVar
	{
		public var name:String;		// transform
		public var target:String;	// "vc3", "va2.x"
		public var x:Number = Number.NaN;
		public var y:Number = Number.NaN;
		public var z:Number = Number.NaN;
		public var w:Number = Number.NaN;
		
		public function isConstant():Boolean { return !isNaN( x ); }
		public function toString():String {
			if ( this.isConstant() )
				return "alias " + target + ", " + name + "( " + x + ", " + y + ", " + z + ", " + w + " )"; 
			else
				return "alias " + target + ", " + name;  
		}
		
	}
}