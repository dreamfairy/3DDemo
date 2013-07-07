package
{
	import C3.AOI3DAXIS;
	import C3.Event.AOI3DLOADEREVENT;
	import C3.Geoentity.AnimGeoentity;
	import C3.Material.ColorMaterial;
	import C3.Material.TextureMaterial;
	import C3.Object3DContainer;
	import C3.Parser.MD5AnimLoader;
	import C3.Parser.MD5Loader;
	import C3.PlaneMesh;
	import C3.View;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;

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
			
			m_model = new MD5Loader("md5Mesh", new TextureMaterial(textureData));
			m_model.load(new mesh());
			m_model.rotateX = -90;
			m_model.setScale(.1,.1,.1);
			m_model.y = -5;
			m_container.addChild(m_model);
			
			loadAnim();
			
			m_view.scene.addChild(m_container);
			
			stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			this.addEventListener(Event.ENTER_FRAME, onEnter);
		}
		
		private function onKeyDown(e:KeyboardEvent) : void
		{
			m_key[e.keyCode] = true;
		}
		
		private function onKeyUp(e:KeyboardEvent) : void
		{
			delete m_key[e.keyCode];
		}
		
		private function loadAnim() : void
		{
			var animList : Array = [new idelAnim(),new standAnim(),new walkAnim()];
			var actionList : Array = ["idel","stand","walk"];
			var animLoader : MD5AnimLoader;
			while(animList.length)
			{
				animLoader = new MD5AnimLoader(actionList.shift());
				animLoader.addEventListener(AOI3DLOADEREVENT.ON_ANIM_LOADED, onAnimLoaded);
				animLoader.load(animList.shift());
			}
		}
		
		private function onAnimLoaded(e:AOI3DLOADEREVENT) : void
		{
			var loader : MD5AnimLoader = e.target as MD5AnimLoader;
			loader.removeEventListener(AOI3DLOADEREVENT.ON_ANIM_LOADED, onAnimLoaded);
			m_model.addAnimation(loader as AnimGeoentity);
		}
		
		private function onEnter(e:Event) : void
		{
			m_view.render();
			renderKeyboard();
		}
		
		private function renderKeyboard() : void
		{
			if(m_key[Keyboard.NUMBER_1])
				m_model.animator.play("idel");
			
			if(m_key[Keyboard.NUMBER_2])
				m_model.animator.play("stand");
			
			if(m_key[Keyboard.NUMBER_3])
				m_model.animator.play("walk");
			
			if(m_key[Keyboard.NUMBER_4])
				m_model.animator.pause();
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
		private var m_key : Object = new Object();
		private var m_container : Object3DContainer;
		
		[Embed(source="../source/hellknight/hellknight.md5mesh", mimeType="application/octet-stream")]
		private var mesh : Class;
		
		[Embed(source="../source/hellknight/idle2.md5anim", mimeType="application/octet-stream")]
		private var idelAnim : Class;
		
		[Embed(source="../source/hellknight/stand.md5anim", mimeType="application/octet-stream")]
		private var standAnim : Class;
		
		[Embed(source="../source/hellknight/walk7.md5anim", mimeType="application/octet-stream")]
		private var walkAnim : Class;
		
		[Embed(source="../source/hellknight/hellknight_diffuse.jpg")]
		private var textureData : Class;
	}
}