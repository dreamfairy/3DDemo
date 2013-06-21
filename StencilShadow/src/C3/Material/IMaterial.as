package C3.Material
{
	import flash.display3D.textures.Texture;
	
	import C3.IDispose;
	import C3.PostRender.IPostRender;

	public interface IMaterial extends IDispose
	{
		function getMatrialData() : Vector.<Number>;
		function getFragmentStr(item : IPostRender) : String;
		function updateFragmentStr() : void;
		function getTexture() : Texture;
	}
}