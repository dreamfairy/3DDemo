package
{
	/**
	 * 测试正交投影
	 */
	import com.adobe.utils.AGALMiniAssembler;
	import com.adobe.utils.PerspectiveMatrix3D;
	
	import flash.display.Sprite;
	import flash.display.Stage3D;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.Program3D;
	import flash.events.Event;
	import flash.geom.Matrix3D;

	[SWF(width = "512", height = "512", frameRate="60")]
	public class OrthoTest extends Sprite
	{
		public function OrthoTest()
		{
			stage ? init() : addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null) : void
		{
			if(hasEventListener(Event.ADDED_TO_STAGE))
				removeEventListener(Event.ADDED_TO_STAGE, init);
			
			m_proj = new PerspectiveMatrix3D();
			m_proj.orthoRH(stage.stageWidth,stage.stageHeight,1,100);
//			m_proj.perspectiveFieldOfViewRH(45 * (Math.PI/180), stage.stageWidth / stage.stageHeight, 0.1, 1000);
			
			m_view = new Matrix3D();
			m_model = new Matrix3D();
			m_final = new Matrix3D();
			
			stage.stage3Ds[0].addEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
			stage.stage3Ds[0].requestContext3D();
		}
		
		private function onContextCreated(e:Event) : void
		{
			m_context = (e.target as Stage3D).context3D;
			m_context.configureBackBuffer(stage.stageWidth, stage.stageHeight, 2, true);
			m_context.enableErrorChecking = true;
			
			m_quad = createQuad("test");
			
			addEventListener(Event.ENTER_FRAME, onEnter);
		}
		
		private static function makeOrthoProjection(w:Number, h:Number, n:Number, f:Number):Matrix3D
		{
			return new Matrix3D(Vector.<Number>
				([
					2/w, 0  ,       0,        0,
					0  , 2/h,       0,        0,
					0  , 0  , 1/(f-n), -n/(f-n),
					0  , 0  ,       0,        1
				]));
		}
		
		private function onEnter(e:Event) : void
		{
			m_context.clear(.5,.5,.5);
			
			m_model.identity();
			m_model.appendScale(50,50,50);
			m_model.appendTranslation(stage.stageWidth/2,100,0);
			m_view.identity();
			m_view.appendTranslation(-stage.stageWidth/2,-stage.stageHeight/2,0);
			m_view.appendScale(1,-1,1);
			m_final.identity();
			m_final.append(m_model);
			m_final.append(m_view);
			m_final.append(m_proj);
			
			m_context.setProgram(shadowShader);
			m_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX,0,m_final, true);
			m_context.setVertexBufferAt(0,m_quad.vertexBuffer,0,Context3DVertexBufferFormat.FLOAT_3);
			m_context.setVertexBufferAt(1,m_quad.uvBuffer,0,Context3DVertexBufferFormat.FLOAT_2);
			m_context.drawTriangles(m_quad.indexBuffer);
			
			m_context.present();
		}
		
		private function get shadowShader() : Program3D
		{
			if(m_depthShader) return m_depthShader;
			
			var vertexStr : String = "m44 op, va0, vc0\n"+
				"mov v0, va1\n";
			
			var vertexProgram : AGALMiniAssembler = new AGALMiniAssembler();
			vertexProgram.assemble(Context3DProgramType.VERTEX,vertexStr);
			
			var fragmentStr : String = "mov oc, v0\n";
			
			var fragtmentProgram : AGALMiniAssembler = new AGALMiniAssembler();
			fragtmentProgram.assemble(Context3DProgramType.FRAGMENT,fragmentStr);
			
			m_depthShader = m_context.createProgram();
			m_depthShader.upload(vertexProgram.agalcode,fragtmentProgram.agalcode);
			
			return m_depthShader;
		}
		
		private function createQuad(name : String) : QuadInfo
		{
			var vertexList : Vector.<Number> = new Vector.<Number>();
			vertexList.push(-1,1,0);
			vertexList.push(1,1,0);
			vertexList.push(1,-1,0);
			vertexList.push(-1,-1,0);
			
			var indexList : Vector.<uint> = new Vector.<uint>();
			indexList.push(0,1,2);
			indexList.push(0,2,3);
			
			var uvList : Vector.<Number> = new Vector.<Number>();
			uvList.push(0,0,1,0,1,1,0,1);
			
			var normalList : Vector.<Number> = new Vector.<Number>();
			normalList.push(0,0,0,0,0,0,0,0,0,0,0,0);
			
			var quad : QuadInfo = new QuadInfo();
			quad.name = name;
			
			quad.vertexBuffer = m_context.createVertexBuffer(4,3);
			quad.vertexBuffer.uploadFromVector(vertexList,0,4);
			
			quad.indexBuffer = m_context.createIndexBuffer(6);
			quad.indexBuffer.uploadFromVector(indexList,0,6);
			
			quad.uvBuffer = m_context.createVertexBuffer(4,2);
			quad.uvBuffer.uploadFromVector(uvList,0,4);
			
			quad.normalBuffer = m_context.createVertexBuffer(4,3);
			quad.normalBuffer.uploadFromVector(normalList,0,4);
			
			return quad;
		}
		
		private var m_proj : PerspectiveMatrix3D;
		private var m_view : Matrix3D;
		private var m_model : Matrix3D;
		private var m_context : Context3D;
		private var m_quad : QuadInfo;
		private var m_depthShader : Program3D;
		private var m_final : Matrix3D;
	}
}

import flash.display3D.IndexBuffer3D;
import flash.display3D.VertexBuffer3D;
import flash.geom.Matrix3D;

class QuadInfo
{
	public var name : String;
	public var vertexBuffer : VertexBuffer3D;
	public var indexBuffer : IndexBuffer3D;
	public var uvBuffer : VertexBuffer3D;
	public var normalBuffer : VertexBuffer3D;
	public var transform : Matrix3D = new Matrix3D();
}