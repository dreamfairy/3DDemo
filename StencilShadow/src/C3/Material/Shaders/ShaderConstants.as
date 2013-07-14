package C3.Material.Shaders
{
	import flash.display3D.textures.Texture;
	import flash.geom.Matrix3D;

	/**
	 * shader常量
	 */
	public class ShaderConstants
	{
		public var firstRegister : int = 0;
		public var numRegisters : int;
		public var vector: Vector.<Number>;
		public var matrix : Matrix3D;
		public var texture : Texture;
		
		public function ShaderConstants(pFirstRegister : uint = 0)
		{
			firstRegister = pFirstRegister;
		}
	}
}