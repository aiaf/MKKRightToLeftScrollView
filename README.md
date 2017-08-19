# MKKRightToLeftScrollView
MKKRightToLeftScrollView laterally inverts scrollers on macOS. This means that the vertical scrollers appear on the left side instead of the right.

This is useful for content that is oriented from right-to-left, such as an `NSTextView` with Arabic text.

On macOS 10.12, horizontally inverted scrollers were natively implemented, but require that `[NSApp userInterfaceLayoutDirection]` be set to `NSUserInterfaceLayoutDirectionRightToLeft`, which is not programmatically controllable. 

In other words, the app's `userInterfaceLayoutDirection` affects all `NSScrollView`s in the app, hardly desirable for most use cases.

Additionally, the native implementation does not correctly mirror vertical scrollers.

The code subclasses `NSScrollView` and `NSScroller`.
There's also optional, but recommended, private method swizzling on `NSOverlayScrollerImp`.

`contentInsets` introduced in macOS 10.10 are also supported.

This code was originally created for [Katib](https://katibapp.com/)

## License
Code is released under the MIT license. Refer to LICENSE for details.

## macOS Version Compatibility
Minimally macOS 10.8
Although there's a chance it could work on 10.7. Have not tested.

## Usage
In Interface Builder, locate the Scroll View and set its class to `MKKRightToLeftScrollView` in the Identity inspector. Additionally set both Scroller classes to `MKKRightToLeftScroller`, though this is not strictly required, it's efficient.

By default, `rightToLeftLayout` is enabled. This can also be modified from IB in the Attributes inspector or programatically.

To create `MKKRightToLeftScrollView` programmatically, refer to [Apple's guide](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/TextUILayer/Tasks/TextInScrollView.html) on the topic, but replace every `NSScrollView` with `MKKRightToLeftScrollView`.

### Method swizzling on private classes
Because of some rather unfortunate private implementation bugs by the NSScroller's `NSScrollerImp` class, overriding [`NSScroller rectForPart:]` does not influence the layer rects the private implementation uses for overlay-style scrollers.

A side effect of that is vertical scrollers appearing offset more than desired from the edge of the scrollView, and clipping artifacts whenever any attempt is made to re-position the scroller's frame or drawing coordinates.

We override `[NSOverlayScroller _unsafeRectForPart:]` in `NSScroller+MKKRightToLeftInsets.{h|m}`. If for some reason your app gets rejected or you do not wish to swizzle on private classes, delete those files. A less than ideal fallback will take its place, but the visual results should be identical. Consult the code for details.

## Support
https://github.com/aiaf/MKKRightToLeftScrollView/issues