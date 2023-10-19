---
layout: post
title: SIMD optimized dot and cross product functions
subtitle: C++ examples of vector intrinsics.
permalink: simd-optimized-dot-and-cross
categories:
  - Tech
tags:
  - sse
  - dot product
  - cross product
  - 3d math
  - simd
  - intrinsics
  - c++
---

In my limited spare time, I've been trying to teach myself some basic [SIMD programming](http://en.wikipedia.org/wiki/SIMD) in order to optimize my 3D math library I've been work on. Whilst at EA, we had the idea of having an "FPU" (Floating-point Processing Unit) math library, alongside a "VPU" (vector processing unit) optimized class. I decided to do the same thing in my math library for a few reasons:

1. It allows me to write a simpler, much more basic math library that I could use in unit tests to validate the VPU version
1. It gives me a way to accurately benchmark my SIMD optimized code path
1. Finally there are cases where it's actually better to use a floating point class version, which I'll briefly explain later

As I wanted to guarantee backwards compatibility, I decided to just use SSE2 instructions and not anything more fancy, which means it'll work on every 64-bit desktop processor\* as well as hopefully port quite nicely to [neon for ARM](http://en.wikipedia.org/wiki/ARM_architecture#Advanced_SIMD_.28NEON.29) (more on that in a future post!)

Rather than go through everything, I'll instead just explain what I did for dot and cross products, which will show most of the simple ways of doing things<a id="more"></a><a id="more-175"></a>

# Introduction to SIMD SSE

I won't go into huge detail here as there's plenty of better resources for this, but the basic principality of SSE is to try and do multiple operations (four to be exact) in one instruction call. This is done by using special intrinsic registers which are 128bits wide, and then using special instructions to perform operations on all 4 values at the same time. This works really well for 3D operations where you'll more often than not want to perform actions on the X, Y, Z and W values at the same time. The key is to then try as much as possible to keep the results of these operations in these 4-wide registers to ensure you don't incur the cost of moving them back.

The one caveat to all this is getting the data into these special registers in the first place. For SSE2, nearly all of the load operations require the source data to be **16byte aligned** when you load them using `__mm_load_ps_` instructions There are non-aligned calls, but traditionally these were very slow on various processors, so if you were doing it a lot then you'd cause some serious slow downs. On newer processors and using newer instruction sets this is not so much of a problem, but it's still good to know.

To check for alignment, I wrote a simple macro that tests any reference object to ensure the memory is appropriately aligned before calling any intrinsic functions. This is obviously only for debug and compiles out for our optimized code.

```cpp
#define M_CHECK_ALIGNMENT(lObject, luAlignment) \
{ \
    assert( (luAlignment) ); \
    assert( ( (luAlignment) & ( (luAlignment) - 1 ) ) == 0 ); \
    assert( (reinterpret_cast<intptr_t>( &(lObject) ) & ( (luAlignment) - 1 )) == 0 ); \
}
```

# Simple Operations

Before showing how I put together a dot product function, let's do a simple example: adding. For this ill just be multiplying 4 floats together, which is exactly what I do in my Vector4 class. Below is a simple example of loading 8 floats into two intrinsic registers, performing a mult operation and then print the result.

```cpp
static float lafResult[] = { 0.0f, 0.0f, 0.0f, 0.0f };

__m128 lvfA = _mm_set_ps( 1.0f, 2.0f, 3.0f, 4.0f );
__m128 lvfB = _mm_set_ps( 2.0f, 3.0f, 4.0f, 5.0f );
__m128 lvfA_mult_B = _mm_mult_ps( lvfA, lvfB );

_mm_store_ps( lafResult, lvfA_mult_B );

printf( "%f, %f, %f, %f\n", lafResult[0], lafResult[1], lafResult[2], lafResult[3]);
```

Pretty simple huh?! An interesting point to note is that this snippet of code actually returns the result in the reverse order, so 20.0, 12.0, 6.0, 2.0". This is because intrinsics are stored the opposite way round than what is expected for some reason, so when we store the result back into a float register this gets reversed. It's also important to note that the float array we store the result into must be aligned for this example, otherwise it would crash. One way to ensure your Vector class is 16-byte aligned is by using the

```cpp
__attribute__ ((aligned (x)));
```

keyword in the class declaration. This is actually pretty annoying, as it means for vector types that are smaller than 16bytes (so Vector2 and Vector3) it means we'll be wasting space between instances of this class. It is this reason why it's sometimes actually faster to use the FPU variants of the vector class, as it packs nicer, meaning less cache misses. Interesting fact, whilst at EA and working on the AI systems in Need For Speed, we actually found it was quicker to use the FPU vectors when performing things like A\* algorithms, as the cache-miss overhead on the PS3 and X360 processors cancelled out any benefit from using the VPU variants.

