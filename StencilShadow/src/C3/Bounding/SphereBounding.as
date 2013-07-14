package C3.Bounding
{
	import flash.geom.Vector3D;

	public class SphereBounding extends BoundingVolumeBase
	{
		public function SphereBounding(posX : int, posY : int, posZ : int)
		{
			center||=new Vector3D();
			center.setTo(posX,posY,posZ);
		}
		
		public function compute(vertex : Vector.<Number>) : void
		{
			var len : uint = vertex.length/3;
			var index : int = 0;
			var tempVertex : Vector3D = new Vector3D()
			for(var i : int = 0; i < len; i++)
			{
				index = i * 3;
				tempVertex.x = vertex[index++];
				tempVertex.y = vertex[index++];
				tempVertex.z = vertex[index];
				if(tempVertex.x > maxPos.x && tempVertex.y > maxPos.y && tempVertex.z > maxPos.z)
					maxPos.setTo(tempVertex.x,tempVertex.y,tempVertex.z);
			}
			
			radius = Vector3D.distance(center,maxPos);
		}
	}
}