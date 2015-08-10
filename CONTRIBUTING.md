# How to contribute
Cisco Network Elements support a rich set of features to make networks robust, efficient and secure. The GitHub project [cisco-network-puppet-module](https://github.com/cisco/cisco-network-puppet-module) defines a set of Puppet resource types and providers to manage the network element. Similarly, the GitHub project [cisco-network-chef-cookbook](https://github.com/cisco/cisco-network-chef-cookbook) defines a set of Chef resources and providers for network element management. The providers defined in these projects leverage a common set of Ruby API Objects defined in this project. This object set is expected to grow with contributions from Cisco, Cisco-Partners and third-party alike. Contributions to this project are welcome. To ensure code quality, contributors will be requested to follow few guidelines.

## Getting Started

* Create a [GitHub account](https://github.com/signup/free)
* Create a [cisco.com](http://cisco.com) account if you need access to a Network Simulator to test your code.

## Making Changes

* Fork the repository
  * Pull a branch under the "develop" branch for your changes.
  * Follow all guidelines documented in [README-creating-node_utils-APIs](#README-creating-node_utils-APIs.md)
  * Make changes in your branch.
* Testing
  * Create a minitest for new APIs or new functionality
  * Run all the tests to ensure there was no collateral damage to existing code
* Committing
  * Check for unnecessary whitespace with `git diff --check` before committing.
  * Run `rubocop --lint` against all changed files. See [https://rubygems.org/gems/rubocop](https://rubygems.org/gems/rubocop)
  * Make sure your commit messages clearly describe the problem you are trying to solve and the proposed solution.

## Submitting Changes

* All contributions you submit to this project are voluntary and subject to the terms of the Apache 2.0 license
* Submit a pull request to the repository
* A core team consisting of Cisco and Cisco-Partner employees will looks at Pull Request and provide feedback.
* After feedback has been given we expect responses within two weeks. After two weeks we may close the pull request if it isn't showing any activity.

# Additional Resources

* [General GitHub documentation](http://help.github.com/)
* [GitHub pull request documentation](http://help.github.com/send-pull-requests/)
