/*
 * Scratch Project Editor and Player
 * Copyright (C) 2014 Massachusetts Institute of Technology
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

/**
* This class lets you decode animated GIF files, and show animated GIF's in the Flash player
* Base Class : http://www.java2s.com/Code/Java/2D-Graphics-GUI/GiffileEncoder.htm
* @author Kevin Weiner (original Java version - kweiner@fmsware.com)
* @author Thibault Imbert (AS3 version - bytearray.org)
* @version 0.1 AS3 implementation
* 
* Modified for Scratch by John Maloney.
* Licensed under the MIT Open Source License.
*/

package util {
	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
public class GIFDecoder {
		/**
		 * File read status: No errors.
		 */
		private static var STATUS_OK:int = 0;

		/**
		 * File read status: Error decoding file (may be partially decoded)
		 */
		private static var STATUS_FORMAT_ERROR:int = 1;

		/**
		 * File read status: Unable to open source.
		 */
		private static var STATUS_OPEN_ERROR:int = 2;
		
		private static var frameRect:Rectangle = new Rectangle;

		private var inStream:ByteArray;
		private var status:int;

		// full image width
		private var width:int;
		// full image height
		private var height:int;
		// global color table used
		private var gctFlag:Boolean;
		// size of global color table
		private var gctSize:int;
		// iterations; 0 = repeat forever
		private var loopCount:int = 1;

		// global color table
		private var gct:Array;
		// local color table
		private var lct:Array;
		// active color table
		private var act:Array;

		// background color index
		private var bgIndex:int;
		// background color
		private var bgColor:int;
		// previous bg color
		private var lastBgColor:int;
		// pixel aspect ratio
		private var pixelAspect:int;

		private var lctFlag:Boolean // local color table flag
		// interlace flag
		private var interlace:Boolean;
		// local color table size
		private var lctSize:int;

		private var ix:int;
		private var iy:int;
		private var iw:int;
		// current image rectangle
		private var ih:int;
		// last image rect
		private var lastRect:Rectangle;
		// current frame
		private var image:BitmapData;
		private var bitmap:BitmapData;
		// previous frame
		private var lastImage:BitmapData;
		// current data block
		private var block:ByteArray = new ByteArray();
		// block size
		private var blockSize:int = 0;

		// last graphic control extension info
		private var dispose:int= 0;
		// 0=no action; 1=leave in place; 2=restore to bg; 3=restore to prev
		private var lastDispose:int = 0;
		 // use transparent color
		private var transparency:Boolean = false;
		 // delay in milliseconds
		private var delay:int = 0;
		 // transparent color index
		private var transIndex:int;

		// max decoder pixel stack size
		private static var MaxStackSize:int = 4096;

		// LZW decoder working arrays
		private var prefix:Array
		private var suffix:Array;
		private var pixelStack:Array;
		private var pixels:Array;

		// frames read from current file
		public var frames:Array
		public var frameCount:int

		/**
		 * Reads GIF image from stream
		 *
		 * @param BufferedInputStream containing GIF file.
		 * @return read status code (0 = no errors)
		 */
		public function read( inStream:ByteArray ):int
		{
			init();
			if ( inStream != null) 
			{
				this.inStream = inStream;
				readHeader();
				
				if (!hasError()) 
				{
					readContents();
					
					if (frameCount < 0) status = STATUS_FORMAT_ERROR;
				}
			} 
			else 
			{
				status = STATUS_OPEN_ERROR;
			}
			return status;
		}

		/**
		 * Creates new frame image from current data (and previous
		 * frames as specified by their disposition codes).
		 */
		private function getPixels( bitmap:BitmapData ):Array
		{	
			var pixels:Array = new Array ( 4 * image.width * image.height );
			var count:int = 0;
			var lngWidth:int = image.width;
			var lngHeight:int = image.height;
			var color:int;
			
			for (var th:int = 0; th < lngHeight; th++)
			{
				for (var tw:int = 0; tw < lngWidth; tw++)
				{
					color = bitmap.getPixel (th, tw);

					pixels[count++] = (color & 0xFF0000) >> 16;
					pixels[count++] = (color & 0x00FF00) >> 8;
					pixels[count++] = (color & 0x0000FF);
				}
			}
			return pixels;
		}
		
		private function setPixels( pixels:Array ):void
		{
			var count:int = 0;
			var color:int;
			pixels.position = 0;
			
			var lngWidth:int = image.width;
			var lngHeight:int = image.height;
			bitmap.lock();
			
			for (var th:int = 0; th < lngHeight; th++)
			{
				for (var tw:int = 0; tw < lngWidth; tw++)
				{
					color = pixels[int(count++)];
					bitmap.setPixel32 ( tw, th, color );
				}
			}
			bitmap.unlock();
		}

		private function transferPixels():void
		{
			// expose destination image's pixels as int array
			var dest:Array = getPixels( bitmap );
			// fill in starting image contents based on last image's dispose code
			if (lastDispose > 0)
			{
				if (lastDispose == 3) 
				{
					// use image before last
					var n:int = frameCount - 2;
					lastImage = n > 0 ? frames[n - 1] : null;
					
				}

				if (lastImage != null) 
				{
					var prev:Array = getPixels( lastImage );	
					dest = prev.slice();
					// copy pixels
					if (lastDispose == 2) 
					{
						// fill last image rect area with background color
						var c:Number;
						 // assume background is transparent
						c = transparency ? 0x00000000 : lastBgColor;
						// use given background color
						image.fillRect( lastRect, c );
					}
				}
			}

			// copy each source line to the appropriate place in the destination
			var pass:int = 1;
			var inc:int = 8;
			var iline:int = 0;
			for (var i:int = 0; i < ih; i++) 
			{
				var line:int = i;
				if (interlace) 
				{
					if (iline >= ih) 
					{
						pass++;
						switch (pass) 
						{
							case 2 :
								iline = 4;
								break;
							case 3 :
								iline = 2;
								inc = 4;
								break;
							case 4 :
								iline = 1;
								inc = 2;
								break;
						}
					}
					line = iline;
					iline += inc;
				}
				line += iy;
				if (line < height) 
				{
					var k:int = line * width;
					var dx:int = k + ix; // start of line in dest
					var dlim:int = dx + iw; // end of dest line
					if ((k + width) < dlim) 
					{
						dlim = k + width; // past dest edge
					}
					var sx:int = i * iw; // start of line in source
					var index:int;
					var tmp:int;
					while (dx < dlim) 
					{
						// map color and insert in destination
						index = (pixels[sx++]) & 0xff;
						tmp = act[index];
						if (tmp != 0) 
						{
							dest[dx] = tmp;
						}
						dx++;
					}
				}
			}
			setPixels( dest );
		}

		/**
		 * Decodes LZW image data into pixel array.
		 * Adapted from John Cristy's ImageMagick.
		 */
		private function decodeImageData():void
		{
			var NullCode:int = -1;
			var npix:int = iw * ih;
			var available:int;
			var clear:int;
			var code_mask:int;
			var code_size:int;
			var end_of_information:int;
			var in_code:int;
			var old_code:int;
			var bits:int;
			var code:int;
			var count:int;
			var i:int;
			var datum:int;
			var data_size:int;
			var first:int;
			var top:int;
			var bi:int;
			var pi:int;

			if ((pixels == null) || (pixels.length < npix)) 
			{
				pixels = new Array ( npix ); // allocate new pixel array
			}
			if (prefix == null) prefix = new Array ( MaxStackSize );
			if (suffix == null) suffix = new Array ( MaxStackSize );
			if (pixelStack == null) pixelStack = new Array ( MaxStackSize + 1 );

			//  Initialize GIF data stream decoder.

			data_size = readSingleByte();
			clear = 1 << data_size;
			end_of_information = clear + 1;
			available = clear + 2;
			old_code = NullCode;
			code_size = data_size + 1;
			code_mask = (1 << code_size) - 1;
			for (code = 0; code < clear; code++) 
			{
				prefix[int(code)] = 0;
				suffix[int(code)] = code;
			}

			//  Decode GIF pixel stream.
			datum = bits = count = first = top = pi = bi = 0;

			for (i = 0; i < npix;) 
			{
				if (top == 0) 
				{
					if (bits < code_size) 
					{
						//  Load bytes until there are enough bits for a code.
						if (count == 0) 
						{
							// Read a new data block.
							count = readBlock();
							if (count <= 0)
								break;
							bi = 0;
						}
						datum += (int((block[int(bi)])) & 0xff) << bits;
						bits += 8;
						bi++;
						count--;
						continue;
					}

					//  Get the next code.
					code = datum & code_mask;
					datum >>= code_size;
					bits -= code_size;
					//  Interpret the code
					if ((code > available) || (code == end_of_information))
						break;
					if (code == clear) 
					{
						//  Reset decoder.
						code_size = data_size + 1;
						code_mask = (1 << code_size) - 1;
						available = clear + 2;
						old_code = NullCode;
						continue;
					}
					if (old_code == NullCode) 
					{
						pixelStack[int(top++)] = suffix[int(code)];
						old_code = code;
						first = code;
						continue;
					}
					in_code = code;
					if (code == available) 
					{
						pixelStack[int(top++)] = first;
						code = old_code;
					}
					while (code > clear) 
					{
						pixelStack[int(top++)] = suffix[int(code)];
						code = prefix[int(code)];
					}
					first = (suffix[int(code)]) & 0xff;

					//  Add a new string to the string table,
			
					if (available >= MaxStackSize) break;
					pixelStack[int(top++)] = first;
					prefix[int(available)] = old_code;
					suffix[int(available)] = first;
					available++;
					if (((available & code_mask) == 0)
						&& (available < MaxStackSize)) 
					{
						code_size++;
						code_mask += available;
					}
					old_code = in_code;
				}

				//  Pop a pixel off the pixel stack.

				top--;
				pixels[int(pi++)] = pixelStack[int(top)];
				i++;
			}

			for (i = pi; i < npix; i++) 
			{
				pixels[int(i)] = 0; // clear missing pixels
			}

		}

		/**
		 * Returns true if an error was encountered during reading/decoding
		 */
		private function hasError():Boolean 
		{
			return status != STATUS_OK;
		}

		/**
		 * Initializes or re-initializes reader
		*/
		private function init():void 
		{
			status = STATUS_OK;
			frameCount = 0;
			frames = new Array;
			gct = null;
			lct = null;
		}

		/**
		 * Reads a single byte from the input stream.
		*/
		private function readSingleByte():int
		{
			var curByte:int = 0;
			try 
			{
				curByte = inStream.readUnsignedByte();
			} 
			catch (e:Error) 
			{
				status = STATUS_FORMAT_ERROR;
			}
			return curByte;
		}

		/**
		 * Reads next variable length block from input.
		 *
		 * @return number of bytes stored in "buffer"
		 */
		private function readBlock():int
		{
			blockSize = readSingleByte();
			var n:int = 0;
			if (blockSize > 0) 
			{
				try 
				{
					var count:int = 0;
					while (n < blockSize) 
					{

						inStream.readBytes(block, n, blockSize - n);
						if ( (blockSize - n) == -1) 
							break;
						n += (blockSize - n);
					}
				} 
				catch (e:Error) 
				{
				}

				if (n < blockSize) 
				{
					status = STATUS_FORMAT_ERROR;
				}
			}
			return n;
		}

		/**
		 * Reads color table as 256 RGB integer values
		 *
		 * @param ncolors int number of colors to read
		 * @return int array containing 256 colors (packed ARGB with full alpha)
		 */
		private function readColorTable(ncolors:int):Array 
		{
			var nbytes:int = 3 * ncolors;
			var tab:Array = null;
			var c:ByteArray = new ByteArray;
			var n:int = 0;
			try 
			{
				inStream.readBytes(c, 0, nbytes );
				n = nbytes;
			} 
			catch (e:Error) 
			{
			}
			if (n < nbytes) 
			{
				status = STATUS_FORMAT_ERROR;
			} 
			else 
			{
				tab = new Array(256); // max size to avoid bounds checks
				var i:int = 0;
				var j:int = 0;
				while (i < ncolors) 
				{
					var r:int = (c[j++]) & 0xff;
					var g:int = (c[j++]) & 0xff;
					var b:int = (c[j++]) & 0xff;
					tab[i++] = ( 0xff000000 | (r << 16) | (g << 8) | b );
				}
			}
			return tab;
		}

		/**
		 * Main file parser.  Reads GIF content blocks.
		 */
		private function readContents():void
		{
			// read GIF file content blocks
			var done:Boolean = false;
			
			while (!(done || hasError())) 
			{
				
				var code:int = readSingleByte();
				
				switch (code) 
				{

					case 0x2C : // image separator
						readImage();
						break;

					case 0x21 : // extension
						code = readSingleByte();
					switch (code) 
					{
						case 0xf9 : // graphics control extension
							readGraphicControlExt();
							break;

						case 0xff : // application extension
							readBlock();
							var app:String = "";
							for (var i:int = 0; i < 11; i++) 
							{
								app += block[int(i)];
							}
							if (app == "NETSCAPE2.0") 
							{
								readNetscapeExt();
							}
							else
								skip(); // don't care
							break;

						default : // uninteresting extension
							skip();
							break;
					}
						break;

					case 0x3b : // terminator
						done = true;
						break;

					case 0x00 : // bad byte, but keep going and see what happens
						break;

					default :
						status = STATUS_FORMAT_ERROR;
						break;
				}
			}
		}

		/**
		 * Reads Graphics Control Extension values
		 */
		private function readGraphicControlExt():void
		{
			readSingleByte(); // block size
			var packed:int = readSingleByte(); // packed fields
			dispose = (packed & 0x1c) >> 2; // disposal method
			if (dispose == 0) 
			{
				dispose = 1; // elect to keep old image if discretionary
			}
			transparency = (packed & 1) != 0;
			delay = readShort() * 10; // delay in milliseconds
			transIndex = readSingleByte(); // transparent color index
			readSingleByte(); // block terminator
		}

		/**
		 * Reads GIF file header information.
		 */
		private function readHeader():void
		{
			var id:String = "";
			for (var i:int = 0; i < 6; i++) 
			{
				id += String.fromCharCode (readSingleByte());

			}
			if (!( id.indexOf("GIF") == 0 ) ) 
			{
				status = STATUS_FORMAT_ERROR;
				throw new Error ( "Invalid file type" );
				return;
			}
			readLSD();
			if (gctFlag && !hasError()) 
			{
				gct = readColorTable(gctSize);
				bgColor = gct[bgIndex];
			}
		}

		/**
		 * Reads next frame image
		 */
		private function readImage():void 
		{
			ix = readShort(); // (sub)image position & size
			iy = readShort();
			iw = readShort();
			ih = readShort();

			var packed:int = readSingleByte();
			lctFlag = (packed & 0x80) != 0; // 1 - local color table flag
			interlace = (packed & 0x40) != 0; // 2 - interlace flag
			// 3 - sort flag
			// 4-5 - reserved
			lctSize = 2 << (packed & 7); // 6-8 - local color table size

			if (lctFlag) 
			{
				lct = readColorTable(lctSize); // read table
				act = lct; // make local table active
			} 
			else 
			{
				act = gct; // make global table active
				if (bgIndex == transIndex)
					bgColor = 0;
			}
			var save:int = 0;
			if (transparency) 
			{
				save = act[transIndex];
				act[transIndex] = 0; // set transparent color if specified
			}

			if (act == null) 
			{
				status = STATUS_FORMAT_ERROR; // no color table defined
			}

			if (hasError()) return;

			decodeImageData(); // decode pixel data
			skip();
			if (hasError()) return;

			frameCount++;
			// create new image to receive frame data

			bitmap = new BitmapData ( width, height );
			
			image = bitmap;
			
			transferPixels(); // transfer pixel data to image

			frames.push (bitmap); // add image to frame list

			if (transparency) act[transIndex] = save;
			
			resetFrame();

		}

		/**
		 * Reads Logical Screen Descriptor
		 */
		private function readLSD():void
		{

			// logical screen size
			width = readShort();
			height = readShort();

			// packed fields
			var packed:int = readSingleByte();

			gctFlag = (packed & 0x80) != 0; // 1   : global color table flag
			// 2-4 : color resolution
			// 5   : gct sort flag
			gctSize = 2 << (packed & 7); // 6-8 : gct size
			bgIndex = readSingleByte(); // background color index
			pixelAspect = readSingleByte(); // pixel aspect ratio

		}

		/**
		 * Reads Netscape extenstion to obtain iteration count
		 */
		private function readNetscapeExt():void
		{
			do 
			{
				readBlock();
				if (block[0] == 1) 
				{
					// loop count sub-block
					var b1:int = (block[1]) & 0xff;
					var b2:int = (block[2]) & 0xff;
					loopCount = (b2 << 8) | b1;
				}
			} while ((blockSize > 0) && !hasError());
		}

		/**
		 * Reads next 16-bit value, LSB first
		 */
		private function readShort():int
		{
			// read 16-bit value, LSB first
			return readSingleByte() | (readSingleByte() << 8);
		}

		/**
		 * Resets frame state for reading next image.
		 */
		private function resetFrame():void 
		{
			lastDispose = dispose;
			lastRect = new Rectangle(ix, iy, iw, ih);
			lastImage = image;
			lastBgColor = bgColor;
			// int dispose = 0;
			var transparency:Boolean = false;
			var delay:int = 0;
			lct = null;
		}

		/**
		 * Skips variable length blocks up to and including
		 * next zero length block.
		 */
		private function skip():void
		{
			do 
			{
				readBlock();
				
			} while ((blockSize > 0) && !hasError());
		}

}}