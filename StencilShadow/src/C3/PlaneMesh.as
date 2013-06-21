package C3
{
	import flash.geom.Vector3D;
	
	import C3.Material.IMaterial;

	public class PlaneMesh extends Object3D
	{
		/**
		 * param name 对象名称
		 * param width 平面宽
		 * param height 平面长
		 * param segment 分割顶点数
		 * param axis 平铺屏幕
		 * param mat 材质，默认为RGB材质
		 */
		public function PlaneMesh(name : String = "", width : int = 100, height : int = 100, segment : uint = 2, axis : String = "+xz", mat : IMaterial = null)
		{
			super(name,mat);
			
			m_width = width;
			m_height = height;
			m_axis = axis;
			
			calcVertex(segment);
		}
		
		private function calcVertex(segment : uint) : void
		{
			segment = segment<= 1 ? 2 : segment;
			
			var halfWidth : int = m_width >> 1;
			var startX : int = -halfWidth;
			var endX : int = halfWidth;
			
			var halfHeight : int = m_height >> 1;
			var startY : int = -halfHeight;
			var endY : int = halfHeight;
			
			var stepX : int = m_width/(segment-1);
			var stepY : int = m_height/(segment-1);
			
			var x : int = startX;
			var y : int = startY;
			var vertexList : Vector.<Number> = new Vector.<Number>();
			
			for(var i : int = 0; i < segment; i ++)
			{
				for(var j : int = 0; j < segment; j ++)
				{
					fillVertexList(vertexList,x + j * stepX, y + i * stepY);
				}
			}
			
			vertexRawData = vertexList;
			
			calcIndices(segment);
			calcUV();
			calcNormal();
		}
		
		/**
		 * 计算法线
		 */
		private function calcNormal() : void
		{
			var normalList : Vector.<Number>;
			var v1 : Vector3D = new Vector3D(m_vertexRawData[0],m_vertexRawData[1],m_vertexRawData[2]);
			var v2 : Vector3D = new Vector3D(m_vertexRawData[3],m_vertexRawData[4],m_vertexRawData[5]);
			
			v1.normalize();
			v2.normalize();
			
			var norm : Vector3D = v1.crossProduct(v2);
			normalList = Vector.<Number>([norm.x,norm.y,norm.z]);
			
			normalRawData = normalList;
		}
		
		private function fillVertexList(list : Vector.<Number>, x : Number, y : Number) : void
		{
			switch(m_axis)
			{
				case AOI3DAXIS.XY:
					list.push(x,y,0);
					break;
				case AOI3DAXIS.XZ:
					list.push(x,1,y);
					break;
				case AOI3DAXIS.YZ:
					list.push(0,x,y);
					break;
			}
		}
		
		private function calcIndices(segment : uint) : void
		{
			var baseIndex : int = 0;
			var indexList : Vector.<uint> = new Vector.<uint>();
			var len : int = segment - 1;
			for(var i : int = 0; i < len; i++)
			{
				for(var j : int = 0; j < len; j++)
				{
					indexList[baseIndex]		= i * segment + j;
					indexList[baseIndex + 1]	= i * segment + j + 1;
					indexList[baseIndex + 2]	= (i + 1) * segment + j;
					indexList[baseIndex + 3]	= (i + 1) * segment + j;
					indexList[baseIndex + 4]	= i * segment + j + 1;
					indexList[baseIndex + 5]	= (i + 1) * segment + j + 1;
					
					baseIndex += 6;
				}
			}
			
			indexRawData = indexList;
			m_numTriangles = len * len * 2;
		}
		
		private function calcUV() : void
		{
			uvRawData = Vector.<Number>([0,0,1,0,0,1,1,1]);
		}
		
		private var m_axis : String;
	}
}