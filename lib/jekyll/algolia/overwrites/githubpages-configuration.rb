# frozen_string_literal: true

module GitHubPages
  # The github-pages gem will automatically disable every plugin that is not in
  # the whitelist of plugins allowed by GitHub. This includes any plugin defined
  # in the `_plugins` folder as well.
  #
  # Users of the jekyll-algolia plugin will use custom plugins in _plugins to
  # define custom hooks to modify the indexing. If they happen to have the
  # github-pages gem installed at the same time, those hooks will never be
  # executed.
  #
  # Here, we overwrite the call to GitHubPages::Configuration.set that init the
  # whole plugin to actually do nothing, hence disabling the plugin completely.
  # https://github.com/github/pages-gem/blob/master/lib/github-pages.rb#L19
  #
  # This file will only be loaded when running `jekyll algolia`, so it won't
  # interfere with the regular usage of `jekyll build`
  class Configuration
    class << self
      def set(site); end
    end
  end
end
