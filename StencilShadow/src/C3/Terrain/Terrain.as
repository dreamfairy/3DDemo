package C3.Terrain
{
	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.Texture;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	public class Terrain
	{
		private var m_context3D : Context3D;
		private var m_transform : Matrix3D = new Matrix3D();
		private var m_matrix : Matrix3D = new Matrix3D();
		private var m_needUpdateTransform : Boolean = false;
		private var m_pos : Vector3D = new Vector3D();
		private var m_rotate : Vector3D = new Vector3D();
		private var m_scale : Vector3D = new Vector3D(1,1,1);
		
		private var m_rawVertex : Vector.<Number> = new Vector.<Number>();
		private var m_rawUv : Vector.<Number> = new Vector.<Number>();
		private var m_rawIndex : Vector.<uint> = new Vector.<uint>();
		
		private var m_heightMap : Vector.<int> = new Vector.<int>();
		private var m_vertexBuffer : VertexBuffer3D;
		private var m_uvBuffer : VertexBuffer3D;
		private var m_colorBuffer : VertexBuffer3D;
		private var m_indexBuffer : IndexBuffer3D;
		
		/**列顶点数*/
		private var m_numVertsPerRow : uint;
		/**行顶点数*/
		private var m_numVertsPerCol : uint;
		/**顶点间隔*/
		private var m_cellSpacing : int = 1;
		
		/**列单元格数*/
		private var m_numCellsPerRow : int;
		/**行单元格数*/
		private var m_numCellsperCol : int;
		
		private var m_width : int;
		private var m_depth : int;
		private var m_numVertices : int;
		private var m_numTriangles : int;
		
		private var m_texture : Texture;
		
		/**缩放系数*/
		private var m_heightScale : Number;
		
		public function Terrain(context3D : Context3D, numVertesPerRow : int, numVertsPerCol : int, cellSpacing : int, heightScale : Number, data : ByteArray)
		{
			m_context3D			= context3D;
			m_numVertsPerRow	= numVertesPerRow;
			m_numVertsPerCol	= numVertsPerCol;
			m_cellSpacing		= cellSpacing;
			
			m_numCellsPerRow	= numVertesPerRow - 1;
			m_numCellsperCol	= numVertsPerCol - 1;
			
			m_width				= m_numCellsPerRow * m_cellSpacing;
			m_depth				= m_numCellsperCol * m_cellSpacing;
			
			m_numVertices		= m_numVertsPerRow * m_numVertsPerCol;
			m_numTriangles		= m_numCellsPerRow * m_numCellsperCol * 2;
			
			m_heightScale = heightScale;
			
			if(!parseHeightMaps(data)) return;
			
			var len : uint = m_heightMap.length;
			for(var i : int = 0; i < len; i++)
			{
				m_heightMap[i] *= heightScale;
			}
			computeVertices();
			computeIndices();
			createBuffer();
		}
		
		public function updateFromByteArray(byteArray : ByteArray, start : uint, offset : uint, num : uint) : void
		{
			var vertexByteArray : ByteArray = new ByteArray();
			vertexByteArray.endian = Endian.LITTLE_ENDIAN;
			vertexByteArray.writeBytes(byteArray,0,byteArray.length);
			
			var index : int = 1;
			vertexByteArray.position = 0;
			while(vertexByteArray.bytesAvailable){
				var r : Number = vertexByteArray.readFloat() * 256;
				var g : Number = vertexByteArray.readFloat() * 256;
				var b : Number = vertexByteArray.readFloat() * 256;
				var c : Number = r & 0xFF0000 << 16 | g & 0x00FF00 << 8 | b & 0x0000FF;
				m_rawVertex[index] = c * .05;
				index += 3;
			}
			
			m_vertexBuffer.uploadFromVector(m_rawVertex, 0, m_rawVertex.length / 3);
			m_colorBuffer.uploadFromByteArray(byteArray,offset,start,num - 1);
		}
		
		public function setTexture(data : BitmapData) : void
		{
			m_texture = Utils.getTextureByBmd(data, m_context3D);
		}
		
		public function genTexture(light : Vector3D) : void
		{
			var texWidth : int = m_numVertsPerRow;
			var texHeight : int = m_numVertsPerCol;
			
			var emptyBmd : BitmapData = new BitmapData(texWidth, texHeight,false);
			emptyBmd.lock();
			emptyBmd.fillRect(emptyBmd.rect,0x0099cc);
			
//			for(var i : int = 0; i < texHeight; i ++)
//			{
//				for(var j : int = 0; j < texWidth; j++)
//				{
//					var c : uint;
//					var height : Number = getHeightMapEntry(i,j) / m_heightScale;
//					
//					if(height < 42.5) c = Utils.BEACH_SAND;
//					else if(height < 85) c = Utils.LIGHT_YELLOW_GREEN;
//					else if(height < 127.5) c = Utils.PUREGREEN;
//					else if(height < 170) c = Utils.DARK_YELLOW_GREEN;
//					else if(height < 212.5) c = Utils.DARKBROWN;
//					else c = Utils.WHITE;
//					
//					emptyBmd.setPixel32(j,i,c);
//				}
//			}
//			
//			lightTerrain(emptyBmd,light);
			
			emptyBmd.unlock();
			setTexture(emptyBmd);
		}
		
		private function lightTerrain(bmd : BitmapData, light : Vector3D) : void
		{
			var bmdData : Vector.<uint> = bmd.getVector(bmd.rect);
			for(var i : int = 0; i < bmd.height - 1; i++)
			{
				for(var j : int = 0; j < bmd.width - 1; j++)
				{
					//从uint中分解出RGB,附带上亮度值后还原
					var bright : Number = computeShade(i,j,light);
					var color : Number = bmdData[i * bmd.width + j];
					var red : Number = ((color & 0xFF0000) >> 16) * bright;
					var green : Number = ((color & 0x00FF00) >> 8) * bright;
					var blue : Number = ((color & 0x0000FF)) * bright;
					var endColor : uint = red << 16 | green << 8 | blue;
					bmdData[i * bmd.width + j] = endColor; 
				}
			}
			
			bmd.setVector(bmd.rect,bmdData);
		}
		
		/**
		 * 计算地形阴影
		 */
		private function computeShade(cellRow : int, cellCol : int, light : Vector3D) : Number
		{
			var heightA : Number = getHeightMapEntry(cellRow, cellCol);
			var heightB : Number = getHeightMapEntry(cellRow,cellCol + 1);
			var heightC : Number = getHeightMapEntry(cellRow + 1, cellCol);
			
			//创建2个顶点
			var u : Vector3D = new Vector3D(m_cellSpacing, heightB - heightA,0);
			var v : Vector3D = new Vector3D(0,heightC - heightA, -m_cellSpacing);
			
			//用方格中的两个向量叉积找到面法线
			var n : Vector3D = u.crossProduct(v);
			n.normalize();
			
			var cosine : Number = n.dotProduct(light);
			
			if(cosine < 0)
				cosine = 0;
			
			return cosine;
		}
		
		public function render(view : Matrix3D, proj : Matrix3D, shader : Program3D) : void
		{
			updateTransform();
			
			m_matrix.identity();
			m_matrix.append(m_transform);
			m_matrix.append(view);
			m_matrix.append(proj);
			
			m_context3D.setProgram(shader);
			m_context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, m_matrix, true);
			m_context3D.setTextureAt(0, m_texture);
			m_context3D.setVertexBufferAt(0,m_vertexBuffer,0,Context3DVertexBufferFormat.FLOAT_3);
			m_context3D.setVertexBufferAt(1,m_uvBuffer,0,Context3DVertexBufferFormat.FLOAT_2);
			m_context3D.setVertexBufferAt(2, m_colorBuffer,0, Context3DVertexBufferFormat.FLOAT_3);
			m_context3D.drawTriangles(m_indexBuffer,0,m_numTriangles);
			
			m_context3D.setVertexBufferAt(0,null);
			m_context3D.setVertexBufferAt(1,null);
			m_context3D.setVertexBufferAt(2,null);
			m_context3D.setTextureAt(0,null);
			m_context3D.setProgram(null);
		}
		
		public function getHeight(x : Number, z : Number) : Number
		{
			x = (m_width >> 1) + x;
			z = (m_depth >> 1) - z;
			
			x /= m_cellSpacing;
			z /= m_cellSpacing;
			
			var col : int = Math.floor(x);
			var row : int = Math.floor(z);
			
			var A : Number = getHeightMapEntry(row, col);
			var B : Number = getHeightMapEntry(row, col + 1);
			var C : Number = getHeightMapEntry(row + 1, col);
			var D : Number = getHeightMapEntry(row + 1, col + 1);
			
			var dx : Number = x - col;
			var dz : Number = z - row;
			
			var height : Number = 0;
			if(dz < 1 - dx)
			{
				var uy : Number = B - A;
				var vy : Number = C - A;
				
				height = A + Utils.lerp(0,uy,1 - dx) + Utils.lerp(0,vy,1 - dz);
			}else{
				var uy : Number = C - D;
				var vy : Number = B - D;
				
				height = D + Utils.lerp(0,uy,1 - dx) + Utils.lerp(0,vy,1 - dz);
			}
			
			return height;
		}
		
		private function parseHeightMaps(data : ByteArray) : Boolean
		{
			if(null == data || 0 == data.bytesAvailable) return false;
			
			var len : uint = data.bytesAvailable;
			for(var i : int = 0; i < len; i++){
				m_heightMap.push(data.readUnsignedByte());
			}
			return true;
		}
		
		private function computeVertices() : void
		{
			var startX : int = -m_width / 2;
			var startZ : int = m_depth / 2;
			
			var endX : int = m_width / 2;
			var endZ : int = -m_depth / 2;
			
			//计算每个顶点间的uv材质坐标系的递增值
			var uCoordIncrementSize : Number = 1.0 / m_numCellsPerRow;
			var vCoordIncrementSize : Number = 1.0 / m_numCellsperCol;
			
			var i : int = 0;
			var j : int = 0;
			var z : int = 0;
			var x : int = 0;
			for(z = startZ; z >= endZ; z -= m_cellSpacing)
			{
				j = 0;
				for(x = startX; x <= endX; x += m_cellSpacing)
				{
					//计算当前顶点缓冲的索引，避免死循环
					var index : int = i * m_numVertsPerRow + j;
					m_rawVertex.push(x,0,z);
					m_rawUv.push(j * uCoordIncrementSize,i * vCoordIncrementSize);
					j++;
				}
				i++;
			}
		}
		
		private function computeIndices() : void
		{
			var baseIndex : int = 0;
			
			for(var i : int = 0; i < m_numCellsPerRow; i++)
			{
				for(var j : int = 0; j < m_numCellsPerRow; j++)
				{
					m_rawIndex[baseIndex]		= i * m_numVertsPerRow + j;
					m_rawIndex[baseIndex + 1]	= i * m_numVertsPerRow + j + 1;
					m_rawIndex[baseIndex + 2]	= (i + 1) * m_numVertsPerRow + j;
					m_rawIndex[baseIndex + 3]	= (i + 1) * m_numVertsPerRow + j;
					m_rawIndex[baseIndex + 4]	= i * m_numVertsPerRow + j + 1;
					m_rawIndex[baseIndex + 5]	= (i + 1) * m_numVertsPerRow + j + 1;
					
					baseIndex += 6;
				}
			}
			trace("索引解析完毕");
		}
		
		private function createBuffer() : void
		{
			m_vertexBuffer = m_context3D.createVertexBuffer(m_rawVertex.length / 3, 3);
			m_vertexBuffer.uploadFromVector(m_rawVertex, 0, m_rawVertex.length / 3);
			
			m_indexBuffer = m_context3D.createIndexBuffer(m_rawIndex.length);
			m_indexBuffer.uploadFromVector(m_rawIndex,0,m_rawIndex.length);
			
			m_colorBuffer = m_context3D.createVertexBuffer(m_rawVertex.length / 3,3);
			m_colorBuffer.uploadFromVector(m_rawVertex, 0, m_rawVertex.length / 3);
			
			m_uvBuffer = m_context3D.createVertexBuffer(m_rawUv.length / 2, 2);
			m_uvBuffer.uploadFromVector(m_rawUv,0, m_rawUv.length / 2);
			
			trace("缓冲创建完毕");
		}
		
		public function getHeightMapEntry(row : int, col : int) : int
		{
			return m_heightMap[row * m_numVertsPerRow + col];
		}
		
		public function setHeightMapEntry(row : int, col : int, value : int) : void
		{
			m_heightMap[row * m_numVertsPerRow + col] = value;
		}
		
		public function getRotation() : Vector3D
		{
			return m_rotate;
		}
		
		public function setRotation(x : Number, y : Number, z : Number) : void
		{
			m_rotate.x = x;
			m_rotate.y = y;
			m_rotate.z = z;
			
			m_needUpdateTransform = true;
		}
		
		public function updateTransform() : void
		{
			if(!m_needUpdateTransform) return;
			
			m_transform.identity();
			m_transform.appendRotation(m_rotate.x, Vector3D.X_AXIS);
			m_transform.appendRotation(m_rotate.y, Vector3D.Y_AXIS);
			m_transform.appendRotation(m_rotate.z, Vector3D.Z_AXIS);
			m_transform.appendScale(m_scale.x,m_scale.y,m_scale.z);
			
			m_transform.appendTranslation(m_pos.x,m_pos.y,m_pos.z);
		}
		
		public function move(x : Number, y : Number, z : Number) : void
		{
			m_pos.x += x;
			m_pos.y += y;
			m_pos.z += z;
			
			m_needUpdateTransform = true;
		}
		
		public function moveTo(x : Number, y : Number, z : Number) : void
		{
			m_pos.x = x;
			m_pos.y = y;
			m_pos.z = z;
			
			m_needUpdateTransform = true;
		}
		
		public function rotation(value : Number, axis : Vector3D) : void
		{
			switch(axis){
				case Vector3D.X_AXIS:
					m_rotate.x = value;
					break;
				case Vector3D.Y_AXIS:
					m_rotate.y = value;
					break;
				case Vector3D.Z_AXIS:
					m_rotate.z = value;
					break;
			}
			
			m_needUpdateTransform = true;
		}
		
		public function get position() : Vector3D
		{
			return m_transform.position;
		}
	}
}