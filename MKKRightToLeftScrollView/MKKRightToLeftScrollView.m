//
//  Created by Abdullah Arif on 8/19/17.
//  Copyright © 2017 Abdullah Arif. All rights reserved.
//

#import "MKKRightToLeftScrollView.h"
#import "MKKRightToLeftScroller.h"

NSEdgeInsets const MKKEdgeInsetsZero = {0.0, 0.0, 0.0, 0.0};

static void *MKKRightToLeftScrollViewKVOContext = &MKKRightToLeftScrollViewKVOContext;

@implementation MKKRightToLeftScrollView

@synthesize rightToLeftLayout;
@synthesize supportsContentInsets;

// @TODO: implement cornerView for legacy-style scrollers to properly match LTR look (some documentViews implement their own e.g. NSTableView)
// @TODO: add option to automatically invert lateral content insets in RTL layout
// @TODO: support ruler views

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    
    if ( self ) {
        [self commonInitializer];
        [self assignRightToLeftScrollers];
        [self registerObservers];
    }
    
    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    
    if ( self ) {
        [self commonInitializer];
    }

    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self assignRightToLeftScrollers];
    [self registerObservers];
}

- (void)commonInitializer
{
    rightToLeftLayout = YES;
    supportsContentInsets = [NSScrollView instancesRespondToSelector:NSSelectorFromString(@"automaticallyAdjustsContentInsets")];
}

- (void)assignRightToLeftScrollers
{
    // verticalScroller & horizontalScroller are automatically created by the inner machinery of
    // NSScrollView so it's relatively safe to assume they are instantiated at this point
    if ( ![self.verticalScroller isKindOfClass:[MKKRightToLeftScroller class]] ) {
        [self setVerticalScroller:[self rightToLeftScrollerInheritingFromScroller:self.verticalScroller]];
    }
    
    if ( ![self.horizontalScroller isKindOfClass:[MKKRightToLeftScroller class]] ) {
        [self setHorizontalScroller:[self rightToLeftScrollerInheritingFromScroller:self.horizontalScroller]];
    }
    
}

- (MKKRightToLeftScroller *)rightToLeftScrollerInheritingFromScroller:(NSScroller *)oldScroller
{
    MKKRightToLeftScroller *scroller = [[MKKRightToLeftScroller alloc] initWithFrame:oldScroller.frame];
    [scroller setScrollerStyle:oldScroller.scrollerStyle];
    [scroller setControlSize:oldScroller.controlSize];
    [scroller setArrowsPosition:oldScroller.arrowsPosition];
    [scroller setKnobStyle:oldScroller.knobStyle];
    
    return scroller;
}

- (void)registerObservers
{
    [self addObserver:self
           forKeyPath:NSStringFromSelector(@selector(rightToLeftLayout))
              options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
              context:MKKRightToLeftScrollViewKVOContext];
}

/*
 From https://developer.apple.com/documentation/appkit/nsscrollview/1403509-tile?language=objc
    > Lays out the components of the receiver: the content view, the scrollers, and the ruler views.
 
 So we reset frame origins for those components in right-to-left layout (ruler views are not supported)
 */
- (void)tile
{
    // Calling super will properly layout subviews in the default orientation
    // accounting for findBar visibility/expansion, borderType, contentInsets (if any), and scrollerStyle & visibility
    [super tile];

    // No further adjustments are needed in left-to-right layout
    if ( !self.rightToLeftLayout ) {
        return;
    }
    
    // Get vertical scroller thickness
    CGFloat verticalScrollbarWidth = [[self.verticalScroller class] scrollerWidthForControlSize:self.verticalScroller.controlSize
                                                                                  scrollerStyle:self.verticalScroller.scrollerStyle];
    
    // Don't calculate borderType into this because the [super tile] automatically insets contentView's frame with border thickness
    CGFloat verticalScrollersSideOffset = 0.0;
    
    if ( self.hasVerticalScroller && self.verticalScroller.scrollerStyle == NSScrollerStyleLegacy && !self.verticalScroller.isHidden ) {
        verticalScrollersSideOffset = verticalScrollbarWidth;
    }
    
    // The contentView's frame should remain identical to what it is in
    // left-to-right layout if there's nothing to horizontally offset
    if ( verticalScrollersSideOffset == 0.0 ) {
        return;
    }
    
    // macOS 10.10 introduces contentInsets on NSClipView
    // We need to laterally invert the calculated vertical scroller's inset on that property if any
    if ( self.supportsContentInsets ) {
        /*
         From https://developer.apple.com/documentation/appkit/nsscrollview/1403461-contentinsets?language=objc
            > When the value of this property is not equal to NSEdgeInsetsZero, the rulers, headers, and other subviews are inset as specified. The
            > contentView is placed underneath these sibling views and is only inset by the scroll view border and non-overlay scrollers.
         
         The last sentence refers to the frame origin.
         Additionally, and I don't know if this is a bug, but if contentInsets.right == 0, it offsets
         the contentView frame by the vertical scroller's width instead of adjusting its contentInsets (for legacy scrollers).
        */
        if ( !MKKEdgeInsetsEqual(self.contentInsets, MKKEdgeInsetsZero) && self.contentInsets.right != 0.0 ) {
            NSEdgeInsets calculatedInsets = self.contentView.contentInsets;
            NSEdgeInsets flippedInsets = NSEdgeInsetsMake(calculatedInsets.top, calculatedInsets.left + verticalScrollersSideOffset, calculatedInsets.bottom, calculatedInsets.right - verticalScrollersSideOffset);
            [self.contentView setContentInsets:flippedInsets];
            return;
        }
    }
    
    /*
     Finally, offset clipView from the left side instead of right in right-to-left layout.
     This is only needed when legacy-style scrollers are showing (e.g. if set, or when mouse is plugged in, if that preference is enabled).
     Otherwise the scrollers are overlain on the contentView.
     */
    [self.contentView setFrameOrigin:NSMakePoint(self.contentView.frame.origin.x + verticalScrollersSideOffset, self.contentView.frame.origin.y)];
}


// Ensure that scroller placement is immediately reflected in UI when rightToLeftLayout changes
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ( context == MKKRightToLeftScrollViewKVOContext ) {
        if ( [keyPath isEqualToString:NSStringFromSelector(@selector(rightToLeftLayout))] ) {
            if ( change[NSKeyValueChangeOldKey] != change[NSKeyValueChangeNewKey] ) {
                [self tile];
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(rightToLeftLayout))];
}

- (IBAction)flipScrollViewLayoutDirection:(id)sender
{
    [self setRightToLeftLayout:!self.rightToLeftLayout];
}


@end
