package C3.Pool
{
	import flash.display3D.Context3D;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	public class ContextCache
	{
		public var context : Context3D;
		public var key : int;
		public var shaderCache : Dictionary = new Dictionary();
		
		public function ContextCache($context : Context3D)
		{
			key = getTimer();
			context = $context;
		}
	}
}