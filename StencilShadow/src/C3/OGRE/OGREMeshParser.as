package C3.OGRE
{
	import flash.utils.ByteArray;

	public class OGREMeshParser
	{
		public function OGREMeshParser()
		{
		}
		
		public function load(data : ByteArray) : void
		{
			_textData = new XML(data.readUTFBytes(data.bytesAvailable));
			handleData();
		}
		
		private function handleData() : void
		{
			var node : XML;
			for each(node in _textData.children())
			{
				var nodeName : String = node.name();
				switch(nodeName){
					case SUB_MESHS:
						parseSubMesh(node);
						break;
				}
			}
		}
		
		private function parseSubMesh(data : XML) : void
		{
			var subMeshData : XML = data.child(SUB_MESH)[0];
			var node : XML;
			for each(node in subMeshData.children())
			{
				var nodeName : String = node.name();
				var mesh : MeshData = new MeshData();
				switch(nodeName){
					case FACE:
						parseIndex(node, mesh);
						break;
					case GEOMETRY:
						parseVertex(node);
						break;
					case BONE_ASSIGNMENTS:
						break;
				}
			}
		}
		
		/**
		 * 解析索引
		 */
		private function parseIndex(data : XML, mesh : MeshData) : void
		{
			var numTriangle : uint = data.@count; 
			var face : XML;
			var triangle : OGRETriangle;
			for each(face in data.children())
			{
				triangle = new OGRETriangle();
				triangle.indexVec.push(face.@v1);
				triangle.indexVec.push(face.@v2);
				triangle.indexVec.push(face.@v3);
			}
			mesh.ogre_triangle.push(triangle);
		}
		
		/**
		 * 解析顶点
		 */
		private function parseVertex(data : XML) : OGREVertex
		{
			return null;
		}
		
		private var _textData : XML;
		private var ogre_mesh : Vector.<MeshData> = new Vector.<MeshData>();
		
		/**子网格集合**/
		private static const SUB_MESHS : String = "submeshes";
		/**子网格**/
		private static const SUB_MESH : String = "submesh";
		/**面**/
		private static const FACE : String = "faces";
		/**集合体**/
		private static const GEOMETRY : String = "geometry";
		/**顶点缓冲信息**/
		private static const VERTEX_BUFFER : String = "vertexbuffer";
		/**顶点**/
		private static const VERTEX : String = "vertex";
		/**骨骼**/
		private static const BONE_ASSIGNMENTS : String = "boneassignments";
		
	}
}