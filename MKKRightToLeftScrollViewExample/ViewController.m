//
//  Created by Abdullah Arif on 8/10/17.
//  Copyright © 2017 Abdullah Arif. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

- (void)viewDidAppear {
    [super viewDidAppear];
    
    NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:[@"" stringByPaddingToLength:4000 withString: @"رائع! " startingAtIndex:0]];
    [string addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Courier New" size:16.0] range:NSMakeRange(0, [string length])];
     
    [self.textView.textStorage setAttributedString:string];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
