package C3.Mesh.SkyBox
{
	import com.adobe.utils.AGALMiniAssembler;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Context3DVertexBufferFormat;
	
	import C3.Object3D;
	import C3.Camera.Camera;
	import C3.Material.IMaterial;
	
	public class SkyBoxBase extends Object3D
	{
		public function SkyBoxBase(name:String, mat:IMaterial, size : int = 10)
		{
			super(name, mat);
			m_size = size >> 1;
			setup();
		}
		
		private function setup() : void
		{
			var vertexList : Vector.<Number> = new Vector.<Number>();
			vertexList.push(-m_size,-m_size,m_size);
			vertexList.push(-m_size,m_size,m_size);
			vertexList.push(m_size,-m_size,m_size);
			vertexList.push(m_size,m_size,m_size);
			
			vertexList.push(-m_size,m_size,-m_size);
			vertexList.push(m_size,m_size,-m_size);
			vertexList.push(-m_size,-m_size,-m_size);
			vertexList.push(m_size,-m_size,-m_size);
			
			vertexList.push(-m_size,-m_size,m_size);
			vertexList.push(m_size,-m_size,m_size);
			vertexList.push(m_size,-m_size,-m_size);
			vertexList.push(m_size,m_size,-m_size);
			
			vertexList.push(-m_size,-m_size,-m_size);
			vertexList.push(-m_size,m_size,-m_size);
			
			vertexRawData = vertexList;
			
			var indexList : Vector.<uint> = new Vector.<uint>();
			indexList.push(
				0, 1, 2,
				2, 1, 3,
				1, 4, 3,
				3, 4, 5,
				4, 6, 5,
				5, 6, 7,
				6, 8, 7,
				7, 8, 9,
				2, 3, 10,
				10, 3, 11,
				12, 13, 0,
				0, 13, 1);
			m_numTriangles = indexList.length/3;
			indexRawData = indexList;
		}
		
		public override function render(context:Context3D, camera:Camera):void
		{
			m_context = context;
			m_camera = camera;
			
			checkBuffer();
			
			if(m_transformDirty)
				updateTransform();
			
			Camera.TEMP_FINAL_MATRIX.identity();
			Camera.TEMP_FINAL_MATRIX.append(camera.projectMatrix);
			
//			var parent : Object3DContainer = m_parent;
//			while(null != parent){
//				parent.isRoot ? m_finalMatrix.append(parent.projMatrix) : parent.appendChildMatrix(m_finalMatrix);
//				parent = parent.parent;
//			}
			
			//渲染材质
			if(!m_program)
				createProgram(m_context);
			
			m_context.setCulling(Context3DTriangleFace.NONE);
			m_context.setDepthTest(false,Context3DCompareMode.LESS);
			m_context.setProgram(m_program);
			m_context.setTextureAt(0,m_material.getTexture(m_context));
			m_context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT,0,m_material.getMatrialData());
			m_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 124, Camera.TEMP_FINAL_MATRIX, true);
			m_context.setVertexBufferAt(0, m_vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			m_context.drawTriangles(m_indexBuffer,0,m_numTriangles);
			
			m_context.setTextureAt(0,null);
			m_context.setCulling(Context3DTriangleFace.NONE);
			m_context.setDepthTest(true,Context3DCompareMode.LESS);
		}
		
		protected override function createProgram(context3D:Context3D):void
		{
			var vertexProgram : AGALMiniAssembler = new AGALMiniAssembler();
			vertexProgram.assemble(Context3DProgramType.VERTEX,
				"m44 op va0 vc124\n"+
				"nrm vt0.xyz va0.xyz\n"+
				"mov vt0.w vc0.x\n"+
				"mov v0 vt0\n");
			
			var fragmentProgram : AGALMiniAssembler = new AGALMiniAssembler();
			fragmentProgram.assemble(Context3DProgramType.FRAGMENT,
				m_material.getFragmentStr(null));
			
			m_program = context3D.createProgram();
			m_program.upload(vertexProgram.agalcode,fragmentProgram.agalcode);
		}
		
		private var m_size : int;
	}
}