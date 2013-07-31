package C3.Material.Shaders
{
	import C3.Object3D;
	
	import com.adobe.utils.AGALMiniAssembler;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Matrix3D;
	import flash.utils.ByteArray;
	
	public class ShaderOgreSkeleton extends Shader
	{
		/**顶点**/
		private var vaPos : uint = 0;
		/**纹理坐标**/
		private var vaUV : uint = 1;
		/**法线**/
		private var vaNoraml : uint = 2;
		
		/**投影矩阵**/
		private var vcProjection : uint = 124;
		
		/**纹理**/
		private var fcTexture : uint = 0;
		
		private var m_vertexBuffer : VertexBuffer3D;
		
		public function ShaderOgreSkeleton(renderTarget:Object3D=null)
		{
			super(renderTarget);

			m_params.blendEnabled		= 	true;
			m_params.writeDepth			=	true;
			m_params.depthFunction		=	Context3DCompareMode.LESS;
			m_params.colorMaskEnabled	=	false;
			m_params.culling			=	Context3DTriangleFace.BACK;
		}
		
		public override function getVertexProgram():ByteArray
		{
			return new AGALMiniAssembler().assemble(Context3DProgramType.VERTEX,
				"m44 op va"+vaPos+" vc"+vcProjection+"\n"+
				"mov v0 va"+vaUV+"\n");
		}
		
		public override function getFragmentProgram():ByteArray
		{
			return new AGALMiniAssembler().assemble(Context3DProgramType.FRAGMENT,
				"tex oc v0 fs"+fcTexture+"<2d,linear,mipmap>\n");
		}
		
		public override function render(context3D:Context3D):void
		{
			//			context3D.clear();
			
			m_renderTarget.setContext(context3D);
			context3D.setDepthTest(m_params.writeDepth, m_params.depthFunction);
			context3D.setCulling(m_params.culling);
			
			context3D.setProgram(getProgram(context3D));
			context3D.setTextureAt(fcTexture,m_material.getTexture(context3D));
			
			var mat : Matrix3D = m_renderTarget.matrixGlobal.clone();
			mat.append(m_renderTarget.camera.viewProjMatrix);
			context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX,vcProjection,mat,true);
			context3D.setVertexBufferAt(vaPos,m_vertexBuffer,0,Context3DVertexBufferFormat.FLOAT_3);
			context3D.setVertexBufferAt(vaUV,m_renderTarget.uvBuffer,0,Context3DVertexBufferFormat.FLOAT_2);
			context3D.drawTriangles(m_renderTarget.indexBuffer,0,m_renderTarget.numTriangles);
			
			context3D.setTextureAt(fcTexture,null);
			context3D.setVertexBufferAt(vaPos,null);
			context3D.setVertexBufferAt(vaUV,null);
		}
		
		public function set vertexBuffer(buffer : VertexBuffer3D) : void
		{
			m_vertexBuffer = buffer;
		}
	}
}