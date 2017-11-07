Hi collaborator!

If you have a fix or a new feature, please start by checking in the
[issues](https://github.com/algolia/jekyll-algolia/issues) if it is
already referenced. If not, feel free to open one.

We use [pull requests](https://github.com/algolia/jekyll-algolia/pulls)
for collaboration. The workflow is as follow:

- Create a local branch, starting from `develop`
- Submit the PR on `develop`
- Wait for review
- Do the changes requested (if any)
- We may ask you to rebase the branch to latest `develop` if it gets out of sync
- Receive the thanks of the Algolia team :)

# Development workflow

Start by running `bundle install` to get all the dependencies up to date.

## Testing

Run `rake test` to launch all tests. You can run `rake test_details` to get an
output with more details about the tests.

## TDD

// TODO

## Testing different ruby versions

You can test the gem across all the supported Ruby versions by running
`./scripts/test_all_ruby_versions`. Note that you will need to have RVM
installed for this to work.

## Testing local changes on an existing Jekyll website

If you want to test the plugin on an existing Jekyll website while developping,
I suggest updating the website `Gemfile` to point to the correct local directory

```ruby
group :jekyll_plugins do
  gem "jekyll-algolia", :path => "/path/to/local/gem/folder"
end
```

# Git Hooks

If you plan on submitting a PR, I suggest you install the git hooks located in
`./scripts/git_hook`.

The easiest way is to create a symlink from your `.git/hooks` folder:

```sh
$ git root
$ rm ./.git/hooks
$ ln -s ./scripts/git_hooks/ ./.git/hooks
```

# Tagging and releasing

If you need to release a new version of the gem, run `rake release` from the
`develop` branch. It will ask you for the new version and automatically create
the git tags, create the gem and push it to Rubygems.

# Project owner

[@pixelastic](https://github.com/pixelastic)
