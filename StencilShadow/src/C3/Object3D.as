package C3
{
	import flash.display3D.Context3D;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.events.Event;
	import flash.geom.Matrix3D;
	import flash.geom.Orientation3D;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	
	import C3.Camera.Camera;
	import C3.Core.Managers.MaterialManager;
	import C3.Material.IMaterial;
	import C3.Material.Shaders.Shader;
	import C3.Material.Shaders.ShaderDepthMap;
	import C3.Material.Shaders.ShaderParamters;
	import C3.Material.Shaders.ShaderShadowMap;
	import C3.Mesh.MeshBase;
	import C3.Pool.ContextCache;
	
	import org.osflash.signals.Signal;
	
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
			
			var cache : ContextCache = hasCache(context);
			
			if(null == cache){
				cache = new ContextCache(context);
				m_contextBufferCache[cache.key] = cache;
			}
			
			if(!cache.shaderCache.hasOwnProperty(AOI3DBUFFERTYPE.VERTEX)){
				var vertexBuffer : VertexBuffer3D = context.createVertexBuffer(m_vertexRawData.length/3,3);
				vertexBuffer.uploadFromVector(m_vertexRawData,0,m_vertexRawData.length/3);
				cache.shaderCache[AOI3DBUFFERTYPE.VERTEX] = vertexBuffer;
			}

			return cache.shaderCache[AOI3DBUFFERTYPE.VERTEX];
		}
		
		public function getUvBufferByContext(context : Context3D) : VertexBuffer3D
		{
			if(null == m_uvRawData) return null;
			
			var cache : ContextCache = hasCache(context);
			
			if(null == cache){
				cache = new ContextCache(context);
				m_contextBufferCache[cache.key] = cache;
			}
			
			if(!cache.shaderCache.hasOwnProperty(AOI3DBUFFERTYPE.UV)){
				var uvBuffer : VertexBuffer3D = context.createVertexBuffer(m_uvRawData.length/2,2)
				uvBuffer.uploadFromVector(m_uvRawData,0,m_uvRawData.length/2);
				cache.shaderCache[AOI3DBUFFERTYPE.UV] = uvBuffer;
			}

			return cache.shaderCache[AOI3DBUFFERTYPE.UV];
		}
		
		public function getIndexBufferByContext(context : Context3D) : IndexBuffer3D
		{
			if(null == m_indexRawData) return null;
			
			var cache : ContextCache = hasCache(context);
			
			if(null == cache){
				cache = new ContextCache(context);
				m_contextBufferCache[cache.key] = cache;
			}
			
			if(!cache.shaderCache.hasOwnProperty(AOI3DBUFFERTYPE.INDEX)){
				var indexBuffer : IndexBuffer3D = context.createIndexBuffer(m_indexRawData.length);
				indexBuffer.uploadFromVector(m_indexRawData,0,m_indexRawData.length);
				cache.shaderCache[AOI3DBUFFERTYPE.INDEX] = indexBuffer;
			}
			
			return cache.shaderCache[AOI3DBUFFERTYPE.INDEX];
		}
		
		public function getJointIndexBufferByContext(context : Context3D) : VertexBuffer3D
		{
			if(null == m_jointIndexRawData) return null;
			
			var cache : ContextCache = hasCache(context);
			
			if(null == cache){
				cache = new ContextCache(context);
				m_contextBufferCache[cache.key] = cache;
			}
			
			if(!cache.shaderCache.hasOwnProperty(AOI3DBUFFERTYPE.JOINT_INDEX)){
				var jointIndexBuffer : VertexBuffer3D = context.createVertexBuffer(m_jointIndexRawData.length/userData.maxJoints, userData.maxJoints);
				jointIndexBuffer.uploadFromVector(m_jointIndexRawData,0,m_jointIndexRawData.length/userData.maxJoints);
				cache.shaderCache[AOI3DBUFFERTYPE.JOINT_INDEX] = jointIndexBuffer;
			}
			
			return cache.shaderCache[AOI3DBUFFERTYPE.JOINT_INDEX];
		}
		
		public function getJointWeightBufferByContext(context : Context3D) : VertexBuffer3D
		{
			if(null == m_jointWeightRawData) return null;
			
			var cache : ContextCache = hasCache(context);
			
			if(null == cache){
				cache = new ContextCache(context);
				m_contextBufferCache[cache.key] = cache;
			}
			
			if(!cache.shaderCache.hasOwnProperty(AOI3DBUFFERTYPE.JOINT_WEIGHT)){
				var jointWeightBuffer : VertexBuffer3D = context.createVertexBuffer(m_jointWeightRawData.length/userData.maxJoints, userData.maxJoints);
				jointWeightBuffer.uploadFromVector(m_jointWeightRawData,0,m_jointWeightRawData.length/userData.maxJoints);
				cache.shaderCache[AOI3DBUFFERTYPE.JOINT_WEIGHT] = jointWeightBuffer;
			}
			
			return cache.shaderCache[AOI3DBUFFERTYPE.JOINT_WEIGHT];
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
		protected function checkBuffer() : void
		{
			if(null == m_context) return;
			
			if(m_indexRawData && !m_indexBuffer)
			{
				m_indexBuffer = m_context.createIndexBuffer(m_indexRawData.length);
				m_indexBuffer.uploadFromVector(m_indexRawData,0,m_indexRawData.length);
			}
			
			if(m_vertexRawData && !m_vertexBuffer)
			{
				m_vertexBuffer = m_context.createVertexBuffer(m_vertexRawData.length/3,3);
				m_vertexBuffer.uploadFromVector(m_vertexRawData,0,m_vertexRawData.length/3);
			}
			
			if(m_uvRawData && !m_uvBuffer)
			{
				m_uvBuffer = m_context.createVertexBuffer(m_uvRawData.length/2,2)
				m_uvBuffer.uploadFromVector(m_uvRawData,0,m_uvRawData.length/2);
			}
			
			if(m_normalRawData && !m_normalBuffer)
			{
				m_normalBuffer = m_context.createVertexBuffer(m_normalRawData.length/3,3);
				m_normalBuffer.uploadFromVector(m_normalRawData,0,m_normalRawData.length/3);
			}
			
			if(m_jointIndexRawData && !m_jointIndexBuffer)
			{
				m_jointIndexBuffer = m_context.createVertexBuffer(m_jointIndexRawData.length/userData.maxJoints, userData.maxJoints);
				m_jointIndexBuffer.uploadFromVector(m_jointIndexRawData,0,m_jointIndexRawData.length/userData.maxJoints);
			}
			
			if(m_jointWeightRawData && !m_jointWeightBuffer)
			{
				m_jointWeightBuffer = m_context.createVertexBuffer(m_jointWeightRawData.length/userData.maxJoints, userData.maxJoints);
				m_jointWeightBuffer.uploadFromVector(m_jointWeightRawData,0,m_jointWeightRawData.length/userData.maxJoints);
			}
		}
		
		public function get matrixGlobal() : Matrix3D
		{
			if(m_transformDirty)
				updateTransform();
			
			if(m_parent){
				m_matrixGlobal.copyFrom(m_parent.matrixGlobal);
				m_matrixGlobal.prepend(m_transform);
			}
			
//			var parent : Object3DContainer = m_parent;
//			while(null != parent && !parent.isRoot){
//				m_matrixGlobal.append(parent.transform);
//				parent = parent.parent;
//			}
			
			return m_matrixGlobal;
		}
		
		public function getRight() : Vector3D
		{
			return m_right;
		}
		
		public function getUp() : Vector3D
		{
			return m_up;
		}
		
		public function getForward(lens : Number = 10) : Vector3D
		{
			var gm : Matrix3D = matrixGlobal;
			var forward : Vector3D = Matrix3DUtils.getForward(gm);
			forward.scaleBy(lens);
			forward = gm.position.subtract(forward);
			
			return forward;
		}
		
		public function getBack(lens : Number = 10) : Vector3D
		{
			var gm : Matrix3D = matrixGlobal;
			var back : Vector3D = Matrix3DUtils.getForward(gm);
			back.scaleBy(-lens);
			back = gm.position.subtract(back);
			
			return back;
		}
		
		public function get material() : IMaterial
		{
			return m_material;
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
		public function render(context : Context3D, camera : Camera) : void
		{
			m_context = context;
			m_camera = camera;
			
			checkBuffer();
			
			if(m_transformDirty)
				updateTransform();
			
			m_finalMatrix.identity();
			m_finalMatrix.append(m_transform);
			
			var parent : Object3DContainer = m_parent;
			while(null != parent){
				m_finalMatrix.append(parent.transform);
				parent = parent.parent;
			}
			m_finalMatrix.append(camera.viewProjMatrix);
			
			updateShader(context);
		}
		
		public function updateShader(context : Context3D) : void
		{
			var shader : Shader;
			
			for each(shader in m_shaderList){
				shader.render(context);
			}
			
			var shaderDepth : ShaderDepthMap;
			if(castShadow){
				shaderDepth = MaterialManager.getShader(Shader.DEPTH_MAP, context) as ShaderDepthMap;
				shaderDepth.addTarget(this);
			}else{
				shaderDepth = MaterialManager.getShader(Shader.DEPTH_MAP, context) as ShaderDepthMap;
				shaderDepth.removeTarget(this);
			}
			
			var shaderShadow : ShaderShadowMap;
			if(receiveShadow){
				if(!m_shaderList.hasOwnProperty(Shader.SHADOW_MAP)){
					shaderShadow = MaterialManager.getShader(Shader.SHADOW_MAP, context) as ShaderShadowMap;
					shaderShadow.addTarget(this);
					setShader(shaderShadow);
				}
				
				if(m_shaderList.hasOwnProperty(Shader.SIMPLE))
					m_shaderList[Shader.SIMPLE].enabled = false;
				
			}else{
				if(m_shaderList.hasOwnProperty(Shader.SHADOW_MAP)){
					shaderShadow = MaterialManager.getShader(Shader.SHADOW_MAP, context) as ShaderShadowMap;
					shaderShadow.removeTarget(this);
					setShader(shaderShadow,true);
				}
				
				if(m_shaderList.hasOwnProperty(Shader.SIMPLE))
					m_shaderList[Shader.SIMPLE].enabled = true;
			}
		}
		
		public function get camera() : Camera
		{
			return m_camera;
		}
		
		public function set camera(camera : Camera) : void
		{
			m_camera = camera;
		}
		
		public function get numTriangles() : uint
		{
			return m_numTriangles;
		}
		
		public function set numTriangles(value : uint) : void
		{
			m_numTriangles = value;
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
			m_camera = null;
			m_context = null;
			m_shaderList = null;
			
			onMouseClick.removeAll();
			onMouseClick = null;
			onMouseUp.removeAll();
			onMouseUp = null;
			onMouseDown.removeAll();
			onMouseDown = null;
			onMouseMove.removeAll();
			onMouseMove = null;
			
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
		
		public function set buttonMode(bool : Boolean) : void
		{
			m_buttonMode = bool
		}
		
		public function get buttonMode() : Boolean
		{
			return m_buttonMode;
		}
		
		public function get modelViewProjMatrix() : Matrix3D
		{
			return m_finalMatrix;
		}
		
		public function get modelMatrix() : Matrix3D
		{
			if(m_transformDirty)
				updateTransform();
			
			return m_transform;
		}
		
		public function getShader(type : uint) : Shader
		{
			return m_shaderList[type];
		}
		
		public function setShader(value : Shader, remove : Boolean = false) : void
		{
			if(remove)
				delete m_shaderList[value.type];
				
			if(!m_shaderList.hasOwnProperty(value.type))
				m_shaderList[value.type] = value;
		}
		
		public function setContext(context : Context3D) : void
		{
			m_context = context;
		}
		
		public function lookAt(target : Vector3D, at : Vector3D = null,  up : Vector3D = null) : void
		{
			var matrixGlobal : Matrix3D = matrixGlobal;
			if(matrixGlobal.position.z == target.z){
				target.z += 0.00001;
			}
			if(matrixGlobal.position.x == target.x){
				target.x += 0.00001;
			}
			if(matrixGlobal.position.y == target.y){
				target.y += 0.00001;
			}
			
			var tempMatrix : Matrix3D = Matrix3DUtils.TEMP_MATRIX;
			tempMatrix.identity();
			tempMatrix.position = matrixGlobal.position;
			tempMatrix.pointAt(target, at|| Quaternion.AT_VECTOR, up || Quaternion.UP_VECTOR);
			
			var rot : Vector3D = tempMatrix.decompose(Orientation3D.QUATERNION)[1];
			var ori : Quaternion = new Quaternion();
			ori.setTo(rot.w,rot.x,rot.y,rot.z);
			
			ori.toEuler(m_rotate);
			
			m_transformDirty = true;
		}
		
		private function hasCache(context : Context3D) : ContextCache
		{
			var cache : ContextCache;
			for each(cache in m_contextBufferCache){
				if(cache.context == context) return cache;
			}
			
			return null;
		}
		
		/**
		 * 缓存多个context创建的buffer
		 */
		protected var m_contextBufferCache : Dictionary = new Dictionary();
		
		protected var m_buttonMode : Boolean;
		protected var m_interactive : Boolean;
		protected var m_visible : Boolean;
		protected var m_pickEnabled : Boolean;
		protected var m_matrixGlobal : Matrix3D = new Matrix3D();
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
		protected var m_jointIndexBuffer : VertexBuffer3D;
		protected var m_jointWeightBuffer : VertexBuffer3D;
		
		protected var m_uvRawData : Vector.<Number>;
		protected var m_vertexRawData : Vector.<Number>;
		protected var m_indexRawData : Vector.<uint>;
		protected var m_normalRawData : Vector.<Number>;
		protected var m_jointIndexRawData : Vector.<Number>;
		protected var m_jointWeightRawData : Vector.<Number>;
		
		protected var m_camera : Camera;
		protected var m_context : Context3D;
		protected var m_shaderList : Dictionary = new Dictionary();
		
		protected var m_right : Vector3D = new Vector3D(1,0,0);
		protected var m_up : Vector3D = new Vector3D(0,1,0);
		protected var m_look : Vector3D = new Vector3D(0,0,-1);
		
		/**
		 * 鼠标事件
		 */
		public var onMouseClick : Signal = new Signal(Event);
		public var onMouseUp : Signal = new Signal(Event);
		public var onMouseDown : Signal = new Signal(Event);
		public var onMouseMove : Signal = new Signal(Event);
		
		/**
		 * 投影
		 */
		public var castShadow : Boolean = false;
		public var receiveShadow : Boolean = false;
		
		/**
		 * 特殊渲染选项
		 */
		public var shaderParams : ShaderParamters;
	}
}