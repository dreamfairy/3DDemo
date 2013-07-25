package C3.Material.Shaders
{
	import flash.display.ShaderParameter;
	import flash.display3D.Context3D;
	import flash.display3D.Program3D;
	import flash.utils.ByteArray;
	
	import C3.IDispose;
	import C3.Object3D;
	import C3.Material.IMaterial;

	public class Shader implements IDispose
	{
		protected var m_params : ShaderParamters;
		protected var m_program : Program3D;
		protected var m_renderTarget : Object3D;
		protected var m_material : IMaterial;
		
		public function Shader(renderTarget : Object3D = null)
		{
			m_params = new ShaderParamters();
			m_renderTarget = renderTarget;
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