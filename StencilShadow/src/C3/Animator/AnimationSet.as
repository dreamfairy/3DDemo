package C3.Animator
{
	import flash.display3D.Context3D;
	import flash.utils.Dictionary;
	
	import C3.IDispose;
	import C3.Geoentity.MeshGeoentity;
	import C3.Material.Shaders.ShaderOgreSkeleton;
	
	import org.osflash.signals.Signal;

	/**
	 * 动画集
	 */
	public class AnimationSet implements IDispose
	{
		public function AnimationSet(target : MeshGeoentity)
		{
			m_target = target;
		}
		
		public function set shader(data : ShaderOgreSkeleton) : void
		{
			m_shader = data;
		}
		
		public function get shader() : ShaderOgreSkeleton
		{
			return m_shader;
		}
		
		public function render(context3D : Context3D) : void
		{
			if(m_currentAnimalState){
				m_currentAnimalState.updateAnimation();
				m_shader.vertexBuffer = m_currentAnimalState.getVertexBuffer(context3D);
				m_shader.render(context3D);
			}
		}
		
		public function setRender(state : AnimalState, needRender : Boolean = true) : void
		{
			if(!needRender && m_currentAnimalState == state) m_currentAnimalState = null;
			else m_currentAnimalState = state;
		}
		
		public function add(state : AnimalState) : void
		{
			var anim : AnimalState;
			if(m_animationList.hasOwnProperty(state.animationName)){
				anim = m_animationList[state.animationName];
				anim.dispose();
			}
			
			anim = state;
			m_animationList[state.animationName] = state;
			onStateLoaded.dispatch(state.animationName);
		}
		
		public function createAnimalState(animationName : String) : AnimalState
		{
			return new AnimalState(this, animationName);
		}
		
		public function getState(name : String) : AnimalState
		{
			return m_animationList[name];
		}
		
		public function dispose():void
		{
			// TODO Auto Generated method stub
			
		}
		
		public function get target() : MeshGeoentity
		{
			return m_target;
		}
		
		private var m_animationList : Dictionary = new Dictionary();
		private var m_currentAnimalState : AnimalState;
		private var m_target : MeshGeoentity;
		private var m_shader : ShaderOgreSkeleton;
		
		public var onStateLoaded : Signal = new Signal(String);
		public var dirtyFrameNumber : Number;
	}
}