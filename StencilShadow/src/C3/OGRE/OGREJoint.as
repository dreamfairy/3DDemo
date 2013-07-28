package C3.OGRE
{
	import C3.MD5.Quaternion;
	import C3.Parser.Model.IJoint;
	
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	public class OGREJoint implements IJoint
	{
		public var id : int;
		public var name : String;
		public var position : Vector3D;
		public var angle : Number;
		public var axis : Vector3D;
		public var parent : OGREJoint;
		
		public var frameIndex : int = 0;
		public var frameDataList : OGREFrameList;
		public var frameTimeList : Vector.<Number>;
		public var quaternion : Quaternion;
		
		public var bindPose : Matrix3D;
		public var inverseBindPose : Matrix3D;
		
		public var hasFrameData : Boolean = false;
		public var frameStartTime : Number;
		
		private var rotatedPosition : Vector3D;
		private var totalFrame : uint;
		private var frame : int;
		private var endTime : Number = 0;
		private var tick : Number = 0;
		
		public var hasCalc : Boolean = false;
		
		public function calc() : void
		{
			hasCalc = true;
			axis.normalize();
			
//			quaternion = new Quaternion();
//			quaternion.fromAxisAngle(axis,angle);
//			bindPose = quaternion.toMatrix3D();
			
			bindPose = new Matrix3D();
			bindPose.appendRotation(angle,axis,position);
			inverseBindPose = bindPose.clone();
			inverseBindPose.invert();
			
			hasFrameData = null != frameDataList;
			if(!hasFrameData) return;
			
			frameTimeList = new Vector.<Number>();
			var len : uint = frameDataList.frameData.length;
			for(var i : int = 0; i < len; i++)
			{
				var frameData : OGREFrameData = frameDataList.frameData[i];
				frameTimeList.push(frameData.time);
			}
			
			frame = 0;
			totalFrame = frameDataList.frameData.length;
			frameStartTime = frameTimeList[0];
		}
		
		public function get nextFrameData() : OGREFrameData
		{
			frameIndex = frame++ % totalFrame;
			
			if(frameIndex == frameDataList.frameData.length - 1){
				endTime = tick;
				frame=0;
			}
						
			return frameDataList.frameData[frameIndex];
		}
		
		public function get currentFrameData() : OGREFrameData
		{
			return frameDataList.frameData[frameIndex];
		}
		
		public function getNextFrameTime(deltaTime : Number) : Number
		{
			tick = deltaTime;
			return frame ? endTime + frameTimeList[frameIndex] : endTime + frameStartTime;
		}
	}
}