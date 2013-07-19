package C3.Core.Managers
{
	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.display3D.textures.TextureBase;
	import flash.utils.Dictionary;
	
	import C3.IDispose;

	/**
	 * 缓存不同Context的Texture
	 */
	public class TextureManager implements IDispose
	{
		public function TextureManager()
		{
		}
		
		public static function getTexture(context3D : Context3D, key : BitmapData) : TextureBase
		{
			if(!m_contextDict.hasOwnProperty(context3D) || !m_contextDict[context3D].hasOwnProperty(key)) return null;
			
			return m_contextDict[context3D][key];
		}
		
		public static function cacheTexture(context3D : Context3D, texture : TextureBase, key : BitmapData) : void
		{
			if(!m_contextDict.hasOwnProperty(context3D))
				m_contextDict[context3D] = new Dictionary();
			
			m_contextDict[context3D][key] = texture;
		}
		
		public static function dispose():void
		{
			var dict : Dictionary;
			for each(dict in m_contextDict)
			{
				var key : String;
				for each(key in dict){
					TextureBase(dict[key]).dispose();
					BitmapData(key).dispose();
					key = null;
				}
			}
			m_contextDict = null;
		}

		private static var m_contextDict : Dictionary = new Dictionary();
	}
}