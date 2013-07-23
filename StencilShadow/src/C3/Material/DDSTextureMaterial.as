package C3.Material
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.Texture;
	import flash.display3D.textures.TextureBase;
	
	import C3.Parser.DDSParser;
	import C3.PostRender.IPostRender;
	
	public class DDSTextureMaterial implements IMaterial
	{
		public function DDSTextureMaterial(texture : DDSParser)
		{
			m_textureClass = texture;
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
			if(m_textureClass.data && !m_texture){
				m_texture = context3D.createTexture(m_textureClass.width,m_textureClass.height,
					Context3DTextureFormat.BGRA,false);
				m_texture.uploadFromByteArray(m_textureClass.data,0);
			}
			
			m_texture ||= DefaultMaterialManager.getDefaultTexture(context3D);
			return m_texture;
		}
		
		public function dispose():void
		{
			if(m_textureClass){
				m_textureClass.data.clear();
				m_textureClass = null;
			}
		}
		
		private var m_textureClass : DDSParser;
		private var m_texture : Texture;
	}
}