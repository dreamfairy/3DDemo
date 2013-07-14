package
{
	import com.adobe.utils.AGALMiniAssembler;
	
	import flash.display3D.Context3DProgramType;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.ui.Keyboard;

	[SWF(width = "1024", height = "1024", frameRate="60")]
	public class Picking extends ContextBase
	{
		public function Picking()
		{
			super();
		}
		
		protected override function onCreateContext(e:Event):void
		{
			super.onCreateContext(e);
			
			createTriangle();
			createShader();
			createCamera();
			
			m_modelPos = new Vector3D(0,0,-10);
			stage.addEventListener(Event.ENTER_FRAME, onEnter);
			stage.addEventListener(MouseEvent.CLICK, onClick);
		}
		
		private function onClick(e:MouseEvent) : void
		{
			var xUnit : Number = (stage.mouseX * 2 / stage.stageWidth) - 1.0;
			var yUnit : Number = -((stage.mouseY * 2 / stage.stageHeight) - 1.0);
			
			var rayOrigin : Vector3D = new Vector3D();
			var rayDir : Vector3D = new Vector3D();
			
			trace(xUnit,yUnit);
//			getPickingRay(xUnit,yUnit,rayOrigin,rayDir);
		}
		
		private function createCamera() : void
		{
			m_cameraPos = new Vector3D();
			m_viewDir = new Vector3D();
			m_rightDir = new Vector3D();
			m_realUpDir = new Vector3D();
			m_upDir = new Vector3D(0,1,0);
			m_upDir.normalize();
		}
		
		public function get viewMatrix() : Matrix3D
		{
			var viewDir : Vector3D = m_viewDir;
//			viewDir.x = m_modelPos.x - m_cameraPos.x;
//			viewDir.y = m_modelPos.y - m_cameraPos.y;
//			viewDir.z = m_modelPos.z - m_cameraPos.z;
			viewDir.x = 0;
			viewDir.y = 0;
			viewDir.z = -10;
			m_viewDirMag = m_viewDir.normalize();
			
			//右方向 垂直于 视野方向和上方向 叉乘
			m_rightDir.x = m_viewDir.y * m_upDir.z - m_viewDir.z * m_upDir.y;
			m_rightDir.y = m_viewDir.z * m_upDir.x - m_viewDir.x * m_upDir.z;
			m_rightDir.z = m_viewDir.x * m_upDir.y - m_viewDir.y * m_upDir.x;
			
			//真实上方向 垂直于 右方向和视野方向 叉乘
			m_realUpDir.x = m_rightDir.y * m_viewDir.z - m_rightDir.z * m_viewDir.y;
			m_realUpDir.y = m_rightDir.z * m_viewDir.x - m_rightDir.x * m_viewDir.z;
			m_realUpDir.z = m_rightDir.x * m_viewDir.y - m_rightDir.y * m_viewDir.x;
			
			var worldViewMatrix : Matrix3D = new Matrix3D();
			var rawData : Vector.<Number> = worldViewMatrix.rawData;
			//相机坐标
			rawData[0] = 1;
			rawData[1] = 0;
			rawData[2] = 0;
			rawData[3] = -m_cameraPos.x;
			rawData[4] = 0;
			rawData[5] = 1;
			rawData[6] = 0;
			rawData[7] = -m_cameraPos.y;
			rawData[8] = 0;
			rawData[9] = 0;
			rawData[10] = 1;
			rawData[11] = -m_cameraPos.z;
			rawData[12] = 0;
			rawData[13] = 0;
			rawData[14] = 0;
			rawData[15] = 1;
			
			worldViewMatrix.rawData = rawData;
			
			var tempWorldViewMatrix : Matrix3D = new Matrix3D();
			rawData = tempWorldViewMatrix.rawData;
			
			//相机角度
			rawData[0] = m_rightDir.x;
			rawData[1] = m_rightDir.y;
			rawData[2] = m_rightDir.z;
			rawData[3] = 0;
			rawData[4] = m_realUpDir.x;
			rawData[5] = m_realUpDir.y;
			rawData[6] = m_realUpDir.z;
			rawData[7] = 0;
			rawData[8] = -viewDir.x;
			rawData[9] = -viewDir.y;
			rawData[10] = -viewDir.z;
			rawData[11] = 0;
			rawData[12] = 0;
			rawData[13] = 0;
			rawData[14] = 0;
			rawData[15] = 1;
			
			tempWorldViewMatrix.rawData = rawData;
			tempWorldViewMatrix.invert();
			
			worldViewMatrix.prepend(tempWorldViewMatrix);
//			var temp : Matrix3D = new Matrix3D();
//			temp.appendTranslation(m_cameraPos.x,m_cameraPos.y,m_cameraPos.z);
//			temp.pointAt(m_modelPos,CAM_FACING,CAM_UP);
//			temp.invert();
			return worldViewMatrix;
		}
		
		//获取射线
		private function getPickingRay(xUnit : Number, yUnit : Number, intoOrigin : Vector3D, intoDir : Vector3D) : void
		{
			//射线起点为相机位置
			intoOrigin = m_cameraPos;
			intoOrigin.w = 1;
			
			var nearPlaneHeight : Number = m_zNear * Math.tan(m_fov);
			var nearPlaneWidth : Number = nearPlaneHeight * (stage.stageWidth/stage.stageHeight);
			
			var rightOffset : Number = xUnit * nearPlaneWidth;
			var upOffset : Number = yUnit * nearPlaneHeight;
			
			// dir = viewDir*near + rightDir*rightOffset + realUpDir*upOffset
			intoDir.x = m_viewDir.x*m_zNear + m_rightDir.x*rightOffset + m_realUpDir.x*upOffset;
			intoDir.y = m_viewDir.y*m_zNear + m_rightDir.y*rightOffset + m_realUpDir.y*upOffset;
			intoDir.z = m_viewDir.z*m_zNear + m_rightDir.z*rightOffset + m_realUpDir.z*upOffset;
			intoDir.w = 0;
			intoDir.normalize();
			
			var disc : Number = intersectRay(intoOrigin,intoDir);
			if(disc)trace("碰撞",disc);
		}
		
		//射线相交
		private function intersectRay(origin : Vector3D, dir : Vector3D) : Number
		{
			var temp : Vector3D = new Vector3D();
			var radius : int = 2;
			
			//计算和物体的距离
			temp.x = origin.x - m_modelPos.x;
			temp.y = origin.y - m_modelPos.y;
			temp.z = origin.z - m_modelPos.z;
			
			var a : Number = dir.dotProduct(dir);
			var b : Number = 2 * dir.dotProduct(temp);
			var c : Number = temp.dotProduct(temp) - radius * radius;
			
			//b2 - 4ac
			var disc : Number = b * b - 4 * a *c;
			
			return disc >= 0 ? (-b - Math.sqrt(disc))/(2*a) : NaN;
		}
		
		private function createTriangle() : void
		{
			m_vertexRawData = new Vector.<Number>();
			m_vertexRawData.push(-1,1,0,0,0);
			m_vertexRawData.push(1,1,0,0,1);
			m_vertexRawData.push(0,-1,0,1,1);
			
			m_indexRawData = new Vector.<uint>();
			m_indexRawData.push(0,1,2);
			
			m_vertexBuffer = m_context.createVertexBuffer(3,5)
			m_vertexBuffer.uploadFromVector(m_vertexRawData,0,3);
			
			m_indexBuffer = m_context.createIndexBuffer(3);
			m_indexBuffer.uploadFromVector(m_indexRawData,0,3);
			
			m_modelMatrix = new Matrix3D();
		}
		
		private function createShader() : void
		{
			var vertexShader : AGALMiniAssembler = new AGALMiniAssembler();
			vertexShader.assemble(Context3DProgramType.VERTEX,
				"m44 op va0 vc0\n"+
				"mov v0 va1\n");
			
			var fragmengShader : AGALMiniAssembler = new AGALMiniAssembler();
			fragmengShader.assemble(Context3DProgramType.FRAGMENT,
				"mov oc v0\n");
			
			m_program = m_context.createProgram();
			m_program.upload(vertexShader.agalcode,fragmengShader.agalcode);
		}
		
		private function onEnter(e:Event) : void
		{
			m_context.clear();
			m_context.setProgram(m_program);
			
			m_modelMatrix.identity();
			m_modelMatrix.appendTranslation(m_modelPos.x,m_modelPos.y,m_modelPos.z);
			
			m_finalMatrix.identity();
			m_finalMatrix.append(m_modelMatrix);
			m_finalMatrix.append(m_worldMatrix);
			m_finalMatrix.append(viewMatrix);
			m_finalMatrix.append(m_projMatrix);
			
			m_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX,0,m_finalMatrix,true);
			m_context.setVertexBufferAt(0,m_vertexBuffer,0,"float3");
			m_context.setVertexBufferAt(1,m_vertexBuffer,3,"float2");
			m_context.drawTriangles(m_indexBuffer);
			
			m_context.present();
			renderKeyBoard();
		}
		
		protected override function renderKeyBoard():void
		{
			if(m_key[Keyboard.LEFT])
				m_modelPos.x -= .1;
			
			if(m_key[Keyboard.RIGHT])
				m_modelPos.x += .1;
		}
		
		private var m_vertexRawData : Vector.<Number>;
		private var m_indexRawData : Vector.<uint>;
		private var m_vertexBuffer : VertexBuffer3D;
		private var m_indexBuffer : IndexBuffer3D;
		private var m_modelMatrix : Matrix3D;
		
		//相机部分
		private var m_viewDir : Vector3D;
		private var m_rightDir : Vector3D;
		private var m_realUpDir : Vector3D;
		private var m_upDir : Vector3D;
		private var m_cameraPos : Vector3D;
		private var m_viewDirMag : Number;
		private var m_modelPos : Vector3D;
		
		private var m_program : Program3D;
	}
}