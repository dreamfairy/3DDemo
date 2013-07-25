package C3.Geoentity
{
	import C3.Object3DContainer;
	import C3.Material.IMaterial;
	import C3.Parser.Model.IJoint;

	public class MeshGeoentity extends Object3DContainer
	{
		public function MeshGeoentity(name : String, mat : IMaterial)
		{
			super(name,mat);
		}
		
		public function get meshDatas() : *
		{
			throw new Error("这货需要重写");
		}
		
		public function get joints() : Vector.<IJoint>
		{
			throw new Error("这货需要重写");
		}
		
		public function get useCPU() : Boolean
		{
			throw new Error("这货需要重写");
		}
		
		public function get maxJoints() : uint
		{
			throw new Error("这货需要重写");
		}
		
		public function updateMatrix() : void
		{
			throw new Error("这货需要重写");
		}
		
		public function updateMaterial() : void
		{
			throw new Error("这货需要重写");
		}
	}
}