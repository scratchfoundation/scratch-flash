package com.adobe.utils.macro
{
	internal class UnaryExpression extends Expression
	{
		public function UnaryExpression()	{}
		
		public var right:Expression;
		override public function print( depth:int ):void {
			if ( AGALPreAssembler.TRACE_VM ) {
				trace( spaces( depth ) + "not" );
			}
			right.print( depth+1 );
		}	
		override public function exec( vm:VM ):void {
			right.exec( vm );
			
			var varRight:Number = vm.stack.pop();
			var value:Number = (varRight == 0) ? 1 : 0;
			
			if ( AGALPreAssembler.TRACE_VM ) {
				trace( "::NotExpression push " + value );
			}
			if ( isNaN( varRight ) ) throw new Error( "UnaryExpression NaN" );
			vm.stack.push( value );
		}
	}
}
