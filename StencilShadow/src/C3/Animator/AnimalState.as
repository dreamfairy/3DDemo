package C3.Animator
{
	import flash.display3D.Context3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import C3.IDispose;
	import C3.Object3D;
	import C3.MD5.Quaternion;
	import C3.OGRE.OGREAnimParser;
	import C3.OGRE.OGREJoint;
	import C3.OGRE.OGREVertex;
	import C3.OGRE.OGREVertexBoneData;
	import C3.OGRE.OgreMeshData;
	import C3.Parser.Model.IJoint;

	/**
	 * 一段动画
	 */
	public class AnimalState implements IDispose
	{
		public function AnimalState(animalSet : AnimationSet, name : String)
		{
			animationName = name;
			parent = animalSet;
		}
		
		public function updateAnimation() : void
		{
			m_cpuAnimMatrix||=new Vector.<Matrix3D>(m_data.joints.length, true);
			CalcMeshAnim(getTimer() - m_startTime);
		}
		
		public function checkAnimaltionDirty() : Boolean
		{
			return false;
		}
		
		public function play() : void
		{
			m_startTime = getTimer();
			parent.setRender(this);
		}
		
		public function pause() : void
		{
			m_startTime = getTimer();
		}
		
		public function stop() : void
		{
			parent.setRender(this, false);
		}
		
		public function getVertexBuffer(context3D : Context3D) : VertexBuffer3D
		{
//			if(!m_cpuAnimVertexRawData.length) return null;
			
			m_vertexBuffer ||= context3D.createVertexBuffer(m_cpuAnimVertexRawData.length/3,3);
			
			if(m_vertexDataDirty){
				m_vertexBuffer.uploadFromVector(m_cpuAnimVertexRawData,0,m_cpuAnimVertexRawData.length/3);
				m_vertexDataDirty = false;
			}
			
			return m_vertexBuffer;
		}
		
		/**
		 * 获取下一帧的时间
		 */
		private function getNextFrameNumber() : Number
		{
			return -1;
		}
		
		/**
		 * 计算顶点
		 */
		private function CalcVertex() : void
		{
			var ogreMeshDatas : Vector.<OgreMeshData> = parent.target.meshDatas;
			
			for each(var meshData : OgreMeshData in ogreMeshDatas){
				var vertex : Vector.<OGREVertex> = meshData.ogre_vertex;
				
				var result : Vector3D = new Vector3D();
				var temp : Vector3D = new Vector3D();
				var curVert : OGREVertex;
				
				m_cpuAnimVertexRawData.length = 0;
				
				for each(curVert in vertex)
				{
					result.setTo(0,0,0);
					for each(var boneData : OGREVertexBoneData in curVert.boneList)
					{
						var curIndex : Number = boneData.index;
						var curWeight : Number = boneData.weight;
						var curMatrix : Matrix3D = m_cpuAnimMatrix[curIndex];
						temp = curMatrix.transformVector(curVert.pos);
						temp.scaleBy(curWeight);
						result = result.add(temp);
					}
					m_cpuAnimVertexRawData.push(result.x,result.y,result.z);
				}
			}
		}
		
		private function getData(target : Matrix3D, name : String) : void
		{
			var data : Vector.<Vector3D> = target.decompose();
			trace(name,data[0],data[1],data[2]);
		}
		
		/**
		 * 计算蒙皮
		 */
		private function CalcMeshAnim(time : Number) : void
		{
			var animation : SkeletalAnmationData = parent.target.skeletalAnimationData;
			
			var currentFrame : uint = (Math.floor(time * (animation.frameRate/1000)) + m_startTime) % animation.frameData.length;
			
			if(!animation.frameData.length){
				for each(var tempJoint : OGREJoint in m_data.joints)
				{
					m_cpuAnimMatrix[tempJoint.id] = tempJoint.update().clone();
				}
				CalcVertex();
				m_vertexDataDirty = true;
				return;
			}
			
			if(currentFrame == m_lastFrame) return;
			
			var _currentFrameData : Dictionary = animation.frameData[currentFrame];
			var boneName : String;
			var meshBoneLength : uint = m_data.joints.length;
			var bone : OGREJoint;
			var obj : Object;
			
			for(var i : int = 0; i < meshBoneLength; i++)
			{
				bone = m_data.joints[i] as OGREJoint;
				boneName = bone.name;
				
				obj = _currentFrameData[boneName];
				
				if(obj && !obj.matrix)
				{
					//当前帧的旋转
					var rot : Quaternion = obj.rotation;
					bone.quaternion.setTo(rot.x,rot.y,rot.z,rot.w);
					bone.scale.setTo(obj.scale.x,obj.scale.y,obj.scale.z);
					bone.position.setTo(obj.translation.x,obj.translation.y,obj.translation.z);
					bone.invalidate();
				}
			}
			
			for(i = 0; i < meshBoneLength; i++)
			{
				bone = m_data.joints[i] as OGREJoint;
				boneName = bone.name;
				
				//如果当前有帧中该骨骼有动作
				if(_currentFrameData.hasOwnProperty(boneName)) {
					//如果当前帧的骨骼已经计算过了
					if(_currentFrameData[boneName].matrix){
						bone.update(_currentFrameData[boneName].matrix);
					}else{
						_currentFrameData[boneName].matrix = bone.update().clone();
					}
				}
				
				m_cpuAnimMatrix[bone.id] = bone.transformationMatrix;
			}

			CalcVertex();
			m_vertexDataDirty = true;
			m_lastFrame = currentFrame;
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
		
		public function set Skeleton(data : OGREAnimParser) : void
		{
			m_data = data;
		}
		
		private var m_lastFrame : int;
		private var m_data : OGREAnimParser;
		private var m_cpuAnimVertexRawData : Vector.<Number> = new Vector.<Number>();
		private var m_cpuAnimMatrix : Vector.<Matrix3D>;
		private var m_boneMatrices : Vector.<Matrix3D>;
		private var m_startTime : Number;
		private var m_vertexBuffer : VertexBuffer3D;
		private var m_vertexDataDirty : Boolean = false;
		
		public var parent : AnimationSet;
		public var currentFrameNumber : Number;
		public var animalTarget : Object3D;
		public var animationName : String;
		public var animationDuration : Number;
		public var deltaTime : Number;
		public var isLoop : Boolean;
		public var isEnabled : Boolean;
	}
}