---
title: Frequently Asked Questions
layout: content-with-menu.pug
---

# Frequently Asked Questions

## How many records will the plugin need?

The plugin will not create an exact mapping of `1 page = 1 record`. Instead, it
will split all pages into smaller chunks, and each chunk will be saved as a
record. Splitting into small chunks is key to offer the best relevance of
results.

The default chunking mechanism is to create one chunk per paragraph of content.
So, for a blog post that is made up of 10 paragraphs of text, it will create 10
records.

Estimating the number of records you will need can be tricky as it depends on
both the number of pages you have, and on the average length of them. Some
configuration options (such as [nodes_to_index][1]) can also influence the final
result.

The following table should give you a ballpark estimate of what to expect. All
calculations were done with an average of **15 paragraphs per page**, on a
timeline of **one year**.

| update frequency            | # of new pages | # of records | Algolia plan   |
| --------------------------- | -------------- | ------------ | -------------- |
| ~1 new page per week        | ~50            | ~750         | [Community][2] |
| ~1 new page per day         | ~400           | ~6.000       | [Community][3] |
| ~2 new pages per day        | ~700           | ~10.500      | [Essential][4] |
| ~1 new page per hour        | ~8800          | ~132.000     | [Essential][5] |
| ~1 new page every 5 minutes | ~105.000       | ~1.575.000   | [Plus][6]      |
| More?                       | More?          | More?        | [Business][7]  |

## One of my records is too big. What can I do?

If you get an error about one of your records being too big, be sure to update
the plugin to the latest version. We keep improving the plugin with ways of
making the records smaller.

If you're still having an error, you should check the `.json` log file that has
been created in your source directory. This will contain the content of the
record that has been rejected. It might give you hints about what went wrong.

A common cause for this issue often lies in the page HTML. Maybe the HTML is
malformed (a tag is not closed for example), or instead of several small
paragraphs there is only one large paragraph. This can cause the parser to take
the whole page content (instead of small chunks of it) to create the records.

If you don't find where the issue is coming from, feel free to open a [GitHub
issue][8] with a copy of the log file and we'll be happy to help you.

## How can I tweak the relevance ranking?

The plugin default configuration will rank results based on their textual
relevance. You can adapt the ranking to fit your needs by using a
combination of front-matter and Algolia index settings.

For example, if you know some of your blog posts are popular, you might want to
give them a boost in their ranking. To do so, add a `popular: true` entry to the
front-matter of such posts. Any custom key added to a front-matter is
automatically pushed to their corresponding records.

Then, you would have to edit your `_config.yml` file to pass a custom
`settings.customRanking` value. The `customRanking` is one of the way ranking
can be configured in an Algolia index and follows a tie-breaking algorithm. You
can find more information about the way it works either in the [official
documentation][9] or in [this video][10].

The default `customRanking` used by the plugin is [defined here][11] and use the
date, weight of the header and position in the page by default. You can
overwrite it to also take the `popular` flag into account like:

```yml
algolia:
  settings:
    customRanking:
      - desc(popular)
      - desc(date)
      - desc(custom_ranking.heading)
      - asc(custom_ranking.position)
```

This will rank popular posts matching your keywords before other posts. You can
use either boolean or numeric values for the `customRanking`.

[1]: options.html#nodes-to-index
[2]: https://www.algolia.com/pricing
[3]: https://www.algolia.com/pricing
[4]: https://www.algolia.com/pricing
[5]: https://www.algolia.com/pricing
[6]: https://www.algolia.com/pricing
[7]: https://www.algolia.com/pricing
[8]: https://github.com/algolia/jekyll-algolia/issues
[9]: https://community.algolia.com/jekyll-algolia/options.html#settings
[10]: https://www.youtube.com/watch?v=H6crAohtUBw
[11]:
  https://github.com/algolia/jekyll-algolia/blob/develop/lib/jekyll/algolia/configurator.rb#L27-L30
