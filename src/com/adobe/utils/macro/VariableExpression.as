package com.adobe.utils.macro
{
	internal class VariableExpression extends com.adobe.utils.macro.Expression
	{
		public function VariableExpression( n:String )
		{
			name = n;
		}
		public var name:String;
		override public function print( depth:int ):void { trace( spaces( depth ) + "variable=" + name ); }
		
		override public function exec( vm:VM ):void {
			if ( AGALPreAssembler.TRACE_VM ) {
				trace( "::VariableExpression push var " + name + " value " + vm.vars[ name] );
			}
			if ( isNaN( vm.vars[ name] ) ) throw new Error( "VariableExpression NaN. name=" + name );
			vm.stack.push( vm.vars[ name] );
		}
	}
}