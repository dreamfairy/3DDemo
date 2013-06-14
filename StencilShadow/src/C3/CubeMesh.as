package C3
{
	import com.adobe.utils.AGALMiniAssembler;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.Texture;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	import C3.Light.SimpleLight;

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
		private var m_cubeNormal : Vector.<Number>;
		private var m_normalBuffer : VertexBuffer3D;
		
		private var m_pos : Vector3D = new Vector3D();
		private var m_rotate : Vector3D = new Vector3D();
		private var m_scale : Vector3D = new Vector3D(1,1,1);
		
		private var m_needUpdateTransform : Boolean = false;
		
		private var m_texture : Texture;
		private var m_light : SimpleLight;
		private var m_shader : Program3D;
		
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
		
		public function set light(light : SimpleLight) : void
		{
			m_light = light;
		}
		
		public function render(view : Matrix3D, proj : Matrix3D, shader : Program3D) : void
		{
			updateTransform();
			
			m_matrix.identity();
			m_matrix.append(m_transform);
			m_matrix.append(view);
			m_matrix.append(proj);
			
			m_context3D.setProgram(shader?shader:getShader());
			m_context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, m_matrix, true);
			
			if(m_texture) {
				m_context3D.setTextureAt(0, m_texture);
			}
			
			if(m_light) {
				//上传初始值
				m_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT,0,
					Vector.<Number>([0,0,0,0]));
				//上传环境光
				m_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT,1,
					m_light.getAmbient());
				//上传灯光方向
				var normal : Vector3D = m_light.normalize;
				m_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT,2,
					Vector.<Number>([normal.x,normal.y,normal.z,1]));
				//上传灯光颜色
				m_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT,3,
					m_light.getColor());
			}
			
			m_context3D.setVertexBufferAt(1, m_uvBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
			m_context3D.setVertexBufferAt(2,m_normalBuffer,0,Context3DVertexBufferFormat.FLOAT_3);
			m_context3D.setVertexBufferAt(0,m_vertexBuffer,0,Context3DVertexBufferFormat.FLOAT_3);
			m_context3D.drawTriangles(m_indexBuffer,0,m_cubeIndex.length / 3);
			
			m_context3D.setVertexBufferAt(0,null);
			m_context3D.setVertexBufferAt(1,null);
			m_context3D.setVertexBufferAt(2,null);
			m_context3D.setTextureAt(0, null);
		}
		
		public function updateTransform() : void
		{
			if(!m_needUpdateTransform) return;
			
			m_transform.identity();
			m_transform.appendScale(m_scale.x,m_scale.y,m_scale.z);
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
		
		public function scale(x : Number, y : Number, z : Number) : void
		{
			m_scale.setTo(x<0?.1:x,y<0?.1:y,z<0?.1:z);
			
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
			
			calcNormal();
		}
		
		private function getShader() : Program3D
		{
			if(m_shader) return m_shader;
			
			m_shader = m_context3D.createProgram();
			
			var vertexProgram : AGALMiniAssembler = new AGALMiniAssembler();
			vertexProgram.assemble(Context3DProgramType.VERTEX,
				"m44 op, va0, vc0\n"+
				"mov v1, va1\n"+
				"mov v1, va2");
			
			var fragmentProgram : AGALMiniAssembler = new AGALMiniAssembler();
			fragmentProgram.assemble(Context3DProgramType.FRAGMENT,
				m_texture?("tex ft0, v1, fs0<2d, miplinear>\n" +
					"mov oc, ft0") : ("mov oc v1"));
			
			m_shader.upload(vertexProgram.agalcode, fragmentProgram.agalcode);
			
			return m_shader;
		}
		
		private function calcNormal() : void
		{
			m_cubeNormal = new Vector.<Number>();
			var vertexData : Vector.<Number> = m_cubeVertex;
			var vertexNum : int = vertexData.length/3;
			var vertex : Vector3D = new Vector3D();
			var noraml : Vector3D = new Vector3D();
			var center : Vector3D = new Vector3D();
			
			for(var i : int = 0; i < vertexNum; i++)
			{
				var startIndex : int = i * 3;
				vertex.setTo(vertexData[startIndex],
					vertexData[startIndex + 1],
					vertexData[startIndex + 2]);
				
				noraml = center.add(vertex);
				noraml.normalize();
				m_cubeNormal.push(noraml.x,noraml.y,noraml.z);
			}
			
			m_normalBuffer = m_context3D.createVertexBuffer(m_cubeNormal.length/3,3);
			m_normalBuffer.uploadFromVector(m_cubeNormal,0,m_cubeNormal.length/3);
		}
	}
}