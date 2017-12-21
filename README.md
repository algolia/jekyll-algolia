# Jekyll Algolia Plugin

[![Gem Version][1]](http://badge.fury.io/rb/jekyll-algolia) [![Build
Status][2]](https://travis-ci.org/algolia/jekyll-algolia) [![Coverage
Status][3]](https://coveralls.io/github/algolia/jekyll-algolia?branch=master)
[![Code Climate][4]](https://codeclimate.com/github/algolia/jekyll-algolia)
![Jekyll >= 3.6.0][5] ![Ruby >= 2.3.0][6]

Jekyll plugin to automatically index your content on Algolia.

## Usage

```shell
$ bundle exec jekyll algolia
```

This will push the content of your Jekyll website to your Algolia index.

## Documentation

Full documentation can be found on
[https://community.algolia.com/jekyll-algolia/](https://community.algolia.com/jekyll-algolia/getting-started.html)

## Installation

The plugin requires at least Jekyll 3.6.0 and Ruby 2.3.0.

First, add the `jekyll-algolia` gem to your `Gemfile`, in the `:jekyll_plugins`
section.

```ruby
# Gemfile

group :jekyll_plugins do
  gem 'jekyll-algolia', '~> 1.0'
end
```

Once this is done, download all dependencies with `bundle install`.

## Basic configuration

You need to provide certain Algolia credentials for this plugin to *index* your
site.

*If you don't yet have an Algolia account, you can open a free [Community plan
here][7]. Once signed in, you can get your credentials from
[your dashboard][8].*

Once you have your credentials, you should define your `application_id` and
`index_name` inside your `_config.yml` file like this:

```yaml
# _config.yml

algolia:
  application_id: 'your_application_id'
  index_name:     'your_index_name'
```

## Run it

Once your credentials are setup, you can run the indexing by running the
following command:

```shell
ALGOLIA_API_KEY='{your_admin_api_key}' bundle exec jekyll algolia
```

Note that `ALGOLIA_API_KEY` should be set to your admin API key.

# Thanks

Thanks to [Anatoliy Yastreb][9] for a [great tutorial][10] on creating Jekyll
plugins.


[1]: https://badge.fury.io/rb/jekyll-algolia.svg
[2]: https://travis-ci.org/algolia/jekyll-algolia.svg?branch=master
[3]: https://coveralls.io/repos/algolia/jekyll-algolia/badge.svg?branch=master&service=github
[4]: https://codeclimate.com/github/algolia/jekyll-algolia/badges/gpa.svg
[5]: https://img.shields.io/badge/jekyll-%3E%3D%203.6.0-green.svg
[6]: https://img.shields.io/badge/ruby-%3E%3D%202.3.0-green.svg
[7]: https://www.algolia.com/users/sign_up/hacker
[8]: https://www.algolia.com/licensing
[9]: https://github.com/ayastreb/
[10]: https://ayastreb.me/writing-a-jekyll-plugin/
