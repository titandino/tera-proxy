# requires
fs = require 'fs'
path = require 'path'

SlsProxy = require 'tera-proxy-sls'
GameProxy = require 'tera-proxy-game'

# globals
proxy = null
server = null

# set up exit handling
if process.platform is 'win32'
  require 'readline'
    .createInterface
      input: process.stdin,
      output: process.stdout
    .on 'SIGINT', ->
      process.emit 'SIGINT'

cleanExit = ->
  console.log 'terminating...'
  proxy?.close()
  server?.close()
  process.stdin.end() if process.platform is 'win32'
  setTimeout (-> process.exit()), 5000
    .unref()
  return

process.on 'SIGHUP', cleanExit
process.on 'SIGINT', cleanExit
process.on 'SIGTERM', cleanExit

# main
modules = do ->
  modulesPath = path.join __dirname, 'node_modules'
  name for name in fs.readdirSync modulesPath when name[0] not in ['.', '_']

proxy = new SlsProxy customServers:
  4009:
    name: 'Celestial Chills'
    port: 9247

# remove entry from hosts file in case of bad shutdown
# also catch errors with modifying hosts file
try
  proxy.close()
catch e
  switch e.code
    when 'EACCES'
      console.error """

        *********************************
        *                               *
        *  FAILED TO WRITE HOSTS FILE!  *
        *  ---------------------------  *
        *     FILE SET TO READ-ONLY     *
        *                               *
        *********************************

        Your hosts file seems to be set to read-only.
        Find this file and make sure it's writable:
        (Right-click, Properties, uncheck Read-only)

            #{e.path}

        """
    when 'EPERM'
      console.error """

        *********************************
        *                               *
        *  FAILED TO WRITE HOSTS FILE!  *
        *  ---------------------------  *
        *     RUN AS ADMINISTRATOR!     *
        *                               *
        *********************************

        You don't have sufficient privileges to create or modify the hosts file.
        Please try again by right-clicking and selecting "Run as administrator".

        """
    else
      throw e
  proxy = null
  cleanExit()

proxy?.fetch (err, servers) ->
  if err? then throw err

  target = servers[4009]
  if !target?
    throw new Error 'server 4009 not found'

  server = GameProxy.createServer { host: target.ip, port: target.port },
    (dispatch) -> dispatch.load name, module for name in modules

  proxy.listen '127.0.0.1', ->
    console.log "[sls] server list overridden"

    server.listen 9247, '127.0.0.1', ->
      address = server.address()
      console.log "[game] listening on #{address.address}:#{address.port}"
