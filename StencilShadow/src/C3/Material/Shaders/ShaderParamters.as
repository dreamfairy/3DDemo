package C3.Material.Shaders
{
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DTriangleFace;

	/**
	 * shader参数
	 */
	public class ShaderParamters
	{
		public var vertexShaderConstants		: Vector.<ShaderConstants>;
		public var fragmentShaderConstants		: Vector.<ShaderConstants>;
		
		public static const CULLING			: String = "culling";
		
		public var blendEnabled					: Boolean = false;
		public var blendSource					: String = Context3DBlendFactor.ONE;
		public var blendDestination				: String = Context3DBlendFactor.ZERO;
		public var writeDepth					: Boolean  = true;
		public var depthFunction				: String = Context3DCompareMode.LESS_EQUAL;
		public var colorMaskEnabled				: Boolean = false;
		public var colorMaskR					: Boolean = true;
		public var colorMaskG					: Boolean = true;
		public var colorMaskB					: Boolean = true;
		public var colorMaskA					: Boolean = true;
		public var culling						: String = Context3DTriangleFace.NONE;
		public var requiresLight				: Boolean = false;
		public var loopCount					: int = 1;
		
		public var updateList					: Array;
		
		public function ShaderParamters()
		{
			vertexShaderConstants	= new Vector.<ShaderConstants>();
			fragmentShaderConstants	= new Vector.<ShaderConstants>();
		}
	}
}