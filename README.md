# Jekyll Algolia Plugin

[![Gem Version][1]](http://badge.fury.io/rb/jekyll-algolia) [![Build
Status][2]](https://travis-ci.org/algolia/jekyll-algolia) [![Coverage
Status][3]](https://coveralls.io/github/algolia/jekyll-algolia?branch=master)
[![Code
Climate][4]](https://codeclimate.com/github/algolia/jekyll-algolia)
![Jekyll >= 3.6.2][5] ![Ruby >= 2.2.8][6]

Jekyll plugin to automatically index your content into Algolia.

## Usage

```shell
$ jekyll algolia
```

This will push the content of your Jekyll website to your Algolia index.

## Installation

The plugin requires a minimum version of Jekyll of 3.6.2 and a Ruby version of
2.2.8 (which are the current versions [deployed on GitHub Pages][7] at the time of
writing).

First, add the `jekyll-algolia` gem to your `Gemfile`, in the `:jekyll_plugins`
section. 

If you do not yet have a `Gemfile`, here is the minimal content to get
your started. You will also need [Bundler][8] to be able to use the `Gemfile`.

```ruby
source 'https://rubygems.org'

gem 'jekyll', '~> 3.6'

group :jekyll_plugins do
  gem 'jekyll-algolia'
end
```

Once this is done, download all dependencies with `bundle install`.

If everything went well, you should be able to run `jekyll help` and see the
`algolia` subcommand listed.

## Basic configuration

Add your Algolia credentials under the `algolia` section of your
`_config.yml` file like this:

```yaml
algolia:
  application_id: 'your_application_id'
  index_name:     'your_index_name'
```

_If you don't yet have an Algolia account, you can open a free [Community plan
here][9]. If you already have an account, you can get your credentials from
[your dashboard][10]._

Your API key will be read from the `ALGOLIA_API_KEY` environment variable.
You can define it on the same line as your command, allowing you to type
`ALGOLIA_API_KEY='your_api_key' jekyll algolia`.

### ⚠ Other, unsecure, method ⚠

You can also store your API key in a file named `_algolia_api_key`, in
your source directory. If you do this we __very, very, very strongly__ encourage
you to make sure the file is not tracked in your versioning system.

## How it works

The plugin will work like a `jekyll build` run, but instead of writing `.html`
files to disk, it will push content to Algolia.

It will split each page of your website into small chunks (by default, one per
`<p>` paragraph) and then push each chunk as a new record to Algolia. Splitting
records that way yields a better relevance of results even on long pages.

The placement of each paragraph in the page heading hierarchy (title, subtitles
through `<h1>` to `<h6>`) is also taken into account to further improve
relevance of results.

Each record will also contain metadata about the page it was extracted from
(including `slug`, `url`, `tags`, `categories`, `collection`  and any custom
field added to the front-matter).

Every time you run `jekyll algolia`, a full build of the website is run locally,
but only records that were changed since your last build will be updated in your
index.

## Advanced configuration

The plugin should work out of the box for most websites, but there are options
you can tweak if needed. All the options should be added under the `algolia`
section of your `_config.yml` file.

### `nodes_to_index`

By default, each page of your website will be split into chunks based on this
CSS selector. The default value of `p` means that one record will be created for
each `<p>` in your generated content.

If you would like to index other elements, like `<blockquote>`,
`<li>` or a custom `<div class="paragraph">`. If so, you should edit the value
like this:

```yml
algolia:
  # Also index quotes, list items and custom paragraphs
  nodes_to_index: 'p,blockquote,li,div.paragraph'
```

### `extensions_to_index`

By default, HTML and Markdown files will be indexed. If you are using
another markup language (such as [AsciiDoc][11]
or [Textile][12], then you should overwrite this
option.

```yml
algolia:
  # Also index AsciiDoc and Textile files
  extensions_to_index: 'html,md,adoc,textile'
```

### `files_to_exclude`

The plugin will try to be smart in the pages it should __not__ index. Some files
will always be excluded from the indexing (static assets, custom 404 and
pagination pages). Others are handled by the `files_to_exclude` option.

By default it will exclude all the `index.html` and `index.md` files. Those
files are usually not containing much text (landing pages) or containing
redundant text (latest blog articles) so we decided to exclude them by default.

If you actually want to index those files, you should set the value to an empty
array.

```yml
algolia:
  # Actually index the index.html/index.md pages
  files_to_exclude: []
```

If you want to exclude more files, you should add them to the array:

```yml
algolia:
  # Exclude more files from indexing
  files_to_exclude:
    - index.html
    - index.md
    - excluded-file.html
    - /_posts/2017-01-20-date-to-forget.md
```

### `settings`

By default the plugin will configure your Algolia index with settings tailored
to the format of the extracted records. You are of course free to overwrite
them or configure them as best suits your needs. Every option passed to the
`settings` entry will passed to a call to [set_settings][13].

For example if you want to change the HTML tag used for the highlighting, you
can overwrite it like this:

```yml
algolia:
  settings:
    highlightPreTag: '<em class="custom_highlight">
    highlightPostTag: '</em>'
```

### `indexing_batch_size`

The Algolia API allows you to send batches of changes to add or update several
records at once, instead of doing one HTTP call per record. The plugin will
batch updates by groups of 1000 records.

If you are on an unstable internet connection, you might want to decrease the
value. You will send more batches, but each will be smaller in size.

```yml
algolia:
  # Send fewer records per batch
  indexing_batch_size: 500
```

### `indexing_mode`

Synchronizing your local data with your Algolia index can be done in different
ways. By default, the plugin will use the `diff` indexing mode but you might
also be interested in the `atomic` mode.

### `diff` (default)

By default, the plugin will try to be smart when pushing content to your index:
it will only push new records and delete old ones insted of overwriting
everything.

To do so, we first need to grab the list of all records residing in
your index, then comparing them with the one generated locally. We then delete
the old records that no longer exists, and then add the newly created record.

The main advantage is that it will consume very few operations in your Algolia
quota. The drawback is that it will put your index into an inconsistent state
for a few seconds (records were deleted, but new one were not yet added). Users
doing a search on your website at that time might have incomplete results.

### `atomic`

Using the `atomic` indexing mode, your users will never search into an
inconsistent index. They will either be searching into the index containing the
old data, or the one containing the new data, but never in an intermediate
state.

To do so, the plugin will actually push all data to a temporary index first.
Once everything is copied and configured, it will then overwrite the old index
with the temporary one.

The main advantage is that it will be completly transparent for your users. The
drawback is that it will consume much more operations as you will have to push
all your records to a new index each time.







<!-- ## Custom hooks -->
<!--  -->
<!--  -->
<!--     def self.hook_should_be_excluded?(_filepath) -->
<!--     def self.hook_before_indexing_each(record, _node) -->
<!--     def self.hook_before_indexing_all(records) -->

<!-- ## Command line -->
<!--  -->
<!-- Here is the list of command line options you can pass to the `jekyll algolia -->
<!-- push` command: -->
<!--  -->
<!-- | Flag                     | Description                                                           | -->
<!-- | ----                     | -----                                                                 | -->
<!-- | `--config ./_config.yml` | You can here specify the config file to use. Default is `_config.yml` | -->
<!-- | `--future`               | With this flag, the command will also index posts with a future date  | -->
<!-- | `--limit_posts 10`       | Limits the number of posts to parse and index                         | -->
<!-- | `--drafts`               | Index drafts in the `_drafts` folder as well                          | -->
<!-- | `--dry-run` or `-n`      | Do a dry run, do not actually push anything to your index             | -->
<!-- | `--verbose`              | Display more information about what is going to be indexed            | -->


<!-- ## Searching -->
<!--  -->
<!-- This plugin will index your data in your Algolia index. Building the front-end -->
<!-- search is of the scope of this plugin, but you can follow [our tutorials][14] or -->
<!-- use our forked version of the popular [Hyde theme][15]. -->
<!--  -->
<!-- ## GitHub Pages -->
<!--  -->
<!-- The initial goal of the plugin was to allow anyone to have access to great -->
<!-- search, even on a static website hosted on GitHub pages. -->
<!--  -->
<!-- But GitHub does not allow custom plugins to be run on GitHub Pages. -->
<!-- This means that you'll either have to run `bundle exec jekyll algolia push` -->
<!-- manually, or configure a CI environment (like [Travis][16] to do it for you. -->
<!--  -->
<!-- [Travis CI][17] is an hosted continuous integration -->
<!-- service, and it's free for open-source projects. Properly configured, it can -->
<!-- automatically reindex your data whenever you push to `gh-pages`. -->
<!--  -->
<!-- For it to work, you'll have 3 steps to perform. -->
<!--  -->
<!-- ### 1. Create a `.travis.yml` file -->
<!--  -->
<!-- Create a file named `.travis.yml` at the root of your project, with the -->
<!-- following content: -->
<!--  -->
<!-- ```yml -->
<!-- language: ruby -->
<!-- cache: bundler -->
<!-- branches: -->
<!--   only: -->
<!--     - gh-pages -->
<!-- script: -->
<!--   - bundle exec jekyll algolia push -->
<!-- rvm: -->
<!--  - 2.2 -->
<!-- ``` -->
<!--  -->
<!-- This file will be read by Travis and instruct it to fetch all dependencies -->
<!-- defined in the `Gemfile`, then run `jekyll algolia push`. This will be -->
<!-- triggered when data is pushed to the `gh-pages` branch. -->
<!--  -->
<!-- ### 2. Update your `_config.yml` file to exclude `vendor` -->
<!--  -->
<!-- Travis will download all you `Gemfile` dependencies into a directory named -->
<!-- `vendor`. You have to tell Jekyll to ignore this directory, otherwise Jekyll -->
<!-- will try to parse it (and fail). -->
<!--  -->
<!-- Doing so is easy, add the following line to your `_config.yml` file: -->
<!--  -->
<!-- ```yml -->
<!-- exclude: [vendor] -->
<!-- ``` -->
<!--  -->
<!-- ### 3. Configure Travis -->
<!--  -->
<!-- In order for Travis to be able to push data to your index on your behalf, you -->
<!-- have to give it your write API Key. This is achieved by defining an -->
<!-- `ALGOLIA_API_KEY` [environment variable][18] in Travis settings. -->
<!--  -->
<!-- You should also uncheck the "Build pull requests" option, otherwise any pull -->
<!-- request targeting `gh-pages` will trigger the reindexing. -->
<!--  -->
<!-- ![Travis Configuration][19] -->
<!--  -->
<!-- ### Done -->
<!--  -->
<!-- Commit all the changes to the files, and then push to `gh-pages`. Travis will -->
<!-- catch the event and trigger your indexing for you. You can follow the Travis job -->
<!-- execution directly on [their website][20]. -->
<!--  -->
<!-- ## FAQS -->

# Thanks

Thanks to [Anatoliy Yastreb][21] for a [great tutorial][22] on creating Jekyll
plugins.


[1]: https://badge.fury.io/rb/jekyll-algolia.svg
[2]: https://travis-ci.org/algolia/jekyll-algolia.svg?branch=master
[3]: https://coveralls.io/repos/algolia/jekyll-algolia/badge.svg?branch=master&service=github
[4]: https://codeclimate.com/github/algolia/jekyll-algolia/badges/gpa.svg
[5]: https://img.shields.io/badge/jekyll-%3E%3D%203.6.2-green.svg
[6]: https://img.shields.io/badge/ruby-%3E%3D%202.4.0-green.svg
[7]: https://pages.github.com/versions.json
[8]: http://bundler.io/
[9]: https://www.algolia.com/users/sign_up/hacker
[10]: https://www.algolia.com/licensing
[11]: http://www.methods.co.nz/asciidoc/
[12]: https://github.com/textile)
[13]: https://www.algolia.com/doc/api-reference/api-methods/set-settings/?language=ruby#set-settings
[14]: https://www.algolia.com/doc/javascript
[15]: https://github.com/algolia/hyde
[16]: https://travis-ci.org/)
[17]: https://travis-ci.org/
[18]: http://docs.travis-ci.com/user/environment-variables/
[19]: /docs/travis-settings.png
[20]: https://travis-ci.org
[21]: https://github.com/ayastreb/
[22]: https://ayastreb.me/writing-a-jekyll-plugin/
