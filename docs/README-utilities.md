# Executable utilities included in this gem

## check_metric_limits.rb

This is a helper script for developers. If you're doing refactoring work to
reduce the code complexity metrics, you can run this script to report the
worst offenders for each metric and whether you've managed to improve any
metrics compared to the baseline.  Run this script from the base
cisco-network-node-utils directory to report metrics of code in the
./lib and ./tests directories.

```bash
[cisco-network-node-utils]$ ruby bin/check_metric_limits.rb
```

## show_running_yang

This is a utility to output the current state of an XR configuration. In order
to run, this utility needs access to one or more *.yang files (found in the
/pkg/yang directory on the XR box, as well as from other sources). Usually, this
would be run from the bash-shell on the XR device, but can be run remotely if
applicable .yang files are available. Connection information (host, username, etc.)
is read from the standard [configuration file](../README.md#configuration).

*Note: this utility is not currently supported for nexus devices.*

```bash
Usage: show_running_yang [options] [file_or_directory_path]
    -m, --manifest                   Output config as a Puppet manifest
    -o, --oper                       Retrieve operational data instead of configuration (warning: possibly returns a lot of data; use at own risk)
    -e, --environment node           The node in cisco_node_utils.yaml from which to retrieve data
    -d, --debug                      Enable debug-level logging
    -v, --verbose                    Enable verbose messages
    -h, --help                       Print this help
    
[xrv9k:~]$ show_running_yang
[xrv9k:~]$ show_running_yang /pkg/yang/Cisco-IOS-XR-ipv4-bgp-cfg.yang
```
