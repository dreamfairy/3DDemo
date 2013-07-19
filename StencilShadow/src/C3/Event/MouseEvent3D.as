package C3.Event
{
	import flash.events.Event;
	
	import C3.Object3D;
	
	public class MouseEvent3D extends Event
	{
		public function MouseEvent3D(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		public var target3D : Object3D;
		
		public static const CLICK : String = "click";
		public static const MOUSE_UP : String = "up";
		public static const MOUSE_DOWN : String = "down";
		public static const MOUSE_MOVE : String = "move";
	}
}