# The Dot Product shuffle

Now that we've got a rough idea of how easy SSE coding is done, let's see how we can apply that to a dot product function. First lets write out exactly what a dot product using floats would look:

```cpp
inline
float32_t Dot( const Vector4& lLhs, const Vector4& lRhs )
{
    return lLhs.GetX() * lRhs.GetX() +
    lLhs.GetY() * lRhs.GetY() +
    lLhs.GetZ() * lRhs.GetZ() +
    lLhs.GetW() * lRhs.GetW();
}
```

As you hopefully can see, fundamentally this is just multiplying two vector4's together, and then adding each result together to get the scalar result. We've already shown how to multiply two arrays of 4 floats together, the difficulty comes when moving adding the results together. One way to do this would be to move the results of the multiply into 4 float variables and then add them together, however this would cause more instructions and involve moving to and from float registers, which would negate the benefit of doing all 4 multiplications at the same time. Introducing the shuffle instruction! This function allows you to take two intrinsic variables and move two channels from each of these into a new variable. Here's a simple example:

```cpp
__m128 lvfA = _mm_set_ps( 1.0f, 2.0f, 3.0f, 4.0f );
__m128 lvfB = _mm_set_ps( 5.0f, 6.0f, 7.0f, 8.0f );

__m128 lvfResult = _mm_shuffle_ps( lvfA, lvfB, _MM_SHUFFLE( 0, 1, 2, 3 ) );

printf( "%f, %f, %f, %f\n", lvfResult.m128_f32[0], lvfResult.m128_f32[1],
lvfResult.m128_f32[2], lvfResult.m128_f32[3] );
```

The shuffle command takes a 3rd argument, which is an unsigned int that defines which channel to take from each intrinsic variable. Using this technique, we can move each channel around, add the result together and then end up with the result. Let's see what that looks like:

```cpp
typedef __m128 FloatIntrinsic;

inline FloatIntrinsic
DotV4( const FloatIntrinsic& lLhs, const FloatIntrinsic& lRhs )
{
    M_CHECK_ALIGNMENT( lLhs, sizeof(FloatIntrinsic) );
    M_CHECK_ALIGNMENT( lRhs, sizeof(FloatIntrinsic) );
    FloatIntrinsic lvMult = _mm_mult_ps( lLhs, lRhs );
    FloatIntrinsic lvTemp = _mm_shuffle_ps( lvMult, lvMult, _MM_SHUFFLE( 3, 2, 1, 0 ) ); // W, Z, Y, X
    lvTemp = _mm_add_ps( lvTemp, lvMult ); // (x+w), (y+z), (z+y), (w+x)
    FloatIntrinsic lvTemp2 = _mm_shuffle_ps(lvTemp, lvTemp, _MM_SHUFFLE( 2, 3, 0, 1 ) );
    return _mm_add_ps( lvTemp, lvTemp2 ); // (x+w+z+y), (y+z+w+x), (z+y+x+w), (w+x+y+z)
}
```

As the comments suggest, what we're doing is shuffling the result of the mult operation together, adding this to the original result, then shuffling this **again** and adding those two together. This produces a resultant whereby all the channels are set to the sum of the multiplication, which is very useful if we wanted to later scale a given vector equally, and keeps the result in an intrinsic register, which is good! For good measure, here's what the assembly looks like, which is pretty small:

```
000000013F8FD0E8 mulps xmm0,xmmword ptr [13F940320h]
000000013F8FD0EF movaps xmm1,xmm0
000000013F8FD0F2 shufps xmm1,xmm0,1Bh
000000013F8FD0F6 addps xmm1,xmm0
000000013F8FD0F9 movaps xmm0,xmm1
000000013F8FD0FC shufps xmm0,xmm1,4Eh
000000013F8FD100 addps xmm0,xmm1
000000013F8FD103 movaps xmmword ptr [rsp+50h],xmm0
```

This code could also be used for a Vector3 dot product as well, however you need to _guarantee_ that the "W" component is always zero, otherwise you'll accidentally get wrong results. A common place this might happen is when converting from a Vec4 to a Vec3, or (where I found it an issue) when trying to apply a dot product to a quaternion axis. However it's easy enough to write a DotV3 function, shown below:

```cpp
inline FloatIntrinsic
DotV3( const FloatIntrinsic& lLhs, const FloatIntrinsic& lRhs )
{
    M_CHECK_ALIGNMENT( lLhs, sizeof(FloatIntrinsic) );
    M_CHECK_ALIGNMENT( lRhs, sizeof(FloatIntrinsic) );
    FloatIntrinsic lvMult = _mm_mult_ps( lLhs, lRhs );
    FloatIntrinsic lvTemp = _mm_shuffle_ps( lvMult, lvMult, _MM_SHUFFLE( 1, 0, 0, 0 ) );
    FloatIntrinsic lvTemp2 = _mm_shuffle_ps( lvMult, lvMult, _MM_SHUFFLE( 2, 0, 0, 0 ) );
    FloatIntrinsic lvSum = _mm_add_ps( lvMult, _mm_add_ps( lvTemp, lvTemp2 ) );
    return _mm_shuffle_ps( lvSum, lvSum, _MM_SHUFFLE( 0, 0, 0, 0 ) );
}
```

