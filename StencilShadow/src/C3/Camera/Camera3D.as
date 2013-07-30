package C3.Camera
{
	import com.adobe.utils.PerspectiveMatrix3D;
	
	import flash.geom.Matrix3D;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;

	public class Camera3D implements ICamera
	{
		//近平面最小距离
		public static const MIN_NEAR_DISTANCE : Number = 0.001;
		//远近平面间最小距离
		public static const MIN_PLANE_SEPARATION : Number = 0.001;
		
		/**视口**/
		private var m_viewport : Rectangle;
		
		/**相机位置**/
		private var m_position : Vector3D;
		
		/**相机目标**/
		private var m_target : Vector3D;
		
		/**上方向**/
		private var m_upDir : Vector3D;
		
		/**上方向**/
		private var m_realUpDir : Vector3D;
		
		/**近切面距离**/
		private var m_near : Number;
		
		/**远切面距离**/
		private var m_far : Number;
		
		/**宽高比**/
		private var m_aspect : Number;
		
		/**视野**/
		private var m_vFov : Number;
		
		/**世界到相机**/
		private var m_worldToView : Matrix3D;
		
		/**相机到投影**/
		private var m_viewToClip : Matrix3D;
		
		/**世界到投影**/
		private var m_worldToClip : Matrix3D;
		
		/**相机朝向**/
		private var m_viewDir : Vector3D;
		
		/**朝向量级**/
		private var m_viewDirMag : Number;
		
		/**相机右向**/
		private var m_rightDir : Vector3D;
		
		/**临时矩阵，用来计算 世界->相机 计算**/
		private var m_tempWorldToViewMatrix : Matrix3D;
		
		//全局灯光
		private var m_lightTarget : Vector3D;
		private var m_lightPos : Vector3D;
		private var m_lightMatrix : Matrix3D;
		
		/**投影**/
		private var m_proj : PerspectiveMatrix3D = new PerspectiveMatrix3D();
		
		public function Camera3D(
			near : Number,
			far : Number,
			aspect : Number,
			vFOV : Number,
			positionX : Number,
			positionY : Number,
			positionZ : Number,
			targetX : Number,
			targetY : Number,
			targetZ : Number,
			upDirX : Number,
			upDirY : Number,
			upDirZ : Number)
		{
			if(near < MIN_NEAR_DISTANCE){
				near = MIN_NEAR_DISTANCE;
			}
			
			if(far < near + MIN_PLANE_SEPARATION){
				far = near + MIN_PLANE_SEPARATION;
			}
			
			m_near = near;
			m_far = far;
			m_aspect = aspect;
			m_vFov = vFOV;
			m_position = new Vector3D(positionX,positionY,positionZ);
			m_target = new Vector3D(targetX,targetY,targetZ);
			m_upDir = new Vector3D(upDirX,upDirY,upDirZ);
			m_upDir.normalize();
			
			m_viewDir = new Vector3D();
			m_rightDir = new Vector3D();
			m_realUpDir = new Vector3D();
			m_tempWorldToViewMatrix = new Matrix3D();
			
			m_worldToView = new Matrix3D();
			m_viewToClip = new Matrix3D();
			m_worldToClip = new Matrix3D();
			
			m_proj = new PerspectiveMatrix3D();
			
			updateWorldToView();
			updateViewToClip();
			updateWorldToClip();
		}
		
		public function setGlobalLightPos(vx : Number, vy : Number, vz : Number) : void
		{
			GlobalLightPos.setTo(vx,vy,vz);
		}
		
		public function setGlobalLightTarget(vx : Number, vy : Number, vz : Number) : void
		{
			GlobalLightTarget.setTo(vx,vy,vz);
		}
		
		public function get lightProjection() : Matrix3D
		{
			m_lightMatrix||=new Matrix3D();
			
			m_lightMatrix.identity();
			m_lightMatrix.appendTranslation(GlobalLightPos.x,GlobalLightPos.y,GlobalLightPos.z);
			m_lightMatrix.pointAt(GlobalLightTarget,Camera.CAM_FACING,Camera.CAM_UP);
			m_lightMatrix.invert();
			m_lightMatrix.append(m_proj);
			
			return m_lightMatrix;
		}
		
		public function get viewport() : Rectangle
		{
			return m_viewport;
		}
		
		public function set viewport(vp : Rectangle) : void
		{
			m_viewport = vp;
		}
		
		public function get projectMatrix() : Matrix3D
		{
			return m_viewToClip;
		}
		
		public function get viewMatrix() : Matrix3D
		{
			return m_worldToView;
		}
		
		public function get viewProjMatrix():Matrix3D
		{
			return m_worldToClip;
		}
		
		public function get positionX() : Number
		{
			return m_position.x;
		}
		
		public function set positionX(x : Number) : void
		{
			m_position.x = x;
			
			updateWorldToView();
			updateWorldToClip();
		}
		
		public function get positionY() : Number
		{
			return m_position.y;
		}
		
		public function set positionY(y : Number) : void
		{
			m_position.y = y;
			
			updateWorldToView();
			updateViewToClip();
		}
		
		public function get positionZ() : Number
		{
			return m_position.z;
		}
		
		public function set positionZ(z : Number) : void
		{
			m_position.z = z;
			
			updateWorldToView();
			updateWorldToClip();
		}
		
		public function setPositionValues(x : Number, y : Number, z : Number) : void
		{
			m_position.x = x;
			m_position.y = y;
			m_position.z = z;
			
			updateWorldToView();
			updateWorldToClip();
		}
		
		public function get targetX() : Number
		{
			return m_target.x;
		}
		
		public function set targetX(x : Number) : void
		{
			m_target.x = x;
			
			updateWorldToView();
			updateWorldToClip();
		}
		
		public function get targetY() : Number
		{
			return m_target.z
		}
		
		public function set targetY(y : Number) : void
		{
			m_target.y = y;
			
			updateWorldToView();
			updateWorldToClip();
		}
		
		public function get targetZ() : Number
		{
			return m_target.z;
		}
		
		public function set targetZ(z : Number) : void
		{
			m_target.z = z;
			
			updateWorldToView();
			updateWorldToClip();
		}
		
		public function setTargetValues(x : Number, y : Number, z : Number) : void
		{
			m_target.x = x;
			m_target.y = y;
			m_target.z = z;
			
			updateWorldToView();
			updateWorldToClip();
		}
		
		public function get near() : Number
		{
			return m_near;
		}
		
		public function set near(near : Number) : void
		{
			m_near = near;
			
			updateWorldToView();
			updateWorldToClip();
		}
		
		public function get far() : Number
		{
			return m_far;
		}
		
		public function set far(far : Number) : void
		{
			m_far = far;
			
			updateWorldToView();
			updateWorldToClip();
		}
		
		public function get vFOV() : Number
		{
			return m_vFov;
		}
		
		public function set vFOV(vFOV : Number) : void
		{
			m_vFov = vFOV;
			
			updateWorldToView();
			updateWorldToClip();
		}
		
		public function get aspect() : Number
		{
			return m_aspect;
		}
		
		public function set aspect(aspect : Number) : void
		{
			m_aspect = aspect;
			
			updateWorldToView();
			updateWorldToClip();
		}
		
		public function moveForward(units : Number) : void
		{
			moveAlongAxis(units, m_viewDir);
		}
		
		public function moveBackward(units : Number) : void
		{
			moveAlongAxis(-units, m_viewDir);
		}
		
		public function moveRight(units : Number) : void
		{
			moveAlongAxis(units, m_rightDir);
		}
		
		public function moveLeft(units : Number) : void
		{
			moveAlongAxis(-units, m_rightDir);
		}
		
		public function moveUp(units : Number) : void
		{
			moveAlongAxis(units, m_upDir);
		}
		
		public function moveDown(units : Number) : void
		{
			moveAlongAxis(-units, m_upDir);
		}
		
		private function moveAlongAxis(units : Number, axis : Vector3D) : void
		{
			var delta : Vector3D = axis.clone();
			delta.scaleBy(units);
			
			var newPos : Vector3D = m_position.add(delta);
			setPositionValues(newPos.x,newPos.y,newPos.z);
			
			var newTarget : Vector3D = m_target.add(delta);
			setTargetValues(newTarget.x,newTarget.y,newTarget.z);
		}
		
		public function yaw(numDegrees : Number) : void
		{
			rotate(numDegrees, m_realUpDir);
		}
		
		public function pitch(numDegrees : Number) : void
		{
			rotate(numDegrees, m_rightDir);
		}
		
		public function roll(numDegrees : Number) : void
		{
			if(isNaN(numDegrees)) return;
			
			numDegrees = - numDegrees;
			
			var rotMat : Matrix3D = new Matrix3D();
			rotMat.appendRotation(numDegrees, m_viewDir);
			
			m_upDir = rotMat.transformVector(m_upDir);
			m_upDir.normalize();
			
			updateWorldToView();
			updateWorldToClip();
		}
		
		/**
		 * 根据坐标旋转
		 */
		private function rotate(numDegrees : Number, axis : Vector3D) : void
		{
			if(isNaN(numDegrees)) return;
			
			numDegrees = -numDegrees;
			
			var rotMat : Matrix3D = new Matrix3D();
			rotMat.appendRotation(numDegrees, axis);
			
			var rotatedViewDir : Vector3D = rotMat.transformVector(m_viewDir);
			rotatedViewDir.scaleBy(m_viewDirMag);
			
			var newTarget : Vector3D = m_position.add(rotatedViewDir);
			
			setTargetValues(newTarget.x,newTarget.y,newTarget.z);
		}
		
		/**
		 * 计算相机矩阵
		 */
		private function updateWorldToView() : void
		{
			var viewDir : Vector3D = m_viewDir;
			viewDir.x = m_target.x - m_position.x;
			viewDir.y = m_target.y - m_position.y;
			viewDir.z = m_target.z - m_position.z;
			m_viewDirMag = m_viewDir.normalize();
			
			//up 已经归一化过了
			var upDir : Vector3D = m_upDir;
			
			//right = 朝向 叉乘 上方向
			var rightDir : Vector3D = m_rightDir;
			rightDir.x = m_viewDir.y * m_upDir.z - m_viewDir.z * m_upDir.y;
			rightDir.y = m_viewDir.z * m_upDir.x - m_viewDir.x * m_upDir.z;
			rightDir.z = m_viewDir.x * m_upDir.y - m_viewDir.y * m_upDir.x;
			
			//readlUpDir = 右方向 X 朝向
			var realUpDir : Vector3D = m_realUpDir;
			realUpDir.x = rightDir.y*viewDir.z - rightDir.z*viewDir.y;
			realUpDir.y = rightDir.z*viewDir.x - rightDir.x*viewDir.z;
			realUpDir.z = rightDir.x*viewDir.y - rightDir.y*viewDir.x;

			
			//转换位移
			m_worldToView.identity();
			m_worldToView.appendTranslation(m_position.x,m_position.y,m_position.z);
			
			//朝向矩阵
			var rawData : Vector.<Number> = m_tempWorldToViewMatrix.rawData;
			rawData[0] = rightDir.x;
			rawData[1] = rightDir.y;
			rawData[2] = rightDir.z;
			rawData[3] = 0;
			rawData[4] = realUpDir.x;
			rawData[5] = realUpDir.y;
			rawData[6] = realUpDir.z;
			rawData[7] = 0;
			rawData[8] = -viewDir.x;
			rawData[9] = -viewDir.y;
			rawData[10] = -viewDir.z;
			rawData[11] = 0;
			rawData[12] = 0;
			rawData[13] = 0;
			rawData[14] = 0;
			rawData[15] = 1;

			m_tempWorldToViewMatrix.rawData = rawData;
			m_worldToView.prepend(m_tempWorldToViewMatrix);
		}
		
		/**
		 * 更新相机到投影矩阵
		 */
		private function updateViewToClip() : void
		{
			m_proj.perspectiveFieldOfViewRH(m_vFov,m_aspect,m_near,m_far);
			m_viewToClip.rawData = m_proj.rawData;
		}
		
		/**
		 * 更是世界到投影矩阵
		 */
		private function updateWorldToClip() : void
		{
			m_worldToClip.identity();
			m_worldToView.invert();
			m_worldToClip.append(m_worldToView);
			m_worldToClip.append(m_viewToClip);
		}
		
		private function get GlobalLightPos() : Vector3D
		{
			m_lightPos||=new Vector3D();
			return m_lightPos;
		}
		
		private function get GlobalLightTarget() : Vector3D
		{
			m_lightTarget||=new Vector3D();
			return m_lightTarget;
		}
	}
}