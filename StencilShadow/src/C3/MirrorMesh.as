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

	public class MirrorMesh
	{
		private var m_matrix : Matrix3D = new Matrix3D();
		private var m_transform : Matrix3D = new Matrix3D();
		
		private var m_context3D : Context3D;
		
		private var m_mirrorVertexBuffer : VertexBuffer3D;
		private var m_mirrorIndexBuffer : IndexBuffer3D;
		
		private var m_mirrorRawVertex : Vector.<Number>;
		private var m_mirrorRawIndex : Vector.<uint>;
		
		private var m_pos : Vector3D = new Vector3D();
		private var m_rotate : Vector3D = new Vector3D();
		private var m_scale : Vector3D = new Vector3D(1,1,1);
		
		private var m_mirrorTexture : Texture;
		
		private var m_needUpdateTransform : Boolean = false;
		
		[Embed(source="../../source/ice.jpg")]
		private var iceData : Class;
		
		public function MirrorMesh(context3D : Context3D)
		{
			m_context3D = context3D;
			setup();
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
			
			/**
			 * 绘制镜子，填充模板
			 */
			m_context3D.setTextureAt(0, m_mirrorTexture);
			m_context3D.setVertexBufferAt(0,m_mirrorVertexBuffer,0,Context3DVertexBufferFormat.FLOAT_3);
			m_context3D.setVertexBufferAt(1,m_mirrorVertexBuffer,6,Context3DVertexBufferFormat.FLOAT_2);
			m_context3D.drawTriangles(m_mirrorIndexBuffer,0,m_mirrorRawIndex.length / 3);
			
			m_context3D.setVertexBufferAt(0,null);
			m_context3D.setVertexBufferAt(1,null);
			m_context3D.setTextureAt(0,null);
			m_context3D.setProgram(null);
		}
		
		public function updateTransform() : void
		{
			if(!m_needUpdateTransform) return;
			
			m_transform.identity();
			m_transform.appendRotation(m_rotate.x, Vector3D.X_AXIS);
			m_transform.appendRotation(m_rotate.y, Vector3D.Y_AXIS);
			m_transform.appendRotation(m_rotate.z, Vector3D.Z_AXIS);
			m_transform.appendScale(m_scale.x,m_scale.y,m_scale.z);
			
			m_transform.appendTranslation(m_pos.x,m_pos.y,m_pos.z);
		}
		
		public function scale(x : Number, y : Number, z : Number) : void
		{
			m_scale.x = x;
			m_scale.y = y;
			m_scale.z = z;
			
			if(m_scale.x == 0) m_scale.x = 0.1;
			if(m_scale.y == 0) m_scale.y = 0.1;
			if(m_scale.z == 0) m_scale.z = 0.1;
			
			m_needUpdateTransform = true;
		}
		
		public function move(x : Number, y : Number, z : Number) : void
		{
			m_pos.x += x;
			m_pos.y += y;
			m_pos.z += z;
			
			m_needUpdateTransform = true;
		}
		
		public function get pos() : Vector3D
		{
			return m_pos;
		}
		
		public function moveTo(x : Number, y : Number, z : Number) : void
		{
			m_pos.x = x;
			m_pos.y = y;
			m_pos.z = z;
			
			m_needUpdateTransform = true;
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
		
		public function get position() : Vector3D
		{
			return m_transform.position;
		}
		
		private function setup() : void
		{
			//镜子
			
			m_mirrorRawVertex = new Vector.<Number>();
			m_mirrorRawIndex = new Vector.<uint>();
			
			m_mirrorRawVertex.push(-2.5,	0,	0,		0,	0,	-1,	0,	1);
			m_mirrorRawVertex.push(-2.5,	5,	0,		0,	0,	-1,	0,	0);
			m_mirrorRawVertex.push(2.5,	5,	0,		0,	0,	-1,	1,	0);
			
			m_mirrorRawVertex.push(-2.5,	0,	0,		0,	0,	-1,	0,	1);
			m_mirrorRawVertex.push(2.5,	5,	0,		0,	0,	-1,	1,	0);
			m_mirrorRawVertex.push(2.5,	0,	0,		0,	0,	-1,	1,	1);
			
			m_mirrorTexture = Utils.getTexture(iceData, m_context3D);
			
			m_mirrorRawIndex.push(0,1,2,3,4,5);
			m_mirrorVertexBuffer = m_context3D.createVertexBuffer(m_mirrorRawVertex.length / 8 , 8);
			m_mirrorVertexBuffer.uploadFromVector(m_mirrorRawVertex,0,m_mirrorRawVertex.length / 8);
			
			m_mirrorIndexBuffer = m_context3D.createIndexBuffer(m_mirrorRawIndex.length);
			m_mirrorIndexBuffer.uploadFromVector(m_mirrorRawIndex,0,m_mirrorRawIndex.length);
		}
	}
}