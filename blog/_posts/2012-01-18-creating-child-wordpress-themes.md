---
layout: post
title: Creating Child Wordpress Themes
categories:
  - Tech
tags:
  - Wordpress
  - child themes
  - CSS
---

Wordpress is great, I'm a huge fan of how simple it is to install and get setup.
However, once it is setup, getting a theme that works for you is a little more
tricky. For me this meant that after a joyous 10min installation, I then spent
the best part of a day firstly trying to find a theme I liked, and eventually
giving up and simply customising the default
[twentyeleven](http://theme.wordpress.com/themes/twentyeleven/) theme that comes
with Wordpress.

This was actually surprisingly easy even with my limited CSS and HTML experience
using the joy that is <a href="http://codex.wordpress.org/Child_Themes">Child
Themes</a>. Using child themes allow you to customise any theme without changing
it directly, meaning you can get updates and fixes without affecting the
customisations you've made, which is pretty cool

<!--more-->

# Step 1: Setup your style.css

Create a folder for your theme and within this, create your style.css. Then
stuff this at the top of it:

```css
/*
Theme Name: Theme Name
Theme URI: http://www.themeURI.com
Author: Your Name
Author URI: http://author.com
Description: twentyeleven child theme
Template: twentyeleven
Version: 0.1
*/
```

The most important line here is the `Template: twentyeleven` line, which tells
wordpress which theme to use as the parent. Now add the following line to import
all the settings from twentyeleven.

```
@import url("../twentyeleven/style.css");
```

This is all you need to have a child theme which is identical to the parent. You
can zip up this folder and install on your blog like any other theme.

# Customising the Style

Now that we have the basics sorted, let's start customizing the style. The first
thing I wanted to change the width when in one-column mode. Searching through
the twentyeleven css, I found this:

```css
.one-column #page {
max-width: 680px;
}
```

to change this in the child template, simply copy this into your style.css
(after the import line) and change it to what you want. This will then overwrite
it to what you want it to be. Simple!

Next I wanted to change the post content font to be smaller. Thought a bit more
involved, adding this to my style sheet did the trick:

```css
.entry-content p {
font-size: 12px;
}
```

You get the idea. Simply putting in your style.css anything you want to be
different will make the change, without having to modify the original theme.

# Changing Functions

You can also add/modify any functions inside the Functions.php file by creating
a new file *of the same name* within the child theme. It's important to note
that this doesn't _replace_ the original, but is loaded _as well as_ the
original, and second. This means that say I want the header image height to be
smaller, all I have to add to my functions.php is:

```php
<?php
    define( 'HEADER_IMAGE_HEIGHT', apply_filters( 'twentyeleven_header_image_height', 200 ) );
?>
```

# Customising the page templates

The final thing you can do in child pages is modify the original page templates.
This is a simple case of copying the original from the theme, making the
appropriate changes and saving in the same place in the child theme folder. For
me, I wanted rather than my blog name to be in text above my header picture to
be an overlay, using the magic of CSS. By following
[this guide](http://css-tricks.com/3118-text-blocks-over-image/) I added the
following to my header.php:

```html
<div class="headerimage">
    <img src="<?php header_image(); ?>" width="<?php echo HEADER_IMAGE_WIDTH; ?>" height="<?php echo HEADER_IMAGE_HEIGHT; ?>" alt="" /></p>
    <h1><a href="<?php echo esc_url( home_url( '/' ) ); ?>" title="<?php echo esc_attr( get_bloginfo( 'name', 'display' ) ); ?>" rel="home"><?php bloginfo( 'name' ); ?></a></h1>
</div>
```

And then this into the CSS:

```css
.headerimage {
    position: relative;
    width: 100%; /* for IE 6 */
}

.headerimage h1 {
    position: absolute;
    top: 140px;
    left: 15px;
    width: 100%;
}

.headerimage h1 a {
    color: white;
    background: rgb(0, 0, 0); /* fallback color */
    background: rgba(0, 0, 0, 0.7);
    padding: 10px 10px 10px 5px;
    font-size: 40px;
    font-weight: bold;
    line-height: 36px;
    text-decoration: none;
}
```

It's not perfect, but you get the idea. And that's about it. There's plenty more
you can do with child templates, but this was enough to get something I was
happy with. If you want to see what I ended up with, I've uploaded the theme I
created [here](/uploads/posts/creating-child-wordpress-themes/tomward.zip)
