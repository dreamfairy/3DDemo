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
	
	public class ShaderBlur extends Shader
	{

		public var strength : uint = 3;
		public var uvStep : Number = 1/512;
		
		private var m_pos : uint = 0;
		private var m_uv : uint = 1;
		private var m_emptyMatrix : uint = 0;
		
		private var m_texture : uint = 0;
		
		private var fcBlurStepConstant : uint = 0;
		private var blurStepConstantData : Vector.<Number> = Vector.<Number>([1/strength,0,0,0]);
		
		private var fcBlurUVConstant : uint = 1;
		private var blurUVConstantData : Vector.<Number> = Vector.<Number>();
		
		public function ShaderBlur(renderTarget:Object3D=null, context:Context3D=null)
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
				"tex ft0 v0 fs0\n"+
				getBlurAgal() + 
				"mov oc ft0\n");
		}
		
		private function getBlurAgal() :　String
		{
			var str : String = "";
			var uv : String = "v0";
			var tempUV : String = "ft1";
			var texture : String = "fs0";
			var texTexture : String = "ft0";
			var tempTexTexture : String = "ft2";
			
			var strengthConstant : Vector.<Number> = blurUVConstantData;
			var strengthCount : uint = fcBlurUVConstant;
			var strengthConstantIndex : String;
			var strengthComponent : Array = ["x","y","z","w"];
			var strengthComponentIndex : int = 0;
			var strengthComponentIndexCount : int = 0;
			
			for(var i : int = strength; i >= 1; i--)
			{
				strengthConstant.push(i * uvStep);
			}
			
			for(i = 0; i < strengthConstant.length; i++)
			{
				strengthConstantIndex = "fc" + strengthCount;
				var strengthReg : String = strengthConstantIndex + "." + strengthComponent[strengthComponentIndex];
				str += "add "+tempUV+" "+uv+" " + strengthReg + "\n";
				str += "tex "+tempTexTexture+" "+tempUV+" "+texture+"\n";
				str += "add "+texTexture+" "+texTexture+" "+tempTexTexture+"\n";
				str += "sub "+tempUV+" "+uv+" " + strengthReg + "\n";
				str += "tex "+tempTexTexture+" "+tempUV+" "+texTexture+"\n";
				str += "add "+texTexture+"　"+texTexture+" "+tempTexTexture+"\n";
				strengthComponentIndex = ++strengthComponentIndexCount % 4;
				if(i % 4 == 0) strengthCount++;
			}
			
			str += "mul "+texTexture+" "+texTexture+" fc0.x\n";
			
			return str;
		}
		
		public override function render(context3D:Context3D):void
		{
			context3D.setDepthTest(m_params.writeDepth, m_params.depthFunction);
			context3D.setCulling(m_params.culling);
			
			context3D.setProgram(getProgram(context3D));
			
			context3D.setTextureAt(m_texture,m_renderTarget.material.getTexture(context3D));
			
			context3D.setVertexBufferAt(m_pos, m_renderTarget.vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			context3D.setVertexBufferAt(m_uv, m_renderTarget.uvBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
			
			context3D.drawTriangles(m_renderTarget.indexBuffer,0,m_renderTarget.numTriangles);
			
			context3D.setTextureAt(m_texture,null);
		}
		
		public override function get type():uint
		{
			return BLUR;
		}
	}
}