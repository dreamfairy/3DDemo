package C3.Parser
{
	import flash.sampler.getSize;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	public class DDSParser
	{
		private static const DXT_1:int = 1;
		private static const DXT_2:int = 2;
		private static const DXT_3:int = 3;
		private static const DXT_4:int = 4;
		private static const DXT_5:int = 5;
		private static const DXT_UNKNOWN:int = 6;
		
		// 解码后的颜色结果，定义成静态的而不是每次分配节省时间
		private var mColorBuf:Vector.<Vector.<int>>;
		// 解码过程中使用的透明通道值
		private var mAlphaBuf:Vector.<Vector.<int>>;
		// 编码过程中使用的缓冲
		private var mEncodeBuf:Vector.<int>;
		
		private var ddsFileHeader:DDSFileHeader;
		private var ddsMemBlk:DDSMemBlk;
		
		public function DDSParser(ddsfile:Class)
		{
			// 获取数据
			var bytes:ByteArray = readClass(ddsfile);
			bytes.endian = Endian.LITTLE_ENDIAN;
			ddsMemBlk = decode(bytes);
		}
		
		// 获取解析数据
		public function get data() : ByteArray
		{
			if (ddsMemBlk == null)
				ddsMemBlk = new DDSMemBlk();
			return ddsMemBlk.data;
		}
		
		public function get width() : int
		{
			if (ddsMemBlk == null)
				ddsMemBlk = new DDSMemBlk();
			return ddsMemBlk.width;
		}
		
		public function get height() : int
		{
			if (ddsMemBlk == null)
				ddsMemBlk = new DDSMemBlk();
			return ddsMemBlk.height;
		}
		
		public function get mipMapCount() : int
		{
			if (ddsMemBlk == null)
				ddsMemBlk = new DDSMemBlk();
			return ddsMemBlk.mipcnt;
		}
		
		// 获取文件信息
		public function get format() : uint
		{
			if (ddsFileHeader != null)
				return getDXTFormat(ddsFileHeader.ddpfPixelFormat.fourCC);
			return DXT_UNKNOWN;
		}
		
		private function readClass(f:Class) : ByteArray
		{
			var bytes:ByteArray = new f();
			return bytes;
		}
		
		// 返回本模块是否能处理指定的格式信息
		private function canHandleThisFormat(header:DDSFileHeader) : Boolean
		{
			// 这些标记是必有的，否则认为图片格式不正确
			if (! (header.flags & DDSFileHeader.DDSD_CAPS) ||
				! (header.flags & DDSFileHeader.DDSD_HEIGHT) ||
				! (header.flags & DDSFileHeader.DDSD_WIDTH) ||
				! (header.flags & DDSFileHeader.DDSD_PIXELFORMAT) ||
				! (header.flags & DDSFileHeader.DDSD_LINEARSIZE))
				return false;
			
			// 只处理 DXT? 格式的，不处理其他非压缩格式
			if (! (header.ddpfPixelFormat.flags & DDSPixelFormat.DDPF_FOURCC))
				return false;
			
			// 只处理 DXT1, DXT3, DXT5
			var fmt:int = getDXTFormat(header.ddpfPixelFormat.fourCC);
			if (fmt != DXT_1 && fmt != DXT_3 && fmt != DXT_5)
				return false;
			
			// 只处理Texture类型的，Cube map 和 Volume texture不支持
			if (header.ddsCaps.caps2 & DDSCaps2.DDSCAPS2_CUBEMAP ||
				header.ddsCaps.caps2 & DDSCaps2.DDSCAPS2_VOLUME)
				return false;
			
			// 可以处理的格式
			return true;
		}
		
		// 解码指定的内存段
		private function decode(data:ByteArray) : DDSMemBlk
		{
			var rptr:DDSMemBlk = new DDSMemBlk();
			ddsFileHeader = new DDSFileHeader();
			
			// 如果该段内存比文件头还小，那么肯定有问题，直接返回
			if (data.length < getSize(ddsFileHeader))
				return rptr;
			
			// 复制文件头信息
			ddsFileHeader.magic = data.readInt();
			ddsFileHeader.size = data.readInt();
			ddsFileHeader.flags = data.readInt();
			ddsFileHeader.height = data.readInt();
			ddsFileHeader.width = data.readInt();
			ddsFileHeader.pitchOrLinearSize = data.readInt();
			ddsFileHeader.depth = data.readInt();
			ddsFileHeader.mipMapCount = data.readInt();
			ddsFileHeader.ddpfPixelFormat = new DDSPixelFormat();
			data.position += ddsFileHeader.reserved1;
			ddsFileHeader.ddpfPixelFormat.size = data.readInt();
			ddsFileHeader.ddpfPixelFormat.flags = data.readInt();
			ddsFileHeader.ddpfPixelFormat.fourCC = data.readInt();
			ddsFileHeader.ddpfPixelFormat.rgbBitCount = data.readInt();
			ddsFileHeader.ddpfPixelFormat.rBitMask = data.readInt();
			ddsFileHeader.ddpfPixelFormat.gBitMask = data.readInt();
			ddsFileHeader.ddpfPixelFormat.bBitMask = data.readInt();
			ddsFileHeader.ddpfPixelFormat.rgbaBitMask = data.readInt();
			ddsFileHeader.ddsCaps = new DDSCaps2();
			data.position += ddsFileHeader.ddsCaps.reserved;
			ddsFileHeader.ddsCaps.caps1 = data.readInt();
			ddsFileHeader.ddsCaps.caps2 = data.readInt();
			data.position += ddsFileHeader.reserved2;
			
			// 检查magic是否符合('DDS ')，不符合直接返回
			if (0x20534444 != ddsFileHeader.magic)
				return rptr;
			
			// 检查是否能处理这样的格式
			if (! canHandleThisFormat(ddsFileHeader))
				return rptr;
			
			// 取回DXT格式
			var dxtFmt:int = getDXTFormat(ddsFileHeader.ddpfPixelFormat.fourCC);
			
			// 取回需要解压的层数(没有mipmap当做有1层)
			var mipCount:int = 1;
			if (ddsFileHeader.flags & DDSFileHeader.DDSD_MIPMAPCOUNT)
				mipCount = ddsFileHeader.mipMapCount;
			
			// 取回宽高信息
			var width:int = ddsFileHeader.width, height:int = ddsFileHeader.height;
			
			rptr.size = 0;
			for (var i:int = 0; i < mipCount; i++)
			{
				// 累计所有层需要的缓冲大小
				rptr.size += width * height * getSize(1);
				
				// 计算出下一层mipmap的宽高
				width  = Math.max(1, width >> 1);
				height = Math.max(1, height >> 1);
			}
			
			// 分配内存，填写其他信息
			rptr.data.length = rptr.size;
			rptr.width  = ddsFileHeader.width;
			rptr.height = ddsFileHeader.height;
			rptr.mipcnt = mipCount;
			
			var dataposition:uint = data.position;
			var pdst:ByteArray = rptr.data;
			var bufposition:uint = pdst.position;
			var totalMemSize:Number = 0;
			
			// 循环处理每一层
			width = ddsFileHeader.width; height = ddsFileHeader.height;
			for (i = 0; i < mipCount; i++)
			{
				// 计算出本层mipmap数据的字节大小
				var memSize:int = Math.max(1, BLOCKNUM(width)) * Math.max(1, BLOCKNUM(height)) * BLOCKSIZE(dxtFmt);
				totalMemSize += memSize;
				
				// 解码本层的数据
				decodeOneLayer(width, height, data, memSize, dxtFmt, pdst);
				
				// 指针指向下一层的数据
				data.position = dataposition + totalMemSize;
				pdst.position = bufposition + (width * height * getSize(1)) * (i + 1);
				
				// 计算出下一层mipmap的宽高
				width  = Math.max(1, width >> 1);
				height = Math.max(1, height >> 1);
			}
			// pdst.position = bufposition;
			return rptr;
		}
		
		// 解码一层mipmap
		private function decodeOneLayer(w:int, h:int, data:ByteArray, size:int, fmt:int, buf:ByteArray) : Boolean
		{
			// 压缩块的宽高信息
			var blkw:int = Math.max(1, BLOCKNUM(w)), blkh:int = Math.max(1, BLOCKNUM(h));
			var blksize:int = BLOCKSIZE(fmt);
			var dataposition:uint = data.position;
			var bufposition:uint = buf.position;
			
			// 遍历压缩块
			for (var i:int = 0; i < blkh; i++)
			{
				for (var j:int = 0; j < blkw; j++)
				{
					data.position = dataposition + ((i * blkw) + j) * blksize;
					
					// 将解码出来的颜色信息保存到缓冲中
					decodeOneBlock(data, blksize, fmt);
					
					// 保存本块解码结果
					var _xoff:int = j << 2, _yoff:int = i << 2;
					for (var k:int = 0; k < 4; k++)
					{
						for (var m:int = 0; m < 4; m++)
						{
							// 计算像素点的位置，如果超过了图片大小则跳过
							var _x:int = _xoff + m, _y:int = _yoff + k;
							if (_x >= w || _y >= h)
								continue;
							
							// 将本压缩块的解压结果保存到缓存中
							buf.position = bufposition + w * _y + _x;
							buf.writeByte(mColorBuf[k][m]);
						}
					}
				}
			}
			
			// 解码成功
			return true;
		}
		
		// 解码一个压缩块
		private function decodeOneBlock(pblk:ByteArray, size:int, fmt:int) : Boolean
		{
			// 初始化颜色和透明度缓冲
			mColorBuf = new Vector.<Vector.<int>>(4);
			for (var i:int = 0; i < mColorBuf.length; i++)
				mColorBuf[i] = new Vector.<int>([0, 0, 0, 0]);
			mAlphaBuf = new Vector.<Vector.<int>>(4);
			for (i = 0; i < mAlphaBuf.length; i++)
				mAlphaBuf[i] = new Vector.<int>([0xFF, 0xFF, 0xFF, 0xFF]);
			
			// 如果fmt指明是 DXT2-DXT5，需要先解码出alpha的信息
			if (fmt == DXT_2 || fmt == DXT_3)
				decodeAlphaDXT3(pblk);
			else if (fmt == DXT_4 || fmt == DXT_5)
				decodeAlphaDXT5(pblk);
			
			// 调色板中的四种颜色
			var colors:Vector.<int> = new Vector.<int>(4);
			var  f3colorMode:Boolean = false;
			
			// 取两个调色的原始颜色
			var _color0:int = pblk.readShort();
			var _color1:int = pblk.readShort();
			
			// 计算出插值颜色
			if ((_color0 >= _color1) || fmt != DXT_1)
			{
				// _color0和_color1的格式为RGB 5:6:5。四色模式
				colors[0] = rgb565_to_argb8888(_color0);
				colors[1] = rgb565_to_argb8888(_color1);
				colors[2] = color_add(color_scale(colors[0], 2.0/3), color_scale(colors[1], 1.0/3));
				colors[3] = color_add(color_scale(colors[0], 1.0/3), color_scale(colors[1], 2.0/3));
			}
			else
			{
				// _color0和_color1的格式为RGBA 5:5:5:1。三色模式
				colors[0] = rgb555_to_argb8888(_color0);
				colors[1] = rgb555_to_argb8888(_color1);
				colors[2] = color_add(color_scale(colors[0], 1.0/2), color_scale(colors[1], 1.0/2));
				colors[3] = 0x00000000; // 透明
				f3colorMode = true;
			}
			
			var position:uint = pblk.position;
			// 解码 (4 * 4) = 16 个像素
			for (i = 0; i < 16; i++)
			{
				var row:int = i >> 2, col:int = i % 4;
				
				// 根据块信息求出像素点的索引
				var off:int = col << 1;
				pblk.position = position + row;
				var idx:int = (pblk.readByte() & (0x03 << off)) >> off;
				
				// 如果为三色模式，并且索引值为0b11，那么说明透明信息
				if (f3colorMode && idx == 3)
					mAlphaBuf[row][col] = 0x00;
					// 其他情况，将调色板中的颜色保存下来
				else
					mColorBuf[row][col] = colors[idx];
			}
			
			// 将颜色和通道两种信息合并到一起
			for (i = 0; i < 4; i++)
				for (var j:int = 0; j < 4; j++)
					mColorBuf[i][j] = (mColorBuf[i][j] & 0x00FFFFFF) | (mAlphaBuf[i][j] << 24);
			
			// 解码本块成功
			return true;
		}
		
		// DXT3格式解alpha通道
		private function decodeAlphaDXT3(pblk:ByteArray) : void
		{
			var position:uint = pblk.position;
			// 解码 (4 * 4) = 16 个像素的透明度
			for (var i:int = 0; i < 16; i++)
			{
				var row:int = i >> 2, col:int = i % 4;
				pblk.position = position + 2 * row;
				var d:int = pblk.readShort();
				
				// 根据块信息求出像素点的索引
				var off:int = col << 2;
				var alpha:int = (d & (0x0F << off)) >> off;
				
				// 记录下透明度信息
				mAlphaBuf[row][col] = alpha * 256 / 16;
			}
			
			// 跳过8个字节的透明度块
			pblk.position = position + 8;
		}
		
		// DXT5格式解alpha通道
		private function decodeAlphaDXT5(pblk:ByteArray) : void
		{
			// alpha值查找表
			var alphas:Vector.<int> = new Vector.<int>(8);
			var dd:int;
			
			// 取到alpha_0和alpha_1
			alphas[0] = pblk.readByte();
			alphas[1] = pblk.readByte();
			
			if (alphas[0] > alphas[1])
			{
				// 8-alpha mode
				// Bit code 000 = alpha_0, 001 = alpha_1, others are interpolated.
				alphas[2] = (6 * alphas[0] + 1 * alphas[1] + 3) / 7;    // bit code 010
				alphas[3] = (5 * alphas[0] + 2 * alphas[1] + 3) / 7;    // bit code 011
				alphas[4] = (4 * alphas[0] + 3 * alphas[1] + 3) / 7;    // bit code 100
				alphas[5] = (3 * alphas[0] + 4 * alphas[1] + 3) / 7;    // bit code 101
				alphas[6] = (2 * alphas[0] + 5 * alphas[1] + 3) / 7;    // bit code 110
				alphas[7] = (1 * alphas[0] + 6 * alphas[1] + 3) / 7;    // bit code 111
			}
			else
			{
				// 6-alpha mode
				// Bit code 000 = alpha_0, 001 = alpha_1, others are interpolated.
				alphas[2] = (4 * alphas[0] + 1 * alphas[1] + 2) / 5;    // bit code 010
				alphas[3] = (3 * alphas[0] + 2 * alphas[1] + 2) / 5;    // bit code 011
				alphas[4] = (2 * alphas[0] + 3 * alphas[1] + 2) / 5;    // bit code 100
				alphas[5] = (1 * alphas[0] + 4 * alphas[1] + 2) / 5;    // bit code 101
				alphas[6] = 0;                                          // bit code 110
				alphas[7] = 255;                                        // bit code 111
			}
			
			// 解码4*4的alpha信息块
			var position:uint = pblk.position;
			for (var i:int = 0; i < 16; i++)
			{
				var row:int = i >> 2, col:int = i % 4;
				pblk.position = position + (row>>1)*3;
				dd = pblk.readInt();
				var off:int = (i % 8) * 3;
				var idx:int = (dd & (0x07 << off)) >> off;
				mAlphaBuf[row][col] = alphas[idx];
			}
			
			// 跳过alpha块，除去之前已经跳过的2个字节
			pblk.position = position + (8 - 2);
		}
		
		// 返回DXT的类型，未知返回DXT_UNKNOWN
		private static function getDXTFormat(fourcc:int) : int
		{
			// 必须是 'DXT?' 样式的
			if ((fourcc & 0x00FFFFFF) != 0x00545844)
				return DXT_UNKNOWN;
			
			// 取看是第几种
			var type:int = (fourcc >> 24) - '0'.charCodeAt();
			if (type >= 1 && type <= 5)
				return type;
			
			// 不是有效的类型范围
			return DXT_UNKNOWN;
		}
		
		// 用比例因子缩放ARGB 8:8:8:8
		private static function color_scale(color:int, s:Number) : int
		{
			var a:int, r:int, g:int, b:int;
			a = ((color & 0xFF000000) >> 24) * s;
			r = ((color & 0x00FF0000) >> 16) * s;
			g = ((color & 0x0000FF00) >> 8) * s;
			b = ((color & 0x000000FF)) * s;
			
			return ((a << 24) | (r << 16) | (g << 8) | b);
		}
		
		// 颜色相加。(alpha不参与运算，直接为0xFF)
		private static function color_add(c1:int, c2:int) : int
		{
			var a1:int, r1:int, g1:int, b1:int;
			var a2:int, r2:int, g2:int, b2:int;
			var a:int, r:int, g:int, b:int;
			
			a1 = (c1 & 0xFF000000) >> 24;
			r1 = (c1 & 0x00FF0000) >> 16;
			g1 = (c1 & 0x0000FF00) >>  8;
			b1 = (c1 & 0x000000FF);
			
			a2 = (c2 & 0xFF000000) >> 24;
			r2 = (c2 & 0x00FF0000) >> 16;
			g2 = (c2 & 0x0000FF00) >>  8;
			b2 = (c2 & 0x000000FF);
			
			a = Math.min(a1 + a2, 0xFF);
			r = Math.min(r1 + r2, 0xFF);
			g = Math.min(g1 + g2, 0xFF);
			b = Math.min(b1 + b2, 0xFF);
			
			return ((a << 24) | (r << 16) | (g << 8) | b);
		}
		
		// 求两种颜色的“距离”。(排除alpha值)
		private static function color_distance(c1:int, c2:int) : int
		{
			var r1:int, g1:int, b1:int, r2:int, g2:int, b2:int;
			
			// 分解出color1的通道
			r1 = (c1 & 0x00FF0000) >> 16;
			g1 = (c1 & 0x0000FF00) >> 8;
			b1 = (c1 & 0x000000FF);
			
			// 分解出color2的通道
			r2 = (c2 & 0x00FF0000) >> 16;
			g2 = (c2 & 0x0000FF00) >> 8;
			b2 = (c2 & 0x000000FF);
			
			return Math.abs(r1-r2) + Math.abs(g1-g2) + Math.abs(b1-b2);
		}
		
		// RGB 5:6:5 --> ARGB 8:8:8:8
		private static function rgb565_to_argb8888(color:int) : int
		{
			var a:int, r:int, g:int, b:int;
			
			r = ((color & 0xF800) >> 11) << 3; // * (256/32);
			g = ((color & 0x07E0) >> 5) << 2;  // * (256/64);
			b = (color & 0x001F) << 3;         // * (256/32);
			a = 0xFF;
			
			return ((a << 24) | (r << 16) | (g << 8) | b);
		}
		
		// RGB 5:5:6 --> ARGB 8:8:8:8
		private static function rgb555_to_argb8888(color:int) : int
		{
			var a:int, r:int, g:int, b:int;
			
			r = ((color & 0xF800) >> 11) << 3; //* (256/32);
			g = ((color & 0x07C0) >> 6) << 3;  //* (256/32);
			b = ((color & 0x003F)) << 3;       //* (256/32);
			a = 0xFF;
			
			return ((a << 24) | (r << 16) | (g << 8) | b);
		}
		
		// ARGB 8:8:8:8 --> RGB 5:6:5
		private static function argb8888_to_rgb565(color:int) : int
		{
			var r:int, g:int, b:int;
			
			r = ((color & 0x00FF0000) >> 16) >> 3;
			g = ((color & 0x0000FF00) >> 8) >> 2;
			b = (color & 0x000000FF) >> 3;
			
			return ((r << 11) | (g << 5) | b);
		}
		
		private static function BLOCKSIZE(fmt:int) : int
		{
			return fmt == DXT_1 ? 8 : 16;
		}
		
		private static function BLOCKNUM(wh:int) : int
		{
			return ((wh) + 4 - 1) >> 2;
		}
	}
}

