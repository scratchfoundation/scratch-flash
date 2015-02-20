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

function errorCheckThen(nextCall) {
    return function(err, stdout, stderr) {
        if (err) {
            console.log(err);
            process.exit(1);
        } else {
            nextCall();
        }
    };
}

function compile(src, dest, callback, lib_paths, extra_args) {
    var args = [
        '-output', dest,
        '-debug=false'
    ];

    if(lib_paths) {
        lib_paths.forEach(function(lib_path){
            args.push('-library-path+='+lib_path);
        });
    }

    args.push(src);

    if(extra_args) {
        args = args.concat(extra_args);
    }

    childProcess.execFile(binPath, args, callback);
}

var src = path.join(src_dir, 'Scratch.as');
var libs = [
    path.join(libs_dir, 'blooddy_crypto.swc')
];

function compileWith3D(callback) {
    compile(src, path.join(deploy_dir, 'Scratch.swf'), callback, libs, [
        '-target-player=11.4',
        '-swf-version=17',
        '-define=SCRATCH::allow3d,true'
    ]);
}

function compileWithout3D(callback) {
    compile(src, path.join(deploy_dir, 'ScratchFor10.2.swf'), callback, libs, [
        '-target-player=10.2',
        '-swf-version=11',
        '-define=SCRATCH::allow3d,false'
    ]);
}

compileWith3D(
    errorCheckThen(function() {
        compileWithout3D(
            errorCheckThen(function() {
                process.exit(0);
            })
        )
    })
);
