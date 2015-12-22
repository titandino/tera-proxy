# tera-proxy

Easy script modding through modular network-based hooks.

## Usage

In most cases, you are probably looking for a convenient GUI for simplified
configuration of the mod system. This is currently in development.

If you are developer, server owner, or just want to run the proxy without the
overhead of a GUI, you're in the right place.

The `tera-proxy-sls` and `tera-proxy-game` modules under the `node_modules`
directory each have their own READMEs detailing usage and APIs for the SLS proxy
server and the game proxy server respectively.

An example server can be set up by running as administrator on Windows:

    coffee bin/proxy.coffee

This will load all modules in `bin/node_modules` as long as the module's
directory name does not begin with either `.` or `_`. If you installed via npm,
you should `cd bin && npm install` to install the dependencies for all of the
bundled modules.

Administrator is only required to modify the `hosts` file. See `tera-proxy-sls`
for more details. Note that in this case, all modules will be executed by the
same process and thus will also have administrator privileges. Keep this in mind
when you install modules from unknown sources.

On *nix machines, you probably can't run TERA anyway, so you're likely just
looking to run the proxy game server. See `tera-proxy-game` for more details,
and you can simply modify the provided `proxy.coffee` to not use the SLS proxy.

## Modules

This repository also contains a handful of useful modules under
`bin/node_modules` that may prove to be helpful in writing your own modules.
You can `require()` them and you can also use them as examples on how to write
modules. More in-depth API references are in the `tera-proxy-game` README.
