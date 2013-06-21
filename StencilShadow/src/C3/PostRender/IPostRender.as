package C3.PostRender
{
	import C3.IDispose;

	public interface IPostRender extends IDispose
	{
		function renderBefore(passCount : int) : void;
		function renderAfter(passCount : int) : void;
		function get needReRender() : Boolean;
		function get hasPassDoen() : Boolean;
	}
}