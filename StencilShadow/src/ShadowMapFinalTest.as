package
{
	import C3.MD5.MD5Result;
	
	import com.adobe.utils.AGALMiniAssembler;
	import com.adobe.utils.PerspectiveMatrix3D;
	
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.Texture;
	import flash.events.Event;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;

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
			
			m_showQuad = createQuad("show");
			
			m_viewMatrix.identity();
			
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
				1024,
				1024,
				Context3DTextureFormat.BGRA,
				true
			);
			
			/**
			 * 阴影shader
			 * 将顶点丢入fragmentShader
			 */
			var depthPassVertexShader : AGALMiniAssembler = new AGALMiniAssembler();
			depthPassVertexShader.assemble(Context3DProgramType.VERTEX,
				"m44 vt0 va0 vc0\n"+
				"mov op vt0\n"+
				"mov v0 vt0\n");
			
			var depthPassFragmengShader : AGALMiniAssembler = new AGALMiniAssembler();
			depthPassFragmengShader.assemble(Context3DProgramType.FRAGMENT,
				//将深度缩放在 zFar 之内
				"div ft0 v0.z fc0.x\n"+ 
				//将颜色编码为 32 位浮点型数据存入RGBA
				"mul ft0 ft0 fc1\n"+
				//取出小数部分
				"frc ft0 ft0\n"+
				//255掩码
				"mul ft1 ft0.yzww fc2\n"+
				"sub ft0 ft0 ft1\n"+
				"mov oc ft0\n");
			
			m_shaderPassShader = m_context.createProgram();
			m_shaderPassShader.upload(depthPassVertexShader.agalcode,depthPassFragmengShader.agalcode);
			
			//模型深度图采样shader
			var modelVertexShader : AGALMiniAssembler = new AGALMiniAssembler();
			modelVertexShader.assemble(Context3DProgramType.VERTEX,
				//顶点转换到相机投影
				"m44 op va0 vc0\n"+
				//顶点转移到灯光投影
				"m44 v0 va0 vc4\n"+
				//相机投影顶点->v1, 之后v0和v1要做比较
				"mov v1 va0\n"+
				//法线丢入v2 貌似不要计算光照=.= 无所谓啦,蛮丢了
//				"mov v2 va1\n"+
				//uv丢入v3
				"mov v3 va2\n");
			
			var modelFragmentShader : AGALMiniAssembler = new AGALMiniAssembler();
			modelFragmentShader.assemble(Context3DProgramType.FRAGMENT,
				//将深度缩放在 zFar 之内
				"div ft0, v0.z fc0.x\n"+
				//转换到1维屏幕
				"div ft2 v0.xy v0.ww\n"+
				//ft2.xyzw += 1
				"add ft2 ft2 fc0.y\n"+
				//取1/2
				"mul ft2 ft2 fc0.z\n"+
				//将ft2.y取反 1-ft2.y
				"sub ft2.y fc0.y ft2.y\n"+
				//将模糊次数放置到ft1中
				"mov ft1 fc0.w\n"+
				//计算模糊在阴影图纹理大小的分量
				"mul ft1 ft1 fc1.w\n"+
				"add ft2.x ft2.x ft1\n"+
				
				//阴影图采样
				"tex ft3 ft2.xy fs0<2d,wrap,linear>\n"+
				//将像素转换成深度
				"dp4 ft3 ft3 fc2\n"+
				//当前顶点和灯光像素深度减去世界投影深度
				"sub ft3 ft3 ft0\n"+
				//如果 ft3 > fc3.x ? ft4 = 1 : ft4 = 0;
				//fc3.x 阴影比较值
				"sge ft4 ft3 fc3.x\n"+
				"mov ft5 ft4\n"+
				//将像素偏移到纹理上去
				"add ft2.x ft2.x fc1.w\n"+
				
				"div ft5 ft5 fc3.y\n"+
				"mul ft5 ft5 fc3.z\n"+
				"add ft5 ft5 fc3.z\n"+
				"sat ft5 ft5\n"+
				"mul ft5.xyz ft5.xyz fc1.xyz\n"+
				"mov ft0 ft5\n"+
				
				//模型纹理采样
				"tex ft1 v3 fs1<2d, wrap, linear>\n"+
				//阴影+阴影透明度 0+shadowAlpha 1+shadowAlpha
				"add ft4 ft4 fc3.z\n"+
				//将纹理像素和阴影分量混合
				"mul ft1 ft1 ft4\n"+
				"mov oc ft1\n");
			
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
			renderQuadShow();
