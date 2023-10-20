---
layout: post
title: Reading the Keyboard in X11
permalink: reading-keyboard-in-x11
categories:
  - Tech
tags:
  - linux
  - X11
  - qt
  - keyboard
  - XKeycodeToKeysym
  - XQueryKeymap
---

I actually began this post well over a year ago, as I remember struggling to
work out how to read keyboard input in X. Anyway, I thought I'd finally finish
it off for posterity's sake :)

I recently had to implement some API calls in Linux to be able to return what
keys were currently being pressed. As I was using Qt for the UI layer (which, by
the way, is now my favourite UI framework!) I was hoping there would be some
platform-agnostic call I could make. However (and kinda rightfully so) Qt
doesn't expose a way to do this, as it's assumed you should just do things based
on events.

After a few hours googling and scratching my head, I realised this wasn't going
to be as simple as I imagined, as the documentation for anything X based seems
incessantly complex. Anyway, here's how I did it!

<!--more-->

# Getting the Keys being Pressed

First I get from the QApplication the currently actibe window. Assuming we have
a valid window, I then get the X11 display pointer and use this to call
[XQueryKeymap](http://www.unix.com/man-page/All/3/XQueryKeymap/ "XQueryKeymap").
This function takes an array of 32 chars, which is uses to mark what physical
keys are being pressed, one key per bit.

```cpp
static const uint32_t K_KEYMAP_SIZE = 32;

QWidget* window = qApp->activeWindow();
if( window )
{
    // We have a valid window, so grab the display
    const QX11Info& info = window->x11Info();

    char keyMap[K_KEYMAP_SIZE];

    // First get the bit array of all keys currently down
    XQueryKeymap(info.display(), keyMap);

    // next go through each member of keymap array
    for( uint32_t i = 0; i < K_KEYMAP_SIZE; i++ )
    {
        const char& currentChar = keyMap[i];

        // iterate over each bit and check if the bit is set
        for( uint32_t j = 0; j < 8; j++ )
        {
            // AND current char with current bit we're interested in
            bool isKeyPressed = ((1 << j) & currentChar) != 0;

            if( isKeyPressed )
            {
                // work out the keycode (is just the number of the bit that's set)
                KeyCode keyCode = (i * sizeof(char) * 8) + j;

                // convert to qt key, and append if we get a valid key
                int32_t qtkey = ConvertKeyToQtKey(keyCode, info.display());

                if( qtkey )
                {
                    downkeys.push_back(qtkey);
                }
            }
        }
    }
}
```

# Converting the X11 key to Qt key

In the above code, once I have the bit array of buttons being pressed, I then
iterate through all the keys being pressed and convert the pysical key into a Qt
key. This basically involves using the
[XKeycodeToKeysym](http://www.unix.com/man-page/all/3x/XKeycodeToKeysym "XKeycodeToKeysym")
function, which will convert a key position into a key symbol. However, as each
physical key can have multiple meanings (based on modifiers for instance) I
iterate over all the symbols (using an iterator) and return the first key that I
care about.

```cpp
typedef QMap <keysym, int32_t="">KeySymToQtKeyMap;</keysym,>

int32_t
ConvertKeyToQtKey(
    uint32_t keyCode,
    Display* display )
{
    // This is a static map of key mappings for all the keys I need to know about, which I initialize once
    static KeySymToQtKeyMap keyMapping = InitializeKeyMapping();

    // Iterate through all the keysym's until we find one that matches.
    uint32_t i = 0;
    KeySym key = NoSymbol;
    do
    {
        key = XKeycodeToKeysym((Display*)display, keyCode, i++);

        if( (key >= XK_0 && key <= XK_9) || (key >= XK_a && key <= XK_z) || (key == XK_space) )
        {
            // ASCII Key, make sure it's changed to upper varient if a char
            return isprint(key) ? toupper(key) : key;
        }
        else if( keyMapping.contains(key) )
        {
            return keyMapping[key];
        }
    } while( key != NoSymbol);

    return 0;
}
```

This isn't the perfect solution, but for my case it worked perfectly. The moral
of the story is that looking at the keyboard directly is a Bad Idea and that you
should always always listen to button events instead.
