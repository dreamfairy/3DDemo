package C3.Animator
{
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	
	import C3.IDispose;
	import C3.View;
	import C3.Geoentity.AnimGeoentity;
	import C3.Geoentity.MeshGeoentity;
	import C3.MD5.MD5BaseFrameData;
	import C3.MD5.MD5FrameData;
	import C3.MD5.MD5HierarchyData;
	import C3.MD5.MD5Joint;
	import C3.MD5.MeshData;
	import C3.MD5.Quaternion;

	public class Animator implements IDispose
	{
		public function Animator()
		{
		}
		
		public function addAnimation(anim : AnimGeoentity) : void
		{
			m_actionList[anim.name] = anim;
		}
		
		public function play(name : String, loop : int = -1) : void
		{
			if(!m_actionList.hasOwnProperty(name)) return;
			
			m_currentAnimGeoentity = m_actionList[name];
			m_currentActionName = name;
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
			createShader();
		}
		
		private function createShader() : void
		{
			
		}
		
		public function render() : void
		{
			if(!m_needRender) return;
			
			m_currentFrameData = m_currentAnimGeoentity[m_currentFrame];
			CalcMeshAnim();
			
			if(m_model.useCPU){
				for each(m_currentMeshData in m_model.meshDatas)
				{
					cpuCalcJoint();
				}
			}
		}
		
		private function cpuCalcJoint() : void
		{
			var vertexLen : int = m_currentMeshData.md5_vertex.length;
			
			//当前索引
			var indices : Vector.<Number> = m_currentMeshData.jointIndexRawData;
			//当前顶点
			var vertex : Vector.<Number> = m_currentMeshData.vertexRawData;
			//当前权重
			var weight : Vector.<Number> = m_currentMeshData.jointWeightRawData;
			
			var result : Vector3D = new Vector3D();
			var temp : Vector3D = new Vector3D();
			var curVert : Vector3D = new Vector3D();
			
			m_cpuAnimVertexRawData ||= new Vector.<Number>();
			m_cpuAnimVertexRawData.length = 0;
			
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
				
				m_cpuAnimVertexRawData.push(result.x,result.y,result.z);
			}
			
			m_cpuAnimVertexBuffer ||= View.context.createVertexBuffer(m_cpuAnimVertexRawData.length/3,3);
			m_cpuAnimVertexBuffer.uploadFromVector(m_cpuAnimVertexRawData,0,m_cpuAnimVertexRawData.length/3);
		}
		
		private function CalcMeshAnim() : void
		{
			var joints : Vector.<MD5Joint> = m_model.joints;
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
				joint = joints[i];
				
				if(joint.parentIndex < 0){
					joint.bindPose = matrix3D;
				}else{
					//如果该关节有父级，需要先附带上父级的旋转和偏移
					parentJoint = joints[joint.parentIndex];
					matrix3D.append(parentJoint.bindPose);
					joint.bindPose = matrix3D;
				}
				
				matrix3D = joint.inverseBindPose.clone();
				matrix3D.append(joint.bindPose);
				
				var vc : int = i * 4;
				if(m_model.useCPU){
					m_cpuAnimMatrix[vc] = matrix3D;
				}else{
					View.context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, vc, matrix3D, true);
				}
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
		private var m_currentMeshData : MeshData;
		private var m_currentAnimGeoentity : AnimGeoentity;
		
		private var m_currentActionName : String;
		private var m_currentFrame : int;
		private var m_totalFrame : int;
		private var m_actionList : Dictionary = new Dictionary();
		private var m_model : MeshGeoentity;
		private var m_loop : int;
		private var m_needRender : Boolean;
		
		private var m_cpuAnimMatrix : Vector.<Matrix3D>;
		private var m_cpuAnimVertexRawData : Vector.<Number>;
		private var m_cpuAnimVertexBuffer : VertexBuffer3D;
		
		private var m_vertexShader : Program3D;
		private var m_fragmentShader : Program3D;
	}
}