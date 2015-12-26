---
layout: post
title: Class Layout Reporting with VC++ Compiler
subtitle: Tutorial to show class layout on Windows using VC++.
permalink: class-layout-reporting-with-vc-compiler
categories:
- Tech
tags:
- visual studio
- c++
- class layout
- vs2010
---
Last month whilst searching for a VC++ compiler flag (the -Isystem equivalent for VS, which I never did find) I stumbled across this hidden flag, which allows you to print out what the compiler generates for your class structure. Very cool!

To print out the class structure for all classes in your compilation, you can use /d1reportAllClassLayout. If you want to /d1reportSingleClassLayoutxxx, where xxx is the name to search for

For anyone who's done any data structure optimisation, or tried to make binary serialisation deterministic, this information is invaluable. To explain why, let's see what the compiler generates for this very simple class:

```cpp
class ClassA
{
public:
private:
float32_t mfFloat;
bool mbBool;
int32_t miInt;
bool mbAnotherBool;
};
```

Here's the compiler output:

```
class ClassA size(16):
+---
0   | mfFloat
4   | mbBool
| <alignment member="">(size=3)
8   | miInt
12  | mbAnotherBool
| <alignment member="">(size=3)
+---
```
The first thing to notice is the `<alignment>` members. This is super super useful for finding gaps in your data structures due to memory alignment, which is sometimes difficult to assertain (especially with lots of inheritance). Removing these gaps will make your data structures better packed and therefore reduce the number of cache misses, as well as make sure there's no uninitialised memory, a common cause for undeterministic data in serialised data structures.</alignment></alignment></alignment>

But what does the compiler generate if there's an alignment gap at the end of a base class? Here's another class that derives from ClassA

```cpp
class ClassB : public ClassA
{
public:
private:
bool muBool;
uint32_t muAnotherInt;
};
```

And the associated output:

```
class ClassB size(24):
+---
| +--- (base class ClassA)
0 | | mfFloat
4 | | mbBool
| | <alignment member="">(size=3)
8 | | miInt
12 | | mbAnotherBool
| | <alignment member="">(size=3)
| +---
16 | muBool
| <alignment member="">(size=3)
20 | muAnotherInt
+---
```

As you can see, unfortunately ClassB's members haven't been fitted into the gap at the end of ClassA, meaning an inherent waste of space when using inheritance, a useful thing to be aware of.

Now let's see what happens to our class structure if we add a virtual function into these classes.

```cpp
class ClassA
{
public:
virtual void VirtualFunction()
{ }
virtual void SomeOtherFunction()
{ }
private:
float32_t mfFloat;
bool mbBool;
int32_t miInt;
bool mbAnotherBool;
};

class ClassB : public ClassA
{
public:
virtual void VirtualFunction()
{ }
private:
bool muBool;
uint32_t muAnotherInt;
};
```

Now let's see what the compiler layout is:

```
class ClassA size(20):
+---
0 | {vfptr}
4 | mfFloat
8 | mbBool
| <alignment member="">(size=3)
12 | miInt
16 | mbAnotherBool
| <alignment member="">(size=3)
+---

ClassA::$vftable@:
| &ClassA_meta
| 0
0 | &ClassA::VirtualFunction
1 | &ClassA::SomeOtherFunction

ClassA::VirtualFunction this adjustor: 0
ClassA::SomeOtherFunction this adjustor: 0

class ClassB size(28):
+---
| +--- (base class ClassA)
0 | | {vfptr}
4 | | mfFloat
8 | | mbBool
| | <alignment member="">(size=3)
12 | | miInt
16 | | mbAnotherBool
| | <alignment member="">(size=3)
| +---
20 | muBool
| <alignment member="">(size=3)
24 | muAnotherInt
+---

ClassB::$vftable@:
| &ClassB_meta
| 0
0 | &ClassB::VirtualFunction
1 | &ClassA::SomeOtherFunction

ClassB::VirtualFunction this adjustor: 0
```

We can now see where the compiler has added the vtable pointer to each class, which is good to know about with alignment, but it also shows what functions exist in the class vtable, which is pretty awesome! This vtable printout shows which class the virtual function exists for, so in the above example `SomeOtherFunction()` in ClassB points at the ClassA implementation, so is cool to see exactly how many virtual functions we have and where they come from.

Finally, what does the compiler produce for any classes with multiple inheritance? Let's see what's generated when we have ClassB derive from ClassA and ClassC:

```cpp
class ClassA;

class ClassC
{
public:
virtual void VirtualFunction()
{ }
private:
bool mbYetAnotherBool;
};

class ClassB : public ClassA, public ClassC
{
public:
virtual void VirtualFunction()
{ }
private:
bool muBool;
uint32_t muAnotherInt;
};
```

And the compiler output:

```
class ClassC size(8):
+---
0 | {vfptr}
4 | mbYetAnotherBool
| <alignment member="">(size=3)
+---

ClassC::$vftable@:
| &ClassC_meta
| 0
0 | &ClassC::VirtualFunction

ClassC::VirtualFunction this adjustor: 0

class ClassB size(36):
+---
| +--- (base class ClassA)
0 | | {vfptr}
4 | | mfFloat
8 | | mbBool
| | <alignment member="">(size=3)
12 | | miInt
16 | | mbAnotherBool
| | <alignment member="">(size=3)
| +---
| +--- (base class ClassC)
20 | | {vfptr}
24 | | mbYetAnotherBool
| | <alignment member="">(size=3)
| +---
28 | muBool
| <alignment member="">(size=3)
32 | muAnotherInt
+---

ClassB::$vftable@ClassA@:
| &ClassB_meta
| 0
0 | &ClassB::VirtualFunction
1 | &ClassA::SomeOtherFunction

ClassB::$vftable@ClassC@:
| -20
0 | &thunk: this-=20; goto ClassB::VirtualFunction

ClassB::VirtualFunction this adjustor: 0
```

Again the compiler hasn't filled in any of the alignment gaps at the end of the classes, but does keep the class ordering dependent on what order you put the class inheritance. More interesting is ClassB vtables, especially for ClassC. You can see here effectively what the compiler does for a call to ClassC's `VirtualFunction()` which has been overloaded in ClassB. It effectively does a goto call to the overloaded function, with a modified this pointer to the start of ClassB. Is interesting to see this, even if it is pretty self evident.

Has been interesting to see exactly what the compiler creates, and has been very useful to easily find exactly what the compiler determines as the class structure, as well as seeing inside the class vtables. Would be interesting to build a tool that parses this information and shows where the worst offenders are for data packing.
