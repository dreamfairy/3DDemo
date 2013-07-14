package
{
	import C3.AOI3DAXIS;
	import C3.Event.AOI3DLOADEREVENT;
	import C3.Geoentity.AnimGeoentity;
	import C3.Material.TextureMaterial;
	import C3.Mesh.PlaneMesh;
	import C3.Mesh.SphereMesh;
	import C3.Object3D;
	import C3.Object3DContainer;
	import C3.Parser.MD5AnimLoader;
	import C3.Parser.MD5Loader;
	import C3.View;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.ui.Keyboard;

	[SWF(width = "800", height = "800", frameRate="30")]
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
			
			m_tip = "<a href='http://www.dreamfairy.cn'><u>2007-2013 苍白的茧 | 追逐繁星的苍之茧</u></a>\r移动鼠标点选物体";
			m_info = new TextField();
			m_info.textColor = 0xFFFFFFFF;
			m_info.htmlText = m_tip;
			addChild(m_info);
			
			m_info.width = m_info.textWidth + 10;
			m_info.height = m_info.textHeight + 10;
			
			m_container = new Object3DContainer("root");
			m_container.z = -20;
			
			var bottomPlane : PlaneMesh = new PlaneMesh("floor",10,10, 2, AOI3DAXIS.XZ, new TextureMaterial(floorData));
			bottomPlane.uvRawData = Vector.<Number>([
				0,0,
				5,0,
				0,5,
				5,5]);
			bottomPlane.y = -6;
			bottomPlane.pickEnabled = true;
			bottomPlane.interactive = true;
			m_container.addChild(bottomPlane);
			
			var backPlane : PlaneMesh = new PlaneMesh("wall",10,15, 2, AOI3DAXIS.XY, new TextureMaterial(floorData));
			backPlane.uvRawData = Vector.<Number>([
				0,0,
				5,0,
				0,5,
				5,5]);
			backPlane.z = -4;
			backPlane.y = 2;
			backPlane.pickEnabled = true;
			backPlane.interactive = true;
			m_container.addChild(backPlane);
			
			m_model = new MD5Loader("md5Mesh", new TextureMaterial(textureData));
			m_model.load(new mesh());
			m_model.rotateX = -90;
			m_model.setScale(.1,.1,.1);
			m_model.y = -5;
//			m_model.pickEnabled = true;
			m_container.addChild(m_model);
			
			m_sphere = new SphereMesh("earth",15,15, new TextureMaterial(earthData));
			m_sphere.setScale(5,5,5);
			m_sphere.z = 5;
			m_sphere.y = -5;
			m_sphere.pickEnabled = true;
			m_sphere.interactive = true;
			m_container.addChild(m_sphere);
			
			loadAnim();
			
			m_view.scene.addChild(m_container);
			
			stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			stage.addEventListener(MouseEvent.CLICK, onMouseClick);
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
		
		private var t : Number = 0;
		private function onEnter(e:Event) : void
		{
			t += 1;
			m_sphere.rotateY = t;
			m_view.render();
			renderKeyboard();
			
			m_container.rotateY = t;
		}
		
		private function checkHit() : void
		{
			var hitItem : Object3D = m_view.pickManager.getRender().lastHit;
			if(hitItem) m_info.htmlText = m_tip + "\r" + hitItem.name + " is clicked";
			else m_info.htmlText = m_tip;
			
			m_info.width = m_info.textWidth + 10;
			m_info.height = m_info.textHeight + 10;
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
//			m_view.getCamera().walk(e.delta/3);
		}
		
		private function onMouseMove(e:MouseEvent) : void
		{
//			m_container.rotateY = ((stage.stageWidth >> 1) - stage.mouseX) / 10;
		}
		
		private function onMouseClick(e:MouseEvent) : void
		{
			checkHit();
		}
		
		private var m_view : View;
		private var m_model : MD5Loader;
		private var m_key : Object = new Object();
		private var m_container : Object3DContainer;
		private var m_sphere : Object3D;
		private var m_info : TextField;
		private var m_tip : String;
		
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
		
		[Embed(source="../source/floor1.jpg")]
		private var floorData : Class;
		
		[Embed(source="../source/earth.jpg")]
		private var earthData : Class;
	}
}