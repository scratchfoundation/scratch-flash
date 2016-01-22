/**
 * Created by Mallory on 11/30/15.
 */
package svgeditor.objs {
    import flash.display.Sprite;
    import flash.text.TextField;
    import flash.events.Event;

    import grabcut.CModule;
    import grabcut.vfs.ISpecialFile;

    public class FlasccConsole extends Sprite implements ISpecialFile {

                private var tf:TextField;

                public function SampleApplication():void {
                    addEventListener(Event.ADDED_TO_STAGE, initCode);
                }

                private function initCode(e:Event):void {
                    tf = new TextField();
                    addChild(tf);
                    tf.appendText("SWC Output:\n");



                    // call a C++ function that calls printf
                    var func:int = CModule.getPublicSymbol("test")
                    var result:int = CModule.callI(func, new Vector.<int>());
        }

        /**
         * The PlayerKernel implementation will use this function to handle
         * C IO write requests to the file "/dev/tty" (e.g. output from
         * printf will pass through this function). See the ISpecialFile
         * documentation for more information about the arguments and return value.
         */
        public function write(fd:int, bufPtr:int, nbyte:int, errnoPtr:int):int
        {
            var str:String = CModule.readString(bufPtr, nbyte);
            tf.appendText(str);
            trace(str);
            return nbyte;
        }

        /** See ISpecialFile */
        public function read(fd:int, bufPtr:int, nbyte:int, errnoPtr:int):int { return 0; }
        public function fcntl(fd:int, com:int, data:int, errnoPtr:int):int { return 0; }
        public function ioctl(fd:int, com:int, data:int, errnoPtr:int):int { return 0; }
    }
}
