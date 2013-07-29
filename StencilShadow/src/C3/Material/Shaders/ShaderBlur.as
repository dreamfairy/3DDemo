package C3.Material.Shaders
{
	import flash.display3D.Context3D;
	import flash.utils.ByteArray;
	
	import C3.Object3D;
	
	public class ShaderBlur extends Shader
	{
		public var yStep : uint = 3;
		public var xStep : uint = 3;
		
		public var uvStep : Number = 1/512;
		
		public function ShaderBlur(renderTarget:Object3D=null, context:Context3D=null)
		{
			super(renderTarget, context);
		}
		
		public override function getVertexProgram():ByteArray
		{
			return null;
		}
	}
}