# coding: utf-8

import cherrypy
import os
import ConfigParser
import subprocess
import qrcode
import logging
from cherrypy.lib.static import serve_file

# create logger
logger = logging.getLogger('cherrypy')
logger.setLevel(logging.INFO)

fh = logging.FileHandler("/tmp/app.log")
fh.setLevel(logging.INFO)
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
fh.setFormatter(formatter)
logger.addHandler(fh)

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
        logger.debug("%s, %s, %s" % (user, filename, _type))

        template = (App.VIDEO_PATH if _type == 'video' else App.PROJECT_PATH) + App.FILE_TEMPLATE

        _file = template % (user, filename)
        with open(_file, 'w') as f:
            f.write(rawbody)

        if _type == 'video':
            ofilename = App.FILE_TEMPLATE % (user, filename[:-4]+".mp4")
            outfile = App.SHARE_PATH + ofilename
            flag = self.convert_video(_file, outfile)
            if flag:
                # Todo try to qrcode html code directly?
                # <video id = "video_id" width="100%" height="100%" controls="true" src="VIDEO_LINK" type="video/mp4"></video>
                self.generate_qrcode('http://www.scratchonline.cn:4080/share?video=' + ofilename, outfile[:-4]+'.png')
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

    @cherrypy.expose
    def share(self, **args):
        video = args.get('video')
        if video:
            return serve_file(os.getcwd() + '/share/'+video)

    def convert_video(self, infile, outfile, to_format='mp4'):
        command = "ffmpeg -i %s -f %s -vcodec libx264 -vf format=yuv420p -acodec libmp3lame %s;" % (infile, to_format, outfile)
        subprocess.call(command, shell=True)
        return os.path.isfile(outfile)

    def list_files(self, user, _type):
        type_dir = App.VIDEO_PATH if _type == 'video' else App.PROJECT_PATH
        logger.info(type_dir)
        return [f[len(user)+1:] for f in os.listdir(type_dir) if f.startswith(user)]

    @cherrypy.expose
    def load(self, **args):
        user = self.encode(args.get('user'))
        _type = args.get('type')
        logger.debug("%s %s" % (user, _type))

        project_files = self.list_files(user, _type)
        logger.debug(",".join(project_files))

        if len(project_files) > 0:
            filename = project_files[0]
            logger.info(filename)

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
    working_directory = os.getcwd()    
    conf = {
        '/': {
            'tools.sessions.on': True,
            'tools.staticdir.root': os.path.abspath(working_directory)
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
            'tools.staticfile.filename': working_directory + '/scratch/share.html'
        },
        '/crossdomain.xml': {
            'tools.staticfile.on': True,
            'tools.staticfile.filename': working_directory + '/crossdomain.xml'
        }
    }
    

    webapp = App()
    webapp.config = ConfigParser.ConfigParser()
    webapp.config.read('./app.cnf')
    try:
        import daemon
        with daemon.DaemonContext(files_preserve = [fh.stream],working_directory=working_directory):
            cherrypy.quickstart(webapp, '/', conf)
    except:
        cherrypy.quickstart(webapp, '/', conf)
