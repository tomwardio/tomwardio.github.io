---
layout: post
title: Un-premultiplied textures on Metal
categories:
- Tech
tags:
- ios
- Metal
- texture loading
- objective-c
- Apple
---
Recently in my spare time I've been dabbling on Apple's not-so-new OpenGL replacement, Metal, which has frankly been an absolute joy. It's a very neat and tidy API, a lot simpler to understand than the monstrosity that is OpenGL and gives a lot more fine-grained control over command dispatch, sharing buffers and threaded dispatch (yey!)

For all its bells and whistles, there was one thing that I found really annoying. It's quite a common thing to want to use a texture for applying various effects in OpenGL, using the R, G, B and A values the image's pixels to store arbitrary data in. A good example is when doing bump mapping, where you might want to store the bump amount in the diffuse texture's alpha.

However, on iOS it doesn't seem to be possible to do this. The problem is that when you load a PNG image on iOS, by default it seems to automatically pre-multiply the image by the alpha channel. This means that when you load the UIImage, iOS automatically multiplies the R, G and B by the pixel's alpha amount, which means you lose the color values for anywhere there's a zero alpha. I might be doing something wrong, so I've uploaded an example iOS project that should show the issue ([https://github.com/tomwardio/MetalPremultTexture](https://github.com/tomwardio/MetalPremultTexture)):

# Loading the UIImage using CGContextDrawImage

For this example, I've created my own 8-bit PNG that has the following:

![RGB](http://tomjbward.co.uk/wp-content/uploads/2015/07/texture.png) | ![Alpha](http://tomjbward.co.uk/wp-content/uploads/2015/07/alpha-300x300.png)
------------- | -------------
RGB           | Alpha

To load a UIImage into a Metal texture, the only way to currently do this is to use the CGImage API to get access to the raw pixel data. I wrote a helper function for doing just this:

```objective-c
+ (id<mtltexture>) createTextureFromImage:(UIImage*) image device:(id<mtldevice>) device
{
    CGImageRef imageRef = image.CGImage;

    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
    size_t bitsPerPixel = CGImageGetBitsPerPixel(imageRef);

    CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageRef);
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef);

    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | alphaInfo;

    CGContextRef context = CGBitmapContextCreate( NULL, width, height, bitsPerComponent, (bitsPerPixel / 8) * width, colorSpace, bitmapInfo);
    if( !context )
    {
        NSLog(@"Failed to load image, probably an unsupported texture type");
        return nil;
    }

    CGContextDrawImage( context, CGRectMake( 0, 0, width, height ), image.CGImage );

    MTLPixelFormat format = MTLPixelFormatRGBA8Unorm;
    if( bitsPerComponent == 16 )
    format = MTLPixelFormatRGBA16Unorm;
    else if( bitsPerComponent == 32 )
    format = MTLPixelFormatRGBA32Float;

    MTLTextureDescriptor *texDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:format
        width:width
        height:height
        mipmapped:YES];
    id <mtltexture>texture = [device newTextureWithDescriptor:texDesc];

    [texture replaceRegion:MTLRegionMake2D(0, 0, width, height)
    mipmapLevel:0
    withBytes:CGBitmapContextGetData(context)
    bytesPerRow:4 * width];

    return texture;
}
```

This loads the texture into memory using the image settings. The problem is that rather than creating the RGB values like they are above, I instead get the following when rendering it in Metal:

![Rendered texture](http://tomjbward.co.uk/wp-content/uploads/2015/07/result-300x300.png)

As you can see, the image has been pre-multiplied with the alpha, which is kinda to be expected, because we used the image's CGAlphaInfo to determine how to read the pixel into memory. In the header, there's a promising option called _"kCGImageAlphaLast"_, which looks to be exactly what we want! However, using this causes the image to fail to load with the following error:

> "CGBitmapContextCreate: unsupported parameter combination: 8 integer bits/component; 32 bits/pixel; 3-component color space; kCGImageAlphaLast; 2048 bytes/row."

# Workarounds

There are a couple of ways that you can work around this. The first is to not use the CGImage API to load the pixel data, but instead use libpng directly. This works (and has the added bonus of 16-bit PNG support) but is a real pain to implement for the most part.

Another option (though this won't work in most cases) is to try and un-premult the texture in the fragment shader. However, this will only work for textures that don't have any zero alpha values, as you can simply divide the color by the alpha to (roughly) get back the original.

In the example above, here's what you get when you un-premult the texture:

![RGB / A](http://tomjbward.co.uk/wp-content/uploads/2015/07/unpremult-300x300.png)

As you can see, the areas which had a zero alpha have been lost, and another thing to watch out for is banding issues, where the 8-bit component size has lost precision, so when you divide you end up with some no so exact results (as you can see by the strange fringing).

# Summary

Although maybe not the most important thing, it's rather annoying that Apple doesn't support this relatively small feature when loading images. I hope they add support for this in a future release (maybe iOS 9, given their new MetalView support) but as there's ways to work around it, I imagine it's low on their radar.

I've uploaded a sample project to my github account [here](https://github.com/tomwardio/MetalPremultTexture)
