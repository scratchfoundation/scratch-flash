import hashlib
import os
import wave
import contextlib
import zipfile
import shutil
import json
from PIL import Image

# scratch根目录 ， 一般只需要配置该路径
PRE = ""
# 缩略图路径
PATH_THUMB = PRE + "scratchr2\\static\\medialibrarythumbnails\\"
# 资源路径
PATH_ASSET = PRE + "internalapi\\asset\\"
# 索引库目录
PRE_LIB = PRE + "scratchr2\\static\\medialibraries\\"
# 背景索引
LIB_BACKDROP = PRE_LIB + "backdropLibrary.json"
# 造型索引
LIB_COSTUME = PRE_LIB + "costumeLibrary.json"
# 声音索引
LIB_SOUND = PRE_LIB + "soundLibrary.json"
# 角色索引
LIB_SPRITE = PRE_LIB + "spriteLibrary.json"

if not os.path.exists(PATH_THUMB):
    print("缩略图目录配置不正确")
if not os.path.exists(PATH_ASSET):
    print("资源目录配置不正确")
if not os.path.isfile(LIB_BACKDROP):
    print("找不到背景索引文件")
if not os.path.isfile(LIB_COSTUME):
    print("找不到造型索引文件")
if not os.path.isfile(LIB_SOUND):
    print("找不到声音索引文件")
if not os.path.isfile(LIB_SPRITE):
    print("找不到角色索引文件")


print("""
=========使用说明：==========
1.将本脚本放在scratch根目录，或配置资源目录的路径
2.拖入文件或文件夹
3.回车确认

资源类型说明：
角色文件：.sprite2
背景文件：.jpg
造型文件：.png、.svg
音频文件：.wav
===========================
""")


# 获取md5
def get_md5(file_path):
    md5 = None
    if os.path.isfile(file_path):
        with open(file_path, 'rb') as f:
            md5_obj = hashlib.md5()
            md5_obj.update(f.read())
        hash_code = md5_obj.hexdigest()
        md5 = str(hash_code).lower()
    return md5


