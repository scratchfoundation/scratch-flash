package com.adobe.utils.macro
{
	import com.adobe.utils.macro.VM;
	
	public class Expression
	{
		public function print( depth:int ):void { trace( "top" ); }
		public function exec( vm:VM ):void {
			trace( "WTF" );
		}
		
		protected function spaces( depth:int ):String
		{
			// Must be a clever way to do this...
			var str:String = "";
			for( var i:int=0; i<depth; ++i ) {
				str += "  ";
			}
			return str;
		}
	}
}




