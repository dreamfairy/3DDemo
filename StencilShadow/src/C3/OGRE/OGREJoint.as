package C3.OGRE
{
	import flash.geom.Matrix3D;
	import flash.geom.Orientation3D;
	import flash.geom.Vector3D;
	
	import C3.MD5.Quaternion;
	import C3.Parser.Model.IJoint;

	public class OGREJoint implements IJoint
	{
		private static var tempQua:Quaternion = new Quaternion();
		
		public var id : int;
		public var name : String;
		public var position : Vector3D;
		public var angle : Number;
		public var axis : Vector3D;
		public var parent : OGREJoint;
		public var scale : Vector3D = new Vector3D(1,1,1);
		
		public var invTranslation : Vector3D;
		public var invScale : Vector3D;
		public var invRotation : Quaternion;
		
		private var m_derivedTranslation : Vector3D;
		private var m_derivedScale : Vector3D;
		private var m_derivedRotation : Quaternion;
		private var m_dirty : Boolean = true;

		public var quaternion : Quaternion;
		public var children : Vector.<OGREJoint> = new Vector.<OGREJoint>();
		
		/**
		 * 当前骨骼的变化矩阵
		 */
		public var transformationMatrix:Matrix3D;
		
		
		public function OGREJoint() : void
		{
			transformationMatrix = new Matrix3D();
		}
		
		public function addChild(child : OGREJoint) : void
		{
			if(children.indexOf(child) == -1)
				children.push(child);
		}

		/**
		 * 获取偏移值
		 * 如果有父级，叠加上父级的偏移值
		 */
		public function getDerivedPosition() : Vector3D
		{
			if(null == parent)
				return position;
			
			if(m_dirty){
				var _parentScale : Vector3D = parent.getDerivedScale();
				var _derivedTranslation : Vector3D = parent.getDerivedOrientation().multiplyVector2(
					new Vector3D(
						_parentScale.x * position.x,
						_parentScale.y * position.y,
						_parentScale.z * position.z
					)
				);
				return m_derivedTranslation = _derivedTranslation.add(parent.getDerivedPosition());
			}
			
			return m_derivedTranslation;
		}
		
		/**
		 * 获取缩放
		 * 如果有父级，叠加上父级的缩放
		 */
		public function getDerivedScale() : Vector3D
		{
			if(null == parent)
				return scale;
			
			if(m_dirty){
				var _parentScale : Vector3D = parent.getDerivedScale();
				return m_derivedScale = new Vector3D(_parentScale.x * scale.x, _parentScale.y * scale.y, _parentScale.z * scale.z);
			}
			
			return m_derivedScale;
		}
		
		/**
		 * 获取四元数
		 * 如果有父级，叠加上父级的是四元数
		 */
		public function getDerivedOrientation() : Quaternion
		{
			if(null == parent)
				return quaternion;
			
			if(m_dirty)
			{
				return m_derivedRotation = parent.getDerivedOrientation().multiply2(quaternion, m_derivedRotation);
			}
			
			return m_derivedRotation;
		}
		
		/**
		 * 重新验证骨骼的旋转，位移和缩放
		 */
		public function invalidate():void{
			m_dirty = true;
			invalidateChildren();
		}
		
		private function invalidateChildren() : void
		{
			for each(var child : OGREJoint in children){
				child.invalidate();
			}
		}
		
		/**
		 * 更新骨骼，使用该骨骼父级骨骼，或者更新规定的矩阵作为当前的变换
		 * @param boneMatrix
		 * @return
		 */
		public function update(boneMatrix : Matrix3D = null) : Matrix3D
		{
			if(boneMatrix == null)
			{
				if(m_dirty){
					//获取骨骼派生的缩放
					var _dervedScale : Vector3D = getDerivedScale();
					
					//找到当前Scale的变化 通过移除当前Scale中的 Bind Pose的Scale
					var locScale : Vector3D = new Vector3D(
						_dervedScale.x * invScale.x,
						_dervedScale.y * invScale.y,
						_dervedScale.z * invScale.z
					);
					
					//找到当前Rotation变化 通过移除当前Rotation中的 Bind Pose 的 Rotation
					var _locRotate : Quaternion = getDerivedOrientation().multiply2(invRotation, tempQua);
					
					//合并位移 和 Bind Pose 的反转位移
					//位移是相对于缩放和旋转的
					//首先要反反转变换原来派生的位移到骨骼绑定空间
					//然后变换当前的派生骨骼空间
					var _locTranslate : Vector3D = getDerivedPosition().add(
						_locRotate.multiplyVector2(
							new Vector3D(
								locScale.x * invTranslation.x,
								locScale.y * invTranslation.y,
								locScale.z * invTranslation.z
							)
						)
					);
					transformationMatrix.recompose( Vector.<Vector3D>([_locTranslate, _locRotate.toVector3D(), locScale]), Orientation3D.QUATERNION);
//					transformationMatrix.transpose();
					
					m_dirty = false;
				}
			}else{
				transformationMatrix.copyFrom(boneMatrix);
			}
			
			return transformationMatrix;
		}
		
		public function setBindPose() : void
		{
			invTranslation = getDerivedPosition().clone();
			invTranslation.negate();
			
			var _derivedScale : Vector3D = getDerivedScale();
			invScale = new Vector3D(1/_derivedScale.x,1/_derivedScale.y,1/_derivedScale.z);
			
			var qua : Quaternion = getDerivedOrientation();
			invRotation = qua.inverse();
			
//			trace("父级",name);
//			for each(var child : OGREJoint in children){
//				trace("子集",child.name);
//			}
		}
	}
}