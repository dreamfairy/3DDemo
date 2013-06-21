package C3.PostRender
{
	import com.adobe.utils.AGALMiniAssembler;
	
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Program3D;
	import flash.display3D.textures.Texture;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	import C3.View;
	import C3.Camera.Camera;
	import C3.Light.SimpleLight;

	public class ShadowMapping implements IPostRender
	{
		public function ShadowMapping(light : SimpleLight, target : Vector3D)
		{
			m_light = light;
			m_target = target;
		}
		
		public function dispose():void
		{
			m_depth.dispose();
		}
		
		public function renderAfter(passCount : int):void
		{
			View.context.setRenderToBackBuffer();
			
			//还原相机矩阵
			m_hasPassdone = true;
		}
		
		public function renderBefore(passCount : int):void
		{
			if(null == m_depth)
				createDepthTexture();
			
			if(null == m_lightMatrix)
				createLightMatrix();
			
			//把当前相机的矩阵转换到灯光的矩阵
			View.camera.replaceViewMatrix(m_lightMatrix);
			m_hasPassdone = false;
			
			//设置全局的阴影图,fs7
			View.context.setTextureAt(1, m_depth);
		}
		
		public function get needReRender():Boolean
		{
			return true;
		}
		
		/**
		 * 创建查询纹理和后期处理图
		 */
		private function createDepthTexture() : void
		{
			//创建512*512的阴影图
			m_depth = View.context.createTexture(512,512,
				Context3DTextureFormat.BGRA,
				true
			);
			
			m_output = View.context.createTexture(512,512,
				Context3DTextureFormat.BGRA,
				true
			);
		}
		
		/**
		 * 创建灯光矩阵
		 */
		private function createLightMatrix() : void
		{
			m_lightMatrix = new Matrix3D();
			m_lightMatrix.appendTranslation(m_light.x,m_light.y,m_light.z);
			m_lightMatrix.pointAt(m_target,Camera.CAM_FACING,Camera.CAM_UP);
		}
		
		/**
		 * 创建深度图顶点agal
		 */
		private function createDepthVertexAgal() : void
		{
			m_depthVertexStr = new AGALMiniAssembler();
			m_depthVertexStr.assemble(Context3DProgramType.VERTEX,
				//切换到灯光相机坐标,VC0为灯光相机矩阵
			 	"m44 ft0, va0, vc0\n"+
				//投影深度为投影变换后的ZW分量
				"mov v0.xy, ft0.zw");
		}
		
		/**
		 * 创建深度图像素agal
		 */
		private function createDepthFragementAgal() : void
		{
			//生成深度图
			m_depthFragementStr = new AGALMiniAssembler();
			m_depthFragementStr.assemble(Context3DProgramType.FRAGMENT,
				//把2个分量相除，得到颜色灰度
				"sub ft0.w, v0.x, v0.y\n"+
				"mov oc, f0.w");
		}
		
		/**
		 * 创建深度Shader
		 */
		private function createDepthShader() : void
		{
			m_depthShader = View.context.createProgram();
			m_depthShader.upload(m_depthVertexStr.agalcode, m_depthFragementStr.agalcode);
		}
		
		/**
		 * 创建阴影顶点agal
		 */
		private function createShadowVertexAgal() : void
		{
			m_shadowVertexStr = new AGALMiniAssembler();
			m_shadowVertexStr.assemble(Context3DProgramType.VERTEX,
				//将相机坐标传入vt0, vc1为相机坐标
				"mov vt0, vc1\n"+
				//将相机坐标转换到灯光相机投影钟, vc0为灯光相机矩阵
				"m44 vt0, vt0, vc1\n" +
				"mov v0, vt0");
				
				
		}
		
		/**
		 * 创建阴影像素agal
		 */
		private function createShadowFragmentAgal() : void
		{
		}
		
		public function get hasPassDoen():Boolean
		{
			return m_hasPassdone;
		}
		
		private var m_depth : Texture;
		private var m_output : Texture;
		private var m_lightMatrix : Matrix3D;
		private var m_passStep : uint = 0;
		private var m_light : SimpleLight;
		private var m_target : Vector3D;
		private var m_hasPassdone : Boolean = false;
		
		private var m_depthShader : Program3D;
		private var m_depthVertexStr : AGALMiniAssembler;
		private var m_depthFragementStr : AGALMiniAssembler;
		
		private var m_shadowShader : Program3D;
		private var m_shadowVertexStr : AGALMiniAssembler;
		private var m_shadowFragmenStr : AGALMiniAssembler;
	}
}