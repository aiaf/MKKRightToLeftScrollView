//
//  Created by Abdullah Arif on 8/19/17.
//  Copyright © 2017 Abdullah Arif. All rights reserved.
//

#import "MKKRightToLeftScroller.h"
#import <objc/runtime.h>

/* 
 MKKRightToLeftScroller should only be used as a direct subview (as vertical/horizontal scrollers) of MKKRightToLeftScrollView.
 Any other configuration will quickly break things.
*/

@implementation MKKRightToLeftScroller

+ (BOOL)isCompatibleWithOverlayScrollers
{
    return self == [MKKRightToLeftScroller class];
}

- (MKKRightToLeftScrollView *)scrollView
{
    // enclosingScrollView returns NULL here for some reason.
    // Probably not meant to be used with NSScroller
    return (MKKRightToLeftScrollView *)self.superview;
}

#pragma mark Conditional Layout Overrides

/*
 If you decide to not swizzle private methods on NSOverlayScrollerImp, convertRectToLayer: & convertRectToBacking: will be overridden.
 These are invoked with NSScrollerPart rects by [NSScrollerImp _unsafeRectForPart:] (the source of truth for all NSScroller rects).
 _unsafeRectForPart: does not respect the result from [NSScroller rectForPart:] for overlay scrollers, so overriding/re-implementing it is pointless.
 
 In essence, we modify the vertical scroller knob rects so they are flush with the left edge within the overlay scroller bounds in RTL layout.
 
 This is slightly more hacky than swizzling private methods, believe it or not, because it does not discriminate
 between scroller parts and it simply resets the horizontal origin instead of laterally inverting it.
 However, visual results are nearly identical for the current use case.
 
 Note: if you want to avoid private method swizzling, simply delete NSScroller+MKKRightToLeftInsets.[h|m] from your project.
 */

+ (void)load
{
    /*
     Keep in mind that, as per the docs:
        > A class’s +load method is called after all of its superclasses’ +load methods.
        > A category +load method is called after the class’s own +load method.
     
     Therefore, the following condition should correctly tell us whether the swizzling has occured or not:
     */
        
    if ( ![NSScroller.class instancesRespondToSelector:NSSelectorFromString(@"mkk_hasSwizzledPrivateMethods")] ) {
        Class selfClass = [self class];
        
        struct objc_method_description* convertRectToLayerMethodDescription = method_getDescription(class_getInstanceMethod(selfClass, @selector(convertRectToLayer:)));
        struct objc_method_description* convertRectToBackingMethodDescription = method_getDescription(class_getInstanceMethod(selfClass, @selector(convertRectToBacking:)));
        
        class_addMethod(selfClass, @selector(convertRectToLayer:), method_getImplementation(class_getInstanceMethod(selfClass, @selector(dormant_convertRectToLayer:))), convertRectToLayerMethodDescription->types);
        class_addMethod(selfClass, @selector(convertRectToBacking:), method_getImplementation(class_getInstanceMethod(selfClass, @selector(dormant_convertRectToBacking:))), convertRectToBackingMethodDescription->types);
    }
}

// In my debugging, all calls to convertRectTo[Layer|Backing]: originated from [NSScrollerImp _unsafeRectForPart:]
- (NSRect)dormant_convertRectToLayer:(NSRect)aRect
{
    if ( !sFlags.isHoriz && self.scrollerStyle == NSScrollerStyleOverlay && [self scrollView].rightToLeftLayout && aRect.origin.x != 0.0 ) {
        aRect.origin.x = 0.0;
    }
    
    return [super convertRectToLayer:aRect];
}

- (NSRect)dormant_convertRectToBacking:(NSRect)aRect
{
    if ( !sFlags.isHoriz && self.scrollerStyle == NSScrollerStyleOverlay && [self scrollView].rightToLeftLayout && aRect.origin.x != 0.0 ) {
        aRect.origin.x = 0.0;
    }
    
    return [super convertRectToBacking:aRect];
}


