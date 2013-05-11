fs = require 'fs',
PATH = require 'path'

class Router
    constructor: (@app, path) ->
        
        @path = PATH.resolve process.cwd(), path
        fs.stat path, (err, stat) =>
            throw err if err
            throw new Error "path '#{path}' doesn't exist or isn't a directory" if not stat.isDirectory()
    setParser: () ->
        @app.all '/*', (req, resp, next)->
                req.pass = req.params[0].split '/'
                next()
        
        @crawl @path
    crawl: (dir, path='') ->
        fs.readdir dir, (err,files) =>
            throw Error "No se pudo leer #{dir}: #{err}" if err
            for file in [ "#{dir}/_.js", "#{dir}/_.coffee" ]
                if fs.existsSync file
                    routes=["#{path}/*"]
                    routes.push path if path isnt ''
                    @app.all routes, require file
            
            for file in files
                if file not in ["_.js","_.coffee"] and not (path is '' and file in ["index.coffee","index.js"])                    
                    (=>
                        _file=file
                        fs.stat PATH.join(dir, file), (err, stat) =>
                            throw err if err
                            if stat.isFile() then @getRoute dir, _file, path else @crawl PATH.join(dir, _file), "#{path}/#{_file}"
                    )()
                
    getRoute: (dir, file, path) ->
        filename=false
        
        if (file.substr file.length-3, file.length) is '.js'
            filename = file.substr(0,file.length-3)
        else if (file.substr file.length-7, file.length) is '.coffee'
            filename = file.substr(0,file.length-7)
        
        if filename
            tmp = require PATH.join dir, file
            
            types={}
            
            if typeof tmp is 'function'
                types.all=tmp
            else if tmp.get? or tmp.post? or tmp.all?
                types=tmp
            
            bounds=[]
            
            if filename is 'index'
                if path is '/index'
                    bounds.push '/'
                else
                    bounds.push path
            else
                bounds.push "#{path}/#{filename}"
                bounds.push "#{path}/#{filename}/*"
            
            @setRoute type, bounds, code for type, code of types
            
    setRoute: (type, routes, callback) ->
        if typeof callback is 'function' and routes.length > 0
            console.log "bound type '#{type}' to #{routes}"    
            @app[type](routes,callback)

module.exports = (app, path) ->
    router = new Router app, path
    router.setParser()
