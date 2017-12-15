---
title: Command line
layout: content-with-menu.pug
---

# Commandline

List of all the commandline arguments that can be passed to the plugin and what
they do. Includes ENV variables as well.



## Arguments

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


## Environment variables

The recommended place to store your Algolia application ID and index name are in
the `_config.yml` file but there are a few environment variables your can define
to overwrite those values.

key                    | value
---------------------- | ----------------------
ALGOLIA_APPLICATION_ID | `your_application_id`
ALGOLIA_API_KEY        | `your_api_key`
ALGOLIA_INDEX_NAME     | `your_index_name`


## `_algolia_api_key` file

The recommended way to define your Algolia admin API key is to use the
`ALGOLIA_API_KEY` environment variable. Because this key should be kept secret,
its better if it's loaded directly from the environment.

But the plugin can also load the key from another source. **Note that this
method trades off security for convenience, so be very careful when using it.**

You can create a file named `_algolia_api_key` in your source directory that
contains your admin API key. If no `ALGOLIA_API_KEY` environment variable is
defined, the plugin will fallback to the value set in the `_algolia_api_key`
file.

**Do not commit this file in your versioning system**. This API key has write
access to your index, so you have to keep it secret. For example, you should
add `_algolia_api_key` to your `.gitignore` file. It contains your private API
key





