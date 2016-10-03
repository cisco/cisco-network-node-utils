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
