environments {
    '11.6' {
        output = 'Scrap'
        playerVersion = '11.6'
        additionalCompilerOptions = [
                "-swf-version=19",
                "-define+=SCRATCH::allow3d,true",
        ]
    }
    '10.2' {
        output = 'Scrap'
        playerVersion = '10.2'
        additionalCompilerOptions = [
                "-swf-version=11",
                "-define+=SCRATCH::allow3d,false",
        ]
    }
}
