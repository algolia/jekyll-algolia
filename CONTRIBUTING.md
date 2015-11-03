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

After the necessary `bundle install`, you can simply launch `guard` to start the
test suite in watch mode (perfect for TDD).

If you want to test the plugin on an existing Jekyll website while developping,
I suggest updating the website `Gemfile` to point to the correct local directory

```ruby
gem "algoliasearch-jekyll", :path => "/path/to/local/gem/folder"
```

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



