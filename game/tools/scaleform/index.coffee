fs = require 'fs'
util = require 'util'

pako = require 'pako'
formats = require './formats'
Stream = require './reader'

log = (o) -> console.log util.inspect o, colors: false, depth: null

read = (format, data) ->
  out = {}
  fmt = formats[format]

  r = new Stream.Reader data
  while !r.eof()
    id = r.readValue()
    type = fmt[id]
    if !type?
      console.error "unknown type id #{id} (0x#{id.toString 16}) in format '#{format}'"
      return out

    if type.format?
      res = read type.format, r.readSlice()
    else
      switch type.type
        when 'float'
          res = r.readFloat()
        when 'string'
          res = r.readString()
        when 'slice'
          res = r.readSlice()
        else
          if type.type?
            console.error "unknown type '#{type.type}' in definition for format '#{format}'"
          res = r.readValue()

    name = type.name ? '#' + id

    if type.many
      out[name] ?= []
      out[name].push res
    else
      out[name] = res

  out

write = (format, data) ->
  out = new Stream.Writer new Buffer 8192

  fmt = formats[format]
  keys = Object.keys fmt
  keys.sort (a, b) -> a - b
  for id in keys
    type = fmt[id]
    name = type.name ? '#' + id
    if !data[name]?
      console.error "missing field '#{name}' (id #{id}, 0x#{id.toString 16}) in format '#{format}'"
      continue

    items = data[name]
    if !Array.isArray items
      items = [items]
    for item in items
      out.writeValue +id

      if type.format?
        slice = write type.format, item
        out.writeSlice slice
      else
        switch type.type
          when 'float'
            out.writeFloat item
          when 'string'
            out.writeString item
          when 'slice'
            out.writeSlice item
          else
            if type.type?
              console.error "unknown type '#{type.type}' in definition for format '#{format}'"
            out.writeValue item

  out.end()

r = fs.readFileSync 'test.dat'

n = read 'ui-packet', r
log n

for item in n.data
  cn = "class-#{item.name}"
  if formats[cn]?
    res = new Buffer pako.inflate item.data
    n2 = read cn, res
    log n2, depth: null, colors: true
    test = write cn, n2
    log res
    log test
    if test.length isnt res.length
      return console.error '!'
    for c, i in res
      if test[i] isnt c
        return console.error '!!', i
