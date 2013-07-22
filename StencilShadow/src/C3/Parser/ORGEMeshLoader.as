package C3.Parser
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import C3.OGRE.OGREMeshParser;

	public class ORGEMeshLoader
	{
		public function ORGEMeshLoader()
		{
			m_ogreMeshParser = new OGREMeshParser();
		}
		
		public function load(uri : *) : void
		{
			if(uri is ByteArray){
				m_ogreMeshParser.load(uri);
			}else if(uri is String){
				loadData(uri);
			}
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
	}
}