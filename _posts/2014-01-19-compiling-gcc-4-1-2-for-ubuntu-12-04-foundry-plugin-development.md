---
layout: post
title: Compiling GCC 4.1.2 for Ubuntu 12.04 (Foundry plugin development)
permalink: compiling-gcc-4-1-2-for-ubuntu-12-04-foundry-plugin-development
categories:
  - Tech
tags:
  - gcc
  - Foundry
  - plugins
  - maya
  - modo
  - nuke
  - '4.1'
  - ubuntu
  - ubuntu 12.04
  - gcc-4.1
---

So Last year I posted about triple booting a 2011 MBP, which I can now reveal was to do with me porting [MODO to Linux](http://www.cgchannel.com/2013/03/luxology-previews-modo-for-linux/ "MODO to Linux") (which was pretty cool!). I have since moved to doing all of my development at work to Ubuntu 12.04 so had to compile and install the GCC 4.1.2 compiler, as this is the official compiler for all Foundry applications. This wasn't as straight forward as I hoped, so to save me (and anyone else) going through the same pain, here's a guide for doing just this.
<a id="more"></a><a id="more-213"></a>

# First get the right GCC and Packages

Open up a Terminal in Ubuntu, create a temp directory for doing everything in and then download the gcc tar:

```bash
mkdir /tmp/gcc
cd /tmp/gcc
wget http://ftp.gnu.org/gnu/gcc/gcc-4.1.2/gcc-4.1.2.tar.bz2
```

Next we need to untar the source into a sub-directory and create a build folder, which is where the final executable and libs will go from the build.

```bash
tar -xvjpf ./gcc-4.1.2.tar.bz2
mkdir ./build
```

Finally we need to install a few external packages in order to build gcc, which we can install using the following command:

```bash
sudo apt-get install linux-headers-$(uname -r) zlib1g zlib1g-dev zlibc gcc-multilib
```

We should now have our folder structure set, the source downloaded and un-zipped and the external packages we need installed.

# Source Changes for Ubuntu

Unbuntu made a few subtle changes that means if we try and build with the vanilla gcc source, we'll run into a few problems. Luckily it's only one change that needs to be made, in _./gcc-4.1.2/libstdc++-v3/configure_ where on line 8284 you need to change:

```bash
sed -e 's/GNU ld version \([0-9.][0-9.]*\).*/\1/'`
```

to

```bash
sed -e 's/GNU ld (GNU Binutils for Ubuntu) \([0-9.][0-9.]*\).*/\1/'`
```

GCC also requires a few libs that are in a different structure for Ubuntu. To fix this add the following symbolic links

```bash
sudo ln -s /usr/lib/x86_64-linux-gnu/crt1.o /usr/lib/crt1.o
sudo ln -s /usr/lib/x86_64-linux-gnu/crti.o /usr/lib/crti.o
sudo ln -s /usr/lib/x86_64-linux-gnu/crtn.o /usr/lib/crtn.o
```

# Compiling GCC

Now we need to run configure to build up the make file to build GCC. First go to the build directory we created earlier and run the following configure command:

```bash
mkdir /tmp/gcc412/build
../gcc-4.1.2/configure --program-suffix=-4.1 --enable-shared --enable-threads=posix --enable-checking=release --with-system-zlib --disable-libunwind-exceptions --enable-__cxa_atexit --enable-languages=c,c++ --disable-multilib
```

That should complete pretty quickly. Once that's complete, just run the following make command:

```bash
make -j 2 bootstrap MAKEINFO=makeinfo
sudo make install
```

To start compiling and install! Hopefully that'll complete without any issue, and you should be able to run "gcc-4.1" to compile with this version of gcc.
