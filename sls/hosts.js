// windows-only, synchronous version of `hostile` with slight modifications
var fs = require('fs');
var path = require('path');

var HOSTS = path.join(
	process.env.SystemRoot || path.join(process.env.SystemDrive || 'C:', 'Windows'),
	'/System32/drivers/etc/hosts'
);

exports.get = function () {
	var lines = [];
	try {
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
	} catch (e) {
		// ENOENT: File doesn't exist (equivalent to empty file)
		// Otherwise, throw
		if (e.code !== 'ENOENT') {
			throw e;
		}
	}
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
		data += line + '\r\n';
	});

	// Get mode (or set to rw-rw-rw-); check read-only
	var mode;
	try {
		mode = fs.statSync(HOSTS).mode;
		if (!(mode & 128)) { // 0200 (owner, write)
			console.error();
			console.error('*********************************');
			console.error('*                               *');
			console.error('*  FAILED TO WRITE HOSTS FILE!  *');
			console.error('*  ---------------------------  *');
			console.error('*     FILE SET TO READ-ONLY     *');
			console.error('*                               *');
			console.error('*********************************');
			console.error();
			console.error("Your hosts file seems to be set to read-only.");
			console.error("Find this file and make sure it's writable:");
			console.error("(Right-click, Properties, uncheck Read-only)");
			console.error();
			console.error('    ' + HOSTS);
			console.error();
			process.exit(1);
		}
	} catch (e) {
		if (e.code === 'ENOENT') {
			mode = 33206; // 0100666 (regular file, rw-rw-rw-)
		} else {
			throw e;
		}
	}

	// Write file
	try {
		fs.writeFileSync(HOSTS, data, {mode: mode});
	} catch (e) {
		if (e.code === 'EPERM') {
			console.error();
			console.error('*********************************');
			console.error('*                               *');
			console.error('*  FAILED TO WRITE HOSTS FILE!  *');
			console.error('*  ---------------------------  *');
			console.error('*     RUN AS ADMINISTRATOR!     *');
			console.error('*                               *');
			console.error('*********************************');
			console.error();
			console.error("You don't have sufficient privileges to create or modify the hosts file.");
			console.error("Please try again by right-clicking and selecting \"Run as administrator\".");
			console.error();
			process.exit(1);
		} else {
			throw e;
		}
	}
};
