package C3.OGRE
{
	import C3.Parser.Model.MeshDataBase;

	public class OgreMeshData extends MeshDataBase
	{
		public var ogre_triangle : Vector.<OGRETriangle>;
		public var ogre_vertex : Vector.<OGREVertex>;
		public var ogre_numTriangle : uint;
		public var ogre_numVertex : uint;
		
		public function OgreMeshData()
		{
			ogre_triangle = new Vector.<OGRETriangle>();
			ogre_vertex = new Vector.<OGREVertex>();
		}
		
		private var uvVec : Vector.<Number>;
		public function getUv() : Vector.<Number>
		{
			if(uvVec) return uvVec;
			
			uvVec = new Vector.<Number>();
			for each(var vert : OGREVertex in ogre_vertex)
			{
				uvVec.push(vert.uv_x,vert.uv_y);
			}
			
			return uvVec;
		}
		
		private var indexVec : Vector.<uint>;
		public function getIndex() : Vector.<uint>
		{
			if(indexVec) return indexVec;
			
			indexVec = new Vector.<uint>();
			for each(var tri : OGRETriangle in ogre_triangle)
			{
				indexVec = indexVec.concat(tri.indexVec);
			}
			
			return indexVec;
		}
		
		private var vertexVec : Vector.<Number>;
		public function getVertex() : Vector.<Number>
		{
			if(vertexVec) return vertexVec;
			
			vertexVec = new Vector.<Number>();
			for each(var vertex : OGREVertex in ogre_vertex)
			{
				vertexVec.push(vertex.pos.x,vertex.pos.y,vertex.pos.z);
			}
			
			return vertexVec;
		}
	}
}