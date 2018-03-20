---
title: Migration guide
layout: content-with-menu.pug
---

# Migrating from `algoliasearch-jekyll`

If you're using the previous `algoliasearch-jekyll` gem, and would
like to migrate to the new `jekyll-algolia`, this guide will help you through
the migration process.

## Renaming

Most of the changes you'll have to do to migrate is to rename configuration
settings.

The most obvious one being that the gem is now called `jekyll-algolia` and not
`algoliasearch-jekyll`. You should update your `Gemfile` to add the
`jekyll-algolia` gem to the `:jekyll_plugin` group, like this:

```ruby
source 'https://rubygems.org'

gem 'jekyll', '~> 3.6'

group :jekyll_plugins do
  gem 'jekyll-algolia'
end
```

Note that you no longer need to add the plugin to the list of `plugins` in your
`_config.yml`, this is now taken care of at the `Gemfile` level. The other
important change is that the new version requires at least Ruby 2.3 and Jekyll
3.6 to work.

The command to run the plugin has been simplified from `jekyll algolia push` to
`jekyll algolia`.

## Options

All the previous option and behaviors are still available, but their names have
been changed:

`excluded_files` has been renamed to [files_to_exclude][1],
`record_css_selector` to [nodes_to_index][2] and `allowed_extensions` to
[extensions_to_index][3].  Note that for the last one, it now expects
a comma-separated list of extensions.

The `lazy_update` option does not exist anymore. The new indexing mode is
equal to `lazy_update: true`. Only records that changed between the current
build and the previous one will be updated, and it will even be done in an
atomic way (all in one go).

## Hooks

All three hooks (`custom_hook_excluded_file?`, `custom_hook_each` and
`custom_hook_all`) are still here, but they have been renamed to
[should_be_excluded?][4], [before_indexing_each][5] and [before_indexing_all][6].

They all have the same behavior and expect the same arguments as before, but
should now extend the `Jekyll::Algolia::Hooks` module. It means that the file
you used to define them should now look like this:

```ruby
module Jekyll
  module Algolia
    module Hooks
    # Add your hooks here
    end
  end
end
```

You can find the complete documentation on the [dedicated page][7].

## Records

Records extracted from Jekyll have the same structure as before, except that the
`text` key has been renamed to `content`.

Here is an example of a record extracted by the plugin:

```json
{
  "objectID": "e2dd8dd1eaaf961baa6da4de309628e9",
  "title": "New experimental version of Hacker News Search built with Algolia",
  "type": "post",
  "url": "/2015/01/12/try-new-experimental-version-hn-search.html",
  "date": 1421017200,
  "excerpt_html": "<p>Exactly a year ago, we began to power […]</p>",
  "excerpt_text": "Exactly a year ago, we began to power […]",
  "slug": "try-new-experimental-version-hn-search",

  "html": "<p>We've learned a lot from your comments […]</p>",
  "content": "We've learned a lot from your comments […]",
  "headings": [
    "Applying more UI best practices",
    "Focus on readability"
  ],
  "anchor": "focus-on-readability",
  "custom_ranking": {
    "position": 8,
    "heading": 70
  }
}
```

## Need more help?

If you need more help migrating from the previous plugin to this new version,
you can [file an issue][8] on the GitHub repo and we'll do our best to help you.


[1]: ./options.html#files-to-exclude
[2]: ./options.html#nodes-to-index
[3]: ./options.html#extensions-to-index
[4]: ./hooks.html#should-be-excluded
[5]: ./hooks.html#before-indexing-each
[6]: ./hooks.html#before-indexing-all
[7]: ./hooks.html
[8]: https://github.com/algolia/jekyll-algolia/issues
