---
title: Indexing modes
layout: content-with-menu.pug
---

# Indexing modes

Algolia's pricing model is based on the number of records you have in your index
as well as the number of add/edit/delete operations you operate on your index
per month.

By default, the plugin tries to be mindful of your quota and act in a smart way
by default: only updating records that changed between two runs.

It does so by attributing a unique `objectID` to each record, generated from the
actual content of this record. If the content changes, then the `objectID` will
change as well.

Because of this mechanism, the plugin can know which records changed between two
runs and will delete the records that are no longer needed and push the new ones
instead. Doing so only consumes a small number of operations (instead of pushing
everything each time).

When using the default `indexing_mode` value (`diff`), all those changes are
batched into one call to the API. They will be executed atomically (the index
will be updated with all the changes in one go, instead of one record at
a time). This allow users of the website to always search into the most
up-to-date version of the data.

This should work for 99% of the use-cases and you shouldn't need to change the
value of the `indexing_mode`.


## `diff` (default)

Using the default `diff` mode, the plugin will try to be smart when pushing
content to your index: it will only add/edit/delete what changed. All
records that didn't change will stay untouched.

To do so, it first grabs the list of all records in your index, then compares
them with the records generated locally. It then deletes the old records that no
longer exists, and add the newly created ones. 

There is no notion of "updating" a record here because as soon as the content of
a record changes, it will be considered as a new record (thus, the old version
will be deleted and the new one will be added).

### Cons

All operations will be done on the same index, sequentially. Old records will
first be discarded, then new ones will be added. Users doing a search on your
website during the update will have inconsistent or incomplete results.

## `atomic`

The `atomic` mode solves the inconsistency issue of the `diff` mode. Instead of
doing all changes in sequence on the same index, the updates will be done on
a temporary index in the background.

The plugin will start by making a copy of the existing data, and will then apply
the `diff` method to it: it will remove old records and add new ones to this
index. While those changes are applied, your current index is still serving
search queries by your users. Once all changes are applied, the plugin will
replace the current public index with the temporary one, all in one atomic move.

### Cons

As this method will need to create a copy of your current index during indexing,
it means you will need an Algolia plan that can hold at least **twice** the
number of records.
