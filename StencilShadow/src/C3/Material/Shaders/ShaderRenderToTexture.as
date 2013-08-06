package C3.Material.Shaders
{
	import com.adobe.utils.AGALMiniAssembler;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.textures.TextureBase;
	import flash.utils.ByteArray;
	
	import C3.Object3D;
	
	public class ShaderRenderToTexture extends Shader
	{
		public var originTexture : TextureBase;
		
		private var m_vertexProjectMatrix : uint = 0;
		private var m_pos : uint = 0;
		private var m_uv : uint = 0;
		
		private var m_fsOriginTexture : uint = 0;
		private var m_fsNewTexture : uint = 1;
		
		public function ShaderRenderToTexture(renderTarget:Object3D=null, context:Context3D=null)
		{
			super(renderTarget, context);
			
			m_params.blendEnabled		= 	true;
			m_params.writeDepth			=	true;
			m_params.depthFunction		=	Context3DCompareMode.LESS;
			m_params.colorMaskEnabled	=	false;
			m_params.culling			=	Context3DTriangleFace.FRONT_AND_BACK;
		}
		
		public override function getVertexProgram():ByteArray
		{
			new AGALMiniAssembler().assemble(Context3DProgramType.VERTEX,
				"m44 op va0 vc0\n"+
				"mov v0 va1\n");
		}
		
		public override function getFragmentProgram():ByteArray
		{
			new AGALMiniAssembler().assemble(Context3DProgramType.FRAGMENT,
				"tex oc v0 fs0\n");
		}
		
		public override function render(context3D:Context3D):void
		{
			context3D.setDepthTest(m_params.writeDepth, m_params.depthFunction);
			context3D.setCulling(m_params.culling);
			
			context3D.setProgram(getProgram(context3D));
			context3D.setTextureAt(m_fsOriginTexture,originTexture);
			context3D.setTextureAt(m_fsNewTexture,m_renderTarget.material.getTexture(context3D));
			
			context3D.setVertexBufferAt(m_pos, m_renderTarget.vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			context3D.setVertexBufferAt(m_uv, m_renderTarget.uvBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
			
			context3D.drawTriangles(m_renderTarget.indexBuffer,0,m_renderTarget.numTriangles);
			
			context3D.setTextureAt(m_fsOriginTexture,null);
			context3D.setTextureAt(m_fsNewTexture,null);
		}
		
		public override function get type():uint
		{
			return RENDER_TO_TEXTURE;
		}
	}
}