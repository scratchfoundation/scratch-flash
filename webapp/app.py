# coding: utf-8

import cherrypy
import os
import ConfigParser
import subprocess
import qrcode
import logging
from cherrypy.lib.static import serve_file
from StringIO import StringIO
from stat import S_ISREG, ST_MTIME, ST_MODE
from time import gmtime, strftime

# create logger
logger = logging.getLogger('cherrypy')
logger.setLevel(logging.DEBUG)

fh = logging.FileHandler("/tmp/app.log")
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
fh.setFormatter(formatter)
logger.addHandler(fh)

server_config = {
    'server.socket_host': '0.0.0.0',
    'server.socket_port': 4080,
    'response.timeout': 10*60
}
cherrypy.config.update(server_config)

def error_page_404(status, message, traceback, version):
    return "Oops! Looks like you're lost"
cherrypy.config.update({'error_page.404': error_page_404})

def jsonify_tool_callback(*args, **kwargs):
    response = cherrypy.response
    response.headers['Content-Type'] = 'application/json'
cherrypy.tools.jsonify = cherrypy.Tool('before_finalize', jsonify_tool_callback, priority=30)


class App(object):
    PROJECT_PATH = "projects/"
    VIDEO_PATH = "videos/"
    SHARE_PATH = "share/"
    FILE_TEMPLATE = "%s/%s"

    @cherrypy.expose
    def index(self, **args):
        return file('scratch/Scratch.html')

    @cherrypy.expose
    def ide(self, **args):
        uid = args.get('userid') if 'userid' in args else 'Guest'
        uname = args.get('username') if 'username' in args else 'Guest'
        content = "".join(file('scratch/Scratch.html').readlines())
        content = content.replace('__USER__', uid)
        return StringIO(unicode(content))

    @cherrypy.expose
    def save(self, **args):
        cl = cherrypy.request.headers['Content-Length']
        rawbody = cherrypy.request.body.read(int(cl))
        user = self.encode(args.get('user'))
        filename = self.encode(args.get('filename'))
        _type = args.get('type') if 'type' in args else 'project'
        # logger.debug("%s, %s, %s" % (user, filename, _type))

        template = (App.VIDEO_PATH if _type == 'video' else App.PROJECT_PATH) + App.FILE_TEMPLATE

        directory = template % (user, '')
        if not os.path.exists(directory):
            os.makedirs(directory)

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

        if _type == 'project':
            project = args.get('project')
            if not project: return self.error('project name is necessary')
            if (not project.endswith('.sb2')):
                project += '.sb2'
            project_file = App.PROJECT_PATH + App.FILE_TEMPLATE % (user, project)
            try:
                return file(project_file)
            except:
                if project == 'default.sb2':
                    return file(App.PROJECT_PATH + '/default.sb2')
                else:
                    return self.error('project %s is not exist, please try others' % (project_file))

        elif _type == 'video':
            video = args.get('video')
            if not video: return self.error('video name is necessary')
            video_file = App.VIDEO_PATH + App.FILE_TEMPLATE % (user, video)
            try:
                return file(video_file)
            except:
                return self.error('video %s is not exist, please try others' % (video_file))

        elif _type == 'listproject':
            pdir = App.PROJECT_PATH + App.FILE_TEMPLATE % (user, '')
            if not os.path.exists(pdir): return ''
            
            entries = (os.path.join(pdir, fn) for fn in os.listdir(pdir) if fn.endswith('sb2'))
            entries = ((os.stat(path), path) for path in entries)
            entries = ((stat[ST_MTIME], path) for stat, path in entries if S_ISREG(stat[ST_MODE]))

            plist = map(lambda (mdate, path): "|".join((os.path.basename(path)[:-len(".sb2")], strftime("%Y-%m-%d %H:%M:%S", gmtime(mdate)))), sorted(entries))
            plistStr = ','.join(plist)
            logger.debug(plistStr)
            return plistStr

        else:
            return self.error('correct type is necessary')

    def error(self, message):
        return self.message('ERROR', message)

    def message(self, code, message):
        return "[%s]: %s" % (code, message)
    
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
        '/js': {
            'tools.staticdir.on': True,
            'tools.staticdir.dir': 'js'
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
