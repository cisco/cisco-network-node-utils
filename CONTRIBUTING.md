# How to contribute
Cisco Network Elements support a rich set of features to make networks robust, efficient and secure. The GitHub project [cisco-network-puppet-module](https://github.com/cisco/cisco-network-puppet-module) defines a set of Puppet resource types and providers to manage the network element. Similarly, the GitHub project [cisco-network-chef-cookbook](https://github.com/cisco/cisco-network-chef-cookbook) defines a set of Chef resources and providers for network element management. The providers defined in these projects leverage a common set of Ruby API Objects defined in this project. This object set is expected to grow with contributions from Cisco, Cisco-Partners and third-party alike. Contributions to this project are welcome. To ensure code quality, contributors will be requested to follow few guidelines.

## Getting Started

* Create a [GitHub account](https://github.com/signup/free)
* A virtual Nexus N9000/N3000 may be helpful for development and testing. Users with a valid [cisco.com](http://cisco.com) user ID can obtain a copy of a virtual Nexus N9000/N3000 by sending their [cisco.com](http://cisco.com) user ID in an email to <get-n9kv@cisco.com>. If you do not have a [cisco.com](http://cisco.com) user ID please register for one at [https://tools.cisco.com/IDREG/guestRegistration](https://tools.cisco.com/IDREG/guestRegistration)

## Making Changes

* Fork and clone the repository
  * Run the `bin/git/update-hooks` script to install our recommended Git hooks into your local repository.
  * Pull a branch under the "develop" branch for your changes.
  * Follow all guidelines documented in [README-develop-node_utils-APIs](docs/README-develop-node-utils-APIs.md)
  * Make changes in your branch.
* Testing
  * Create a minitest script for any new APIs or new functionality
  * Run all the tests to ensure there was no collateral damage to existing code. There are two ways you can specify the Nexus switch (virtual or physical) to test against when running the full test suite:
    1. Use the NODE environment variable to specify the address, username, and password:

        ```bash
        export NODE="192.168.100.1 user password"
        rake test
        ```

    2. Enter the connection information at runtime:

        ```
        rake test
        Enter address or hostname of node under test: 192.168.100.1
        Enter username for node under test:           user
        Enter password for node under test:           password
        ```

* Committing
  * Check for unnecessary whitespace with `git diff --check` before committing.
  * Run `rubocop` against all changed files. See [https://rubygems.org/gems/rubocop](https://rubygems.org/gems/rubocop)
  * Make sure your commit messages clearly describe the problem you are trying to solve and the proposed solution.
  * Be sure to update `CHANGELOG.md` with a note about what you have added or fixed.

## Submitting Changes

 All contributions submitted to this project are voluntary and subject to the terms of the Apache 2.0 license
* Submit a pull request to the repository
  * Include output of all added or modified minitest scripts.
* A core team consisting of Cisco and Cisco-Partner employees will review the Pull Request and provide feedback.
* After feedback has been given we expect responses within two weeks. After two weeks we may close the pull request if it isn't showing any activity.
* All code commits must be associated with your github account and email address. Before committing any code use the following commands to update your workspace with your credentials:

```bash
git config --global user.name "John Doe"
git config --global user.email johndoe@example.com
```

# Additional Resources

* [General GitHub documentation](http://help.github.com/)
* [GitHub pull request documentation](http://help.github.com/send-pull-requests/)
