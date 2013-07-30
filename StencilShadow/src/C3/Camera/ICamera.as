package C3.Camera
{
	import flash.geom.Matrix3D;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;

	public interface ICamera
	{
		function get projectMatrix() : Matrix3D;
		function get viewProjMatrix() : Matrix3D;
		function get viewMatrix() : Matrix3D;
		function setGlobalLightPos(vx : Number, vy : Number, vz : Number) : void;
		function setGlobalLightTarget(vx : Number, vy : Number, vz : Number) : void;
		function moveForward(units : Number) : void;
		function moveBackward(units : Number) : void
		function yaw(numDegrees : Number) : void;
		function pitch(numDegrees : Number) : void;
		function moveUp(units : Number) : void;
		function moveDown(units : Number) : void;
		function get viewport() : Rectangle;
		function set viewport(vp : Rectangle) : void;
		function get lightProjection() : Matrix3D;
		function setPositionValues(x : Number, y : Number, z : Number) : void;
		function setTargetValues(x : Number, y : Number, z : Number) : void;
		function get position() : Vector3D;
	}
}