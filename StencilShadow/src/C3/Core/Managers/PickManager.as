package C3.Core.Managers
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import C3.View;

	public class PickManager
	{
		public function PickManager(view : View)
		{
			m_pickRender = new PickRender();
			m_view = view;
			m_view.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}
		
		private function onAddedToStage(e:Event) : void
		{
			m_view.removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			
			m_view.stage.addEventListener(MouseEvent.CLICK, onMouseClick);
			m_view.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		}
		
		private function onMouseMove(e:MouseEvent) : void
		{
			m_pickRender.mouseCoordX = m_view.mouseX;
			m_pickRender.mouseCoordY = m_view.mouseY;
		}
		
		private function onMouseClick(e:MouseEvent) : void
		{
			m_pickRender.mouseCoordX = m_view.mouseX;
			m_pickRender.mouseCoordY = m_view.mouseY;
		}
		
		public function getRender() : PickRender
		{
			return m_pickRender;
		}
		
		public function render() : void
		{
			m_pickRender.render(m_view);
		}
		
		private var m_pickRender : PickRender;
		private var m_view : View;
	}
}