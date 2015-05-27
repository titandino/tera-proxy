net = require 'net'

Encryption = require './encryption'
PacketBuffer = require './packetBuffer'

module.exports = class Connection
  constructor: (@socket, @dispatch) ->
    @state = -1
    @session1 = new Encryption
    @session2 = new Encryption
    @clientBuffer = new PacketBuffer
    @serverBuffer = new PacketBuffer

    @socket.setNoDelay true

    @socket.on 'data', (data) =>
      switch @state
        when 0
          if data.length is 128
            data.copy @session1.clientKeys[0]
            data.copy @session2.clientKeys[0]
            @client.write data

        when 1
          if data.length is 128
            data.copy @session1.clientKeys[1]
            data.copy @session2.clientKeys[1]
            @client.write data

        when 2
          @session1.decrypt data
          @clientBuffer.write data

          while data = @clientBuffer.read()
            opcode = data.readUInt16LE 2
            data = @dispatch.handle opcode, data, false
            if data
              @session2.decrypt data
              @client.write data

          return

    @socket.on 'close', => @client.end()
    @socket.on 'error', => @client.end()

  connect: (opt) ->
    @client = net.connect opt
    @client.setNoDelay true
    @client.on "connect", =>
      @remote = @socket.remoteAddress + ':' + @socket.remotePort
      console.log "[connection] routing #{@remote} to #{@client.remoteAddress}:#{@client.remotePort}"
      @state = -1

    @client.on 'data', (data) =>
      switch @state
        when -1
          if data.readUInt32LE(0) is 1
            @state = 0
            @socket.write data

        when 0
          if data.length is 128
            data.copy @session1.serverKeys[0]
            data.copy @session2.serverKeys[0]
            @state = 1
            @socket.write data

        when 1
          if data.length is 128
            data.copy @session1.serverKeys[1]
            data.copy @session2.serverKeys[1]
            @session1.init()
            @session2.init()
            @state = 2
            @socket.write data

        when 2
          @session2.encrypt data
          @serverBuffer.write data

          while data = @serverBuffer.read()
            opcode = data.readUInt16LE 2
            data = @dispatch.handle opcode, data, true
            if data
              @session1.encrypt data
              @socket.write data

      return

    @client.on "close", =>
      console.log "[connection] #{@remote} disconnected"
      @dispatch.close()

    @client.on "error", (err) ->
      console.warn err

  sendClient: (data) ->
    @session1.encrypt data if @state is 2
    @socket.write data

  sendServer: (data) ->
    @session2.decrypt data if @state is 2
    @client.write data
