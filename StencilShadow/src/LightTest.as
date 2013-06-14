package
{
	import com.adobe.utils.AGALMiniAssembler;
	
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Program3D;
	import flash.display3D.textures.Texture;
	import flash.events.Event;
	import flash.geom.Vector3D;
	
	import C3.CubeMesh;
	import C3.Light.SimpleLight;

	/**
	 * 逐像素光照test
	 * 环境光 ambient_color = ambient_light_color * ambient_material_color
	 * 漫反射 diffuse_color = diffuse_light_color * diffuse_material_color * cos(Θ);
	 * 镜面光 specular_color = specular_light_color * specular_material_color * cos(α)shiness.
	 * 
	 * cos(Θ) =  dot(light_vec , normal_vec) ；
	 * cos(α) =  dot(reflect_vec , eye_vec) ；
	 * dot(reflect_vec , eye_vec) = dot(halfvec , normal_vec)
	 * 
	 * halfvec = eyevec + Lightvec
	 */
	[SWF(width = "1440", height = "800", frameRate="30")]
	public class LightTest extends ContextBase
	{
		public function LightTest()
		{
			super();
		}
		
		protected override function onCreateContext(e:Event):void
		{
			super.onCreateContext(e);
			
			setupMesh();
			setupLight();
			
			m_viewMatrix.identity();
			m_viewMatrix.appendTranslation(0,0,-10);
			
			addEventListener(Event.ENTER_FRAME, onEnter);
		}
		
		private function setupMesh() : void
		{
			cubeTexture = Utils.getTexture(cubeMesh,m_context);
			cube = new CubeMesh(m_context,cubeTexture);
			cube.moveTo(0,0,0);
		}
		
		private function setupLight() : void
		{
			//三光总和为1
			var amb : Number = .3;
			var diff : Number = .4;
			var spec : Number = .3;
			
			lightDirection = new SimpleLight(0xFFFFFF,1);
			light = new CubeMesh(m_context);
			light.scale(.1,.1,.1);
			lightProp = new Vector3D(amb,diff,spec);
			
			cube.light = lightDirection;
			
			lightProgram = m_context.createProgram();
			
			var vertxProgram : AGALMiniAssembler = new AGALMiniAssembler();
			vertxProgram.assemble(Context3DProgramType.VERTEX,getVertexStr());
			
			var fragmentProgram : AGALMiniAssembler = new AGALMiniAssembler();
			fragmentProgram.assemble(Context3DProgramType.FRAGMENT, getFragmentStr());
			
			lightProgram.upload(vertxProgram.agalcode,fragmentProgram.agalcode);
		}
		
		private var t : Number = 0;
		private function onEnter(e:Event) : void
		{
			t += 1;
			
			m_context.clear();
			renderLight();
			renderScene();
			m_context.present();
		}
		
		private function renderLight() : void
		{
			lightDirection.pos.setTo(Math.cos(t/50) * 5,
				0,
				Math.sin(t/50) * 5);
			
			
			light.moveTo(lightDirection.x,lightDirection.y,lightDirection.z);
			light.render(m_viewMatrix,m_projMatrix,null);
			
//			m_context.setProgramConstantsFromVector(Context3DProgramType.VERTEX,1,Vector.<Number>([lightProp.x,lightProp.y,lightProp.z,1]));
//			m_context.setProgramConstantsFromVector(Context3DProgramType.VERTEX,Vector.<Number>([lightDirection.x,lightDirection.y,lightDirection.z,0]));
		}
		
		private function renderScene() : void
		{
			cube.rotateY = t/10;
			cube.render(m_viewMatrix,m_projMatrix,lightProgram);	
		}
		
		private function getVertexStr() : String
		{
			var data : Array = [
				//投影顶点
				"mov vt0, va0",
				"m44 op, vt0, vc0",
				//归一化顶点
				"nrm vt1.xyz, va0.xyz",
				//重置顶点分量
				"mov vt1.w, va0.w",
				"mov v1, vt1",
				"mov v2, va1",
				"mov v3, va2"]
			return data.join("\n");
		}
		
		private function getFragmentStr() : String
		{
			var data : Array = [
				"tex ft0, v2, fs0<2d,mipmap,repeat>",
				//灯光和法线点乘, fc2灯光向量
				"dp3 ft1, fc2, v1",
				//翻转角度
				"neg ft1, ft1",
				//
				"sat ft1, ft1",
				//混合环境光
				"mul ft2, ft0, ft1",
				//混合灯光颜色
				"mul ft2, ft2, fc3",
				//输出
				"add oc, ft2, fc1"];
			
			return data.join("\n");
		}
		
		private var cube : CubeMesh;
		private var lightDirection : SimpleLight;
		private var lightProp : Vector3D;
		private var light : CubeMesh;
		private var lightProgram : Program3D;
		
		[Embed(source="../source/seber.jpg")]
		private var cubeMesh : Class;
		
		private var cubeTexture : Texture;
	}
}