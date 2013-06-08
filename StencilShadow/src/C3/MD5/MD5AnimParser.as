package C3.MD5
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;

	public class MD5AnimParser extends EventDispatcher
	{
		public function MD5AnimParser()
		{
		}
		
		public function load(data : ByteArray) : void
		{
			_textData = data.readUTFBytes(data.bytesAvailable);
			handleData();
		}
		
		private function handleData() : void
		{
			var token : String;
			while(true){
				token = getNextToken();
				switch(token)
				{
					case NUM_ANIMATED_COMPONENTS_TOKEN:
						numAnimatedComponents = getNextInt();
						break;
					case COMMENT_TOKEN:
						ignoreLine();
						break;
					case VERSION_TOKEN:
						_versin = getNextInt();
						if(_versin != 10) throw new Error("版本错误，只支持10");
						break;
					case COMMAND_LINE_TOKEN:
						parseCMD();
						break;
					case NUM_FRAMES_TOKEN:
						numFrames = getNextInt();
						bounds = new Vector.<MD5BoundsData>();
						frameData = new Vector.<MD5FrameData>();
						break;
					case NUM_JOINTS_TOKEN:
						numJoints = getNextInt();
						hierarchy = new Vector.<MD5HierarchyData>(numJoints, true);
						baseFrameData = new Vector.<MD5BaseFrameData>(numJoints, true);
						break;
					case FRAME_RATE_TOKEN:
						frameRate = getNextInt();
						break;
					case HIERARCHY_TOKEN:
						parseHierachy();
						break;
					case BOUNDS_TOKEN:
						parseBounds();
						break;
					case BASE_FRAME_TOKEN:
						parseBaseFrame();
						break;
					case FRAME_TOKEN:
						parseFrame();
						break;
					default:
						if(!_reachedEOF)
							throw new Error("解析错误，错误的token");
						break;
				}
				if(_reachedEOF){
					this.dispatchEvent(new Event(Event.COMPLETE));
					return;
				}
			}
		}
		
		/**
		 * 解析帧信息
		 */
		private function parseFrame() : void
		{
			var ch : String;
			var data : MD5FrameData;
			var token : String;
			var frameIndex : int;
			
			frameIndex = getNextInt();
			token = getNextToken();
			
			if(token != "{") throw new Error("解析错误，错误的{");
			
			
			do{
				if(_reachedEOF) throw new Error("错误的文件尾");
				data = new MD5FrameData();
				data.components = new Vector.<Number>(numAnimatedComponents, true);
				
				for(var i : int = 0; i < numAnimatedComponents; ++i){
					data.components[i] = getNextNumber();
				}
				
				frameData[frameIndex] = data;
				
				ch = getNextChar();
				
				//跳过注释
				if (ch == "/") {
					putBack();
					ch = getNextToken();
					if (ch == COMMENT_TOKEN) ignoreLine();
					ch = getNextChar();
				}
				
				if (ch != "}") putBack();
			}while (ch != "}");
		}
		
		/**
		 * 解析基础帧信息
		 */
		private function parseBaseFrame() : void
		{
			var ch : String;
			var data : MD5BaseFrameData;
			var token : String = getNextToken();
			var i : int;
			
			if(token != "{") throw new Error("解析错误，错误的{");
			
			do{
				if(_reachedEOF) throw new Error("错误的文件尾");
				data = new MD5BaseFrameData();
				data.position = parseVector3D();
				data.orientation = parseQuaternion();
				
				baseFrameData[i++] = data;
				
				//跳过注释
				ch = getNextChar();
				
				if (ch == "/") {
					putBack();
					ch = getNextToken();
					if (ch == COMMENT_TOKEN) ignoreLine();
					ch = getNextChar();
				}
				
				if (ch != "}") putBack();
			}while(ch != "}");
		}
		
		/**
		 * 解析帧范围
		 */
		private function parseBounds() : void
		{
			var ch : String;
			var data : MD5BoundsData;
			var token : String = getNextToken();
			var i : int = 0;
			
			if(token != "{") throw new Error("解析错误，错误的{");
			
			do{
				if(_reachedEOF) throw new Error("错误的文件尾");
				data = new MD5BoundsData();
				data.min = parseVector3D();
				data.max = parseVector3D();
				bounds[i++] = data;
				
				//跳过注释
				ch = getNextChar();
				
				if (ch == "/") {
					putBack();
					ch = getNextToken();
					if (ch == COMMENT_TOKEN) ignoreLine();
					ch = getNextChar();
				}
				
				if (ch != "}") putBack();
			}while(ch != "}");
		}
		
		/**
		 * 解析层级
		 */
		private function parseHierachy() : void
		{
			var ch : String;
			var data : MD5HierarchyData;
			var token : String = getNextToken();
			var i : int = 0;
			
			if(token != "{") throw new Error("错误的{");
			
			do{
				if(_reachedEOF) throw new Error("到达文件尾");
				data = new MD5HierarchyData();
				data.name = parseLiteralString();
				data.parentIndex = getNextInt();
				data.flags = getNextInt();
				data.startIndex = getNextInt();
				hierarchy[i++] = data;
				
				//跳过之后的注释
				ch = getNextChar();
				if(ch == "/"){
					putBack();
					ch = getNextToken();
					if(ch == COMMENT_TOKEN) ignoreLine();
					ch = getNextChar();
				}
				
				if(ch != "}") putBack();
			}while (ch != "}");
		}
		
		/**
		 * 从数据流中解析下一个四元数
		 */
		private function parseQuaternion() : Quaternion
		{
			var quat : Quaternion = new Quaternion();
			var ch : String = getNextToken();
			
			if(ch != "(") throw new Error("解析错误，错误的(");
			quat.x = getNextNumber();
			quat.y = getNextNumber();
			quat.z = getNextNumber();
			
			//四元数需要一个单位长度
			var t : Number = 1 - quat.x * quat.x - quat.y * quat.y - quat.z * quat.z;
			quat.w = t < 0 ? 0 : - Math.sqrt(t);
			
			if (getNextToken() != ")") throw new Error("解析错误，错误的)");
			
			return quat;
		}
		
		/**
		 * 获取Vector3d
		 */
		private function parseVector3D() : Vector3D
		{
			var vec : Vector3D = new Vector3D();
			var ch : String = getNextToken();
			
			if(ch != "(") throw new Error("解析错误，错误的(");
			vec.x = getNextNumber();
			vec.y = getNextNumber();
			vec.z = getNextNumber();
			
			if(getNextToken() != ")") throw new Error("解析错误，错误的)");
			
			return vec;
		}
		
		/**
		 * 从数据流中解析下一个浮点型数值
		 */
		private function getNextNumber() : Number
		{
			var f : Number = parseFloat(getNextToken());
			if(isNaN(f)) throw new Error("float type");
			return f;
		}
		
		/**
		 * 解析指令行数据
		 */
		private function parseCMD() : void
		{
			//仅仅忽略指令行属性
			parseLiteralString();
		}
		
		/**
		 * 解析数据流中的逐字符串，一个逐字符是一个序列字符，被两个引号包围
		 */
		private function parseLiteralString() : String
		{
			skipWhiteSpace();
			
			var ch : String = getNextChar();
			var str : String = "";
			
			if(ch != "\"") throw new Error("引号解析错误");
			do{
				if(_reachedEOF) throw new Error("到达文件结尾");
				ch = getNextChar();
				if(ch != "\"") str += ch;
			}while(ch != "\"");
			
			return str;
		}
		
		/**
		 * 读出数据流中的下一个整型
		 */
		private function getNextInt() : int
		{
			var i : Number = parseInt(getNextToken());
			if(isNaN(i)) throw new Error("解析错误 int type");
			return i;
		}
		
		/**
		 * 跳过下一行
		 */
		private function ignoreLine() : void
		{
			var ch : String;
			while(!_reachedEOF && ch != "\n")
				ch = getNextChar();
		}
		
		private function getNextToken() : String
		{
			var ch : String;
			var token : String = "";
			
			while(!_reachedEOF){
				ch = getNextChar();
				if(ch == " " || ch == "\r" || ch == "\n" || ch == "\t"){
					//如果不为注释，跳过
					if(token != COMMENT_TOKEN)
						skipWhiteSpace();
					//如果不为空白, 返回
					if(token != "")
						return token;
				}else token += ch;
				
				if(token == COMMENT_TOKEN) return token;
			}
			
			return token;
		}
		
		/**
		 * 从数据流中读取下一个字符
		 */
		private function getNextChar() : String
		{
			var ch : String = _textData.charAt(_parseIndex++);
			
			//如果遇到换行符
			if(ch == "\n"){
				++_line;
				_charLineIndex = 0;
			}
				//如果遇到回车符
			else if(ch != "\r"){
				++_charLineIndex;
			}
			
			if(_parseIndex >= _textData.length)
				_reachedEOF = true;
			
			return ch;
		}
		
		/**
		 * 跳过数据流中的空白
		 */
		private function skipWhiteSpace() : void
		{
			var ch : String;
			do {
				ch = getNextChar();
			}while(ch == "\n" || ch == " " || ch == "\r" || ch == "\t");
			
			putBack();
		}
		
		/**
		 * 将最后读出的字符放回数据流
		 */
		private function putBack() : void
		{
			_parseIndex--;
			_charLineIndex--;
			_reachedEOF = _parseIndex >= _textData.length;
		}
		
		private var _textData : String;
		private var _line : int;
		private var _parseIndex : int;
		private var _charLineIndex : int;
		private var _versin : int;
		private var _reachedEOF : Boolean;
		
		public var frameRate : int;
		public var numFrames : int;
		public var numJoints : int;
		public var numAnimatedComponents : int;
		
		public var hierarchy : Vector.<MD5HierarchyData>;
		public var bounds : Vector.<MD5BoundsData>;
		public var frameData : Vector.<MD5FrameData>;
		public var baseFrameData : Vector.<MD5BaseFrameData>;
		
		private static const COMMENT_TOKEN : String = "//";
		private static const VERSION_TOKEN : String = "MD5Version";
		private static const COMMAND_LINE_TOKEN : String = "commandline";
		
		private static const NUM_FRAMES_TOKEN : String = "numFrames";
		private static const NUM_JOINTS_TOKEN : String = "numJoints";
		private static const FRAME_RATE_TOKEN : String = "frameRate";
		private static const NUM_ANIMATED_COMPONENTS_TOKEN : String = "numAnimatedComponents";
		
		private static const HIERARCHY_TOKEN : String = "hierarchy";
		private static const BOUNDS_TOKEN : String = "bounds";
		private static const BASE_FRAME_TOKEN : String = "baseframe";
		private static const FRAME_TOKEN : String = "frame";
	}
}