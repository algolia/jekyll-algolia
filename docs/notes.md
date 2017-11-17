## Custom hooks


    def self.hook_should_be_excluded?(_filepath)
    def self.hook_before_indexing_each(record, _node)
    def self.hook_before_indexing_all(records)

## Command line

Here is the list of command line options you can pass to the `jekyll algolia
push` command:

| Flag                     | Description                                                           |
| ----                     | -----                                                                 |
| `--config ./_config.yml` | You can here specify the config file to use. Default is `_config.yml` |
| `--future`               | With this flag, the command will also index posts with a future date  |
| `--limit_posts 10`       | Limits the number of posts to parse and index                         |
| `--drafts`               | Index drafts in the `_drafts` folder as well                          |
| `--dry-run` or `-n`      | Do a dry run, do not actually push anything to your index             |
| `--verbose`              | Display more information about what is going to be indexed            |


## Searching

This plugin will index your data in your Algolia index. Building the front-end
search is of the scope of this plugin, but you can follow [our tutorials][1] or
use our forked version of the popular [Hyde theme][2].

## GitHub Pages

The initial goal of the plugin was to allow anyone to have access to great
search, even on a static website hosted on GitHub pages.

But GitHub does not allow custom plugins to be run on GitHub Pages.
This means that you'll either have to run `bundle exec jekyll algolia push`
manually, or configure a CI environment (like [Travis][3] to do it for you.

[Travis CI][4] is an hosted continuous integration
service, and it's free for open-source projects. Properly configured, it can
automatically reindex your data whenever you push to `gh-pages`.

For it to work, you'll have 3 steps to perform.

### 1. Create a `.travis.yml` file

Create a file named `.travis.yml` at the root of your project, with the
following content:

```yml
language: ruby
cache: bundler
branches:
  only:
    - gh-pages
script:
  - bundle exec jekyll algolia push
rvm:
 - 2.2
```

This file will be read by Travis and instruct it to fetch all dependencies
defined in the `Gemfile`, then run `jekyll algolia push`. This will be
triggered when data is pushed to the `gh-pages` branch.

### 2. Update your `_config.yml` file to exclude `vendor`

Travis will download all you `Gemfile` dependencies into a directory named
`vendor`. You have to tell Jekyll to ignore this directory, otherwise Jekyll
will try to parse it (and fail).

Doing so is easy, add the following line to your `_config.yml` file:

```yml
exclude: [vendor]
```

### 3. Configure Travis

In order for Travis to be able to push data to your index on your behalf, you
have to give it your write API Key. This is achieved by defining an
`ALGOLIA_API_KEY` [environment variable][5] in Travis settings.

You should also uncheck the "Build pull requests" option, otherwise any pull
request targeting `gh-pages` will trigger the reindexing.

![Travis Configuration][6]

### Done

Commit all the changes to the files, and then push to `gh-pages`. Travis will
catch the event and trigger your indexing for you. You can follow the Travis job
execution directly on [their website][7].

## FAQS


[1]: https://www.algolia.com/doc/javascript
[2]: https://github.com/algolia/hyde
[3]: https://travis-ci.org/
[4]: https://travis-ci.org/
[5]: http://docs.travis-ci.com/user/environment-variables/
[6]: /docs/travis-settings.png
[7]: https://travis-ci.org
