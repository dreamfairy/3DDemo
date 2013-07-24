package C3.Animator
{
	import flash.utils.Dictionary;
	
	import C3.IDispose;
	import C3.Geoentity.MeshGeoentity;

	/**
	 * 动画集
	 */
	public class AnimationSet implements IDispose
	{
		public function AnimationSet(target : MeshGeoentity)
		{
			m_target = target;
		}
		
		public function render() : void
		{
			if(m_currentAnimalState)m_currentAnimalState.updateAnimation();
		}
		
		public function setRender(state : AnimalState) : void
		{
			m_currentAnimalState = state;
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
		
		public var dirtyFrameNumber : Number;
	}
}