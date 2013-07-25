package C3.Animator
{
	import flash.display3D.Context3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.getTimer;
	
	import C3.IDispose;
	import C3.Object3D;
	import C3.OGRE.OGREAnimParser;
	import C3.OGRE.OGREFrameData;
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
				var vertexLen : int = vertex.length;
				
				var result : Vector3D = new Vector3D();
				var temp : Vector3D = new Vector3D();
				var curVert : OGREVertex;
				
				m_cpuAnimVertexRawData.length = 0;
				
				for(var i : int = 0; i < vertexLen; i++)
				{
					curVert = vertex[i];
//					trace(curVert.pos);
					result.setTo(0,0,0);
					var weightCount : uint = curVert.maxJoints;
					for(var j : int = 0; j < weightCount; j++)
					{
						var curBoneData : OGREVertexBoneData = curVert.boneList[j];
						var curIndex : Number = curBoneData.index;
						var curWeight : Number = curBoneData.weight;
						var curMatrix : Matrix3D = m_cpuAnimMatrix[curIndex];
						temp = curMatrix.transformVector(curVert.pos);
						temp.scaleBy(curWeight);
						result = result.add(temp);
					}
//					trace(result);
					m_cpuAnimVertexRawData.push(result.x,result.y,result.z);
				}
			}
		}
		
		/**
		 * 计算蒙皮
		 */
		private function CalcMeshAnim(tick : Number) : void
		{
			var t : Number = tick / 1000;

			var skeletonBone : Vector.<IJoint> = parent.target.joints;
			var animationBone : Vector.<IJoint> = m_data.joints;
			var jointsNum : int = skeletonBone.length;
			
			m_cpuAnimMatrix||=new Vector.<Matrix3D>(jointsNum, true);
			
			var parentJoint : OGREJoint;
			var currentJoint : OGREJoint;
			var skeletonJoint : OGREJoint;
			var currentFrameData : OGREFrameData;
			for(var i : int = 0; i < jointsNum; i ++)
			{
				currentJoint = animationBone[i] as OGREJoint;
				skeletonJoint = skeletonBone[i] as OGREJoint;
				
				var matrix3D : Matrix3D = new Matrix3D();
				
				if(!currentJoint.hasFrameData)
				{
					matrix3D.appendTranslation(currentJoint.position.x,currentJoint.position.y,currentJoint.position.z);
					matrix3D.appendRotation(currentJoint.angle,currentJoint.axis);
				}else{
					
					if(t < currentJoint.getNextFrameTime(t)){
						currentFrameData = currentJoint.currentFrameData;
					}else{
						currentFrameData = currentJoint.nextFrameData;
					}
					
					matrix3D.appendTranslation(currentFrameData.translate.x,currentFrameData.translate.y,currentFrameData.translate.z);
					matrix3D.appendRotation(currentFrameData.rotate,currentFrameData.axis);
					matrix3D.appendScale(currentFrameData.scale.x,currentFrameData.scale.y,currentFrameData.scale.z);
					
					if(currentJoint.name == "Bip01 Spine1") {
//						trace(currentFrameData.translate.x,currentFrameData.translate.y,currentFrameData.translate.z);
					}
				}
				
				parentJoint = currentJoint.parent;
				if(parentJoint){
					matrix3D.append(parentJoint.bindPose);
				}
				
				currentJoint.bindPose = matrix3D;
				
				matrix3D = currentJoint.inverseBindPose.clone();
				matrix3D.append(currentJoint.bindPose);
				
//				matrix3D.invert();
				m_cpuAnimMatrix[currentJoint.id] = matrix3D;
			}
			
			CalcVertex();
			m_vertexDataDirty = true;
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