package C3.Parser
{
	import C3.Event.AOI3DLOADEREVENT;
	import C3.Geoentity.AnimGeoentity;
	import C3.MD5.MD5AnimParser;
	import C3.MD5.MD5BaseFrameData;
	import C3.MD5.MD5FrameData;
	import C3.MD5.MD5HierarchyData;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;

	public class MD5AnimLoader extends AnimGeoentity
	{
		public function MD5AnimLoader(name : String)
		{
			super(name,null);
			m_md5AnimParser = new MD5AnimParser();
			m_md5AnimParser.addEventListener(AOI3DLOADEREVENT.ON_ANIM_LOADED, onAnimLoaded);
		}
		
		public function load(uri : *) : void
		{
			if(uri is ByteArray){
				m_md5AnimParser.load(uri);
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
			m_md5AnimParser.load(m_loader.data);
		}
		
		/**
		 * 单个动画加载完毕
		 */
		private function onAnimLoaded(event:AOI3DLOADEREVENT) : void
		{
			m_totalFrames = m_md5AnimParser.numFrames;
			this.dispatchEvent(new AOI3DLOADEREVENT(AOI3DLOADEREVENT.ON_ANIM_LOADED,null));
		}
		
		public override function get frameDatas():Vector.<MD5FrameData>
		{
			return m_md5AnimParser.frameData;
		}
		
		public override function get baseFrameDatas():Vector.<MD5BaseFrameData>
		{
			return m_md5AnimParser.baseFrameData;
		}
		
		public override function get hierarchies():Vector.<MD5HierarchyData>
		{
			return m_md5AnimParser.hierarchy;
		}
		
		override public function get numFrams():uint
		{
			return m_md5AnimParser.numFrames;
		}
		
		public override function dispose():void
		{
			
		}
		
		private var m_totalFrames : uint;
		private var m_md5AnimParser : MD5AnimParser;
		private var m_loader : URLLoader;
	}
}