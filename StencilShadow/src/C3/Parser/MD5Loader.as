package C3.Parser
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.geom.Vector3D;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import C3.Object3D;
	import C3.Object3DContainer;
	import C3.Animator.Animator;
	import C3.Camera.ICamera;
	import C3.Event.AOI3DLOADEREVENT;
	import C3.Geoentity.AnimGeoentity;
	import C3.Geoentity.MeshGeoentity;
	import C3.MD5.MD5Joint;
	import C3.MD5.MD5MeshData;
	import C3.MD5.MD5MeshParser;
	import C3.MD5.MD5Vertex;
	import C3.MD5.MD5Weight;
	import C3.Material.IMaterial;
	import C3.Material.Shaders.ShaderSimple;
	import C3.Parser.Model.IJoint;

	public class MD5Loader extends MeshGeoentity
	{
		public function MD5Loader(name : String, mats : Vector.<IMaterial>)
		{
			super(name, null);
			m_mats = mats;
			m_md5MeshParser = new MD5MeshParser();
			m_md5MeshParser.addEventListener(AOI3DLOADEREVENT.ON_MESH_LOADED, onMeshLoaded);
			m_md5MeshParser.addEventListener(Event.COMPLETE, onAllMeshLoaded);
		}
		
		public function load(uri : *) : void
		{
			if(uri is ByteArray){
				m_md5MeshParser.load(uri);
			}else if(uri is String){
				loadData(uri);
			}
		}
		
		private function onAllMeshLoaded(e:Event) : void
		{
			m_md5MeshParser.removeEventListener(AOI3DLOADEREVENT.ON_MESH_LOADED, onMeshLoaded);
			m_md5MeshParser.removeEventListener(Event.COMPLETE, onAllMeshLoaded);
			m_useCPU = m_md5MeshParser.md5_joint.length * 4 > 128;
		}
		
		/**
		 * 单个网格加载完毕
		 */
		private function onMeshLoaded(event:AOI3DLOADEREVENT) : void
		{
			var mat : IMaterial = m_mats.shift();
			var obj : Object3D = new Object3D(m_name,mat);
			var meshData : MD5MeshData = event.data;
			obj.uvRawData = meshData.getUv();
			obj.indexRawData = meshData.getIndex();
			
			//取出最大关节数
			var maxJointCount : int = m_md5MeshParser.maxJointCount;
			var vertexLen : int = meshData.md5_vertex.length;
			
			var vertexRawData : Vector.<Number> = new Vector.<Number>(vertexLen * maxJointCount, true);
			var jointIndexRawData : Vector.<Number> = new Vector.<Number>(vertexLen * maxJointCount, true);
			var jointWeightRawData : Vector.<Number> =  new Vector.<Number>(vertexLen * maxJointCount, true);
			
			var nonZeroWeights : int;
			var l : int;
			var finalVertex : Vector3D;
			var vertex : MD5Vertex;
			
			for(var i : int = 0; i < vertexLen; i++)
			{
				finalVertex = new Vector3D();
				vertex = meshData.md5_vertex[i];
				nonZeroWeights = 0;
				//遍历每个顶点的总权重
				for(var j : int = 0; j < vertex.weight_count; j++)
				{
					//取出当前顶点的权重
					var weight : MD5Weight = meshData.md5_weight[vertex.weight_index + j];
					//取出当前顶点对应的关节
					var joint2 : MD5Joint = m_md5MeshParser.md5_joint[weight.jointID] as MD5Joint;
					
					//将权重转换为关节坐标系为参考的值
					var wv : Vector3D = joint2.bindPose.transformVector(weight.pos);
					//进行权重缩放
					wv.scaleBy(weight.bias);
					//输出转换后的顶点
					finalVertex = finalVertex.add(wv);
					
					jointIndexRawData[l] = weight.jointID * 4;
					jointWeightRawData[l++] = weight.bias;
					++nonZeroWeights;
				}
				
				for(j = nonZeroWeights; j < maxJointCount; ++j)
				{
					jointIndexRawData[l] = 0;
					jointWeightRawData[l++] = 0;
				}
				
				var startIndex : int = i * 3;
				vertexRawData[startIndex] = finalVertex.x; 
				vertexRawData[startIndex+1] = finalVertex.y; 
				vertexRawData[startIndex+2] = finalVertex.z; 
			}
			
			obj.vertexRawData = vertexRawData;
			obj.userData = {meshData : meshData, maxJoints : maxJointCount};
			obj.jointIndexRawData = jointIndexRawData;
			obj.jointWeightRawData = jointWeightRawData;
			obj.numTriangles = meshData.num_tris;
			obj.castShadow = castShadow;
			obj.receiveShadow = receiveShadow;
			
			var shader : ShaderSimple = new ShaderSimple(obj);
			shader.material = m_material;
			obj.setShader(shader);
			
			addChild(obj);
		}
		
		override public function updateMatrix():void
		{
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
			
			m_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 124, m_finalMatrix, true);
		}
		
		override public function updateMaterial():void
		{
			m_context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT,0,m_material.getMatrialData());
			m_context.setTextureAt(0,m_material.getTexture(m_context));
		}
		
		public override function render(context:Context3D, camera:ICamera):void
		{
			m_context = context;
			m_camera = camera;
			
			if(m_transformDirty)
				updateTransform();
			
			animator.render(context);
			
			for each(var child : Object3D in m_modelList)
			{
				child.render(context, camera);
			}
			
//			trace(matrixGlobal.position);
		}
		
		private function loadData(url : String) : void
		{
			m_loader = new URLLoader();
			m_loader.dataFormat = URLLoaderDataFormat.BINARY;
			m_loader.addEventListener(Event.COMPLETE, onLoadData);
			m_loader.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
			m_loader.load(new URLRequest(url));
		}
		
		private function onLoadError(e:IOErrorEvent) : void
		{
			trace(e.text,this);
		}
		
		private function onLoadData(e:Event) : void
		{
			m_md5MeshParser.load(m_loader.data);
		}
		
		public function addAnimation(anim : AnimGeoentity) : void
		{
			animator.addAnimation(anim);
		}
		
		public function get animator() : Animator
		{
			if(null == m_animator){
				m_animator = new Animator();
				m_animator.bind(this);
			}
			
			return m_animator;
		}
		
		public override function get meshDatas():*
		{
			return m_md5MeshParser.md5_mesh;
		}
		
		public override function get joints():Vector.<IJoint>
		{
			return m_md5MeshParser.md5_joint;
		}
		
		public override function get useCPU():Boolean
		{
			return m_useCPU;
		}
		
		public override function get maxJoints():uint
		{
			return m_md5MeshParser.maxJointCount;
		}
		
		private var m_mats : Vector.<IMaterial>;
		private var m_md5MeshParser : MD5MeshParser;
		private var m_loader : URLLoader;
		private var m_animator : Animator;
		private var m_useCPU : Boolean;
	}
}