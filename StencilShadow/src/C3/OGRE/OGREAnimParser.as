package C3.OGRE
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import C3.MD5.Quaternion;
	import C3.Parser.Model.IJoint;

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
			
			
			for each(var parentJoint : JointTree in m_jointTree){
				for each(var childJoint : JointTree in m_jointTree){
					//如果是相同对象，跳过
					if(childJoint.NodeJoint.name == parentJoint.NodeJoint.name) continue;
					//如果是父亲
					if(childJoint.NodeJoint.parent && childJoint.NodeJoint.parent.name == parentJoint.NodeJoint.name){
						parentJoint.push(childJoint);
					}
				}
			}
			
			var jointTree : JointTree = m_jointTree[m_rootBoneName];
			m_jointTree = null;
			
			m_jointList = new Vector.<IJoint>();
			getChildren(m_jointList, jointTree);
			
			
			setBindPose();
			
			this.dispatchEvent(new Event(Event.COMPLETE));
		}
		
		private function setBindPose() : void
		{
			var len : uint = m_jointList.length;
			for(var i : int = 0; i < len; i++)
			{
				m_jointList[i].setBindPose();
			}
		}
		
		private function getChildren(list : Vector.<IJoint>, tree : JointTree) : void
		{
			list.push(tree.NodeJoint);
			if(!tree.NodeJoint.hasCalc)tree.NodeJoint.calc();
			while(tree.children.length){
				getChildren(list,tree.children.shift());
			}
		}
		
		private function jointSortFun(joint1 : OGREJoint, joint2 : OGREJoint) : int
		{
			return joint1.id > joint2.id ? 0 : -1;
		}
		
		private function parseBone(node : XML) : void
		{
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
							bone.position = new Vector3D(info.@x,info.@y,info.@z,1);
							break;
						case ROTATION:
							bone.angle = info.@angle;
							bone.axis = new Vector3D(info[AXIS].@x,info[AXIS].@y,info[AXIS].@z);
							bone.quaternion = new Quaternion();
							bone.quaternion.fromAxisAngle(bone.axis,bone.angle);
							break;
					}
				}
				m_jointCache[bone.name] = bone;
				m_jointTree[bone.name] = new JointTree(bone);
				
				if(bone.name == ROOT)
					m_rootBoneName = bone.name;
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
			var tree : JointTree;
			
			for each(boneParent in node.children()){
				childBoneName = boneParent.@bone;
				parentBoneName = boneParent.@parent;
				bone = m_jointCache[childBoneName];
				bone.parent = m_jointCache[parentBoneName];
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
						
						if(keyFrame.hasOwnProperty(TRANSLATE)){
							frameData.translate = new Vector3D(keyFrame[TRANSLATE].@x,keyFrame[TRANSLATE].@y,keyFrame[TRANSLATE].@z);
						}
						
						if(keyFrame.hasOwnProperty(SCALE)){
							frameData.translate = new Vector3D(keyFrame[SCALE].@x,keyFrame[SCALE].@y,keyFrame[SCALE].@z);
						}
						
						if(keyFrame.hasOwnProperty(ROTATE)){
							var angleData : XML = keyFrame[ROTATE][0];
							frameData.rotate = angleData.@angle;
							frameData.axis = new Vector3D(angleData[AXIS].@x,angleData[AXIS].@y,angleData[AXIS].@z);
						}
						
						frameDataList.frameData.push(frameData);
					}
				}
			}
		}
		
		public function get joints() : Vector.<IJoint>
		{
			return m_jointList;
		}
		
		private var m_rootBoneName : String;
		private var _textData : XML;
		private var m_jointCache : Dictionary = new Dictionary();
		private var m_jointList : Vector.<IJoint>;
		private var m_jointTree : Dictionary = new Dictionary();
		
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
		/**骨骼缩放**/
		private static const SCALE : String = "scale";
		/**动画帧信息**/
		private static const TRACKS : String = "tracks";
		/**无动画骨骼**/
		private static const BIND : String = "Bind";
		private static const TRACK : String = "track";
		private static const KEY_FRAMES : String = "keyframes";
		private static const KEY_FRAME : String = "keyframe";
		private static const TRANSLATE : String = "translate";
	}
}
import C3.OGRE.OGREJoint;

class JointTree
{
	public var isNode : Boolean = false;
	public var NodeJoint : OGREJoint;
	public var children : Array = [];
	public var name : String;
	public var level : int = 0;
	
	public function JointTree(node : OGREJoint) : void
	{
		NodeJoint = node;
		name = node.name;
	}
	
	public function push(target : JointTree) : void
	{
		children.push(target);
		level+= target.children.length;
	}
}