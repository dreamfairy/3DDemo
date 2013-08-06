package C3.Material.Shaders
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Program3D;
	import flash.utils.ByteArray;
	
	import C3.IDispose;
	import C3.Object3D;
	import C3.Material.IMaterial;

	public class Shader implements IDispose
	{
		public var enabled : Boolean = true;
		
		protected var m_params : ShaderParamters;
		protected var m_program : Program3D;
		protected var m_renderTarget : Object3D;
		protected var m_material : IMaterial;
		
		public static const DEPTH_MAP : uint = 0;
		public static const SHADOW_MAP : uint = 1;
		public static const SIMPLE : uint = 2;
		public static const SKYBOX : uint = 3;
		public static const RENDER_TO_TEXTURE : uint = 4;
		public static const BLUR : uint = 5;
		public static const BLOOM : uint = 6;
		
		public function Shader(renderTarget : Object3D = null, context : Context3D = null)
		{
			m_params = new ShaderParamters();
			m_renderTarget = renderTarget;
		}
		
		public function updateShaderParams(target : Object3D, context : Context3D) : void
		{
			context.setDepthTest(m_params.writeDepth, m_params.depthFunction);
			context.setCulling(m_params.culling);
			
			if(null == target || null == target.shaderParams
			|| null == target.shaderParams.updateList) return;
			
			for each(var key : String in target.shaderParams.updateList)
			{
				switch(key){
					case ShaderParamters.CULLING:
						context.setCulling(target.shaderParams[key]);
						break;
				}
			}
		}
		
		public function get renderTarget() : Object3D
		{
			return m_renderTarget;
		}
		
		public function get params() : ShaderParamters
		{
			return m_params;
		}
		
		public function set material(data : IMaterial) : void
		{
			m_material = data;
		}
		
		public function get material() : IMaterial
		{
			return m_material;
		}
		
		public function getProgram(context : Context3D) : Program3D
		{
			if(null == m_program){
				m_program = context.createProgram();
				m_program.upload(getVertexProgram(),getFragmentProgram());
			}
			
			return m_program;
		}
		
		public function getVertexProgram() : ByteArray
		{
			throw new Error("这货需要重写");
		}
		
		public function getFragmentProgram() : ByteArray
		{
			throw new Error("这货需要重写");
		}
		
		public function render(context3D : Context3D) : void
		{
			if(m_params.blendEnabled) context3D.setBlendFactors(m_params.blendSource,m_params.blendDestination);
			else context3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
		}
		
		public function get type() : uint
		{
			throw new Error("这货必须重写");
		}
		
		public function dispose():void
		{
			//再说吧
		}
	}
}