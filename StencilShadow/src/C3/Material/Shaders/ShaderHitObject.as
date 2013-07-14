package C3.Material.Shaders
{
	import com.adobe.utils.AGALMiniAssembler;
	
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTriangleFace;
	import flash.utils.ByteArray;

	/**
	 * 拾取物体的Shader
	 */
	public class ShaderHitObject extends Shader
	{
		private var vaPos : uint = 0;
		private var vaUV : uint = 1;
		private var vaNormal : uint = 2;
		private var vaTangent : uint = 3;
		private var vaBoneIndices : uint = 1;
		private var vaBoneWeight : uint = 3;
		
		private var vcModelToWorld : uint = 5;
		private var vcProjection : uint = 0;
		private var vcBoneMatrices : uint = 9;
		
		public function ShaderHitObject()
		{
			super();
			
			m_params.blendEnabled		= false;
			m_params.writeDepth		= true;
			m_params.depthFunction	= Context3DCompareMode.LESS;
			m_params.colorMaskEnabled	= false;
			m_params.culling			= Context3DTriangleFace.FRONT;
			m_params.loopCount		= 1;
			m_params.requiresLight	= false;
		}
		
		public override function getVertexProgram() : ByteArray
		{
			return new AGALMiniAssembler().assemble(Context3DProgramType.VERTEX,
				"m44 vt0, va"+vaPos+", vc"+vcProjection+"\n"+
				"mul vt1.xy, vt0.w, vc4.xy\n"+
				"add vt0.xy, vt0.xy, vt1.xy\n"+
				"mul vt0.xy, vt0.xy, vc4.zw\n"+
				"mov op, vt0\n");
		}
		
		public override function getFragmentProgram() : ByteArray
		{
			return new AGALMiniAssembler().assemble(Context3DProgramType.FRAGMENT,
				"mov oc, fc0\n");
		}
	}
}