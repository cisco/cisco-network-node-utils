# Maintainers Guide

Guidelines for the core maintainers of the cisco-network-node-utils project - above and beyond the [general developer guidelines](../CONTRIBUTING.md).

## Accepting Pull Requests

* Is the pull request correctly submitted against `develop`?
* Does `rubocop` pass? (TODO - this will be part of our CI integration to run automatically)
* Is `CHANGELOG.md` updated appropriately?
* Are new minitests added? Do they provide sufficient coverage and consistent results?
* Do minitests pass on both N9K and N3K?

## Setting up git-flow

If you don't already have [`git-flow`](https://github.com/petervanderdoes/gitflow/) installed, install it.

Either run `git flow init` from the repository root directory, or manually edit your `.git/config` file. Either way, when done, you should have the following in your config:

```ini
[gitflow "branch"]
        master = master
        develop = develop
[gitflow "prefix"]
        feature = feature/
        release = release/
        hotfix = hotfix/
        support = support/
        versiontag = v
```

Most of these are default for git-flow except for the `versiontag` setting.

## Release Checklist

When we are considering publishing a new release, all of the following steps must be carried out (using the latest code base in `develop`):

1. Review cisco_node_utils.gemspec
  * Is the data still relevant?
  * Do the version dependencies need to be updated? (e.g. rubocop)

2. Run full minitest suite with various Ruby versions and hardware platforms:
  * Ruby versions:
    - REQUIRED: the Ruby version(s) bundled with Chef and Puppet (currently 2.1.6)
    - OPTIONAL: any/all other Ruby major versions currently supported by this gem (2.0, 2.2.2)
  * Platforms (all with latest released software or release candidate)
    - N30xx
    - N31xx
    - N9xxx

3. Triage any minitest failures.

4. Check code coverage results from minitest to see if there are any critical gaps in coverage.

5. Build gem and test it in combination with the latest released Puppet module (using Beaker and demo manifests) to make sure no backward compatibility issues have been introduced.

6. Make sure CHANGELOG.md accurately reflects all changes since the last release.
  * Add any significant changes that weren't documented in the changelog
  * Clean up any entries that are overly verbose, unclear, or otherwise could be improved.

## Release Process

When the release checklist above has been fully completed, the process for publishing a new release is as follows:

1. Create a release branch. Follow [semantic versioning](http://semver.org):
    * 0.0.x - a bugfix release
    * 0.x.0 - new feature(s)
    * x.0.0 - backward-incompatible change (if unvoidable!)

    ```
    git flow release start 1.0.1
    ```

2. In the newly created release branch, update `CHANGELOG.md` (this *should* be automatic if you have installed the Git hooks for this repository):

    ```diff
     Changelog
     =========
 
    -(unreleased)
    -------------
    +1.0.1
    +-----
    ```
    
    and also update `version.rb`:
    
    ```diff
    -  VERSION = '1.0.0'
    +  VERSION = '1.0.1'
    ```

3. Finish the release and push it to GitHub:

    ```
    git flow release finish 1.0.1
    git push origin master
    git push origin develop
    git push --tags
    ```

4. Add release notes on GitHub, for example `https://github.com/cisco/cisco-network-node-utils/releases/new?tag=v1.0.1`. Usually this will just be a copy-and-paste of the relevant section of the `CHANGELOG.md`.

5. Publish the new gem version to rubygems.org:

    ```
    gem build cisco_node_utils.gemspec
    gem push cisco_node_utils-0.9.0.gem
    ```
