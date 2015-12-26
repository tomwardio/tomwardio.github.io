---
layout: post
title: Incremental Linking and Embedding Manifests
categories:
- Tech
tags:
- visual studio
- Incremental linking
- manifest
- msvc
---
Working on a project that needs to support multiple target platforms and therefore multiple development environments is always difficult. Inevitably the best approach is to use a platform agnostic build solution (such as [Make](http://www.gnu.org/software/make/), [SCons](http://www.scons.org/), [CMake](http://www.cmake.org/) etc) to wrap up how each development environment actually goes about building and linking the product.

However, this then means that you're now given the responsibility of managing the manifest file, which you're [recommended to embed into your project's output](http://msdn.microsoft.com/en-us/library/ms235591%28v=vs.80%29.aspx). There's two approaches to do this. The first is to simply run mt.exe, passing in the manifest generated during the link stage.

```
> mt.exe -manifest MyApp.exe.manifest -outputresource:MyApp.exe;1
```

Although simple, this then prevents incremental linking from running, because running mt.exe on the link output means that the next time you link, it detects a change that it doesn't know about and instead does a full link

> xxxx not found or not built by the last incremental link;
> performing full link

One way round this is to simply make a copy of the output and then run mt on this, but that means copying and embedding the manifest everytime you compile, not ideal! There is another way, and it's the way Microsoft do it when using Visual Studio

# How does Visual Studio do it?

As discussed [here](http://msdn.microsoft.com/en-us/library/ms235229%28v=vs.80%29.aspx), Visual Studio embeds the manifest as a resource at link time, rather than performing the embedding after the link stage. This is achieved by:

1. After the compile stage has completed an initial link is done and, using the intermediate compilation objects a manifest is built.
2. Using the manifest generated, a resource is built containing the manifest. This is done using the command line rc.exe tool
3. A second link is performed, which adds the newly created manifest resource into the output. As it's compiled again using the linker (rather than mt), this keeps incremental linking working as expected
4. Any subsequent links now uses the previous build's manifest, only performing the second link when the manifest resource changes

# Replicating Visual Studio Incremental Linking

1. Run an initial link with the /MANIFEST flag set, so that we create a new manifest from the compilation units

    ```
    link.exe /OUT:HelloWorld.exe /INCREMENTAL /MANIFEST "/manifestfile:HelloWorld.manifest"  

    helloWorld.obj
    ```

2. Next, create a new file res file with the following in:

    ```c
    #include "winuser.h"  

    1 RT_MANIFEST <manifestfilepath.manifest></manifestfilepath.manifest>
    ```

    NB: The number at the beginning should be 1 for executables, and 2 for dlls

3. Next, run rc.exe with this as the input to create a resource file to embed

    ```
    rc.exe <path_to_res_file>manifest.rc</path_to_res_file>
    ```

4. Now run the same link command as above, but including the newly created resource in the command

    ```
    > link.exe /OUT:HelloWorld.exe /INCREMENTAL /MANIFEST "/manifestfile:HelloWorld.manifest"  

    > helloWorld.obj **manifest.rc**
    ```

In subsequent builds, add the previous build's resource into the first link command,and then compare the newly generated manifest file with the previous builds and, if different, follow the steps above to do a relink.

Although a bit more involved, this way of embedding manifests keeps incremental linking working, and should be relatively simple to add to a build system for those Windows developers.
