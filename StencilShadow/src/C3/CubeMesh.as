package C3
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.Texture;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	public class CubeMesh
	{
		private var m_matrix : Matrix3D = new Matrix3D();
		private var m_transform : Matrix3D = new Matrix3D();
		
		private var m_context3D : Context3D;
		private var m_vertexBuffer : VertexBuffer3D;
		private var m_indexBuffer : IndexBuffer3D;
		private var m_uvBuffer : VertexBuffer3D;
		private var m_cubeVertex : Vector.<Number>;
		private var m_cubeUV : Vector.<Number>;
		private var m_cubeIndex : Vector.<uint>;
		
		private var m_pos : Vector3D = new Vector3D();
		private var m_rotate : Vector3D = new Vector3D();
		
		private var m_needUpdateTransform : Boolean = false;
		
		private var m_texture : Texture;
		
		public function CubeMesh(context3D : Context3D, texture : Texture = null)
		{
			m_context3D = context3D;
			m_texture = texture;
			
			setup();
		}
		
		public function get texture() : Texture
		{
			return m_texture;
		}
		
		public function get transform() : Matrix3D
		{
			return m_transform;
		}
		
		public function render(view : Matrix3D, proj : Matrix3D, shader : Program3D) : void
		{
			updateTransform();
			
			m_matrix.identity();
			m_matrix.append(m_transform);
			m_matrix.append(view);
			m_matrix.append(proj);
			
			m_context3D.setProgram(shader);
			m_context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, m_matrix, true);
			
			if(m_texture) {
				m_context3D.setTextureAt(0, m_texture);
				m_context3D.setVertexBufferAt(1, m_uvBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
			}
			
			m_context3D.setVertexBufferAt(0,m_vertexBuffer,0,Context3DVertexBufferFormat.FLOAT_3);
			m_context3D.drawTriangles(m_indexBuffer,0,m_cubeIndex.length / 3);
			
			m_context3D.setVertexBufferAt(0,null);
			m_context3D.setVertexBufferAt(1,null);
			m_context3D.setTextureAt(0, m_texture);
		}
		
		public function updateTransform() : void
		{
			if(!m_needUpdateTransform) return;
			
			m_transform.identity();
			m_transform.appendRotation(m_rotate.x, Vector3D.X_AXIS);
			m_transform.appendRotation(m_rotate.y, Vector3D.Y_AXIS);
			m_transform.appendRotation(m_rotate.z, Vector3D.Z_AXIS);
			
			m_transform.appendTranslation(m_pos.x,m_pos.y,m_pos.z);
		}
		
		public function moveTo(x : Number, y : Number, z : Number) : void
		{
			m_pos.x = x;
			m_pos.y = y;
			m_pos.z = z;
			
			m_needUpdateTransform = true;
		}
		
		public function set rotateY(value : Number) : void
		{
			m_rotate.y = value;
			
			m_needUpdateTransform = true;
		}
		
		public function get rotateY() : Number
		{
			return m_rotate.y;
		}
		
		public function rotation(value : Number, axis : Vector3D) : void
		{
			switch(axis){
				case Vector3D.X_AXIS:
					m_rotate.x = value;
					break;
				case Vector3D.Y_AXIS:
					m_rotate.y = value;
					break;
				case Vector3D.Z_AXIS:
					m_rotate.z = value;
					break;
			}
			
			m_needUpdateTransform = true;
		}
		
		public function move(x : Number, y : Number, z : Number) : void
		{
			m_pos.x += x;
			m_pos.y += y;
			m_pos.z += z;
			
			m_needUpdateTransform = true;
		}
		
		public function get position() : Vector3D
		{
			return m_transform.position;
		}
		
		public function get radius() : Number
		{
			return 2;
		}
		
		private function setup() : void
		{
			m_cubeVertex = new Vector.<Number>();
			m_cubeVertex.push(-1,-1,-1);//左下
			m_cubeVertex.push(-1,1,-1);//左上
			m_cubeVertex.push(1,1,-1);//右上
			m_cubeVertex.push(1,-1,-1);//右下
			m_cubeVertex.push(-1,-1,1);
			m_cubeVertex.push(-1,1,1);
			m_cubeVertex.push(1,1,1);
			m_cubeVertex.push(1,-1,1);
			
			m_cubeIndex = new Vector.<uint>();
			m_cubeIndex.push(0,1,2);
			m_cubeIndex.push(0,2,3);
			m_cubeIndex.push(4,6,5);
			m_cubeIndex.push(4,7,6);
			m_cubeIndex.push(4,5,1);
			m_cubeIndex.push(4,1,0);
			m_cubeIndex.push(3,2,6);
			m_cubeIndex.push(3,6,7);
			m_cubeIndex.push(1,5,6);
			m_cubeIndex.push(1,6,2);
			m_cubeIndex.push(4,0,3);
			m_cubeIndex.push(4,3,7);
			
			m_cubeUV = new Vector.<Number>();
			//正面
			m_cubeUV.push(1,1); 
			m_cubeUV.push(1,0);
			m_cubeUV.push(0,0);
			m_cubeUV.push(0,1);
			
			m_cubeUV.push(0,1); 
			m_cubeUV.push(0,0);
			m_cubeUV.push(1,0);
			m_cubeUV.push(1,1);
			
			m_vertexBuffer = m_context3D.createVertexBuffer(m_cubeVertex.length / 3, 3);
			m_vertexBuffer.uploadFromVector(m_cubeVertex,0,m_cubeVertex.length / 3);
			
			m_indexBuffer = m_context3D.createIndexBuffer(m_cubeIndex.length);
			m_indexBuffer.uploadFromVector(m_cubeIndex,0,m_cubeIndex.length);
			
			m_uvBuffer = m_context3D.createVertexBuffer(m_cubeUV.length / 2, 2);
			m_uvBuffer.uploadFromVector(m_cubeUV, 0, m_cubeUV.length / 2);
		}
	}
}