//
//  LNOverlayView.h
//  Screen Capture
//
//  Created by Levi Nunnink on 3/7/14.
//  Copyright (c) 2014 Levi Nunnink. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern CGFloat LNOverlayViewStandardRadius;

@interface LNOverlayView : NSView

@property CGFloat bezelRadius;
@property (copy) NSString *label;

- (void)centerInSuperview;

@end
