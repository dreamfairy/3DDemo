package C3.Core.Managers
{
	import flash.display.BitmapData;
	import flash.display.Stage3D;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.events.Event;
	import flash.geom.Matrix3D;
	import flash.geom.Rectangle;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	
	import C3.Object3D;
	import C3.Object3DContainer;
	import C3.View;
	import C3.Camera.Camera;
	import C3.Material.Shaders.ShaderHitObject;
	import C3.Mesh.IMesh;

	public class PickRender
	{
		/**
		 * 创建一个context 来绘制像素采集图
		 */
		private var m_context : Context3D;
		
		private var m_lastHit : Object3D;
		private var m_initialzed : Boolean;
		private var m_drawRect : Rectangle = new Rectangle(0,0,1,1);
		private var m_viewportData : Vector.<Number> = new Vector.<Number>(4,true);
		private var m_mouseCoordX : Number;
		private var m_mouseCoordY : Number;
		private var m_viewMatrix : Matrix3D = new Matrix3D();
		private var m_modelViewMatrix : Matrix3D = new Matrix3D();
		private var m_finalMatrix : Matrix3D = new Matrix3D();
		private var m_bitmapData : BitmapData;
		private var m_lastProgram : Program3D;
		private var m_shader : ShaderHitObject;
		
		public function PickRender()
		{
		}
		
		public function set mouseCoordX(value : Number) : void
		{
			m_mouseCoordX = value;
		}
		
		public function get lastHit() : Object3D
		{
			return m_lastHit;
		}
		
		public function get mouseCoordX() : Number
		{
			return m_mouseCoordX;
		}
		
		public function set mouseCoordY(value : Number) : void
		{
			m_mouseCoordY = value;
		}
		
		public function get mouseCoordY() : Number
		{
			return m_mouseCoordY;
		}
		
		public function getBitmapData() : BitmapData
		{
			return m_bitmapData;
		}
		
		private function onContextCreated(e:Event) : void
		{
			m_context = View.contextList[1] = (e.target as Stage3D).context3D;
			m_initialzed = false;
			initInternal();
		}
		
		private function initInternal() : void
		{
			m_bitmapData = new BitmapData(1,1,false,0x00000000);
			m_shader = new ShaderHitObject();
		}
		
		public function render(view : View, camera : Camera) : void
		{
			m_lastHit = null;
			
			if(m_context == null)
			{
				if(View.contextList[2] == null)
				{
					view.stage.stage3Ds[1].addEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
					view.stage.stage3Ds[1].requestContext3D();
					view.stage.stage3Ds[1].x = -50;
					view.stage.stage3Ds[1].y = -50;
					return;
				}else{
					m_context = View.contextList[1];
					view.stage.stage3Ds[1].addEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
					view.stage.stage3Ds[1].x = -50;
					view.stage.stage3Ds[1].y = -50;
				}
			}
			
			if(!m_initialzed)
			{
				m_context.configureBackBuffer(50,50,0,true);
				m_context.enableErrorChecking = true;
				m_initialzed = true;
			}
			
			var renderObject : Object3D;
			var mesh : IMesh;
			var vertexBuffer : VertexBuffer3D;
			var subMeshLen : uint;
			var subMeshIndex : uint;
			var program : Program3D;
			var subMesh : IMesh;
			
			//清除缓冲
			m_context.clear(0,0,0,0);
			m_context.setScissorRectangle(m_drawRect); 
			m_context.setCulling(Context3DTriangleFace.NONE);
//			//关闭混合模式
			m_context.setBlendFactors(Context3DBlendFactor.ONE,Context3DBlendFactor.ZERO);
			m_context.setColorMask(true,true,true,true);
			m_context.setDepthTest(true, Context3DCompareMode.LESS);
			//将鼠标所在的画笔偏移到0,0坐标系下
			m_viewportData[2] = camera.viewport.width;
			m_viewportData[3] = camera.viewport.height;
			m_viewportData[0] = 1 - (m_mouseCoordX / camera.viewport.width) * 2;
			m_viewportData[1] = (m_mouseCoordY / camera.viewport.height) * 2 - 1;
			
			m_context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4 , m_viewportData, 1);
			
			//获取需要渲染的目标
			var renderableSet : Vector.<Object3D> = view.scene.children;
			var len : uint = renderableSet.length;
			if(len == 1){
				renderableSet = Object3DContainer(view.scene.children[0]).children;
				len = renderableSet.length;
			}

			for(var i : int = 0; i < len; i++)
			{
				renderObject = renderableSet[i];
				//如果目标不可见，或者不可拣选，则跳过不渲染
				if(!renderObject.pickEnabled || !renderObject.visible) continue;
				
				m_finalMatrix.identity();
				m_finalMatrix.append(renderObject.matrixGlobal);
				m_finalMatrix.append(camera.getViewMatrix());
				m_finalMatrix.append(camera.projectMatrix);
				
				m_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, m_finalMatrix, true);
				
				var selectionIndex : uint = i + 1;
				
				//将拣选索引分割到4个浮点坐标点中
				var fragmentColor : Vector.<Number> = Vector.<Number>([
					(((selectionIndex) % 32) << 3) / 255.0,
					(((selectionIndex >> 5) % 32) << 3) / 255.0,
					(((selectionIndex >> 10) % 32) << 3) / 255.0,1
				]);
				
				m_context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, fragmentColor, 1);
				
				program = m_shader.getProgram(m_context);
				
				if(program != m_lastProgram){
					m_context.setProgram(program);
					m_lastProgram = program;
				}
				
				//设置顶点流
				setStreamsFromShader(renderObject, m_context);
				
				m_context.drawTriangles(renderObject.getIndexBufferByContext(m_context), 0, renderObject.numTriangles);
			}
			
			//绘制单个像素到位图
			m_context.drawToBitmapData(m_bitmapData);
			//获取拣选颜色
			var selectedIndexColor : uint = m_bitmapData.getPixel(0,0);
			//查抄选中目标的索引
			var red : uint = (selectedIndexColor >> 16) & 0xFF;
			var green : uint = (selectedIndexColor >> 8) & 0xFF;
			var blue : uint = (selectedIndexColor) & 0xFF;
			var selectedIndex : uint = ((red / 8.0)) + ((green / 8.0) << 5) + ((blue / 8.0) << 10);
			
			if(selectedIndex != 0 && selectedIndex <= len && renderableSet[selectedIndex - 1].interactive)
			{
				m_lastHit = renderableSet[selectedIndex - 1];
			}else{
				m_lastHit = null;
			}
			
			if(m_lastHit && m_lastHit.buttonMode)Mouse.cursor = MouseCursor.BUTTON;
			else Mouse.cursor = MouseCursor.AUTO;
			
			m_lastProgram = null;
			
			//如果有对象被选中，计算包围盒的偏移值, 略过
			m_context.present();
		}
		
		private function setStreamsFromShader(target : Object3D, context3D : Context3D) : void
		{
			m_context.setVertexBufferAt(0,target.getVertexBufferByContext(context3D),0,Context3DVertexBufferFormat.FLOAT_3);
		}
	}
}