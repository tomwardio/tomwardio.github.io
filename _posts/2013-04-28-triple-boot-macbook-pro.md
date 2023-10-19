---
layout: post
title: Triple-boot Macbook Pro
subtitle: Installing OSX, Windows 7 and Redhat.
permalink: triple-boot-macbook-pro
categories:
  - Tech
tags:
  - refit
  - triple-boot
  - osx
  - rhel
  - windows
  - tripleboot
  - mbr
  - macbook
  - mbp
---

For the past year I've been working on porting [modo](http://www.luxology.com/modo/ "modo") to Linux, which involved me having to do lots of fun filled tests on both OSX and Windows, as well as having to haul a machine to/from America in order to work with the dev team out in Mountain View. After much messing about this week, I finally got my 2011 MBP triple-booting all three platforms correctly! So that I can remember how to do it again, here's what I did

The key to all of this is partition management, followed by MBR magic. A lot of what follows was what I could piece together from various blogs and posts, or some good old fashioned trial-and-error

Firstly, this is completely from scratch with a fresh 1TB drive, and using a Macbook Pro from late 2011. The three distros I've gone for are OSX Mountain Lion, RHEL 6.4 and Windows 7. YMMV with newer macbooks and different distros...<a id="more"></a><a id="more-160"></a>

# First: Install Mountain Lion

Create a bootable USB stick with Mountain Lion (google is your friend here!) and follow the usual instructions. Nothing special here, and you should end up with a lovely and fresh ML installation. That was easy huh?!

# Second: Move that pesky Recovery Partition

For reasons that I'd like to say are to do with the [MBR](http://en.wikipedia.org/wiki/Master_boot_record) but don't really know, You need to have the three OS's that you want to boot in the first three partitions of your drive after the hidden EFI boot partition. Unfortunately ML creates a hidden recovery partition at the end of your ML installation that buggers this up. Therefore, first thing to do is to move it to the end of the drive, which you can do with OSX's "Disk Utility"
1\. Set the debug flag so that you can see hidden partitions in OSX. To do this, load Terminal and type the following:

```bash
defaults write com.apple.DiskUtility DUDebugMenuEnabled 1
```

Now load Disk Utility, and you should see a debug menu option. Select "Show every partition" to see all partitions on your disk.

2\. Select the OSX hard drive and goto the partition tab. You now basically need to create a partition at the end of your drive at least 1gb in size. The way I did this was to create one massive partition that fills the drive up to 1gb before the end (this we're going to split up later anyway) then create the new recovery partition.

3\. With the partitions created, select the old "Recovery HD" partition in the list on the left and click "mount". Now select the newly mounted Recovery HD and select the "Restore" tab on the right. Drag the new partition to the destination and hit "Restore".

4\. You'll now want to remove the old Recovery partition and the temp partition we created previously, however annoyingly Disk Utility doesn't let you remove them. Time to install [gdisk](http://www.rodsbooks.com/gdisk/)! Once you have that installed, go to Terminal and (assuming your device is disk0) type:

```bash
sudo gdisk /dev/disk0
```

You should then be able to delete the recovery and temp partitions, and still have the Recovery HD at the end.

# Creating the Partitions

You'll now need to create **3** new partitions in Disk Utility. The first is going to be your Linux partition, so size appropriately (don't worry about what type, it'll get reformatted during install anyway) next will be your Windows partition, and the final one a SWAP partition for Linux. I create my OSX, Windows and Linux partitions to be 330GB each, with a SWAP size of just shy of 9GB, but that's me. For clarity's sake, here's my partition table in gdisk:

```
Number Start (sector) End (sector) Size Code Name
1 40 409639 200.0 MiB EF00 EFI System Partition
2 409640 644940887 307.3 GiB AF00 OSX
3 645203968 1289734143 307.3 GiB EF00 RHEL
4 1289734144 1934262271 307.3 GiB EF00 WINDOWS7
5 1934262272 1950595071 7.8 GiB 8200 SWAP
6 1950595440 1953525127 1.4 GiB AB00 Recovery
```

# Install rEFIt

Next, you'll need a way to boot into Windows/Linux/OSX once it's all setup, so I now installed [rEFIt](http://refit.sourceforge.net/) to do this (I did try [rEFInd](http://www.rodsbooks.com/refind/), but found I needed to use reFit's partition syncing to get Windows **and** Linux to boot, so reverted to reFit in the end). This should be pretty straight forward, and once done you should reboot to check it all works.

# Install Windows

This is important. INSTALL WINDOWS FIRST! I tried twice to do Linux and then Windows and ended up corrupting the Windows partition. I don't know why it does this, but it does. Stick your Windows 7 disk into your macbook, and whilst it boots up hold down "c" to make your laptop boot from the CD. Install Windows as usual, **making sure to install to the correct partition**. Also be careful not to resize of create any other partitions, just select and format to NTFS.

# Install RHEL

With Windows installed and running, stick in your RHEL disk, reboot and again hold down the "c" key to make it boot from the CD. Again start going through the install process, selecting the Linux partition you created earlier for the root drive, and the swap partition created earlier as your swap partition. **Be careful not to install the bootloader to the MBR!** When you get given the option of bootloader, make sure you install it to the start of the partition you installed it, and not to the MBR.

# Fixing the MBR

So with RHEL installed, you'll probably find that you now cannot boot into Windows and/or RHEL. I got a lovely

> no bootable device – insert boot disk and press any key

This is because RHEL has completely knackered the MBR when it installed it's bootloader... To fix, reboot your machine and when in the rEFIt boot loader, select "sync partitions". This should then prompt you with what it thinks the MBR should look like. If it looks ok, accept, cross your fingers, reboot and try loading Windows. Hopefully you should be able to now load into Windows (yey!) reboot and try Linux. This should also boot, and you can go rejoice!

I found that the first couple of boots, I had rEFIt hang on the tux logo, but after a couple of reboots that problem seemed to disappear (see [http://ubuntuforums.org/showthread.php?t=767677](http://ubuntuforums.org/showthread.php?t=767677))

Good luck!
