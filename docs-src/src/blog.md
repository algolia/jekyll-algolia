---
title: Blog search
layout: content-with-menu.pug
---

# Blog search

The default Jekyll theme ([minima][1] is perfect for writing a blog. Let's see how
to edit this theme to allow searching into all the posts.

This tutorial will be focused on the front-end part, and assumes that you
already have pushed all your data, following our [getting started][2] guide.

![Search in the minima theme](./assets/img/minima-search.gif)



Explanation of how to search into a blog. Examples will be given using common
themes. I could use the Hyde theme as a great use-case and show how to implement
it with InstantSearch.js.


This will be the simplest example. How to add search to Jekyll blog. We'll use
the default minima theme as an example.

We'll change the front page. Instead of displaying the list of topics, it will
display a searchable list (and we'll add an excerpt for good measure).

Because I'm editing a pre-pakaged theme, the first thing to do is to copu the
files from the theme to my locl jekyll section. I take the posts layout, to
change the display of the full page

Then, we will add the files needed by Algolia. The IS js file, as well as two
CSS files to style it. The first one provides just "usable" default, the second
one provides some theming that happen to be similar to the one of minima. great

We will start by configuring the call and instanciating. We'll need to reuse
some of our credentials, so we can have them directly from the config.yml file

We'll also need a earch only API key. This one is a public key, that can only
read the idnex (not edit stuff). It's safe to put it in the markup. Just to stay
consustent, I'll put it along with the other keys, to have all my credentials at
the same place, ut it's not officially part of the plugin. you can name it the
way your want

Now that we have that, well it does not do much. What we'll do is add the
results to be displayed, and adding our first widget

the moment the widget is instanciates, it will replace its target with the
result grabbed from the index. we will put the target to where the list is
already displayed. it means that on page load, everything will be here, but then
the js lib will kick in and replace static results with dynamic one

at that point it works but its too raw. we'll add a template so it looks exactly
like the static version. we re-use the same kind of markup, but we might have to
do a few adjustements.

the original version had no excerpt, but we'll add it (both to the static and
dynamic one, so there is no "jump" from one to the other). we'll also have to
add some margin around the elements and rpelace it with divs. instantsearch adds
divs by default, and divs inside ul won't work so we change things around

looks the same. Now we had search, buy adding a search bar, defining its
placeholder and width

works well, but we have some display issues we should fix. inside the template
function we'll change a few values. the date should be formatted using moment,
and the results should be highlighted with what is matching




- Copy file form minima
- Include algolia.html where we put everything
- include JS and CSS
- instanciate the instance with credentials
- add dynamic results
- style results so they look the same
- add excerpt to both sides, format the date
- add search bar
- add highlight on results


[1]: https://github.com/jekyll/minima)
[2]: ./getting-started.html