import flash.sampler.getSize;
import flash.utils.ByteArray;
import flash.utils.Endian;

class DDSPixelFormat
{
	public var size:int;
	public var flags:int;
	public var fourCC:int;
	public var rgbBitCount:int;
	public var rBitMask:int;
	public var gBitMask:int;
	public var bBitMask:int;
	public var rgbaBitMask:int;
	
	// DDSPixelFormat 的 Flags 字段可用标记如下
	public static var DDPF_ALPHAPIXELS:Number           = 0x00000001
	public static var DDPF_FOURCC:Number                = 0x00000004
	public static var DDPF_RGB:Number                   = 0x00000040
}

class DDSCaps2
{
	public var caps1:int;
	public var caps2:int;
	public var reserved:uint = getSize(1) * 2;           // 保留字段的长度
	
	// DDSCaps2 的 Caps1 字段可用标记如下
	public static var DDSCAPS_COMPLEX:Number            = 0x00000008
	public static var DDSCAPS_TEXTURE:Number            = 0x00001000
	public static var DDSCAPS_MIPMAP:Number             = 0x00400000
	
	// DDSCaps2 的 Caps2 字段可用标记如下
	public static var DDSCAPS2_CUBEMAP:Number           = 0x00000200
	public static var DDSCAPS2_CUBEMAP_POSITIVEX:Number = 0x00000400
	public static var DDSCAPS2_CUBEMAP_NEGATIVEX:Number = 0x00000800
	public static var DDSCAPS2_CUBEMAP_POSITIVEY:Number = 0x00001000
	public static var DDSCAPS2_CUBEMAP_NEGATIVEY:Number = 0x00002000
	public static var DDSCAPS2_CUBEMAP_POSITIVEZ:Number = 0x00004000
	public static var DDSCAPS2_CUBEMAP_NEGATIVEZ:Number = 0x00008000
	public static var DDSCAPS2_VOLUME:Number            = 0x00200000
}

