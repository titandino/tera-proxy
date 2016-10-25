let why;
try {
  why = require('why-is-node-running');
} catch (_) {}

// requires
const fs = require('fs');
const path = require('path');

const hosts = require('./hosts');

const SlsProxy = require('tera-proxy-sls');
const GameProxy = require('tera-proxy-game');

// check if hosts is writable
try {
  hosts.remove('127.0.0.1', 'sls.service.enmasse.com');
} catch (e) {
  switch (e.code) {
    case 'EACCES': {
      console.error(`
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

    ${e.path}
`);
      break;
    }

    case 'EPERM': {
      console.error(`
*********************************
*                               *
*  FAILED TO WRITE HOSTS FILE!  *
*  ---------------------------  *
*     RUN AS ADMINISTRATOR!     *
*                               *
*********************************

You don't have sufficient privileges to create or modify the hosts file.
Please try again by right-clicking and selecting "Run as administrator".
`);
      break;
    }

    default: {
      throw e;
    }
  }

  process.exit(1);
}

/********
 * main *
 ********/
const customServers = require('./servers.json');
const proxy = new SlsProxy({ customServers });

// load modules
const modules = (
  fs.readdirSync(path.join(__dirname, 'node_modules'))
    .filter(name => name[0] !== '.' && name[0] !== '_')
);

// cache
console.log('[proxy] preloading modules');
for (let name of modules) {
  try {
    require(name);
  } catch (e) {
    console.warn();
    console.warn(`[proxy] failed to load "${name}"`);
    console.warn(e.stack);
    console.warn();
  }
}

// fetch official server list
proxy.fetch((err, gameServers) => {
  if (err) throw err;

  // set up proxy servers
  const servers = new Map();

  for (let id in customServers) {
    const target = gameServers[id];
    if (!target) {
      console.error(`server ${id} not found`);
      continue;
    }

    const server = GameProxy.createServer({ host: target.ip, port: target.port }, (dispatch) => {
      for (let name of modules) dispatch.load(name, module);
    });

    servers.set(id, server);
  }

  // run sls proxy
  proxy.listen('127.0.0.1', () => {
    hosts.set('127.0.0.1', 'sls.service.enmasse.com');
    console.log('[sls] server list overridden');

    // run game proxies
    for (let [id, server] of servers) {
      server.listen(customServers[id].port, '127.0.0.1', () => {
        const address = server.address();
        console.log(`[game] listening on ${address.address}:${address.port}`);
      });
    }
  });

  // set up exit handling
  if (process.platform === 'win32') {
    require('readline')
      .createInterface({ input: process.stdin, output: process.stdout })
      .on('SIGINT', () => {
        process.emit('SIGINT');
      });
  }

  function cleanExit() {
    console.log('terminating...');

    try {
      hosts.remove('127.0.0.1', 'sls.service.enmasse.com');
    } catch (_) {}

    proxy.close();
    servers.forEach(server => server.close());

    if (process.platform === 'win32') {
      process.stdin.end();
    }

    setTimeout(() => {
      why && why();
      process.exit();
    }, 5000).unref();
  };

  process.on('SIGHUP', cleanExit);
  process.on('SIGINT', cleanExit);
  process.on('SIGTERM', cleanExit);
});
