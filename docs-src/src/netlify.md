---
title: Deploying on Netlify
layout: content-with-menu.pug
---

# Deploying on Netlify

Netlify is our recommend way to host static websites. Each time you push your
content to your repository, it will build your website and host it.

It takes care of all the building and hosting for you, and you can even run
custom commands (like `jekyll algolia`) as part of the build process.


## Enabling Netlify

To enable Netlify automatic deploy for your Jekyll project, follow those steps:

- Go to [netlify.com][1] and open an account
- Click on "New site from Git" and pick your repository from the list
- Select which branch should be deployed

## Configuring Netlify

Netlify UI will suggest a command to run and a website to serve by default.  We
recommend instead to create a file named `netlify.toml` at the root of your
repository. Having all configuration stored in a local file instead of a web UI
will make its management easier.

```toml
# netlify.toml
# This file should be at the root of your project
[build]
  command = "jekyll build && jekyll algolia"
  publish = "_site"
```

This file will be read by Netlify on each push to your repo. Because you have
a `Gemfile` in your project, Netlify will automatically detect that it's a Ruby
project and will setup Bundler for you.

It will then run the defined `command`, building the website and then pushing
records to Algolia. Once done, the directory specified in `publish` will be
deployed and publicly available.

## Specifying the Ruby version

By default Netlify uses Ruby v2.1.2. This version is not compatible with the
`jekyll-algolia`.

To fix this, you'll have to add a file named `.ruby-version` at the root of your
repository. The file content should be `2.4`. It will be picked up by Netlify
and used as the local Ruby version.

```config
# .ruby-version
# This file should be at the root of your project
# Don't forget to remove those comments!
2.4
```

## Adding the API Key

The plugin will need your Admin API key to push data. Because you don't want to
expose this key in your repository, you'll have to add `ALGOLIA_API_KEY` as an
environment variable to Netlify. You can do that through the UI, in your Netlify
Settings page.

![Netlify environment variables][2]

## Done

Commit all the changes you made, and then push your repository. Netlify will
catch the event and trigger your build and indexing for you. You can follow the
Netlify job execution directly on your Netlify dashboard, with a full log.


[1]: https://www.netlify.com/
[2]: ./assets/images/netlify-env.png
