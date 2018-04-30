---
title: Frequently Asked Questions
layout: content-with-menu.pug
---

# Frequently Asked Questions

## How many records will the plugin need?

The plugin will not create an exact mapping of `1 page = 1 record`. Instead, it
will split all pages into smaller chunks, and each chunk will be saved as
a record. Splitting in small chunks is key to offer the best relevance of
results.

The default chunking mechanism is to create one chunk per paragraphof content.
So, for a blog post that is made of 10 paragraphs of text, it will create 10
records.

Estimating the number of records you will need can be tricky as it depends both
on the number of pages you have, but also on the average length of them.  Some
configuration options (such as [nodes_to_index][1]) can also influence the final
result.

The following table should give you a ballpark estimate of what to expect. All
calculations were done with an average of **15 paragraphs per page**, on
a timeline of **one year**.

| update frequency               | # of new pages | # of records | Algolia plan |
| ------------------------------ | -------------- | ------------ | ------------ |
| ~1 new page per week           | ~50            | ~750         | [Community][2] |
| ~1 new page per day            | ~400           | ~6.000       | [Community][3] |
| ~2 new pages per day           | ~700           | ~10.500      | [Essential][4] |
| ~1 new page per hour           | ~8800          | ~132.000     | [Essential][5] |
| ~1 new page every 5 minutes    | ~105.000       | ~1.575.000   | [Plus][6]      |
| More?                          | More?          | More?        | [Business][7]  |

## One of my records is too big. What can I do?

If you get an error about one of your record being too big, be sure to update
the plugin to the latest version. We keep improving the plugin with ways of
making the records smaller.

If you're still having an error, you should check the `.json` log file that has
been created in your source directory. This will contain the content of the
record that has been rejected. It might give you hints about what went wrong.

A common cause for this issue often liens in the page HTML. Maybe the HTML is
malformed (a tag is not closed for example), or instead of several small
paragraphs there is only one large paragraph. This can cause the parser to take
the whole page content (instead of small chunks of it) to create the
records.

If you don't find where the issue is coming from, feel free to open a [GitHub
issue][8] with a copy of the log file and we'll be happy to help you.


[1]: options.html#nodes-to-index
[2]: https://www.algolia.com/pricing
[3]: https://www.algolia.com/pricing
[4]: https://www.algolia.com/pricing
[5]: https://www.algolia.com/pricing
[6]: https://www.algolia.com/pricing
[7]: https://www.algolia.com/pricing
[8]: https://github.com/algolia/jekyll-algolia/issues
