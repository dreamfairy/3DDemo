package C3.Camera
{
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	import C3.TeapotMesh;

	public class Camera
	{
		public function Camera(isRH : Boolean = true)
		{
			m_isRH = isRH;
		}
		
		public function target(target : TeapotMesh) : void
		{
			m_target = target;
		}
		
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

			return m_transform;
		}
		
		public function setLook(x : Number, y : Number, z : Number) : void
		{
			m_look.setTo(x,y,z);
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
		
		private static const CAM_FACING:Vector3D = new Vector3D(0, 0, -1);
		private static const CAM_UP:Vector3D = new Vector3D(0, -1, 0);
		
		private var m_isRH : Boolean;
		
		private var m_tempVector : Vector3D = new Vector3D();
		private var m_tempMat : Matrix3D = new Matrix3D();
		
		private var m_transform : Matrix3D = new Matrix3D();
		private var m_followTransForm : Matrix3D = new Matrix3D();
		
		private var m_right : Vector3D = new Vector3D(1,0,0);
		private var m_up : Vector3D = new Vector3D(0,1,0);
		private var m_look : Vector3D = new Vector3D(0,0,1);
		private var m_pos : Vector3D = new Vector3D(0,0,10);
		private var m_type : uint;
		private var m_target : TeapotMesh;
		
		public static const LANDOBJECT : uint = 0;
		public static const AIRCRAFT : uint = 1;
	}
}