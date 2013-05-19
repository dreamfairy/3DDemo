package C3
{
	import flash.geom.Vector3D;

	public class Plane
	{
		private var m_d : Number = 0;
		private var m_n : Vector3D;
		private var m_p : Vector3D;
		
		/**
		 * n为平面法向量
		 * p为平面上的一点
		 */
		public function Plane(n : Vector3D, p : Vector3D)
		{
			m_n = n;
			m_p = p;
			
			m_d = -m_n.dotProduct(m_p);
		}
		
		/**
		 * 计算该平面的反射矩阵
		 */
		public function reflect(out : Vector.<Number>) : void
		{
			m_n.normalize();
			m_d = -m_n.dotProduct(m_p);
			
			if(!out)out = new Vector.<Number>();
			out.splice(0,out.length);
			
			out.push(-2 * m_n.x * m_n.x + 1);
			out.push(-2 * m_n.y * m_n.x);
			out.push(-2 * m_n.z + m_n.x);
			out.push(0);
			
			out.push(-2 * m_n.x * m_n.y);
			out.push(-2 * m_n.y * m_n.y + 1);
			out.push(-2 * m_n.z * m_n.y);
			out.push(0);
			
			out.push(-2 * m_n.x * m_n.z);
			out.push(-2 * m_n.y * m_n.z);
			out.push(-2 * m_n.z * m_n.z + 1);
			out.push(0);
			
			out.push(-2 * m_n.x * m_d);
			out.push(-2 * m_n.y * m_d);
			out.push(-2 * m_n.z * m_d);
			out.push(1);
		}
		
		public function get n() : Vector3D
		{
			return m_n;
		}
		
		public function get p() : Vector3D
		{
			return m_p;
		}
	}
}