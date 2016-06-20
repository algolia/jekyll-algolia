Hi collaborator!

If you have a fix or a new feature, please start by checking in the
[issues](https://github.com/algolia/algoliasearch-jekyll/issues) if it is
already referenced. If not, feel free to open one.

We use [pull requests](https://github.com/algolia/algoliasearch-jekyll/pulls)
for collaboration. The workflow is as follow:

- Create a local branch, starting from `develop`
- Submit the PR on `develop`
- Wait for review
- Do the changes requested (if any)
- We may ask you to rebase the branch to latest `develop` if it gets out of sync
- Receive the thanks of the Algolia team :)

# Development workflow

After the necessary `bundle install`, you'll also need to run `appraisal
install`. This will configure the repository so that tests can be run both from
Jekyll 2.5 and Jekyll 3.

You can then launch:
- `./scripts/test_v2` to launch tests on Jekyll v2
- `./scripts/test_v3` to launch tests on Jekyll v3
- `./scripts/test` to launch tests on both
- `./scripts/watch` to start a test watcher (for TDD) for Jekyll v2
- `./scripts/watch_v3` to start a test watcher (for TDD) for Jekyll v3

The watched test will both launch Guard (with `guard-rspec`), but each will use
its own `Guardfile` version, launching the correct `appraisal` before the
`rspec` command.

If you want to test the plugin on an existing Jekyll website while developping,
I suggest updating the website `Gemfile` to point to the correct local directory

```ruby
gem "algoliasearch-jekyll", :path => "/path/to/local/gem/folder"
```
You should also run `rake gemspec` from the `algoliasearch-jekyll` repository if
you added/deleted any file or dependency.

If you plan on submitting a PR, I suggest you install the git hooks. This will
run pre-commit and pre-push checks. Those checks will also be run by TravisCI,
but running them locally gives faster feedback.

# Tagging and releasing

This part is for main contributors:

```
# Bump the version (in develop)
./scripts/bump_version minor

# Update master and release
./scripts/release

# Install the gem locally (optional)
rake install
```

# Project owner

[@pixelastic](https://github.com/pixelastic)



