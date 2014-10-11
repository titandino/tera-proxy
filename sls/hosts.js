// synchronous version of `hostile` with slight modifications
var fs = require('fs');

var WINDOWS = (process.platform === 'win32');
var EOL = WINDOWS ? '\r\n' : '\n';
var HOSTS = (WINDOWS ? 'C:/Windows/System32/drivers' : '') + '/etc/hosts';

exports.get = function () {
	var lines = [];
	fs.readFileSync(HOSTS, {encoding: 'utf8'})
	.replace(/\r?\n$/, '')
	.split(/\r?\n/)
	.forEach(function (line) {
		var matches = /^\s*?([^#]+?)\s+([^#]+?)$/.exec(line);
		if (matches && matches.length === 3) {
			// Found a hosts entry
			var ip = matches[1];
			var host = matches[2];
			lines.push([ip, host]);
		} else {
			// Found a comment, blank line, or something else
			lines.push(line);
		}
	});
	return lines;
};

exports.set = function (ip, host) {
	var lines = exports.get();

	// Try to update entry, if host already exists in file
	var didUpdate = false;
	lines = lines.map(function (line) {
		if (Array.isArray(line) && line[1] === host) {
			line[0] = ip;
			didUpdate = true;
		}
		return line;
	});

	// If entry did not exist, let's add it
	if (!didUpdate) {
		lines.push([ip, host]);
	}

	exports.writeFile(lines);
};

exports.remove = function (ip, host) {
	var lines = exports.get();

	// Try to remove entry, if it exists
	lines = lines.filter(function (line) {
		return !(Array.isArray(line) && line[0] === ip && line[1] === host);
	});

	exports.writeFile(lines);
};

exports.writeFile = function (lines) {
	var data = '';
	lines.forEach(function (line) {
		if (Array.isArray(line)) {
			line = line[0] + ' ' + line[1];
		}
		data += line + EOL;
	});

	var stat = fs.statSync(HOSTS);
	fs.writeFileSync(HOSTS, data, {mode: stat.mode});
};
