package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import C3.AOI3DAXIS;
	import C3.Object3DContainer;
	import C3.PlaneMesh;
	import C3.View;
	import C3.Material.ColorMaterial;
	import C3.Material.TextureMaterial;
	import C3.Parser.MD5Loader;

	[SWF(width = "1024", height = "1024", frameRate="30")]
	public class ShadowMapTest extends Sprite
	{
		public function ShadowMapTest()
		{
			stage ? init() : addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null) : void
		{
			if(hasEventListener(Event.ADDED_TO_STAGE))
				removeEventListener(Event.ADDED_TO_STAGE, init);
			
			m_view = new View(stage.stageWidth,stage.stageHeight,true);
			addChild(m_view);
			
			m_container = new Object3DContainer();
			m_container.z = -20;
			
			var bottomPlane : PlaneMesh = new PlaneMesh("plane",10,10, 2, AOI3DAXIS.XZ, new ColorMaterial(0xFFFFFF,1));
			bottomPlane.y = -6;
			m_container.addChild(bottomPlane);
			
			var backPlane : PlaneMesh = new PlaneMesh("plane",10,15, 2, AOI3DAXIS.XY, new ColorMaterial(0xFFFFFF,1));
			backPlane.z = -4;
			backPlane.y = 2;
			m_container.addChild(backPlane);
			
			m_model = new MD5Loader("md5", new TextureMaterial(textureData));
			m_model.load(new mesh());
			m_model.rotateX = -90;
			m_model.setScale(.1,.1,.1);
			m_model.y = -5;
			m_container.addChild(m_model);
			
			m_view.scene.addChild(m_container);
			
//			var light : SimpleLight = new SimpleLight(0xFF0000,1);
//			var shadowMap : ShadowMap = new ShadowMap(light);
//			m_view.addPostItem(shadowMap);
			
			stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			this.addEventListener(Event.ENTER_FRAME, onEnter);
		}
		
		private function onEnter(e:Event) : void
		{
			m_view.render();
		}
		
		private function onMouseWheel(e:MouseEvent) : void
		{
			m_view.getCamera().walk(e.delta/3);
		}
		
		private function onMouseMove(e:MouseEvent) : void
		{
			m_container.rotateY = ((stage.stageWidth >> 1) - stage.mouseX) / 10;
		}
		
		private var m_view : View;
		private var m_model : MD5Loader;
		private var m_container : Object3DContainer;
		
		[Embed(source="../source/hellknight/hellknight.md5mesh", mimeType="application/octet-stream")]
		private var mesh : Class;
		
		[Embed(source="../source/hellknight/hellknight_diffuse.jpg")]
		private var textureData : Class;
	}
}