package
{
	import C3.Light.SimpleLight;
	import C3.MD5.MD5Result;
	import C3.Material.DefaultMaterialManager;
	
	import com.adobe.utils.AGALMiniAssembler;
	import com.adobe.utils.PerspectiveMatrix3D;
	
	import flash.display3D.Context3DClearMask;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.Texture;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	import flash.utils.ByteArray;

	/**
	 * 这次肯定能写出来了
	 */
	[SWF(width = "800", height = "800", frameRate="60")]
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
			m_floorQuad = createQuad("floor");
			m_wallQuad = createQuad("wall");
			m_defaultTexture = DefaultMaterialManager.getDefaultTexture(m_context);
			addEventListener(Event.ENTER_FRAME, onEnter);
			
			m_light.pos = new Vector3D(10,25,0);	
			
			var tf : TextField = new TextField();
			tf.selectable = false;
			tf.textColor = 0xFFFFFF;
			tf.htmlText = "<a href='http://www.dreamfairy.cn'><u>2007-2013 苍白的茧 | 追逐繁星的苍之茧</u></a>\r方向键控制相机";
			tf.width = tf.textWidth + 10;
			tf.height = tf.textHeight + 10;
			tf.x = stage.stageWidth - tf.width;
			addChild(tf);
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
			
			m_modelPos = new Vector3D(0,-6,-20);
			
			//使用透视投影来模拟点光
			m_lightProj.perspectiveFieldOfViewRH(45,stage.stageWidth/stage.stageHeight,m_zNear,m_zFar);
			
			//使用正交投影来模拟平行光
//			m_lightProj.orthoRH(stage.stageWidth,stage.stageHeight,m_zNear,m_zFar);
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
//				"tex ft1 v0 fs1<2d, linear, repeat\n"+
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
				"mov ft0.xyzw, v0.zzzz\n"+
//				"mov ft0.w fc0.y\n"+
				"div ft0.xyzw, ft0.xyzw, fc0.x\n"+
				"mov oc ft0\n");
			
			m_shaderPassShader = m_context.createProgram();
			m_shaderPassShader.upload(depthPassVertexShader.agalcode,depthPassFragmengShader.agalcode);
			
			//模型深度图采样shader
			var modelVertexShader : AGALMiniAssembler = new AGALMiniAssembler();
			modelVertexShader.assemble(Context3DProgramType.VERTEX,
				//投影到场景相机 modelViewProj
				"m44 vt0 va0 vc0\n"+
				//投影到 modelToWorld
				"m44 vt2 va0 vc20\n"+
				//投影到 lightViewToProj
				"m44 vt3 vt2 vc12\n"+
				
				"mov v2 vt3\n"+
				//uv
				"mov v3 va2\n"+
				//worldPos
				"mov op vt0\n");
			
			var modelFragmentShader : AGALMiniAssembler = new AGALMiniAssembler();
			modelFragmentShader.assemble(Context3DProgramType.FRAGMENT,
				//纹理采样
				"tex ft1 v3 fs1<2d,wrap,nearst>\n"+
				
				//将坐标转换到其次坐标
				"div ft2.xy v2.xy v2.ww\n"+
				
				//将坐标转换到纹理UV fc2.y = 0.5
				// 0.5 * xy + 0.5;
				
				"mul ft2.xy ft2.xy fc2.y\n"+
				"add ft2.xy ft2.xy fc2.y\n"+
				
				"neg ft2.y ft2.y\n"+
				
				//阴影图深度采样
				"tex ft3 ft2.xy fs0<2d,wrap,nearst>\n"+
//				"sub ft3 ft3 ft0\n"+
				//距离和深度值进行比较
//				"sub ft5.x v2.x fc0.x\n"+
//				"sub ft5.y v2.y fc0.y\n"+
//				"sub ft5.z v2.z fc0.z\n"+
//				"mul ft5.x ft5.x ft5.x\n"+
//				"mul ft5.y ft5.y ft5.y\n"+
//				"mul ft5.z ft5.z ft5.z\n"+
//				"add ft5.w ft5.x ft5.y\n"+
//				"add ft5.w ft5.w ft5.z\n"+
//				"sqt ft5.w ft5.w\n"+
//				"mul ft5.w ft5.w fc2.w\n"+
//				"div ft5.w ft5.w fc2.x\n"+
				
				"mul ft5.z ft3.z fc2.x\n"+
				"mul ft5.z ft5.z fc2.w\n"+
				"sge ft5.w ft5.z v2.z\n"+
				"add ft5.w ft5.w fc2.y\n" +
				"mul ft1 ft1 ft5.w\n"+
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
			renderKeyBoard();
			//渲染到纹理
			m_context.clear();
			m_context.setRenderToTexture(m_shaderMap,true,2,0);
			renderShadowMap();
			renderModel();
//			renderQuadShow();
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
		
		private var m_orthoDepth : int = 0;
		private function renderShadowMap() : void
		{
			//近的时候为0， 远的时候为1
			m_context.clear();

			//使用正交投影模拟阳光渲染模型
			
			m_lightModel.identity();
			m_lightModel.appendRotation(-90,Vector3D.X_AXIS);
			m_lightModel.appendRotation(t, Vector3D.Y_AXIS);
			m_lightModel.appendScale(.1,.1,.1);
			m_lightModel.appendTranslation(m_modelPos.x,m_modelPos.y,m_modelPos.z);
//			m_lightModel.appendTranslation(stage.stageWidth/2,stage.stageHeight/2 - 200,200);
			
			m_lightModelWorld.identity();
			m_lightModelWorld.append(m_lightModel);
			m_lightModelWorld.append(m_worldMatrix);
			
			m_lightView.identity();
			m_lightView.appendTranslation(m_light.pos.x,m_light.pos.y,-m_light.pos.z);
			m_lightView.pointAt(m_lightModel.position,CAM_FACING,CAM_UP);
			m_lightView.invert();
			
			m_lightViewProj.identity();
			m_lightViewProj.append(m_lightView);
			m_lightViewProj.append(m_lightProj);
			
			m_lightModelFinal.identity();
			m_lightModelFinal.append(m_lightModelWorld);
			m_lightModelFinal.append(m_lightViewProj);
			
			//vc0 灯光投影矩阵
			m_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, m_lightModelFinal, true);
			m_context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, Vector.<Number>([m_zFar,1,1,1]));
			
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
			
			//绘制floor
			renderDepthQuad(m_floorQuad,m_modelPos,-90);
			//绘制wall
			renderDepthQuad(m_wallQuad,new Vector3D(0,0,-30),0);
			
			//输出到纹理
			m_context.present();
		}
		
		private function renderDepthQuad(target : QuadInfo, pos : Vector3D, xDegree : Number) : void
		{
			m_lightModel.identity();
			m_lightModel.appendRotation(xDegree,Vector3D.X_AXIS);
			m_lightModel.appendScale(10,10,10);
			m_lightModel.appendTranslation(pos.x,pos.y,pos.z);
			
			m_lightModelWorld.identity();
			m_lightModelWorld.append(m_lightModel);
			m_lightModelWorld.append(m_worldMatrix);
			
			m_lightView.identity();
			m_lightView.appendTranslation(m_light.pos.x,m_light.pos.y,-m_light.pos.z);
			m_lightView.pointAt(m_lightModel.position,CAM_FACING,CAM_UP);
			m_lightView.invert();
			
			m_lightModelFinal.identity();
			m_lightModelFinal.append(m_lightModelWorld);
			m_lightModelFinal.append(m_lightViewProj);
			
			m_context.setProgram(m_shaderPassShader);
			m_context.setVertexBufferAt(0,m_floorQuad.vertexBuffer,0,"float3");
			m_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, m_lightModelFinal, true);
			m_context.drawTriangles(target.indexBuffer);
		}
		
		private function renderModel() : void
		{
			m_context.clear();

			m_context.setProgram(m_modelDepthShader);
			
			m_modelMatrix.identity();	
			m_modelMatrix.appendRotation(-90,Vector3D.X_AXIS);
			m_modelMatrix.appendRotation(t, Vector3D.Y_AXIS);
			m_modelMatrix.appendScale(.1,.1,.1);
			m_modelMatrix.appendTranslation(m_modelPos.x,m_modelPos.y,m_modelPos.z);
			
			m_viewMatrix.identity();
			m_viewMatrix.appendTranslation(m_viewPos.x,m_viewPos.y,m_viewPos.z);
			m_viewMatrix.pointAt(new Vector3D(0,0,-20),CAM_FACING,CAM_UP);
//			m_viewMatrix.invert();
			
			m_sceneViewProj.identity();
			m_sceneViewProj.append(m_viewMatrix);
			m_sceneViewProj.append(m_projMatrix);
			
			m_modelToWorld.identity();
			m_modelToWorld.append(m_modelMatrix);
			m_modelToWorld.append(m_worldMatrix);
			
			m_finalMatrix.identity();
			m_finalMatrix.append(m_modelToWorld);
			m_finalMatrix.append(m_sceneViewProj);
			
			//fs0 阴影查询图
			m_context.setTextureAt(0, m_shaderMap);
			m_context.setTextureAt(1, m_diffusetexture);
//			m_context.setTextureAt(2, m_normalTexture);
			
			m_context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, Vector.<Number>([m_light.pos.x,m_light.pos.y,m_light.pos.z,1]));
			//传入光照角度
			var lightNorm : Vector3D = m_light.normalize;
			m_context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, Vector.<Number>([lightNorm.x,lightNorm.y,lightNorm.z,m_shadowAlpha]));
			
			m_context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, Vector.<Number>([m_zFar,0.5,1,m_shadowEpsilon]));
			//传入光照颜色
			m_context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 3, m_light.getNegAmbient());
			m_context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 4, m_light.getAmbient());
			
			//vc0 cameraModelViewProj
			m_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, m_finalMatrix, true);
			//vc4 lightModelViewProj
			m_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 4, m_lightModelFinal, true);
			//vc8 cameraViewProj
			m_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 8, m_sceneViewProj, true);
			//vc12 lightViewProj
			m_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 12, m_lightViewProj, true);
			//vc16 world
			m_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 16, m_worldMatrix, true);
			//vc20 modelWorld
			m_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 20, m_modelToWorld, true);
			//vc24 emptyMatrix
			m_emptyMatrix.identity();
			m_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 24, m_emptyMatrix, true);
			
			for(var i : int = 0; i < md5Result.meshDataNum; i++){
				var vertexBuffer : VertexBuffer3D = md5Result.vertexBufferList[i];
				var uvBuffer : VertexBuffer3D = md5Result.uvBufferList[i];
				var indexBuffer : IndexBuffer3D = md5Result.indexBufferList[i];
				
				m_context.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
				m_context.setVertexBufferAt(2,uvBuffer,0,Context3DVertexBufferFormat.FLOAT_2);
				m_context.drawTriangles(indexBuffer);
			}
			
			//绘制quadFloor
			renderQuad(m_floorQuad,m_modelPos, -90);
			//绘制quadWall
			renderQuad(m_wallQuad,new Vector3D(0,0,-30),0);
			
			m_context.setTextureAt(0, null);
			m_context.setTextureAt(1, null);
			m_context.setTextureAt(2, null);
			m_context.setVertexBufferAt(0, null);
			m_context.setVertexBufferAt(1, null);
			m_context.setVertexBufferAt(2, null);
			m_context.setVertexBufferAt(3, null);
		}
		
		private function renderQuad(target: QuadInfo, pos : Vector3D, xDegree : Number) : void
		{
			//绘制floor
			target.transform.identity();
			target.transform.appendRotation(xDegree,Vector3D.X_AXIS);
			target.transform.appendScale(10,10,10);
			target.transform.appendTranslation(pos.x,pos.y,pos.z);
			
			m_viewMatrix.identity();
			m_viewMatrix.appendTranslation(m_viewPos.x,m_viewPos.y,m_viewPos.z);
			m_viewMatrix.pointAt(new Vector3D(0,0,-20),CAM_FACING,CAM_UP);
//			m_viewMatrix.invert();
			
			m_sceneViewProj.identity();
			m_sceneViewProj.append(m_viewMatrix);
			m_sceneViewProj.append(m_projMatrix);
			
			m_modelToWorld.identity();
			m_modelToWorld.append(target.transform);
			m_modelToWorld.append(m_worldMatrix);
			
			m_finalMatrix.identity();
			m_finalMatrix.append(m_modelToWorld);
			m_finalMatrix.append(m_sceneViewProj);
			
			m_context.setProgram(m_modelDepthShader);
			m_context.setTextureAt(0, m_shaderMap);
			m_context.setTextureAt(1, m_defaultTexture);
			
			
			//vc0 cameraModelViewProj
			m_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, m_finalMatrix, true);
			//vc20 modelWorld
			m_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 20, m_modelToWorld, true);
			//vc24 emptyMatrix
			m_emptyMatrix.identity();
			m_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 24, m_emptyMatrix, true);
			
			m_context.setVertexBufferAt(0,target.vertexBuffer,0,"float3");
			m_context.setVertexBufferAt(2,target.uvBuffer,0,"float2");
			m_context.drawTriangles(target.indexBuffer);
		}
		
		protected override function renderKeyBoard():void
		{
			if(m_key[Keyboard.UP])
				m_viewPos.z -=.1;
			
			if(m_key[Keyboard.DOWN])
				m_viewPos.z +=.1;
			
			if(m_key[Keyboard.LEFT])
				m_viewPos.x -=.1;
			
			if(m_key[Keyboard.RIGHT])
				m_viewPos.x +=.1;
			
//			if(m_key[Keyboard.A])
//				m_shadowEpsilon+=0.01;
//			
//			if(m_key[Keyboard.D])
//				m_shadowEpsilon-=0.01;
			
//			trace(m_shadowEpsilon);
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
		private var m_floorQuad : QuadInfo;
		private var m_wallQuad : QuadInfo;
		private var m_depthShader : Program3D;
		private var m_defaultTexture : Texture;
		
		private var m_lightModelFinal : Matrix3D = new Matrix3D();
		private var m_lightModelWorld : Matrix3D = new Matrix3D();
		private var m_lightFloorFinal : Matrix3D = new Matrix3D();
		
		private var m_viewPos : Vector3D = new Vector3D();
		private var m_modelPos : Vector3D = new Vector3D();
		
		//场景
		private var m_sceneViewProj : Matrix3D = new Matrix3D();
		private var m_modelToWorld : Matrix3D = new Matrix3D();
		private var m_emptyMatrix : Matrix3D = new Matrix3D();
		
		//阴影图部分
		private var m_shadowEpsilon : Number = 1.09;
		private var m_shadowMapSize : int = 1024;
		private var m_shadowMapDx : Number = 1.0 / m_shadowMapSize;
		private var m_modelDepthShader : Program3D;
		private var m_shaderPassShader : Program3D;
		private var m_shaderMap : Texture;
		private var m_shadowAlpha : Number = .7;
		
		//灯光部分
		private var m_lightModel : Matrix3D = new Matrix3D(); //灯光模型
		private var m_lightView : Matrix3D = new Matrix3D(); //灯光视图
		private var m_lightProj : PerspectiveMatrix3D = new PerspectiveMatrix3D();
		private var m_lightViewProj : Matrix3D = new Matrix3D(); //视图投影矩阵
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