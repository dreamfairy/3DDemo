package C3.Mesh
{
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	import C3.Light.SimpleLight;
	import C3.Material.IMaterial;

	public interface IMesh
	{
		function get position() : Vector3D;
		function set position(pos : Vector3D) : void;
		function set x(value : Number) : void;
		function get x() : Number;
		function set y(value : Number) : void;
		function get y() : Number;
		function set z(value : Number) : void;
		function get z() : Number;
		
		function get scaleX() : Number;
		function set scaleX(value : Number) : void;
		function get scaleY() : Number;
		function set scaleY(value : Number) : void;
		function get scaleZ() : Number;
		function set scaleZ(value : Number) : void;
		function setScale(x : Number, y : Number, z : Number) : void;
		
		function get rotateX() : Number;
		function set rotateX(value : Number) : void;
		function get rotateY() : Number;
		function set rotateY(value : Number) : void;
		function get rotateZ() : Number;
		function set rotateZ(value : Number) : void;
		function setRotate(x : Number, y : Number, z : Number) : void;
		
		function set material(mat : IMaterial) : void;
		function set light(light : SimpleLight) : void;
		
		function get transform() : Matrix3D;
		
		function updateTransform() : void;
	}
}