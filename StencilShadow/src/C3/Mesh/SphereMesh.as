package C3.Mesh
{
	import flash.display3D.Context3D;
	
	import C3.Object3D;
	import C3.Camera.Camera;
	import C3.Camera.ICamera;
	import C3.Material.IMaterial;
	import C3.Material.Shaders.Shader;
	import C3.Material.Shaders.ShaderSimple;
	
	public class SphereMesh extends Object3D
	{
		public static const MIN_SLICES:uint = 3;
		public static const MIN_STACKS:uint = 3;
		
		private var m_slices : uint;
		private var m_stacks : uint;
		private var m_stepTheta : Number;
		private var m_stepPhi : Number;
		private var m_stepU : Number;
		private var m_stepV : Number;
		private var m_verticesPerStack : uint;
		private var m_numVertices : uint;
		
		public function SphereMesh(name : String = "", slices : uint = MIN_SLICES, stacks : uint = MIN_STACKS, mat:IMaterial = null)
		{
			super(name,mat);
			
			m_slices = slices;
			m_stacks = stacks;
			m_stepTheta = (2.0 * Math.PI) / slices;
			m_stepPhi = Math.PI / stacks;
			m_stepU = 1.0 / slices;
			m_stepV = 1.0 / stacks;
			m_verticesPerStack = slices + 1;
			m_numVertices = m_verticesPerStack * (stacks + 1);
			
			var positions : Vector.<Number> = new Vector.<Number>(m_numVertices * 3);
			var texCoords : Vector.<Number> = new Vector.<Number>(m_numVertices * 2);
			var tris : Vector.<uint> = new Vector.<uint>(m_slices * m_stacks * 6);
			
			var halfCosThetas : Vector.<Number> = new Vector.<Number>(m_verticesPerStack);
			var halfSinThetas : Vector.<Number> = new Vector.<Number>(m_verticesPerStack);
			var curTheta : Number = 0;
			for(var slice : uint = 0; slice < m_verticesPerStack; ++slice)
			{
				halfCosThetas[slice] = Math.cos(curTheta) * .5;
				halfSinThetas[slice] = Math.sin(curTheta) * .5;
				curTheta +=  m_stepTheta;
			}
			
			//计算顶点和uv
			var curV : Number = 1.0;
			var curPhi : Number = Math.PI;
			var posIndex : uint;
			var texCoordIndex : uint;
			for(var stack : uint = 0; stack < stacks+1; ++stack)
			{
				var curU : Number = 1.0;
				var curY : Number = Math.cos(curPhi) * .5;
				var sinCurPhi : Number = Math.sin(curPhi);
				for(slice = 0; slice < m_verticesPerStack; ++slice)
				{
					positions[posIndex++] = halfCosThetas[slice] * sinCurPhi;
					positions[posIndex++] = curY;
					positions[posIndex++] = halfSinThetas[slice] * sinCurPhi;
					
					texCoords[texCoordIndex++] = curU;
					texCoords[texCoordIndex++] = curV;
					curU -= m_stepU;
				}
				curV -= m_stepV;
				curPhi -= m_stepPhi;
			}
			
			//计算三角形
			var lastStackFirstVertexIndex : uint = 0;
			var curStackFirstVertexIndex : uint = m_verticesPerStack;
			var triIndex : uint;
			for(stack = 0; stack < stacks; ++stack)
			{
				for(slice = 0; slice < slices; ++slice)
				{
					//底部三角形
					tris[triIndex++] = lastStackFirstVertexIndex + slice + 1;
					tris[triIndex++] = curStackFirstVertexIndex + slice;
					tris[triIndex++] = lastStackFirstVertexIndex + slice;
					
					//顶部三角形
					tris[triIndex++] = lastStackFirstVertexIndex + slice + 1;
					tris[triIndex++] = curStackFirstVertexIndex + slice + 1;
					tris[triIndex++] = curStackFirstVertexIndex + slice;
				}
				
				lastStackFirstVertexIndex += m_verticesPerStack;
				curStackFirstVertexIndex += m_verticesPerStack;
			}
			
			//创建buffer
			vertexRawData = positions;
			uvRawData = texCoords;
			indexRawData = tris;
			m_numTriangles = computeNumTris(slices,stacks)/3;
			
			//创建Shader
			var shader : ShaderSimple = new ShaderSimple(this);
			shader.material = mat;
			setShader(shader);
		}
		
		public override function render(context:Context3D, camera:ICamera):void
		{
			super.render(context,camera);
		}
		
		public static function computeNumTris(slices : uint, stacks : uint) : uint
		{
			if(slices < MIN_SLICES)
				slices = MIN_SLICES;
			
			if(stacks <= MIN_STACKS)
				stacks = MIN_STACKS;
			
			return slices * stacks * 6;
		}
	}
}