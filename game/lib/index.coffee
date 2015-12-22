fs = require 'fs'
net = require 'net'
path = require 'path'

Dispatch = require './dispatch'
Connection = require './connection'

createServer = (connectOpts, cb) ->
  net.createServer (socket) ->
    dispatch = new Dispatch

    proxy = new Connection socket, dispatch
    proxy.connect connectOpts

    dispatch.connection = proxy
    cb dispatch

module.exports = { createServer }
