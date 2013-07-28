package C3.Core.Managers
{
	import C3.IDispose;
	import C3.Material.Shaders.Shader;
	import C3.Material.Shaders.ShaderDepthMap;
	import C3.Material.Shaders.ShaderShadowMap;
	import C3.Pool.ContextCache;
	
	import flash.display3D.Context3D;
	import flash.utils.Dictionary;

	public class MaterialManager
	{
		public function MaterialManager()
		{
		}
		
		public static function getShader(type : uint, context : Context3D) : Shader
		{
			var cache : ContextCache = hasCache(context);
			
			if(null == cache) {
				cache = new ContextCache(context);
				m_shaderCache[cache.key] = cache;
			}

			if(!cache.shaderCache.hasOwnProperty(type))
				cache.shaderCache[type] = createShader(type, context);
			
			return cache.shaderCache[type];
		}
		
		private static function hasCache(context : Context3D) : ContextCache
		{
			var cache : ContextCache;
			for each(cache in m_shaderCache){
				if(cache.context == context) return cache;
			}
			
			return null;
		}
		
		public static function addBeforeRenderShader(shader : Shader) : void
		{
			beforeRenderShaderList.push(shader);
			beforeRenderShaderList.sort(shaderSortFun);
		}
		
		public static function shaderSortFun(shader1 : Shader, shader2 : Shader) : int
		{
			return shader1.type > shader2.type ? 1 : -1;
		}
		
		public static function free() : void
		{
			beforeRenderShaderList.length = 0;
		}
		
		private static function createShader(type : uint, context : Context3D) : Shader
		{
			switch(type){
				case Shader.SHADOW_MAP:
					return new ShaderShadowMap();
					break;
				case Shader.DEPTH_MAP:
					return new ShaderDepthMap(context);
					break;
			}
			
			return null;
		}
		
		public static var beforeRenderShaderList : Vector.<Shader> = new Vector.<Shader>();
		
		private static var m_shaderCache : Dictionary = new Dictionary();
	}
}