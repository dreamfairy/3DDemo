package C3.Bounding
{
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	public class BoundingVolumeBase
	{
		public var minPos : Vector3D = new Vector3D();
		public var maxPos : Vector3D = new Vector3D();
		public var center : Vector3D;
		public var radius : Number;
		
		public function update(transform : Matrix3D) : void
		{
			
		}
	}
}