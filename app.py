import cherrypy
import os
import ConfigParser
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

    @cherrypy.expose
    def index(self, **args):
        return file('./readme.md')

if __name__ == '__main__':
    conf = {
        '/': {
            'tools.sessions.on': True,
            'tools.staticdir.root': os.path.abspath(os.getcwd())
        },
        '/internalapi': {
            'tools.staticdir.on': True,
            'tools.staticdir.dir': 'internalapi'
        },
        '/js': {
            'tools.staticdir.on': True,
            'tools.staticdir.dir': 'js'
        },
        '/css': {
            'tools.staticdir.on': True,
            'tools.staticdir.dir': 'css'
        },
        '/debug': {
            'tools.staticdir.on': True,
            'tools.staticdir.dir': 'bin-debug'
        },
        '/release': {
            'tools.staticdir.on': True,
            'tools.staticdir.dir': 'bin-release'
        },
        '/crossdomain.xml': {
            'tools.staticfile.on': True,
            'tools.staticfile.filename': '/Users/zezhen/workspace/scratch-flash/crossdomain.xml'
        }
    }
    

    webapp = App()
    webapp.config = ConfigParser.ConfigParser()
    webapp.config.read('./app.cnf')
    cherrypy.quickstart(webapp, '/', conf)
