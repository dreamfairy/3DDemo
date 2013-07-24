package C3.Parser
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTriangleFace;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import C3.Object3D;
	import C3.Animator.AnimalState;
	import C3.Animator.AnimationSet;
	import C3.Camera.Camera;
	import C3.Event.AOI3DLOADEREVENT;
	import C3.Geoentity.MeshGeoentity;
	import C3.Material.IMaterial;
	import C3.Material.Shaders.ShaderSimple;
	import C3.OGRE.MeshData;
	import C3.OGRE.OGREAnimParser;
	import C3.OGRE.OGREMeshParser;
	import C3.Parser.Model.IJoint;

	public class ORGEMeshLoader extends MeshGeoentity
	{
		public function ORGEMeshLoader(name : String, mat : IMaterial, autoLoadSkelton : Boolean = false)
		{
			super(name, mat);
			m_ogreMeshParser = new OGREMeshParser(true);
			m_ogreMeshParser.addEventListener(Event.COMPLETE, onAllMeshLoaded);
			m_ogreMeshParser.addEventListener(AOI3DLOADEREVENT.ON_MESH_LOADED, onMeshLoaded);
			m_ogreMeshParser.addEventListener(AOI3DLOADEREVENT.REQUEST_SKELETON, requestSkeleton);
		}
		
		public function loadMesh(uri : *) : void
		{
			if(uri is ByteArray){
				m_ogreMeshParser.load(uri);
			}else if(uri is String){
				m_sourceFolder = uri.substring(0,uri.lastIndexOf("/") + 1);
				m_loadState = LOAD_MESH;
				loadData(uri);
			}
		}
		
		public function loadSkeleton(uri : *) : void
		{
			return;
			
			m_ogreSkeletonParser ||= new OGREAnimParser();
			if(uri is ByteArray){
				m_ogreSkeletonParser.load(uri);
			}else if(uri is String){
				if(m_hasMeshData){
					m_loadState = LOAD_SKELETON;
					loadData(m_sourceFolder + uri + ".xml");
				}else{
					m_skeletonDownloadList||=new Vector.<String>();
					m_skeletonDownloadList.push(uri);
				}
			}
		}
		
		private function requestSkeleton(e : AOI3DLOADEREVENT) : void
		{
			m_loadState = LOAD_SKELETON_LINK;
			loadData(m_sourceFolder + e.data + ".xml");
		}
		
		public override function render(context:Context3D, camera:Camera):void
		{
			for each(var child : Object3D in m_modelList)
			{
				child.render(context,camera);
				child.shader.render(context);
			}
			
			if(m_animatorSet)m_animatorSet.render();
		}
		
		private function onAllMeshLoaded(e:Event) : void
		{
			m_hasMeshData = true;
		}
		
		private function onMeshLoaded(e:AOI3DLOADEREVENT) : void
		{
			var obj : Object3D = new Object3D(m_name, m_material);
			var meshData : MeshData = e.data;
			obj.uvRawData = meshData.getUv();
			obj.indexRawData = meshData.getIndex();
			obj.vertexRawData = meshData.getVertex();
			obj.numTriangles = meshData.ogre_numTriangle;
			obj.shader = new ShaderSimple(obj);
			obj.shader.material = m_material;
			obj.shader.params.culling = Context3DTriangleFace.FRONT;
			
			obj.pickEnabled = m_pickEnabled;
			obj.interactive = m_interactive;
			obj.buttonMode = m_buttonMode;
			
			if(onMouseClick.numListeners){
				obj.onMouseClick = onMouseClick;
			}
			addChild(obj);
		}
		
		private function loadData(url : String) : void
		{
			m_urlRequest||=new URLRequest();
			m_loader||= new URLLoader();
			m_urlRequest.url = url;
			
			m_loader.dataFormat = URLLoaderDataFormat.BINARY;
			m_loader.addEventListener(Event.COMPLETE, onLoadData);
			m_loader.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
			m_loader.load(m_urlRequest);
		}
		
		private function onLoadError(e:IOErrorEvent) : void
		{
			trace(e.text,this);
		}
		
		private function clearEvent() : void
		{
			return;
			m_loader.removeEventListener(Event.COMPLETE, onLoadData);
			m_loader.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		}
		
		private function onLoadData(e:Event) : void
		{
			switch(m_loadState){
				case LOAD_MESH:
					m_ogreMeshParser.load(m_loader.data);
					break;
				case LOAD_SKELETON_LINK:
					m_ogreMeshParser.loadSkeleton(m_loader.data);
					break;
				case LOAD_SKELETON:
					break;
			}
		}
		
		public override function get maxJoints():uint
		{
			return m_ogreMeshParser.maxJoints;
		}
		
		public override function get joints():Vector.<IJoint>
		{
			return m_ogreMeshParser.joints;
		}
		
		public function addAnimalState(state : AnimalState) : void
		{
			m_animatorSet ||= new AnimationSet(this);
			m_animatorSet.add(state);
		}

		private var m_hasMeshData : Boolean = false;
		private var m_sourceFolder : String;
		private var m_loader : URLLoader;
		private var m_ogreMeshParser : OGREMeshParser;
		private var m_ogreSkeletonParser : OGREAnimParser;
		private var m_animatorSet : AnimationSet;
		private var m_skeletonDownloadList : Vector.<String>;
		private var m_loadState : int = -1;
		private var m_urlRequest : URLRequest;
		
		private static const LOAD_SKELETON_LINK : uint = 0;
		private static const LOAD_MESH : uint = 1;
		private static const LOAD_SKELETON : uint = 2;
	}
}