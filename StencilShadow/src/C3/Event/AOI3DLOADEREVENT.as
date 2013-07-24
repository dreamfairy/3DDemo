package C3.Event
{
	import flash.events.Event;
	
	public class AOI3DLOADEREVENT extends Event
	{
		public static const ON_MESH_LOADED : String = "OML";
		public static const ON_ANIM_LOADED : String = "OAL";
		public static const REQUEST_SKELETON : String = "RS";
		public static const ON_SKELETON_LOADED : String = "OSL";
		public function AOI3DLOADEREVENT(type:String, data : *, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.data = data;
		}
		
		public var data : *;
	}
}