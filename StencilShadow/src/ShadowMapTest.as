package
{
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	
	import C3.AOI3DAXIS;
	import C3.Object3D;
	import C3.Object3DContainer;
	import C3.View;
	import C3.Camera.Camera;
	import C3.Event.AOI3DLOADEREVENT;
	import C3.Event.MouseEvent3D;
	import C3.Geoentity.AnimGeoentity;
	import C3.Material.CubeMaterial;
	import C3.Material.TextureMaterial;
	import C3.Mesh.PlaneMesh;
	import C3.Mesh.SphereMesh;
	import C3.Mesh.SkyBox.SkyBoxBase;
	import C3.Parser.MD5AnimLoader;
	import C3.Parser.MD5Loader;
	import C3.Parser.ORGEMeshLoader;

	[SWF(width = "600", height = "600", frameRate="60")]
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
//			m_view.camera.setCameraType(Camera.LANDOBJECT);
//			m_view.camera.Position.z = -160;
			addChild(m_view);
			addChild(new Stats());
			
			var mat : Matrix3D = new Matrix3D();
			mat.pointAt(new Vector3D(11,12,13), Camera.CAM_FACING, Camera.CAM_UP);
			
			m_bitmap = new Bitmap();
			addChild(m_bitmap);
			
			m_skyBox = new SkyBoxBase("sky", new CubeMaterial(skyData));
			m_view.skyBox = m_skyBox;
			
			m_tip = "";
//			m_tip = "<a href='http://www.dreamfairy.cn'><u>2007-2013 苍白的茧 | 追逐繁星的苍之茧</u></a>\r移动鼠标点选物体";
			m_info = new TextField();
			m_info.textColor = 0xFFFFFF;
			m_info.filters = [new GlowFilter(0,1,2,2,10)];
			m_info.htmlText = m_tip;
			m_info.y = stage.stageHeight >> 1;
			addChild(m_info);
			
			m_info.width = m_info.textWidth + 10;
			m_info.height = m_info.textHeight + 10;
			
			m_container = new Object3DContainer("root");
			m_container.z = -30;
			
			var bottomPlane : PlaneMesh = new PlaneMesh("floor",10,10, 2, AOI3DAXIS.XZ, new TextureMaterial(floorData));
			bottomPlane.y = -5;
			bottomPlane.pickEnabled = true;
			bottomPlane.interactive = true;
			bottomPlane.buttonMode = true;
			bottomPlane.receiveShadow = true;
			bottomPlane.castShadow = true;
			bottomPlane.onMouseClick.add(onMouseClick);
			bottomPlane.scaleX = bottomPlane.scaleZ = 10;
			m_container.addChild(bottomPlane);
			
			var backPlane : PlaneMesh = new PlaneMesh("wall",10,10, 2, AOI3DAXIS.XY, new TextureMaterial(floorData));
			backPlane.z = -5;
			backPlane.pickEnabled = true;
			backPlane.interactive = true;
			backPlane.buttonMode = true;
			backPlane.castShadow = true;
			backPlane.receiveShadow = true;
			backPlane.onMouseClick.add(onMouseClick);
			m_container.addChild(backPlane);
			
//			m_model = new MD5Loader("md5Mesh", new TextureMaterial(textureData));
//			m_model.load(new mesh());
//			m_model.rotateX = -90;
//			m_model.setScale(.1,.1,.1);
//			m_model.y = -5;
//			m_container.addChild(m_model);
			
			m_sphere = new SphereMesh("earth",15,15, new TextureMaterial(earthData));
			m_sphere.setScale(5,5,5);
			m_sphere.y = -2;
			m_sphere.z = -15;
			m_sphere.pickEnabled = true;
			m_sphere.interactive = true;
			m_sphere.buttonMode = true;
			m_sphere.castShadow = true;
			m_sphere.receiveShadow = true;
			m_sphere.onMouseClick.add(onMouseClick);
			m_view.scene.addChild(m_sphere);
			
			m_ogreModel = new ORGEMeshLoader("ogre", new TextureMaterial(ogreData));
			m_ogreModel.loadMesh("../source/ogre/PET_CAT.MESH.xml");
			m_ogreModel.loadSkeleton("../source/ogre/WALK.SKELETON.xml");
			m_ogreModel.animatorset.onStateLoaded.add(onStateLoaded);
			m_ogreModel.onMouseClick.add(onMouseClick);
			m_ogreModel.InteractiveChildren = m_ogreModel.PickChildren = true;
			m_ogreModel.buttonMode = true;
			m_ogreModel.castShadow = true;
			m_ogreModel.receiveShadow = true;
			m_ogreModel.y = -5;
			m_ogreModel.z = 20;
			m_ogreModel.rotateY = -180;
			m_container.addChild(m_ogreModel);
			
//			loadAnim();
			
			m_view.scene.addChild(m_container);
			m_view.camera.setGlobalLightTarget(0,0,-30);
			m_view.camera.setGlobalLightPos(100,25,-18);
			
			stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			this.addEventListener(Event.ENTER_FRAME, onEnter);
		}
		
		private function onStateLoaded(stateName : String) : void
		{
			m_ogreModel.animatorset.getState(stateName).play();
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
//			m_sphere.rotateY = t;
//			m_skyBox.rotateY = t;
			m_view.render();
			renderKeyboard();
			m_sphere.rotateX = -t;
//			m_container.rotateY = t;
			
//			m_bitmap.bitmapData = m_view.depthBMD;
			

//			m_ogreModel.lookAt(m_sphere.matrixGlobal.position);
			
			
			
			var cat : Object3D = m_ogreModel;
			var pos : Vector3D = cat.matrixGlobal.position;
			var forward : Vector3D = cat.getForward();
//			m_view.camera.setPositionValues(pos.x,pos.y + 1.5, pos.z);
//			m_view.camera.setTargetValues(forward.x,forward.y + 1.5, forward.z);
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
			
			if(m_key[Keyboard.LEFT])
				m_ogreModel.rotateY += 5;
			
			if(m_key[Keyboard.RIGHT])
				m_ogreModel.rotateY -= 5;
			
			if(m_key[Keyboard.UP])
				m_ogreModel.moveForward();
			
			if(m_key[Keyboard.DOWN])
				m_ogreModel.moveBack();
			
			if(m_key[Keyboard.W])
				m_view.camera.moveForward(1);
			
			if(m_key[Keyboard.S])
				m_view.camera.moveBackward(1);
			
			if(m_key[Keyboard.D])
				m_view.camera.yaw(-1)
			
			if(m_key[Keyboard.A])
				m_view.camera.yaw(1)
					
			if(m_key[Keyboard.R])
				m_view.camera.moveUp(1)
			
			if(m_key[Keyboard.T])
				m_view.camera.moveDown(1)
			
//			m_view.camera.setTarget(0,m_ogreModel.x,m_ogreModel.z - 5);
		}
		
		private function onMouseWheel(e:MouseEvent) : void
		{
//			m_view.getCamera().walk(e.delta/3);
		}
		
		private function onMouseMove(e:MouseEvent3D) : void
		{
			m_container.rotateY = ((stage.stageWidth >> 1) - stage.mouseX) / 10;
		}
		
		private function onMouseClick(e:MouseEvent3D) : void
		{
			m_info.htmlText = m_tip + "\r" + e.target3D.name + " is clicked";
			m_info.width = m_info.textWidth + 10;
			m_info.height = m_info.textHeight + 10;
		}
		
		private var m_view : View;
		private var m_model : MD5Loader;
		private var m_ogreModel : ORGEMeshLoader;
		private var m_key : Object = new Object();
		private var m_container : Object3DContainer;
		private var m_sphere : Object3D;
		private var m_info : TextField;
		private var m_tip : String;
		private var m_bitmap : Bitmap;
		private var m_skyBox : SkyBoxBase;
		
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
		
		[Embed(source="../source/skybox3.jpg")]
		private var skyData : Class;
		
		[Embed(source="../source/ogre/PET_CAT.jpg")]
		private var ogreData : Class;
		
		[Embed(source="../source/ogre/PET_CAT.DDS", mimeType="application/octet-stream")]
		private var ogreDDSData : Class;
	}
}