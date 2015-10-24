net = require 'net'

Dispatch = require './dispatch'
Connection = require './connection'

class proxyServer
  constructor: ->
    @server = net.createServer (socket) ->
      dispatch = new Dispatch
      dispatch.load 'logger'

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
