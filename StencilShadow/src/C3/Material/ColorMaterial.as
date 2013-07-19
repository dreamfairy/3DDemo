package C3.Material
{
	import flash.display3D.Context3D;
	import flash.display3D.textures.Texture;
	import flash.display3D.textures.TextureBase;
	
	import C3.PostRender.IPostRender;

	public class ColorMaterial implements IMaterial
	{
		public function ColorMaterial(color : uint, alpha : Number)
		{
			var r : Number = ((color & 0xFF0000) >> 16)/256;
			var g : Number = ((color & 0x00FF00) >> 8)/256;
			var b : Number = (color & 0x0000FF)/256; 
			
			m_colorVector = Vector.<Number>([r,g,b,alpha]);
			
			updateFragmentStr();
		}
		
		public function getMatrialData():Vector.<Number>
		{
			return m_colorVector;
		}
		
		public function dispose():void
		{
			m_texture.dispose();
			m_colorVector = null;
		}
		
		public function setRGBA(r : Number, g : Number, b : Number, a : Number) : void
		{
			m_colorVector = Vector.<Number>([r,g,b,a]);
		}
		
		public function getFragmentStr(item : IPostRender):String
		{
			return m_fragmentStr;
		}
		
		public function updateFragmentStr():void
		{
			m_fragmentStr = 
				"tex ft0, v0, fs0<2d,repeat>\n" +
				"mul ft0, ft0, fc0\n" +
				"mov oc, ft0";
		}
		
		public function getTexture(context3D : Context3D) : TextureBase
		{
			m_texture ||= DefaultMaterialManager.getDefaultTexture(context3D);
			return m_texture;
		}
		
		private var m_texture : Texture;
		private var m_fragmentStr : String;
		private var m_colorVector : Vector.<Number>;
	}
}