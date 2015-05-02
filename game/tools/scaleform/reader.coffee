module.exports =
  Reader: class Reader
    constructor: (@buffer, @pos = 0) ->

    eof: -> @buffer.length <= @pos

    readByte: -> @buffer[@pos++]

    readValue: ->
      out = 0
      shift = 0
      loop # no do..while in coffeescript why
        value = @readByte()
        out |= (value & 0x7F) << (7 * shift++)
        break unless value & 0x80
      out

    readFloat: ->
      out = @buffer.readFloatLE @pos
      @pos += 4
      out

    readString: (length = @readValue()) ->
      out = ''
      for i in [0...length] by 2
        c = @readByte() | (@readByte() << 8)
        out += String.fromCharCode c
      out

    readSlice: (length = @readValue()) ->
      @buffer.slice @pos, @pos += length

  Writer: class Writer
    constructor: (@buffer, @pos = 0) ->

    writeByte: (n) -> @buffer[@pos++] = n

    writeValue: (n) ->
      loop
        value = n & 0x7F
        more = value isnt +n
        value |= +more << 7
        @writeByte value
        break unless more
        n >>= 7
      return

    writeFloat: (n) ->
      @buffer.writeFloatLE n, @pos
      @pos += 4

    writeString: (str) ->
      len = str.length
      @writeValue len * 2
      for i in [0...len] by 1
        c = str.charCodeAt i
        @writeByte c & 0xFF
        @writeByte (c >> 16) & 0xFF
      return

    writeSlice: (slice) ->
      length = slice.length
      @writeValue length
      slice.copy @buffer, @pos
      @pos += length

    end: ->
      out = new Buffer @pos
      @buffer.copy out
      #@buffer = null # is this necessary?
      out
