package
{
	import com.adobe.utils.AGALMiniAssembler;
	import com.adobe.utils.PerspectiveMatrix3D;
	
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.Texture;
	import flash.events.Event;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	
	import C3.Light.SimpleLight;
	import C3.MD5.MD5Result;

	/**
	 * 这次肯定能写出来了
	 */
	[SWF(width = "512", height = "512", frameRate="60")]
	public class ShadowMapFinalTest extends ContextBase
	{
		public function ShadowMapFinalTest()
		{
			super();
		}
		
		protected override function onCreateContext(e:Event):void
		{
			super.onCreateContext(e);
			
			setupModel();
			setupShader();
			setupDepthMap();
			
			m_showQuad = createQuad("show")
			addEventListener(Event.ENTER_FRAME, onEnter);
		}
		
		/**
		 * 初始化
		 * 丢一个md5模型出来
		 */
		private function setupModel() : void
		{
			md5Result = new MD5Result(m_context);
			md5Result.addEventListener("meshLoaded", onMeshComplete);
			md5Result.loadModel(new mesh as ByteArray);
			md5Result.loadAnim(new anim as ByteArray);
			
			m_diffusetexture = Utils.getTexture(textureData,m_context);
			m_normalTexture = Utils.getTexture(normalData,m_context);
			
			m_viewMatrix.identity();
			m_viewMatrix.appendTranslation(0,30,100);
			m_viewMatrix.invert();
			
			//使用透视投影来模拟点光
//			m_lightProj.copyFrom(m_projMatrix);
			
			//使用正交投影来模拟平行光
			m_lightProj.orthoRH(stage.stageWidth,stage.stageHeight,m_zNear,m_zFar);
		}
		
		private function setupShader() : void
		{
			//默认shader
			var vertexShader : AGALMiniAssembler = new AGALMiniAssembler();
			vertexShader.assemble(Context3DProgramType.VERTEX,
				"m44 op va0 vc124\n"+
				"mov v0 va1\n");
			
			var fragmentShader : AGALMiniAssembler = new AGALMiniAssembler();
			fragmentShader.assemble(Context3DProgramType.FRAGMENT,
				"tex ft0 v0 fs0<2d, linear, repeat\n"+
				"tex ft1 v0 fs1<2d, linear, repeat\n"+
				"mov oc ft0\n");
			
			m_defaultShader = m_context.createProgram();
			m_defaultShader.upload(vertexShader.agalcode, fragmentShader.agalcode);
		}
		
		/**
		 * 初始化深度图及相关数据
		 */
		private function setupDepthMap() : void
		{
			//准备阴影图,并开启为RTT优化
			m_shaderMap = m_context.createTexture(
				m_shadowMapSize,
				m_shadowMapSize,
				Context3DTextureFormat.BGRA,
				true
			);
			
			/**
			 * 阴影shader
			 * 将顶点丢入fragmentShader
			 */
			var depthPassVertexShader : AGALMiniAssembler = new AGALMiniAssembler();
			depthPassVertexShader.assemble(Context3DProgramType.VERTEX,
				//将顶点转入灯光投影空间mvp
				"m44 vt0 va0 vc0\n"+
				//输出顶点
				"mov op vt0\n"+
				//传入像素着色器
				"mov v0 vt0\n");
			
			var depthPassFragmengShader : AGALMiniAssembler = new AGALMiniAssembler();
			depthPassFragmengShader.assemble(Context3DProgramType.FRAGMENT,
				//将 w/zFar = z;
				"mov ft0 v0.zzzz\n"+
//				"div ft0 v0.w fc0.x\n"+ 
//				//将颜色编码为 32 位浮点型数据存入RGBA
//				"mul ft0 ft0 fc1\n"+
//				//取出小数部分
//				"frc ft0 ft0\n"+
//				//255掩码
//				"mul ft1 ft0.zzwz fc2\n"+
//				"sub ft0 ft0 ft1\n"+
				//清除0像素
				"kil ft0.wwww\n"+
				"mov oc ft0\n");
			
			m_shaderPassShader = m_context.createProgram();
			m_shaderPassShader.upload(depthPassVertexShader.agalcode,depthPassFragmengShader.agalcode);
			
			//模型深度图采样shader
			var modelVertexShader : AGALMiniAssembler = new AGALMiniAssembler();
			modelVertexShader.assemble(Context3DProgramType.VERTEX,
				//顶点转换到相机投影mvp
				"m44 op va0 vc0\n"+
				//顶点转移到灯光投影mvp
				"m44 v0 va0 vc4\n"+
				//相机投影顶点->v1, 之后v0和v1要做比较
				"mov v1 va0\n"+
				//法线丢入v2 貌似不要计算光照=.= 无所谓啦,蛮丢了
//				"mov v2 va1\n"+
				//uv丢入v3
				"mov v3 va2\n");
			
			var modelFragmentShader : AGALMiniAssembler = new AGALMiniAssembler();
			modelFragmentShader.assemble(Context3DProgramType.FRAGMENT,
				"tex ft0, v3, fs0<2d,wrap,linear>\n"+
				"tex ft1, v3, fs1<2d,wrap,linear>\n"+
				"tex ft2, v3, fs2<2d,wrap,linear>\n"+

				"sge ft3 v0.z ft0.z\n"+
				"add ft3 ft3 fc0.x\n"+
				"mul ft3 ft1 ft3\n"+
				"mov oc ft3\n");
//				//将投影缩放的其次坐标空间
//				"div ft0 v1.xyz v1.w\n"+
//				//从NDC坐标系转换到纹理坐标系
//				//ft0.x = 0.5 * ft0.x + 0.5;
//				//ft0.y = -0.5 * ft0.y + 0.5;
//				//fc0(0.5, -0.5, m_shadowMapDx, m_shadowEpsilon);
//				//fc1(m_shadowMapSize,0,0,0.15);
//				"mul ft0.x ft0.x fc0.x\n"+
//				"add ft0.x ft0.x fc0.x\n"+
//				"mul ft0.y ft0.y fc0.y\n"+
//				"add ft0.y ft0.y fc0.x\n"+
//				
//				//阴影图采样
//				//平滑阴影边缘
//				"mov ft1 v3\n"+
//				"mov ft2.xy ft1.xy\n"+ //xy + (0,0);
//				"tex ft2 ft2.xy fs0<2d,wrap,nearest>\n"+
//				
//				"mov ft3.xy ft1.xy\n"+
//				"add ft3.x ft3.x fc1.x\n"+ //xy + (m_shadowMapSize,0);
//				"tex ft3 ft3.xy fs0<2d,wrap,nearest>\n"+
//				
//				"mov ft4.xy ft1.xy\n"+
//				"add ft4.y ft4.y fc1.x\n"+ //xy + (0, m_shadowMapSize);
//				"tex ft4 ft4.xy fs0<2d,wrap,nearest>\n"+
//				
//				"mov ft5.xy ft1.xy\n"+
//				"add ft5.xy ft5.xy fc1.xx\n"+ //xy + (m_shadowMapSize,m_shadowMapSize);
//				"tex ft5 ft5.xy fs0<2d,wrap,nearest>\n"+
//				
//				//ft1.xyzw 存储4个result 
//				"add ft1.x ft2.x fc0.w\n"+
//				"add ft1.y ft3.x fc0.w\n"+
//				"add ft1.z ft4.x fc0.w\n"+
//				"add ft1.w ft5.x fc0.w\n"+
//				
//				//判断像素是否在阴影中
//				//result = ft1.xyzw > depth, ft0.z = depth;
//				"sge ft1.x ft1.x ft0.z\n"+
//				"sge ft1.y ft1.y ft0.z\n"+
//				"sge ft1.z ft1.z ft0.z\n"+
//				"sge ft1.w ft1.w ft0.z\n"+
//				
//				//ft2,3,4,5 回收
//				//转换到纹理空间
//				"mul ft3.xy fc1.xx ft0.xy\n"+
//				//检测差值数量
//				"frc ft3.xy ft3.xy\n"+
//				
//				//计算平滑结果值
//				//lerp = a-(a*t) + (b*t); ->ft2.w
//				//先平滑a lerp(ft1.x,ft1.y,ft3.x);
//				//再平滑b lerp(ft1.z,ft1.w,ft3.x);
//				//t = ft3.y
//				
//				//ft1.x-(ft1.x * ft3.x) -> ft4.x
//				"mul ft4.x ft1.x ft3.x\n"+
//				"sub ft4.x ft1.x ft4.x\n"+
//				//ft1.y * ft3.x -> ft4.y
//				"mul ft4.y ft1.y ft3.x\n"+
//				"add ft5.x ft4.x ft4.y\n"+
//				
//				//ft1.z-(ft1.z * ft3.x) -> ft4.x
//				"mul ft4.x ft1.z ft3.x\n"+
//				"sub ft4.x ft1.z ft4.x\n"+
//				//ft1.w * ft3.x -> ft4.y
//				"mul ft4.y ft1.w ft3.x\n"+
//				"add ft5.y ft4.x ft4.y\n"+
//				
//				//a = ft5.x b = ft5.y t = ft3.y
//				"mul ft4.x ft5.x ft3.y\n"+
//				"sub ft4.x ft5.x ft4.x\n"+
//				"mul ft4.y ft5.y ft3.y\n"+
//				
//				//差值结果 ft4.w ft3,5回收
//				"add ft4.w ft4.x ft4.y\n"+
//				
//				//模型纹理采样
//				"tex ft2 v3 fs1<2d,wrap,nearest>\n"+
//				
//				//模型法线采样
//				"tex ft3 v3 fs2<2d,wrap,nearest>\n"+
//				
//				//fc2 灯光方向 fc3 灯光颜色
//				//混合灯光颜色
//				"mul ft2 ft2 fc3\n"+
//				//计算反射因子
//				"dp3 ft5 fc2 ft3\n"+
//				//混合反 射因子 和 投影混合
//				"mul ft5.xyzw ft4.wwww ft5.xyzw\n"+
//				//叠加因子
//				"add ft2 ft2 ft5\n"+
//				"mov oc ft2\n");
//			
			m_modelDepthShader = m_context.createProgram();
			m_modelDepthShader.upload(modelVertexShader.agalcode,modelFragmentShader.agalcode);
		}
		
		private function onMeshComplete(e:Event) : void
		{
			m_hasMeshData = true;
		}
		
		private var t : Number = 0;
		private function onEnter(e:Event) : void
		{
			t++;
			//渲染到纹理
			m_context.clear();
			m_context.setRenderToTexture(m_shaderMap,true);
			renderShadowMap();
			renderModel();
//			renderQuadShow();
//			renderKeyBoard();
			m_context.present();
		}
		
		/**
		 * 看看深度图长啥样
		 */
		private function renderQuadShow() : void
		{
			m_context.clear(.5,.5,.5);
			
			m_context.setTextureAt(0, m_shaderMap);
			m_context.setProgram(shadowShader);
			
			m_showQuad.transform.identity();
			m_showQuad.transform.appendScale(10,10,10);
			m_showQuad.transform.appendTranslation(0,0,0);
			
			m_viewMatrix.identity();
			m_viewMatrix.appendTranslation(0,0,-30);
			
			m_finalMatrix.identity();
			m_finalMatrix.append(m_showQuad.transform);
			m_finalMatrix.append(m_viewMatrix);
			m_finalMatrix.append(m_projMatrix);
			
			m_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX,0,m_finalMatrix,true);
			m_context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, Vector.<Number>([60, 1, 0, 0]));
			m_context.setVertexBufferAt(0,m_showQuad.vertexBuffer,0,Context3DVertexBufferFormat.FLOAT_3);
			m_context.setVertexBufferAt(1,m_showQuad.uvBuffer,0,Context3DVertexBufferFormat.FLOAT_2);
			m_context.drawTriangles(m_showQuad.indexBuffer);
			
			m_context.setTextureAt(0, null);
			m_context.setVertexBufferAt(0,null);
			m_context.setVertexBufferAt(1,null);
		}
		
		private function renderShadowMap() : void
		{
			m_context.clear();

			m_context.setCulling(Context3DTriangleFace.FRONT);
			//使用正交投影模拟阳光渲染模型
			
			m_lightModel.identity();
			m_lightModel.appendRotation(90,Vector3D.Y_AXIS);
			m_lightModel.appendRotation(-t, Vector3D.X_AXIS);
			m_lightModel.appendScale(3,3,3);
			m_lightModel.appendTranslation(stage.stageWidth/2,stage.stageHeight/2 - 200,0);
			
			m_lightView.identity();
			m_lightView.appendTranslation(-stage.stageWidth/2,-stage.stageHeight/2,0);
			m_lightView.appendTranslation(1,-1,1);
//			m_lightView.pointAt(m_lightModel.position,CAM_FACING,CAM_UP);
//			m_lightView.invert();
			
			m_lightFinal.identity();
			m_lightFinal.append(m_lightModel);
			m_lightFinal.append(m_lightView);
			m_lightFinal.append(m_lightProj);
			
			//vc0 灯光投影矩阵
			m_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, m_lightFinal, true);
			
			//使用shadowMapShader渲染模型
			m_context.setProgram(m_shaderPassShader);
			
			for(var i : int = 0; i < md5Result.meshDataNum; i++){
				var vertexBuffer : VertexBuffer3D = md5Result.vertexBufferList[i];
				var uvBuffer : VertexBuffer3D = md5Result.uvBufferList[i];
				var indexBuffer : IndexBuffer3D = md5Result.indexBufferList[i];
				
				m_context.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
//				m_context.setVertexBufferAt(1,uvBuffer,0,Context3DVertexBufferFormat.FLOAT_2);
				m_context.drawTriangles(indexBuffer);
			}
			
			//输出到纹理
			m_context.present();
		}
		
		private function renderModel() : void
		{
			m_context.clear();

			m_context.setCulling(Context3DTriangleFace.BACK);
			m_context.setProgram(m_modelDepthShader);
			
			m_modelMatrix.identity();	
			m_modelMatrix.appendRotation(-90,Vector3D.X_AXIS);
//			m_modelMatrix.appendRotation(-90,Vector3D.Y_AXIS);
			m_modelMatrix.appendRotation(t, Vector3D.Y_AXIS);
			m_modelMatrix.appendScale(.1,.1,.1);
			m_modelMatrix.appendTranslation(0,-6,-20);
			
			m_viewMatrix.identity();
			m_viewMatrix.invert();
			
			m_finalMatrix.identity();
			m_finalMatrix.append(m_modelMatrix);
			m_finalMatrix.append(m_viewMatrix);
			m_finalMatrix.append(m_projMatrix);
			
			m_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 124, m_finalMatrix, true);
			
			//fs0 阴影查询图
			m_context.setTextureAt(0, m_shaderMap);
			m_context.setTextureAt(1, m_diffusetexture);
			m_context.setTextureAt(2, m_normalTexture);
			
			m_context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, Vector.<Number>([0.5, -0.5, m_shadowMapDx, m_shadowEpsilon]));
			m_context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, Vector.<Number>([m_shadowMapSize, 0, 0, 0.15]));
			//传入光照角度
			var lightNorm : Vector3D = m_light.normalize;
			m_context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, Vector.<Number>([lightNorm.x,lightNorm.y,lightNorm.z,lightNorm.w]));
			//传入光照颜色
			m_context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 3, m_light.getAmbient());
			
			m_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, m_finalMatrix, true);
			m_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 4, m_lightFinal, true);
			
			for(var i : int = 0; i < md5Result.meshDataNum; i++){
				var vertexBuffer : VertexBuffer3D = md5Result.vertexBufferList[i];
				var uvBuffer : VertexBuffer3D = md5Result.uvBufferList[i];
				var indexBuffer : IndexBuffer3D = md5Result.indexBufferList[i];
				
				m_context.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
				m_context.setVertexBufferAt(2,uvBuffer,0,Context3DVertexBufferFormat.FLOAT_2);
				m_context.drawTriangles(indexBuffer);
			}
			
			m_context.setTextureAt(0, null);
			m_context.setTextureAt(1, null);
			m_context.setTextureAt(2, null);
			
			m_context.setVertexBufferAt(0, null);
			m_context.setVertexBufferAt(1, null);
			m_context.setVertexBufferAt(2, null);
		}
		
		protected override function renderKeyBoard():void
		{
			
		}
		
		private function createQuad(name : String) : QuadInfo
		{
			var vertexList : Vector.<Number> = new Vector.<Number>();
			vertexList.push(-1,1,0);
			vertexList.push(1,1,0);
			vertexList.push(1,-1,0);
			vertexList.push(-1,-1,0);
			
			var indexList : Vector.<uint> = new Vector.<uint>();
			indexList.push(0,1,2);
			indexList.push(0,2,3);
			
			var uvList : Vector.<Number> = new Vector.<Number>();
			uvList.push(0,0,1,0,1,1,0,1);
			
			var normalList : Vector.<Number> = new Vector.<Number>();
			normalList.push(0,0,0,0,0,0,0,0,0,0,0,0);
			
			var quad : QuadInfo = new QuadInfo();
			quad.name = name;
			
			quad.vertexBuffer = m_context.createVertexBuffer(4,3);
			quad.vertexBuffer.uploadFromVector(vertexList,0,4);
			
			quad.indexBuffer = m_context.createIndexBuffer(6);
			quad.indexBuffer.uploadFromVector(indexList,0,6);
			
			quad.uvBuffer = m_context.createVertexBuffer(4,2);
			quad.uvBuffer.uploadFromVector(uvList,0,4);
			
			quad.normalBuffer = m_context.createVertexBuffer(4,3);
			quad.normalBuffer.uploadFromVector(normalList,0,4);
			
			return quad;
		}
		
		private function get shadowShader() : Program3D
		{
			if(m_depthShader) return m_depthShader;
			
			var vertexStr : String = "m44 vt0, va0, vc0\n"+
				"mov op, vt0\n"+
				"mov v0, va1\n"+
				"mov v1, vt0\n";
			
			var vertexProgram : AGALMiniAssembler = new AGALMiniAssembler();
			vertexProgram.assemble(Context3DProgramType.VERTEX,vertexStr);
			
			var fragmentStr : String = "tex ft0, v0, fs0<2d,linear,mipnone>\n"+
				"mov oc, ft0\n";
			
			var fragtmentProgram : AGALMiniAssembler = new AGALMiniAssembler();
			fragtmentProgram.assemble(Context3DProgramType.FRAGMENT,fragmentStr);
			
			m_depthShader = m_context.createProgram();
			m_depthShader.upload(vertexProgram.agalcode,fragtmentProgram.agalcode);
			
			return m_depthShader;
		}
		
		[Embed(source="../source/hellknight/hellknight.md5mesh", mimeType="application/octet-stream")]
		private var mesh : Class;
		
		[Embed(source="../source/hellknight/idle2.md5anim", mimeType="application/octet-stream")]
		private var anim : Class;
		
		[Embed(source="../source/hellknight/hellknight_diffuse.jpg")]
		private var textureData : Class;
		
		[Embed(source="../source/hellknight/hellknight_normals.png")]
		private var normalData : Class;
		
		private var md5Result : MD5Result;
		private var m_diffusetexture : Texture;//difuse texture
		private var m_normalTexture : Texture; //normal texture;
		private var m_modelMatrix : Matrix3D = new Matrix3D();
		private var m_hasMeshData : Boolean;
		
		private var m_defaultShader : Program3D;
		private var m_showQuad : QuadInfo;
		private var m_depthShader : Program3D;
		
		//阴影图部分
		private var m_shadowEpsilon : Number = 0.001;
		private var m_shadowMapSize : int = 1024;
		private var m_shadowMapDx : Number = 1.0 / m_shadowMapSize;
		private var m_modelDepthShader : Program3D;
		private var m_shaderPassShader : Program3D;
		private var m_shaderMap : Texture;
		private var m_shadowAlpha : Number = .4;
		
		//灯光部分
		private var m_lightModel : Matrix3D = new Matrix3D(); //灯光模型
		private var m_lightView : Matrix3D = new Matrix3D(); //灯光视图
		private var m_lightProj : PerspectiveMatrix3D = new PerspectiveMatrix3D();
		private var m_lightFinal : Matrix3D = new Matrix3D();
		private var m_light : SimpleLight = new SimpleLight(0xFFFFFF,1);
	}
}

import flash.display3D.IndexBuffer3D;
import flash.display3D.VertexBuffer3D;
import flash.geom.Matrix3D;

class QuadInfo
{
	public var name : String;
	public var vertexBuffer : VertexBuffer3D;
	public var indexBuffer : IndexBuffer3D;
	public var uvBuffer : VertexBuffer3D;
	public var normalBuffer : VertexBuffer3D;
	public var transform : Matrix3D = new Matrix3D();
}