---
layout: post
title: Running Perforce server on Raspberry Pi
subtitle: Tutorial for getting perforce running on Rasbian.
header-img: uploads/posts/running-perforce-server-on-raspberry-pi/background.jpg
categories:
  - Tech
tags:
  - perforce
  - raspberry pi
  - arm
  - raspbmc
  - linux
  - ld-linux.so.3
---

Although I've used SVN and to a lesser extent CVS before, my fave source control
tool has to be perforce. I used it heavily at EA and have started to use it at
The Foundry for one of the products I'm working on, and frankly I think it's
great.

I also recently bought a Raspberry Pi, and thought I'd give it a go trying to
migrate my Perforce server from an Amazon EC2 server to my Pi, and save the $10
or so it costs a year to store things in the cloud.

First things first, I had to find out if Perforce was supported on ARM chips.
Luckily I found that although unofficial, they do seem to have LinuxARM builds
on their FTP!
[ftp://ftp.perforce.com/perforce/r12.1/bin.linux26armel/](ftp://ftp.perforce.com/perforce/r12.1/bin.linux26armel/ "ftp://ftp.perforce.com/perforce/r12.1/bin.linux26armel/")

So I uploaded the p4 binary I found to my pi, made it executable
(`chmod a+x p4d`) only to get the following error when running:

```bash
pi@raspbmc:~$ ./p4
-bash: ./p4: No such file or directory
```

Not the most useful error message in the world, but with a bit of googling I
managed to figure out that basically the binary was trying to load a library
that it couldn't find. By running the following command:

```bash
eu-readelf --program-headers p4
```

on the binary (I got this program by installing elfutils using _sudo apt-get
install elfutils_) I found it needed _/lib/ld-linux.so.3_. I fixed this by
simply creating a symlink to the one on my system with the following command:

```bash
sudo ln -s /lib/ld-linux-armhf.so.3 /lib/ld-linux.so.3
```

Once I'd done that I could happily run not only the client but also the server,
which was pretty neat!

Hope this helps
