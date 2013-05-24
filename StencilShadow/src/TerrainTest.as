package 
{
	import C3.TeapotMesh;
	import C3.Terrain.Terrain;
	
	import com.adobe.utils.AGALMiniAssembler;
	import com.adobe.utils.PerspectiveMatrix3D;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shader;
	import flash.display.ShaderJob;
	import flash.display.Sprite;
	import flash.display.Stage3D;
	import flash.display.StageDisplayState;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Program3D;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.ShaderEvent;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.getTimer;

	[SWF(width = "640", height = "480", frameRate="60")]
	public class TerrainTest extends Sprite
	{
		public function TerrainTest()
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
			
			var tf : TextField = new TextField();
			tf.text = "方向键平行移动相机\nPage Up & Page Down 抬升降低相机";
			tf.textColor = 0xffffff;
			tf.width = 640;
			addChild(tf);
		}
		
		
		private function onKeyDown(e:KeyboardEvent) : void
		{
			m_key[e.keyCode] = true;
		}
		
		private function onKeyUp(e:KeyboardEvent) : void
		{
			delete m_key[e.keyCode];
		}
		
		private function onCreateContext(e:Event):void
		{
			if(hasEventListener(Event.ENTER_FRAME))
				removeEventListener(Event.ENTER_FRAME, onEnter);
			
			m_context = (e.target as Stage3D).context3D;
			m_context.configureBackBuffer(stage.stageWidth,stage.stageHeight,2);
			m_context.enableErrorChecking = true;
			
			m_projMatrix.identity();
			m_projMatrix.perspectiveFieldOfViewRH(45,stage.stageWidth / stage.stageHeight, 1, 5000.0);
			
			m_viewMatrix.identity();
			m_viewMatrix.appendTranslation(0,5,-80);
			
			setup();
			
			addEventListener(Event.ENTER_FRAME, onEnter);
		}
		
		private var t : Number = 0;
		private function onEnter(e:Event) : void
		{
			t += .1;
			m_context.clear();
			renderWave();
			renderScene();
			renderKeyBoard();
			m_context.present();
		}
		
		private function renderWave() : void
		{
			var timer : int = getTimer();
			point0.y = timer / 400;
			point1.y = timer / 640;
			
			waveBmp.perlinNoise( 3, 3, 2, 0, false, true, 7, true, [point0, point1] );
			job = new ShaderJob(shader, bytes, terrainSize, terrainSize);
			job.addEventListener(ShaderEvent.COMPLETE, shaderCompleteEvent, false, 0, true);
			job.start();
		}
		
		private function shaderCompleteEvent(e:ShaderEvent) : void
		{
			if(m_terrainMesh){
				m_terrainMesh.updateFromByteArray(bytes,0,0,terrainSize * terrainSize);
			}
		}
		
		private function renderScene() : void
		{
			
			m_viewMatrix.pointAt(m_terrainMesh.position, CAM_FACING, CAM_UP);
			m_cameraMatrix = m_viewMatrix.clone();
			m_cameraMatrix.invert();
			
//			m_terrainMesh.rotation(t,Vector3D.Y_AXIS);
			m_terrainMesh.render(m_cameraMatrix,m_projMatrix,m_shader);
			m_mirrorMesh.render(m_cameraMatrix,m_projMatrix,m_shaderNoUV);
			
			var t:Number = getTimer();
			m_mirrorMesh.setRotation( 0, 0, 0 );
			m_mirrorMesh.rotation(Math.cos( t / 400 ) * 6, Vector3D.X_AXIS);
			m_mirrorMesh.rotation( Math.cos( t / 300 ) * 6 + 90, Vector3D.Z_AXIS);
			
			var color:uint = waveBmp.getPixel( terrainSize * 0.5, terrainSize * 0.5 ) & 0xff;
			var height:Number =  color / 255 * 15 - 10;
			m_mirrorMesh.moveTo(0,height,0);
		}
		
		private function setup() : void
		{
			var vertex : AGALMiniAssembler = new AGALMiniAssembler();
			vertex.assemble(Context3DProgramType.VERTEX,
				[
					"m44 op va0, vc0",
					"mov v1, va1",
					"mov v2, va2",
				].join("\n"));
			
			var fragment : AGALMiniAssembler = new AGALMiniAssembler();
			fragment.assemble(Context3DProgramType.FRAGMENT,
				[
					"tex ft0, v1, fc0<2d,repeat,linear>",
					"mul ft0, ft0, v2",
					"mov oc, ft0",
				].join("\n"));
			
			var vertexShader : AGALMiniAssembler = new AGALMiniAssembler();
			vertexShader.assemble(Context3DProgramType.VERTEX,
				[
					"m44 op, va0, vc0",
					"mov v1, va1",
				].join("\n"));
			
			var fragmentShader : AGALMiniAssembler = new AGALMiniAssembler();
			fragmentShader.assemble(Context3DProgramType.FRAGMENT,
				[
					"tex ft0, v1, fc0<2d,repeat,linear>",
					"mov oc, ft0",
				].join("\n"));
			
			m_shader = m_context.createProgram();
			m_shader.upload(vertex.agalcode, fragment.agalcode);
			
			m_shaderNoUV = m_context.createProgram();
			m_shaderNoUV.upload(vertexShader.agalcode, fragmentShader.agalcode);
			
			m_terrainMesh = new Terrain(m_context,64,64,10,1,new terrainData);
			m_terrainMesh.genTexture(new Vector3D(0,1,0));
//			m_terrainMesh.setTexture(Bitmap(new textureData).bitmapData);
			m_terrainMesh.moveTo(0,-10,0);
			
			m_mirrorMesh = new TeapotMesh(m_context);
			m_mirrorMesh.rotation(90,Vector3D.Z_AXIS);
			m_mirrorMesh.moveTo(0,30,0);
			m_mirrorMesh.scale(10,10,10);
			
			//创建波浪shader
			bytes = new ByteArray();
			bytes.endian = Endian.LITTLE_ENDIAN;
			bytes.length = terrainSize * terrainSize * 16;
			
			shader = new Shader( new waveData );
			shader.data.src.input = waveBmp;
		}
		
		private function onMouseWheel(e:MouseEvent) : void
		{
			m_viewMatrix.appendTranslation(0,0,e.delta);
		}
		
		private function renderKeyBoard() : void
		{
			var speed : Number = 1;
			var height : Number = 0;
			
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
//				height = m_terrainMesh.getHeight(m_mirrorMesh.position.x,m_mirrorMesh.position.z);
//				height += m_terrainMesh.position.y + 5;
//				m_mirrorMesh.move(0,0,speed);
//				m_mirrorMesh.moveTo(m_mirrorMesh.pos.x,height,m_mirrorMesh.pos.z);
			}
			
			if(m_key[Keyboard.S]){
//				height = m_terrainMesh.getHeight(m_mirrorMesh.position.x,m_mirrorMesh.position.z);
//				height += m_terrainMesh.position.y + 5;
//				m_mirrorMesh.move(0,0,-speed);
//				m_mirrorMesh.moveTo(m_mirrorMesh.pos.x,height,m_mirrorMesh.pos.z);
			}
			
			if(m_key[Keyboard.A]){
//				height = m_terrainMesh.getHeight(m_mirrorMesh.position.x,m_mirrorMesh.position.z);
//				height += m_terrainMesh.position.y + 5;
//				m_mirrorMesh.move(speed,0,0);
//				m_mirrorMesh.moveTo(m_mirrorMesh.pos.x,height,m_mirrorMesh.pos.z);
			}
				
			
			if(m_key[Keyboard.D]){
//				height = m_terrainMesh.getHeight(m_mirrorMesh.position.x,m_mirrorMesh.position.z);
//				height += m_terrainMesh.position.y + 5;
//				m_mirrorMesh.move(-speed,0,0);
//				m_mirrorMesh.moveTo(m_mirrorMesh.pos.x,height,m_mirrorMesh.pos.z);
			}
		}
		
		private static const CAM_FACING:Vector3D = new Vector3D(0, 0, -1);
		private static const CAM_UP:Vector3D = new Vector3D(0, -1, 0);
		
		private var m_key : Object = new Object();
		
		private var m_terrainMesh : Terrain;
		private var m_mirrorMesh : TeapotMesh;
		
		private var terrainSize : uint = 64;
		private var job : ShaderJob;
		private var shader : Shader;
		private var bytes:ByteArray;
		
		private var point0 : Point = new Point();
		private var point1 : Point = new Point();
		private var waveBmp : BitmapData = new BitmapData(terrainSize,terrainSize,false);
		private var waveBm : Bitmap = new Bitmap();
		
		private var m_shader : Program3D;
		private var m_shaderNoUV : Program3D;
		private var m_context : Context3D;
		private var m_projMatrix : PerspectiveMatrix3D = new PerspectiveMatrix3D()
		private var m_worldMatrix : Matrix3D = new Matrix3D();
		private var m_finalMatrix : Matrix3D = new Matrix3D();
		private var m_viewMatrix : Matrix3D = new Matrix3D();
		private var m_cameraMatrix : Matrix3D;
		
		[Embed(source="../source/coastMountain64.raw",mimeType = "application/octet-stream")] 
		private var terrainData : Class;
		
		[Embed(source="../source/grass.jpg")]
		private var textureData : Class;
		
		[Embed(source="../source/water.pbj",mimeType = "application/octet-stream")] 
		private var waveData : Class;
	}
}