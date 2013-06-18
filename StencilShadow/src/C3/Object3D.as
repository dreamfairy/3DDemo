package C3
{
	import com.adobe.utils.AGALMiniAssembler;
	
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Matrix3D;
	
	import C3.Material.IMaterial;
	import C3.Mesh.MeshBase;
	
	public class Object3D extends MeshBase
	{
		public function Object3D(name : String, mat:IMaterial)
		{
			super(mat);
			m_name = name;
		}
		
		public function get indexRawData() : Vector.<uint>
		{
			return m_indexRawData;
		}
		
		public function set indexRawData(data : Vector.<uint>) : void
		{
			m_indexRawData = data;
			
			if(m_indexBuffer){
				m_indexBuffer.dispose();
				m_indexBuffer = null;
			}
		}
		
		public function get vertexRawData() : Vector.<Number>
		{
			return m_vertexRawData;
		}
		
		public function set vertexRawData(data : Vector.<Number>) : void
		{
			m_vertexRawData = data;
			
			if(m_vertexBuffer){
				m_vertexBuffer.dispose();
				m_vertexBuffer = null;
			}
		}
		
		public function get uvRawData() : Vector.<Number>
		{
			return m_uvRawData;
		}
		
		public function set uvRawData(data : Vector.<Number>) : void
		{
			m_uvRawData = data;
			
			if(m_uvBuffer){
				m_uvBuffer.dispose();
				m_uvBuffer = null;
			}
		}
		
		public function get normalRawData() : Vector.<Number>
		{
			return m_normalRawData;
		}
		
		public function set normalRawData(data : Vector.<Number>) : void
		{
			m_normalRawData = data;
			
			if(m_normalBuffer){
				m_normalBuffer.dispose();
				m_normalBuffer = null;
			}
		}
		
		/**
		 * 如果buffer 没有创建，则创建一次
		 */
		private function checkBuffer() : void
		{
			if(m_indexRawData && !m_indexBuffer)
			{
				m_indexBuffer = View.context.createIndexBuffer(m_indexRawData.length);
				m_indexBuffer.uploadFromVector(m_indexRawData,0,m_indexRawData.length);
			}
			
			if(m_vertexRawData && !m_vertexBuffer)
			{
				m_vertexBuffer = View.context.createVertexBuffer(m_vertexRawData.length/3,3);
				m_vertexBuffer.uploadFromVector(m_vertexRawData,0,m_vertexRawData.length/3);
			}
			
			if(m_uvRawData && !m_uvBuffer)
			{
				m_uvBuffer = View.context.createVertexBuffer(m_uvRawData.length/2,2)
				m_uvBuffer.uploadFromVector(m_uvRawData,0,m_uvRawData.length/2);
			}
			
			if(m_normalRawData && !m_normalBuffer)
			{
				m_normalBuffer = View.context.createVertexBuffer(m_normalRawData.length/3,3);
				m_normalBuffer.uploadFromVector(m_normalRawData,0,m_normalRawData.length/3);
			}
		}
		
		/**
		 * 模型矩阵放置在 124 末位
		 * 顶点	vt0
		 * 纹理	vt1
		 * 法线	vt2
		 * 贴图	fs0
		 * 
		 * fc0 材质提供的数据
		 */
		public function render() : void
		{
			checkBuffer();
			
			if(m_transformDirty)
				updateTransform();
			
			m_finalMatrix.identity();
			m_finalMatrix.append(m_transform);
			m_finalMatrix.append(View.camera.getViewMatrix());
			
			var parent : Object3DContainer = m_parent;
			while(null != parent){
				m_finalMatrix.append(parent.transform);
				parent = parent.parent;
			}
			
			//渲染材质
			if(!m_program)
				createProgram();
			
			View.context.setProgram(m_program);
			View.context.setTextureAt(0,m_material.getTexture());
			View.context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT,0,m_material.getMatrialData());
			
			View.context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 124, m_finalMatrix, true);
			
			View.context.setVertexBufferAt(0, m_vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			View.context.setVertexBufferAt(1,m_uvBuffer,0,Context3DVertexBufferFormat.FLOAT_2);
			
			if(m_normalBuffer)
				View.context.setVertexBufferAt(2,m_normalBuffer,0,Context3DVertexBufferFormat.FLOAT_3);
			
			View.context.drawTriangles(m_indexBuffer,0,m_numTriangles);
			
			View.context.setTextureAt(0, null);
		}
		
		/**
		 * 内部构建一个Program
		 * v0 为 uv
		 * 从材质获取FragmentStr
		 */
		private function createProgram() : void
		{
			var vertexProgram : AGALMiniAssembler = new AGALMiniAssembler();
			vertexProgram.assemble(Context3DProgramType.VERTEX,
				"m44 op, va0, vc124\n"+
				"mov v0, va1");
			
			var fragementProgram : AGALMiniAssembler = new AGALMiniAssembler();
			fragementProgram.assemble(Context3DProgramType.FRAGMENT,
				m_material.getFragmentStr());
			
			m_program = View.context.createProgram();
			m_program.upload(vertexProgram.agalcode,fragementProgram.agalcode);
		}
		
		public function get parent() : Object3DContainer
		{
			return m_parent;
		}
		
		public function set parent(value : Object3DContainer) : void
		{
			m_parent = value;
		}
		
		public function get name() : String
		{
			return m_name;
		}
		
		public function set name(value : String) : void
		{
			m_name = value;
		}
		
		public override function dispose():void
		{
			super.dispose();
			m_finalMatrix = null;
		}
		
		protected var m_finalMatrix : Matrix3D = new Matrix3D();
		
		protected var m_name : String;
		protected var m_width : int;
		protected var m_height : int;
		protected var m_parent : Object3DContainer;
		protected var m_numTriangles : uint;
		protected var m_program : Program3D;
		
		protected var m_uvBuffer : VertexBuffer3D;
		protected var m_vertexBuffer : VertexBuffer3D;
		protected var m_indexBuffer : IndexBuffer3D;
		protected var m_normalBuffer : VertexBuffer3D;
		
		protected var m_uvRawData : Vector.<Number>;
		protected var m_vertexRawData : Vector.<Number>;
		protected var m_indexRawData : Vector.<uint>;
		protected var m_normalRawData : Vector.<Number>;
	}
}