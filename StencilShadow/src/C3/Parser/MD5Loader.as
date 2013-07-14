package C3.Parser
{
	import C3.Animator.Animator;
	import C3.Event.AOI3DLOADEREVENT;
	import C3.Geoentity.AnimGeoentity;
	import C3.Geoentity.MeshGeoentity;
	import C3.MD5.MD5Joint;
	import C3.MD5.MD5MeshParser;
	import C3.MD5.MD5Vertex;
	import C3.MD5.MD5Weight;
	import C3.MD5.MeshData;
	import C3.Material.IMaterial;
	import C3.Object3D;
	import C3.Object3DContainer;
	import C3.View;
	
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.geom.Vector3D;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;

	public class MD5Loader extends MeshGeoentity
	{
		public function MD5Loader(name : String, mat : IMaterial)
		{
			super(name, mat);
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
			var obj : Object3D = new Object3D(m_name,m_material);
			var meshData : MeshData = event.mesh;
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
					var joint2 : MD5Joint = m_md5MeshParser.md5_joint[weight.jointID];
					
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
			
			addChild(obj);
		}
		
		override public function updateMatrix():void
		{
			if(m_transformDirty)
				updateTransform();
			
			m_finalMatrix.identity();
			m_finalMatrix.append(m_transform);
			m_finalMatrix.append(View.camera.getViewMatrix());
			
			var parent : Object3DContainer = m_parent;
			while(null != parent){
				parent.isRoot ? m_finalMatrix.append(parent.projMatrix) : m_finalMatrix.append(parent.transform);
				parent = parent.parent;
			}
			
			View.context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 124, m_finalMatrix, true);
		}
		
		override public function updateMaterial():void
		{
			View.context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT,0,m_material.getMatrialData());
			View.context.setTextureAt(0,m_material.getTexture());
		}
		
		public override function render():void
		{
			if(m_animator){
				if(m_animator.render())
					return;
			}
			
			updateMatrix();
			updateMaterial();
			
			//渲染材质
			if(!m_program)
				createProgram();
			
			View.context.setProgram(m_program);
			
			
			var obj : Object3D;
			for each(obj in m_modelList)
			{
				View.context.setVertexBufferAt(0, obj.vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
				View.context.setVertexBufferAt(1, obj.uvBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
				View.context.drawTriangles(obj.indexBuffer);
			}
			
			View.context.setTextureAt(0,null);
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
		
		public override function get meshDatas() : Vector.<MeshData>
		{
			return m_md5MeshParser.md5_mesh;
		}
		
		public override function get joints():Vector.<MD5Joint>
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
		
		private var m_md5MeshParser : MD5MeshParser;
		private var m_loader : URLLoader;
		private var m_animator : Animator;
		private var m_useCPU : Boolean;
	}
}