//
//  NSBezierPath+LNExtensions.m
//  Screen Capture
//
//  Created by Levi Nunnink on 2/25/19.
//  Copyright © 2019 Levi Nunnink. All rights reserved.
//

#import "NSBezierPath+LNExtensions.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSBezierPath (LNExtensions)

static void CGPathCallback(void *info, const CGPathElement *element)
{
    NSBezierPath *path = (__bridge NSBezierPath *)(info);
    CGPoint *points = element->points;
    
    switch (element->type) {
        case kCGPathElementMoveToPoint:
        {
            [path moveToPoint:NSMakePoint(points[0].x, points[0].y)];
            break;
        }
        case kCGPathElementAddLineToPoint:
        {
            [path lineToPoint:NSMakePoint(points[0].x, points[0].y)];
            break;
        }
        case kCGPathElementAddQuadCurveToPoint:
        {
            // NOTE: This is untested.
            NSPoint currentPoint = [path currentPoint];
            NSPoint interpolatedPoint = NSMakePoint((currentPoint.x + 2*points[0].x) / 3, (currentPoint.y + 2*points[0].y) / 3);
            [path curveToPoint:NSMakePoint(points[1].x, points[1].y) controlPoint1:interpolatedPoint controlPoint2:interpolatedPoint];
            break;
        }
        case kCGPathElementAddCurveToPoint:
        {
            [path curveToPoint:NSMakePoint(points[2].x, points[2].y) controlPoint1:NSMakePoint(points[0].x, points[0].y) controlPoint2:NSMakePoint(points[1].x, points[1].y)];
            break;
        }
        case kCGPathElementCloseSubpath:
        {
            [path closePath];
            break;
        }
    }
}

- (CGPathRef)CGPath {
    int i, numElements;
    
    // Need to begin a path here.
    CGPathRef           immutablePath = NULL;
    
    // Then draw the path elements.
    numElements = (int)[self elementCount];
    if (numElements > 0)
    {
        CGMutablePathRef    path = CGPathCreateMutable();
        NSPoint             points[3];
        BOOL                didClosePath = YES;
        
        for (i = 0; i < numElements; i++)
        {
            switch ([self elementAtIndex:i associatedPoints:points])
            {
                case NSMoveToBezierPathElement:
                    CGPathMoveToPoint(path, NULL, points[0].x, points[0].y);
                    break;
                    
                case NSLineToBezierPathElement:
                    CGPathAddLineToPoint(path, NULL, points[0].x, points[0].y);
                    didClosePath = NO;
                    break;
                    
                case NSCurveToBezierPathElement:
                    CGPathAddCurveToPoint(path, NULL, points[0].x, points[0].y,
                                          points[1].x, points[1].y,
                                          points[2].x, points[2].y);
                    didClosePath = NO;
                    break;
                    
                case NSClosePathBezierPathElement:
                    CGPathCloseSubpath(path);
                    didClosePath = YES;
                    break;
            }
        }
        
        // Be sure the path is closed or Quartz may not do valid hit detection.
        if (!didClosePath)
            CGPathCloseSubpath(path);
        
        immutablePath = CGPathCreateCopy(path);
        CGPathRelease(path);
    }
    
    return immutablePath;
    
}

+ (NSBezierPath *)bezierPathWithCGPath:(CGPathRef)pathRef
{
    NSBezierPath *path = [NSBezierPath bezierPath];
    CGPathApply(pathRef, (__bridge void *)path, CGPathCallback);
    
    return path;
}

@end

NS_ASSUME_NONNULL_END
