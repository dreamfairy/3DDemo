package C3.Material
{
	import C3.PostRender.IPostRender;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.Texture;
	import flash.display3D.textures.TextureBase;
	
	public class RTTMaterial implements IMaterial
	{
		public function RTTMaterial(width : int, height : int)
		{
			m_width = Utils.nextPowerOfTwo(width);
			m_height = Utils.nextPowerOfTwo(height);
		}
		
		public function getMatrialData():Vector.<Number>
		{
			return null;
		}
		
		public function getFragmentStr(item:IPostRender):String
		{
			return null;
		}
		
		public function updateFragmentStr():void
		{
		}
		
		public function getTexture(context3D:Context3D):TextureBase
		{
			m_texture||=context3D.createTexture(m_width,m_height,Context3DTextureFormat.BGRA,true);
			
			return m_texture;
		}
		
		public function dispose():void
		{
		}
		
		private var m_texture : Texture;
		private var m_width : int;
		private var m_height : int;
	}
}