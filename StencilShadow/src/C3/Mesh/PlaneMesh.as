package C3.Mesh
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTriangleFace;
	import flash.geom.Vector3D;
	
	import C3.AOI3DAXIS;
	import C3.Object3D;
	import C3.Object3DContainer;
	import C3.Camera.Camera;
	import C3.Camera.ICamera;
	import C3.Core.Managers.MaterialManager;
	import C3.Material.IMaterial;
	import C3.Material.Shaders.Shader;
	import C3.Material.Shaders.ShaderParamters;
	import C3.Material.Shaders.ShaderSimple;

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
			m_segment = segment < 2 ? 2 : segment;
			
			calcVertex();
		}
		
		private function calcVertex() : void
		{
			var top : int = getTop();
			var left : int = getLeft();
			var stepU : int = getStepU();
			var stepV : int = getStepV();
			
			var vertexList : Vector.<Number> = new Vector.<Number>();
			
			var curVertex : Vector3D = getFirstVertex(top,left);
			var nextVertex : Vector3D;
			var disU : int;
			var disV : int;
			
			//横向
			for(var i : int = 0; i < m_segment; i ++ )
			{
				disU = i * stepU;
				//纵向
				for(var j : int = 0; j < m_segment; j++)
				{
					disV = j * stepV;
					nextVertex = getNextVertex(curVertex,disU,disV);
					vertexList.push(nextVertex.x,nextVertex.y,nextVertex.z);
				}
			}
			
			//循环计算顶点数
			vertexRawData = vertexList;
			calcIndices();
			calcUV();
			calcNormal();
			
			
			var shader : ShaderSimple = new ShaderSimple(this)
			shader.material = m_material;
			shader.params.culling = Context3DTriangleFace.NONE;
			setShader(shader);
			
			shaderParams = new ShaderParamters();
			shaderParams.culling = Context3DTriangleFace.NONE;
			shaderParams.updateList = [ShaderParamters.CULLING];
		}
		
		private function getNextVertex(firstVector : Vector3D, disU : int, disV : int, outPos : Vector3D = null) : Vector3D
		{
			outPos ||= new Vector3D();
			switch(m_axis){
				case AOI3DAXIS.XY:
					outPos.setTo(firstVector.x + disU,firstVector.y + disV,0);
					break;
				case AOI3DAXIS.XZ:
					outPos.setTo(firstVector.x + disU,0,firstVector.z + disV);
					break;
				case AOI3DAXIS.YZ:
					outPos.setTo(0,firstVector.y + disV, firstVector.z + disU);
					break;
			}
			return outPos;
		}
		
		private function getFirstVertex(v : int, u : int, outPos : Vector3D = null) : Vector3D
		{
			outPos ||= new Vector3D();
			switch(m_axis){
				case AOI3DAXIS.XY:
					outPos.setTo(u,v,0);
					break;
				case AOI3DAXIS.XZ:
					outPos.setTo(u,0,v);
					break;
				case AOI3DAXIS.YZ:
					outPos.setTo(0,v,u);
					break;
			}
			return outPos;
		}
		
		private function getStepU() : int
		{
			switch(m_axis){
				case AOI3DAXIS.XY:
				case AOI3DAXIS.XZ:
					return m_width / (m_segment - 1);
					break;
				case AOI3DAXIS.YZ:
					return -(m_width / (m_segment - 1));
					break;
			}
			return 0;
		}
		
		private function getStepV() : int
		{
			switch(m_axis){
				case AOI3DAXIS.YZ:
				case AOI3DAXIS.XY:
					return -(m_height / (m_segment - 1));
					break;
				case AOI3DAXIS.XZ:
					return m_height / (m_segment - 1);
					break;
			}
			return 0;
		}
		
		private function getTop() : int
		{
			switch(m_axis){
				case AOI3DAXIS.XY:
					return m_height >> 1;
					break;
				case AOI3DAXIS.XZ:
					return -m_height >> 1;
					break;
				case AOI3DAXIS.YZ:
					return m_height >> 1;
					break;
			}
			return 0;
		}
		
		private function getLeft() : int
		{
			switch(m_axis){
				case AOI3DAXIS.XY:
					return -m_width >> 1;
					break;
				case AOI3DAXIS.XZ:
					return -m_width >> 1;
					break;
				case AOI3DAXIS.YZ:
					return m_width >> 1;
			}
			return 0;
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
					list.push(x,0,y);
					break;
				case AOI3DAXIS.YZ:
					list.push(0,x,y);
					break;
			}
		}
		
		private function calcIndices() : void
		{
			var baseIndex : int = 0;
			var indexList : Vector.<uint> = new Vector.<uint>();
			var len : int = m_segment - 1;
			for(var i : int = 0; i < len; i++)
			{
				for(var j : int = 0; j < len; j++)
				{
					//顺时针 在右手坐标系中为 Frong
					indexList[baseIndex]		= i * m_segment + j; //左上
					indexList[baseIndex + 1]	= (i + 1) * m_segment + j + 1; //右下
					indexList[baseIndex + 2]	= i * m_segment + j + 1; //左下
					indexList[baseIndex + 3]	= i * m_segment + j; //左上
					indexList[baseIndex + 4]	= (i + 1) * m_segment + j; //右上
					indexList[baseIndex + 5]	= (i + 1) * m_segment + j + 1; //右下
//逆时针
//					indexList[baseIndex]		= i * m_segment + j;
//					indexList[baseIndex + 1]	= i * m_segment + j + 1;
//					indexList[baseIndex + 2]	= (i + 1) * m_segment + j;
//					indexList[baseIndex + 3]	= (i + 1) * m_segment + j;
//					indexList[baseIndex + 4]	= i * m_segment + j + 1;
//					indexList[baseIndex + 5]	= (i + 1) * m_segment + j + 1;
					
					baseIndex += 6;
				}
			}
			
//			trace(indexList);
//			indexList = Vector.<uint>([0,3,1,0,2,3]);
			indexRawData = indexList;
			m_numTriangles = len * len * 2;
		}
		
		private function calcUV() : void
		{
			uvRawData = Vector.<Number>([0,0,1,0,0,1,1,1]);
		}
		
		public override function render(context:Context3D, camera:ICamera):void
		{
			super.render(context, camera);
		}
		
		private var m_axis : String;
		private var m_segment : int;
	}
}