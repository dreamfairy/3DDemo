package C3.OGRE
{
	import flash.geom.Vector3D;

	public class OGREVertex
	{
		public var uv_x : Number;
		public var uv_y : Number;
		public var pos : Vector3D;
		
		public var id : Number = 0;
		public var index : uint;
		
		/**切线向量**/
		public var tangent : Vector3D;
		
		/**对应的骨骼**/
		public var m_boneList : Vector.<OGREVertexBoneData>;
		
		public function get boneList() : Vector.<OGREVertexBoneData>
		{
			m_boneList||=new Vector.<OGREVertexBoneData>;
			return m_boneList;
		}
		
		public function set boneList(data : Vector.<OGREVertexBoneData>)
		{
			m_boneList = data;
		}
		
		public function get maxJoints() : uint
		{
			return m_boneList ? m_boneList.length : 0;
		}
	}
}