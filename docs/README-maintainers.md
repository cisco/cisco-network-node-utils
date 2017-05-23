# Maintainers Guide

Guidelines for the core maintainers of the cisco-network-node-utils project - above and beyond the [general developer guidelines](../CONTRIBUTING.md).

## Accepting Pull Requests

* Is the pull request correctly submitted against `develop`?
* Does `rubocop` pass? (TODO - this will be part of our CI integration to run automatically)
* Is `CHANGELOG.md` updated appropriately?
* Are new minitests added? Do they provide sufficient coverage and consistent results?
* Do minitests pass on all supported platforms

## Release Process Checklist

When we are considering publishing a new release, all of the following steps must be carried out.
   * NOTE: Use the latest code base in `develop`

### Pre-Merge to `master` branch:

1. Pull release branch based on the `develop` branch.
    * 0.0.x - a bugfix release
    * 0.x.0 - new feature(s)
    * x.0.0 - backward-incompatible change (if unvoidable!)

1. Run full minitest regression on [supported platforms.](https://github.com/cisco/cisco-network-node-utils#overview)
    * Fix All Bugs.
    * Make sure proper test case skips are in place for unsupported platforms.

1. Build gem and test it in combination with the latest released Puppet module (using Beaker and demo manifests) to make sure no backward compatibility issues have been introduced.

1. Update [changelog.](https://github.com/cisco/cisco-network-node-utils/blob/develop/CHANGELOG.md)
    * Make sure CHANGELOG.md accurately reflects all changes since the last release.
    * Add any significant changes that weren't documented in the changelog
    * Clean up any entries that are overly verbose, unclear, or otherwise could be improved.
    * Create markdown release tag.
      * [Example](https://github.com/cisco/cisco-network-node-utils/blob/develop/CHANGELOG.md#v120)
    * Add compare versions
      ```diff
      ...
      +[v1.0.1]: https://github.com/cisco/cisco-network-node-utils/compare/v1.0.0...v1.0.1
      [v1.0.0]: https://github.com/cisco/cisco-network-node-utils/compare/v0.9.0...v1.0.0
      ```
    * Indicate new platform support (if any) for exisiting providers.

1. Update [cisco_node_utils.gemspec](https://github.com/cisco/cisco-network-node-utils/blob/develop/cisco_node_utils.gemspec) if needed.
    * Is the data still relevant?
    * Do the version dependencies need to be updated? (e.g. rubocop)

1. Update [version.rb](https://github.com/cisco/cisco-network-node-utils/blob/develop/lib/cisco_node_utils/version.rb) file.
    ```diff
    -  VERSION = '1.0.0'
    +  VERSION = '1.0.1'
    ```

1. Scrub README Docs.
    * Update references to indicate new platorm support where applicable.
    * Update nxos release information where applicable.

1. Open pull request from release branch against the `master` branch.
    * Merge after approval.

### Post-Merge to `master` branch:

1. Create annotated git tag for the release.
    * [HowTo](https://git-scm.com/book/en/v2/Git-Basics-Tagging#Annotated-Tags)

2. Draft a [new release](https://github.com/cisco/cisco-network-node-utils/releases) on github.

3. Publish the gem to rubygems.org. (Replace `x.x.x` with actual gem version)
    ```
    gem build cisco_node_utils.gemspec
    gem push cisco_node_utils-x.x.x.gem
    ```
4. Merge `master` branch back into `develop` branch.
    * Resolve any merge conflicts
    * Optional: Delete release branch (May want to keep for reference)
