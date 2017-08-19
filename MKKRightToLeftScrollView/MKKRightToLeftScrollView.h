//
//  Created by Abdullah Arif on 8/19/17.
//  Copyright © 2017 Abdullah Arif. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// NSEdgeInsetsZero & MKKEdgeInsetsEqual are only available in 10_10, so define our own
FOUNDATION_EXPORT NSEdgeInsets const MKKEdgeInsetsZero;
NS_INLINE BOOL MKKEdgeInsetsEqual(NSEdgeInsets a, NSEdgeInsets b) {
    return a.top == b.top && a.right == b.right && a.bottom == b.bottom && a.left == b.left;
}

@interface MKKRightToLeftScrollView : NSScrollView

@property IBInspectable BOOL rightToLeftLayout;
// contentInsets was only introduced in macOS 10.10
@property (readonly) BOOL supportsContentInsets;

- (IBAction)flipScrollViewLayoutDirection:(id)sender;

@end
