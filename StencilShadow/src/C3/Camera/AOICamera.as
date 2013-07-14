package C3.Camera
{
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	public class AOICamera
	{
		public function AOICamera()
		{
		}
		
		public function set viewport(value : Rectangle) : void
		{
			m_viewPortRect = value;
			m_aspectRatio = m_viewPortRect.width/m_viewPortRect.height;
		}
		
		private function createViewPortMatrix() : void
		{
			var maxDepth : int = 1;
			var minDepth : int = 0;
			var rawData : Vector.<Number> = new Vector.<Number>();
			rawData.push(m_viewPortRect.width/2,0,0,0);
			rawData.push(0,-m_viewPortRect.height/2,0,0);
			rawData.push(0,0,maxDepth - minDepth,0);
			rawData.push(m_viewPortRect.width/2,m_viewPortRect.height/2,minDepth,1);
			
			m_viewPortMatrix = new Matrix3D();
			m_viewPortMatrix.rawData = rawData;
		}
		
		private function sceneToNDC(sceneX : Number, sceneY : Number) : Point
		{
			var ndcPos : Point = new Point();
			ndcPos.x = 2 * sceneX / m_viewPortRect.width - 1;
			ndcPos.y = -(2 * sceneY / m_viewPortRect.height - 1);
			
			return ndcPos;
		}
		
		private var m_viewPortMatrix : Matrix3D;
		private var m_viewPortRect : Rectangle;
		private var m_aspectRatio : Number;
	}
}