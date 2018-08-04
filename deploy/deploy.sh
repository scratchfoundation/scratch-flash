#! /bin/sh

root=`dirname $0`
cd "$root/.."
root=`pwd`

deployDir=`mktemp -d '/tmp/scratch-XXXX'`
echo $deployDir

# copy webapp files/directories
cp -R $root/webapp/* $deployDir

# copy scratch files
mkdir $deployDir/scratch
cp -R $root/bin-release/* $deployDir/scratch


dest='root@47.98.176.45:~'
#rsync -uravzh -e "ssh -i $root/deploy/aliyun.pem" $deployDir/* "$dest/scratchonline/"

#rm -r $deployDir
