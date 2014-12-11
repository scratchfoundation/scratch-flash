package com.adobe.utils.macro
{
	internal class NumberExpression extends Expression
	{
		public function NumberExpression( v:Number ) {
			value = v;
		}
		private var value:Number;
		override public function print( depth:int ):void { trace( spaces( depth ) + "number=" + value ); }
		override public function exec( vm:VM ):void {
			if ( AGALPreAssembler.TRACE_VM ) {
				trace( "::NumberExpression push " + value );
			}
			if ( isNaN( value ) ) throw new Error( "Pushing NaN to stack" );
			vm.stack.push( value );
		}
	}
}