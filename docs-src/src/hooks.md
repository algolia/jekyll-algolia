---
title: Hooks
layout: content-with-menu.pug
---

# Hooks

The plugin gives you access to hooks in its lifecycle. Those hooks can
be used to add your own custom Ruby logic to have more control on the way
records are being extracted and indexed.

Using hooks are a more advanced feature than using [regular configuration][1] options
but they will also give you much more flexibility.

### Usage

You'll have to extend the `Jekyll::Algolia` class to overwrite the method
definition of the hooks. The best way to do so is to [add a custom plugin][2] to
your Jekyll site.

Create a `_plugins` directory in your Jekyll source folder if you don't have one
already. Inside this folder, create an `algolia_hooks.rb` file.

The file should have the following structure:

```ruby
module Jekyll
  module Algolia
    # Add your hooks here
  end
end
```

## `hook_should_be_excluded?`

This hook will give you more control on which file should be indexed or not. It
will be called for every indexable file, with the source `filepath` as an
argument. The file will be excluded if the hook returns `true`, and will be
indexed if it returns `false`.

| Key  | Value  |
| ---- | ---- |
| Signature | `hook_should_be_excluded?(filepath)` |
| Arguments | <ul><li>`filepath`: The source path of the file</li></ul> |
| Expected returns | <ul><li>`true` if the file should be excluded</li><li>`false` if it should be indexed</li></ul> |

*Note that the hook will not be called on files already excluded by
[extensions\_to\_index][3] or [files\_to\_exclude][4].*

### Example

```ruby
module Jekyll
  module Algolia
    def self.hook_should_be_excluded?(filepath)
      # Do not index blog posts from 2015
      return true if filepath =~ %r{_posts/2015-}
      false
    end
  end
end
```

## `hook_before_indexing_each`

This hook will be called on every single record before indexing them. It gives you
a way to edit the record before pushing it. You can use this hook to add, edit
or delete keys from the record. If the hook returns `nil`, the
record will not be indexed.

The hook will receive two arguments: `record` and `node`. `record` is the hash
of the record, ready to be pushed to Algolia. `node` is a [Nokogiri][5]
representation of the HTML node the record was extracted from (as specified in
[nodes_to_index][6].

| Key  | Value  |
| ---- | ---- |
| Signature | `hook_before_indexing_each(record, node)` |
| Arguments | <ul><li>`record`: A hash of the record that will be pushed</li><li>`node`: A [Nokogiri][7] representation of the HTML node it was extracted from</li></ul> |
| Expected returns | <ul><li>A hash of the record to be indexed</li><li>`nil` if the record should not be indexed</li></ul> |

### Example

```ruby
module Jekyll
  module Algolia
    def self.hook_before_indexing_each(record, node)
      # Do not index deprecation warnings
      return nil if node.attr('class') =~ 'deprecation-notice'
      # Add my name as an author to each record
      record[:author] = 'Myself'

      record
    end
  end
end
```

## `hook_before_indexing_all`

This hook is very similar to [hook_before_index_each][8], but instead of being called
on every record, it is called only once, on the full list of record, right
before pushing them.

It will be called with one argument, `records`, being the full list of records
to be pushed, and expects a list of records to be returned.

You can use this hook to add, edit or delete complete records from the list,
knowing the full context of what is going to be pushed.

| Key  | Value  |
| ---- | ---- |
| Signature | `hook_before_indexing_all(records)` |
| Arguments | <ul><li>`records`: An array of hashes representing the records that are going to be pushed</li></ul> |
| Expected returns | <ul><li>An array of hashes to be pushed as records</li></ul> |

### Example

```ruby
module Jekyll
  module Algolia
    def self.hook_before_indexing_all(records)
      # Add a tags array to each record
      records.each do |record|
        record[:tags] = []
        # Add 'blog' as a tag if it's a post
        record[:tags] << 'blog' if record[:type] == 'post'
        # Add js as a tag if it's about javascript
        record[:tags] << 'js' if record[:title] =~ 'js'
      end

      records
    end
  end
end
```

[1]: ./options.html
[2]: https://jekyllrb.com/docs/plugins/#installing-a-plugin
[3]: ./options.html#extensions-to-index
[4]: ./options.html#files-to-exclude
[5]: http://www.nokogiri.org
[6]: ./options.html#nodes-to-index
[7]: http://www.nokogiri.org
[8]: hooks.html#hook-before-indexing-each
