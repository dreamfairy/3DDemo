package C3.Material
{
	import flash.display3D.textures.Texture;

	public class TextureMaterial implements IMaterial
	{
		public function TextureMaterial(texture : Texture, smooth : Boolean = true, repeat : Boolean = false, mipmap : Boolean = true)
		{
			m_texture = texture;
			m_smooth = smooth;
			m_repeat = repeat;
			m_mipmap = mipmap;
		}
		
		public function getMatrialData():Vector.<Number>
		{
			return null;
		}
		
		public function getFragmentStr():String
		{
			// TODO Auto Generated method stub
			return null;
		}

		private var m_texture : Texture;
		private var m_smooth : Boolean;
		private var m_repeat : Boolean;
		private var m_mipmap : Boolean;
	}
}