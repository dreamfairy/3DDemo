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
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	
	import flashx.textLayout.events.UpdateCompleteEvent;

	/**
	 * MD5结果
	 */
	public class MD5Result extends EventDispatcher
	{
		public var context : Context3D;
		
		/**MD5模型**/
		public var hasMesh : Boolean;
		
		private var md5MeshParser : MD5MeshParser = new MD5MeshParser();
		
		/**转换信息**/
		private var vertexs : Vector.<Number>;
		private var uvIndices : Vector.<Number>;
		private var indices : Vector.<uint>;
		
		//buffer
		public var indexBuffer : IndexBuffer3D;
		public var vertexBuffer : VertexBuffer3D;
		public var uvBuffer : VertexBuffer3D;
		
		/**骨骼及权重**/
		public var jointIndices : Vector.<Number>;
		public var jointWeights : Vector.<Number>;
		public var jointIndicesBuffer : VertexBuffer3D;
		public var jointWeightsBuffer : VertexBuffer3D;
		
		/**索引和权重长度**/
		public var bufferFormat : String;
		public var globalMatrices : Vector.<Number>;
		
		//test
		public var vertexBufferList : Vector.<VertexBuffer3D>;
		public var indexBufferList : Vector.<IndexBuffer3D>;
		public var uvBufferList : Vector.<VertexBuffer3D>;
		
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
		
		private function onLoadModelMesh(e:Event) : void
		{
			for each(var mesh : MeshData in md5MeshParser.md5_mesh){
				translateGeom(mesh);
			}
			meshDataNum = md5MeshParser.md5_mesh.length;
			hasMesh = true;
			createShader();
			this.dispatchEvent(new Event("meshLoaded"));
		}
		
		private function translateGeom(meshData : MeshData) : void
		{
//			uvIndices = meshData.getUv();
//			uvBuffer = context.createVertexBuffer(uvIndices.length/2,2);
//			uvBuffer.uploadFromVector(uvIndices,0,uvIndices.length/2);
			
//			indices = meshData.getIndex();
//			indexBuffer = context.createIndexBuffer(indices.length);
//			indexBuffer.uploadFromVector(indices, 0, indices.length);
			
			uvBufferList ||= new Vector.<VertexBuffer3D>();
			var uvIndicesTemp : Vector.<Number> = meshData.getUv();
			var uvBufferTemp : VertexBuffer3D = context.createVertexBuffer(uvIndicesTemp.length/2,2);
			uvBufferTemp.uploadFromVector(uvIndicesTemp,0,uvIndicesTemp.length/2);
			uvBufferList.push(uvBufferTemp);
			
			indexBufferList ||= new Vector.<IndexBuffer3D>();
			var indicesTemp : Vector.<uint> = meshData.getIndex();
			var indexBufferTemp : IndexBuffer3D = context.createIndexBuffer(indicesTemp.length);
			indexBufferTemp.uploadFromVector(indicesTemp, 0, indicesTemp.length);
			indexBufferList.push(indexBufferTemp);
			
			//取出最大关节数
			var maxJointCount : int = md5MeshParser.maxJointCount;
			
			vertexs = new Vector.<Number>();
			var vertexLen : int = meshData.md5_vertex.length;
			jointIndices = new Vector.<Number>(vertexLen * maxJointCount, true);
			jointWeights = new Vector.<Number>(vertexLen * maxJointCount, true);
			
			var nonZeroWeights : int;
			var l : int;
			var finalVertex : Vector3D;
			var vertex : MD5Vertex;
			for(var i : int = 0; i < vertexLen; i++)
			{
				finalVertex = new Vector3D();
				vertex = meshData.md5_vertex[i];
				nonZeroWeights = 0;
				for(var j : int = 0; j < vertex.weight_count; j++)
				{
					var weight : MD5Weight = meshData.md5_weight[vertex.weight_index + j];
					var joint2 : MD5Joint = md5MeshParser.md5_joint[weight.jointID];
					
					var wv : Vector3D = joint2.bindPose.transformVector(weight.pos);
					wv.scaleBy(weight.bias);
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
				
				vertexs.push(finalVertex.x,finalVertex.y,finalVertex.z);
			}
			
//			vertexBuffer = context.createVertexBuffer(vertexs.length/3,3);
//			vertexBuffer.uploadFromVector(vertexs,0,vertexs.length/3);
			
			vertexBufferList ||= new Vector.<VertexBuffer3D>();
			var vertexBufferTemp : VertexBuffer3D = context.createVertexBuffer(vertexs.length/3,3);
			vertexBufferTemp.uploadFromVector(vertexs,0,vertexs.length/3);
			vertexBufferList.push(vertexBufferTemp);
			
			//创建关节索引和权重buffer
//			jointIndicesBuffer = context.createVertexBuffer(jointIndices.length/maxJointCount, maxJointCount);
//			jointIndicesBuffer.uploadFromVector(jointIndices,0,jointIndices.length/maxJointCount);
//			
//			jointWeightsBuffer = context.createVertexBuffer(jointWeights.length/maxJointCount, maxJointCount);
//			jointWeightsBuffer.uploadFromVector(jointWeights,0,jointWeights.length/maxJointCount);
		}
		
		private function createShader() : void
		{
			var vertexShader : AGALMiniAssembler;
			var fragmentShader : AGALMiniAssembler;
			
			var vertexStr : String;
			vertexStr = "m44 op, va0, vc124 \n"+
				"mov v0, va1";
			
			vertexShader = new AGALMiniAssembler();
			vertexShader.assemble(Context3DProgramType.VERTEX, vertexStr);
			
			fragmentShader = new AGALMiniAssembler();
			fragmentShader.assemble(Context3DProgramType.FRAGMENT,
				"tex ft0, v0, fs0<2d, linear, repeat>\n" +
				"mov oc, ft0");
			
			program = context.createProgram();
			program.upload(vertexShader.agalcode, fragmentShader.agalcode);
			
			bufferFormat = "float" + md5MeshParser.maxJointCount;
			
			globalMatrices = new Vector.<Number>(md5MeshParser.md5_joint.length * 16, true);
		}
	}
}