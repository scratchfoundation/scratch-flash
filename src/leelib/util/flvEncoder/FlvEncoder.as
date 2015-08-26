package leelib.util.flvEncoder 
{
    import flash.display.BitmapData;
    import flash.errors.IllegalOperationError;
    import flash.geom.Rectangle;
    import flash.utils.ByteArray;
    import flash.utils.Endian;
    import flash.utils.IDataOutput;
    import flash.utils.getQualifiedClassName;
    import flash.utils.getQualifiedSuperclassName;
    
	/**
	 * Don't instantiate this class directly. 
	 * Use ByteArrayFlvEncoder or FileStreamFlvEncoder instead.
	 */
	public class FlvEncoder
	{
		public static const SAMPLERATE_11KHZ:uint = 11025;
		public static const SAMPLERATE_22KHZ:uint = 22050;
		public static const SAMPLERATE_44KHZ:uint = 44100;
		
		public static const BLOCK_WIDTH:int = 32;
		public static const BLOCK_HEIGHT:int = 32;

		protected var _frameRate:Number;
		protected var _bytes:IByteable;
		
		private var _duration:Number;
		private var _durationPos:int;

		private var _hasVideo:Boolean;
		private var _frameWidth:int;
		private var _frameHeight:int;
		
		private var _hasAudio:Boolean;
		private var _sampleRate:uint;
		private var _is16Bit:Boolean;
		private var _isStereo:Boolean;
		private var _isAudioInputFloats:Boolean;

		private var _videoPayloadMaker:IVideoPayload;
		
		private var _soundPropertiesByte:uint;
		private var _audioFrameSize:uint;
		
		private var _lastTagSize:uint = 0;
		private var _frameNum:int = 0;

		private var _isStarted:Boolean;
		
		
		/**
		 * @param $framesPerSecond		Dictates the framerate of FLV playback. 
		 */
	 	public function FlvEncoder($frameRate:Number)
		{
			var s:String = getQualifiedClassName(this);
			s = s.substr(s.indexOf("::")+2);
			if (s == "FlvEncoder") throw new IllegalOperationError("FlvEncoder must be instantiated thru a subclass (eg, ByteArrayFlvEncoder or FileStreamFlvEncoder)"); 
			
			_frameRate = $frameRate;
			
			makeBytes(); 
		}
		
		protected function makeBytes():void
		{
			//
			// _bytes must be instantiated here
			//
		}

		/**
		 * Defines the video dimensions to be used in the FLV.
		 * setVideoProperties() must be called before calling "start()"
		 * 
		 * @param $width		Width of each bitmapData to be supplied in addFrame()
		 * @param $height		Width of each bitmapData to be supplied in addFrame()
		 * 
		 * @param $customVideoPayloadMakerClass	
		 * 						A custom video encoder class can be specified here.
		 * 						(For example, one that is Alchemy or Pixelbender-based).
		 */
		public function setVideoProperties($width:int, $height:int, $customVideoPayloadMakerClass:Class=null):void
		{
			if (_isStarted) {
				throw new Error("setVideoProperties() must be called before begin()");
			}
			
			if (! $customVideoPayloadMakerClass) {
				_videoPayloadMaker = new VideoPayloadMaker();
			}
			else {
				_videoPayloadMaker = new $customVideoPayloadMakerClass();
				
				if (! _videoPayloadMaker || ! (_videoPayloadMaker is IVideoPayload)) {
					throw new Error("$customVideoPayloadMakerClass is not of type IVideoPayload");
				}
			}
			_videoPayloadMaker.init($width, $height);
			
			_frameWidth = $width;
			_frameHeight = $height;
			_hasVideo = true;
		}
		
		/**
		 * Defines the audio properties to be used in the FLV.
		 * setAudioProperties() must be called before calling "start()"
		 * 
		 * @param $sampleRate			Should be either SAMPLERATE_11KHZ, SAMPLERATE_22KHZ, or SAMPLERATE_44KHZ
		 * @param $is16Bit				16-bit audio will be expected if true, 8-bit if false
		 * 								Default is true, matching data format coming from Microphone
		 * @param $isStereo				Two channel of audio will be expected if true, one (mono) if false
		 * 								Default is false, matching data format coming from Microphone
		 * @param $dataWillBeInFloats	If set to true, audio data supplied to "addFrame()" will be assumed to be
		 * 								in floating point format and will be automatically converted to 
		 * 								unsigned shortints for the FLV. (PCM audio coming from either WAV files or 
		 * 								from webcam microphone input is in floating point format.) 
		 */		
		public function setAudioProperties($sampleRate:uint=0, $is16Bit:Boolean=true, $isStereo:Boolean=false, $dataWillBeInFloats:Boolean=true):void
		{
			if (_isStarted) {
				throw new Error("setAudioProperties() must be called before begin()");
			}
			if ($sampleRate != SAMPLERATE_44KHZ && $sampleRate != SAMPLERATE_22KHZ && $sampleRate != SAMPLERATE_11KHZ) { 
				throw new Error("Invalid samplerate value. Use supplied constants (eg, SAMPLERATE_11KHZ)");
			}
			
			_sampleRate = $sampleRate;
			_is16Bit = $is16Bit;
			_isStereo = $isStereo;
			_isAudioInputFloats = $dataWillBeInFloats;
			
			var n:Number = _sampleRate * (_isStereo ? 2 : 1) * (_is16Bit ? 2 : 1);
			n = n / _frameRate;
			if (_isAudioInputFloats) n *= 2;
			_audioFrameSize = int(n);
			
			_soundPropertiesByte = makeSoundPropertiesByte();
			
			_hasAudio = true;
		}
		
		/**
		 * Must be called after setVideoProperties and/or setAudioProperties
		 * and before addFrame() gets called.
		 * 
		 * If setAudioProperties() was not called, the FLV is assumed to be video-only.
		 * If setVideoProperties() was not called, the FLV is assumed to be audio-only.
		 */
		public function start():void
		{
			if (_isStarted) throw new Error("begin() has already been called");
			if (_hasVideo==false && _hasAudio==false) throw new Error("setVideoProperties() and/or setAudioProperties() must be called first");
			
			// create header
			var ba:ByteArray = new ByteArray();
			ba.writeBytes( makeHeader() );
			
			// create metadata tag
			ba.writeUnsignedInt( _lastTagSize );
			ba.writeBytes( makeMetaDataTag() );

			// get and save position of metadata's duration float
			var tmp:ByteArray = new ByteArray();
			tmp.writeUTFBytes("duration");
			_durationPos = byteArrayIndexOf(ba, tmp) + tmp.length + 1;
			
			_bytes.writeBytes(ba);

		}
		
		/**
		 * @param $bitmapData	Dimensions should match those supplied in setVideoProperties.
		 * 						If creating an audio-only FLV, set to null.
		 * 
		 * @param $pcmAudio		Audio properties (bits per sample, channels per sample, and sample-rate) 
		 * 						should match those supplied in setAudioProperties.
		 * 						If creating a video-only FLV, set to null. 
		 */
		public function addFrame($bitmapData:BitmapData, $uncompressedAudio:ByteArray):void
		{
			if (! _bytes) throw new Error("start() must be called first");
			if (! _hasVideo && $bitmapData) throw new Error("Expecting null for argument 1 because video properties were not defined via setVideoProperties()");
			if (! _hasAudio && $uncompressedAudio) throw new Error("Expecting null for argument 2 because audio properties were not defined via setAudioProperties()");
			if (_hasVideo && ! $bitmapData) throw new Error("Expecting value for argument 1");
			if (_hasAudio && ! $uncompressedAudio) throw new Error("Expecting value for argument 2");
			
			if ($bitmapData) 
			{
				_bytes.writeUnsignedInt(_lastTagSize);
				writeVideoTagTo(_bytes, $bitmapData);
			}
			
			if ($uncompressedAudio) 
			{
				_bytes.writeUnsignedInt(_lastTagSize);
				
				// Note how, if _isAudioInputFloats is true (which is the default), 
				// the incoming audio data is assumed to be in normalized floats 
				// (4 bytes per float value) and converted to signed shortint's, 
				// which are 2 bytes per value. Don't let this be a source of confusion...
				
				var b:ByteArray = _isAudioInputFloats ? floatsToSignedShorts($uncompressedAudio) : $uncompressedAudio;

				writeAudioTagTo(_bytes, b);
			}

			_frameNum++;
		}
		
		public function updateDurationMetadata():void
		{
			_bytes.pos = _durationPos;
			_bytes.writeDouble( _frameNum / _frameRate );
			_bytes.pos = _bytes.len; // (restore)
		}
		

		protected function get bytes():IByteable
		{
			return _bytes;
		}
		
		public function get frameRate():Number
		{
			return _frameRate;
		}	
		
		/**
		 * Prepare instance for garbage collection.
		 */		
		public function kill():void
		{
			_videoPayloadMaker.kill();
			_bytes = null;
			_videoPayloadMaker = null;
		}
		
		/**
		 * Convenience property returning the expected size in bytes of the   
		 * audio data that should be supplied in the addFrame() method.
		 */
		public function get audioFrameSize():uint
		{
			return _audioFrameSize;
		}
		
		public function get frameWidth():uint
		{
			return _frameWidth;
		}
		
		public function get frameHeight():uint
		{
			return _frameHeight;
		}
		
		/**
		 * Convenience method to convert Sound.extract data or SampleDataEvent data
		 * into linear PCM format used for uncompressed FLV audio.
		 * I.e., converts normalized floats to signed shortints.
		 */
		public static function floatsToSignedShorts($ba:ByteArray):ByteArray
		{
			var out:ByteArray = new ByteArray();
			out.endian = Endian.LITTLE_ENDIAN;
			
			$ba.position = 0;
			var num:int = $ba.length / 4;
			
			for (var i:int = 0; i < num; i++)
			{
				var n:Number = $ba.readFloat();
				var val:int = n * 32768;
				out.writeShort(val);
			}
			
			return out;
		}
		
		//
		
		private function makeHeader():ByteArray
		{
			var baHeader:ByteArray = new ByteArray();
			
			baHeader.writeByte(0x46) // 'F'
			baHeader.writeByte(0x4C) // 'L'
			baHeader.writeByte(0x56) // 'V'
			baHeader.writeByte(0x01) // Version 1
			
			// streams: video and/or audio
			var u:uint = 0;
			if (_hasVideo) u += 1;
			if (_hasAudio) u += 4;
			baHeader.writeByte(u);
			
			baHeader.writeUnsignedInt(0x09) // header length
			
			return baHeader;
		}		
		
		private function makeMetaDataTag():ByteArray
		{
			var baTag:ByteArray = new ByteArray();
			var baMetaData:ByteArray = makeMetaData();

			// tag 'header'
			baTag.writeByte( 18 ); 					// tagType = script data
			writeUI24(baTag, baMetaData.length);	// data size
			writeUI24(baTag, 0);					// timestamp should be 0 for onMetaData tag
			baTag.writeByte(0);						// timestamp extended
			writeUI24(baTag, 0);					// streamID always 0
			
			// payload		
			baTag.writeBytes( baMetaData );
			
			_lastTagSize = baTag.length;
			return baTag;
		}

		private function makeMetaData():ByteArray
		{
			// onMetaData info goes in a ScriptDataObject of data type 'ECMA Array'

			var b:ByteArray = new ByteArray();
			
			// ObjectNameType (always 2)
			b.writeByte(2);	
		
			// ObjectName (type SCRIPTDATASTRING):
			writeUI16(b, "onMetaData".length); // StringLength
			b.writeUTFBytes( "onMetaData" ); // StringData
		
			// ObjectData (type SCRIPTDATAVALUE):
			
			b.writeByte(8); // Type (ECMA array = 8)
			b.writeUnsignedInt(7) // // Elements in array
		
			// SCRIPTDATAVARIABLES...
			
			writeUI16(b, "duration".length);
			b.writeUTFBytes("duration");
			b.writeByte(0); 
			b.writeDouble(0.0); // * this value will get updated dynamically with addFrame() 
			
			writeUI16(b, "width".length);
			b.writeUTFBytes("width");
			b.writeByte(0); 
			b.writeDouble(_frameWidth);

			writeUI16(b, "height".length);
			b.writeUTFBytes("height");
			b.writeByte(0); 
			b.writeDouble(_frameHeight);

			writeUI16(b, "framerate".length);
			b.writeUTFBytes("framerate");
			b.writeByte(0); 
			b.writeDouble(_frameRate);

			writeUI16(b, "videocodecid".length);
			b.writeUTFBytes("videocodecid");
			b.writeByte(0); 
			b.writeDouble(3); // 'Screen Video' = 3

			writeUI16(b, "canSeekToEnd".length);
			b.writeUTFBytes("canSeekToEnd");
			b.writeByte(1); 
			b.writeByte(int(true));

			var mdc:String = "FlvEncoder v0.9 Lee Felarca";			
			writeUI16(b, "metadatacreator".length);
			b.writeUTFBytes("metadatacreator");
			b.writeByte(2); 
			writeUI16(b, mdc.length);
			b.writeUTFBytes(mdc);
			
			// VariableEndMarker1 (type UI24 - always 9)
			writeUI24(b, 9);
		
			return b;			
		}

		private function writeVideoTagTo($bytes:IByteable, $bitmapData:BitmapData):void
		{
			var pos:int = $bytes.pos;

			var ba:ByteArray = _videoPayloadMaker.make($bitmapData);
			
			var timeStamp:uint = uint(1000/_frameRate * _frameNum);
			
			// tag 'header'
			$bytes.writeByte( 0x09 ); 				// tagType = video
			writeUI24($bytes, ba.length); 			// data size
			writeUI24($bytes, timeStamp);			// timestamp in ms
			$bytes.writeByte(0);					// timestamp extended, no need 
			writeUI24($bytes, 0);					// streamID always 0

			// payload			
			$bytes.writeBytes( ba );
			
			_lastTagSize = $bytes.pos - pos;
			
			ba.length = 0;
			ba = null;
		}
		
		private function writeAudioTagTo($bytes:IByteable, $pcmData:ByteArray):void
		{
			var pos:int = $bytes.pos;
			
			$bytes.writeByte( 0x08 ); 						// TagType - 8 = audio
			writeUI24($bytes, $pcmData.length+1); 			// DataSize ("+1" for header)
			var timeStamp:uint = uint(1000/_frameRate * _frameNum);
			writeUI24($bytes, timeStamp);					// Timestamp (ms)
			$bytes.writeByte(0);							// TimestampExtended - not using 
			writeUI24($bytes, 0);							// StreamID - always 0
			
			// AUDIODATA			
			$bytes.writeByte(_soundPropertiesByte);		// header
			$bytes.writeBytes($pcmData);					// real sound data
			
			_lastTagSize = $bytes.pos - pos;
		}
		
		private function makeSoundPropertiesByte():uint
		{
			var u:uint, val:int;
			
			// soundformat [4 bits] - only supporting linear PCM little endian == 3
			u  = (3 << 4); 

			// soundrate [2 bits]
			switch(_sampleRate) {
				case SAMPLERATE_11KHZ: 	val = 1; break;
				case SAMPLERATE_22KHZ: 	val = 2; break;
				case SAMPLERATE_44KHZ: 	val = 3; break;
			}
			u += (val << 2);
			
			// soundsize [1 bit] - 0 = 8bit; 1 = 16bit
			val = _is16Bit ? 1 : 0;
			u += (val << 1);
			
			// soundtype [1 bit] - 0 = mono; 1 = stereo
			val = _isStereo ? 1 : 0;
			u += (val << 0);			
			
			// trace('FlvEncoder.makeSoundPropertiesByte():', u.toString(2));

			return u;
		}
		
		public static function byteArrayIndexOf($ba:ByteArray, $searchTerm:ByteArray):int
		{
			var origPosBa:int = $ba.position;
			var origPosSearchTerm:int = $searchTerm.position;
			
			var end:int = $ba.length - $searchTerm.length
			for (var i:int = 0; i <= end; i++)
			{
				if (byteArrayEqualsAt($ba, $searchTerm, i)) 
				{
					$ba.position = origPosBa;
					$searchTerm.position = origPosSearchTerm;
					return i;
				}
			}
			
			$ba.position = origPosBa;
			$searchTerm.position = origPosSearchTerm;
			return -1;
		}
		
		public static function byteArrayEqualsAt($ba:ByteArray, $searchTerm:ByteArray, $position:int):Boolean
		{
			// NB, function will modify byteArrays' cursors 
			
			if ($position + $searchTerm.length > $ba.length) return false;
			
			$ba.position = $position;
			$searchTerm.position = 0;

			for (var i:int = 0; i < $searchTerm.length; i++)
			{
				var valBa:int = $ba.readByte();
				var valSearch:int = $searchTerm.readByte();
				
				if (valBa != valSearch) return false;
			}
			
			return true;
		}
		
		public static function writeUI24(stream:*, p:uint):void
		{
			var byte1:int = p >> 16;
			var byte2:int = p >> 8 & 0xff;
			var byte3:int = p & 0xff;
			stream.writeByte(byte1);
			stream.writeByte(byte2);
			stream.writeByte(byte3);
		}
		
		public static function writeUI16(stream:*, p:uint):void
		{
			stream.writeByte( p >> 8 )
			stream.writeByte( p & 0xff );			
		}

		public static function writeUI4_12(stream:*, p1:uint, p2:uint):void
		{
			// writes a 4-bit value followed by a 12-bit value in a total of 2 bytes

			var byte1a:int = p1 << 4;
			var byte1b:int = p2 >> 8;
			var byte1:int = byte1a + byte1b;
			var byte2:int = p2 & 0xff;

			stream.writeByte(byte1);
			stream.writeByte(byte2);
		}		
	}
}
