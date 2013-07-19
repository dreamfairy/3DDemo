package C3.Material.Shaders
{
	import flash.display3D.Context3D;
	import flash.display3D.Program3D;
	import flash.display3D.textures.TextureBase;
	import flash.utils.ByteArray;
	
	import C3.IDispose;
	import C3.Object3D;

	public class Shader implements IDispose
	{
		protected var m_params : ShaderParamters;
		protected var m_program : Program3D;
		protected var m_renderTarget : Object3D;
		protected var m_texture : TextureBase;
		
		public function Shader(renderTarget : Object3D = null)
		{
			m_params = new ShaderParamters();
			m_renderTarget = renderTarget;
		}
		
		public function set texture(data : TextureBase) : void
		{
			m_texture = data;
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
			throw new Error("这货需要重写");
		}
		
		public function dispose():void
		{
			//再说吧
		}
	}
}