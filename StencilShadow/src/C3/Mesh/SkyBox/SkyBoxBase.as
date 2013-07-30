package C3.Mesh.SkyBox
{
	import com.adobe.utils.AGALMiniAssembler;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Context3DVertexBufferFormat;
	
	import C3.Object3D;
	import C3.Camera.Camera;
	import C3.Camera.ICamera;
	import C3.Material.IMaterial;
	import C3.Material.Shaders.Shader;
	import C3.Material.Shaders.ShaderSkyBox;
	
	public class SkyBoxBase extends Object3D
	{
		public function SkyBoxBase(name:String, mat:IMaterial, size : int = 10)
		{
			super(name, mat);
			m_size = size >> 1;
			setup();
		}
		
		private function setup() : void
		{
			var vertexList : Vector.<Number> = new Vector.<Number>();
			vertexList.push(-m_size,-m_size,m_size);
			vertexList.push(-m_size,m_size,m_size);
			vertexList.push(m_size,-m_size,m_size);
			vertexList.push(m_size,m_size,m_size);
			
			vertexList.push(-m_size,m_size,-m_size);
			vertexList.push(m_size,m_size,-m_size);
			vertexList.push(-m_size,-m_size,-m_size);
			vertexList.push(m_size,-m_size,-m_size);
			
			vertexList.push(-m_size,-m_size,m_size);
			vertexList.push(m_size,-m_size,m_size);
			vertexList.push(m_size,-m_size,-m_size);
			vertexList.push(m_size,m_size,-m_size);
			
			vertexList.push(-m_size,-m_size,-m_size);
			vertexList.push(-m_size,m_size,-m_size);
			
			vertexRawData = vertexList;
			
			var indexList : Vector.<uint> = new Vector.<uint>();
			indexList.push(
				0, 1, 2,
				2, 1, 3,
				1, 4, 3,
				3, 4, 5,
				4, 6, 5,
				5, 6, 7,
				6, 8, 7,
				7, 8, 9,
				2, 3, 10,
				10, 3, 11,
				12, 13, 0,
				0, 13, 1);
			m_numTriangles = indexList.length/3;
			indexRawData = indexList;
			
			var shader : ShaderSkyBox = new ShaderSkyBox(this);
			shader.material = m_material;
			setShader(shader);
		}
		
		public override function render(context:Context3D, camera:ICamera):void
		{
			m_context = context;
			m_camera = camera;
			
			checkBuffer();
			
			if(m_transformDirty)
				updateTransform();
			
			for each(var shader : Shader in m_shaderList){
				shader.render(context);
			}
		}
		
		private var m_size : int;
	}
}