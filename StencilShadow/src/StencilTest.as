package
{
	import com.adobe.utils.AGALMiniAssembler;
	
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DStencilAction;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.Texture;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;

	public class StencilTest extends ContextBase
	{
		public function StencilTest()
		{
			super();
		}
		
		protected override function onCreateContext(e:Event) : void
		{
			super.onCreateContext(e);
			m_viewMatrix.identity();
			m_viewMatrix.appendTranslation(0,0,-10);
			
			setup();
			
			addEventListener(Event.ENTER_FRAME, onEnter);
		}
		
		private function onEnter(e:Event) : void
		{
			renderScene();
		}
		
		private function renderScene() : void
		{
			m_context.clear(0,0,0,1,1,0);
			
			m_context.setDepthTest(true,Context3DCompareMode.LESS);
			m_context.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK,
				Context3DCompareMode.ALWAYS, Context3DStencilAction.KEEP);
			drawBiggerCube();
			
			m_context.setDepthTest(false,Context3DCompareMode.LESS);
			m_context.setStencilReferenceValue(0);
			m_context.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK,
				Context3DCompareMode.EQUAL, Context3DStencilAction.INCREMENT_SATURATE);
				
			drawCube();
			
			m_context.setStencilReferenceValue(1);
			
			drawTriangle();
			m_context.present();
		}
		
		private function drawBiggerCube() : void
		{
			t += .1;
			m_modelMatrix.identity();
			m_modelMatrix.appendTranslation(0,0,-1);
			m_modelMatrix.appendScale(2,2,2);
			m_finalMatrix.identity();
			m_finalMatrix.append(m_modelMatrix);
			m_finalMatrix.append(m_viewMatrix);
			m_finalMatrix.append(m_projMatrix);
			
			m_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX,0,m_finalMatrix,true);
			
			m_context.setProgram(m_textureShader);
			m_context.setTextureAt(0,brickTexture);
			m_context.setVertexBufferAt(0, m_rectVertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			m_context.setVertexBufferAt(1,m_rectVertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_2);
			m_context.drawTriangles(m_rectIndexBuffer,0,2);
		}
		
		private function drawTriangle() : void
		{
			m_modelMatrix.identity();
			m_finalMatrix.identity();
			m_finalMatrix.append(m_modelMatrix);
			m_finalMatrix.append(m_viewMatrix);
			m_finalMatrix.append(m_projMatrix);
			
			m_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX,0,m_finalMatrix,true);
			
			m_context.setProgram(m_shader);
			m_context.setTextureAt(0,null);
			m_context.setVertexBufferAt(0, m_triangleVertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			m_context.setVertexBufferAt(1,null);
			m_context.drawTriangles(m_triangleIndexBuffer,0,1);
		}
		
		private var t : Number = 0.0;
		private function drawCube() : void
		{
			t += .1;
			m_modelMatrix.identity();
			m_modelMatrix.appendTranslation(Math.sin(t),0,0);
			m_finalMatrix.identity();
			m_finalMatrix.append(m_modelMatrix);
			m_finalMatrix.append(m_viewMatrix);
			m_finalMatrix.append(m_projMatrix);
			
			m_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX,0,m_finalMatrix,true);
			
			m_context.setProgram(m_textureShader);
			m_context.setTextureAt(0,texture);
			m_context.setVertexBufferAt(0, m_rectVertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			m_context.setVertexBufferAt(1,m_rectVertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_2);
			m_context.drawTriangles(m_rectIndexBuffer,0,2);
		}
		
		public function setup() : void
		{
			var triangleVertex : Vector.<Number> = new Vector.<Number>();
			triangleVertex.push(0,1,0);
			triangleVertex.push(1,0,0);
			triangleVertex.push(-1,0,0);
			
			var traiangleIndex : Vector.<uint> = new Vector.<uint>();
			traiangleIndex.push(0,1,2);
			
			m_triangleIndexBuffer = m_context.createIndexBuffer(traiangleIndex.length);
			m_triangleIndexBuffer.uploadFromVector(traiangleIndex,0,3);
			
			m_triangleVertexBuffer = m_context.createVertexBuffer(3,3);
			m_triangleVertexBuffer.uploadFromVector(triangleVertex,0,3);
			
			var rectVertex : Vector.<Number> = new Vector.<Number>();
			rectVertex.push(-1,1,0,0,0);
			rectVertex.push(1,1,0,1,0);
			rectVertex.push(1,-1,0,1,1);
			rectVertex.push(-1,-1,0,0,1);
			
			var rectIndex : Vector.<uint> = new Vector.<uint>();
			rectIndex.push(0,1,2,0,2,3);
			
			m_rectIndexBuffer = m_context.createIndexBuffer(rectIndex.length);
			m_rectIndexBuffer.uploadFromVector(rectIndex,0,rectIndex.length);
			
			m_rectVertexBuffer = m_context.createVertexBuffer(4,5);
			m_rectVertexBuffer.uploadFromVector(rectVertex,0,4);
			
			m_shader = m_context.createProgram();
			m_textureShader = m_context.createProgram();
			
			var vertex : AGALMiniAssembler = new AGALMiniAssembler();
			vertex.assemble(Context3DProgramType.VERTEX,
				[
					"m44 op, va0, vc0",
					"mov v0, va0"
					].join("\n"));
			
			var fragment : AGALMiniAssembler = new AGALMiniAssembler();
			fragment.assemble(Context3DProgramType.FRAGMENT,
				[
					"mov oc, v0"
					].join("\n"));
			
			var textureVertex : AGALMiniAssembler = new AGALMiniAssembler();
			textureVertex.assemble(Context3DProgramType.VERTEX,
				[
					"m44 op, va0, vc0",
					"mov v1, va1"
				].join("\n"));
			
			var textureFragment : AGALMiniAssembler = new AGALMiniAssembler();
			textureFragment.assemble(Context3DProgramType.FRAGMENT,
				[
					"tex ft0,v1,fc0<2d,wrap,linear>",
					"mov oc,ft0"
					].join("\n"));
			
			m_shader.upload(vertex.agalcode, fragment.agalcode);
			m_textureShader.upload(textureVertex.agalcode,textureFragment.agalcode);
			
			texture = Utils.getTexture(textureData, m_context);
			brickTexture = Utils.getTexture(brickData, m_context);
		}
		
		private var m_triangleIndexBuffer : IndexBuffer3D;
		private var m_triangleVertexBuffer : VertexBuffer3D;
		private var m_rectIndexBuffer : IndexBuffer3D;
		private var m_rectVertexBuffer : VertexBuffer3D;
		private var m_shader : Program3D;
		private var m_textureShader : Program3D;
		private var m_modelMatrix : Matrix3D = new Matrix3D();
		
		[Embed(source="../source/seber.jpg")]
		private var textureData : Class;
		private var texture : Texture;
		
		[Embed(source="../source/brick0.jpg")]
		private var brickData : Class;
		private var brickTexture : Texture;
	}
}