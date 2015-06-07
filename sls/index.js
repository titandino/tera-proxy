/************
 * includes *
 ************/
var fs = require('fs'),
    dns = require('dns'),
    http = require('http'),
    proxy = require('http-proxy'),
    hosts = require('./hosts');

/*************
 * constants *
 *************/
var HOST = 'sls.service.enmasse.com';
var PORT = 8080;

/********
 * main *
 ********/
var servers = fs.readFileSync(__dirname + '/servers.xml');

dns.resolve(HOST, function (err, addresses) {
  if (err) {
    console.error('[DNS] error');
    throw err;
  }

  hosts.set('127.0.0.1', HOST);
  console.log('modified hosts file');
  console.log();
  console.log("   **********************************");
  console.log("   * CTRL+C TO TERMINATE GRACEFULLY *");
  console.log("   * ------------------------------ *");
  console.log("   * You may be unable to log in if *");
  console.log("   * you do not use Ctrl+C to close *");
  console.log("   * this program when you're done. *");
  console.log("   **********************************");
  console.log();

  var ip = addresses[0];
  console.log('sls ip:', ip);

  var proxied = proxy.createProxyServer({target: 'http://' + ip + ':' + PORT});

  proxied.on('proxyReq', function (proxyReq, req, res, options) {
    proxyReq.setHeader('Host', HOST + ':' + PORT);

    if (req.url === '/servers/list.en') {
      //res.setHeader('Content-Length', req.headers['content-length'] + servers.length);
    }
  });

  http.createServer(function (req, res) {
    console.log('requested:', req.url);

    if (req.url[0] != '/') {
      console.warn('* denying\n');
      res.end();
      return;
    }

    if (req.url === '/servers/list.en') {
      var data = '',
          writeHead = res.writeHead,
          write = res.write,
          end = res.end;

      res.writeHead = function (code, headers) {
        res.removeHeader('Content-Length');
        if (headers) delete['content-length'];

        writeHead.apply(res, arguments);
      };

      res.write = function (chunk) {
        data += chunk;
      };

      res.end = function (chunk) {
        if (chunk) data += chunk;

        var index = data.indexOf('</serverlist>');
        if (index !== -1) {
          data = data.slice(0, index) + servers + data.slice(index);
          console.log('* injection success\n');
        } else {
          console.error('* failed to inject servers\n');
        }

        write.call(res, data, 'utf8');
        end.call(res);
      };
    }

    proxied.web(req, res, function (err) {
      console.warn('* error proxying request');
      console.warn(err);
      console.warn();
      res.end();
    });
  })
  .listen(PORT, '127.0.0.1');

  console.log('listening on', PORT, '\n');
});

/************
 * shutdown *
 ************/
if (process.platform === 'win32') {
  require('readline').createInterface({
    input: process.stdin,
    output: process.stdout
  }).on('SIGINT', function () {
    console.log();
    process.emit('SIGINT');
  });
}

process.on('SIGINT', function () {
  hosts.remove('127.0.0.1', HOST);
  console.log('reverted hosts file');
  process.exit();
});
