FlvEncoder (leelib.util.flvEncoder.*)
Lee Felarca
http://www.zeropointnine.com/blog
3-29-2011
Package version: v0.9b

Creates uncompressed FLV's with video and audio without server-side dependency.

See http://www.zeropointnine.com/blog/updated-flv-encoder-alchemy for more info.

FLV spec is described here: http://www.adobe.com/devnet/f4v.html


Example usage:

	[1] ByteArrayFlvEncoder:
	
		var baFlvEncoder:ByteArrayFlvEncoder = new ByteArrayFlvEncoder(myFrameRate);
		
		baFlvEncoder.setVideoProperties(myWidth, myHeight, VideoPayloadMakerAlchemy);
		// (Omit the 3rd argument to NOT use the Alchemy encoding routine)
		baFlvEncoder.setAudioProperties(BaseFlvEncoder.SAMPLERATE_44KHZ, true, false, true);
		
		baFlvEncoder.start();
		
		baFlvEncoder.addFrame(myBitmapData, myAudioByteArray);
		baFlvEncoder.addFrame(myBitmapData, myAudioByteArray); // etc.
		
		baFlvEncoder.updateDurationMetadata();
		
		saveOutMyFileUsingFileReference( baFlvEncoder.byteArray );
		
		baFlvEncoder.kill(); // for garbage collection
		
	[2] FileStreamFlvEncoder (using Adobe AIR)
	
		var myFile:File = File.documentsDirectory.resolvePath("video.flv");
		var fsFlvEncoder:FileStreamFlvEncoder = new FileStreamFlvEncoder(myFile, myFrameRate);
		fsFlvEncoder.fileStream.openAsync(myFile, FileMode.UPDATE);
		
		fsFlvEncoder.setVideoProperties(myWidth, myHeight, VideoPayloadMakerAlchemy);
		// (Omit the 3rd argument to NOT use the Alchemy encoding routine)
		fsFlvEncoder.setAudioProperties(BaseFlvEncoder.SAMPLERATE_44KHZ, true, false, true);
		
		fsFlvEncoder.start();
		
		fsFlvEncoder.addFrame(myBitmapData, myAudioByteArray);
		fsFlvEncoder.addFrame(myBitmapData, myAudioByteArray); // etc.
		
		fsFlvEncoder.updateDurationMetadata();
		
		fsFlvEncoder.fileStream.close();
	
		fsFlvEncoder.kill();
	
*** To use the Alchemy version, add a SWC folder reference to leelib/util/flvEncoder/alchemy


Source code licensed under a Creative Commons Attribution 3.0 License.
http://creativecommons.org/licenses/by/3.0/
Some Rights Reserved.
