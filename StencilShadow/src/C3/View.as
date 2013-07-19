package C3
{
	import flash.display.Sprite;
	import flash.display.Stage3D;
	import flash.display3D.Context3D;
	import flash.events.Event;
	import flash.geom.Matrix3D;
	import flash.geom.Rectangle;
	
	import C3.Camera.Camera;
	import C3.Core.Managers.PickManager;
	import C3.Mesh.SkyBox.SkyBoxBase;
	import C3.PostRender.IPostRender;

	public class View extends Sprite implements IDispose
	{
		public function View(width : int, height : int, enableErrorCheck : Boolean)
		{
			m_width = width;
			m_height = height;
			m_enableErrorCheck = enableErrorCheck;
			
			m_camera = new Camera();
			m_worldMatrix = new Matrix3D();
			m_postRenderList = new Vector.<IPostRender>();
			
			m_rootContainer = new Object3DContainer("scene",null);
			m_rootContainer.isRoot = true;
			m_rootContainer.view = this;
			
			m_pickManager = new PickManager(this);
			
			addEventListener(Event.ADDED_TO_STAGE, addedToStage);
		}
		
		private function addedToStage(e:Event) : void
		{
			if(hasEventListener(Event.ADDED_TO_STAGE))
				removeEventListener(Event.ADDED_TO_STAGE,addedToStage);
			
			stage.stage3Ds[0].addEventListener(Event.CONTEXT3D_CREATE, onCreateContext);
			stage.stage3Ds[0].requestContext3D();
			
			
			m_viewport = new Rectangle(0,0,stage.stageWidth,stage.stageHeight);
			m_camera.viewport = m_viewport;
			m_camera.parent = this;
		}
		
		private function onCreateContext(e:Event) : void
		{
			m_renderablle = false;
			
			m_context = (e.target as Stage3D).context3D;
			m_context.configureBackBuffer(m_width,m_height,2,true);
			m_context.enableErrorChecking = m_enableErrorCheck;
			contextList[0] = m_context;
			
			setup();
			
			m_renderablle = true;
		}
		
		private var m_cube : CubeMesh;
		private function setup() : void
		{
			m_cube = new CubeMesh(m_context);
		}
		
		public function render() : void
		{
			if(!m_renderablle) return;
			
			m_context.clear();
			postProcessing(true);
			m_rootContainer.render(m_context, m_camera);
			postProcessing(false);
			m_context.present();
			m_pickManager.render(m_camera);
			onAfterRender();
		}
		
		public function getCamera() : Camera
		{
			return m_camera;
		}
		
		private function onAfterRender() : void
		{
			
		}
		
		/**
		 * 后期渲染
		 */
		private function postProcessing(before : Boolean) : void
		{
			for each(var item : IPostRender in m_postRenderList)
			{
//				before?item.renderBefore():item.renderAfter();
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
		}
		
		private var m_pickManager : PickManager;
		
		private var m_camera : Camera;
		private var m_context : Context3D;
		private var m_viewport : Rectangle;
		private var m_width : int;
		private var m_height : int;
		private var m_enableErrorCheck : Boolean;
		private var m_rootContainer : Object3DContainer;
		private var m_renderablle : Boolean;
		private var m_postRenderList : Vector.<IPostRender>;
		
		private var m_worldMatrix : Matrix3D;
		private var m_skyBox : SkyBoxBase;
		
		public static var contextList : Vector.<Context3D> = new Vector.<Context3D>(3,true);
	}
}