In this example you could avoid the last shuffle and use the first value from the intrinsic. However as I said before, it's very beneficial to have the same value in all the channels, as you can then use it in other operations (this is called "splatting" the result across all channels). Here's the assembly for this as well for good measure:

```
000000013FC5F2A8 mulps xmm2,xmmword ptr [13FCB0580h]
000000013FC5F2AF movaps xmm0,xmm2
000000013FC5F2B2 shufps xmm0,xmm2,1
000000013FC5F2B6 movaps xmm1,xmm2
000000013FC5F2B9 shufps xmm1,xmm2,2
000000013FC5F2BD addps xmm1,xmm0
000000013FC5F2C0 addps xmm1,xmm2
000000013FC5F2C3 shufps xmm1,xmm1,0
000000013FC5F2C7 movaps xmmword ptr [rsp+50h],xmm1
```

# Now for the Cross Product

Phew! That wasn't too bad was it?! Ok maybe it was, but the good news is that using these techniques, you can do cross product in a very similar way. Again, lets write a simple cross product function using floats:

```cpp
inline
Vector3 Cross( const Vector3& lLhs, const Vector3& lRhs )
{
    Vector3 lvResult;
    lvResult.GetX() = lLhs.GetY() * lRhs.GetZ() - lLhs.GetZ() * lRhs.GetY();
    lvResult.GetY() = lLhs.GetZ() * lRhs.GetX() - lLhs.GetX() * lRhs.GetZ();
    lvResult.GetZ() = lLhs.GetX() * lRhs.GetY() - lLhs.GetY() * lRhs.GetX();
    return lvResult;
}
```

Again I've structured this in a way that makes it obvious that we have 3 operations that need to be performed. Unlike the dot however, we need to first get our two vectors into the right order before multiplying and subtracting. Let's see what that looks like:

```cpp
M_FORCE_INLINE FloatIntrinsic
CrossV3( const FloatIntrinsic& lLhs, const FloatIntrinsic& lRhs )
{
    M_CHECK_ALIGNMENT( lLhs, sizeof(FloatIntrinsic) );
    M_CHECK_ALIGNMENT( lRhs, sizeof(FloatIntrinsic) );
    const uint32_t YZXMask = _MM_SHUFFLE( 1, 2, 0, 0 );
    const uint32_t ZXYMask = _MM_SHUFFLE( 2, 0, 1, 0 );
    FloatIntrinsic lvTemp1 = _mm_shuffle_ps( lLhs, lLhs, YZXMask );
    FloatIntrinsic lvTemp2 = _mm_shuffle_ps( lRhs, lRhs, ZXYMask );
    FloatIntrinsic lvMult = _mm_mult_ps( lvTemp1, lvTemp2 ); // (y1*z2), (z1*x2), (x1*y2), (x1*x2)
    lvTemp1 = _mm_shuffle_ps( lLhs, lLhs, ZXYMask );
    lvTemp2 = _mm_shuffle_ps( lRhs, lRhs, YZXMask );
    FloatIntrinsic lvMult2 = _mm_mult_ps( lvTemp1, lvTemp2 ); // (z1*y2), (x1*z2), (y1*x2), (x1*x2)
    return _mm_sub_ps( lvMult, lvMult2 );
}
```

Pretty striaght forward right?! The cool thing about this is that because we're doing x1*x2 - x1*x2 in the W, no matter what is there will become zero, which is very handy when using the result in some other operation. Let's see what this looks like as assembly:

```
000000013F34EDAA movaps xmm6,xmm2
000000013F34EDAD shufps xmm6,xmm2,12h
000000013F34EDB1 movaps xmm0,xmm1
000000013F34EDB4 shufps xmm0,xmm1,9
000000013F34EDB8 mulps xmm6,xmm0
000000013F34EDBB shufps xmm1,xmm1,12h
000000013F34EDBF shufps xmm2,xmm2,9
000000013F34EDC3 mulps xmm2,xmm1
000000013F34EDC6 subps xmm6,xmm2
```

# Summary

So that's a quick whistle stop tour of writing SSE instructions and showing how to create dot and cross functions. I'll try and add some performance tests comparing the the two functions above to their FPU equivalents in a later post.

\* That's not actually true, some of the earliest Pentium 4 64-bit processors didn't have any SSE support, but I doubt anybody will be using those
