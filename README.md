# Jekyll Algolia Plugin

[![gem version][1]](https://rubygems.org/gems/jekyll-algolia)
![ruby][2]
![jekyll][3]
[![build master][4]](https://travis-ci.org/algolia/jekyll-algolia)
[![coverage master][5]](https://coveralls.io/github/algolia/jekyll-algolia?branch=master)
[![build develop][6]](https://travis-ci.org/algolia/jekyll-algolia)
[![coverage develop][7]](https://coveralls.io/github/algolia/jekyll-algolia?branch=develop)

Add fast and relevant search to your Jekyll site.

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
here][8]. Once signed in, you can get your
credentials from [your dashboard][9].*

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

## More about the Community plan

The Algolia [Community plan][10] lets you host up to 10k records and perform up to
100k add/edit/delete operations per month (search operations are free). The plan
is entirely free, with no time limit.

What we ask in exchange is that you display a "Search by Algolia" logo next to
your search results. Our [InstantSearch libraries][11] have a simple boolean
option to toggle that on an off. If you want more flexibility, you can find
all versions of our logo [here][12].

# Thanks

Thanks to [Anatoliy Yastreb][13] for a [great tutorial][14] on creating Jekyll
plugins.


[1]: https://badge.fury.io/rb/jekyll-algolia.svg
[2]: https://img.shields.io/badge/ruby-%3E%3D%202.3.0-green.svg
[3]: https://img.shields.io/badge/jekyll-%3E%3D%203.6.0-green.svg
[4]: https://img.shields.io/badge/dynamic/json.svg?label=build%3Amaster&query=value&uri=https%3A%2F%2Fimg.shields.io%2Ftravis%2Falgolia%2Fjekyll-algolia.json%3Fbranch%3Dmaster
[5]: https://img.shields.io/badge/dynamic/json.svg?label=coverage%3Amaster&colorB=&prefix=&suffix=%25&query=$.coverage_change&uri=https%3A%2F%2Fcoveralls.io%2Fgithub%2Falgolia%2Fjekyll-algolia.json%3Fbranch%3Dmaster
[6]: https://img.shields.io/badge/dynamic/json.svg?label=build%3Adevelop&query=value&uri=https%3A%2F%2Fimg.shields.io%2Ftravis%2Falgolia%2Fjekyll-algolia.json%3Fbranch%3Ddevelop
[7]: https://img.shields.io/badge/dynamic/json.svg?label=coverage%3Adevelop&colorB=&prefix=&suffix=%25&query=$.coverage_change&uri=https%3A%2F%2Fcoveralls.io%2Fgithub%2Falgolia%2Fjekyll-algolia.json%3Fbranch%3Ddevelop
[8]: #more-about-the-community-plan
[9]: https://www.algolia.com/licensing
[10]: https://www.algolia.com/users/sign_up/hacker
[11]: https://community.algolia.com/instantsearch.js/
[12]: https://www.algolia.com/press#resources
[13]: https://github.com/ayastreb/
[14]: https://ayastreb.me/writing-a-jekyll-plugin/
