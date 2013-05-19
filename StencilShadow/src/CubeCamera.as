package 
{
	import C3.Camera.Camera;
	import C3.CubeMesh;
	import C3.Ray.Ray;
	import C3.TeapotMesh;
	
	import com.adobe.utils.AGALMiniAssembler;
	import com.adobe.utils.PerspectiveMatrix3D;
	import com.greensock.TweenLite;
	
	import flash.display.Sprite;
	import flash.display.Stage3D;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Program3D;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.text.TextField;
	import flash.ui.Keyboard;

	[SWF(width="640",height="480",frameRate="60")]
	public class CubeCamera extends Sprite
	{
		public function CubeCamera()
		{
			stage ? init() : addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private var tip : TextField;
		
		private function init(e:Event = null) : void
		{
			stage.stage3Ds[0].addEventListener(Event.CONTEXT3D_CREATE, onContextCreate);
			stage.stage3Ds[0].requestContext3D();
			
			tip = new TextField();
			tip.textColor = 0xffffff;
			tip.width = 300;
			tip.text = "W,S,A,D,N,M,方向键控制相机\n试试用鼠标点击方块";
			tip.selectable = false;
			addChild(tip);
		}
		
		private function onContextCreate(e:Event) : void
		{
			if(hasEventListener(Event.ENTER_FRAME))
				removeEventListener(Event.ENTER_FRAME, onEnter);
			
			m_context = (e.target as Stage3D).context3D;
			
			m_context.configureBackBuffer(stage.stageWidth,stage.stageHeight,2,true);
			m_context.enableErrorChecking = true;
			
			setup();
			
			addEventListener(Event.ENTER_FRAME, onEnter);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			stage.addEventListener(MouseEvent.CLICK, onClick);
		}
		
		private function onClick(e:MouseEvent) : void
		{
			//将鼠标点击位置偏移视口中央
			var sceenX : Number = stage.mouseX;
			var sceenY : Number = stage.mouseY;
			
			var viewX : Number = (sceenX * 2  / stage.stageWidth) - 1;
			var viewY : Number = (-sceenY * 2 / stage.stageHeight) + 1;
			
			var ray : Ray = new Ray();

			//将射线转换到相机所在空间
			var viewMat : Matrix3D = m_camera.getViewMatrix().clone();
			ray.origin = viewMat.transformVector(new Vector3D(0,0,0));
			
			//将相机反转,相机的平移和旋转总是和世界坐标系相反的
			viewMat.invert();
			ray.direction =  viewMat.deltaTransformVector(new Vector3D(viewX,viewY,1));
			ray.direction.normalize();
			
			//取出相机的缩放值
			var scale : Vector3D = m_proj.decompose()[2];
			var walk : Vector3D = m_camera.getViewMatrix().decompose()[0];
			walk.z += 10;
			
			walk.x *= scale.x * scale.x;
			walk.y *= scale.y * scale.y;
			walk.z *= scale.z * scale.z;
			
			
			//将射线转到目标所在空间
			var cubeMesh : CubeMesh;
			for each(cubeMesh in m_cubeList)
			{

				//相交检测
				var cubePos : Vector3D = cubeMesh.transform.position;
				cubePos = cubePos.add(walk);
				
				cubePos.x *= scale.x;
				cubePos.y *= scale.y;
				cubePos.z *= scale.z;


				if(Ray.RaySphereIntersect(ray.origin, ray.direction, cubePos, 2))
					TweenLite.to(cubeMesh,1,{rotateY : 1080});
				else
					TweenLite.to(cubeMesh,1,{rotateY : 0});
			}
		}
		
		private function onKeyUp(e:KeyboardEvent) : void
		{
			delete m_key[e.keyCode];
		}
		
		private function onKeyDown(e:KeyboardEvent) : void
		{
			m_key[e.keyCode] = true;
		}
		
		private function setup() : void
		{
			var count : uint = 30;
			
			for(var i : int = 0; i < count ; i++)
			{
				var cubeMesh : CubeMesh = new CubeMesh(m_context);
				cubeMesh.moveTo(Math.random() * -count, Math.random() * -count, Math.random() * -count);
				m_cubeList.push(cubeMesh);
			}
			
			m_cubeList[0].moveTo(Math.random() * 5, Math.random() * 5,0);
			
			m_teapotMesh = new TeapotMesh(m_context);
			m_teapotMesh.moveTo(0,0,0);
			m_teapotMesh.rotation(-90,Vector3D.Z_AXIS);
			
			m_shader = m_context.createProgram();
			var vertexShader : AGALMiniAssembler = new AGALMiniAssembler();
			vertexShader.assemble(Context3DProgramType.VERTEX,
				[
					"m44 op, va0, vc0",
					"mov v0, va0",
					"mov v1, va1",
					].join("\n"));
			
			var fragmentShader : AGALMiniAssembler = new AGALMiniAssembler();
			fragmentShader.assemble(Context3DProgramType.FRAGMENT,
				[
					"tex ft0, v1, fc0<2d,wrap,linear>",
					"mov oc, ft0",
					].join("\n"));
			
			m_shader.upload(vertexShader.agalcode, fragmentShader.agalcode);
			
			m_shaderNoTexture = m_context.createProgram();
			vertexShader = new AGALMiniAssembler();
			vertexShader.assemble(Context3DProgramType.VERTEX,
				[
					"m44 op, va0, vc0",
					"mov v0, va0",
				].join("\n"));
			
			fragmentShader = new AGALMiniAssembler();
			fragmentShader.assemble(Context3DProgramType.FRAGMENT,
				[
					"mov oc, v0",
				].join("\n"));
			
			m_shaderNoTexture.upload(vertexShader.agalcode, fragmentShader.agalcode);
			
			m_proj.identity();
			m_proj.perspectiveFieldOfViewRH(45,stage.stageWidth / stage.stageHeight, 0.001, 1000);
			
			m_viewMatrix.appendTranslation(0,0,10);
			
			m_camera = new Camera();
			m_camera.setCameraType(Camera.AIRCRAFT);
		}
		
		private function onEnter(e:Event) : void
		{
			m_context.clear();
			renderScene();
			renderKeyBoard();
			m_context.present();
		}
		
		private var n : Number = 0;
		private function renderScene() : void
		{
			n += .01;
			
			//相机上下浮动
//			m_viewMatrix.appendTranslation(0,Math.sin(y) / 10,0);
//			m_viewMatrix.pointAt(m_teapotMesh.position, CAM_FACING, CAM_UP);
			//矩形做自转运动
//			m_cubeList[0].rotation(n * 33.3,Vector3D.Y_AXIS);
			
			for each(var cubeMesh : CubeMesh in m_cubeList)
			{
				cubeMesh.render(m_camera.getViewMatrix(),m_proj,m_shaderNoTexture);
			}
			
			m_teapotMesh.render(m_camera.getViewMatrix(),m_proj,m_shader);
		}
		
		private function renderKeyBoard() : void
		{
			var speed : Number = .005;
			
			if(m_key[Keyboard.LEFT])
				m_camera.strafe(-speed * 33.3);
			
//			if(m_key[Keyboard.UP])
//				m_camera.walk(speed * 33.3);
			
			if(m_key[Keyboard.RIGHT])
				m_camera.strafe(speed * 33.3);
			
//			if(m_key[Keyboard.DOWN])
//				m_camera.walk(-speed * 33.3);
			
			if(m_key[Keyboard.A])
				m_camera.yaw(-speed * 33.3);
			
			if(m_key[Keyboard.D])
				m_camera.yaw(speed * 33.3);
			
			if(m_key[Keyboard.W])
				m_camera.pitch(speed * 33.3);
			
			if(m_key[Keyboard.S])
				m_camera.pitch(-speed * 33.3);
			
//			if(m_key[Keyboard.N])
//				m_camera.roll(-speed * 33.3);
//			
//			if(m_key[Keyboard.M])
//				m_camera.roll(speed * 33.3);
		}
		
		private static const CAM_FACING:Vector3D = new Vector3D(0, 0, -1);
		private static const CAM_UP:Vector3D = new Vector3D(0, -1, 0);
		
		private var m_teapotMesh : TeapotMesh;
		private var m_cubeList : Vector.<CubeMesh> = new Vector.<CubeMesh>();
		private var m_context : Context3D;
		private var m_shader : Program3D;
		private var m_shaderNoTexture : Program3D;
		private var m_key : Object = new Object();
		
		private var m_proj : PerspectiveMatrix3D = new PerspectiveMatrix3D();
		private var m_viewMatrix : Matrix3D = new Matrix3D();
		private var m_camera : Camera;
	}
}