---
layout: post
title: PPTP on Raspberry Pi
subtitle: How to add PPTP daemon to a Raspberry Pi.
permalink: pptp-on-raspberry-pi
header-img: uploads/posts/pptp-on-raspberry-pi/background.jpg
categories:
  - Tech
tags:
  - raspberry pi
  - linux
  - pptp
  - pptpd
  - vpn
  - raspbian
---

When I was working out in California, I occasionally found myself wanting to get
access to my home network for things like network shares, connecting to my local
machines or various other reasons. As I had a Raspberry Pi knocking about, I
decided to set it up as a VPN server to allow me to securely connect back using
my iOS devices. So here's a quick guide on how to do just that!

<!--more-->

# Step 1 - Setup the device

First things first, go ahead and install Rasbian from the official source and
connect via. SSH. The default username is "pi" and the password "raspberry".
You'll want to change the password pretty quickly.

Once you're logged in through ssh, run the following command:

```bash
sudo apt-get install pptpd
```

This will install the PPTP daemon on the device.

# Step 2 - Configure PPTP

Next, open /etc/pptpd.conf with your favorite terminal text editor. I use vi but
nano is another popular option. Remember to run with sudo, as you need super
user access to save the file.

```bash
sudo vim /etc/pptpd.conf
```

With the config file open, find the line `#localip 192.168.0.1`, remove the # at
the beginning and change the IP address to that of the device. If you don't know
the IP address, then close the file and use the `ifconfig` command to find this
out. On my network the IP address is "192.168.0.10", so the line would look like
this:

```
localip 192.168.0.10
```

Next you want to again find the line beginning with `#remoteip` and remove the
#, then choose a range of IP addresses to assign devices that connect to the
VPN. Make sure this doesn't conflict with the ones that are assigned by your
router on the network, otherwise you could have problems. Below is the
configuration I used:

```
remoteip 192.168.1.210-22
```

With these two changes saved, you can now close this file.

# Step 3 - Setup PPTP options

Next you want to open the /etc/ppp/pptpd-options file with the following command
(again feel free to use whatever text editor you want):

```bash
sudo vi /etc/ppp/pptpd-options
```

Next, you want to setup what DNS to use. I usually set this to be the same as my
router address, but you could also use Google's DNS address 8.8.8.8 if you like.
Find the first line starting with `#ms-dns`, un-comment this again (remove the
#) and change it to something like this:

```
ms-dns 192.168.1.254
```

You might also want to set the wins-dns as well to your router address (don't
set this to Google's DNS!) so that you can find Windows shares.

```
ms-wins 192.168.1.254
```

You can now save these changes and close this file.

# Step 4 - Enable packet forwarding and start PPTP daemon

Now that we've configured PPTP, we now need to enable packet forwarding on the
device and open the PPTP port on your router. First, open the file
/etc/sysctl.conf with your fave editor:

```bash
sudo vi /etc/sysctl.conf
```

and uncomment the following line:

```
#net.ipv4.ip_forward=1
```

Now that everything's setup, run the following two commands. The first will
restart the service with the above changes, the second will make sure the
service is restarted when the pi reboots.

```bash
sudo service pptpd restart
sudo systemctl enable pptpd
```

## Setting up router

The final step you will (probably) need to do is to open port 1723 on your
router. This varies from device to device, but is usually configurable from the
router's web interface.

That's it! If you still can't connect, there's some options in /etc/pptpd.conf
to enable debug logging, which you can see in /var/log/messages. A useful
command for viewing the end of the log is as follows:

```bash
tail -f /var/log/messages
```
