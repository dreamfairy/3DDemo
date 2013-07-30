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
	import C3.Core.Managers.MaterialManager;
	
	public class ShaderShadowMap extends Shader
	{
		private var blurX : int = 2;
		private var blurY : int = 2;
		
		private var renderList : Vector.<Object3D> = new Vector.<Object3D>();
		private var vaPos : uint = 0;
		private var vaUV : uint = 1;
		
		private var vcModelCameraProjection : uint = 0;
		private var vcModelWorld : uint = 4;
		private var vcLightViewProjection : uint = 8;
		
		private var fsDepthMap : uint = 1;
		private var fsDiffuseMap : uint = 0;
		private var depthTexture : TextureBase;
		
		private var fcShadowConstant : uint = 0;
		private var fcConstant : Vector.<Number> = Vector.<Number>([1000,0.5,1,2.5]);
		
		private var fcBlurConstant : uint = 1;
		private var blurConstantData : Vector.<Number> = Vector.<Number>([1/512,1/512,3,0]);
		
		public function ShaderShadowMap(renderTarget:Object3D=null)
		{
			super(renderTarget);
			
			m_params.blendEnabled		= 	true;
			m_params.writeDepth			=	true;
			m_params.depthFunction		=	Context3DCompareMode.LESS;
			m_params.colorMaskEnabled	=	false;
			m_params.culling			=	Context3DTriangleFace.BACK;
			
//			MaterialManager.addBeforeRenderShader(this);
		}
		
		public override function getVertexProgram():ByteArray
		{
			return new AGALMiniAssembler().assemble(Context3DProgramType.VERTEX,
				//投影到场景相机
				"m44 vt0 va"+vaPos+" vc"+vcModelCameraProjection+"\n"+
				//投影到世界
				"m44 vt1 va"+vaPos+" vc"+vcModelWorld+"\n"+
				//投影到灯光世界
				"m44 vt2 vt1 vc"+vcLightViewProjection+"\n"+
				
				"mov op vt0\n"+
				"mov v0 va"+vaUV+"\n"+
				"mov v1 vt2\n");
		}
		
		public override function getFragmentProgram():ByteArray
		{
			return new AGALMiniAssembler().assemble(Context3DProgramType.FRAGMENT,
				//纹理采样
				"tex ft0 v0 fs"+fsDiffuseMap+"<2d,wrap,linear>\n"+
				
				//将坐标转换到其次坐标
				"div ft1.xy v1.xy v1.ww\n"+
				
				//将坐标转换到纹理UV fc2.y = 0.5
				// 0.5 * xy + 0.5;
				
				"mul ft1.xy ft1.xy fc"+fcShadowConstant+".y\n"+
				"add ft1.xy ft1.xy fc"+fcShadowConstant+".y\n"+
				
				"neg ft1.y ft1.y\n"+
				
				//阴影图深度采样
				"tex ft2 ft1.xy fs"+fsDepthMap+"<2d,wrap,linear>\n"+
				
//				getBlurAgal() +

				"mul ft3.z ft2.z fc"+fcShadowConstant+".x\n"+
				"add ft3.z ft3.z fc"+fcShadowConstant+".w\n"+
				"sge ft3.w ft3.z v1.z\n"+
				"add ft3.w ft3.w fc"+fcShadowConstant+".y\n" +
				"mul ft0 ft0 ft3.w\n"+
				"mov oc ft0\n");
		}
		
		private function getBlurAgal() :　String
		{
			var uvList : Array = ["x","y"];
			var str : String = "";
			for(var i : int = 0; i < uvList.length; i++)
			{
				var coord : String = uvList[i];
				
				str +=
				"mov ft4.xy ft1.xy\n" +
				"add ft4."+coord+" ft4."+coord+" fc"+fcBlurConstant+".x\n" +
				"tex ft6 ft4.xy fs"+fsDepthMap+"<2d,wrap,linear>\n"+
				"mov ft4.xy ft1.xy\n" +
				"add ft4."+coord+" ft4."+coord+" fc"+fcBlurConstant+".y\n"+
				"tex ft7 ft4.xy fs"+fsDepthMap+"<2d,wrap,linear>\n"+
				"add ft7 ft7 ft6\n"+
				"add ft7 ft7 ft2\n";
			}
			str += 
				"div ft7 ft7 fc"+fcBlurConstant+".z\n"+
				"mov ft2 ft7\n";
			
			return str;
		}
		
		public override function render(context3D:Context3D):void
		{
			depthTexture = MaterialManager.getShader(DEPTH_MAP,context3D).material.getTexture(context3D);
			
//			context3D.clear();
			context3D.setProgram(getProgram(context3D));
			context3D.setTextureAt(fsDepthMap,depthTexture);
			context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT,fcShadowConstant,
				fcConstant);
			context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT,fcBlurConstant,
				blurConstantData);
			
			for each(var target : Object3D in renderList)
			{
				updateShaderParams(target,context3D);
				
				//modelViewProj
				context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX,vcModelCameraProjection,target.modelViewProjMatrix,true);
				
				//modelWorld
				context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX,vcModelWorld,target.matrixGlobal,true);
				
				//modelLightProj
				context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX,vcLightViewProjection,
					target.camera.lightProjection,true);
				
				context3D.setTextureAt(fsDiffuseMap,target.material.getTexture(context3D));
				context3D.setVertexBufferAt(vaPos,target.vertexBuffer,0,Context3DVertexBufferFormat.FLOAT_3);
				context3D.setVertexBufferAt(vaUV,target.uvBuffer,0,Context3DVertexBufferFormat.FLOAT_2);
				context3D.drawTriangles(target.indexBuffer,0,target.numTriangles);
			}
			
			context3D.setTextureAt(fsDepthMap,null);
			context3D.setTextureAt(fsDiffuseMap,null);
			context3D.setVertexBufferAt(vaPos,null);
			context3D.setVertexBufferAt(vaUV,null);
		}
		
		public function addTarget(target : Object3D) : void
		{
			if(renderList.indexOf(target) == -1)
				renderList.push(target);
		}
		
		public function removeTarget(target : Object3D) : void
		{
			var index : int = renderList.indexOf(target);
			if(index != -1) renderList.splice(index, 1);
		}
		
		public override function dispose():void
		{
			renderList = null;
			fcConstant = null;
		}
		
		public override function get type():uint
		{
			return SHADOW_MAP;
		}
	}
}