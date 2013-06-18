package C3
{
	import com.adobe.utils.PerspectiveMatrix3D;
	
	import flash.display.Sprite;
	import flash.display.Stage3D;
	import flash.display3D.Context3D;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Matrix3D;
	
	import C3.Camera.Camera;

	public class View extends Sprite implements IDispose
	{
		public function View(width : int, height : int, enableErrorCheck : Boolean)
		{
			m_width = width;
			m_height = height;
			m_enableErrorCheck = enableErrorCheck;
			
			camera = new Camera();
			m_proj = new PerspectiveMatrix3D();
			m_proj.perspectiveFieldOfViewRH(45, m_width/m_height,1,5000.0);
			m_worldMatrix = new Matrix3D();
			m_finalMatrix = new Matrix3D();
			
			m_rootContainer = new Object3DContainer("root",null);
			m_rootContainer.isRoot = true;
			m_rootContainer.view = this;
			
			addEventListener(Event.ADDED_TO_STAGE, addedToStage);
		}
		
		private function addedToStage(e:Event) : void
		{
			if(hasEventListener(Event.ADDED_TO_STAGE))
				removeEventListener(Event.ADDED_TO_STAGE,addedToStage);
			
			stage.stage3Ds[0].addEventListener(Event.CONTEXT3D_CREATE, onCreateContext);
			stage.stage3Ds[0].requestContext3D();
			
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			stage.addEventListener(MouseEvent.CLICK, onMouseClick);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
//			stage.addEventListener(MouseEvent.RIGHT_CLICK, onMouseRightClick);
			
		}
		
		private function onCreateContext(e:Event) : void
		{
			m_renderablle = false;
			
			context = (e.target as Stage3D).context3D;
			context.configureBackBuffer(m_width,m_height,2,true);
			context.enableErrorChecking = m_enableErrorCheck;
			
			setup();
			
			m_renderablle = true;
		}
		
		private var m_cube : CubeMesh;
		private function setup() : void
		{
			m_cube = new CubeMesh(context);
		}
		
		public function render() : void
		{
			if(!m_renderablle) return;
			
			context.clear();
			m_rootContainer.render();
			context.present();
			onAfterRender();
		}
		
		public function getCamera() : Camera
		{
			return camera;
		}
		
		private function onAfterRender() : void
		{
			
		}
		
		private function onKeyDown(e:KeyboardEvent) : void
		{
			
		}
		
		private function onKeyUp(e:KeyboardEvent) : void
		{
			
		}
		
		private function onMouseClick(e:MouseEvent) : void
		{
			
		}
		
		private function onMouseMove(e:MouseEvent) : void
		{
			
		}
		
		private function onMouseRightClick(e:MouseEvent) : void
		{
			
		}
		
		public function get projMatrix() : Matrix3D
		{
			return m_proj;
		}
		
		public function get scene() : Object3DContainer
		{
			return m_rootContainer;
		}
		
		public function dispose():void
		{
			m_rootContainer.dispose();
			m_renderablle = false;
		}
		
		private var m_width : int;
		private var m_height : int;
		private var m_enableErrorCheck : Boolean;
		private var m_rootContainer : Object3DContainer;
		private var m_renderablle : Boolean;
		
		private var m_proj : PerspectiveMatrix3D;
		private var m_worldMatrix : Matrix3D;
		private var m_finalMatrix : Matrix3D;
		
		public static var context : Context3D;
		public static var camera : Camera;
	}
}