class Push:
    def __init__(self, fullpath, name=""):
        self.fullpath = fullpath
        self.path, self.filename = os.path.split(fullpath)
        self.name, self.suffix = os.path.splitext(self.filename)
        if name != "": self.name = name

    def push_costume(self):
        print("处理造型:", self.name)
        md5 = get_md5(self.fullpath)
        md5_filename = md5 + self.suffix
        shutil.copy(self.fullpath, PATH_ASSET + md5_filename)

        im = Image.open(self.fullpath)
        size_width, size_length = im.size
        im.thumbnail((100, 100))
        im.save(PATH_THUMB + md5_filename)
        custume_obj = {
            "info": [
                # 计算旋转中心
                size_width // 2,
                size_length // 2
            ],
            "md5": md5_filename,
            "input_type": "costume",
            "name": self.name,
            "tags": ['custom']
        }
        print(custume_obj)
        with open(LIB_COSTUME, 'r', encoding="utf-8") as f:
            text = f.read()
            json_data = json.loads(text)
            json_data.insert(0, custume_obj)
        with open(LIB_COSTUME, 'w', encoding='utf-8') as f:
            text_data = '[\n'
            for j in json_data:
                text_data += json.dumps(j)
                text_data += ",\n"
            text_data = text_data[:-2]
            text_data += "\n]"
            f.write(text_data)

    def push_back(self):
        print("处理背景:", self.name)
        md5 = get_md5(self.fullpath)
        md5_filename = md5 + self.suffix
        shutil.copy(self.fullpath, PATH_ASSET + md5_filename)

        im = Image.open(self.fullpath)
        im.thumbnail((100, 100))
        im.save(PATH_THUMB + md5_filename)

        back_obj = {"name": self.name, "md5": md5_filename, "input_type": "backdrop", "tags": ['custom'], "info": []}
        print(back_obj)
        with open(LIB_BACKDROP, 'r', encoding="utf-8") as f:
            text = f.read()
            json_data = json.loads(text)
            json_data.insert(0, back_obj)
        with open(LIB_BACKDROP, 'w', encoding='utf-8') as f:
            text_data = '[\n'
            for j in json_data:
                text_data += json.dumps(j)
                text_data += ",\n"
            text_data = text_data[:-2]
            text_data += "\n]"
            f.write(text_data)

    def push_sound(self):
        print("处理声音:", self.name)
        md5 = get_md5(self.fullpath)
        md5_filename = md5 + self.suffix

        # 计算音频时长
        duration = 0.00
        with contextlib.closing(wave.open(path, 'r')) as f:
            frames = f.getnframes()
            rate = f.getframerate()
            duration = frames / float(rate)
        duration = round(duration, 3)
        shutil.copy(self.fullpath, PATH_ASSET + md5_filename)
        sound_obj = {"name": self.name, "md5": md5_filename, "input_type": "sound", "tags": ["custom"], "info": [duration]}
        print(sound_obj)
        with open(LIB_SOUND, 'r', encoding="utf-8") as f:
            text = f.read()
            json_data = json.loads(text)
            json_data.insert(0, sound_obj)
        with open(LIB_SOUND, 'w', encoding='utf-8') as f:
            text_data = '[\n'
            for j in json_data:
                text_data += json.dumps(j)
                text_data += ",\n"
            text_data = text_data[:-2]
            text_data += "\n]"
            f.write(text_data)

    def push_sprite(self):
        print("处理角色:", self.name)
        if os.path.exists("tmp"):
            shutil.rmtree("tmp")
        zf = zipfile.ZipFile(self.fullpath)
        zf.extractall("tmp")

        for filename in os.listdir("tmp"):
            print("处理资源：", filename)
            name, ext = os.path.splitext(filename)
            md5 = get_md5("tmp\\" + filename)
            if ext == ".wav":
                shutil.copy("tmp\\" + filename, PATH_ASSET + md5 + ext)
            elif ext == ".png" or ext == ".svg" or ext == ".jpg":
                shutil.copy("tmp\\" + filename, PATH_ASSET + md5 + ext)
                # 生成缩略图
                im = Image.open("tmp\\" + filename)
                im.thumbnail((100, 100))
                im.save(PATH_THUMB + md5 + ext)
            elif ext == ".json":
                shutil.copy("tmp\\" + filename, PATH_ASSET + md5 + ext)
                sprite_obj = {"name": self.name, "md5": md5 + ".json", "input_type": "sprite", "tags": ["custom"],
                              "info": [0, 1, 1]}
                print(sprite_obj)
                with open(LIB_SPRITE, 'r', encoding="utf-8") as f:
                    text = f.read()
                    json_data = json.loads(text)
                    json_data.insert(0, sprite_obj)
                with open(LIB_SPRITE, 'w', encoding='utf-8') as f:
                    text_data = '[\n'
                    for j in json_data:
                        text_data += json.dumps(j)
                        text_data += ",\n"
                    text_data = text_data[:-2]
                    text_data += "\n]"
                    f.write(text_data)
            else:
                print("未知资源：", filename)

    def push(self):
        if file_suffix == ".wav":
            self.push_sound()
        elif file_suffix == ".jpg":
            self.push_back()
        elif file_suffix == ".png" or file_suffix == ".svg":
            self.push_costume()
        elif file_suffix == ".sprite2":
            self.push_sprite()
        else:
            print("无法识别对应格式的文件")


while True:
    path = input("\n\n拖入文件或文件夹:\n")
    if os.path.isdir(path):
        path += "\\"
        input_type = input("输入该文件夹的类型：0.自动 1.背景   2.造型  3.声音  4.角色\n")
        for lists in os.listdir(path):
            push = Push(lists)
            if input_type == "0":
                push.push()
            elif input_type == "1":
                push.push_back()
            elif input_type == "2":
                    push.push_costume()
            elif input_type == "3":
                    push.push_sound()
            elif input_type == "4":
                push.push_sprite()
            else:
                push.push()
    else:
        path.replace("\"", "")
        filename_full = os.path.split(path)[1]
        file_name, file_suffix = os.path.splitext(filename_full)
        push = Push(path, file_name)
        push.push()
