---
title: Getting started with jekyll-algolia
layout: content-with-menu.pug
---

# Getting started

## Welcome to jekyll-algolia

`jekyll-algolia` is a Jekyll plugin that lets you index all your content to
Algolia, to make it searchable by typing `jekyll algolia`.

## Requirements

You'll need:

- [Jekyll][1] >= 3.6.0
- [Ruby][2] >= 2.3.0
- [Bundler][3]

## Installation

You need to add `jekyll-algolia` to your `Gemfile`, as part of the
`:jekyll-plugins` group. If you do not yet have a Gemfile, here is the minimal
content you'll need:

```ruby
source 'https://rubygems.org'

gem 'jekyll', '~> 3.6'

group :jekyll_plugins do
  gem 'jekyll-algolia'
end
```

Then, run `bundle install` to update your dependencies.

If everything went well, you should be able to run `jekyll help` and see the
`algolia` subcommand listed.

## Configuration

You need to provide certain Algolia credentials for this plugin to *index* your
site.

*If you don't yet have an Algolia account, you can open a free [Community plan
here][4]. Once signed in, you can get your credentials from
[your dashboard][5].*

The plugin will try to fetch the credentials from your environment-variables
hash and fallback to your Jekyll configuration if not found.

To pass the credentials as ENV variables, you can do so at the same time when
you run the `jekyll algolia` command


[1]: https://jekyllrb.com/
[2]: https://www.ruby-lang.org/en/
[3]: http://bundler.io/
[4]: https://www.algolia.com/users/sign_up/hacker
[5]: https://www.algolia.com/licensing
