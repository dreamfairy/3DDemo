package C3.Material.Shaders
{
	import com.adobe.utils.AGALMiniAssembler;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.utils.ByteArray;
	
	import C3.Object3D;
	
	/**
	 * 天空盒Shader
	 */
	public class ShaderSkyBox extends Shader
	{
		/**顶点**/
		private var vaPos : uint = 0;
		/**投影矩阵**/
		private var vcProjection : uint = 124;
		/**纹理**/
		private var fcTexture : uint = 0;
		/**顶点常量索引**/
		private var vertexConstIndex : uint = 0;
		/**顶点常量**/
		private var vertexConst : Vector.<Number> = Vector.<Number>([1,0,0,0]);
		
		public function ShaderSkyBox(renderTarget:Object3D=null)
		{
			super(renderTarget);
			
			m_params.blendEnabled		= 	true;
			m_params.writeDepth			=	false;
			m_params.depthFunction		=	Context3DCompareMode.LESS;
			m_params.colorMaskEnabled	=	false;
			m_params.culling			=	Context3DTriangleFace.FRONT;
		}
		
		public override function getVertexProgram():ByteArray
		{
			return new AGALMiniAssembler().assemble(Context3DProgramType.VERTEX,
				"m44 op va"+vaPos+" vc"+vcProjection+"\n"+
				"nrm vt0.xyz va"+vaPos+".xyz\n"+
				"mov vt0.w vc"+vertexConstIndex+".x\n"+
				"mov v0 vt0\n");
		}
		
		public override function getFragmentProgram():ByteArray
		{
			return new AGALMiniAssembler().assemble(Context3DProgramType.FRAGMENT,
				"tex oc v0 fs"+fcTexture+"<cube,clamp,linear,miplinear>\n");
		}
		
		public override function render(context3D:Context3D):void
		{
			context3D.setDepthTest(m_params.writeDepth,m_params.depthFunction);
			context3D.setCulling(m_params.culling);
			
			context3D.setProgram(getProgram(context3D));
			context3D.setTextureAt(fcTexture,m_material.getTexture(context3D));
			context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX,vertexConstIndex,vertexConst);
			context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX,vcProjection,m_renderTarget.camera.projectMatrix,true);
			context3D.setVertexBufferAt(0,m_renderTarget.vertexBuffer,0,Context3DVertexBufferFormat.FLOAT_3);
			context3D.drawTriangles(m_renderTarget.indexBuffer,0,m_renderTarget.numTriangles);
		}
	}
}