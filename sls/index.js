/************
 * includes *
 ************/
var fs = require('fs'),
	dns = require('native-dns'),
	http = require('http'),
	proxy = require('http-proxy'),
	hosts = require('./hosts');

/*************
 * constants *
 *************/
var HOST = 'sls.service.enmasse.com';
var PORT = 8080;

/***********
 * helpers *
 ***********/
var dnsResolve = function (host, callback) {
	var resolved = false;

	dns.Request({
		question: dns.Question({name: host}),
		server: {address: '8.8.8.8'}
	})
	.on('timeout', function () {
		console.error('[DNS] error: timeout');
		callback('DNS timeout');
	})
	.on('message', function (err, message) {
		if (resolved) return;

		if (err) {
			console.error('[DNS] error');
			console.error(err);
			callback(err);
			return;
		}

		var answer = message.answer[0]; // pick first one
		if (answer) {
			resolved = true;
			callback(null, answer.address);
		}
	})
	.on('end', function () {
		if (!resolved) {
			callback('failed to resolve');
			return;
		}
	})
	.send();
};

/********
 * main *
 ********/
dnsResolve(HOST, function (err, ip) {
	if (err) return;
	console.log('sls ip:', ip);

	hosts.set('127.0.0.1', HOST);
	console.log('modified hosts file');

	var proxied = proxy.createProxyServer({target: 'http://' + ip + ':' + PORT});

	http.createServer(function (req, res) {
		console.log('requested:', req.url);

		if (req.url[0] != '/') {
			console.warn('* denying\n');
			res.end();
			return;
		}

		if (req.url === '/servers/list.en') {
			var data = '',
				end = res.end;

			res.write = function (chunk) {
				data += chunk;
				return true;
			};

			res.end = function (chunk, encoding, callback) {
				if (chunk) data += chunk;

				var servers = fs.readFileSync(__dirname + '/servers.xml'); // TODO async

				var index = data.indexOf('</serverlist>');
				if (index !== -1) {
					data = data.slice(0, index) + servers + data.slice(index);
					console.log('* injection success\n');
				} else {
					console.error('* failed to inject servers\n');
				}

				return end.call(res, data, encoding, callback);
			};
		}

		proxied.web(req, res, function (err) {
			console.warn('* error proxying request\n');
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
        process.emit('SIGINT');
    });
}

process.on('SIGINT', function () {
	hosts.remove('127.0.0.1', HOST);
	console.log('reverted hosts file');
	process.exit();
});
