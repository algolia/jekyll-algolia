---
title: Indexing modes
layout: content-with-menu.pug
---

# Indexing modes

Several ways to skin a cat, so show different ways of indexing. We want to be
mindful of people quotas. 

- atomic: push everything to a new index
- diff: pushes the difference
- atomic-diff: Makes a copy of the current index, then do a diff on it, and
  replace it

Show pros and cons of each



Synchronizing your local data with your Algolia index can be done in different
ways. By default, the plugin will use the `diff` indexing mode but you might
also be interested in the `atomic` mode.

#### `diff` (default)

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

#### `atomic`

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








