var childProcess = require('child_process');
var path = require('path');
var flexSdk = require('flex-sdk');
var binPath = flexSdk.bin.mxmlc;

// Source locations for Scratch and the 3D rendering library
var proj_dir = path.normalize(path.join(__dirname, '..'))
var src_dir = path.join(proj_dir, 'src');
var src_dir_3d = path.join(proj_dir, '3d_render_src');

// Where to find libraries to link into Scratch
var libs_dir = path.join(proj_dir, 'libs');

// Where to put the built SWF
var deploy_dir = path.join(proj_dir, 'bin');

// Build the 3D code
compile(path.join(src_dir_3d, 'DisplayObjectContainerIn3D.as'),
        path.join(libs_dir, 'RenderIn3D.swf'),
        function(err, stdout, stderr) {
            if (err) {
                console.log(err);
                process.exit(1);
            } else {
                // Build Scratch
                compile(path.join(src_dir, 'Scratch.as'),
                        path.join(deploy_dir, 'Scratch.swf'),
                        function(err, stdout, stderr) {
                            if (err) {
                                console.log(err);
                                process.exit(1);
                            } else {
                                process.exit(0);
                            }
                        },
                        [path.join(libs_dir, 'blooddy_crypto.swc')]
                );
            }
        }
);

function compile(src, dest, callback, lib_paths) {
    var args = [
        '-output', dest,
        '-target-player=11.4',
        '-swf-version=17',
        '-debug=false'
    ];

    if(lib_paths) {
        lib_paths.forEach(function(lib_path){
            args.push('-library-path+='+lib_path);
        });
    }

    args.push(src);
    childProcess.execFile(binPath, args, callback);
}
