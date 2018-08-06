# coding: utf-8

import cherrypy
import os
import ConfigParser
import subprocess
import qrcode
import socket

# import os, tempfile, sys, socket, re
# import importlib
# from StringIO import StringIO

# sys.path.append("./modules")
# import util, bconfig, brick

# server_config = {
#     'server.socket_host': '0.0.0.0',
#     'server.socket_port': 4443,
#     'server.ssl_module': 'pyopenssl',
#     'server.ssl_certificate':'/home/y/conf/sslcerts/server.crt',
#     'server.ssl_private_key':'/home/y/conf/sslcerts/server.key',
#     'server.ssl_certificate_chain':'/home/y/conf/sslcerts/server.intermediate.crt',
#     'response.timeout': 10*60
# }

server_config = {
    'server.socket_host': '0.0.0.0',
    'server.socket_port': 4080,
    'response.timeout': 10*60
}

cherrypy.config.update(server_config)

def jsonify_tool_callback(*args, **kwargs):
    response = cherrypy.response
    response.headers['Content-Type'] = 'application/json'
cherrypy.tools.jsonify = cherrypy.Tool('before_finalize', jsonify_tool_callback, priority=30)

class App(object):
    PROJECT_PATH = "projects/"
    VIDEO_PATH = "videos/"
    SHARE_PATH = "share/"
    FILE_TEMPLATE = "%s_%s"

    @cherrypy.expose
    def index(self, **args):
        return file('scratch/Scratch.html')

    @cherrypy.expose
    def save(self, **args):
        cl = cherrypy.request.headers['Content-Length']
        rawbody = cherrypy.request.body.read(int(cl))
        user = self.encode(args.get('user'))
        filename = self.encode(args.get('filename'))
        _type = args.get('type') if 'type' in args else 'project'
        print user, filename, _type

        template = (App.VIDEO_PATH if _type == 'video' else App.PROJECT_PATH) + App.FILE_TEMPLATE

        _file = template % (user, filename)
        with open(_file, 'w') as f:
            f.write(rawbody)

        if _type == 'video':
            ofilename = App.FILE_TEMPLATE % (user, filename[:-4]+".mp4")
            outfile = App.SHARE_PATH + ofilename
            flag = self.convert_video(_file, outfile)
            if flag:
                self.generate_qrcode('http://www.scratchonline.cn:4080/share.html?video=' + ofilename, outfile[:-4]+'.png')
                return file(outfile[:-4]+'.png')

        return True

    def generate_qrcode(self, url, img_name):
        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_L,
            box_size=10,
            border=4,
        )
        qr.add_data(url)
        qr.make(fit=True)
        img = qr.make_image()
        img.save(img_name)


    def convert_video(self, infile, outfile, to_format='mp4'):
        command = "ffmpeg -i %s -f %s -vcodec libx264 -acodec libmp3lame %s; rm %s" % (infile, to_format, outfile, infile)
        subprocess.call(command, shell=True)
        return os.path.isfile(outfile)

    def list_files(self, user, _type):
        type_dir = App.VIDEO_PATH if _type == 'video' else App.PROJECT_PATH
        print type_dir
        return [f[len(user)+1:] for f in os.listdir(type_dir) if f.startswith(user)]

    @cherrypy.expose
    def load(self, **args):
        user = self.encode(args.get('user'))
        _type = args.get('type')
        print user, _type

        project_files = self.list_files(user, _type)
        print project_files

        if len(project_files) > 0:
            filename = project_files[0]
            print filename

        template = (App.VIDEO_PATH if _type == 'video' else App.PROJECT_PATH) + App.FILE_TEMPLATE
        try:
            return file(template % (user, filename))
        except:
            if _type == 'project': return file(App.PROJECT_PATH + "default.sb2")

    
    def encode(self, _str, charset='uft-8'):
        try:
            return "{}".format(_str.encode('utf-8'))
        except:
            return _str


if __name__ == '__main__':
    conf = {
        '/': {
            'tools.sessions.on': True,
            'tools.staticdir.root': os.path.abspath(os.getcwd())
        },
        '/assets': {
            'tools.staticdir.on': True,
            'tools.staticdir.dir': 'assets'
        },
        '/scratch': {
            'tools.staticdir.on': True,
            'tools.staticdir.dir': 'scratch'
        },
        '/share': {
            'tools.staticdir.on': True,
            'tools.staticdir.dir': 'share'
        },
        '/share.html': {
            'tools.staticfile.on': True,
            'tools.staticfile.filename': os.getcwd() + '/scratch/share.html'
        },
        '/crossdomain.xml': {
            'tools.staticfile.on': True,
            'tools.staticfile.filename': os.getcwd() + '/crossdomain.xml'
        }
    }
    

    webapp = App()
    webapp.config = ConfigParser.ConfigParser()
    webapp.config.read('./app.cnf')
    cherrypy.quickstart(webapp, '/', conf)
