package C3.OGRE
{
	public class MeshData
	{
		public var ogre_triangle : Vector.<OGRETriangle>;
		public var ogre_vertex : Vector.<OGREVertex>;
		public var ogre_numTriangle : uint;
		public var ogre_numVertex : uint;
		
		public function MeshData()
		{
			ogre_triangle = new Vector.<OGRETriangle>();
			ogre_vertex = new Vector.<OGREVertex>();
		}
		
		public function getUv() : Vector.<Number>
		{
			var uvVec : Vector.<Number> = new Vector.<Number>();
			for each(var vert : OGREVertex in ogre_vertex)
			{
				uvVec.push(vert.uv_x,vert.uv_y);
			}
			
			return uvVec;
		}
		
		public function getIndex() : Vector.<uint>
		{
			var indexVec : Vector.<uint> = new Vector.<uint>();
			for each(var tri : OGRETriangle in ogre_triangle)
			{
				indexVec = indexVec.concat(tri.indexVec);
			}
			
			return indexVec;
		}
		
		public function getVertex() : Vector.<Number>
		{
			var vertexVec : Vector.<Number> = new Vector.<Number>();
			for each(var vertex : OGREVertex in ogre_vertex)
			{
				vertexVec.push(vertex.pos.x,vertex.pos.y,vertex.pos.z);
			}
			
			return vertexVec;
		}
	}
}