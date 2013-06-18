package C3.MD5
{
	import com.adobe.utils.AGALMiniAssembler;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;

	/**
	 * MD5结果
	 */
	public class MD5Result extends EventDispatcher
	{
		public var context : Context3D;
		
		/**MD5模型**/
		public var hasMesh : Boolean;
		public var hasAnim : Boolean;
		
		private var md5MeshParser : MD5MeshParser = new MD5MeshParser();
		private var md5AnimParser : MD5AnimParser = new MD5AnimParser();
		
		/**CPU运算模式下，存储动画关节信息**/
		private var cpuAnimMatrix : Vector.<Matrix3D>;
		
		/**骨骼及权重**/
		public var jointIndicesBuffer : VertexBuffer3D;
		public var jointWeightsBuffer : VertexBuffer3D;
		
		/**索引和权重长度**/
		public var bufferFormat : String;
		public var globalMatrices : Vector.<Number>;
		
		//buffer
		public var vertexBufferList : Vector.<VertexBuffer3D>;
		public var indexBufferList : Vector.<IndexBuffer3D>;
		public var uvBufferList : Vector.<VertexBuffer3D>;
		public var jointIndexList : Vector.<VertexBuffer3D>;
		public var jointWeightList : Vector.<VertexBuffer3D>;
		
		public var useCPU : Boolean = false;
		public var cpuAnimVertexRawData : Vector.<Number>;
		public var cpuAnimVertexBuffer : VertexBuffer3D;
		
		//动画信息
		public var numFrames : int;
		public var meshDataNum : int = 0;
		public var program : Program3D;
		
		public function MD5Result(context : Context3D)
		{
			this.context = context;
		}
		
		public function loadModel(data : ByteArray) : void
		{
			md5MeshParser.addEventListener(Event.COMPLETE, onLoadModelMesh);
			md5MeshParser.load(data);
		}
		
		public function loadAnim(data : ByteArray) : void
		{
			md5AnimParser.addEventListener(Event.COMPLETE, onLoadModelAnim);
			md5AnimParser.load(data);
		}
		
		private function onLoadModelAnim(e:Event) : void
		{
			numFrames = md5AnimParser.numFrames;
			hasAnim = true;
			if(!useCPU)createShader();
			this.dispatchEvent(new Event("animLoaded"));
		}
		
		private function onLoadModelMesh(e:Event) : void
		{
			uvBufferList = new Vector.<VertexBuffer3D>();
			indexBufferList = new Vector.<IndexBuffer3D>();
			vertexBufferList = new Vector.<VertexBuffer3D>();
			jointIndexList = new Vector.<VertexBuffer3D>();
			jointWeightList = new Vector.<VertexBuffer3D>();
			
			for each(var mesh : MeshData in md5MeshParser.md5_mesh){
				translateGeom(mesh);
				uvBufferList.push(mesh.uvBuffer);
				indexBufferList.push(mesh.indiceBuffer);
				vertexBufferList.push(mesh.vertexBuffer);
				jointIndexList.push(mesh.jointIndexBuffer);
				jointWeightList.push(mesh.jointWeightBuffer);
			}
			meshDataNum = md5MeshParser.md5_mesh.length;
			useCPU = md5MeshParser.md5_joint.length * 4 > 128;
			hasMesh = true;
			createShader();
			this.dispatchEvent(new Event("meshLoaded"));
		}
		
		private function translateGeom(meshData : MeshData) : void
		{
			meshData.uvRawData = meshData.getUv();
			meshData.uvBuffer = context.createVertexBuffer(meshData.uvRawData.length/2,2);
			meshData.uvBuffer.uploadFromVector(meshData.uvRawData,0,meshData.uvRawData.length/2);
			
			meshData.indiceRawData = meshData.getIndex();
			meshData.indiceBuffer = context.createIndexBuffer(meshData.indiceRawData.length);
			meshData.indiceBuffer.uploadFromVector(meshData.indiceRawData, 0, meshData.indiceRawData.length);
			
			//取出最大关节数
			var maxJointCount : int = md5MeshParser.maxJointCount;
			var vertexLen : int = meshData.md5_vertex.length;
			
			meshData.vertexRawData = new Vector.<Number>(vertexLen * maxJointCount, true);
			meshData.jointIndexRawData = new Vector.<Number>(vertexLen * maxJointCount, true);
			meshData.jointWeightRawData = new Vector.<Number>(vertexLen * maxJointCount, true);
			
			var vertexs : Vector.<Number> = meshData.vertexRawData;
			var jointIndices : Vector.<Number> = meshData.jointIndexRawData;
			var jointWeights : Vector.<Number> = meshData.jointWeightRawData;
			
			var nonZeroWeights : int;
			var l : int;
			var finalVertex : Vector3D;
			var vertex : MD5Vertex;
			for(var i : int = 0; i < vertexLen; i++)
			{
				finalVertex = new Vector3D();
				vertex = meshData.md5_vertex[i];
				nonZeroWeights = 0;
				//遍历每个顶点的总权重
				for(var j : int = 0; j < vertex.weight_count; j++)
				{
					//取出当前顶点的权重
					var weight : MD5Weight = meshData.md5_weight[vertex.weight_index + j];
					//取出当前顶点对应的关节
					var joint2 : MD5Joint = md5MeshParser.md5_joint[weight.jointID];
					
					//将权重转换为关节坐标系为参考的值
					var wv : Vector3D = joint2.bindPose.transformVector(weight.pos);
					//进行权重缩放
					wv.scaleBy(weight.bias);
					//输出转换后的顶点
					finalVertex = finalVertex.add(wv);
					
					jointIndices[l] = weight.jointID * 4;
					jointWeights[l++] = weight.bias;
					++nonZeroWeights;
				}
				
				for(j = nonZeroWeights; j < maxJointCount; ++j)
				{
					jointIndices[l] = 0;
					jointWeights[l++] = 0;
				}
				
				var startIndex : int = i * 3;
				vertexs[startIndex] = finalVertex.x; 
				vertexs[startIndex+1] = finalVertex.y; 
				vertexs[startIndex+2] = finalVertex.z; 
			}
			

			meshData.vertexBuffer = context.createVertexBuffer(vertexs.length/3,3);
			meshData.vertexBuffer.uploadFromVector(vertexs,0,vertexs.length/3);
			
			meshData.jointIndexBuffer = context.createVertexBuffer(jointIndices.length/maxJointCount, maxJointCount);
			meshData.jointIndexBuffer.uploadFromVector(jointIndices,0,jointIndices.length/maxJointCount);
			
			meshData.jointWeightBuffer = context.createVertexBuffer(jointWeights.length/maxJointCount, maxJointCount);
			meshData.jointWeightBuffer.uploadFromVector(jointWeights,0,jointWeights.length/maxJointCount);
		}
		
		private function createShader() : void
		{
			var vertexShader : AGALMiniAssembler;
			var fragmentShader : AGALMiniAssembler;
			
			var vertexStr : String;
			if(hasAnim){
				vertexStr = getAnimAgal();
			}else{
				vertexStr = "m44 op, va0, vc124 \n"+
					"mov v0, va1 \n";
			}
			
			vertexShader = new AGALMiniAssembler();
			vertexShader.assemble(Context3DProgramType.VERTEX, vertexStr);
			
			fragmentShader = new AGALMiniAssembler();
			fragmentShader.assemble(Context3DProgramType.FRAGMENT,
				//纹理采样
				"tex ft0, v0, fs0<2d, linear, repeat>\n" +
				"tex ft1, v0, fs1<2d, linear, repeat>\n" +
				//灯光点乘法线
				"dp3 ft2, ft1, fc2\n" +
				"neg ft2, ft2\n" + 
				"sat ft2, ft2\n"+
				
				//混合环境光
				"mul ft3, ft0, ft2\n" +
				//混合灯光颜色
				"mul ft3, ft3, fc1\n" +
				//输出
				"add oc, ft3, fc0");
			
			program = context.createProgram();
			program.upload(vertexShader.agalcode, fragmentShader.agalcode);
			
			bufferFormat = "float" + md5MeshParser.maxJointCount;
			
			globalMatrices = new Vector.<Number>(md5MeshParser.md5_joint.length * 16, true);
		}
		/**
		 * 基础帧vc
		 * 顶点va2
		 * 权重va3
		 * vc * va0 -> vt1 将基础帧位置混合当前顶点帧位置
		 * vt1 * va3 -> vt1 将基础帧乘以权重
		 * 将vt1 叠加到 vt2
		 * vt2 * vc124 将vt2转换到世界坐标
		 */
		private function getAnimAgal() : String
		{
			//顶点和权重
			var indexStream : String = "va2";
			var weightStream : String = "va3";
			var indices : Array = [ indexStream + ".x", indexStream + ".y", indexStream + ".z", indexStream + ".w" ];
			var weights : Array = [ weightStream + ".x", weightStream + ".y", weightStream + ".z", weightStream + ".w" ];
			
			var code : String = "";
			for(var j : int = 0; j < md5MeshParser.maxJointCount; ++j){
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
			
			return code;
		}
		
		private function cpuCalcJoint(meshIndex : int, view : Matrix3D) : void
		{
			var meshData : MeshData = md5MeshParser.md5_mesh[meshIndex];
			var vertexLen : int = meshData.md5_vertex.length;
			
			//当前索引
			var indices : Vector.<Number> = meshData.jointIndexRawData;
			//当前顶点
			var vertex : Vector.<Number> = meshData.vertexRawData;
			//当前权重
			var weight : Vector.<Number> = meshData.jointWeightRawData;
			
			var result : Vector3D = new Vector3D();
			var temp : Vector3D = new Vector3D();
			var curVert : Vector3D = new Vector3D();
			
			cpuAnimVertexRawData ||= new Vector.<Number>();
			cpuAnimVertexRawData.length = 0;
			
			var l : int = 0;
			for(var i : int = 0; i < vertexLen; i++)
			{
				var startIndex : int = i * 3;
				//初始化当前的顶点和索引
				curVert.setTo(vertex[startIndex],vertex[startIndex+1],vertex[startIndex+2]);
				result.setTo(0,0,0);
				for(var j : int = 0; j < md5MeshParser.maxJointCount; j++)
				{
					//当前索引对应的矩阵
					var curIndex : Number = indices[l];
					var curWeight : Number = weight[l];
					var curMatrix : Matrix3D = cpuAnimMatrix[curIndex];
					temp = curMatrix.transformVector(curVert);
					temp.scaleBy(curWeight);
					result = result.add(temp);
					l++;
				}

				cpuAnimVertexRawData.push(result.x,result.y,result.z);
			}
			
			cpuAnimVertexBuffer ||= context.createVertexBuffer(cpuAnimVertexRawData.length/3,3);
			cpuAnimVertexBuffer.uploadFromVector(cpuAnimVertexRawData,0,cpuAnimVertexRawData.length/3);
		}
		
		public function clearCpuData() : void
		{
			cpuAnimVertexBuffer = null;
		}
		
		/**
		 * 计算每帧动作
		 */
		public function prepareMesh(frame : int, meshIndex : int, view : Matrix3D) : void
		{
			//取出当前帧数据
			var frameData : MD5FrameData = md5AnimParser.frameData[frame];
			var meshData : MeshData = md5MeshParser.md5_mesh[meshIndex];
			
			CalcMeshAnim(frameData);
			if(useCPU){
				cpuCalcJoint(meshIndex, view);	
			}
		}
		
		private function CalcMeshAnim(frameData : MD5FrameData) : void
		{
			//取出关节数据
			var joints : Vector.<MD5Joint> = md5MeshParser.md5_joint;
			var jointsNum : int = joints.length;
			
			cpuAnimMatrix ||= new Vector.<Matrix3D>(jointsNum * 4, true);
			
			var joint : MD5Joint;
			var parentJoint : MD5Joint;
			for(var i : int = 0; i < jointsNum; i++)
			{
				//从基本帧开始偏移
				var baseFrame : MD5BaseFrameData = md5AnimParser.baseFrameData[i];
				var animatedPos : Vector3D = baseFrame.position;
				var animatedOrient : Quaternion = baseFrame.orientation;
				
				//将帧数据替换掉基本帧中对应的数据
				var hierachy : MD5HierarchyData = md5AnimParser.hierarchy[i];
				
				var flags : int = hierachy.flags;
				var j : int = 0;
				if(flags & 1) //tx
					animatedPos.x = frameData.components[hierachy.startIndex + j++];
				
				if(flags & 2) //ty
					animatedPos.y = frameData.components[hierachy.startIndex + j++];
				
				if(flags & 4)
					animatedPos.z = frameData.components[hierachy.startIndex + j++];
				
				if(flags & 8)
					animatedOrient.x = frameData.components[hierachy.startIndex + j++];
				
				if(flags & 16)
					animatedOrient.y = frameData.components[hierachy.startIndex + j++];
				
				if(flags & 32)
					animatedOrient.z = frameData.components[hierachy.startIndex + j++];
				
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
				if(useCPU){
					cpuAnimMatrix[vc] = matrix3D;
				}else{
					context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, vc, matrix3D, true);
				}
			}
		}
	}
}