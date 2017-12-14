---
title: How does this work?
layout: content-with-menu.pug
---

## How does this work?

The plugin will work like a `jekyll build` run, but instead of writing `.html`
files to disk, it will push content to Algolia. It will go through each file
Jekyll would have processed in a regular build: pages, posts and collections.

It will not push the whole content of each page to Algolia as one record.
Instead, it will split each page into small chunks (by default, one per
`<p>` paragraph) and then push each chunk as a new record to Algolia. Splitting
records that way allows for a more fine-tuned relevance even on long pages.

Each record created that way will contain a mix of specific data and shared
data. Specific data will be the paragraph content, and information about its
position in the page (where its situated in the hierarchy of headings in the
page). Shared data is the metadata of the page it was extracted from (`slug`,
`url`, `tags`, etc, as well as any custom field added to the front-matter).

Once displayed, results are grouped so only the best matching paragraph of each
page is returned for a specific query. This greatly improves the perceived
relevance of the search results.

Because the plugin is splitting each page into smaller chunks, it can be hard to get
an estimate of how many records will actually be pushed. The plugin tries to be
smart and consume as less operations as possible, but you can always run it in
`--dry-run` mode to better understand what it would do.

