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
	import C3.Camera.Camera;
	import C3.Event.AOI3DLOADEREVENT;
	import C3.Geoentity.MeshGeoentity;
	import C3.Material.IMaterial;
	import C3.Material.Shaders.ShaderSimple;
	import C3.OGRE.MeshData;
	import C3.OGRE.OGREMeshParser;

	public class ORGEMeshLoader extends MeshGeoentity
	{
		public function ORGEMeshLoader(name : String, mat : IMaterial, autoLoadSkelton : Boolean = false)
		{
			super(name, mat);
			m_ogreMeshParser = new OGREMeshParser();
			m_ogreMeshParser.addEventListener(Event.COMPLETE, onAllMeshLoaded);
			m_ogreMeshParser.addEventListener(AOI3DLOADEREVENT.ON_MESH_LOADED, onMeshLoaded);
		}
		
		public function load(uri : *) : void
		{
			if(uri is ByteArray){
				m_ogreMeshParser.load(uri);
			}else if(uri is String){
				loadData(uri);
			}
		}
		
		public override function render(context:Context3D, camera:Camera):void
		{
			if(!m_needRender) return;
			for each(var child : Object3D in m_modelList)
			{
				child.render(context,camera);
				child.shader.render(context);
			}
		}
		
		private function onAllMeshLoaded(e:Event) : void
		{
			m_needRender = true;
		}
		
		private function onMeshLoaded(e:AOI3DLOADEREVENT) : void
		{
			var obj : Object3D = new Object3D(m_name, m_material);
			var meshData : MeshData = e.mesh;
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
			m_ogreMeshParser.load(m_loader.data);
		}

		private var m_loader : URLLoader;
		private var m_ogreMeshParser : OGREMeshParser;
		private var m_needRender : Boolean = false;
	}
}