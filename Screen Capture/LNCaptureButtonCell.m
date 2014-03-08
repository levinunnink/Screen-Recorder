//
//  SCCaptureButtonCell.m
//  Screen Capture
//
//  Created by Levi Nunnink on 3/7/14.
//  Copyright (c) 2014 Levi Nunnink. All rights reserved.
//

#import "LNCaptureButtonCell.h"

@implementation LNCaptureButtonCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSBezierPath *bgPath = [NSBezierPath bezierPathWithRoundedRect:controlView.bounds xRadius:12 yRadius:20];
    [bgPath setClip];

    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.8f] setFill];
    
    if (self.isHighlighted) {
        [[NSColor blackColor] setFill];
    }
    
    NSRectFill(cellFrame);
    
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    
    paragraph.alignment = NSCenterTextAlignment;
    
    NSDictionary *stringAttributes = @{NSForegroundColorAttributeName : !self.isHighlighted ? [NSColor colorWithCalibratedWhite:1.0 alpha:1.0] : [NSColor colorWithCalibratedWhite:1.0 alpha:0.5],
                                       NSFontAttributeName : [NSFont boldSystemFontOfSize:12.0],
                                       NSParagraphStyleAttributeName : paragraph};
    
    [self.title drawInRect:NSOffsetRect(cellFrame, 0, 3) withAttributes:stringAttributes];
}

@end
