package C3.Material
{
	import flash.display3D.textures.Texture;
	
	import C3.View;
	import C3.PostRender.IPostRender;

	public class TextureMaterial implements IMaterial
	{
		public function TextureMaterial(texture : Class, smooth : Boolean = true, repeat : Boolean = false, mipmap : Boolean = true)
		{
			m_textureClass = texture;
			m_smooth = smooth;
			m_repeat = repeat;
			m_mipmap = mipmap;
			m_materialData = new Vector.<Number>();
			updateFragmentStr();
		}
		
		public function getMatrialData():Vector.<Number>
		{
			return m_materialData;
		}
		
		public function getFragmentStr(item : IPostRender):String
		{
			m_shadowMap = item;
			if(m_shadowMap) updateFragmentStr();
			
			return m_fragmentStr;
		}
		
		public function dispose():void
		{
			m_texture.dispose();
		}
		
		public function getTexture():Texture
		{
			if(m_textureClass)
				m_texture = Utils.getTexture(m_textureClass, View.context);
			
			m_texture ||= DefaultMaterialManager.getDefaultTexture();
			return m_texture;
		}
		
		public function updateFragmentStr():void
		{
			if(null == m_shadowMap){
				m_fragmentStr = 
					"tex ft0, v0, fs0<2d," + 
					(m_repeat?"repeat":"clamp") + "," +
					(m_mipmap?"mipmap":"nomip") + "," +
					(m_smooth?"linear":"nearest")+ ">\n" +
					"mov oc, ft0";
				return;
			}
			
			
		}
		
		private var m_shadowMap : IPostRender;
		private var m_textureClass : Class;
		private var m_texture : Texture;
		private var m_smooth : Boolean;
		private var m_repeat : Boolean;
		private var m_mipmap : Boolean;
		private var m_fragmentStr : String;
		private var m_materialData : Vector.<Number>;
	}
}