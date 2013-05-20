package
{
	import com.adobe.utils.AGALMiniAssembler;
	import com.adobe.utils.PerspectiveMatrix3D;
	
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.Stage3D;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DClearMask;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DStencilAction;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Program3D;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	
	import C3.MirrorMesh;
	import C3.TeapotMesh;
	import C3.WallMesh;
	
	[SWF(width = "800", height = "600", frameRate="60")]
	public class StencilMirror extends Sprite
	{
		private var m_context : Context3D;
		private var m_shader : Program3D;
		
		private var m_lightShader : Program3D;
		private var m_light : Vector3D;
		
		private var m_projMatrix : PerspectiveMatrix3D = new PerspectiveMatrix3D()
		private var m_worldMatrix : Matrix3D = new Matrix3D();
		private var m_finalMatrix : Matrix3D = new Matrix3D();
		private var m_viewMatrix : Matrix3D = new Matrix3D();
		private var m_cameraMatrix : Matrix3D;
		
		private var m_wall : WallMesh;
		private var m_mirrorMesh : MirrorMesh;
		private var m_teapot : TeapotMesh;
		private var m_edgeTeapot : TeapotMesh;
		private var m_mirrorTeapot : TeapotMesh;
		private var m_shadowTeapot : TeapotMesh;
		
		private var m_key : Object = new Object();
		
		private static const CAM_FACING:Vector3D = new Vector3D(0, 0, -1);
		private static const CAM_UP:Vector3D = new Vector3D(0, -1, 0);
		
		public function StencilMirror()
		{
			stage ? init() : addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null) : void
		{
			stage.stage3Ds[0].addEventListener(Event.CONTEXT3D_CREATE, onCreateContext);
			stage.stage3Ds[0].requestContext3D();
			
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			
			var tip : TextField = new TextField();
			tip.textColor = 0xFFFFFFFF;
			tip.text = "控制键: W.S.A.D 方向键 PageUp PageDown";
			tip.width = 800;
			addChild(tip);
		}
		
		private function onKeyDown(e:KeyboardEvent) : void
		{
			m_key[e.keyCode] = true;
		}
		
		private function onKeyUp(e:KeyboardEvent) : void
		{
			delete m_key[e.keyCode];
		}
		
		private function onCreateContext(e:Event) : void
		{
			if(hasEventListener(Event.ENTER_FRAME))
				removeEventListener(Event.ENTER_FRAME, onEnter);
			
			m_context = (e.target as Stage3D).context3D;
			m_context.configureBackBuffer(stage.stageWidth,stage.stageHeight,2);
			m_context.enableErrorChecking = true;
			
			var vertex : AGALMiniAssembler = new AGALMiniAssembler();
			vertex.assemble(Context3DProgramType.VERTEX,
				[
					"m44 op va0, vc0",
					"mov v0, va0",
					"mov v1, va1",
				].join("\n"));
			
			var fragment : AGALMiniAssembler = new AGALMiniAssembler();
			fragment.assemble(Context3DProgramType.FRAGMENT,
				[
					"tex ft0, v1, fc0<2d,repeat,linear>",
					"mov oc, ft0",
				].join("\n"));
			
			m_shader = m_context.createProgram();
			m_shader.upload(vertex.agalcode, fragment.agalcode);
			
			var lightVertex : AGALMiniAssembler = new AGALMiniAssembler();
			lightVertex.assemble(Context3DProgramType.VERTEX,
				[
					"m33 vt0.xyz, va1.xyz, vc8",
					"nrm vt0.xyz, vt0.xyz",
					"mov v0, vt0.xyz",
					
					"mov vt0, vc12",
					"m33 vt0.xyz, vt0.xyz, vc4",
					"nrm vt1.xyz, vt0.xyz",
					"neg vt0.xyz, vt1.xyz",
					"mov v1, vt0.xyz",
					
					"m44 vt0, va1, vc4",
					"neg vt0, vt0",
					"nrm vt0.xyz, vt0.xyz",
					"sub vt0.xyz, vt0.xyz, vt1.xyz",
					"nrm vt2.xyz, vt0.xtz",
					"mov v2, vt2.xyz",
					
					"m44 op, va0, vc0",
					"mov v3, va2"
				].join("\n"));
			
			var lightFragment : AGALMiniAssembler = new AGALMiniAssembler();
			lightFragment.assemble(Context3DProgramType.FRAGMENT,
				[
					"nrm ft0.xyz, v0.xyz",
					"nrm ft1.xyz, v1.xyz",
					"nrm ft2.xyz, v2.xyz",
					
					"mov ft3, fc0",
					"mul ft3, ft3, fc1",
					"mul ft3, ft3, fc6",
					"mov ft4, fc2",
					"mul ft4, ft4, fc3",
					"mul ft4, ft4, fc6.yyyy",
					"mov ft5, fc4",
					"mul ft5, ft5, fc5",
					"mul ft5, ft5, fc6.zzzz",
					
					"dp3 ft6, ft0.xyz, ft1.xyz",
					"sat ft6, ft6",
					
					"dp3 ft7, ft0.xyz, ft2.xyz",
					"sat ft7, ft7",
					"pow ft7, ft7, fc6.wwww",
					
					"mul ft4, ft4, ft6",
					"mul ft5, ft5, ft7",
					"add ft3, ft3, ft4",
					"add ft3, ft3, ft5",
					"tex ft4, v3, fs0<2d,repeat,linear>",
					"add ft3, ft3, ft4",
					"mov oc, ft3"
				].join("\n"));
			
			m_lightShader = m_context.createProgram();
			m_lightShader.upload(lightVertex.agalcode, lightFragment.agalcode);
			
			m_projMatrix.identity();
			m_projMatrix.perspectiveFieldOfViewRH(45,stage.stageWidth / stage.stageHeight, 0.001, 1000.0);
			
			m_viewMatrix.identity();
			m_viewMatrix.appendTranslation(0,5,-15);
			
			m_wall = new WallMesh(m_context);
			m_wall.moveTo(0,0,0);
			
			m_mirrorMesh = new MirrorMesh(m_context);
			m_mirrorMesh.moveTo(0,0,0);
			
			m_shadowTeapot = new TeapotMesh(m_context);
			m_shadowTeapot.moveTo(0,0,0);
			
			m_teapot = new TeapotMesh(m_context);
			m_teapot.moveTo(0,2,-5);
			
			m_edgeTeapot = new TeapotMesh(m_context);
			m_edgeTeapot.moveTo(0,2,-5);
			m_edgeTeapot.scale(1.1,1.1,1.1);
			
			m_mirrorTeapot = new TeapotMesh(m_context);
			
			var reflect : Vector.<Number> = Utils.getReflectionMatrix(new Vector3D(0,0,-1), new Vector3D(0,0,0));
			var reflectMatrix : Matrix3D = new Matrix3D();
			reflectMatrix.copyRawDataFrom(reflect);
			
			var shadow : Vector.<Number> = Utils.getShadowMatrix(new Vector3D(0,-1,0), new Vector3D(0,-1,0), new Vector3D(0,5,0));
			var shadowMatrix : Matrix3D = new Matrix3D();
			shadowMatrix.copyRawDataFrom(shadow);
			
			var bmd : BitmapData = new BitmapData(16,16,true,0);
			bmd.fillRect(bmd.rect,0);
			
			m_mirrorTeapot.setReflectionMatrix(reflectMatrix);
			m_shadowTeapot.setShadowMatrix(shadowMatrix);
			m_shadowTeapot.setTexture(bmd);
			
			bmd.fillRect(bmd.rect,0xFFFFFFFF);
			m_edgeTeapot.setTexture(bmd);
			
			m_light = new Vector3D(0,0,-1);
			
			addEventListener(Event.ENTER_FRAME, onEnter);
		}
		
		private var t : Number = 0;
		private function onEnter(e:Event) : void
		{
			t += 1;
			m_context.clear();
			renderScene();
			renderKeyBoard();
			m_context.present();
		}
		
		private function renderScene() : void
		{
			//还原混合模式
			m_context.setBlendFactors(Context3DBlendFactor.ONE,Context3DBlendFactor.ZERO);
			//对于不参与的模板测试的三角形,统一都通过测试,但不改变模板值
			m_context.setStencilActions(Context3DTriangleFace.BACK,Context3DCompareMode.ALWAYS);
			//还原裁剪面
			m_context.setCulling(Context3DTriangleFace.FRONT);
			//还原深度测试
			m_context.setDepthTest(true,Context3DCompareMode.LESS);
			
			m_viewMatrix.pointAt(m_wall.position, CAM_FACING, CAM_UP);
			m_cameraMatrix = m_viewMatrix.clone();
			m_cameraMatrix.invert();
			
			//剔除
			m_context.setCulling(Context3DTriangleFace.BACK);
			m_context.setStencilActions(Context3DTriangleFace.FRONT,Context3DCompareMode.ALWAYS);
			
			m_edgeTeapot.render(m_cameraMatrix, m_projMatrix, m_shader);
			m_edgeTeapot.rotation(t, Vector3D.Y_AXIS);
			
			//还原
			m_context.setCulling(Context3DTriangleFace.FRONT);
			m_context.setStencilActions(Context3DTriangleFace.BACK,Context3DCompareMode.ALWAYS);
			
			m_teapot.render(m_cameraMatrix,m_projMatrix,m_lightShader,m_light);
			m_teapot.rotation(t, Vector3D.Y_AXIS);
			
			/**
			 * 绘制投影
			 */
			
			//关闭深度测试
			m_context.setDepthTest(false,Context3DCompareMode.LESS);
			
			//设置模板值为0,之后绘制的三角形会使模板值递增
			m_context.setStencilReferenceValue(0);
			m_context.setStencilActions(Context3DTriangleFace.BACK,
				Context3DCompareMode.EQUAL, Context3DStencilAction.INCREMENT_SATURATE);
			
			m_wall.render(m_cameraMatrix, m_projMatrix, m_shader);
			
			m_context.setStencilReferenceValue(1);
			
			//混合模式为 1 * dest + 0 * 0 = dest. 目标颜色为墙体颜色和飞船颜色的混合
			m_context.setBlendFactors(Context3DBlendFactor.SOURCE_COLOR, Context3DBlendFactor.DESTINATION_COLOR);
			m_context.setCulling(Context3DTriangleFace.FRONT);
			
			var shadow : Vector.<Number> = Utils.getShadowMatrix(new Vector3D(0,-1,0), new Vector3D(0,-1,0), new Vector3D(-m_shadowTeapot.position.x,5,0));
			var shadowMatrix : Matrix3D = new Matrix3D();
			shadowMatrix.copyRawDataFrom(shadow);
			m_shadowTeapot.setShadowMatrix(shadowMatrix);
			
			m_shadowTeapot.render(m_cameraMatrix,m_projMatrix,m_shader);
			m_shadowTeapot.moveTo(m_teapot.position.x,m_teapot.position.y,m_teapot.position.z);
			m_shadowTeapot.rotation(t, Vector3D.Y_AXIS);
			
			m_context.setCulling(Context3DTriangleFace.FRONT);
			/**
			 * 绘制反射
			 */
			
			//清空模板
			m_context.clear(0,0,0,1,1,0,Context3DClearMask.STENCIL);
			
			//设置模板值为0,之后绘制的三角形会使模板值递增
			m_context.setStencilReferenceValue(0);
			m_context.setStencilActions(Context3DTriangleFace.FRONT,
				Context3DCompareMode.EQUAL, Context3DStencilAction.INCREMENT_SATURATE);
			
			m_mirrorMesh.render(m_cameraMatrix,m_projMatrix,m_shader);
			
			//混合模式为 1 * dest + 0 * 0 = dest. 目标颜色为镜子颜色和飞船颜色的混合
			m_context.setBlendFactors(Context3DBlendFactor.DESTINATION_COLOR, Context3DBlendFactor.ZERO);
			m_context.setCulling(Context3DTriangleFace.BACK);
			m_context.setStencilReferenceValue(1);
			
			m_mirrorTeapot.render(m_cameraMatrix,m_projMatrix,m_shader);
			m_mirrorTeapot.moveTo(m_teapot.position.x,m_teapot.position.y,m_teapot.position.z);
			m_mirrorTeapot.rotation(t, Vector3D.Y_AXIS);
		}
		
		private function onMouseWheel(e:MouseEvent) : void
		{
			m_viewMatrix.appendTranslation(0,0,e.delta);
		}
		
		private function renderKeyBoard() : void
		{
			var speed : Number = .1;
			
			if(m_key[Keyboard.PAGE_UP])
				m_viewMatrix.appendTranslation(0,speed,0);
			
			if(m_key[Keyboard.PAGE_DOWN])
				m_viewMatrix.appendTranslation(0,-speed,0);
			
			if(m_key[Keyboard.UP])
				m_viewMatrix.appendTranslation(0,0,speed);
			
			if(m_key[Keyboard.DOWN])
				m_viewMatrix.appendTranslation(0,0,-speed);
			
			if(m_key[Keyboard.LEFT])
				m_viewMatrix.appendTranslation(speed,0,0);
			
			if(m_key[Keyboard.RIGHT])
				m_viewMatrix.appendTranslation(-speed,0,0);
			
			if(m_key[Keyboard.W]){
				if(m_teapot.position.z < -1){
					m_teapot.move(0,0,speed);
					m_edgeTeapot.move(0,0,speed);
				}
			}
				
			if(m_key[Keyboard.S]){
				m_teapot.move(0,0,-speed);
				m_edgeTeapot.move(0,0,-speed);
			}
				
			if(m_key[Keyboard.A]){
				m_teapot.move(speed,0,0);
				m_edgeTeapot.move(speed,0,0);
			}
				
			
			if(m_key[Keyboard.D]){
				m_teapot.move(-speed,0,0);
				m_edgeTeapot.move(-speed,0,0);
			}	
		}
	}
}