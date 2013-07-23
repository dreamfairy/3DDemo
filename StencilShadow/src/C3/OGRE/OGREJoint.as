package C3.OGRE
{
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	public class OGREJoint
	{
		public var id : uint;
		public var name : String;
		public var position : Vector3D;
		public var angle : Number;
		public var axis : Vector3D;
		public var parent : OGREJoint;
		public var isRoot : Boolean;
		
		public var frameDataList : OGREFrameList;
		public var frameTimeList : Vector.<Number>;
		
		public var bindPose : Matrix3D;
		public var inverseBindPose : Matrix3D;
		
		private var rotatedPosition : Vector3D;
		
		public function calc() : void
		{
			bindPose = new Matrix3D();
			bindPose.appendTranslation(position.x,position.y,position.z);
			bindPose.appendRotation(angle,axis);
			inverseBindPose = bindPose.clone();
			inverseBindPose.invert();
			
			frameTimeList = new Vector.<Number>();
			var len : uint = frameDataList.frameData.length;
			for(var i : int = 0; i < len; i++)
			{
				var frameData : OGREFrameData = frameDataList.frameData[i];
				frameTimeList.push(frameData);
			}
		}
	}
}