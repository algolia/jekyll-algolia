---
title: Deploying on Netlify
layout: content-with-menu.pug
---

# Deploying on Netlify

Go on Netlify, add site.

Add a netlify.toml (or update through UI). Add jekyll build && jekyll algolia
Netlify takes care of using bundle if detects a Gemfile
But runs with ruby 2.1.2, not compatible with the plugin.
Add a .ruby-version containing 2.4 to change the version
