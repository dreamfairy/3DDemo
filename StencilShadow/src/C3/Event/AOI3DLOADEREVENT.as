package C3.Event
{
	import flash.events.Event;
	
	import C3.MD5.MeshData;
	
	public class AOI3DLOADEREVENT extends Event
	{
		public static const ON_MESH_LOADED : String = "OML";
		public static const ON_ANIM_LOADED : String = "OAL";
		public function AOI3DLOADEREVENT(type:String, mesh : MeshData, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.mesh = mesh;
		}
		
		public var mesh : MeshData;
	}
}