# Algolia Jekyll Plugin 

[![Gem Version](https://badge.fury.io/rb/algoliasearch-jekyll.svg)](http://badge.fury.io/rb/algoliasearch-jekyll)

Jekyll plugin to automatically index your Jekyll posts and pages into an
Algolia index by simply running `jekyll algolia push`.

## Usage

```shell
$ jekyll algolia push
```

This will push the content of your jekyll website to your Algolia index.

You can specify any option you would normally pass to `jekyll build`, like
`--config`, `--source`, `--destination`, etc.

## Installation

First, add the `algoliasearch-jekyll` gem to your `Gemfile`, in the
`:jekyll_plugins` section. If you do not yet have a `Gemfile`, here is the
minimum content to get your started.

```ruby
source 'https://rubygems.org'

gem 'jekyll', '>=2.5.3'

group :jekyll_plugins do
  gem 'algoliasearch-jekyll'
end
```

Once this is done, download all dependencies with `bundle install`. 

Then, add `algoliasearch-jekyll` to your `_config.yml` file, under the `gems`
section, like this:

```yaml
gems:
  - algoliasearch-jekyll
```

If everything went well, you should be able to execute `jekyll help` and see the
`algolia` subcommand listed.

## Configuration

Add information about your Algolia configuration into the `_config.yml` file,
under the `algolia` section, like this:

```yaml
algolia:
  application_id: 'your_application_id'
  index_name:     'your_index_name'
```

You admin api key will be read from the `ALGOLIA_API_KEY` environment variable.
You can define it on the same line as your command, allowing you to type
`ALGOLIA_API_KEY='your_admin_api_key' jekyll algolia push`.

### ⚠ Other, unsecure, method ⚠

You can also store your admin api key in a file named `_algolia_api_key`, in
your source directory. If you do this we __very, very, very strongly__ encourage
you to make sure the file is not tracked in your versioning system.

### Options

The plugin uses sensible defaults, but you may want to override some of its
configuration. Here are the various options you can add to your `_config.yml`
file, under the `algolia` section:

#### `excluded_files`

Defines which files should not be indexed for search.

```yml
algolia:
  excluded_files:
    - index.html
    - 2015-01-01-post.md
```

#### `record_css_selector`

Defines the css selector inside a page/post used to choose which parts to index.
It is set to all paragraphs (`<p>`) by default.

If you would like to also index lists, you could set it like this:

```yml
algolia:
  record_css_selector: 'p,ul'
```

#### `settings`

Here you can pass any custom settings you would like to push to your Algolia
index.

If you want to activate `distinct` and some snippets for example, you would do:

```yml
algolia:
  settings:
    attributeForDistinct: 'hierarchy'
    distinct: true
    attributesToSnippet: ['text:20']
```

### Hooks

The `AlgoliaSearchRecordExtractor` contains two methods (`custom_hook_each` and
`custom_hook_all`) that are here so you can overwrite them to add your custom
logic. They currently simply return the argument they take as input.

```ruby
class AlgoliaSearchRecordExtractor
  # Hook to modify a record after extracting
  # `node` refers to the Nokogiri HTML node of the element
  def custom_hook_each(item, node)
    item
  end

  # Hook to modify all records after extracting
  def custom_hook_all(items)
    items
  end
end
```

## Searching

This plugin will only index your data in your Algolia index. Adding search
capabilities is quite easy. You can follow [our tutorials][1] or use our forked
version of the popular [Hyde theme][2].

## GitHub Pages

Unfortunatly, GitHub does not allow custom plugins to be run on GitHub Pages.
This mean that you will have to manually run `jekyll algolia push` before
pushing your content to GitHub.


[1]: https://www.algolia.com/doc/javascript
[2]: https://github.com/algolia/hyde
