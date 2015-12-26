---
layout: post
title: Turning off Thirdparty include warnings
categories:
- Tech
tags:
- includes
- warnings
- gcc
- visual studio
- annoyances
---
Love it or hate it, compiler warnings are there to try and tell you that you're doing something silly, and you should fix it even though it's not the end of the world. The most annoying thing I've found recently is when you use someone else's code and find that there's loads of warnings. Things like boost and Qt can have loads of warnings, and as tempting as it is to fix them locally, it then becomes a bit of a nightmare when updating the library, as well as some being rather difficult to fix.

One useful thing that you can do on Linux or OSX/Mac with gcc is change the way you add include paths. Rather than doing this:

```bash
gcc -I #Some/Include/Path ...
```

you can do this

```bash
gcc -isystem #Some/Include/Path ...
```

and the gcc compiler will stop spewing out warnings for files within this include directory! Snazzy

The same can't be said in Windows land and Visual Studio. As far as I know (_PLEASE_ someone tell me otherwise!) the only way to do the same kind of thing is to use #pragma's around the #include, as follows:

```cpp
#pragma warning( push, 0 )
#include "Some/Include/Header.h"
#pragma warning( pop )
```

This sets the warning level to 0 whilst including the header, and then restores to whatever it was before. (FYI: this doesn't turn off **all** warnings, as VS in their infinite wisdom don't allow you to disable some, esp. linker warnings)

Really wish VS would add an equivalient -Isystem for the compiler, as I don't really like having to put pragmas all over my code, and isn't very cross-platform friendly...

Anyway, hopefully this helps get you back to the joys of warning free compiling, and get warnings as errors turned on!
