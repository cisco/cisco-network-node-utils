# Executing the tests provided for this gem

## RSpec tests

The test files located in the `spec/` directory use [RSpec](http://rspec.info/) as their test framework. These tests are generally standalone and do not generally require any actual Cisco hardware or virtual machines to test against.

### Running a single RSpec test

You can execute a single spec file by name:

```bash
rspec spec/environment_spec.rb
```

### Running all RSpec tests


```bash
rake spec
```

## Minitest tests

The test files located in the `tests/` directory use [minitest](https://github.com/seattlerb/minitest/) as their test framework. These tests generally require one or more Cisco routers, switches, or virtual machines to test against.

It is recommended that you create a `cisco_node_utils.yaml` file (as described in [README.md](../README.md#configuration) to specify the node(s) under test, but if you do not create such a file, the test will prompt you to enter the required information at runtime:

```bash
$ rake test
Enter address or hostname of node under test: 192.168.100.1
Enter username for node under test:           user
Enter password for node under test:           password
```

### Running a single minitest test

You can execute a single test file by name. If you do not specify the `-e` / `--environment` option, the node labeled as `default` in `cisco_node_utils.yaml` will be used (or, if no such entry exists, you will be prompted to enter the required information as shown above):

```bash
# Run test against the 'default' node:
$ ruby tests/test_node.rb
# Run test against node 'n7k':
$ ruby tests/test_node.rb --environment n7k
# Run test against node 'n9k':
$ ruby tests/test_node.rb -e n9k
```

### Running all minitest tests

As above, if you do not specify the `--environment` option, the `default` node will be used or you will be prompted if necessary.

```bash
# Run all tests against the 'default' node:
$ rake test
# Run all tests against 'n7k':
$ rake test TEST_OPTS='--environment=n7k'
```
