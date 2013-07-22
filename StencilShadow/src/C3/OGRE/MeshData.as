package C3.OGRE
{
	public class MeshData
	{
		public var ogre_triangle : Vector.<OGRETriangle>;
		public var ogre_vertex : Vector.<OGREVertex>;
		
		public function MeshData()
		{
			ogre_triangle = new Vector.<OGRETriangle>();
			ogre_vertex = new Vector.<OGREVertex>();
		}
	}
}