package
{
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.Texture;
	import flash.events.Event;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	import flash.utils.ByteArray;
	
	import C3.MD5.MD5Result;

	[SWF(width = "800", height = "800", frameRate="30")]
	public class MD5Test extends ContextBase
	{
		public function MD5Test()
		{
			super();
		}
		
		private function onMeshComplete(e:Event) : void
		{
			m_hasMeshData = true;
		}
		
		private function onAnimComplete(e:Event) : void
		{
			m_hasAnimData = true;
		}
		
		protected override function onCreateContext(e:Event):void
		{
			super.onCreateContext(e);
			
			md5Result = new MD5Result(m_context);
			md5Result.addEventListener("meshLoaded", onMeshComplete);
			md5Result.addEventListener("animLoaded", onAnimComplete);
			md5Result.loadModel(new mesh as ByteArray);
			md5Result.loadAnim(new anim as ByteArray);
			
			m_texture = Utils.getTexture(textureData,m_context);
			
//			m_headTexture = Utils.getTexture(headTextureData, m_context);
//			m_equipTexture = Utils.getTexture(equipTextureData, m_context);
//			m_weaponTexture = Utils.getTexture(weaponTextureData, m_context);
//			m_faceTexture = Utils.getTexture(faceTextureData, m_context);
//			
//			m_textureList = new <Texture>[m_headTexture,m_equipTexture,m_weaponTexture,m_faceTexture];
			
			stage.addEventListener(Event.ENTER_FRAME, onEnter);
			addChild(new Stats);
			
			var tf : TextField = new TextField();
			tf.textColor = 0xFFFFFF;
			tf.text = "方向键及鼠标滚轮控制相机. 1 切换到原始网格 2 切换到骨骼动画\n苍白的茧 | 追逐繁星的苍之茧\nhttp://www.dreamfairy.cn/blog";
			tf.width = tf.textWidth + 10;
			tf.height = tf.textHeight + 10;
			tf.y = stage.stageHeight - tf.height >> 1;
			tf.x = stage.stageWidth - tf.width >> 1;
			tf.selectable = false;
			addChild(tf);
		}
		
		private var t : Number = 0;
		private function onEnter(e:Event) : void
		{
			m_context.clear(0,0,0,0);
			
			t += 1;
			
			if(!m_hasMeshData) return;
			
			m_context.setProgram(md5Result.program);
						
			m_modelMatrix.identity();
			m_modelMatrix.appendRotation(-90,Vector3D.X_AXIS);
			m_modelMatrix.appendRotation(t, Vector3D.Y_AXIS);
			m_modelMatrix.appendScale(.5,.5,.5);
			m_modelMatrix.appendTranslation(0,-30,-100);
			
			m_finalMatrix.identity();
			m_finalMatrix.append(m_modelMatrix);
			m_finalMatrix.append(m_viewMatrix);
			m_finalMatrix.append(m_projMatrix);
			
			m_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 124, m_finalMatrix, true);
			
			m_context.setTextureAt(0, m_texture);
			for(var i : int = 0; i < md5Result.meshDataNum; i++){
				var vertexBuffer : VertexBuffer3D = md5Result.vertexBufferList[i];
				var uvBuffer : VertexBuffer3D = md5Result.uvBufferList[i];
				var indexBuffer : IndexBuffer3D = md5Result.indexBufferList[i];
//				var texture : Texture = m_textureList[i];
				
				if(m_hasAnimData){
					m_currentFrame = t % md5Result.numFrames;
					md5Result.prepareMesh(m_currentFrame, i, m_finalMatrix);
					
					if(!md5Result.useCPU){
						var jointIndiceBuffer : VertexBuffer3D = md5Result.jointIndexList[i];
						var jointWeightBuffer : VertexBuffer3D = md5Result.jointWeightList[i];
						
						//上传骨骼和权重
						m_context.setVertexBufferAt(2, jointIndiceBuffer, 0, md5Result.bufferFormat);
						m_context.setVertexBufferAt(3, jointWeightBuffer, 0, md5Result.bufferFormat);
					}else{
						vertexBuffer = md5Result.cpuAnimVertexBuffer;
					}
				}
				
//				m_context.setTextureAt(0, texture);
				m_context.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
				m_context.setVertexBufferAt(1,uvBuffer,0,Context3DVertexBufferFormat.FLOAT_2);
				m_context.drawTriangles(indexBuffer);
//				m_context.setTextureAt(0, m_texturenull);
				md5Result.clearCpuData();
			}
			m_context.present();
			
			renderKeyBoard();
		}
		
		protected override function renderKeyBoard():void
		{
			super.renderKeyBoard();
			
			if(m_key[Keyboard.NUMBER_1])
				m_hasAnimData = false;
			
			if(m_key[Keyboard.NUMBER_2])
				m_hasAnimData = true;
		}
		
		[Embed(source="../source/hellknight/hellknight.md5mesh", mimeType="application/octet-stream")]
		private var mesh : Class;
		
		[Embed(source="../source/hellknight/idle2.md5anim", mimeType="application/octet-stream")]
		private var anim : Class;
	
		[Embed(source="../source/hellknight/hellknight_diffuse.jpg")]
		private var textureData : Class;
		
//		[Embed(source="../source/meizi/chujitou.jpg")]
//		private var headTextureData : Class;
//		
//		[Embed(source="../source/meizi/chujizhuang3.jpg")]
//		private var equipTextureData : Class;
//		
//		[Embed(source="../source/meizi/dao.jpg")]
//		private var weaponTextureData : Class;
//		
//		[Embed(source="../source/meizi/nvlian1.jpg")]
//		private var faceTextureData : Class;
		
		private var md5Result : MD5Result;
		private var m_hasMeshData : Boolean;
		private var m_hasAnimData : Boolean;
		private var m_texture : Texture;
		private var m_currentFrame : int;
		private var m_modelMatrix : Matrix3D = new Matrix3D();
		
		private var m_headTexture : Texture;
		private var m_equipTexture : Texture;
		private var m_weaponTexture : Texture;
		private var m_faceTexture : Texture;
		private var m_textureList : Vector.<Texture>;
	}
}