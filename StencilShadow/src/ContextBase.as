package
{
	import com.adobe.utils.PerspectiveMatrix3D;
	
	import flash.display.Sprite;
	import flash.display.Stage3D;
	import flash.display3D.Context3D;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.ui.Keyboard;

	[SWF(width = "1024", height = "1024", frameRate="60")]
	public class ContextBase extends Sprite
	{
		protected var m_context : Context3D;
		protected var m_key : Object = new Object();
		
		protected var m_projMatrix : PerspectiveMatrix3D = new PerspectiveMatrix3D()
		protected var m_worldMatrix : Matrix3D = new Matrix3D();
		protected var m_finalMatrix : Matrix3D = new Matrix3D();
		protected var m_viewMatrix : Matrix3D = new Matrix3D();
		
		protected static const CAM_FACING:Vector3D = new Vector3D(0, 0, -1);
		protected static const CAM_UP:Vector3D = new Vector3D(0, -1, 0);
		
		public function ContextBase()
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
		
		protected function onCreateContext(e:Event) : void
		{
			m_context = (e.target as Stage3D).context3D;
			m_context.configureBackBuffer(stage.stageWidth, stage.stageHeight, 2, true);
			m_context.enableErrorChecking = true;
			
			m_projMatrix.perspectiveFieldOfViewRH(45, stage.stageWidth / stage.stageHeight, 1, 5000.0);
		}
		
		protected function onMouseWheel(e:MouseEvent) : void
		{
			m_viewMatrix.appendTranslation(0,0,e.delta);
		}
		
		protected function renderKeyBoard() : void
		{
			var speed : Number = 1.0;
			
			if(m_key[Keyboard.UP])
				m_viewMatrix.appendTranslation(0,speed,0);
			
			if(m_key[Keyboard.DOWN])
				m_viewMatrix.appendTranslation(0,-speed,0);
			
			if(m_key[Keyboard.LEFT])
				m_viewMatrix.appendTranslation(-speed,0,0);
			
			if(m_key[Keyboard.RIGHT])
				m_viewMatrix.appendTranslation(speed,0,0);
		}
	}
}