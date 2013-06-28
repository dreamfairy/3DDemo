package C3.Material
{
	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.display3D.textures.Texture;
	
	import C3.View;

	public class DefaultMaterialManager
	{
		private static var m_defultTexture : Texture;
		private static var m_defaultTextureBitmapData : BitmapData;
		
		public static function getDefaultTexture(context : Context3D = null) : Texture
		{
			if(!m_defultTexture)
				createDefaultTexture(context ? context : View.context);
			
			return m_defultTexture;
		}
		
		private static function createDefaultTexture(context : Context3D) : void
		{
			m_defaultTextureBitmapData = new BitmapData(8,8,false,0x0);
			
			var i:uint, j:uint;
			for (i=0; i<8; i++) {
				for (j=0; j<8; j++) {
					if ((j & 1) ^ (i & 1))
						m_defaultTextureBitmapData.setPixel(i, j, 0XFFFFFF);
				}
			}
			
			m_defultTexture = Utils.getTextureByBmd(m_defaultTextureBitmapData, context);
		}
	}
}