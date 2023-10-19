---
layout: post
title: Disable Ubuntu ALT key moving windows - the easy way!
permalink: disable-ubuntu-alt-key-moving-windows-the-easy-way
categories:
  - Tech
tags:
  - linux
  - maya
  - modo
  - ubuntu
  - alt key
---

Because I've had to install Ubuntu a lot recently, and I always forget how to do this.

Basically by default Ubuntu binds ALT+LMB to moving windows. This is incredibly frustrating for nearly every 3D application, as this is usually the way to rotate a camera, so most people disable this shortcut.

The simplest way I've found is to run this:

```cpp
gconftool-2 --set /apps/metacity/general/mouse_button_modifier --type string '<super>'
```

which moves the key to the "Super" key (on a Windows keyboard this is the window key, on mac the CMD key).

And that's it! if you don't have gconftool-2 installed (I think it comes with Ubuntu by default, if not just install through apt-get)
