fs = require 'fs'
path = require 'path'
util = require 'util'

png = (require 'node-png').PNG
protocol = require '../../lib/protocol'



getColors = (data) ->
  data[i ... i + 3] for i in [0 ... data.length] by 3

convert = (data, fn) ->
  version = data.readInt32LE 4
  size = data.readInt32LE 8
  type = data.readInt32LE 12

  img = new png width: size, height: size

  switch type
    when 0, 1 # palette (max 256 colors)
      numColors = data.readInt32LE 16
      offset = 20 + numColors * 3
      colors = getColors data.slice 20, offset
      numPixels = data.readInt32LE offset
      pixels = data.slice offset + 4, offset + 4 + numPixels

      for pixel, i in pixels
        colors[pixel].copy img.data, i * 4
        img.data[i*4 + 3] = 0xFF

      # type 1 has extra section at end?

    when 2, 3 # grayscale
      numPixels = data.readInt32LE 16
      pixels = data.slice 20, 20 + numPixels

      for pixel, i in pixels
        img.data.fill pixel, i*4, i*4 + 3
        img.data[i*4 + 3] = 0xFF

      # type 3 has extra section at end?

    else
      console.error "unknown type #{type} for #{path.basename fn}"
      console.error data.toString 'hex'
      img = null
      return

  img.pack()
  .pipe fs.createWriteStream fn
  .on 'end', ->
    console.log "saved #{path.basename fn}"
  return



code = protocol.map.name.sImage
if !code?
  console.error "error: opcode for sImage is required"
  return

if process.argc < 3
  console.error "error: no log file specified"
  return

log = fs.readFileSync process.argv[2], encoding: 'utf8'
for line in log.split '\n'
  if match = line.match /^\*?\s*\d+ \| (<-|->) [0-9A-F]{4} \| ((?:[0-9A-F]{2}(?: |$)){4,})/
    data = new Buffer match[2].replace(/\s/g, ''), 'hex'
    if code is data.readUInt16LE 2
      {name, data} = protocol.parse code, data
      fn = path.join __dirname, 'img', name + '.png'
      if !fs.existsSync fn
        if 'TERA' is data[0..3].toString 'utf8'
          convert data, fn
        else
          console.error "unknown image format for #{path.basename fn}"
          console.error data.toString 'hex'
