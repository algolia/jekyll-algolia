---
title: Indexing modes
layout: content-with-menu.pug
---

# Indexing modes

Algolia's pricing model is based on the number of records you have in your index
as well as the number of add/edit/delete operations you operate on your index
per month.

The plugin tries to be mindful of your quotaes and act in a smart way by
default: only updating records if they changed.

Because of the nature of Jekyll (having no state, regenerating everything on
each build), doing a sync between local data and remote index requires some
assumptions, and comes with a some drawbacks.

This page will list the different `indexing_modes` that can be configured,
explaining their pros and cons so you can pick the one that best suits your
needs.

## `diff` (default)

Using the default `diff` mode, the plugin will try to be smart when pushing
content to your index: it will delete the old records and add new ones. All
records that didn't change will stay untouched.

To do so, it first grabs the list of all records in your index, then compares
them with the records generated locally. It then deletes the old records that no
longer exists, and add the newly created ones.

### Pros

It will consume a small number of **operations** on your Algolia quota. Only
changed content will be updated, the rest will be untouched.

### Cons

All operations will be done on the same index, sequentially. Old records will
first be discarded, then new ones will be added. Users doing a search on your
website during the update will have inconsistent or incomplete results

## `atomic`

The `atomic` mode solves the inconsistency issue of the `diff` mode. Instead of
doing all changes in sequence on the same index, the updates will be done on
a temporary index in the background.

The plugin will push all records to a temporary index. Once everything is
pushed, it will replace the current index with the temporary one in one atomic
move.

### Pros

The moment the update is finished, all the users now search into the new version
of your data. Users either search into the old version, or the new version, but
never in an inconsistent state that was a mix of both.

### Cons

It consumes a lot of **operations** as the plugin actually pushes **all**
records to a temporary index on each call. It also requires that you have a plan
that can hold **twice the number of records**: during the update you'll have
both the old index and the temporary one on your account.

