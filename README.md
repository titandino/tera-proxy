# tera-proxy

Easy script modding through modular network-based hooks.

## Usage:

In most cases, you are probably looking for a convenient GUI for simplified configuration
of the mod system. This is currently in development.

If you are developer, server owner, or just want to run the proxy without the overhead of
a GUI, you're in the right place.

The `sls` and `game` directory each have their own READMEs detailing usage and APIs for
the SLS proxy server and the game proxy server respectively.

An example script using these can be run by executing as administrator on Windows:

    coffee bin/proxy.coffee

Administrator is only required to modify the `hosts` file. See `sls` for more details.

On *nix machines, you probably can't run TERA anyway, so you're likely just looking to
run the proxy game server. See `game` for more details, and you can simply modify the
provided `proxy.coffee` to not use the SLS proxy.
