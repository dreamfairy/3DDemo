package C3.Camera
{
	import com.adobe.utils.PerspectiveMatrix3D;
	
	import flash.geom.Matrix3D;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	
	import C3.IDispose;
	import C3.View;

	public class Camera implements IDispose
	{
		public function Camera(isRH : Boolean = true)
		{
			m_isRH = isRH;
		}
		
		public function set viewport(rect : Rectangle) : void
		{
			m_viewPort = rect;
			updateProjMatrix();
		}
		
		public function get viewport() : Rectangle
		{
			return m_viewPort;
		}
		
		public function set parent(target : View) : void
		{
			m_parent = target;
//			m_parent.stage.addEventListener(MouseEvent.CLICK, onClick);
		}
		
		public function get fov() : Number
		{
			return m_fov;
		}
		
		public function set fov(value : Number) : void
		{
			m_fov = value;
			updateProjMatrix();
		}
		
		public function get zNear() : Number
		{
			return m_zNear;
		}
		
		public function set zNear(value : Number) : void
		{
			m_zNear = value;
			updateProjMatrix();
		}
		
		public function get zFar() : Number
		{
			return m_zFar;
		}
		
		public function set zFar(value : Number) : void
		{
			m_zFar = value;
			updateProjMatrix();
		}
		
		//更新投影矩阵
		private function updateProjMatrix() : void
		{
			m_proj.perspectiveFieldOfViewRH(m_fov,m_viewPort.width/m_viewPort.height,m_zNear,m_zFar);
		}
		
		/**
		private function onClick(e:MouseEvent) : void
		{
			var p : Vector.<Number> = m_parent.projMatrix.rawData;
			
			//将屏幕坐标转换到设备坐标
			var stage : Stage = e.target as Stage;
			var vx : Number = (2*stage.mouseX/View.viewport.width - 1);
			var vy : Number = (-2*stage.mouseY/View.viewport.height + 1);
			
			//创建拾取射线
			var rayOrigin : Vector3D = new Vector3D();
			var rayDir : Vector3D = new Vector3D();
			getPickingRay(vx,vy,rayOrigin,rayDir);
		}
		
		public function getPickingRay(xUnit : Number, yUnit : Number, intoOrigin : Vector3D, intoDir : Vector3D) : void
		{
			//射线原点为相机位置
			intoOrigin.x = m_pos.x;
			intoOrigin.y = m_pos.y;
			intoOrigin.z = m_pos.z;
			intoOrigin.w = 1;
			
			var aspect : Number = View.viewport.width/View.viewport.height;
			var nearPlaneHeight : Number = zNear * Math.tan(fov);
			var nearPlaneWidth : Number = nearPlaneHeight * aspect;
			
			var rightOffset : Number = xUnit * nearPlaneWidth;
			var upOffset : Number = yUnit * nearPlaneHeight;
			
			//dir = viewDir * near + rightDir * rightOffset + readlUpDir * upOffset
//			intoDir.x = m_look.x * zNear + 
		}**/
	
		
		public function unproject(x : Number, y : Number, z : Number) : Vector3D
		{
			var v : Vector3D = new Vector3D(x,y,z,1);
			
			v = m_transform.transformVector(v);
			
			//计算缩放
			var inv : Number = 1 / v.w;
			
			v.x *= inv;
			v.y *= inv;
			v.z *= inv;
			v.w = 1.0;
			
			return v;
		}
		
		/**
		 * 平移
		 */
		public function strafe(units : Number) : void
		{
			if(m_type == LANDOBJECT){
				m_tempVector.setTo(m_right.x,0,m_right.z);
				m_tempVector.scaleBy(units);
				m_pos = m_pos.add(m_tempVector);
			}
			
			if(m_type == AIRCRAFT){
				m_tempVector.setTo(m_right.x,m_right.y,m_right.z);
				m_tempVector.scaleBy(units);
				m_pos = m_pos.add(m_tempVector);
			}
		}
		
		/**
		 * 飞行
		 */
		public function fly(units : Number) : void
		{
			if(m_type == LANDOBJECT)
				m_pos.y += units;
			
			if(m_type == AIRCRAFT){
				m_tempVector.setTo(m_up.x,m_up.y,m_up.z);
				m_tempVector.scaleBy(units);
				m_pos = m_pos.add(m_tempVector);
			}
		}
		
		/**
		 * 行走
		 */
		public function walk(units : Number) : void
		{
			if(m_type == LANDOBJECT){
				m_tempVector.setTo(m_look.x,0,m_look.z);
				m_tempVector.scaleBy(units);
				m_pos = m_pos.add(m_tempVector);
			}
				
			
			if(m_type == AIRCRAFT){
				m_tempVector.setTo(m_look.x,m_look.y,m_isRH ? -m_look.z : m_look.z);
				m_tempVector.scaleBy(units);
				m_pos = m_pos.add(m_tempVector);
			}
		}
		
		/**
		 * 倾斜
		 */
		public function pitch(angle : Number) : void
		{
			m_tempMat.identity();
			m_tempMat.appendRotation(angle,m_right);
			
			//绕右侧向量旋转up,look
			m_up = m_tempMat.deltaTransformVector(m_up);
			m_look = m_tempMat.deltaTransformVector(m_look);
		}
		
		/**
		 * 偏航
		 */
		public function yaw(angle : Number) : void
		{
			m_tempMat.identity();
			if(m_type == LANDOBJECT)
				m_tempMat.appendRotation(angle, m_up);
			
			if(m_type == AIRCRAFT)
				m_tempMat.appendRotation(angle,m_up);
			
			//绕up或者y轴旋转right,look
			m_right = m_tempMat.deltaTransformVector(m_right);
			m_look = m_tempMat.deltaTransformVector(m_look);
		}
		
		/**
		 * 翻滚
		 */
		public function roll(angle : Number) : void
		{
			//只用空间相机支持
			if(m_type == AIRCRAFT){
				m_tempMat.identity();
				m_tempMat.appendRotation(angle, m_look);
				
				//绕look旋转up,right
				m_right = m_tempMat.deltaTransformVector(m_right);
				m_up = m_tempMat.deltaTransformVector(m_up);
			}
		}
		
		public function getViewMatrix() : Matrix3D
		{
			if(m_replaceMatrix) return m_replaceMatrix;
			
			//使相机的各坐标系互相垂直
			m_look.normalize();
			m_up = m_look.crossProduct(m_right);//up向量和look及right成直角
			m_up.normalize();
			m_right = m_up.crossProduct(m_look);//right向量和up及look成直角
			m_right.normalize();
			
			//计算视图矩阵
			var x : Number = -m_right.dotProduct(m_pos); //计算右侧到原点的距离
			var y : Number = -m_up.dotProduct(m_pos);
			var z : Number = -m_look.dotProduct(m_pos);
			
			var rawData : Vector.<Number> = m_transform.rawData;
			rawData[0] = m_right.x;
			rawData[1] = m_up.x;
			rawData[2] = m_look.x;
			rawData[3] = 0;
			
			rawData[4] = m_right.y;
			rawData[5] = m_up.y;
			rawData[6] = m_look.y;
			rawData[7] = 0;
			
			rawData[8] = m_right.z;
			rawData[9] = m_up.z;
			rawData[10] = m_look.z;
			rawData[11] = 0;
			
			rawData[12] = x;
			rawData[13] = y;
			rawData[14] = z;
			rawData[15] = 1;

			m_transform.copyRawDataFrom(rawData);
			
//			m_transform.pointAt(m_target,CAM_FACING,CAM_UP);

			return m_transform;
		}
		
		/**
		 * 替换相机矩阵
		 */
		public function replaceViewMatrix(matrix : Matrix3D) : void
		{
			m_replaceMatrix = matrix;
		}
		
		/**
		 * 还原相机矩阵
		 */
		public function restoreViewMatrix() : void
		{
			m_replaceMatrix = null;
		}
		
		public function setLook(x : Number, y : Number, z : Number) : void
		{
			m_look.setTo(x,y,z);
		}
		
		public function setTargetObjectPoint(target : Vector3D) : void
		{
			m_target.setTo(target.x,target.y,target.z);
		}
		
		public function setTarget(x : Number, y : Number, z : Number) : void
		{
			m_target.setTo(x,y,z);
//			m_target.negate();
		}
		
		public function setCameraType(type : uint) : void
		{
			m_type = type;
		}
		
		public function get Position() : Vector3D
		{
			return m_pos;
		}
		
		public function set Position(pos : Vector3D) : void
		{
			m_pos.setTo(pos.x,pos.y,pos.z);
		}
		
		public function getRight() : Vector3D
		{
			return m_right;
		}
		
		public function getUp() : Vector3D
		{
			return m_up;
		}
		
		public function getLook() : Vector3D
		{
			return m_look;
		}
		
		public function get projectMatrix() : Matrix3D
		{
			return m_proj;
		}
		
		public function get viewProjMatrix() : Matrix3D
		{
			var viewProj : Matrix3D = getViewMatrix();
			viewProj.append(m_proj);
			return viewProj;
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
			m_lightMatrix.pointAt(GlobalLightTarget,CAM_FACING,CAM_UP);
			m_lightMatrix.invert();
			m_lightMatrix.append(m_proj);
			
			return m_lightMatrix;
		}
		
		public function dispose():void
		{
			m_lightPos = null;
			m_lightMatrix = null;
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
		
		public static const CAM_FACING:Vector3D = new Vector3D(0, 0, -1);
		public static const CAM_UP:Vector3D = new Vector3D(0, -1, 0);
		
		private var m_isRH : Boolean;
		
		private var m_tempVector : Vector3D = new Vector3D();
		private var m_tempMat : Matrix3D = new Matrix3D();
		
		private var m_transform : Matrix3D = new Matrix3D();
		private var m_followTransForm : Matrix3D = new Matrix3D();
		
		private var m_right : Vector3D = new Vector3D(1,0,0);
		private var m_up : Vector3D = new Vector3D(0,1,0);
		private var m_look : Vector3D = new Vector3D(0,0,1);
		private var m_pos : Vector3D = new Vector3D(0,0,0);
		private var m_target : Vector3D = new Vector3D();
		private var m_parent : View;
		private var m_type : uint;
		
		//投影矩阵
		private var m_proj : PerspectiveMatrix3D = new PerspectiveMatrix3D();
		
		//视图区域
		private var m_viewPort : Rectangle;
		private var m_zNear : Number = 1;
		private var m_zFar : Number = 1000;
		private var m_fov : Number = 45;
		
		//替换的相机矩阵
		private var m_replaceMatrix : Matrix3D;
		
		//全局灯光
		private var m_lightTarget : Vector3D;
		private var m_lightPos : Vector3D;
		private var m_lightMatrix : Matrix3D;
		
		public static var TEMP_FINAL_MATRIX : Matrix3D = new Matrix3D();
		
		public static const LANDOBJECT : uint = 0;
		public static const AIRCRAFT : uint = 1;
	}
}