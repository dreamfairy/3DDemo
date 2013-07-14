package C3
{
	import C3.Material.IMaterial;
	import C3.Mesh.MeshBase;
	import C3.PostRender.IPostRender;
	
	import com.adobe.utils.AGALMiniAssembler;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Matrix3D;
	import flash.utils.Dictionary;
	
	public class Object3D extends MeshBase
	{
		public function Object3D(name : String, mat:IMaterial)
		{
			super(mat);
			m_name = name;
		}
		
		public function set shadowMapping(item : IPostRender) : void
		{
			m_shadowMap = item;
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
		 * 骨骼顶点
		 */
		public function set jointIndexRawData(data : Vector.<Number>) : void
		{
			m_jointIndexRawData = data;
			
			if(m_jointIndexBuffer){
				m_jointIndexBuffer.dispose();
				m_jointIndexBuffer = null;
			}
		}
		
		public function get jointIndexRawData() : Vector.<Number>
		{
			return m_jointIndexRawData;
		}
		
		/**
		 * 骨骼权重
		 */
		public function set jointWeightRawData(data : Vector.<Number>) : void
		{
			m_jointWeightRawData = data;
			
			if(m_jointWeightBuffer){
				m_jointWeightBuffer.dispose();
				m_jointWeightBuffer = null;
			}
		}
		
		public function get jointWeightRawData() : Vector.<Number>
		{
			return m_jointWeightRawData;
		}
		
		/**
		 * 多context3D 测试开始
		 */
		public function getVertexBufferByContext(context : Context3D) : VertexBuffer3D
		{
			if(null == m_vertexRawData) return null;
			
			if(!m_contextBufferCache.hasOwnProperty(context))
				m_contextBufferCache[context] = [];
			
			if(m_contextBufferCache.hasOwnProperty(context) &&
				m_contextBufferCache[context][AOI3DBUFFERTYPE.VERTEX])
				return m_contextBufferCache[context][AOI3DBUFFERTYPE.VERTEX];
			
			var vertexBuffer : VertexBuffer3D = context.createVertexBuffer(m_vertexRawData.length/3,3);
			vertexBuffer.uploadFromVector(m_vertexRawData,0,m_vertexRawData.length/3);
			m_contextBufferCache[context][AOI3DBUFFERTYPE.VERTEX] = vertexBuffer;
			
			return vertexBuffer;
		}
		
		public function getUvBufferByContext(context : Context3D) : VertexBuffer3D
		{
			if(null == m_uvRawData) return null;
			
			if(!m_contextBufferCache.hasOwnProperty(context))
				m_contextBufferCache[context] = [];
			
			if(m_contextBufferCache.hasOwnProperty(context) &&
				m_contextBufferCache[context][AOI3DBUFFERTYPE.UV])
				return m_contextBufferCache[context][AOI3DBUFFERTYPE.UV];
			
			var uvBuffer : VertexBuffer3D = context.createVertexBuffer(m_uvRawData.length/2,2)
			uvBuffer.uploadFromVector(m_uvRawData,0,m_uvRawData.length/2);
			m_contextBufferCache[context][AOI3DBUFFERTYPE.UV] = uvBuffer;
			
			return uvBuffer;
		}
		
		public function getIndexBufferByContext(context : Context3D) : IndexBuffer3D
		{
			if(null == m_indexRawData) return null;
			
			if(!m_contextBufferCache.hasOwnProperty(context))
				m_contextBufferCache[context] = [];
			
			if(m_contextBufferCache.hasOwnProperty(context) &&
				m_contextBufferCache[context][AOI3DBUFFERTYPE.INDEX])
				return m_contextBufferCache[context][AOI3DBUFFERTYPE.INDEX];
			
			var indexBuffer : IndexBuffer3D = context.createIndexBuffer(m_indexRawData.length);
			indexBuffer.uploadFromVector(m_indexRawData,0,m_indexRawData.length);
			m_contextBufferCache[context][AOI3DBUFFERTYPE.INDEX] = indexBuffer;
			
			return indexBuffer;
		}
		
		public function getJointIndexBufferByContext(context : Context3D) : VertexBuffer3D
		{
			if(null == m_jointIndexRawData) return null;
			
			if(!m_contextBufferCache.hasOwnProperty(context))
				m_contextBufferCache[context] = [];
			
			if(m_contextBufferCache.hasOwnProperty(context) &&
				m_contextBufferCache[context][AOI3DBUFFERTYPE.JOINT_INDEX])
				return m_contextBufferCache[context][AOI3DBUFFERTYPE.JOINT_INDEX];
			
			var jointIndexBuffer : VertexBuffer3D = context.createVertexBuffer(m_jointIndexRawData.length/userData.maxJoints, userData.maxJoints);
			jointIndexBuffer.uploadFromVector(m_jointIndexRawData,0,m_jointIndexRawData.length/userData.maxJoints);
			m_contextBufferCache[context][AOI3DBUFFERTYPE.JOINT_INDEX] = jointIndexBuffer;
			
			return jointIndexBuffer;
		}
		
		public function getJointWeightBufferByContext(context : Context3D) : VertexBuffer3D
		{
			if(null == m_jointWeightRawData) return null;
			
			if(!m_contextBufferCache.hasOwnProperty(context))
				m_contextBufferCache[context] = [];
			
			if(m_contextBufferCache.hasOwnProperty(context) &&
				m_contextBufferCache[context][AOI3DBUFFERTYPE.JOINT_WEIGHT])
				return m_contextBufferCache[context][AOI3DBUFFERTYPE.JOINT_WEIGHT];
			
			var jointWeightBuffer : VertexBuffer3D = context.createVertexBuffer(m_jointWeightRawData.length/userData.maxJoints, userData.maxJoints);
			jointWeightBuffer.uploadFromVector(m_jointWeightRawData,0,m_jointWeightRawData.length/userData.maxJoints);
			m_contextBufferCache[context][AOI3DBUFFERTYPE.JOINT_WEIGHT] = jointWeightBuffer;
			
			return jointWeightBuffer;
		}
		
		/**
		 * 多context3D 测试结束
		 */
		
		
		public function get vertexBuffer() : VertexBuffer3D
		{
			checkBuffer();
			return m_vertexBuffer;
		}
		
		public function get uvBuffer() : VertexBuffer3D
		{
			checkBuffer();
			return m_uvBuffer;
		}
		
		public function get indexBuffer() : IndexBuffer3D
		{
			checkBuffer();
			return m_indexBuffer;
		}
		
		public function get jointIndexBuffer() : VertexBuffer3D
		{
			checkBuffer();
			return m_jointIndexBuffer;
		}
		
		public function get jointWeightBuffer() : VertexBuffer3D
		{
			checkBuffer();
			return m_jointWeightBuffer;
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
			
			if(m_jointIndexRawData && !m_jointIndexBuffer)
			{
				m_jointIndexBuffer = View.context.createVertexBuffer(m_jointIndexRawData.length/userData.maxJoints, userData.maxJoints);
				m_jointIndexBuffer.uploadFromVector(m_jointIndexRawData,0,m_jointIndexRawData.length/userData.maxJoints);
			}
			
			if(m_jointWeightRawData && !m_jointWeightBuffer)
			{
				m_jointWeightBuffer = View.context.createVertexBuffer(m_jointWeightRawData.length/userData.maxJoints, userData.maxJoints);
				m_jointWeightBuffer.uploadFromVector(m_jointWeightRawData,0,m_jointWeightRawData.length/userData.maxJoints);
			}
		}
		
		public function get matrixGlobal() : Matrix3D
		{
			if(m_transformDirty)
				updateTransform();
			
			m_matrixGlobal.identity();
			m_matrixGlobal.append(m_transform);
			var parent : Object3DContainer = m_parent;
			while(null != parent && !parent.isRoot){
				m_matrixGlobal.append(parent.transform);
				parent = parent.parent;
			}
			
			return m_matrixGlobal;
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
			
			var parent : Object3DContainer = m_parent;
			while(null != parent){
				parent.isRoot ? m_finalMatrix.append(parent.projMatrix) : parent.appendChildMatrix(m_finalMatrix);
				parent = parent.parent;
			}
			
			//渲染材质
			if(!m_program)
				createProgram();
			
			View.context.setProgram(m_program);
			
			/**
			 * 如果有阴影图，且阴影图未绘制完毕，则不需要创建自己的纹理
			 * 如果没有阴影图，或者阴影图绘制完毕，绘制自己的纹理
			 */
			if(!m_shadowMap || m_shadowMap.hasPassDoen)
				View.context.setTextureAt(0,m_material.getTexture());
			
			View.context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT,0,m_material.getMatrialData());
			
			View.context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 124, m_finalMatrix, true);
			
			View.context.setVertexBufferAt(0, m_vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			View.context.setVertexBufferAt(1,m_uvBuffer,0,Context3DVertexBufferFormat.FLOAT_2);
			
//			if(m_normalBuffer)
//				View.context.setVertexBufferAt(2,m_normalBuffer,0,Context3DVertexBufferFormat.FLOAT_3);
			
			View.context.drawTriangles(m_indexBuffer,0,m_numTriangles);
			
			View.context.setTextureAt(0, null);
		}
		
		/**
		 * 内部构建一个Program
		 * v0 为 uv
		 * 从材质获取FragmentStr
		 */
		protected function createProgram() : void
		{
			var vertexProgram : AGALMiniAssembler = new AGALMiniAssembler();
			vertexProgram.assemble(Context3DProgramType.VERTEX,
				"m44 op, va0, vc124\n"+
				"mov v0, va1");
			
			var fragementProgram : AGALMiniAssembler = new AGALMiniAssembler();
			fragementProgram.assemble(Context3DProgramType.FRAGMENT,
				m_material.getFragmentStr(m_shadowMap));
			
			m_program = View.context.createProgram();
			m_program.upload(vertexProgram.agalcode,fragementProgram.agalcode);
		}
		
		public function get numTriangles() : uint
		{
			return m_numTriangles;
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
			
			for each(var key : String in m_contextBufferCache)
			{
				var arr : Array = m_contextBufferCache[key];
				for each(var buffer : * in arr){
					buffer.dispose();
				}
			}
			m_contextBufferCache = null;
		}
		
		public function set pickEnabled(bool : Boolean) : void
		{
			m_pickEnabled = bool
		}
		
		public function get pickEnabled() : Boolean
		{
			return m_pickEnabled;
		}
		
		public function set visible(bool : Boolean) : void
		{
			m_visible = bool;
		}
		
		public function get visible() : Boolean
		{
			return m_visible;
		}
		
		public function set interactive(bool : Boolean) : void
		{
			m_interactive = bool;
		}
		
		public function get interactive() : Boolean
		{
			return m_interactive;
		}
		
		/**
		 * 缓存多个context创建的buffer
		 */
		protected var m_contextBufferCache : Dictionary = new Dictionary();
		
		protected var m_interactive : Boolean;
		protected var m_visible : Boolean;
		protected var m_pickEnabled : Boolean;
		protected var m_finalMatrix : Matrix3D = new Matrix3D();
		protected var m_matrixGlobal : Matrix3D = new Matrix3D();
		
		protected var m_name : String;
		protected var m_width : int;
		protected var m_height : int;
		protected var m_parent : Object3DContainer;
		protected var m_numTriangles : uint;
		protected var m_program : Program3D;
		protected var m_shadowMap : IPostRender;
		
		protected var m_uvBuffer : VertexBuffer3D;
		protected var m_vertexBuffer : VertexBuffer3D;
		protected var m_indexBuffer : IndexBuffer3D;
		protected var m_normalBuffer : VertexBuffer3D;
		protected var m_jointIndexBuffer : VertexBuffer3D;
		protected var m_jointWeightBuffer : VertexBuffer3D;
		
		protected var m_uvRawData : Vector.<Number>;
		protected var m_vertexRawData : Vector.<Number>;
		protected var m_indexRawData : Vector.<uint>;
		protected var m_normalRawData : Vector.<Number>;
		protected var m_jointIndexRawData : Vector.<Number>;
		protected var m_jointWeightRawData : Vector.<Number>;
	}
}