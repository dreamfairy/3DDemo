package C3.Core.Managers
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import C3.IDispose;
	import C3.Object3D;
	import C3.View;
	import C3.Camera.Camera;
	import C3.Event.MouseEvent3D;

	public class PickManager implements IDispose
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
			m_view.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			m_view.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			m_view.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		}
		
		private function onMouseMove(e:MouseEvent) : void
		{
			if(null != m_currentObject && m_currentObject.onMouseMove && m_currentObject.onMouseMove.numListeners)
			{
				var event : MouseEvent3D = new MouseEvent3D(MouseEvent3D.MOUSE_MOVE);
				event.target3D = m_currentObject;
				m_currentObject.onMouseMove.dispatch(event);
			}
			
		}
		
		private function onMouseClick(e:MouseEvent) : void
		{
			if(null != m_currentObject && m_currentObject.onMouseClick && m_currentObject.onMouseClick.numListeners)
			{
				var event : MouseEvent3D = new MouseEvent3D(MouseEvent3D.CLICK);
				event.target3D = m_currentObject;
				m_currentObject.onMouseClick.dispatch(event);
			}
		}
		
		private function onMouseUp(e:MouseEvent) : void
		{
			if(null != m_currentObject && m_currentObject.onMouseUp && m_currentObject.onMouseUp.numListeners)
			{
				var event : MouseEvent3D = new MouseEvent3D(MouseEvent3D.MOUSE_UP);
				event.target3D = m_currentObject;
				m_currentObject.onMouseUp.dispatch(event);
			}
		}
		
		private function onMouseDown(e:MouseEvent) : void
		{
			if(null != m_currentObject && m_currentObject.onMouseDown && m_currentObject.onMouseDown.numListeners)
			{
				var event : MouseEvent3D = new MouseEvent3D(MouseEvent3D.MOUSE_MOVE);
				event.target3D = m_currentObject;
				m_currentObject.onMouseDown.dispatch(event);
			}
		}
		
		public function getRender() : PickRender
		{
			return m_pickRender;
		}
		
		public function render(camera : Camera) : void
		{
			m_pickRender.mouseCoordX = m_view.mouseX;
			m_pickRender.mouseCoordY = m_view.mouseY;
			
			m_pickRender.render(m_view, camera);
			m_currentObject = m_pickRender.lastHit;
		}
		
		public function dispose():void
		{
			// TODO Auto Generated method stub
			
		}
		
		private var m_currentObject : Object3D;
		private var m_pickRender : PickRender;
		private var m_view : View;
	}
}