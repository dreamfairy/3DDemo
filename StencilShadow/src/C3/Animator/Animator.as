package C3.Animator
{
	import flash.display3D.Context3D;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import C3.IDispose;
	import C3.Object3D;
	import C3.Geoentity.AnimGeoentity;
	import C3.Geoentity.MeshGeoentity;
	import C3.MD5.MD5BaseFrameData;
	import C3.MD5.MD5FrameData;
	import C3.MD5.MD5HierarchyData;
	import C3.MD5.MD5Joint;
	import C3.MD5.MD5MeshData;
	import C3.MD5.Quaternion;
	import C3.Parser.Model.IJoint;

	public class Animator implements IDispose
	{
		public function Animator()
		{
			
		}
		
		public function addAnimation(anim : AnimGeoentity) : void
		{
			m_actionList[anim.name] = anim;
			
			if(!m_hasAnimation){
				m_hasAnimation = true;
			}
		}
		
		public function play(name : String, loop : int = -1) : void
		{
			if(!m_actionList.hasOwnProperty(name)) return;
			
			m_currentAnimGeoentity = m_actionList[name];
			m_currentActionName = name;
			m_currentFrame = m_frame = 0;
			m_totalFrame = m_currentAnimGeoentity.numFrams;
			m_loop = loop;
			m_needRender = true;
		}
		
		public function pause() : void
		{
			m_needRender = false;
		}
		
		public function bind(target : MeshGeoentity) : void
		{
			m_model = target;
		}

		
		public function render(context3D : Context3D) : Boolean
		{
			if(!m_needRender) return false;
			
			var now : int = getTimer();
			
			if(now - m_lastTime > m_frameRate){
				m_currentFrame = ++m_frame % m_totalFrame;
				m_currentFrameData = m_currentAnimGeoentity.frameDatas[m_currentFrame];
				
				for each(var child : Object3D in m_model.children)
				{
					CalcMeshAnim();
					cpuCalcJoint(child);
				}
				m_lastTime = now;
			}
			
			return true;
		}
		
		private function cpuCalcJoint(meshData : Object3D) : void
		{
			var vertexLen : int = meshData.vertexRawData.length/3;
			
			//当前索引
			var indices : Vector.<Number> = meshData.jointIndexRawData;
			//当前顶点
			var vertex : Vector.<Number> = meshData.vertexRawData;
			//当前权重
			var weight : Vector.<Number> = meshData.jointWeightRawData;
			
			var result : Vector3D = new Vector3D();
			var temp : Vector3D = new Vector3D();
			var curVert : Vector3D = new Vector3D();
			
			var cpuAnimVertexRawData : Vector.<Number> = new Vector.<Number>();
			cpuAnimVertexRawData.concat(meshData.vertexRawData);
			
			var l : int = 0;
			for(var i : int = 0; i < vertexLen; i++)
			{
				var startIndex : int = i * 3;
				//初始化当前的顶点和索引
				curVert.setTo(vertex[startIndex],vertex[startIndex+1],vertex[startIndex+2]);
				result.setTo(0,0,0);
				for(var j : int = 0; j < m_model.maxJoints; j++)
				{
					//当前索引对应的矩阵
					var curIndex : Number = indices[l];
					var curWeight : Number = weight[l];
					var curMatrix : Matrix3D = m_cpuAnimMatrix[curIndex];
					temp = curMatrix.transformVector(curVert);
					temp.scaleBy(curWeight);
					result = result.add(temp);
					l++;
				}
				
				cpuAnimVertexRawData[startIndex]		= result.x;
				cpuAnimVertexRawData[startIndex + 1]	= result.y;
				cpuAnimVertexRawData[startIndex + 2]	= result.z;
			}
			
			if(meshData.vertexBuffer){
				meshData.vertexBuffer.uploadFromVector(cpuAnimVertexRawData,0,cpuAnimVertexRawData.length/3);
			}
		}
		
		private function CalcMeshAnim() : void
		{
			var joints : Vector.<IJoint> = m_model.joints;
			var jointsNum : int = joints.length;
			
			if(m_model.useCPU){
				m_cpuAnimMatrix ||= new Vector.<Matrix3D>(jointsNum * 4, true);
			}
			
			var joint : MD5Joint;
			var parentJoint : MD5Joint;
			for(var i : int = 0; i < jointsNum; i++)
			{
				//从基本帧开始偏移
				m_currentBaseFrameData = m_currentAnimGeoentity.baseFrameDatas[i];
				var animatedPos : Vector3D = m_currentBaseFrameData.position;
				var animatedOrient : Quaternion = m_currentBaseFrameData.orientation;
				
				//将帧数据替换掉基本帧中对应的数据
				var hierachy : MD5HierarchyData = m_currentAnimGeoentity.hierarchies[i];
				
				var flags : int = hierachy.flags;
				var j : int = 0;
				if(flags & 1) //tx
					animatedPos.x = m_currentFrameData.components[hierachy.startIndex + j++];
				
				if(flags & 2) //ty
					animatedPos.y = m_currentFrameData.components[hierachy.startIndex + j++];
				
				if(flags & 4)
					animatedPos.z = m_currentFrameData.components[hierachy.startIndex + j++];
				
				if(flags & 8)
					animatedOrient.x = m_currentFrameData.components[hierachy.startIndex + j++];
				
				if(flags & 16)
					animatedOrient.y = m_currentFrameData.components[hierachy.startIndex + j++];
				
				if(flags & 32)
					animatedOrient.z = m_currentFrameData.components[hierachy.startIndex + j++];
				
				//计算w
				var t : Number = 1 - animatedOrient.x * animatedOrient.x - animatedOrient.y * animatedOrient.y - 
					animatedOrient.z * animatedOrient.z;
				animatedOrient.w = t < 0 ? 0 : - Math.sqrt(t);
				
				var matrix3D : Matrix3D = animatedOrient.toMatrix3D();
				matrix3D.appendTranslation(animatedPos.x, animatedPos.y, animatedPos.z);
				
				//取出当前关节
				joint = joints[i] as MD5Joint;
				
				if(joint.parentIndex < 0){
					joint.bindPose = matrix3D;
				}else{
					//如果该关节有父级，需要先附带上父级的旋转和偏移
					parentJoint = joints[joint.parentIndex] as MD5Joint;
					matrix3D.append(parentJoint.bindPose);
					joint.bindPose = matrix3D;
				}
				
				matrix3D = joint.inverseBindPose.clone();
				matrix3D.append(joint.bindPose);
				
				var vc : int = i * 4;
				m_cpuAnimMatrix[vc] = matrix3D;
				
//				if(m_model.useCPU){
//					m_cpuAnimMatrix[vc] = matrix3D;
//				}else{
//					m_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, vc, matrix3D, true);
//				}
			}
		}
		
		public function dispose():void
		{
			m_model = null;
			m_actionList = null;
		}
		
		public function get currentFrame() : int
		{
			return m_currentFrame;
		}
		
		public function get totalFrame() : int
		{
			return m_totalFrame;
		}
		
		private var m_currentBaseFrameData : MD5BaseFrameData;
		private var m_currentFrameData : MD5FrameData;
		private var m_currentMeshData : MD5MeshData;
		private var m_currentAnimGeoentity : AnimGeoentity;
		
		private var m_frameRate : uint = 25;
		private var m_lastTime : int = 0;
		private var m_frame : int = 0;
		private var m_currentActionName : String;
		private var m_currentFrame : int;
		private var m_totalFrame : int;
		private var m_actionList : Dictionary = new Dictionary();
		private var m_model : MeshGeoentity;
		private var m_loop : int;
		private var m_needRender : Boolean;
		private var m_hasAnimation : Boolean = false;
		private var m_bufferFormat : String;
		
		private var m_cpuAnimMatrix : Vector.<Matrix3D>;
	}
}