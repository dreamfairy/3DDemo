package C3.Ray
{
	import flash.geom.Vector3D;
	
	import C3.AABB;
	import C3.CubeMesh;
	import C3.IMesh;

	public class Ray
	{
		public var origin : Vector3D;
		public var direction : Vector3D;
		
		public function Ray()
		{
		}
		
		/**
		 * 包围球射线检测
		 * param o 射线原点
		 * param d 射线角度
		 * param c 圆心
		 * param r 半径
		 */
		public static function RaySphereIntersect(o : Vector3D, d : Vector3D, c : Vector3D, r : Number) : Boolean
		{
			var intersect : Boolean;
			var s : Number; 
			var l : Vector3D = c.subtract(o); //圆心到射线原点的距离
			s = d.dotProduct(l); //以射线起点开始,以射线的方向步进和包围球的长度的距离
			
			var ll : Number = l.length * l.length; //以射线的起点为圆心,以和包围球的距离为半径假设一个球形
			var rr : Number = r * r;
			
			if(s < 0 && ll > rr) return false; //s < 0 表示目标在射线之后， ll > rr 表示射线不在圆内
			
			var mm : Number = ll - s*s; //圆心垂直于射线方向的长度
			if(mm > rr) return false; //和射线构成的三角形不在圆内
			
			var q : Number = Math.sqrt(rr - mm); //圆心垂直于射线方向的点到射线碰撞的圆表面点的距离
			var t : Number; //射线起点和圆相交点的距离
			if(ll > rr)  //当射线在圆外
				t = s - q;
			else 
				t = s + q;
			
			return true;	
		}
		
		/**
		 * 包围球碰撞检测
		 */
		public static function raySphereIntTest(ray : Ray, cube : CubeMesh) : Boolean
		{
			var v : Vector3D = ray.origin.subtract(cube.position);
			var b : Number = 2 * ray.direction.dotProduct(v);
			var c : Number = v.dotProduct(v) - (2 * 2);
			
			var discriminant : Number = (b * b) - (4 * c);
			
			if(discriminant < 0)
				return false;
			
			discriminant = Math.sqrt(discriminant);
			
			var s0 : Number = (-b + discriminant) / 2;
			var s1 : Number = (-b - discriminant) / 2;
			
			if(s0 >= 0 || s1 >= 0)
				return true;
			
			return false;
		}
		
		/**
		 * AABB检测
		 */
		public static function rayAABBIntersect(ray : Ray, target : AABB) : Boolean
		{
			var length : Vector3D = target.center.subtract(ray.origin);
			var c : Vector3D = length;
			c.scaleBy(.5);
			var w : Vector3D = c.clone();
			w.normalize();
			
			var vx = Math.abs(w.x);
			var vy = Math.abs(w.y);
			var vz = Math.abs(w.z);
			
			if(Math.abs(c.x) > vx + target.hx) return false;
			if(Math.abs(c.y) > vy + target.hy) return false;
			if(Math.abs(c.z) > vz + target.hz) return false;
			if(Math.abs(c.y * w.z - c.z * w.y) > target.hy * vz + target.hz * vy) return false;
			if(Math.abs(c.x * w.z - c.z * w.x) > target.hx * vz + target.hz * vx) return false;
			if(Math.abs(c.x * w.y - c.y * w.x) > target.hy * vy + target.hy * vx) return false;
			
			return true;
		}
		
	}
}