package C3.Material.Shaders
{
	import flash.display3D.Context3D;
	import flash.display3D.Program3D;
	import flash.utils.ByteArray;

	public class Shader
	{
		protected var m_params : ShaderParamters;
		protected var m_program : Program3D;
		
		public function Shader()
		{
			m_params = new ShaderParamters();
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
	}
}