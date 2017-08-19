//
//  Created by Abdullah Arif on 8/19/17.
//  Copyright © 2017 Abdullah Arif. All rights reserved.
//

#import "NSScroller+MKKRightToLeftInsets.h"
#import "MKKRightToLeftScroller.h"
#import <objc/runtime.h>

/*
 Code in this unit serves to modify _unsafeRectForPart: on all NSOverlayScrollerImp instances throughout the app.
 
 If you do not wish to swizzle on private classes/methods, delete the NSScroller+MKKRightToLeftInsets.[h|m] files
 from your project or comment out the contents thereof. Right-to-left scrollers will still show correctly,
 just not in an ideal manner.
 
 [NSScrollerImp _unsafeRectForPart:] is the source of truth for part rects even if [NSScroller rectForPart:] is overridden.

 The result from [NSScrollerImp _unsafeRectForPart:] is used internally by AppKit in a bunch of layer geometry 
 and drawing methods that cannot be safely or correctly modified otherwise.
 
 So we must modify _unsafeRectForPart: on all instances of NSOverlayScrollerImp (which inherits from NSScrollerImp)
 to have correctly mirrored vertical overlay scrollers.
*/

@interface NSScroller (MKKRightToLeftOverlayScrollerImpRuntimeInterface)

// These are properties & methods declared in NSScrollerImp (not NSScroller),
// we declare them here to avoid compiler errors.
@property NSSize boundsSize;
@property(getter=isHorizontal) BOOL horizontal;
- (MKKRightToLeftScroller*)scroller;
- (NSRect)_unsafeRectForPart:(NSScrollerPart)partCode;

// This method will be dynamically added on NSOverlayScrollerImp and
// will contain the native implementation of [NSOverlayScrollerImp _unsafeRectForPart:] during runtime
- (NSRect)mkk_original_unsafeRectForPart:(NSScrollerPart)partCode;

@end

@implementation NSScroller (MKKRightToLeftInsets)

+ (void)load
{
    // NSOverlayScrollerImp is a subclass of NSScrollerImp, both private AppKit classes
    Class mkk_NSOverlayScrollerImpClass = NSClassFromString(@"NSOverlayScrollerImp");
    
    Method original_unsafeRectForPartMethod = class_getInstanceMethod(mkk_NSOverlayScrollerImpClass, @selector(_unsafeRectForPart:));
    Method mkk_unsafeRectForPartMethod = class_getInstanceMethod([NSScroller class], @selector(mkk_unsafeRectForPart:));
    
    // Returns "{CGRect={CGPoint=dd}{CGSize=dd}}24@0:8Q16" for ->types but better not hardcode it
    struct objc_method_description* unsafeRectForPartMethodDescription = method_getDescription(original_unsafeRectForPartMethod);
    
    class_addMethod(mkk_NSOverlayScrollerImpClass, @selector(mkk_original_unsafeRectForPart:), method_getImplementation(original_unsafeRectForPartMethod), unsafeRectForPartMethodDescription->types);
    method_setImplementation(original_unsafeRectForPartMethod, method_getImplementation(mkk_unsafeRectForPartMethod));
}

/*
 During runtime, `self` in this method will be an instance of NSOverlayScrollImp or any subclass thereof.
 This method will laterally invert knob rect insets of overlay-style vertical scrollers in right-to-left layout.
 This is to ensure perfect mirroring of scrollers.
 */
- (NSRect)mkk_unsafeRectForPart:(NSScrollerPart)partCode
{
    NSRect partRect = [self mkk_original_unsafeRectForPart:partCode];
    
    // Since we're swizzling on all NSOverlayScrollImp instances we must do an extra check with isKindOfClass:
    // to see if the scroller implements the behavior we require.
    if ( !self.isHorizontal && ( partCode == NSScrollerKnob || partCode == NSScrollerKnobSlot ) && [self.scroller isKindOfClass:[MKKRightToLeftScroller class]] && [self.scroller scrollView].rightToLeftLayout && partRect.size.width != 0.0 && partRect.size.width != self.boundsSize.width ) {
        partRect.origin.x = self.boundsSize.width - ( partRect.origin.x + partRect.size.width );
    }
    
    return partRect;
}

- (BOOL)mkk_hasSwizzledPrivateMethods
{
    return YES;
}

@end
