package C3
{
	import com.adobe.utils.AGALMiniAssembler;
	
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.Stage3D;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.Program3D;
	import flash.display3D.textures.TextureBase;
	import flash.events.Event;
	import flash.geom.Matrix3D;
	import flash.geom.Rectangle;
	
	import C3.Camera.Camera3D;
	import C3.Camera.ICamera;
	import C3.Core.Managers.MaterialManager;
	import C3.Core.Managers.PickManager;
	import C3.Material.Shaders.Shader;
	import C3.Material.Shaders.ShaderDepthMap;
	import C3.Mesh.SkyBox.SkyBoxBase;
	import C3.PostRender.IPostRender;

	public class View extends Sprite implements IDispose
	{
		public function View(width : int, height : int, enableErrorCheck : Boolean)
		{
			m_width = width;
			m_height = height;
			m_enableErrorCheck = enableErrorCheck;
			
			m_camera = new Camera3D(
				0.001, //near
				1000.0, //far
				600/600, //aspect
				45, //fov
				0,0,0, //pos
				0,0,-1, //target
				0,1,0 //upDir
			);
			
			m_postRenderList = new Vector.<IPostRender>();
			m_modelList = new Vector.<Object3D>();
			
			m_rootContainer = new Object3DContainer("scene",null);
			m_rootContainer.isRoot = true;
			m_rootContainer.view = this;
			
			m_pickManager = new PickManager(this);
			
			addEventListener(Event.ADDED_TO_STAGE, addedToStage);
		}
		
		public function get camera() : ICamera
		{
			return m_camera;
		}
		
		public function set camera(camera : ICamera) : void
		{
			m_camera = camera;
		}
		
		private function addedToStage(e:Event) : void
		{
			if(hasEventListener(Event.ADDED_TO_STAGE))
				removeEventListener(Event.ADDED_TO_STAGE,addedToStage);
			
			stage.stage3Ds[0].addEventListener(Event.CONTEXT3D_CREATE, onCreateContext);
			stage.stage3Ds[0].requestContext3D();
			
			
			m_viewport = new Rectangle(0,0,stage.stageWidth,stage.stageHeight);
			m_camera.viewport = m_viewport;
//			m_camera.parent = this;
		}
		
		private function onCreateContext(e:Event) : void
		{
			m_renderablle = false;
			
			m_context = (e.target as Stage3D).context3D;
			m_context.configureBackBuffer(m_width,m_height,2,true);
			m_context.enableErrorChecking = m_enableErrorCheck;
			contextList[0] = m_context;
			
			m_renderablle = true;
		}
		
		public function render() : void
		{
			if(!m_renderablle) return;
			
			onBeforeRender();
			m_context.clear();
			
//			renderQuadShow();
			m_rootContainer.render(m_context, m_camera);
			
			m_context.present();
			
			m_pickManager.render(m_camera);
			
			onAfterRender();
		}
		
		private function onBeforeRender() : void
		{
			m_context.clear();
			
			var list : Vector.<Shader> = MaterialManager.beforeRenderShaderList;
			var shader : Shader;
			for each(shader in list){
				shader.render(m_context);
			}
		}
		
		private function onAfterRender() : void
		{
			
		}
		
		/**
		 * 获取所有对象列表
		 */
		public function get modelList() : Vector.<Object3D>
		{
			m_modelList.splice(0,m_modelList.length);
			getChildren(m_rootContainer, m_modelList);
			
			return m_modelList;
		}
		
		private function getChildren(container : Object3DContainer, outList : Vector.<Object3D>) : void
		{
			for each(var child : Object3D in container.children){
				if(child is Object3DContainer) getChildren(child as Object3DContainer, outList);
				else outList.push(child);
			}
		}
		
		public function addPostItem(item : IPostRender) : void
		{
			if(m_postRenderList.indexOf(item) == -1)
				m_postRenderList.push(item);
		}
		
		public function removePostItem(item : IPostRender) : void
		{
			var index : int = m_postRenderList.indexOf(item);
			m_postRenderList.splice(index, 1);
		}
		
		public function removeAllPostItem() : void
		{
			while(m_postRenderList.length){
				var item : IPostRender = m_postRenderList.shift();
				item.dispose();
			}
		}
		
		/**
		 * 天空盒
		 * 一个就够了
		 */
		public function set skyBox(value : SkyBoxBase) : void
		{
			if(null != m_skyBox){
				m_rootContainer.removeChild(m_skyBox);
			}
			
			m_skyBox = value;
			if(m_skyBox){
				m_rootContainer.addChild(m_skyBox);
			}
		}
		
		public function get skyBox() : SkyBoxBase
		{
			return m_skyBox;
		}
		
		public function get scene() : Object3DContainer
		{
			return m_rootContainer;
		}
		
		public function get pickManager() : PickManager
		{
			return m_pickManager;
		}
		
		public function dispose():void
		{
			m_rootContainer.dispose();
			m_renderablle = false;
			m_skyBox = null;
			m_modelList = null;
		}
		
		public function get depthBMD() : BitmapData
		{
			if(m_context)
				return ShaderDepthMap(MaterialManager.getShader(Shader.DEPTH_MAP,m_context)).bmd;
			
			return null;
		}
		
		/**
		 * 看看深度图长啥样
		 */
		private var m_showQuad : QuadInfo;
		private var m_viewMatrix : Matrix3D = new Matrix3D();
		private var m_finalMatrix : Matrix3D = new Matrix3D();
		private function renderQuadShow() : void
		{
			var list : Vector.<Shader> = MaterialManager.beforeRenderShaderList;
			if(!list.length) return;
			
			for each(var taget : Object3D in Object3DContainer(m_rootContainer.children[0]).children)
			{
				taget.camera = m_camera;
				taget.setContext(m_context);
				taget.updateShader(m_context);
			}
				
			m_context.clear(.3,.3,.3);
			
			m_showQuad||=createQuad("xx");
			
			var m_shaderMap : TextureBase = MaterialManager.getShader(Shader.DEPTH_MAP,m_context).material.getTexture(m_context);
			m_context.setTextureAt(0, m_shaderMap);
			m_context.setProgram(shadowShader);
			
			m_showQuad.transform.identity();
			m_showQuad.transform.appendScale(10,10,10);
			m_showQuad.transform.appendTranslation(0,0,0);
			
			m_viewMatrix.identity();
			m_viewMatrix.appendTranslation(0,0,-30);
			
			m_finalMatrix.identity();
			m_finalMatrix.append(m_showQuad.transform);
			m_finalMatrix.append(m_viewMatrix);
			m_finalMatrix.append(m_camera.projectMatrix);
			
			m_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX,0,m_finalMatrix,true);
			m_context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, Vector.<Number>([60, 1, 0, 0]));
			m_context.setVertexBufferAt(0,m_showQuad.vertexBuffer,0,Context3DVertexBufferFormat.FLOAT_3);
			m_context.setVertexBufferAt(1,m_showQuad.uvBuffer,0,Context3DVertexBufferFormat.FLOAT_2);
			m_context.drawTriangles(m_showQuad.indexBuffer);
			
			m_context.setTextureAt(0, null);
			m_context.setVertexBufferAt(0,null);
			m_context.setVertexBufferAt(1,null);
		}
		
		private var m_depthShader : Program3D;
		private function get shadowShader() : Program3D
		{
			if(m_depthShader) return m_depthShader;
			
			var vertexStr : String = "m44 vt0, va0, vc0\n"+
				"mov op, vt0\n"+
				"mov v0, va1\n"+
				"mov v1, vt0\n";
			
			var vertexProgram : AGALMiniAssembler = new AGALMiniAssembler();
			vertexProgram.assemble(Context3DProgramType.VERTEX,vertexStr);
			
			var fragmentStr : String = "tex ft0 v0 fs0\n"+
				"mov oc, ft0\n";
			
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
		
		private var m_pickManager : PickManager;
		
		private var m_camera : ICamera;
		private var m_context : Context3D;
		private var m_viewport : Rectangle;
		private var m_width : int;
		private var m_height : int;
		private var m_enableErrorCheck : Boolean;
		private var m_rootContainer : Object3DContainer;
		private var m_renderablle : Boolean;
		private var m_postRenderList : Vector.<IPostRender>;
		private var m_modelList : Vector.<Object3D>;
		
		private var m_skyBox : SkyBoxBase;
		
		public static var contextList : Vector.<Context3D> = new Vector.<Context3D>(3,true);
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