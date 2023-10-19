---
layout: post
title: API Hooking on Windows
subtitle: Modifying system calls on Windows...
permalink: api-hooking-on-windows
categories:
  - Tech
tags:
  - windows
  - qt
  - API Hooking
  - MSDN
  - DPI awareness
  - VirtualProtect
---

A while back I was porting an application to Qt 4.8 on Windows and, due to the
fact the program couldn't deal with varying DPI settings, I had to make sure Qt
didn't call the _"SetProcessDPIAware()"_ function. The simple way to do this
would be to simply recompile Qt to remove this offending line, but as we wanted
to share the *exact* same library with other products, I didn't have that
luxury.

So I did something really really naughty: I used a trick to modify the API call
to not actually do anything. Welcome to API Hooking! This is actually used quite
a lot by profilers or memory tracking software to hook into low-level API's and
track various tasks, but we're going to use it in this case to simply early out
of the given function.

- First, add an entry point to perform the code injection. For me, I just added
  a block of code into the main function of the dll.
- Next, you need to get the address for the function you want to change. I
  assume the library will already have been loaded, otherwise you'll need to
  call _"LoadLibrary()"_ first on the dll that contains the function (in this
  case, "user32.dll").
- Once you have the address, you need to make the page that the pointer exists
  in writeable, so that you can modify the code. This involves using the
  _"VirtualProtect()"_ function, remembering to store the old protection level
  so that you can reset it afterwards. See
  [here](http://msdn.microsoft.com/en-us/library/windows/desktop/aa366898%28v=vs.85%29.aspx "VirtualProtect function MSDN")
  for more details.
- Now the page is writeable, it's time to get out your assembly writing skills!
  For this example, all I needed to do was write a "ret" instruction into the
  first line of the function address, which would return before pushing anything
  on the stack etc. For more advanced tasks,a common technique is to add a jump
  call to a custom function to do all the heavy lifting in.
- Finally, you want to reset the protection level on the given page.

Sounds quite complex, but it basically boils down to something like this:

```cpp
typedef BOOL (WINAPI *SetProcessDPIAwarePtr)(VOID);

INT APIENTRY DllMain(HMODULE hDLL, DWORD reason, LPVOID reserved)
{
    if (reason == DLL_PROCESS_ATTACH )
    {
        // Make sure we're not already DPI aware
        assert( !IsProcessDPIAware() );

        // First get the DPIAware function pointer
        SetProcessDPIAwarePtr lpDPIAwarePointer = (SetProcessDPIAwarePtr)
        GetProcAddress(GetModuleHandle("user32.dll"),
        "SetProcessDPIAware");

        // Next make the page writeable so that we can change the function assembley
        DWORD oldProtect;
        VirtualProtect((LPVOID)lpDPIAwarePointer, 1, PAGE_EXECUTE_READWRITE, &oldProtect);

        // write "ret" as first assembly instruction to avoid actually setting HighDPI
        BYTE newAssembly[] = {0xC3};
        memcpy(lpDPIAwarePointer, newAssembly, sizeof(newAssembly));

        // change protection back to previous setting.
        VirtualProtect((LPVOID)lpDPIAwarePointer, 1, oldProtect, NULL);
    }
    return TRUE;
}
```

That's not too scary, right?! In my use case this seems to have worked
perfectly, and saved me from the hassle of recompiling Qt!
