---
title: Hooks
layout: content-with-menu.pug
---

# Hooks

Explanation of what the hooks can do: give more control diretcly in ruby. Make
a list of what can be done, then explain each hook and how it works




## Custom hooks


    ```ruby
    def self.hook_should_be_excluded?(_filepath)
    def self.hook_before_indexing_each(record, _node)
    def self.hook_before_indexing_all(records)
    ```
