package C3.Parser
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import C3.Event.AOI3DLOADEREVENT;
	import C3.Geoentity.AnimGeoentity;
	import C3.OGRE.OGREAnimParser;

	public class OGREAnimLoader extends AnimGeoentity
	{
		public function OGREAnimLoader(name : String)
		{
			super(name, null);
			m_ogreAnimParser = new OGREAnimParser();
			m_ogreAnimParser.addEventListener(AOI3DLOADEREVENT.ON_ANIM_LOADED, onAnimLoaded);
		}
		
		public function load(uri : *) : void
		{
			if(uri is ByteArray){
				m_ogreAnimParser.load(uri);
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
			m_ogreAnimParser.load(m_loader.data);
		}
		
		private function onAnimLoaded(e: AOI3DLOADEREVENT) : void
		{
			
		}
		
		private var m_ogreAnimParser : OGREAnimParser;
		private var m_loader : URLLoader;
	}
}