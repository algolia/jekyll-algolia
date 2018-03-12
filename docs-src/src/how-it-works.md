---
title: How does this work?
layout: content-with-menu.pug
---

# How does this work?

This page will give you a bit more insight about how the internals of the plugin
are working. This should give you more context to better understand the various
options you can configure.

## Extracting data

The plugin will work like a `jekyll build` run, but instead of writing `.html`
files to disk, it will push content to Algolia. It will go through each file
Jekyll would have processed in a regular build: pages, posts and collections.

It will not push the whole content of each page to Algolia as one record.
Instead, it will split each page into small chunks (by default, one per
`<p>` paragraph) and then push each chunk as a new record to Algolia. Splitting
records that way allows for a more fine-tuned relevance even on long pages.

Here is an example of what a record looks like:

```json
{
  "objectID": "e2dd8dd1eaaf961baa6da4de309628e9",
  "title": "New experimental version of Hacker News Search built with Algolia",
  "type": "post",
  "url": "/2015/01/12/try-new-experimental-version-hn-search.html",
  "draft": false,
  "layout": "post",
  "ext": ".md",
  "date": 1421017200,
  "excerpt_html": "<p>Exactly a year ago, we began to power […]</p>",
  "excerpt_text": "Exactly a year ago, we began to power […]",
  "slug": "try-new-experimental-version-hn-search",

  "html": "<p>We've learned a lot from your comments […]</p>",
  "content": "We've learned a lot from your comments […]",
  "tag_name": "p",
  "hierarchy": {
    "lvl0": null,
    "lvl1": "Applying more UI best practices",
    "lvl2": "Focus on readability",
  },
  "anchor": "focus-on-readability",
  "custom_ranking": {
    "position": 8,
    "heading": 70
  }
}
```

Each record created that way will contain a mix of shared data and specific
data. Shared data is the metadata of the page it was extracted from (`title`,
`slug`, `url`, `tags`, etc, as well as any custom field added to the
front-matter). Specific data is the paragraph content, and information
about its position in the page (where its situated in the hierarchy of headings
in the page).

Using the [distinct setting][1] of the Algolia API, only the best matching
paragraph of each page is returned for a specific query. This greatly improves
the perceived relevance of the search results as you can highlight specifically
the part that was matching.

## Pushing data

The plugin tries to be smart by using as less operations as possible, to be
mindful of your Algolia quota. Whenever you run `jekyll algolia`, only records
that changed since your last push will be updated.

This is made possible because each record is attributed a unique `objectID`,
computed as a hash of the actual content of the record. Whenever the content of
the record changes, its `objectID` will change as well. This allows us to compare
what is current available in your index and what is about to be pushed, to only
update what actually changed.

Previous outdated records will be deleted, and new updated records will be added
instead. All those operations are grouped into a batch call, making sure that
the changes are done atomically: your index will never be in an inconsistent
state where records are only partially updated.

[1]: https://www.algolia.com/doc/guides/ranking/distinct/?language=ruby#distinct-to-index-large-records
