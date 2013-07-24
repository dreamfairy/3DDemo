package C3.Animator
{
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.getTimer;
	
	import C3.IDispose;
	import C3.Object3D;
	import C3.OGRE.OGREFrameData;
	import C3.OGRE.OGREJoint;

	/**
	 * 一段动画
	 */
	public class AnimalState implements IDispose
	{
		public function AnimalState(animalSet : AnimationSet, animationName : String)
		{
		}
		
		public function updateAnimation() : void
		{
			if(!m_needRender) return;
			CalcMeshAnim(getTimer() - m_startTime);
		}
		
		public function checkAnimaltionDirty() : Boolean
		{
			return false;
		}
		
		public function play() : void
		{
			m_startTime = getTimer();
			m_needRender = true;
		}
		
		public function pause() : void
		{
			
		}
		
		public function stop() : void
		{
			
		}
		
		/**
		 * 获取下一帧的时间
		 */
		private function getNextFrameNumber() : Number
		{
			return -1;
		}
		
		private function get timeList() : Vector.<Number>
		{
			return null;
		}
		
		/**
		 * 计算顶点
		 */
		private function calcVertex() : void
		{
			var vertex : Vector.<Number> = new Vector.<Number>();
			var indices : Vector.<Number> = new Vector.<Number>();
			var weight : Vector.<Number> = new Vector.<Number>();
			var vertexLen : int = vertex.length;
			
			var result : Vector3D = new Vector3D();
			var temp : Vector3D = new Vector3D();
			var curVert : Vector3D = new Vector3D();
			var maxJoint : int;
			
			m_cpuAnimVertexRawData.length = 0;
			
			var l : int = 0;
			for(var i : int = 0; i < vertexLen; i++)
			{
				var startIndex : int = i * 3;
				curVert.setTo(vertex[startIndex],vertex[startIndex + 1], vertex[startIndex + 2]);
				result.setTo(0,0,0);
				for(var j : int = 0; j < maxJoint; j++)
				{
					var curIndex : Number = indices[l];
					var curWeight : Number = weight[l];
					var curMatrix : Matrix3D = m_cpuAnimMatrix[curIndex];
					temp = curMatrix.transformVector(curVert);
					temp.scaleBy(curWeight);
					result = result.add(temp);
					l++;
				}
				m_cpuAnimVertexRawData.push(result.x,result.y,result.z);
			}
		}
		
		/**
		 * 计算蒙皮
		 */
		private function CalcMeshAnim(tick : Number) : void
		{
			if(m_nextFrameTime != -1 && tick < m_nextFrameTime) return;
			m_cpuAnimMatrix.splice(0,m_cpuAnimMatrix.length);
			
			var joints : Vector.<OGREJoint> = new Vector.<OGREJoint>();
			var jointsNum : int = joints.length;
			
			var parentJoint : OGREJoint;
			var currentJoint : OGREJoint;
			var currentFrameData : OGREFrameData;
			for(var i : int = 0; i < jointsNum; i ++)
			{
				currentJoint = joints[i];
				currentFrameData = currentJoint.frameDataList.frameData[m_currentFrameIndex];
				var animatedPos : Vector3D = currentJoint.position;
				var animatedRotate : Matrix3D = new Matrix3D();
				
				animatedPos.x = currentFrameData.translate.x;
				animatedPos.y = currentFrameData.translate.y;
				animatedPos.z = currentFrameData.translate.z;
				
				animatedRotate.appendTranslation(animatedPos.x,animatedPos.y,animatedPos.z);
				animatedRotate.appendRotation(currentFrameData.rotate,currentFrameData.axis);
				
				currentJoint.bindPose = animatedRotate;
				parentJoint = currentJoint.parent;
				if(parentJoint){
					animatedRotate.append(parentJoint.bindPose);
				}
				
				animatedRotate = currentJoint.inverseBindPose.clone();
				animatedRotate.append(currentJoint.bindPose);
				
				var vc : int = i * 4;
				m_cpuAnimMatrix[vc] = animatedRotate;
			}
			
			m_nextFrameTime = timeList[m_currentFrameIndex++];
		}
		
		private function getNextFrame(tick : Number, timeList : Vector.<Number>) : int
		{
			for(var i : int = 0; i < timeList.length; i++)
			{
				if(tick >= timeList[i]) return i;
			}
			
			return -1;
		}
		
		/**
		 * 获取骨骼矩阵
		 */
		private function get boneMatrices() : Matrix3D
		{
			return null;
		}
		
		public function dispose():void
		{
			// TODO Auto Generated method stub
			
		}
		
		private var m_cpuAnimVertexRawData : Vector.<Number> = new Vector.<Number>();
		private var m_cpuAnimMatrix : Vector.<Matrix3D> = new Vector.<Matrix3D>();
		private var m_boneMatrices : Vector.<Matrix3D>;
		private var m_currentFrameIndex : int = 0;
		private var m_nextFrameTime : Number = -1;
		private var m_needRender : Boolean = false;
		private var m_startTime : Number;
		
		public var currentFrameNumber : Number;
		public var animalTarget : Object3D;
		public var animationName : String;
		public var animationDuration : Number;
		public var deltaTime : Number;
		public var isLoop : Boolean;
		public var isEnabled : Boolean;
	}
}