---
layout: post
title: Playing with Parse
permalink: playing-with-parse
categories:
  - Tech
tags:
  - parse
  - ios
  - nosql
  - web
---

Recently I've started delving into the world of writing iOS apps, mainly because
it's just so much faster to develop than in C/C++. I decided to create a little
exercise app to give it some context called "FriendTracker". The premise was
that it would keep a history of your location, but also allow you to see where
your friends have been as well.

To do this I would need to store the data on a web service so that others could
see where you've been whilst offline, so I began setting up my Raspberry Pi as a
little server to do just that. That was until I stumbled across a service called
"[Parse](http://www.parse.com "Parse")" that looked like it would tick all the
boxes and then some!

Parse is basically a NoSQL-based service specifically for mobile development. It
provides SDK's for pretty much every popular device & languge under the sun, as
well as a REST API for everyone else. They also provide analytics, crashreports,
push notifications and, on some devices, offline caching. It still seems a
little green around the edges (I had issues with empty objects being uploaded)
but overall it's really pretty awesome! Caching and querying the data is a
breeze, integrating the SDK is relatively painless and, most importantly, it's
**free** to setup and use!

Will post some more stuff on it later, but am enjoying the experience so far!
