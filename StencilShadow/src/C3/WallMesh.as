package C3
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DClearMask;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DStencilAction;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.Texture;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	public class WallMesh
	{
		private var m_matrix :Matrix3D = new Matrix3D();
		private var m_transform : Matrix3D = new Matrix3D();
		private var m_reflect : Matrix3D = new Matrix3D();
		
		private var m_context3D : Context3D;
		
		private var m_floorVertexBuffer : VertexBuffer3D;
		private var m_floorIndexBuffer : IndexBuffer3D;
		
		private var m_wallVertexBuffer : VertexBuffer3D;
		private var m_wallIndexBuffer : IndexBuffer3D;
		
		private var m_blockVertexBuffer : VertexBuffer3D;
		private var m_blockIndexBuffer : IndexBuffer3D;
		
		private var m_floorRawVertex : Vector.<Number>;
		private var m_floorRawIndex : Vector.<uint>;
		
		private var m_wallRawVertex : Vector.<Number>;
		private var m_wallRawIndex : Vector.<uint>;
		
		private var m_blockRawVertex : Vector.<Number>;
		private var m_blockRawIndex : Vector.<uint>;
		
		private var m_floorTexture : Texture;
		private var m_wallTexture : Texture;
		private var m_mirrorTexture : Texture;
		
		private var m_pos : Vector3D = new Vector3D();
		private var m_rotate : Vector3D = new Vector3D();
		
		private var m_needUpdateTransform : Boolean = false;
		
		private var m_mirrorTeapot : TeapotMesh;
		
		[Embed(source="../../source/brick0.jpg")]
		private var wallData : Class;
		
		[Embed(source="../../source/checker.jpg")]
		private var floorData : Class;
		
		[Embed(source="../../source/ice.jpg")]
		private var iceData : Class;
		
		public function WallMesh(context3D : Context3D)
		{
			m_context3D = context3D;
			setup();
			
			m_mirrorTeapot = new TeapotMesh(m_context3D);
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
			
			//绘制地板
			m_context3D.setTextureAt(0, m_floorTexture);
			m_context3D.setVertexBufferAt(0,m_floorVertexBuffer,0,Context3DVertexBufferFormat.FLOAT_3);
			m_context3D.setVertexBufferAt(1,m_floorVertexBuffer,6,Context3DVertexBufferFormat.FLOAT_2);
			m_context3D.drawTriangles(m_floorIndexBuffer,0,m_floorRawIndex.length / 3);
			
			//绘制墙壁
			m_context3D.setTextureAt(0, m_wallTexture);
			m_context3D.setVertexBufferAt(0,m_wallVertexBuffer,0,Context3DVertexBufferFormat.FLOAT_3);
			m_context3D.setVertexBufferAt(1,m_wallVertexBuffer,6,Context3DVertexBufferFormat.FLOAT_2);
			m_context3D.drawTriangles(m_wallIndexBuffer,0,m_wallRawIndex.length / 3);
			
			//绘制另一面墙
			m_context3D.setTextureAt(0, m_wallTexture);
			m_context3D.setVertexBufferAt(0,m_blockVertexBuffer,0,Context3DVertexBufferFormat.FLOAT_3);
			m_context3D.setVertexBufferAt(1,m_blockVertexBuffer,6,Context3DVertexBufferFormat.FLOAT_2);
			m_context3D.drawTriangles(m_blockIndexBuffer,0,m_blockRawIndex.length / 3);
			
			/**
			 * 设置模板引用数值为0
			 * 之后绘制的任何三角形都会通过检测
			 */
//			m_context3D.setStencilActions(Context3DTriangleFace.FRONT,Context3DCompareMode.EQUAL,Context3DStencilAction.DECREMENT_SATURATE);
//			m_context3D.setStencilReferenceValue(0);
			
			/**
			 * 绘制镜子，填充模板
			 */
//			m_context3D.setTextureAt(0, m_mirrorTexture);
//			m_context3D.setVertexBufferAt(0,m_mirrorVertexBuffer,0,Context3DVertexBufferFormat.FLOAT_3);
//			m_context3D.setVertexBufferAt(1,m_mirrorVertexBuffer,6,Context3DVertexBufferFormat.FLOAT_2);
//			m_context3D.drawTriangles(m_mirrorIndexBuffer,0,m_mirrorRawIndex.length / 3);
//			
//			m_context3D.setVertexBufferAt(0,null);
//			m_context3D.setVertexBufferAt(1,null);
//			m_context3D.setTextureAt(0,null);
//			
//			m_context3D.setDepthTest(false,Context3DCompareMode.LESS);
//			m_context3D.setStencilReferenceValue(1);
//			
//			/**
//			 * 在有镜子的地方绘制Cube
//			 */
//			m_matrix.identity();
//			m_matrix.append(m_transform);
//			m_matrix.append(m_reflect);
//			m_matrix.append(view);
//			m_matrix.append(proj);
//			
//			m_context3D.setProgram(shader);
//			m_context3D.clear(0,0,0,1,1,0,Context3DClearMask.DEPTH);
//			
//			m_context3D.setTextureAt(0, m_mirrorTeapot.texture);
//			m_context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, m_matrix, true);
//			m_context3D.setVertexBufferAt(0, m_mirrorTeapot.mesh.positionsBuffer,0,Context3DVertexBufferFormat.FLOAT_3);
//			m_context3D.setVertexBufferAt(1, m_mirrorTeapot.mesh.uvBuffer,0,Context3DVertexBufferFormat.FLOAT_2);
//			m_context3D.drawTriangles(m_mirrorTeapot.mesh.indexBuffer, 0, m_mirrorTeapot.mesh.IndexBufferCount);
//			
//			m_context3D.setTextureAt(0, null);
//			m_context3D.setVertexBufferAt(0, null);
//			m_context3D.setVertexBufferAt(1, null);
//			m_context3D.setProgram(null);
//			
//			m_context3D.setDepthTest(true,Context3DCompareMode.LESS);
//			m_context3D.setStencilActions(Context3DTriangleFace.FRONT,Context3DCompareMode.ALWAYS,Context3DStencilAction.KEEP);
		}
		
		public function updateTransform() : void
		{
			if(!m_needUpdateTransform) return;
			
			m_transform.identity();
			m_transform.appendRotation(m_rotate.x, Vector3D.X_AXIS);
			m_transform.appendRotation(m_rotate.y, Vector3D.Y_AXIS);
			m_transform.appendRotation(m_rotate.z, Vector3D.Z_AXIS);
			
			m_transform.appendTranslation(m_pos.x,m_pos.y,m_pos.z);
			
			m_needUpdateTransform = false;
		}
		
		public function move(x : Number, y : Number, z : Number) : void
		{
			m_pos.x += x;
			m_pos.y += y;
			m_pos.z += z;
			
			m_needUpdateTransform = true;
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
			
			m_floorTexture = Utils.getTexture(floorData, m_context3D);
			m_wallTexture = Utils.getTexture(wallData, m_context3D);
			
			//地板
			
			m_floorRawVertex = new Vector.<Number>();
			m_floorRawIndex = new Vector.<uint>();
			
			
			m_floorRawVertex.push(-7.5,	0,	-10,	0,	1,	0,	0,	1);
			m_floorRawVertex.push(-7.5,	0,	0,		0,	1,	0,	0,	0);
			m_floorRawVertex.push(7.5,	0,	0,		0,	1,	0,	1,	0);

			m_floorRawVertex.push(-7.5,	0,	-10,	0,	1,	0,	0,	1);
			m_floorRawVertex.push(7.5,	0,	0,		0,	1,	0,	1,	0);
			m_floorRawVertex.push(7.5,	0,	-10,	0,	1,	0,	1,	1);
			
			m_floorRawIndex.push(0,1,2,3,4,5);
			
			m_floorVertexBuffer = m_context3D.createVertexBuffer(m_floorRawVertex.length / 8 , 8);
			m_floorVertexBuffer.uploadFromVector(m_floorRawVertex,0,m_floorRawVertex.length / 8);
			
			m_floorIndexBuffer = m_context3D.createIndexBuffer(m_floorRawIndex.length);
			m_floorIndexBuffer.uploadFromVector(m_floorRawIndex,0,m_floorRawIndex.length);
			
			//墙壁
			
			m_wallRawVertex = new Vector.<Number>();
			m_wallRawIndex = new Vector.<uint>();
			
			m_wallRawVertex.push(-7.5,	0,	0,		0,	0,	-1,	0,	1);
			m_wallRawVertex.push(-7.5,	5,	0,		0,	0,	-1,	0,	0);
			m_wallRawVertex.push(-2.5,	5,	0,		0,	0,	-1,	1,	0);
			
			m_wallRawVertex.push(-7.5,	0,	0,		0,	0,	-1,	0,	1);
			m_wallRawVertex.push(-2.5,	5,	0,		0,	0,	-1,	1,	0);
			m_wallRawVertex.push(-2.5,	0,	0,		0,	0,	-1,	1,	1);
			
			m_wallRawIndex.push(0,1,2,3,4,5);
			m_wallVertexBuffer = m_context3D.createVertexBuffer(m_wallRawVertex.length / 8 , 8);
			m_wallVertexBuffer.uploadFromVector(m_wallRawVertex,0,m_wallRawVertex.length / 8);
			
			m_wallIndexBuffer = m_context3D.createIndexBuffer(m_wallRawIndex.length);
			m_wallIndexBuffer.uploadFromVector(m_wallRawIndex,0,m_wallRawIndex.length);
			
			//给镜子留个位置
			
			m_blockRawVertex = new Vector.<Number>();
			m_blockRawIndex = new Vector.<uint>();
			
			m_blockRawVertex.push(2.5,	0,	0,		0,	0,	-1,	0,	1);
			m_blockRawVertex.push(2.5,	5,	0,		0,	0,	-1,	0,	0);
			m_blockRawVertex.push(7.5,	5,	0,		0,	0,	-1,	1,	0);
			
			m_blockRawVertex.push(2.5,	0,	0,		0,	0,	-1,	0,	1);
			m_blockRawVertex.push(7.5,	5,	0,		0,	0,	-1,	1,	0);
			m_blockRawVertex.push(7.5,	0,	0,		0,	0,	-1,	1,	1);
			
			m_blockRawIndex.push(0,1,2,3,4,5);
			m_blockVertexBuffer = m_context3D.createVertexBuffer(m_blockRawVertex.length / 8 , 8);
			m_blockVertexBuffer.uploadFromVector(m_blockRawVertex,0,m_blockRawVertex.length / 8);
			
			m_blockIndexBuffer = m_context3D.createIndexBuffer(m_blockRawIndex.length);
			m_blockIndexBuffer.uploadFromVector(m_blockRawIndex,0,m_blockRawIndex.length);
		}
	}
}