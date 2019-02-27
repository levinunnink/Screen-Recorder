//
//  LNWindowSelector.m
//  Screen Capture
//
//  Created by Levi Nunnink on 2/27/19.
//  Copyright © 2019 Levi Nunnink. All rights reserved.
//

#import "LNWindowSelector.h"

@implementation LNWindowSelector

- (BOOL)containsPoint:(CGPoint)p
{
    CGPathRef thickPath = CGPathCreateCopyByStrokingPath(self.path, NULL, 10, kCGLineCapButt, kCGLineJoinBevel, 0);
    
    return CGPathContainsPoint(thickPath, NULL, p, false);
}

@end
