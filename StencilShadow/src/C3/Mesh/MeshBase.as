package C3.Mesh
{
	import flash.events.EventDispatcher;
	import flash.geom.Matrix3D;
	import flash.geom.Orientation3D;
	import flash.geom.Vector3D;
	
	import C3.IDispose;
	import C3.Object3DContainer;
	import C3.Quaternion;
	import C3.Light.SimpleLight;
	import C3.Material.ColorMaterial;
	import C3.Material.IMaterial;

	public class MeshBase extends EventDispatcher implements IMesh, IDispose
	{
		public function MeshBase(mat : IMaterial)
		{
			if(null == mat) mat = new ColorMaterial(0xFFFFFF,1);
			this.material = mat;
			
			m_decomposedMatrix.push(m_pos,m_rotate,m_scale);
		}
		
		public function get position():Vector3D
		{
			return m_pos;
		}
		
		public function set position(pos:Vector3D):void
		{
			m_pos.setTo(pos.x,pos.y,pos.z);
			
			m_transformDirty = true;
		}
		
		public function set x(value:Number):void
		{
			m_pos.x = value;
			
			m_transformDirty = true;
		}
		
		public function get x():Number
		{
			return m_pos.x;
		}
		
		public function set y(value:Number):void
		{
			m_pos.y = value;
			
			m_transformDirty = true;
		}
		
		public function get y():Number
		{
			return m_pos.y;
		}
		
		public function set z(value:Number):void
		{
			m_pos.z = value;
			
			m_transformDirty = true;
		}
		
		public function get z():Number
		{
			return m_pos.z;
		}
		
		public function setRotate(x:Number, y:Number, z:Number):void
		{
			m_rotate.setTo(x,y,z);
			
			m_transformDirty = true;
		}
		
		public function getRotate() : Vector3D
		{
			return m_rotate;
		}
		
		public function get rotateX():Number
		{
			return m_rotate.x;
		}
		
		public function set rotateX(value:Number):void
		{
			m_rotate.x = value % 360;
			
			m_transformDirty = true;
		}
		
		public function get rotateY():Number
		{
			return m_rotate.y;
		}
		
		public function set rotateY(value:Number):void
		{
			m_rotate.y = value % 360;
			
			m_transformDirty = true;
		}
		
		public function get rotateZ():Number
		{
			return m_rotate.z;
		}
		
		public function set rotateZ(value:Number):void
		{
			m_rotate.z = value % 360;
			
			m_transformDirty = true;
		}
		
		public function get scaleX():Number
		{
			return m_scale.x;
		}
		
		public function set scaleX(value:Number):void
		{
			m_scale.x = value<=0?.1:value;
			
			m_transformDirty = true;
		}
		
		public function get scaleY():Number
		{
			return m_scale.y;
		}
		
		public function set scaleY(value:Number):void
		{
			m_scale.y = value<=0?.1:value;
			
			m_transformDirty = true;
		}
		
		public function get scaleZ():Number
		{
			return m_scale.z;
		}
		
		public function set scaleZ(value:Number):void
		{
			m_scale.z = value<=0?.1:value;
			
			m_transformDirty = true;
		}
		
		public function setScale(x:Number, y:Number, z:Number):void
		{
			m_scale.setTo(x<=0?.1:x,y<=0?.1:y,z<=0?.1:z);
			
			m_transformDirty = true;
		}
		
		public function set material(mat : IMaterial) : void
		{
			m_material = mat;
		}
		
		public function get transform():Matrix3D
		{
			return m_transform;
		}
		
		public function updateTransform():void
		{
			m_decomposedMatrix[0].x = m_pos.x;
			m_decomposedMatrix[0].y = m_pos.y;
			m_decomposedMatrix[0].z = m_pos.z;
			
			m_tempRotation.copyFrom(m_rotate);
			m_tempRotation.scaleBy(Quaternion.DEG_TO_RAD);
			
			m_decomposedMatrix[1] = m_tempRotation;
			
			m_decomposedMatrix[2] = m_scale;
			
			m_transform.recompose(m_decomposedMatrix,Orientation3D.EULER_ANGLES);
			
			m_transformDirty = false;
		}
		
		public function dispose():void
		{
			m_transform = null;
			m_scale = null;
			m_rotate = null;
			m_pos = null;
			m_decomposedMatrix = null;
		}
		
		protected var m_transform : Matrix3D = new Matrix3D();
		protected var m_scale : Vector3D = new Vector3D(1,1,1);
		protected var m_rotate : Vector3D = new Vector3D();
		protected var m_pos : Vector3D = new Vector3D();
		protected var m_decomposedMatrix : Vector.<Vector3D> = new Vector.<Vector3D>();
		protected var m_tempRotation : Vector3D = new Vector3D();
		protected var m_material : IMaterial;
		protected var m_transformDirty : Boolean = true;
		
		public var userData : Object;
	}
}