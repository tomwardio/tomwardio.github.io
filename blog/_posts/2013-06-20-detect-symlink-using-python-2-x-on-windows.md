---
layout: post
title: Detect Symlink using Python 2.x on Windows
subtitle: Fix for detecting symlinks on Python for Windows.
permalink: /blog/detect-symlink-using-python-2-x-on-windows/
categories:
  - Tech
tags:
  - windows
  - python
  - symlink
  - python 2.7
---

Just a quick one today, spent today automating the creation of a VS project for
the product I'm working on (which uses a custom build system) and found myself
needing to detect if a directory is a symlink on Windows. Python does provide a
function `os.path.islink(dirPath)` but annoyingly on Python 2.x this always
returns false for Windows symlinks. Great!

So here's a working version of the function that I put together using ctypes:

```python
import os, ctypes
def IsSymlink(path):
    FILE_ATTRIBUTE_REPARSE_POINT = 0x0400

    if os.path.isdir(path) and \
        (ctypes.windll.kernel32.GetFileAttributesW(unicode(path)) & FILE_ATTRIBUTE_REPARSE_POINT):
    return True
    else:
    return False
```

Hopefully that saves someone the hassle of finding how to do this
