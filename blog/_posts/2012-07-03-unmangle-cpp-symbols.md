---
layout: post
title: Unmangle C++ symbols
categories:
  - Tech
tags:
  - linux
  - c++
  - unmangle
---

Not done any posting on here for a while now, mainly because I've been
state-side doing some rather exciting VFX work, all very hush hush though....

Anyway, one tool I've found immensely useful (especially in my current
project...) is unmangling those rather 'orrible C++ symbols that the linker
spits out. With g++ on linux comes c++filt, which you can pass it the mangled
function and out it comes all readable. Delightful.

For example:

```bash
c++filt _ZZ12TestFunctionEN4TestC1Ev
```

Will produce:

```
TestFunction::Test::Test()
```

Much better!
