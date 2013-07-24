package C3.MD5
{
	import flash.geom.Matrix3D;
	
	import C3.Parser.Model.IJoint;

	/**
	 * 关节
	 */
	public class MD5Joint implements IJoint
	{
		//初始及动画位置矩阵
		public var bindPose : Matrix3D;
		
		//平移和旋转矩阵的转制矩阵
		public var inverseBindPose : Matrix3D;
		
		public var name : String = "";
		
		public var parentIndex : int = 0;
	}
}