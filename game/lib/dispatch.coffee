protocol = require './protocol'

module.exports = class Dispatch
  constructor: ->
    @connection = null
    @modules = {}
    @hooks =
      raw: {}
      pre: {}

  close: ->
    for name, module of @modules
      module.destructor?()
    @modules = {}
    @hooks = { raw: {}, pre: {} }
    return

  load: (name, reload = false) ->
    try
      if reload
        delete require.cache[require.resolve name]

      module = require name
      @modules[name] = new module this

      console.log "[dispatch] loaded " + name
      true
    catch e
      console.error "[dispatch] load: error initializing module '#{name}'"
      console.error e
      false

  unload: (name) ->
    module = @modules[name]
    if !module?
      console.warn "[dispatch] unload: cannot unload non-loaded module '#{name}'"
      return false

    module.destructor?()
    delete @modules[name]
    true

  hook: (name, type, cb) ->
    if !cb?
      cb = type
      type = 'pre'

    if name is '*'
      type = 'raw'
      code = name
    else
      code = protocol.map.name[name]

    hooks = @hooks[type]
    if !hooks?
      console.warn "[dispatch] hook: unexpected hook type '#{type}'"
      hooks = @hooks.pre

    hooks[code] ?= []
    hooks[code].push cb

  unhook: (name, type, cb) ->
    if !cb?
      cb = type
      type = 'pre'

    if name is '*'
      type = 'raw'
      code = name
    else
      code = protocol.map.name[name]

    hooks = @hooks[type]
    if !hooks?
      console.warn "[dispatch] hook: unexpected hook type '#{type}'"
      hooks = @hooks.pre

    index = hooks[code].indexOf cb
    if index is -1
      console.error "[dispatch] unhook: could not find cb"
      return

    hooks[code].splice index, 1

  toClient: (name, data) ->
    if name.constructor is Buffer
      data = name
    else
      try
        data = protocol.write name, data
      catch e
        console.error "[dispatch] failed to generate message:", name
        console.error e
        console.error data
        return false

    @connection?.sendClient data

  toServer: (name, data) ->
    if name.constructor is Buffer
      data = name
    else
      try
        data = protocol.write name, data
      catch e
        console.error "[dispatch] failed to generate message:", name
        console.error e
        console.error data
        return false

    @connection?.sendServer data

  handle: (code, data, fromServer) ->
    hooks = @hooks.raw['*']
    if hooks?
      for cb in hooks
        result = cb code, data, fromServer
        if result?.constructor is Buffer
          data = result
        else if result is false
          return false

    hooks = @hooks.raw[code]
    if hooks?
      for cb in hooks
        result = cb code, data, fromServer
        if result?.constructor is Buffer
          data = result
        else if result is false
          return false

    hooks = @hooks.pre[code]
    if hooks?
      event = protocol.parse code, data
      changed = false

      for cb in hooks
        result = cb event
        if result is true
          changed = true
        else if result is false
          return false

      if changed
        data = protocol.write code, event

    data
