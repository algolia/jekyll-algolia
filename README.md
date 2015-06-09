# Algolia Jekyll Plugin

Jekyll plugin to automatically index your Jekyll posts and pages into an
Algolia index.

## Usage

```shell
$ jekyll algolia push
```

This will push the content of your jekyll website to your Algolia index.

## Installation

Add `algoliasearch-jekyll` to your `_config.yml` file, under the `gems` section,
like this:

```yaml
gems:
  - algoliasearch-jekyll
```

If you're using a `Gemfile`, you should also add the gem to the
`:jekyll_plugins` group, like this:

```ruby
group :jekyll_plugins do
  gem 'algoliasearch-jekyll'
end
```

## Configuration

Add information about your Algolia configuration into the `_config.yml` file,
under the `algolia` section, like this:

```yaml
algolia:
  application_id: 'the_name_of_your_application'
  index_name:     'the_name_of_your_index'
```

You api key will be read either from the `ALGOLIA_API_KEY` environment variable,
or the `./_algolia_api_key` file.

Note that if you decide to use the `./_algolia_api_key` approach, we strongly
encourage you to not track this file in your versionning system.

## Search

Now that your index is populated with your data, you can start searching in it.
You can query it yourself using our [Javascript client][1], or you can use
our updated [Hyde theme][2].


[1]: https://www.algolia.com/doc/javascript
[2]: https://github.com/algolia/algoliasearch-jekyll-hyde
