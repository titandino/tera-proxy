fs = require 'fs'
path = require 'path'

hints = require './hints'
data = {}

try data = require '../data/data.json'

checkTypes = (constraints, values) ->
  for field, type of constraints
    value = values[field]

    if Array.isArray value
      for v in value
        if !checkTypes type, v
          return false
      continue

    all = type.all ? []
    any = type.any ? []
    none = type.none ? []
    if typeof type is 'string'
      all = [type]

    match = false

    if any.length > 0
      for type in any when !match
        match = hints.field.type[type] value
    else
      match = true

    for type in all when match
      match = hints.field.type[type] value

    for type in none when match
      match = !hints.field.type[type] value

    if !match
      return false

  true

saveEnums = (enums, values) ->
  for field, type of enums
    value = values[field]
    if Array.isArray value
      saveEnums type, v for v in value
      continue

    data[type] ?= {}
    data[type][value] = 1

  return

checkEnums = (enums, values) ->
  for field, type of enums
    value = values[field]

    if Array.isArray value
      for v in value
        if !checkEnums type, v
          return false
      continue

    if !data[type]?[value]?
      return false

  true

checkArrays = (arrays, values) ->
  arrays = [arrays] if !Array.isArray arrays
  for field in arrays
    if !Array.isArray values[field]
      return false

    if values[field].length is 0
      return false

  true

self = module.exports =
  feed: (name, values) ->
    # check constraints
    if hints.field.message[name]?
      if !checkTypes hints.field.message[name], values
        console.warn "#{name} - failed to adhere to type constraints"
        console.warn "values:"
        console.warn values

    if hints.custom[name]?
      if !hints.custom[name] values
        console.warn "#{name} - failed to validate on custom filter"
        console.warn "values:"
        console.warn values

    # save enumerations
    if hints.enumerable[name]?
      saveEnums hints.enumerable[name], values

    return

  save: ->
    file = path.join __dirname, '../data/data.json'
    fs.writeFileSync file, JSON.stringify data

  check: (structure, data, lookahead, name) ->
    counts = {}
    offsets = {}
    values = {}

    try
      for [key, type] in structure
        switch type
          when 'count'
            counts[key] = data.uint16()
          when 'offset'
            offsets[key] = data.uint16()
          when 'byte'
            values[key] = data.byte()
            if !values[key]?
              return false
          when 'int16', 'uint16', 'int32', 'uint32', 'int64', 'uint64', 'float'
            values[key] = data[type]()
          when 'bytes'
            count = counts[key]
            if !count?
              return false
            values[key] = data.bytes count
          when 'string'
            offset = offsets[key]
            if offset? and data.position isnt offset
              return false
            values[key] = ''
            while c = data.uint16()
              values[key] += String.fromCharCode c
              data.buffer[data.position - 2] = 255
              data.buffer[data.position - 1] = 255
          else
            if typeof type is 'object'
              count = counts[key]
              offset = offsets[key]

              # sanity check
              if !count? or !offset?
                return false

              # start
              values[key] = []
              while count > 0
                # check here
                here = data.uint16()
                if here isnt offset
                  return false

                # save next
                count--
                next = data.uint16()
                if next > 0 and next < offset
                  return false

                # check
                res = self.check type, data
                if res is false
                  return false

                # save
                values[key].push res

                # go to next
                offset = next

              # check count
              if count isnt 0 or offset isnt 0
                return false
    catch e
      return false

    if !name?
      values
    else
      if data.position isnt data.buffer.length
        return false # failed structure validation: bad length

      if !self.checkHeuristic name, values, lookahead
        return false # failed heuristics validation

      true

  checkHeuristic: (name, values, lookahead) ->
    if hints.field.message[name]?
      if !checkTypes hints.field.message[name], values
        return false

    if hints.enumerable[name]?
      if !checkEnums hints.enumerable[name], values
        return false

    if hints.array[name]?
      if !checkArrays hints.array[name], values
        return false

    if hints.custom[name]?
      if !hints.custom[name] values
        return false

    if hints.precedes[name]?
      if hints.precedes[name] not in lookahead
        return false

    true
