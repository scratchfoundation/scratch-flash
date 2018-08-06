#! /bin/sh

mode='dev'

if [ $# -ge 1 ]; then
	mode=$1
fi

root=`dirname $0`
cd "$root/.."
root=`pwd`

deployDir='/tmp/scratch-debug'
if [ -d $deployDir ]; then
	rm -r $deployDir
fi
mkdir -p $deployDir

if [ $mode != 'dev' ]; then
    deployDir=`mktemp -d '/tmp/scratch-XXXX'`
fi
echo $deployDir

# copy webapp files/directories
cp -R $root/webapp/* $deployDir

# copy scratch files
mkdir -p $deployDir/scratch

if [ $mode == 'dev' ]; then
	cp -R $root/bin-debug/* $deployDir/scratch
	sed -i '.tmp' 's/WEBAPPURL/rewardafford.corp.gq1.yahoo.com/' $deployDir/scratch/Scratch.html
	dest='rewardafford.corp.gq1.yahoo.com:~'
	rsync -uravzh $deployDir/* "$dest/scratchonline/"
else
	cp -R $root/bin-release/* $deployDir/scratch
	sed -i '.tmp' 's/WEBAPPURL/www.scratchonline.cn/' $deployDir/scratch/Scratch.html
	dest='root@47.98.176.45:~'
	rsync -uravzh -e "ssh -i $root/deploy/aliyun.pem" $deployDir/* "$dest/scratchonline/"
	rm -r $deployDir
fi
