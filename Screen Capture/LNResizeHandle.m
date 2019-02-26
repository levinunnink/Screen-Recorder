//
//  LNResizeHandle.m
//  Screen Capture
//
//  Created by Levi Nunnink on 2/25/19.
//  Copyright © 2019 Levi Nunnink. All rights reserved.
//

#import "LNResizeHandle.h"
#import "NSBezierPath+LNExtensions.h"

@interface LNResizeHandle ()

@property (readwrite) LNResizePosition resizeLocation;

@end

@implementation LNResizeHandle

+(id)handleWithPosition:(LNResizePosition)position
{
    LNResizeHandle *handle = [LNResizeHandle layer];
    handle.resizeLocation = position;
    return handle;
}

- (id)init {
    self = [super init];
    if(self){
#if TARGET_OS_IPHONE
        self.fillColor     = [UIColor blueColor].CGColor;
        self.strokeColor   = [UIColor whiteColor].CGColor;
        self.shadowColor   = [UIColor blackColor].CGColor;
#else
        self.fillColor     = [NSColor grayColor].CGColor;
        self.strokeColor   = [NSColor whiteColor].CGColor;
        self.shadowColor   = [NSColor blackColor].CGColor;
#endif
        self.lineWidth     = 2.5; //Not sure why this needs to be 2.5 but 2.0 creates a weird artifact in mavericks
        self.shadowOpacity = 0.5;
        self.shadowRadius  = 3.0;
        self.shadowOffset  = CGSizeMake(0, 0);
        
        self.frame         = CGRectMake(0, 0, DEFAULT_HANDLE_WIDTH, DEFAULT_HANDLE_WIDTH);

    }
    return self;
}

- (BOOL)containsPoint:(CGPoint)p
{
    CGPathRef thickPath = CGPathCreateCopyByStrokingPath(self.path, NULL, 10, kCGLineCapButt, kCGLineJoinBevel, 0);
    
    return CGPathContainsPoint(thickPath, NULL, p, false);
}

- (void)setRepresentedPoint:(CGPoint)representedPoint
{
    _representedPoint = representedPoint;
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    self.position = CGPointMake(_representedPoint.x, _representedPoint.y);
    
    [CATransaction commit];
    
//    if(self.active){
        [self.delegate handle:self pointDidChangeTo:representedPoint];
//    }
}

- (CGPathRef)path
{
#if TARGET_OS_IPHONE
    return [UIBezierPath bezierPathWithOvalInRect:self.bounds].CGPath;
#else
    return [NSBezierPath bezierPathWithOvalInRect:self.bounds].CGPath;
#endif
}

- (NSCursor*)cursor
{
    switch (self.resizeLocation) {
        case LNResizePositionTop:
        case LNResizePositionBottom:
            return [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"resizenorthsouth"] hotSpot:NSMakePoint(0, 0)];
            break;
        case LNResizePositionLeft:
        case LNResizePositionRight:
            return [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"resizeeastwest"] hotSpot:NSMakePoint(0, 0)];
            break;
        case LNResizePositionBottomLeft:
        case LNResizePositionTopRight:
            return [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"resizenortheastsouthwest"] hotSpot:NSMakePoint(0, 0)];
            break;
        case LNResizePositionTopLeft:
        case LNResizePositionBottomRight:
            return [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"resizenorthwestsoutheast"] hotSpot:NSMakePoint(0, 0)];
            break;
        default:
            return [NSCursor crosshairCursor];
            break;
    }
}

@end
