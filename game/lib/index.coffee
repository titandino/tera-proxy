net = require 'net'

Dispatch = require './dispatch'
Connection = require './connection'

class proxyServer
  constructor: ->
    @server = net.createServer (socket) ->
      dispatch = new Dispatch
      dispatch.load 'core'
      #dispatch.load 'responsive'
      #dispatch.load 'tp'
      #dispatch.load 'dmgspy'
      dispatch.load 'outfitlogger'
      dispatch.load 'arborean-apparel'
      dispatch.load 'inventory'
      dispatch.load 'logger'

      proxy = new Connection socket, dispatch
      proxy.connect
        host: '208.67.49.68',
        port: 10001

      dispatch.connection = proxy

    @server.on 'listening', =>
      address = @server.address()
      console.log "[server] listening on #{address.address}:#{address.port}"

    @server.listen 9247

new proxyServer
