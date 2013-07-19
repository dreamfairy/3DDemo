package C3.Mesh
{
	import com.adobe.utils.AGALMiniAssembler;
	
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	
	import C3.Object3D;
	import C3.Object3DContainer;
	import C3.View;
	import C3.Material.IMaterial;
	
	public class CubeMesh extends Object3D
	{
		public function CubeMesh(name:String, size : int = 100, mat:IMaterial)
		{
			super(name, mat);
			m_size = size;
			
			calcVertex(m_size);
		}
		
		private function calcVertex(size : uint) : void
		{
			var halfSize : uint = size >> 1;
			var vertexList : Vector.<Number> = new Vector.<Number>();
			
			//front
			
			//left top
			vertexList.push(-halfSize,halfSize,halfSize);
			//right top
			vertexList.push(halfSize,halfSize,halfSize);
			//right bottom
			vertexList.push(halfSize,halfSize,halfSize);
			//left bottom
			vertexList.push(-halfSize,-halfSize,halfSize);
			
			//back
			
			//left top
			vertexList.push(-halfSize,halfSize,-halfSize);
			//right top
			vertexList.push(halfSize,halfSize,-halfSize);
			//right bottom
			vertexList.push(halfSize,halfSize,-halfSize);
			//left bottom
			vertexList.push(-halfSize,-halfSize,-halfSize);
			
			vertexRawData = vertexList;
			
			calcIndices();
			calcNormal();
		}
		
		private function calcIndices() : void
		{
//			var indexList : Vector.<uint> = new Vector.<uint>();
			//+x
			//-x
			//+y
			//-y
			//+z
			//-z
		}
		
		private function calcNormal() : void
		{
			
		}
		
		public override function render():void
		{
			checkBuffer();
			
			if(m_transformDirty)
				updateTransform();
			
			m_finalMatrix.identity();
			m_finalMatrix.append(m_transform);
			
			var parent : Object3DContainer = m_parent;
			while(null != parent){
				parent.isRoot ? m_finalMatrix.append(parent.projMatrix) : parent.appendChildMatrix(m_finalMatrix);
				parent = parent.parent;
			}
			
			//渲染材质
			if(!m_program)
				createProgram();
			
			View.context.setProgram(m_program);
			
			View.context.setTextureAt(0,m_material.getTexture());
			
			View.context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT,0,m_material.getMatrialData());
			
			View.context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 124, m_finalMatrix, true);
			
			View.context.setVertexBufferAt(0, m_vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			
			View.context.drawTriangles(m_indexBuffer,0,m_numTriangles);
			
			View.context.setTextureAt(0, null);
		}
		
		protected override function createProgram():void
		{
			var vertexProgram : AGALMiniAssembler = new AGALMiniAssembler();
			vertexProgram.assemble(Context3DProgramType.VERTEX,
				"m44 vt0, va0, vc124\n"+
				"nrm v0.xyz, vt0.xyz\n"+
				"mov op vt0\n");
			
			var fragmentProgram : AGALMiniAssembler = new AGALMiniAssembler();
			fragmentProgram.assemble(Context3DProgramType.FRAGMENT,
				m_material.getFragmentStr(null));
			
			m_program = View.context.createProgram();
			m_program.upload(vertexProgram.agalcode,fragmentProgram.agalcode);
		}
		
		private var m_size : int;
	}
}