package C3.Animator
{
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	
	import C3.MD5.Quaternion;

	public class SkeletalAnmationData
	{
		public var frameData : Vector.<Dictionary>;
		public var frameRate : uint = 24;
		
		public function SkeletalAnmationData()
		{
			frameData = new Vector.<Dictionary>();
		}
		
		public function addBoneData(frame : int, boneName : String, _translation : Vector3D, _rotation : Quaternion, _scale : Vector3D) : void
		{
			if(frame > frameData.length - 1 || frameData[frame] == null)
			{
				frameData[frame] = new Dictionary();
			}
			
			frameData[frame][boneName] = {translation : _translation, rotation : _rotation, scale : _scale};
		}
	}
}