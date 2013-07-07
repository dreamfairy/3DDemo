package C3.Animator
{
	import C3.Geoentity.AnimGeoentity;
	import C3.Geoentity.MeshGeoentity;
	import C3.IDispose;
	import C3.MD5.MD5BaseFrameData;
	import C3.MD5.MD5FrameData;
	import C3.MD5.MD5HierarchyData;
	import C3.MD5.MD5Joint;
	import C3.MD5.MD5Result;
	import C3.MD5.MeshData;
	import C3.MD5.Quaternion;
	import C3.Object3D;
	import C3.View;
	
	import com.adobe.utils.AGALMiniAssembler;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;

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
				if(m_context)createShader();
				else m_needToUpdateAnimProgram = true;
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
			m_bufferFormat = "float" + m_model.maxJoints;
		}
		
		
		private function createShader() : void
		{
			m_shader ||= m_context.createProgram();
			m_shader.upload(updateVertesProgram().agalcode,updateFragmentProgram().agalcode);
			if(m_needToUpdateAnimProgram)m_needToUpdateAnimProgram = false;
		}
		
		/**
		 * 0顶点
		 * 1uv
		 * 2骨骼
		 * 3权重
		 * 124世界坐标
		 */
		private function updateVertesProgram() : AGALMiniAssembler
		{
			var code : String = "";
			if(!m_model.useCPU){
				//骨骼和权重
				var indexStream : String = "va2";
				var weightStream : String = "va3";
				var indices : Array = [ indexStream + ".x", indexStream + ".y", indexStream + ".z", indexStream + ".w" ];
				var weights : Array = [ weightStream + ".x", weightStream + ".y", weightStream + ".z", weightStream + ".w" ];
				
				for(var j : int = 0; j < m_model.maxJoints; ++j){
					code += "m44 vt1, va0, vc[" + indices[j] + "]\n" +
						//将骨骼坐标乘以权重值
						"mul vt1, vt1, " + weights[j] + "\n";
					//初始化vt2
					if(j == 0) code += "mov vt2, vt1 \n";
					else code += "add vt2, vt2, vt1 \n";
					
				}
				
				//将顶点转为世界坐标
				code += "m44 op, vt2, vc124 \n" +
					"mov v0, va1";
			}else{
				code = "m44 op, va0, vc124 \n"+
					"mov v0, va1 \n";
			}
			
			var vertexShader : AGALMiniAssembler = new AGALMiniAssembler();
			vertexShader.assemble(Context3DProgramType.VERTEX, code);
			
			return vertexShader;
		}
		
		/**
		 * 0纹理
		 * 1法线
		 * 2反射
		 */
		private function updateFragmentProgram() : AGALMiniAssembler
		{
			var code : String = m_model.material.getFragmentStr(null)
//				"tex ft0 v0 fs0<2d linear wrap>\n"+
//				"mov oc ft0\n";
			
			var fragmentShader : AGALMiniAssembler = new AGALMiniAssembler();
			fragmentShader.assemble(Context3DProgramType.FRAGMENT, code);
			
			return fragmentShader;
		}
		
		public function render() : Boolean
		{
			if(!m_needRender) return false;
			m_context = View.context;
			if(!m_shader || m_needToUpdateAnimProgram)createShader();
			
			m_currentFrame = ++m_frame % m_totalFrame;
			m_currentFrameData = m_currentAnimGeoentity.frameDatas[m_currentFrame];
			
			CalcMeshAnim();
			
			m_context.setProgram(m_shader);
			m_model.updateMatrix();
			m_model.updateMaterial();
			
			var child : Object3D;
			for each(child in m_model.children)
			{
				m_currentMeshData = child.userData.meshData as MeshData;
				CalcMeshAnim();
				
				if(!m_model.useCPU){
					//上传骨骼和权重
					m_context.setVertexBufferAt(2, child.jointIndexBuffer, 0, m_bufferFormat);
					m_context.setVertexBufferAt(3, child.jointWeightBuffer, 0, m_bufferFormat);
				}else{
					cpuCalcJoint(child);
				}
				
				var vertexBuffer : VertexBuffer3D = m_model.useCPU ? m_cpuAnimVertexBuffer : child.vertexBuffer;
				
				m_context.setVertexBufferAt(0,vertexBuffer,0,Context3DVertexBufferFormat.FLOAT_3);
				m_context.setVertexBufferAt(1,child.uvBuffer,0,Context3DVertexBufferFormat.FLOAT_2);
				m_context.drawTriangles(child.indexBuffer);
			}
			
			free();
			return true;
		}
		
		private function free() : void
		{
			m_cpuAnimVertexBuffer = null;
			
			for(var i : int = 0; i < 4; i++){
				m_context.setVertexBufferAt(i,null);
			}
		}
		
		private function cpuCalcJoint(meshData : Object3D) : void
		{
			var vertexLen : int = m_currentMeshData.md5_vertex.length;
			
			//当前索引
			var indices : Vector.<Number> = meshData.jointIndexRawData;
			//当前顶点
			var vertex : Vector.<Number> = meshData.vertexRawData;
			//当前权重
			var weight : Vector.<Number> = meshData.jointWeightRawData;
			
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
			
			m_cpuAnimVertexBuffer ||= m_context.createVertexBuffer(m_cpuAnimVertexRawData.length/3,3);
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
					m_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, vc, matrix3D, true);
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
		
		private var m_frame : int = 0;
		private var m_currentActionName : String;
		private var m_currentFrame : int;
		private var m_totalFrame : int;
		private var m_actionList : Dictionary = new Dictionary();
		private var m_model : MeshGeoentity;
		private var m_loop : int;
		private var m_needRender : Boolean;
		private var m_hasAnimation : Boolean = false;
		private var m_needToUpdateAnimProgram : Boolean = false;
		private var m_bufferFormat : String;
		
		private var m_cpuAnimMatrix : Vector.<Matrix3D>;
		private var m_cpuAnimVertexRawData : Vector.<Number>;
		private var m_cpuAnimVertexBuffer : VertexBuffer3D;
		
		private var m_shader : Program3D;
		private var m_context : Context3D;
	}
}