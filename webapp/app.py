# coding: utf-8

import cherrypy
import os
import ConfigParser
from os import listdir, getcwd
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

        template = (App.PROJECT_PATH if _type == 'project' else App.VIDEO_PATH) + App.FILE_TEMPLATE

        with open(template % (user, filename), 'w') as f:
            f.write(rawbody)
        return True
    
    def show(self, user):
        project_files = [f[len(user)+1:] for f in listdir(App.PROJECT_PATH) if f.startswith(user) and f.endswith('sb2')]
        return project_files

    @cherrypy.expose
    def load(self, **args):
        user = self.encode(args.get('user'))
        project_files = self.show(user)
        if len(project_files) > 0:
            filename = project_files[0]
            print filename

        try:
            return file(App.PROJECT_PATH + App.FILE_TEMPLATE % (user, filename))
        except:
            return file(App.PROJECT_PATH + "default.sb2")

    
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
        '/crossdomain.xml': {
            'tools.staticfile.on': True,
            'tools.staticfile.filename': getcwd() + '/crossdomain.xml'
        }
    }
    

    webapp = App()
    webapp.config = ConfigParser.ConfigParser()
    webapp.config.read('./app.cnf')
    cherrypy.quickstart(webapp, '/', conf)
