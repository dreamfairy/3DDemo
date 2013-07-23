package C3
{
	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.Program3D;
	import flash.display3D.textures.Texture;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	public class TeapotMesh
	{
		private var m_matrix : Matrix3D = new Matrix3D();
		private var m_transform : Matrix3D = new Matrix3D();
		
		private var m_context3D : Context3D;
		
		private var m_pos : Vector3D = new Vector3D();
		private var m_rotate : Vector3D = new Vector3D();
		private var m_scale : Vector3D = new Vector3D(1,1,1);
		
		private var m_needUpdateTransform : Boolean = false;
		
		private var m_reflectionMatrix : Matrix3D;
		private var m_shadowMatrix : Matrix3D;
		
		public function TeapotMesh(context3D : Context3D)
		{
			m_context3D = context3D;
			
			setup();
		}
		
		public function getRotation() : Vector3D
		{
			return m_rotate;
		}
		
		public function setRotation(x : Number, y : Number, z : Number) : void
		{
			m_rotate.x = x;
			m_rotate.y = y;
			m_rotate.z = z;
			
			m_needUpdateTransform = true;
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
		
		public function get pos() : Vector3D
		{
			return m_pos;
		}
		
		public function setReflectionMatrix(data : Matrix3D) : void
		{
			m_reflectionMatrix = data;
		}
		
		public function setShadowMatrix(data : Matrix3D) : void
		{
			m_shadowMatrix = data;
		}
		
		public function setTexture(data : BitmapData) : void
		{
			m_teapotTexture = Utils.getTextureByBmd(data,m_context3D);
		}
		
		public function render(view : Matrix3D, proj : Matrix3D, shader : Program3D, light : Vector3D = null) : void
		{
			updateTransform();
			
			m_matrix.identity();
			m_matrix.append(m_transform);
			
			if(m_reflectionMatrix)
				m_matrix.append(m_reflectionMatrix);
			
			if(m_shadowMatrix)
				m_matrix.append(m_shadowMatrix);

			m_matrix.append(view);
			
			m_context3D.setProgram(shader);
			
			m_context3D.setTextureAt(0, m_teapotTexture);
			
			if(light){
				//上传投影矩阵
				m_context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, m_matrix, true);
				
				var viewModelMat : Matrix3D = m_matrix.clone();
				var normalData : Vector.<Number> = viewModelMat.rawData;
				normalData[0] = normalData[7] = normalData[11] = 
					normalData[12] = normalData[13] = normalData[14] = normalData[15] = 0;
				var normalMat : Matrix3D = new Matrix3D();
				normalMat.copyRawDataFrom(normalData);
				normalMat.invert();
				
				m_matrix.append(proj);
				
				//上传投影矩阵
				m_context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, m_matrix, true);
				
				//上传模型视图矩阵
				m_context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 4, viewModelMat, true);
				//上传模型法线矩阵
				m_context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 8, normalMat, false);
				//上传灯光位置
				m_context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 12, Vector.<Number>([light.x,light.y,light.z,light.w]));
				//环境光
				m_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, Vector.<Number>([1,1,1,1]));
				//漫反射逛
				m_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, Vector.<Number>([1,1,1,1]));
				//镜面反射
				m_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 4, Vector.<Number>([1,1,1,1]));
				//材质环境光
				m_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, Vector.<Number>([0.3,0.3,0.3,1]));
				//材质漫反射
				m_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 3, Vector.<Number>([0.6,0.6,0.6,1]));
				//材质镜面反射
				m_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 5, Vector.<Number>([1,1,1,1]));
				//光权
				m_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 6, Vector.<Number>([0.3,0.4,0.3,10]));
				
				m_context3D.setVertexBufferAt(0, m_teapotMesh.positionsBuffer,0,Context3DVertexBufferFormat.FLOAT_3);
				m_context3D.setVertexBufferAt(1, m_teapotMesh.normalsBuffer,0,Context3DVertexBufferFormat.FLOAT_2);
				m_context3D.setVertexBufferAt(2, m_teapotMesh.uvBuffer,0,Context3DVertexBufferFormat.FLOAT_2);
			}else{
				
				m_matrix.append(proj);
				
				//上传投影矩阵
				m_context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, m_matrix, true);
				
				m_context3D.setVertexBufferAt(0, m_teapotMesh.positionsBuffer,0,Context3DVertexBufferFormat.FLOAT_3);
				m_context3D.setVertexBufferAt(1, m_teapotMesh.uvBuffer,0,Context3DVertexBufferFormat.FLOAT_2);
			}

			
			m_context3D.drawTriangles(m_teapotMesh.indexBuffer, 0, m_teapotMesh.IndexBufferCount);
			
			m_context3D.setTextureAt(0, null);
			m_context3D.setVertexBufferAt(0, null);
			m_context3D.setVertexBufferAt(1, null);
			m_context3D.setVertexBufferAt(2, null);
			m_context3D.setProgram(null);
		}
		
		private function setup() : void
		{
			m_teapotMesh = new Stage3DObjParser(m_teapotMeshData, m_context3D, 1);
			m_teapotTexture = Utils.getTexture(m_teapotTexuteData, m_context3D);
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
		
		public function get mesh() : Stage3DObjParser
		{
			return m_teapotMesh;
		}
		
		public function get texture() : Texture
		{
			return m_teapotTexture;
		}
		
		[Embed(source="../../source/PET_PANDA.obj",mimeType = "application/octet-stream")] 
		private var m_teapotMeshData : Class;
		private var m_teapotMesh : Stage3DObjParser;
		
		[Embed(source="../../source/PET_PANDA.jpg")]
		private var m_teapotTexuteData : Class;
		private var m_teapotTexture : Texture;
	}
}