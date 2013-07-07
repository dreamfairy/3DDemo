package C3.Mesh
{
	import C3.IDispose;
	import C3.Light.SimpleLight;
	import C3.Material.ColorMaterial;
	import C3.Material.IMaterial;
	
	import flash.events.EventDispatcher;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	public class MeshBase extends EventDispatcher implements IMesh, IDispose
	{
		public function MeshBase(mat : IMaterial)
		{
			this.material = mat ? mat : new ColorMaterial(0xFFFFFF,1);
		}
		
		public function set light(light:SimpleLight):void
		{
			m_light = light;
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
		
		public function get rotateX():Number
		{
			return m_rotate.x;
		}
		
		public function set rotateX(value:Number):void
		{
			m_rotate.x = value;
			
			m_transformDirty = true;
		}
		
		public function get rotateY():Number
		{
			return m_rotate.y;
		}
		
		public function set rotateY(value:Number):void
		{
			m_rotate.y = value;
			
			m_transformDirty = true;
		}
		
		public function get rotateZ():Number
		{
			return m_rotate.z;
		}
		
		public function set rotateZ(value:Number):void
		{
			m_rotate.z = value;
			
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
			m_transform.identity();
			m_transform.appendScale(m_scale.x,m_scale.y,m_scale.z);
			m_transform.appendRotation(m_rotate.x,Vector3D.X_AXIS);
			m_transform.appendRotation(m_rotate.y,Vector3D.Y_AXIS);
			m_transform.appendRotation(m_rotate.z,Vector3D.Z_AXIS);
			m_transform.appendTranslation(m_pos.x,m_pos.y,m_pos.z);
			
			m_transformDirty = false;
		}
		
		public function get material() : IMaterial
		{
			return m_material;
		}
		
		public function dispose():void
		{
			m_transform = null;
			m_scale = null;
			m_rotate = null;
			m_pos = null;
		}
		
		protected var m_transform : Matrix3D = new Matrix3D();
		protected var m_scale : Vector3D = new Vector3D(1,1,1);
		protected var m_rotate : Vector3D = new Vector3D();
		protected var m_pos : Vector3D = new Vector3D();
		protected var m_material : IMaterial;
		protected var m_transformDirty : Boolean;
		protected var m_light : SimpleLight;
		
		public var userData : Object;
	}
}