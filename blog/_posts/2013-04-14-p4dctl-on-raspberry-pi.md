---
layout: post
title: p4dctl on Raspberry Pi
subtitle: Adding control daemon for controlling perforce server.
categories:
  - Tech
tags:
  - perforce
  - raspberry pi
  - arm
  - raspbmc
  - linux
  - debian
  - scm
---

So with perforce running on my Raspberry Pi, I now wanted to setup a service to
deal with starting, stopping and backing up my perforce server. Although I
could've just created an init.d script myself, I decided to use the open source
[p4dctl](http://public.perforce.com/wiki/P4dctl "p4dctl") to do most of the
work. The problem was that this wasn't compiled for ARM, especially not for a
hard-float ARM distro that I'm using. Here I explain how I got it built, but if
you're lazy like me I've also uploaded a copy
[here](/uploads/posts/p4dctl-on-raspberry-pi/p4dctl.zip) that you can unzip and
copy to your device.

# Getting setup to build p4dctl

First and foremost, currently perforce is only supported on ARMv4 architecture,
which means all the libraries are built for a soft-float ABI (see
[soft-float vs hard-float](http://www.memetic.org/raspbian-benchmarking-armel-vs-armhf/ "soft-vs-hard float")).
Because soft-float is forward compatible this makes sense, however you also need
to compile as soft-float. For simplicity, I had a spare SD card knocking about
so put
[Debian Wheezy soft-float version](http://www.raspberrypi.org/downloads "raspberry-pi-wheezy")
on it.

<!--more-->

Once you've Wheezy installed and running, you'll need to get a couple of
packages installed. SSH onto the device and run the following command:

```bash
sudo apt-get install g++ gcc make bison flex
```

These are the tools you'll need to build first Jam (the build system perforce
uses) and finally p4dctl itself.

# Building Jam

Ok, next step is to download and build jam, the build system of choice for
perforce's various tools. Create a dir to store the source files and download
using:

```bash
wget -r ftp://ftp.perforce.com/jam/src/
```

Next from the source folder run:

```bash
make
```

This should create a jam executable, which you can either add to your PATH, or
copy to somewhere like /usr/local/bin to be used later on.

# Building p4dctl

With jam built for ARM, it's time to build p4dctl. First download the source
code from the public perforce repository
[here](http://public.perforce.com:8080/@md=d&cd=//guest/tony_smith/perforce/p4dctl/src/&c=M2e@//guest/tony_smith/perforce/p4dctl/src/?ac=83), then
get
the [p4api](ftp://ftp.perforce.com/perforce/r13.1/bin.linux26armel/p4api.tgz "p4api") for
ARMel and untar somewhere, taking a note of the\*\* **full** path

Next change into the p4dctl source directory and type

```bash
jam -sP4=/full/path/to/perforce/api -sOSVER=26
```

which should finally get you a p4dctl executable. Remember to put the full path
to the Perforce API, otherwise it'll complain about not being able to find
headers. Also, if you get a link error something like this:

> /usr/bin/ld: failed to merge target specific data of file
> ../p4api-2013.1.610569/lib/<wbr>libsupp.a(mapchar.o)
>
> /usr/bin/ld: error: ../bin.linux26arm/p4dctl uses VFP register arguments,
> ../p4api-2013.1.610569/lib/<wbr>libp4sslstub.a(sslstub.o) does not

It's basically complaining that you're trying to link both hard-float and
soft-float libraries, which you can't do.

With p4dctl built and working, it was a simple case of copying the various cool
scripts from the p4dctl wiki to setup p4d as a proper service!
