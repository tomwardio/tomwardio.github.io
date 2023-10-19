---
layout: post
title: 3D Camera Controls
subtitle: Examples of doing camera controls in C++.
permalink: 3d-camera-controls
categories:
  - Tech
  - 3D
tags:
  - 3d math
  - cameras
  - quaternions
  - matrix
  - opengl
  - viewmatrix
  - orbiting
  - lookat
---

In my spare time I've started working on making my own little model viewer in
OpenGL (more on this later) and I've recently been working on creating some nice
camera controls. Although I've had to delve into cameras a few times over the
years, this is the first time I'd had to create one from scratch and was quite
an experience! I also found the help online to be a bit sparse, with various
ways of doing it but none I really liked.

Here's what I learnt and snippets of my final solution, I haven't gone into the
nitty gritty of all the math functions, but there's plenty of places to find
that stuff.

# First Things First, Looking at a Point

Firstly I wanted to make a camera that I could position in world space, looking
at a particular point which I could later use to orbit around. This was
relatively simple to do by writing a LookAt function that would take a camera
position, target position and up direction (which in this case would be positive
Y) to produce a view matrix. This is what I came up with which I basically
nicked from [here](http://www.opengl.org/wiki/GluLookAt_code):

```cpp
inline
Matrix44 Matrix44FromLookAt(
    const Vector3& lvEyePosition,
    const Vector3& lvTargetPosition,
    const Vector3& lvUp )
{
    Vector3 lvAt = Normalize( lvTargetPosition - lvEyePosition );
    M_ASSERT( IsValid( lvAt ) );
    Vector3 lvRight = Normalize( Cross( lvAt, lvUp ) );
    M_ASSERT( IsValid( lvRight ) );
    Vector3 lvPlane = Cross( lvRight, lvAt );
    M_ASSERT( IsValid( lvPlane ) );

    Matrix44 lLookAt;
    lLookAt.SetIdentity();
    lLookAt.SetRowX( Vector4( lvRight, -Dot( lvRight, lvEyePosition ) ) );
    lLookAt.SetRowY( Vector4( lvPlane, -Dot( lvPlane, lvEyePosition ) ) );
    lLookAt.SetRowZ( Vector4( -lvAt, Dot(lvAt, lvEyePosition ) ) );
    return lLookAt;
}
```

That worked pretty well for setting up the camera to look at an object, so I
began by storing my position, target and up direction in my camera class, then
calculating the resulting matrix on demand using the above code.

# Zooming the Camera

With my camera setup, I then proceeded to add the ability to zoom the camera. I
did this first basically because I thought it would be the easiest to do! This
was indeed very simple, basically all I did was get the vector between the
camera position and the target position, then multiply this by a "zoom factor"
(how quickly I want to zoom by) and add this vector to the camera position to
move it closer/farther from the target pos. I did start by using a set distance
to zoom by (so say 1m) but this caused it to feel like it was zooming a lot when
close up and not much at all when far away, so instead I went for a percentage.
Here's the code:

```cpp
void
Camera::ZoomCamera(
    const float32_t& lfZoomFactor )
{
    Vector3 lvCameraDirection = GetTargetPosition() - GetPosition();

    // if we don't have a direction, we can't zoom
    if( !IsZero( lvCameraDirection ) )
    {
        lvCameraDirection *= lvfZoomFactor;

        SetPosition( GetPosition() + lvCameraDirection );
    }
}
```

Really simple stuff, one thing I should probably add is a minimum/maximum
distance to zoom to prevent getting stuck at the extents, but I haven't managed
to look at that yet.

# Next, Panning

With the simple movement out of the way, I looked at being able to pan the
camera. The first thing that became apparent here is that I needed not only to
move the camera position, but also the target position in order to retain the
same look direction, and to maintain the same orbit "feel".

I began this by trying to use the "right" vector of the camera in world space
(calculated the cross product of the look at direction by the camera up), as I
figured this would allow me to move perpendicular to the target position a
certain amount. This didn't really work though because the direction I was
moving in was screen space and not world space, so instead I had to get the
right vector for the viewmatrix instead. Once I had the correct direction, I
could then multiply this by a panning amount in both the X and Y to get the pan
translation in world space. Adding this to both the camera position and target
produced a nice smooth camera pan in both the X and Y, whilst still retaining my
looking direction. Here's the code:

```cpp
void
Camera::PanCamera(
const Vector2& lvScreenPanAmount )
{
    Matrix44 lViewMatrix = GetViewMatrix();

    const Vector3 lvCameraUp = Normalize( GetCameraUp() );

    Vector3 lvWorldPanAmount;
    lvWorldPanAmount += GetXYZ( lViewMatrix.GetRowY() ) * lvScreenPanAmount.GetY();
    lvWorldPanAmount -= GetXYZ( lViewMatrix.GetRowX() ) * lvScreenPanAmount.GetX(); // reversed as it makes more sense!

    Vector3 lvNewPosition = GetPosition() + lvWorldPanAmount;
    Vector3 lvNewTarget = GetTargetPosition() + lvWorldPanAmount;

    SetPosition(lvNewPosition);
    SetTargetPosition(lvNewTarget);
}
```

# The ellusive orbit

With panning and zooming sorted, the final movement I wanted was to be able to
orbit around the target position. Recall I'm currently storing the target
position, camera position and up direction for the camera and computing the
lookat matrix from these components. Therefore all I needed to do was to rotate
about the target position a certain amount (in radians) and translate by the
current position to target distance in order to obtain my new look at position.
I began by rotating just around the world up direction, which I did using the
following to great success:

```cpp
    Math::VPU::Matrix44 lRotationMatrix;
    lRotationMatrix.SetIdentity();
    lRotationMatrix.RotateYAxis( Math::ToRadians( lvfRotationAmount ) );

    // Get the direction from target position to the camera. This might seem a little backward, but we want to rotate
    // around the target and not the camera position
    Math::VPU::Vector3 lvTargetToCameraDirection = lpCamera->GetCameraPosition() - lpCamera->GetTargetPosition();

    // rotate the target to camera direction
    lvTargetToCameraDirection = (lvTargetToCameraDirection * lRotationMatrix);

    lpCamera->SetCameraPosition( lvTargetToCameraDirection + lpCamera->GetTargetPosition() );
```

This worked pretty well as I'm only rotating in one axis (the XZ plane). The
problems started happening when I began trying to rotate in all three
directions. The problem was I was trying to rotate a matrix around a given axis
a certain amount, which was done using euler angles. I don't want to get bogged
down explaining quaternions (take a look on google!), but basically I ended up
getting into gimbal lock and all kinds of things. The solution was instead of
using the lookat function above for calculating my view matrix, I instead stored
my direction as a quaternion and created my view matrix from this. After I'd
done this I completely fixed my rotation woes, ensuring a nice smoooth orbit.
There was one final thing that didn't feel quite right, and that was how I
rotated in the XZ plane. I found it just felt better doing so always around the
world up rather than the camera up, but this is kind of down to personal
preference (it's more "correct" to rotate around the camera up).

Here's the code I ended up with, which produced a nice orbit:

```cpp
void
Camera::OrbitCamera(
    const Vector2& lvOrbitAmount )
{
    // Get the direction from target position to the camera. This might seem a little backward, but we want to rotate
    // around the target and not the camera position
    Vector3 lvRelativePos = GetPosition() - GetTargetPosition();

    Vector3 lvAxis = Normalize( Cross( GetCameraUp(), lvRelativePos ) );

    Quaternion lRotationAmount = QuaternionFromAxisRotationAngle( lvAxis, ToRadians( lvOrbitAmount.GetY() ) );
    lRotationAmount *= QuaternionFromAxisRotationAngle( Vector3(0.0f, 1.0f, 0.0f), ToRadians( lvOrbitAmount.GetX() ) );

    Matrix44 lRotationMatrix = lRotationMatrix = Matrix44FromQuaternion( lRotationAmount );

    SetPosition( GetTargetPosition() + ( lvRelativePos * lRotationMatrix ) );
    SetRotation( GetRotation() * lRotationAmount );
    SetCameraUp( Normalize( GetCameraUp() * lRotationMatrix ) );
}
```

# Summary

I never really found any great examples of doing this stuff, so hopefully this
little post will help some poor soul out in the future. I found it infuriating
at times trying to work out where in my matrix math code I was going wrong, but
it was pretty rewarding once I finally figured it all out.
