package C3.Ray
{
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	
	import C3.AABB;
	import C3.CubeMesh;
	import C3.Mesh.IMesh;
	import C3.Camera.Camera;

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
			
			var vx : Number = Math.abs(w.x);
			var vy : Number = Math.abs(w.y);
			var vz : Number = Math.abs(w.z);
			
			if(Math.abs(c.x) > vx + target.hx) return false;
			if(Math.abs(c.y) > vy + target.hy) return false;
			if(Math.abs(c.z) > vz + target.hz) return false;
			if(Math.abs(c.y * w.z - c.z * w.y) > target.hy * vz + target.hz * vy) return false;
			if(Math.abs(c.x * w.z - c.z * w.x) > target.hx * vz + target.hz * vx) return false;
			if(Math.abs(c.x * w.y - c.y * w.x) > target.hy * vy + target.hy * vx) return false;
			
			return true;
		}
		
		/**
		 * Away3D AABB
		 */
		public static function rayAway3DAABBIntersect(x : Number, y : Number, ray : Ray, view : Matrix3D, camera : Camera, target : CubeMesh) : Boolean
		{	
			//射线位置
			var rayPosition : Vector3D = camera.unproject(x,y,0);
			
			//射线方向
			var rayDirection : Vector3D = camera.unproject(x,y,1);
			rayDirection = rayDirection.subtract(rayPosition);
			
			var localRayPosiiton : Vector3D;
			var localRayDirection : Vector3D;
			
			var rayEntryDistence : Number;
			var normal : Vector3D = new Vector3D();
			
			//射线转换到实体空间
			var invertMat : Matrix3D = new Matrix3D();
			invertMat.copyFrom(camera.getViewMatrix());
			invertMat.prepend(target.transform);
			invertMat.invert();
			localRayPosiiton = invertMat.transformVector(rayPosition);
			localRayDirection = invertMat.deltaTransformVector(rayDirection);
			
			//边界检测
			rayEntryDistence = rayIntersection(target.position, localRayPosiiton, localRayDirection, normal);
			
			if(rayEntryDistence >= 0){
				trace("碰撞！",rayEntryDistence);
				return true;
			}else{
				trace("未碰撞！",rayEntryDistence);
			}
			return false;
		}
		
		private static function rayIntersection(cubePos : Vector3D, position : Vector3D, direction : Vector3D, targetNormal : Vector3D) : Number
		{
			if(containsPoint(position,cubePos)) return 0;
			
			var px : Number = position.x - cubePos.x;
			var py : Number = position.y - cubePos.y;
			var pz : Number = position.z - cubePos.z;
			var vx : Number = direction.x;
			var vy : Number = direction.y;
			var vz : Number = direction.z;
			var ix : Number, iy : Number, iz : Number;
			var rayEntryDistance : Number;
			var _halfExtentsX : Number = 2, _halfExtentsY : Number = 2, _halfExtentsZ : Number = 2;
			
			// ray-plane tests
			var intersects : Boolean;
			if (vx < 0) { //射线在AABB的左侧
				rayEntryDistance = ( _halfExtentsX - px ) / vx;
				if (rayEntryDistance > 0) {
					iy = py + rayEntryDistance * vy;
					iz = pz + rayEntryDistance * vz;
					if (iy > -_halfExtentsY && iy < _halfExtentsY && iz > -_halfExtentsZ && iz < _halfExtentsZ) {
						targetNormal.x = 1;
						targetNormal.y = 0;
						targetNormal.z = 0;
						
						intersects = true;
					}
				}
			}
			if (!intersects && vx > 0) { //射线指向在AABB右侧
				rayEntryDistance = ( -_halfExtentsX - px ) / vx; //归一化
				if (rayEntryDistance > 0) {
					iy = py + rayEntryDistance * vy;
					iz = pz + rayEntryDistance * vz;
					if (iy > -_halfExtentsY && iy < _halfExtentsY && iz > -_halfExtentsZ && iz < _halfExtentsZ) {
						targetNormal.x = -1;
						targetNormal.y = 0;
						targetNormal.z = 0;
						intersects = true;
					}
				}
			}
			if (!intersects && vy < 0) {
				rayEntryDistance = ( _halfExtentsY - py ) / vy;
				if (rayEntryDistance > 0) {
					ix = px + rayEntryDistance * vx;
					iz = pz + rayEntryDistance * vz;
					if (ix > -_halfExtentsX && ix < _halfExtentsX && iz > -_halfExtentsZ && iz < _halfExtentsZ) {
						targetNormal.x = 0;
						targetNormal.y = 1;
						targetNormal.z = 0;
						intersects = true;
					}
				}
			}
			if (!intersects && vy > 0) {
				rayEntryDistance = ( -_halfExtentsY - py ) / vy;
				if (rayEntryDistance > 0) {
					ix = px + rayEntryDistance * vx;
					iz = pz + rayEntryDistance * vz;
					if (ix > -_halfExtentsX && ix < _halfExtentsX && iz > -_halfExtentsZ && iz < _halfExtentsZ) {
						targetNormal.x = 0;
						targetNormal.y = -1;
						targetNormal.z = 0;
						intersects = true;
					}
				}
			}
			if (!intersects && vz < 0) {
				rayEntryDistance = ( _halfExtentsZ - pz ) / vz;
				if (rayEntryDistance > 0) {
					ix = px + rayEntryDistance * vx;
					iy = py + rayEntryDistance * vy;
					if (iy > -_halfExtentsY && iy < _halfExtentsY && ix > -_halfExtentsX && ix < _halfExtentsX) {
						targetNormal.x = 0;
						targetNormal.y = 0;
						targetNormal.z = 1;
						intersects = true;
					}
				}
			}
			if (!intersects && vz > 0) {
				rayEntryDistance = ( -_halfExtentsZ - pz ) / vz;
				if (rayEntryDistance > 0) {
					ix = px + rayEntryDistance * vx;
					iy = py + rayEntryDistance * vy;
					if (iy > -_halfExtentsY && iy < _halfExtentsY && ix > -_halfExtentsX && ix < _halfExtentsX) {
						targetNormal.x = 0;
						targetNormal.y = 0;
						targetNormal.z = -1;
						intersects = true;
					}
				}
			}
			
			return intersects ? rayEntryDistance : -1;
		}
		
		private static function containsPoint(position : Vector3D, cubePos : Vector3D) : Boolean
		{
			var px : Number = position.x - cubePos.x;
			var py : Number = position.y - cubePos.y;
			var pz : Number = position.z - cubePos.z;
			return px <= 2 && px >= -2 &&
				py <= 2 && py >= -2 &&
				pz <= 2 && pz >= -2;
		}
		
	}
}