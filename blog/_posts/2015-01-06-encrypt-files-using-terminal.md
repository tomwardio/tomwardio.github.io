---
layout: post
title: Encrypt Files using Terminal
subtitle: How-to encrypt files using built in OSX tools.
categories:
  - Tech
tags:
  - python
  - openssl
  - encrypting files
  - bash
  - terminal
---

Sometimes it's really useful to be able to encrypt a file locally, and although
there's lots of pieces of software that can do this for you, I much prefer to
just do it myself. Using Terminal's "openssl" command, it's really really simple
to encrypt a file well enough for snoops to not be able to read.

<!--more-->

To encrypt a file, simply run the following from Terminal. It'll then ask you
for a password to encrypt the file with (you can pass this in as an argument
using -k <password>, but then people can see what it is in the Terminal history,
and we don't want that!)</password>

```bash
openssl enc -aes-256-cbc -salt -in </path/for/file/to/encrypt.txt> -out </path/to/encrypted/output.enc>
```

Let's break down this command:

- _enc -aes-256-cbc_: This is the encryption algorithm that you want to use.
  There's a whole raft of options that are possible, but I'd recommend using
  AES-256, it's pretty secure.
- _-salt_: You should always use this, it basically adds another level of
  security by "salting" the encryption. This basically means that it you encrypt
  the same file with the same password, it'll come out different. This is really
  really useful to stop thieves from using brute force to figure out the
  password.
- _-in_: Pretty self-explanitory, is basically file path to the file you want to
  encrypt. This could obviously be whatever you like.
- _-out_: Again, this is straight forward enough, should be a location on disk
  to save the encrypted file to.

Cool, so we now have a pretty well encrypted file! You probably want to be able
to decrypt it though as well (pretty useless otherwise right?!). You can do this
by running the following:

```bash
openssl enc -aes-256-cbc -salt <salt> -d -in </path/to/encrypted/output.enc> -out </path/to/decrypted/file.txt>
```

Note that the input and output files have changed round, and we've added the all
important "-d" argument, which tells us to decrypt the file rather than
encrypting it.

##### Added Bonus

Another cool thing to make your files that little bit less noticeable is to
concatenate your encrypted file to the end of another file. You can't do it with
all files, but I've tried it with JPEG and MP3, both of which are quite amenable
to doing this. It's really easy as well, though splitting them apart involves a
4 line python script!

To concatenate the files together, run the following:

```bash
(cat /path/to/MySong.mp3; cat /path/to/encrypted/file.enc) > MySecretSong.mp3
```

This simply takes the song and the encrypted file and bugs them together.
Simple! Try playing "MySecretSong.mp3", hopefully it should still play.

To extract the file, you'll need to save the following python script into a text
file, call it something like "ExtractSecret.py":

```python
#!/usr/bin/python
import sys
f = open(sys.argv[1]).read()
out = f.split(&quot;Salted__&quot;)[1]
open(sys.argv[2], 'r').write("Salted__"+out)
```

You then simply run the following to get your encrypted file back:

```bash
python ExtractSecret.py "/path/to/MySecretSong.mp3" "/path/to/encrypted/output.enc"
```

And that's it! You should now be able to decrypt in the normal way.
