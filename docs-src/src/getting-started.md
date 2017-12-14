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

You need to provide your Algolia credentials for this plugin to *index* your
site.

*If you don't yet have an Algolia account, you can open a free [Community plan
here][4]. Once signed in, you can get your credentials from
[your dashboard][5].*

Once you have your credentials, you should define your `application_id` and
`index_name` inside your `_config.yml` file like this:

```yaml
# _config.yml

algolia:
  application_id: 'your_application_id'
  index_name:     'your_index_name'
```

## Usage

Once your credentials are setup, you can run the indexing by running the
following command:

```shell
ALGOLIA_API_KEY='{your_admin_api_key}' bundle exec jekyll algolia
```

Note that `ALGOLIA_API_KEY` should be set to your admin API key. This key has
write access to your index so will be able to push new data. This is also why
you have to set it on the command line and not in the `_config.yml` file: you
want to keep this key secret and not commit it to your versioning system.

_Note that the method can be simplified to `jekyll algolia` by using an
[alternative way][6] of loading the API key and using [rubygems-bundler][7]._


[1]: https://jekyllrb.com/
[2]: https://www.ruby-lang.org/en/
[3]: http://bundler.io/
[4]: https://www.algolia.com/users/sign_up/hacker
[5]: https://www.algolia.com/licensing
[6]: ./commandline.html#algolia-api-key-file
[7]: https://github.com/rvm/rubygems-bundler
