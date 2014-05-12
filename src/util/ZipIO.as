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

package util {
	import flash.utils.Endian;
	import flash.utils.ByteArray;

public class ZipIO {
		
	private const Version:int = 10;
	private const FileEntryID:uint = 0x04034b50;	// Local File Header Record
	private const DirEntryID:uint = 0x02014b50;		// Central Directory Record
	private const EndID:uint = 0x06054b50;			// End of Central Directory Record

	private static var crcTable:Array = makeCrcTable();

	private var buf:ByteArray;
	private var entries:Array = [];
	private var writtenFiles:Object = new Object();

	//************************************
	// Reading
	//************************************

	public function read(data:ByteArray):Array {
		// Read the given zip file data and return an array of [<name>, <data>] pairs.
		var i:int;
		buf = data;
		buf.endian = Endian.LITTLE_ENDIAN;
		entries = [];
		scanForEndRecord();
		var entryCount:int = readEndRecord();
		for (i = 0; i < entryCount; i++) entries.push(readDirEntry());
		var result:Array = [];
		for (i = 0; i < entries.length; i++) {
			var e:Entry = entries[i];
			readFile(e);
			result.push([e.name, e.data]);
		}
		return result;
	}

	public function recover(data:ByteArray):Array {
		// Scan the zip file for file entries and return all the well-formed files.
		// This can be used to recover some of the files if the zip file is damaged.
		var result:Array = [];
		buf = data;
		buf.endian = Endian.LITTLE_ENDIAN;
		for (var i:int = 0; i < buf.length - 4; i++) {
			if (buf[i] == 0x50) {
				buf.position = i;
				if (buf.readUnsignedInt() == FileEntryID) {
					// Try to extract the file.
					var e:Entry = new Entry();
					e.offset = i;
					try {
						readFile(e, true);
					} catch (e:*) {
						e = null; // skip bad file entry
					}
					if (e) result.push([e.name, e.data]);
				}
			}
		}
		return result;
	}

	private function readFile(e:Entry, recovering:Boolean = false):void {
		// Read a local file header and the following file data.
		// Decompress the data if necessary, check the CRC, and record in e.data.
		buf.position = e.offset;
		if (buf.readUnsignedInt() != FileEntryID) throw Error("zip: bad local file header");
		var versionNeeded:int = buf.readUnsignedShort();
		var flags:int = buf.readUnsignedShort();
		var compressionMethod:int = buf.readUnsignedShort();
		var dosTime:uint = buf.readUnsignedInt();
		var crc:uint = buf.readUnsignedInt();
		var compressedSize:uint = buf.readUnsignedInt();
		var uncompressedSize:uint = buf.readUnsignedInt();
		var nameLength:int = buf.readUnsignedShort();
		var extraLength:int = buf.readUnsignedShort();
		var fileName:String = buf.readUTFBytes(nameLength);
		var extra:ByteArray = new ByteArray();
		if (extraLength > 0) buf.readBytes(extra, 0, extraLength);
		if ((flags & 1) != 0) throw Error("cannot read encrypted zip files");
		if ((compressionMethod != 0) && (compressionMethod != 8)) throw Error("Cannot handle zip compression method " + compressionMethod);
		if (!recovering && ((flags & 8) != 0)) {
			// use the sizes and crc values from directory (these values are also stored following the data)
			compressedSize = e.compressedSize;
			uncompressedSize = e.size;
			crc = e.crc;
		}
		e.name = fileName;
		e.data = new ByteArray();
		if (compressedSize > 0) buf.readBytes(e.data, 0, compressedSize);
		if (compressionMethod == 8) e.data.inflate();
		if (e.data.length != uncompressedSize) throw Error("Bad uncompressed size");
		if (crc != computeCRC(e.data)) throw Error("Bad CRC");
	}

	private function readDirEntry():Entry {
		if (buf.readUnsignedInt() != DirEntryID) throw Error("zip: bad central directory entry");
		var versionMadeBy:int = buf.readUnsignedShort();
		var versionNeeded:int = buf.readUnsignedShort();
		var flags:int = buf.readUnsignedShort();
		var compressionMethod:int = buf.readUnsignedShort();
		var dosTime:uint = buf.readUnsignedInt();
		var crc:uint = buf.readUnsignedInt();
		var compressedSize:uint = buf.readUnsignedInt();
		var uncompressedSize:uint = buf.readUnsignedInt();
		var nameLength:int = buf.readUnsignedShort();
		var extraLength:int = buf.readUnsignedShort();
		var commentLength:int = buf.readUnsignedShort();
		var diskNum:int = buf.readUnsignedShort();
		var internalAttributes:int = buf.readUnsignedShort();
		var externalAttributes:uint = buf.readUnsignedInt();
		var offset:uint = buf.readUnsignedInt();
		var fileName:String = buf.readUTFBytes(nameLength);
		var extra:ByteArray = new ByteArray();
		if (extraLength > 0) buf.readBytes(extra, 0, extraLength);
		var comment:String = buf.readUTFBytes(commentLength);
		var entry:Entry = new Entry();
		entry.name = fileName;
		entry.time = dosTime;
		entry.offset = offset;
		entry.size = uncompressedSize;
		entry.compressedSize = compressedSize;
		entry.crc = crc;
		return entry;
	}

	private function readEndRecord():int {
		// Read the end-of-central-directory record. If successful, set entryCount
		// and leave the buffer positioned at the start of the directory.
		if (buf.readUnsignedInt() != EndID) throw Error("zip: bad zip end record");
		var thisDiskNum:int = buf.readUnsignedShort();
		var startDiskNum:int = buf.readUnsignedShort();
		var entriesOnThisDisk:int = buf.readUnsignedShort();
		var totalEntries:int = buf.readUnsignedShort();
		var directorySize:uint = buf.readUnsignedInt();
		var directoryOffset:uint = buf.readUnsignedInt();
		var comment:String = buf.readUTF();
		if ((thisDiskNum != startDiskNum) || (entriesOnThisDisk != totalEntries)) {
			 throw Error("cannot read multiple disk zip files");
		}
		buf.position = directoryOffset;
		return totalEntries;
	}

	private function scanForEndRecord():void {
		// Scan backwards from the end to find the EndOfCentralDiretory record.
		// If successful, leave the buffer positioned at the start of the record.
		// Otherwise, throw an error.
		for (var i:int = buf.length - 4; i >= 0; i--) {
			if (buf[i] == 0x50) {
				buf.position = i;
				if (buf.readUnsignedInt() == EndID) {
					buf.position = i;
					return;
				}
			}
		}
		throw new Error("Could not find zip directory; bad zip file?");
	}

	//************************************
	// Writing
	//************************************

	public function startWrite():void {
		buf = new ByteArray();
		buf.endian = Endian.LITTLE_ENDIAN;
		entries = [];
		writtenFiles = new Object();
	}

	public function write(fileName:String, stringOrByteArray:*, useCompression:Boolean = false):void {
		if (writtenFiles[fileName] != undefined) {
			throw new Error("duplicate file name: " + fileName);
		} else {
			writtenFiles[fileName] = true;
		}
		var e:Entry = new Entry();
		e.name = fileName;
		e.time = dosTime(new Date().time);
		e.offset = buf.position;
		e.compressionMethod = 0;
		e.data = new ByteArray();
		if (stringOrByteArray is String) e.data.writeUTFBytes(String(stringOrByteArray));
		else e.data.writeBytes(stringOrByteArray);
		e.size = e.data.length;
		e.crc = computeCRC(e.data);
		if (useCompression) {
			e.compressionMethod = 8;
			e.data.deflate();
		}
		e.compressedSize = e.data.length;
		entries.push(e); // record the entry so it can be saved in the directory

		// write the file header and data
		writeFileHeader(e);
		buf.writeBytes(e.data);
	}

	public function endWrite():ByteArray {
		if (entries.length < 1) throw new Error("A zip file must have at least one entry");
		var off:uint = buf.position;
		// write central directory
		for (var i:int = 0; i < entries.length; i++) {
			writeDirectoryEntry(entries[i]);
		}
		writeEndRecord(off, buf.position - off);
		buf.position = 0;
		return buf;
	}
	
	private function writeFileHeader(e:Entry):void {
		buf.writeUnsignedInt(FileEntryID);
		buf.writeShort(Version);
		buf.writeShort(0);				// flags
		buf.writeShort(e.compressionMethod);				
		buf.writeUnsignedInt(e.time);
		buf.writeUnsignedInt(e.crc);
		buf.writeUnsignedInt(e.compressedSize);
		buf.writeUnsignedInt(e.size);
		buf.writeShort(e.name.length);
		buf.writeShort(0);				// extra info length
		buf.writeUTFBytes(e.name);
		// optional extra info would go here
	}
	
	private function writeDirectoryEntry(e:Entry):void {
		buf.writeUnsignedInt(DirEntryID);
		buf.writeShort(Version);		// version created by
		buf.writeShort(Version);		// minimum version needed to extract
		buf.writeShort(0);				// flags
		buf.writeShort(e.compressionMethod);
		buf.writeUnsignedInt(e.time);
		buf.writeUnsignedInt(e.crc);
		buf.writeUnsignedInt(e.compressedSize);
		buf.writeUnsignedInt(e.size);
		buf.writeShort(e.name.length);
		buf.writeShort(0);				// extra info length
		buf.writeShort(0);				// comment length
		buf.writeShort(0);				// starting disk number
		buf.writeShort(0);				// internal file attributes
		buf.writeUnsignedInt(0);		// external file attributes
		buf.writeUnsignedInt(e.offset); // relative offset of local header
		buf.writeUTFBytes(e.name);
		// optional extra info would go here
		// optional comment would go here
	}
	
	private function writeEndRecord(dirStart:uint, dirSize:uint):void {
		buf.writeUnsignedInt(EndID);
		buf.writeShort(0);					// number of this disk
		buf.writeShort(0);					// central directory start disk
		buf.writeShort(entries.length);		// number of directory entries on this disk
		buf.writeShort(entries.length);		// total number of directory entries
		buf.writeUnsignedInt(dirSize);		// length of central directory in bytes
		buf.writeUnsignedInt(dirStart);		// offset of central directory from start of file
		buf.writeUTF("");					// zip file comment (not used)
	}

	public function dosTime(time:Number):uint {
		var d:Date = new Date(time);
		return (d.fullYear - 1980 & 0x7F) << 25
			| (d.month + 1) << 21
			| d.day << 16
			| d.hours << 11
			| d.minutes << 5
			| d.seconds >> 1;
	}

	private function computeCRC(buf:ByteArray):uint {
		var off:uint = 0;
		var len:uint = buf.length;
		var crc:uint = 0xFFFFFFFF; // = ~0
		while(--len >= 0) crc = crcTable[(crc ^ buf[off++]) & 0xFF] ^ (crc >>> 8);
		return ~crc & 0xFFFFFFFF;
	}

	/* CRC table, computed at load time. */
	private static function makeCrcTable():Array {
		var crcTable:Array = new Array(256);
		for (var n:int = 0; n < 256; n++) {
			var c:uint = n;
			for (var i:int = 0; i < 8; i++) {
				if ((c & 1) != 0) c = 0xedb88320 ^ (c >>> 1);
				else c = c >>> 1;
			}
			crcTable[n] = c;
		}
		return crcTable;
	}

}}
import flash.utils.ByteArray;

class Entry {
	public var name:String;
	public var time:uint;
	public var offset:uint;
	public var compressionMethod:int;	// compression method (0 = uncompressed, 8 = deflate)
	public var size:uint;
	public var compressedSize:uint;
	public var data:ByteArray;
	public var crc:uint;
}
