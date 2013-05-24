package
{
	import com.adobe.utils.AGALMiniAssembler;
	import com.adobe.utils.PerspectiveMatrix3D;
	
	import flash.display.Sprite;
	import flash.display.Stage3D;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.Texture;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	import C3.CubeMesh;

	[SWF(width = "800", height = "800", frameRate="60")]
	public class PostProcessing extends Sprite
	{
		private var m_key : Object = new Object();
		private var m_context : Context3D;
		private var m_projMatrix = new PerspectiveMatrix3D;
		private var m_viewMatrix : Matrix3D = new Matrix3D();
		private var m_modelMatrix : Matrix3D = new Matrix3D();
		private var m_finalMatrix : Matrix3D = new Matrix3D();
		
		[Embed(source="../source/seber.jpg")]
		private var m_cubeBitmap : Class;
		private var m_cubeTexture : Texture;
		
		private var m_sceneTexture : Texture;
		private var m_cube : CubeMesh;
		
		private var m_normalShader : Program3D;
		private var m_noTextureShader : Program3D;
		private var m_redShader : Program3D;
		
		private var m_sceneVertexRawData : Vector.<Number>;
		private var m_sceneIndexRawData : Vector.<uint>;
		
		private var m_sceneVertexBuffer : VertexBuffer3D;
		private var m_sceneIndexBuffer : IndexBuffer3D;
		
		public function PostProcessing()
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
		}
		
		private function onKeyDown(e:KeyboardEvent) : void
		{
			m_key[e.keyCode] = true;
		}
		
		private function onKeyUp(e:KeyboardEvent) : void
		{
			delete m_key[e.keyCode];
		}
		
		
		protected function onMouseWheel(e:MouseEvent) : void
		{
			//			m_viewMatrix.appendTranslation(0,0,e.delta);
		}
		
		protected function onCreateContext(e:Event) : void
		{
			m_context = (e.target as Stage3D).context3D;
			m_context.configureBackBuffer(stage.stageWidth, stage.stageHeight, 2, true);
			m_context.enableErrorChecking = true;
			
			m_projMatrix.perspectiveFieldOfViewRH(45, stage.stageWidth / stage.stageHeight, 0.001, 1000.0);
			
			setup();
			stage.addEventListener(Event.ENTER_FRAME, onEnter);
		}
		
		private function setup() : void
		{
			m_sceneVertexRawData = Vector.<Number>([
				-1, 1, 1, 0, 0,
				1, 1, 1, 1, 0,
				1, -1, 1, 1, 1,
				-1,-1, 1, 0, 1
				]);
				
			m_sceneIndexRawData = Vector.<uint>([
				0,2,3,
				0,1,2
			]);
			
			m_sceneVertexBuffer = m_context.createVertexBuffer(4, 5);
			m_sceneVertexBuffer.uploadFromVector(m_sceneVertexRawData,0,4);
			
			m_sceneIndexBuffer = m_context.createIndexBuffer(6);
			m_sceneIndexBuffer.uploadFromVector(m_sceneIndexRawData, 0, 6);
			
			var vertexProgram : AGALMiniAssembler = new AGALMiniAssembler();
			var fragmentProgram : AGALMiniAssembler = new AGALMiniAssembler();
			
			vertexProgram.assemble(Context3DProgramType.VERTEX,
				"m44 op, va0, vc0\n"+
				"mov v0, va1\n");
			
			fragmentProgram.assemble(Context3DProgramType.FRAGMENT,
				"tex ft0, v0, fs0<2d, clamp, linear>\n"+
				"sub ft0.xz, ft0.xz, ft0.xz\n" +
				"mov oc, ft0\n");
			
			m_normalShader = m_context.createProgram();
			m_normalShader.upload(vertexProgram.agalcode, fragmentProgram.agalcode);
			
			vertexProgram.assemble(Context3DProgramType.VERTEX,
				"m44 op, va0, vc0\n"+
				"mov v0, va0\n");
			
			fragmentProgram.assemble(Context3DProgramType.FRAGMENT,
				"mov oc, v0\n");
			
			m_noTextureShader = m_context.createProgram();
			m_noTextureShader.upload(vertexProgram.agalcode, fragmentProgram.agalcode);
			
			// Setup scene texture
			m_sceneTexture = m_context.createTexture(
				Utils.nextPowerOfTwo(stage.stageWidth),
				Utils.nextPowerOfTwo(stage.stageHeight),
				Context3DTextureFormat.BGRA,
				true
			);
			
			m_viewMatrix.identity();
			m_viewMatrix.appendTranslation(0,0,-4);
			
			m_cube = new CubeMesh(m_context);
		}
		
		private var t : Number = 0;
		private function onEnter(e:Event) : void
		{
			t += 1;
//			renderCube();
			renderPostProcessing();
			m_context.present();
		}
		
		private function renderCube() : void
		{
			m_context.clear(0.5,0.5,0.5);
			m_cube.render(m_viewMatrix, m_projMatrix, m_noTextureShader);
			m_cube.rotation(t, Vector3D.Y_AXIS);
		}
		
		private function renderPostProcessing() : void
		{
			// Render the scene to the scene texture
			m_context.setRenderToTexture(m_sceneTexture, true);
			renderCube();
			m_context.setRenderToBackBuffer();
			
			m_context.setProgram(m_normalShader);
			m_context.setTextureAt(0, m_sceneTexture);
			m_context.clear(0.5,0.5,0.5);
			
			m_modelMatrix.identity();
			m_modelMatrix.appendTranslation(0,0,1.21);
			
			m_finalMatrix.identity();
			m_finalMatrix.append(m_modelMatrix);
			m_finalMatrix.append(m_viewMatrix);
			m_finalMatrix.append(m_projMatrix);
			
			m_context.setVertexBufferAt(0, m_sceneVertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			m_context.setVertexBufferAt(1,m_sceneVertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_2);
			
			m_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, m_finalMatrix, true);
			
			m_context.drawTriangles(m_sceneIndexBuffer,0,2);
			m_context.setTextureAt(0,null);
			m_context.setVertexBufferAt(0,null);
			m_context.setVertexBufferAt(1,null);
		}
	}
}