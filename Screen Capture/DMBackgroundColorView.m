//
//  DMBackgroundColorView.m
//  Screen Capture
//
//  Created by zhubch on 1/20/16.
//  Copyright © 2016 Levi Nunnink. All rights reserved.
//

#import "DMBackgroundColorView.h"

@implementation DMBackgroundColorView

- (void)setBackgroundColor:(NSColor *)color
{
    _backgroundColor = color;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSGraphicsContext currentContext] saveGraphicsState];
    
    if (self.backgroundColor) {
        [self.backgroundColor setFill];
        NSRectFill(dirtyRect);
    }
    
    [super drawRect:dirtyRect];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
}

@end
