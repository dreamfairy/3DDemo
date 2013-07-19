package C3.Material
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.CubeTexture;
	import flash.display3D.textures.TextureBase;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import C3.View;
	import C3.PostRender.IPostRender;
	
	public class CubeMaterial implements IMaterial
	{
		public function CubeMaterial(texture : Class)
		{
			setTextureByCube(texture);
			updateFragmentStr();
		}
		
		public function setTextureBySixFace() : void
		{
			throw "这货以后再说";
		}
		
		private function setTextureByCube(texture : Class) : void
		{
			var source : BitmapData = (new texture() as Bitmap).bitmapData;
			m_size = source.width >> 2;
			initClipList();
			var tempFace : BitmapData;
			for(var i : int = 0; i < 6; i++)
			{
				tempFace = new BitmapData(m_size,m_size,false,0);
				tempFace.copyPixels(source,m_clipList[i],m_zeroPos);
				m_cubeBitmapDataList[i] = tempFace;
			}
		}
		
		private function initClipList() : void
		{
			m_clipList = new Vector.<Rectangle>();
			m_clipList.push(new Rectangle(2*m_size,m_size,m_size,m_size));
			m_clipList.push(new Rectangle(0,m_size,m_size,m_size));
			
			m_clipList.push(new Rectangle(m_size,0,m_size,m_size));
			m_clipList.push(new Rectangle(m_size,2*m_size,m_size,m_size));
			
			m_clipList.push(new Rectangle(m_size,m_size,m_size,m_size));
			m_clipList.push(new Rectangle(3*m_size,m_size,m_size,m_size));
		}
		
		public function getMatrialData():Vector.<Number>
		{
			return m_materialData;
		}
		
		public function getFragmentStr(item:IPostRender):String
		{
			if(null == m_fragmentStr)
				updateFragmentStr();
			
			return m_fragmentStr;
		}
		
		public function updateFragmentStr():void
		{
			m_fragmentStr = 
				"tex oc v0 fs0<cube,clamp,linear,miplinear>\n";
		}
		
		public function getTexture(context3D : Context3D) : TextureBase
		{
			if(null == m_cubeTexture)
				createCubeTexture(context3D);
			return m_cubeTexture;
		}
		
		public function dispose():void
		{
			m_cubeTexture.dispose();
			while(m_cubeBitmapDataList.length){
				m_cubeBitmapDataList.shift().dispose();
			}
			m_cubeBitmapDataList = null;
			m_clipList = null;
			m_zeroPos = null;
		}
		
		public function get cubeBitmapDataList() : Vector.<BitmapData>
		{
			return m_cubeBitmapDataList;
		}
		
		private function createCubeTexture(context3D : Context3D) : void
		{
			m_cubeTexture = context3D.createCubeTexture(m_size, Context3DTextureFormat.BGRA,false);
			
			for(var i : int = 0; i < 6; i++)
			{
				Utils.generateMipMapsCube(m_cubeBitmapDataList[i],m_cubeTexture,i);
			}
		}
		
		private var m_cubeTexture : CubeTexture;
		private var m_size : int;
		private var m_cubeBitmapDataList : Vector.<BitmapData> = new Vector.<BitmapData>();
		private var m_clipList : Vector.<Rectangle>;
		private var m_fragmentStr : String;
		private var m_zeroPos : Point = new Point();
		private var m_materialData : Vector.<Number> = Vector.<Number>([1,0,0,0]);
		
		public static const POSITIVE_X:uint = 0;
		public static const NEGATIVE_X:uint = 1;
		public static const POSITIVE_Y:uint = 2;
		public static const NEGATIVE_Y:uint = 3;
		public static const POSITIVE_Z:uint = 4;
		public static const NEGATIVE_Z:uint = 5;
	}
}