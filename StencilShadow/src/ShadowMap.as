package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import C3.AOI3DAXIS;
	import C3.PlaneMesh;
	import C3.View;
	import C3.Material.ColorMaterial;

	[SWF(width = "800", height = "800", frameRate="30")]
	public class ShadowMap extends Sprite
	{
		public function ShadowMap()
		{
			stage ? init() : addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null) : void
		{
			if(hasEventListener(Event.ADDED_TO_STAGE))
				removeEventListener(Event.ADDED_TO_STAGE, init);
			
			m_view = new View(stage.stageWidth,stage.stageHeight,true);
			addChild(m_view);
			
			m_plane = new PlaneMesh("plane",10,10, 2, AOI3DAXIS.XY, new ColorMaterial(0xFF0000,1));
			m_plane.z = -20;
			m_view.scene.addChild(m_plane);
			
			stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			this.addEventListener(Event.ENTER_FRAME, onEnter);
		}
		
		private function onEnter(e:Event) : void
		{
			m_view.render();
		}
		
		private function onMouseWheel(e:MouseEvent) : void
		{
			m_view.getCamera().walk(-1 * e.delta/3);
		}
		
		private var m_view : View;
		private var m_plane : PlaneMesh;
	}
}