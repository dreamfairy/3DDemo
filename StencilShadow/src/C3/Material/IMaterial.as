package C3.Material
{
	import flash.display3D.textures.Texture;
	
	import C3.IDispose;

	public interface IMaterial extends IDispose
	{
		function getMatrialData() : Vector.<Number>;
		function getFragmentStr() : String;
		function updateFragmentStr() : void;
		function getTexture() : Texture;
	}
}