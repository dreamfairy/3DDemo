package C3.Material.Shaders
{
	import C3.Core.Managers.MaterialManager;
	import C3.Material.RTTMaterial;
	import C3.Object3D;
	import C3.View;
	
	import com.adobe.utils.AGALMiniAssembler;
	
	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.Program3D;
	import flash.geom.Matrix3D;
	import flash.utils.ByteArray;
	
	public class ShaderDepthMap extends Shader
	{
		private var renderList : Vector.<Object3D> = new Vector.<Object3D>();
		private var vaPos : uint = 0;
		private var vaUV : uint = 1;
		private var vcProjection : uint = 0;
		private var fcConstant : uint = 0;
		private var fcConstantData : Vector.<Number> = Vector.<Number>([1000,0,0,0]);
		private var modellightProj : Matrix3D = new Matrix3D();
		
		public var bmd : BitmapData = new BitmapData(512,512,true,0);
		
		public function ShaderDepthMap(context : Context3D)
		{
			m_material||=new RTTMaterial(512, 512);
			m_material.getTexture(context);
			
			m_params.blendEnabled		= false;
			m_params.writeDepth			= true;
			m_params.depthFunction		= Context3DCompareMode.LESS;
			m_params.colorMaskEnabled	= false;
			m_params.culling			= Context3DTriangleFace.BACK;
			m_params.loopCount			= 1;
			m_params.requiresLight		= false;
			
			MaterialManager.addBeforeRenderShader(this);
		}
		
		public override function getProgram(context:Context3D):Program3D
		{
			return	super.getProgram(context);
		}
		
		public override function getVertexProgram():ByteArray
		{
			return new AGALMiniAssembler().assemble(Context3DProgramType.VERTEX,
				"m44 vt0 va"+vaPos+" vc"+vcProjection+"\n"+
				"mov op vt0\n"+
				"mov v0 vt0\n");
		}
		
		public override function getFragmentProgram():ByteArray
		{
			return new AGALMiniAssembler().assemble(Context3DProgramType.FRAGMENT,
				"mov ft0.xyzw v0.zzzz\n"+
				"div ft0.xyzw ft0.xyzw fc"+fcConstant+".x\n"+
				"mov oc ft0\n");
		}
		
		public override function render(context3D:Context3D):void
		{
			context3D.setRenderToTexture(m_material.getTexture(context3D),true,2,0);
			context3D.clear();
			
			context3D.setDepthTest(m_params.writeDepth, m_params.depthFunction);
			context3D.setCulling(m_params.culling);
			context3D.setProgram(getProgram(context3D));
			context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT,fcConstant,
				fcConstantData);
			
			for each(var target : Object3D in renderList){
				modellightProj.identity();
				modellightProj.append(target.matrixGlobal);
				modellightProj.append(target.camera.lightProjection);
				
				context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX,vcProjection,modellightProj,true);
				context3D.setVertexBufferAt(vaPos,target.vertexBuffer,0,Context3DVertexBufferFormat.FLOAT_3);
				context3D.drawTriangles(target.indexBuffer,0,target.numTriangles);
			}
			
//			context3D.drawToBitmapData(bmd);
			context3D.present();
			
			context3D.setVertexBufferAt(vaPos,null);
		}
		
		public function addTarget(target : Object3D) : void
		{
			if(renderList.indexOf(target) == -1)
				renderList.push(target);
		}
		
		public function removeTarget(target : Object3D) : void
		{
			var index : int = renderList.indexOf(target);
			if(index != -1) renderList.splice(index, 1);
		}
		
		public override function dispose():void
		{
			fcConstantData = null;
			renderList = null;
			modellightProj = null;
		}
		
		public override function get type():uint
		{
			return DEPTH_MAP;
		}
	}
}