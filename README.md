# Algolia Jekyll Plugin

Jekyll plugin to automatically index your Jekyll posts and pages into your
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