// 文件头
class DDSFileHeader
{
	public var magic:int;
	public var size:int;
	public var flags:int;
	public var height:int;
	public var width:int;
	public var pitchOrLinearSize:int;
	public var depth:int;
	public var mipMapCount:int;
	public var reserved1:uint = getSize(1) * 11;         // 保留字段的长度
	public var ddpfPixelFormat:DDSPixelFormat;
	public var ddsCaps:DDSCaps2;
	public var reserved2:uint = getSize(1);              // 保留字段，目前为空
	
	// DDSFileHeader 的 Flags 字段可用标记如下
	public static var DDSD_CAPS:Number                  = 0x00000001
	public static var DDSD_HEIGHT:Number                = 0x00000002
	public static var DDSD_WIDTH:Number                 = 0x00000004
	public static var DDSD_PITCH:Number                 = 0x00000008
	public static var DDSD_PIXELFORMAT:Number           = 0x00001000
	public static var DDSD_MIPMAPCOUNT:Number           = 0x00020000
	public static var DDSD_LINEARSIZE:Number            = 0x00080000
	public static var DDSD_DEPTH:Number                 = 0x00800000
}

// 编码/解码后的结果
class DDSMemBlk
{
	public var data:ByteArray;
	public var size:int;
	public var width:int, height:int, mipcnt:int;
	
	public function DDSMemBlk()
	{
		data = new ByteArray();
		data.endian = Endian.LITTLE_ENDIAN;
		size = 0;
	}
}