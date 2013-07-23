package C3.OGRE
{
	import flash.geom.Vector3D;

	public class OGREVertex
	{
		public var uv_x : Number;
		public var uv_y : Number;
		public var pos : Vector3D;
		/**权重开始索引**/
		public var weight_index : Number = 0;
		/**权重数量**/
		public var weight_count : Number = 0;
		public var id : Number = 0;
		public var index : uint;
		
		/**切线向量**/
		public var tangent : Vector3D;
	}
}