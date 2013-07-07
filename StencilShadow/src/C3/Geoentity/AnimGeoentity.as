package C3.Geoentity
{
	import C3.Object3DContainer;
	import C3.MD5.MD5BaseFrameData;
	import C3.MD5.MD5FrameData;
	import C3.MD5.MD5HierarchyData;
	import C3.Material.IMaterial;

	public class AnimGeoentity extends Object3DContainer
	{
		public function AnimGeoentity(name : String, mat : IMaterial)
		{
			super(name,mat);
		}
		
		public function get frameDatas() : Vector.<MD5FrameData>
		{
			throw new Error("这货需要重写");
		}
		
		public function get numFrams() : uint
		{
			throw new Error("这货需要重写");
		}
		
		public function get baseFrameDatas() : Vector.<MD5BaseFrameData>
		{
			throw new Error("这货需要重写");
		}
		
		public function get hierarchies() : Vector.<MD5HierarchyData>
		{
			throw new Error("这货需要重写");
		}
	}
}