package C3.OGRE
{
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	import C3.MD5.Quaternion;

	public class OGREFrameData
	{
		public var time : Number;
		public var translate : Vector3D;
		public var rotate : Number;
		public var axis : Vector3D;
		public var scale : Vector3D = new Vector3D(1,1,1);
		public var quaternion : Quaternion;
		public var matrix : Matrix3D;
	}
}