//			renderModel();
//			renderKeyBoard();
			m_context.present();
		}
		
		/**
		 * 看看深度图长啥样
		 */
		private function renderQuadShow() : void
		{
			m_context.clear();
			
			m_context.setTextureAt(0, m_shaderMap);
			m_context.setProgram(shadowShader);
			
			m_showQuad.transform.identity();
			m_showQuad.transform.appendScale(10,10,10);
			m_showQuad.transform.appendTranslation(0,0,-20);
			
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
			m_lightModel.identity();
			m_lightModel.appendRotation(-90,Vector3D.X_AXIS);
			m_lightModel.appendRotation(t, Vector3D.Y_AXIS);
			m_lightModel.appendScale(.1,.1,.1);
			m_lightModel.appendTranslation(0,-6,-20);
			
			m_lightView.identity();
			m_lightView.appendTranslation(-50,0,0);
			m_lightView.pointAt(new Vector3D(0,-6,-20),CAM_FACING,CAM_UP);
			m_lightView.invert();
			
//			m_modelMatrix.identity();
//			m_modelMatrix.appendRotation(-90,Vector3D.X_AXIS);
//			m_modelMatrix.appendRotation(-90,Vector3D.Y_AXIS);
//			m_modelMatrix.appendRotation(t, Vector3D.Y_AXIS);
//			m_modelMatrix.appendScale(.1,.1,.1);
//			m_modelMatrix.appendTranslation(0,-6,-20);
			
			m_lightProj.identity();
			m_lightProj.append(m_lightModel);
			m_lightProj.append(m_lightView);
			m_lightProj.append(m_projMatrix);
			
			//vc0 灯光投影矩阵
			m_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, m_lightProj, true);
			//fc0 m_zFar 最大深度
			m_context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT,0, Vector.<Number>([m_zFar,1,1,1]));
			//1,255,255*255,255*255*255
			m_context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT,1, Vector.<Number>([1,255,65025,16581375]));
			//[(1.0/255.0),(1.0/255.0),(1.0/255.0),0.0]
			m_context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT,2, Vector.<Number>([1/255,1/255,1/255,0]));
			
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
			m_context.setProgram(m_modelDepthShader);
			
			m_modelMatrix.identity();
			
			m_modelMatrix.appendRotation(-90,Vector3D.X_AXIS);
//			m_modelMatrix.appendRotation(-90,Vector3D.Y_AXIS);
			m_modelMatrix.appendRotation(t, Vector3D.Y_AXIS);
			m_modelMatrix.appendScale(.1,.1,.1);
			m_modelMatrix.appendTranslation(0,-6,-20);
			
			m_finalMatrix.identity();
			m_finalMatrix.append(m_modelMatrix);
			m_finalMatrix.append(m_viewMatrix);
			m_finalMatrix.append(m_projMatrix);
			
			m_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 124, m_finalMatrix, true);
			
			//fs0 阴影查询图
			m_context.setTextureAt(0, m_shaderMap);
			m_context.setTextureAt(1, m_diffusetexture);
			
			m_context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, Vector.<Number>([m_zFar, 1, 0.5, -12 / 2]));
			m_context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, Vector.<Number>([1, 1, 1, 1 / 256]));
			m_context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, Vector.<Number>([1, 1 / 255, 1 / 65025, 1 / 16581375]));
			m_context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 3, Vector.<Number>([0.00001, 12, m_shadowAlpha,0]));
			
			m_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, m_finalMatrix, true);
			m_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 4, m_lightProj, true);
			
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
		private var m_modelDepthShader : Program3D;
		private var m_shaderPassShader : Program3D;
		private var m_shaderMap : Texture;
		private var m_shadowAlpha : Number = .7;
		
		//灯光部分
		private var m_lightModel : Matrix3D = new Matrix3D(); //灯光模型
		private var m_lightView : Matrix3D = new Matrix3D(); //灯光视图
		private var m_lightProj : Matrix3D = new Matrix3D();
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