#pragma mark Layout & Positioning

/*
 We override setFrame: and setFrameOrigin: to move the scroller to the left edge in right-to-left layout.
 
 The rest of the necessary layout logic is in the MKKRightToLeftScrollView:
 [NSScrollView _applyContentAreaLayout:] called from [NSScrollView tile] invokes setFrame: on the scroller to position it normatively.
 
 The logic within _applyContentAreaLayout: does not take into account contenView.frame.origin to position layout scrollers
 so we cannot influence scroller positioning by adjusting the contentView.
 
 Additionally, invoking setFrame: after [NSScrollView tile] has already run
 will misplace the private _cornerView, necessitating another call to tile.
 
 This makes for, unfortunately, tighter coupling between the scroller and the scrollView,
 but directly overriding setFrame/Origin is the only realistic option outside of implementing tiling from scratch.
 */

- (void)setFrame:(NSRect)frame
{
    if ( [self scrollView].rightToLeftLayout ) {
        frame.origin.x = [self rightToLeftFrameOriginX];
    }
    
    [super setFrame:frame];
}

// In case this gets called independently from setFrame, we reset the origin here as well
- (void)setFrameOrigin:(NSPoint)newOrigin
{
    if ( [self scrollView].rightToLeftLayout ) {
        newOrigin.x = [self rightToLeftFrameOriginX];
    }
    
    [super setFrameOrigin:newOrigin];
}

- (CGFloat)rightToLeftFrameOriginX
{
    CGFloat originX = 0.0;
    MKKRightToLeftScrollView *sV = [self scrollView];
    
    if ( sV.supportsContentInsets ) {
        originX += sV.contentInsets.left + sV.scrollerInsets.left;
    }
    
    CGFloat borderOffset = 0.0;
    
    switch ( sV.borderType ) {
        case NSNoBorder:
            borderOffset = 0.0;
            break;
        case NSLineBorder:
            borderOffset = 1.0;
            break;
        case NSBezelBorder:
            borderOffset = 1.0;
            break;
        case NSGrooveBorder:
            borderOffset = 2.0;
            break;
        default:
            borderOffset = 0.0;
            break;
    }
    
    if ( sFlags.isHoriz ) {
        if ( self.scrollerStyle == NSScrollerStyleLegacy ) {
            if ( sV.hasVerticalScroller && !sV.verticalScroller.isHidden ) {
                originX += [sV.verticalScroller.class scrollerWidthForControlSize:sV.verticalScroller.controlSize scrollerStyle:sV.verticalScroller.scrollerStyle];
            }
        } else {
            originX += borderOffset;
        }
    } else {
        originX += borderOffset;
    }
    
    return originX;
}

#pragma mark Flipping

/*
 Laterally inverting drawing coordinates is necessary because the knob & slot
 do not have equal left & right insets in left-to-right layout.
 
 NSScroller's private machinery does not make it easy to invert these insets. 
 
 Additionally the overlay-style expansion animation grows from the closest edge of the scrollView.
 
 We must correctly mirror the visual result.
 */

- (void)drawKnob
{
    [self flipHorizontalCoordinatesInRightToLeftLayoutForPart:NSScrollerKnob];
    [super drawKnob];
}

- (void)drawKnobSlotInRect:(NSRect)slotRect highlight:(BOOL)flag
{
    [self flipHorizontalCoordinatesInRightToLeftLayoutForPart:NSScrollerKnobSlot];
    [super drawKnobSlotInRect:slotRect highlight:flag];
}

- (void)flipHorizontalCoordinatesInRightToLeftLayoutForPart:(NSScrollerPart)part
{
    if ( !sFlags.isHoriz && [self scrollView].rightToLeftLayout ) {
        // Laterally invert coordinates in the current graphics context
        NSAffineTransform* flip = [NSAffineTransform transform];
        [flip translateXBy:[self rectForPart:part].size.width yBy:0.0];
        [flip scaleXBy:-1.0 yBy:1.0];
        [flip concat];
    }
}

@end
