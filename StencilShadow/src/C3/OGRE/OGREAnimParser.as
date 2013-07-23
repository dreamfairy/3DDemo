package C3.OGRE
{
	import flash.events.EventDispatcher;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;

	public class OGREAnimParser extends EventDispatcher
	{
		public function OGREAnimParser()
		{
		}
		
		public function load(data : ByteArray) : void
		{
			_textData = new XML(data.readUTFBytes(data.bytesAvailable));
			handleData();
		}
		
		private function handleData() : void
		{
			var node : XML;
			for each(node in _textData.children()){
				var nodeName : String = node.name();
				switch(nodeName)
				{
					case BONES:
						parseBone(node);
						break;
					case HIERARCHY:
						parseHierarchy(node);
						break;
					case ANIMATIONS:
						parseAnimation(node);
						break;
				}
			}
		}
		
		private function parseBone(node : XML) : void
		{
			m_jointList = new Vector.<OGREJoint>();
			
			var boneData : XML;
			var bone : OGREJoint;
			var info : XML;
			var nodeName : String;
			for each(boneData in node.children())
			{
				bone = new OGREJoint();
				bone.id = boneData.@id;
				bone.name = boneData.@name;
				for each(info in boneData.children())
				{
					nodeName = info.name();
					switch(nodeName){
						case POSITION:
							bone.position = new Vector3D(info.@x,info.@y,info.@z);
							break;
						case ROTATION:
							bone.angle = info.@angle;
							bone.axis = new Vector3D(info[AXIS].@x,info[AXIS].@y,info[AXIS].@z);
							break;
					}
				}
				m_jointList.push(bone);
				m_jointCache[bone.name] = bone;
			}
		}
		
		/**
		 * 骨骼的父级关系
		 */
		private function parseHierarchy(node : XML) : void
		{
			var boneParent : XML;
			var childBoneName : String;
			var parentBoneName : String;
			var bone : OGREJoint;
			for each(boneParent in node.children()){
				childBoneName = boneParent.@bone;
				parentBoneName = boneParent.@parent;
				bone = m_jointCache[childBoneName];
				if(parentBoneName == ROOT) bone.isRoot = true;
				else bone.parent = m_jointCache[parentBoneName];
			}
		}
		
		private function parseAnimation(node : XML) : void
		{
			animationName = node[ANIMATION].@name;
			animationDuration = node[ANIMATION].@length;
			
			var trackNode : XMLList = node[ANIMATION][TRACKS];
			var trackData : XML;
			var frameDataList : OGREFrameList;
			var frameData : OGREFrameData;
			var joint : OGREJoint;
			for each(trackData in trackNode.children())
			{
				frameDataList = new OGREFrameList();
				frameDataList.name = trackData.@bone;
				joint = m_jointCache[frameDataList.name];
				joint.frameDataList = frameDataList;
				var keyFrames : XML;
				for each(keyFrames in trackData.children())
				{
					var keyFrame : XML;
					for each(keyFrame in keyFrames.children())
					{
						frameData = new OGREFrameData();
						frameData.time = keyFrame.@time;
						frameData.translate = new Vector3D(keyFrame[TRANSLATE].@x,keyFrame[TRANSLATE].@y,keyFrame[TRANSLATE].@z);
						var angleData : XML = keyFrame[ROTATE][0];
						frameData.rotate = angleData.@angle;
						frameData.axis = new Vector3D(angleData[AXIS].@x,angleData[AXIS].@y,angleData[AXIS].@z);
						frameDataList.frameData.push(frameData);
					}
				}
			}
		}
		
		private var _textData : XML;
		private var m_jointCache : Dictionary = new Dictionary();
		private var m_jointList : Vector.<OGREJoint>;
		
		public var animationName : String;
		public var animationDuration : Number;
		
		/**骨骼根节点**/
		private static const ROOT : String = "Root";
		/**骨骼基本信息**/
		private static const BONES : String = "bones";
		/**骨骼差值信息**/
		private static const HIERARCHY : String = "bonehierarchy";
		/**骨骼动画集**/
		private static const ANIMATIONS : String = "animations";
		/**骨骼动画**/
		private static const ANIMATION : String = "animation";
		/**骨骼坐标**/
		private static const POSITION : String = "position";
		/**骨骼旋转**/
		private static const ROTATION : String = "rotation";
		private static const ROTATE : String = "rotate";
		/**骨骼坐标系**/
		private static const AXIS : String = "axis";
		/**动画帧信息**/
		private static const TRACKS : String = "tracks";
		private static const TRACK : String = "track";
		private static const KEY_FRAMES : String = "keyframes";
		private static const KEY_FRAME : String = "keyframe";
		private static const TRANSLATE : String = "translate";
	}
}