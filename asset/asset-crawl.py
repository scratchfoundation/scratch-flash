# from StringIO import StringIO
import getopt
import gzip
import json
import sys
import os
import requests
import urllib
import re

pretend = False
downloaded = set()
cdn = 'cdn.assets.scratch.mit.edu'


def download(fileName):
    if fileName in downloaded: return None
    request = urllib.Request('http://'+cdn+'/internalapi/asset/{0}/get/'.format(fileName))
    print(request.get_full_url())
    if pretend: return None
    request.add_header('Accept-encoding', 'gzip')
    response = urllib.urlopen(request)
    contents = response.read()
    if response.info().get('Content-Encoding') == 'gzip':
        # rawFile = StringIO(contents)
        # gzFile = gzip.GzipFile(fileobj = rawFile)
        # contents = gzFile.read()
        contents = response.read()

    with open(fileName, 'wb') as f:
        f.write(contents)
    downloaded.add(fileName)
    return contents

def downloadMediaLibraryFiles(mediaLibFileName):
    print("Processing "+mediaLibFileName)
    with open(mediaLibFileName) as f:
        library = json.load(f)
        for item in library:
            fileName = item['md5']
            contents = download(fileName)
            if contents and fileName.lower().endswith('.json'):
                downloadSpriteFiles(contents)

def downloadSpriteFiles(spriteJSON):
    sprite = json.loads(spriteJSON)
    for sound in sprite.get('sounds',[]):
        download(sound['md5'])
    for costume in sprite.get('costumes',[]):
        download(costume['baseLayerMD5'])

def main():
    try:
        opts, args = getopt.gnu_getopt(sys.argv[1:], "p", ["pretend"])
    except getopt.GetoptError as err:
        print(err)
        sys.exit(2)

    for o,a in opts:
        if o in ("-p", "--pretend"):
            global pretend
            pretend = True
        else:
            assert False, "Unhandled option: " + o
    downloadMediaLibraryFiles("libs/backdropLibrary.json")
    downloadMediaLibraryFiles("libs/soundLibrary.json")
    downloadMediaLibraryFiles("libs/spriteLibrary.json")
    downloadMediaLibraryFiles("libs/costumeLibrary.json")
    downloadMediaLibraryFiles("../miscellaneous.json")


def download_file(url, path):
    floder = "/".join(path.split("/")[0:-1])
    if not os.path.exists(floder):
        os.makedirs(floder)
    res = requests.get(url)
    if path in downloaded:
        return None
    if res.status_code == 200:
        print(path)
        with open(path, "wb") as f:
            f.write(res.content)
            downloaded.add(path)
            return res.content
    else:
        return None


def download_media(json_path):
    if not json_path: return None
    media_url = "https://cdn.assets.scratch.mit.edu/internalapi/asset/%s/get/"
    thumbnails_url = "https://cdn.scratch.mit.edu/scratchr2/static/__628c3a81fae8e782363c36921a30b614__/medialibrarythumbnails/8d508770c1991fe05959c9b3b5167036.gif"
    download_path = "internalapi/asset/"
    json_name = json_path.split("/")[-1]


    with open(json_path, "r") as f:
        media = json.load(f)
        for m in media:
            res = download_file(media_url % m['md5'], download_path + m['md5'])
            if json_name == "spriteLibrary.json":
                # download sprite
                with open(download_path + m['md5'], "r") as s:
                    sprite = json.load(s)
                    for sound in sprite.get('sounds', []):
                        download_file(media_url % sound['md5'], download_path + sound['md5'])
                    for costume in sprite.get('costumes', []):
                        download_file(media_url % costume['baseLayerMD5'], download_path + costume['baseLayerMD5'])


def download_json(url):
    path = "scratchr2/static/"
    filename = url.split("/")[-1]
    filepath = path + filename
    if download_file(url, filepath):
        print("start process:", filepath)
        download_media(filepath)

json_url = [
"https://cdn.scratch.mit.edu/scratchr2/static/__628c3a81fae8e782363c36921a30b614__/medialibraries/spriteLibrary.json",
"https://cdn.scratch.mit.edu/scratchr2/static/__628c3a81fae8e782363c36921a30b614__/medialibraries/soundLibrary.json",
"https://cdn.scratch.mit.edu/scratchr2/static/__628c3a81fae8e782363c36921a30b614__/medialibraries/backdropLibrary.json",
"https://cdn.scratch.mit.edu/scratchr2/static/__628c3a81fae8e782363c36921a30b614__/medialibraries/costumeLibrary.json"
]

for u in json_url:
    download_json(u)