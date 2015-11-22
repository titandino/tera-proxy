fs = require 'fs'
net = require 'net'
path = require 'path'

Dispatch = require './dispatch'
Connection = require './connection'

class proxyServer
  constructor: ->
    @server = net.createServer (socket) ->
      dispatch = new Dispatch

      conf = process.argv[2..].join ' '
      if conf isnt ''
        ; # todo
      else
        modulesPath = path.join __dirname, '../node_modules'
        for module in fs.readdirSync modulesPath when module[0] not in ['.', '_']
          dispatch.load module

      proxy = new Connection socket, dispatch
      proxy.connect
        host: '208.67.49.68',
        port: 10001

      dispatch.connection = proxy

    @server.on 'listening', =>
      address = @server.address()
      console.log "[server] listening on #{address.address}:#{address.port}"

    @server.listen 9247, '127.0.0.1'

new proxyServer
