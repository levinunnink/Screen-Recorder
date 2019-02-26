//
//  LNControlsView.m
//  Screen Capture
//
//  Created by Levi Nunnink on 2/26/19.
//  Copyright © 2019 Levi Nunnink. All rights reserved.
//

#import "LNControlsView.h"

@implementation LNControlsView

- (void)drawRect:(NSRect)dirtyRect {
    NSBezierPath *mainPath = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:3 yRadius:3];
    [mainPath setClip];
    [[NSColor controlBackgroundColor] setFill];
    [[NSColor unemphasizedSelectedContentBackgroundColor] setStroke];
    NSRectFill(self.bounds);
    [mainPath setLineWidth:1.0];
    [mainPath stroke];
    
    // Drawing code here.
}

@end
