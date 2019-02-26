//
//  SCCapturePanel.m
//  Screen Capture
//
//  Created by Levi Nunnink on 3/6/14.
//  Copyright (c) 2014 Levi Nunnink. All rights reserved.
//

#import "LNCapturePanel.h"
#import <QuartzCore/QuartzCore.h>
#import "LNResizeHandle.h"

#define kCropRectKey @"LNCropRectKey"

@interface SCCapturePanelBackgroundView : NSView <LNLayerHandleDelegate>

@property (nonatomic, assign) NSRect cropRect;
@property (nonatomic, strong) CAShapeLayer *cropLine;
@property (strong) LNResizeHandle *topLeftHandle;
@property (strong) LNResizeHandle *topRightHandle;
@property (strong) LNResizeHandle *bottomLeftHandle;
@property (strong) LNResizeHandle *bottomRightHandle;
@property (strong) LNResizeHandle *topHandle;
@property (strong) LNResizeHandle *rightHandle;
@property (strong) LNResizeHandle *leftHandle;
@property (strong) LNResizeHandle *bottomHandle;
@property (strong) CALayer *backgroundColorLayer;
@property (assign) CGPoint startPoint;
@property (assign) CGRect startRect;
@property (assign) LNResizeHandle *activeHandle;

@end


@interface LNCapturePanel ()

@property (strong) SCCapturePanelBackgroundView* bgView;

@end

@implementation SCCapturePanelBackgroundView

- (id) initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    [self setWantsLayer:YES];
    
    if (self) {
        [self setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
        [self setAutoresizesSubviews:YES];
        self.backgroundColorLayer = [CALayer layer];
        self.backgroundColorLayer.bounds = self.bounds;
        self.backgroundColorLayer.backgroundColor = [NSColor colorWithWhite:0.0 alpha:0.5].CGColor;
        [[self layer] addSublayer:self.backgroundColorLayer];

        // 8 resize handles, y'all
        self.topLeftHandle = [LNResizeHandle handleWithPosition:LNResizePositionTopLeft];
        self.topRightHandle = [LNResizeHandle handleWithPosition:LNResizePositionTopRight];
        self.bottomLeftHandle = [LNResizeHandle handleWithPosition:LNResizePositionBottomLeft];
        self.bottomRightHandle = [LNResizeHandle handleWithPosition:LNResizePositionBottomRight];
        self.topHandle = [LNResizeHandle handleWithPosition:LNResizePositionTop];
        self.rightHandle = [LNResizeHandle handleWithPosition:LNResizePositionRight];
        self.bottomHandle = [LNResizeHandle handleWithPosition:LNResizePositionBottom];
        self.leftHandle = [LNResizeHandle handleWithPosition:LNResizePositionLeft];
        self.topLeftHandle.delegate = self;
        self.topRightHandle.delegate = self;
        self.bottomLeftHandle.delegate = self;
        self.bottomRightHandle.delegate = self;
        self.topHandle.delegate = self;
        self.rightHandle.delegate = self;
        self.bottomHandle.delegate = self;
        self.leftHandle.delegate = self;
    }
    
    return self;
}

- (void)setCropRect:(NSRect)cropRect
{
    if(cropRect.size.height == 0 || cropRect.size.width == 0) {
//        self.layer.mask = nil;
//        [self.cropLine setHidden:YES];
        return;
    }
    _cropRect = cropRect;
    [CATransaction begin];
    [CATransaction setDisableActions: YES];
    
    self.topLeftHandle.position = CGPointMake(cropRect.origin.x, cropRect.origin.y + cropRect.size.height);
    self.topRightHandle.position = CGPointMake(cropRect.origin.x + cropRect.size.width, cropRect.origin.y + cropRect.size.height);
    self.bottomLeftHandle.position = CGPointMake(cropRect.origin.x, cropRect.origin.y);
    self.bottomRightHandle.position = CGPointMake(cropRect.origin.x + cropRect.size.width, cropRect.origin.y);
    self.topHandle.position = CGPointMake(cropRect.origin.x + (cropRect.size.width / 2), cropRect.origin.y + cropRect.size.height);
    self.rightHandle.position = CGPointMake(cropRect.origin.x + cropRect.size.width, cropRect.origin.y + (cropRect.size.height / 2));
    self.bottomHandle.position = CGPointMake(cropRect.origin.x + (cropRect.size.width / 2), cropRect.origin.y);
    self.leftHandle.position = CGPointMake(cropRect.origin.x, cropRect.origin.y + (cropRect.size.height / 2));
    
    CAShapeLayer *maskLayer;
    if(self.layer.mask) {
        maskLayer = self.layer.mask;
    } else {
        maskLayer = [CAShapeLayer layer];
    }
    CGMutablePathRef maskPath = CGPathCreateMutable();
    CGPathAddRect(maskPath, NULL, self.bounds); // this line is new
    CGPathRef cropRectPath = CGPathCreateWithRect(cropRect, nil);
    CGPathAddPath(maskPath, nil, cropRectPath );
    CGPathRelease(cropRectPath);
    [maskLayer setPath:maskPath];
    maskLayer.fillRule = kCAFillRuleEvenOdd;         // this line is new
    CGPathRelease(maskPath);
    self.backgroundColorLayer.mask = maskLayer;
    
    if(!self.cropLine) {
        self.cropLine = [CAShapeLayer layer];
        self.cropLine.backgroundColor = [NSColor clearColor].CGColor;
        self.cropLine.fillColor = [NSColor clearColor].CGColor;
        self.cropLine.strokeColor = [NSColor whiteColor].CGColor;
        self.cropLine.lineWidth = 1;
        self.cropLine.lineJoin = kCALineJoinRound;
        self.cropLine.lineDashPattern = @[@(4), @(4)];
        [self.layer addSublayer:self.cropLine];
    }
    
    [self.layer addSublayer:self.topLeftHandle];
    [self.layer addSublayer:self.topRightHandle];
    [self.layer addSublayer:self.bottomLeftHandle];
    [self.layer addSublayer:self.bottomRightHandle];
    [self.layer addSublayer:self.topHandle];
    [self.layer addSublayer:self.rightHandle];
    [self.layer addSublayer:self.bottomHandle];
    [self.layer addSublayer:self.leftHandle];

    CGPathRef linePath = CGPathCreateWithRect((CGRect){
        cropRect.origin.x - 1,
        cropRect.origin.y - 1,
        cropRect.size.width + 2,
        cropRect.size.height + 2,
    }, nil);
    
    self.cropLine.path = linePath;
    
    CGPathRelease(linePath);
    
    [CATransaction commit];
    
    [[NSUserDefaults standardUserDefaults] setObject:NSStringFromRect(cropRect) forKey:kCropRectKey];
}

- (void)mouseEntered:(NSEvent *)event
{
    [[NSCursor crosshairCursor] push];
}

- (void)mouseExited:(NSEvent *)event
{
    [[NSCursor crosshairCursor] pop];
}

- (void)mouseMoved:(NSEvent *)event
{
    DMARK;
    CGPoint point = [self convertPoint:event.locationInWindow fromView:nil];
    CALayer* layer = [self.layer hitTest:point];
    DLOG(@"Layer %@", layer);
    if ([layer isKindOfClass:[LNResizeHandle class]]) {
        [[(LNResizeHandle*)layer cursor] push];
//        [self handle:(LNResizeHandle*)layer pointDidChangeTo:point];
        return;
    } else if (CGRectContainsPoint(self.cropRect, point)) {
        [[NSCursor openHandCursor] push];
//        [self moveCropRectFromPoint:self.startPoint ToPoint:point];
        return;
    } else {
        [[NSCursor arrowCursor] set];
    }
}

- (void)mouseDragged:(NSEvent *)event
{
    CGPoint point = [self convertPoint:event.locationInWindow fromView:nil];
    if (self.activeHandle) {
        [self.activeHandle setRepresentedPoint:point];
        return;
    } else if (CGRectContainsPoint(self.cropRect, point)) {
        [self moveCropRectFromPoint:self.startPoint ToPoint:point];
        return;
    } else {
        [[NSCursor arrowCursor] set];
    }

}

- (void)mouseDown:(NSEvent *)theEvent
{
    DMARK;
    CGPoint point = [self convertPoint:theEvent.locationInWindow fromView:nil];
    CALayer* layer = [self.layer hitTest:point];
    
    if ([layer isKindOfClass:[LNResizeHandle class]]) {
        DLOG(@"LNResizeHandle click");
        self.activeHandle = (LNResizeHandle*)layer;
        return;
    }
    if(CGRectContainsPoint(self.cropRect, point))  {
        DLOG(@"cropLayerClick");
        self.startPoint = point;
        self.startRect = self.cropRect;
        return;
    }
}

- (void)mouseUp:(NSEvent *)event
{
    self.activeHandle = nil;
}

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    [self addTrackingArea:[[NSTrackingArea alloc] initWithRect:self.frame options:NSTrackingMouseMoved+NSTrackingActiveAlways owner:self userInfo:nil]];
}

- (void)setFrame:(NSRect)frameRect
{
    [super setFrame:frameRect];
    [CATransaction begin];
    [CATransaction setDisableActions: YES];
    self.backgroundColorLayer.frame = CGRectMake(0, 0, frameRect.size.width, frameRect.size.height);
    [CATransaction commit];
    [self updateTrackingAreas];
}

#pragma mark - LNLayerHandleDelegate

- (void)moveCropRectFromPoint:(CGPoint)point ToPoint:(CGPoint)newPoint
{
    CGPoint difference = (CGPoint) {
        newPoint.x - point.x,
        newPoint.y - point.y,
    };
    CGRect newRect = self.startRect;
    newRect = CGRectApplyAffineTransform(newRect, CGAffineTransformMakeTranslation(difference.x, difference.y));
    [self setCropRect:newRect];
}

- (void)handle:(LNResizeHandle*)sender pointDidChangeTo:(CGPoint)point;
{
    CGRect bounding = self.cropRect;
    
    if (sender.resizeLocation == LNResizePositionTop) {
        CGFloat initialY = bounding.origin.y;
        bounding.size.height = point.y - initialY;
        bounding.origin.y    = initialY;
        return [self setCropRect:bounding];
    }
    
    if (sender.resizeLocation == LNResizePositionBottom) {
        bounding.size.height = bounding.size.height - (point.y - bounding.origin.y);
        bounding.origin.y    = point.y;
        return [self setCropRect:bounding];
    }
    
    if (sender.resizeLocation == LNResizePositionRight) {
        bounding.size.width = CGRectGetWidth(bounding) + (point.x - CGRectGetWidth(bounding) - CGRectGetMinX(bounding));
        return [self setCropRect:bounding];
    }
    
    if (sender.resizeLocation == LNResizePositionLeft) {
        bounding.size.width = CGRectGetWidth(bounding) - (point.x - CGRectGetMinX(bounding));
        bounding.origin.x = point.x;
        return [self setCropRect:bounding];
    }
    
    if (sender.resizeLocation == LNResizePositionTopLeft || sender.resizeLocation == LNResizePositionBottomLeft) {
        bounding.size.width = CGRectGetWidth(bounding) + (CGRectGetMinX(bounding) - point.x);
        bounding.origin.x   = point.x;
        //Right Handle X
    }else{
        bounding.size.width -= CGRectGetMaxX(bounding) - point.x;
    }
    
    //Top Handle Y
    if (sender.resizeLocation == LNResizePositionTopLeft || sender.resizeLocation == LNResizePositionTopRight) {
        bounding.size.height = CGRectGetHeight(bounding) - (CGRectGetMaxY(bounding) - point.y);
        bounding.origin.y    = point.y - CGRectGetHeight(bounding);
        //Bottom Handle Y
    }else{
        bounding.size.height = CGRectGetHeight(bounding) + (CGRectGetMinY(bounding) - point.y);
        bounding.origin.y    = point.y;
    }
    
    [self setCropRect:bounding];
}

@end

@implementation LNCapturePanel

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)aStyle
                  backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    self = [super initWithContentRect:NSZeroRect styleMask:aStyle
                              backing:NSBackingStoreBuffered defer:NO];
    [self setFloatingPanel:YES];
    [self setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary];
    [self setBackgroundColor:[NSColor clearColor]];
    [self setMovableByWindowBackground:NO];
    [self setExcludedFromWindowsMenu:YES];
    [self setAlphaValue:1.0];
    [self setOpaque:NO];
    [self setHasShadow:NO];
    [self setHidesOnDeactivate:NO];
    [self setLevel:NSStatusWindowLevel];
    [self setRestorable:NO];
    [self disableSnapshotRestoration];
    [self setIgnoresMouseEvents:NO];
    
    self.bgView = [[SCCapturePanelBackgroundView alloc] initWithFrame:contentRect];
    self.bgView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self.contentView addSubview:self.bgView];
    
    NSString *rectString = [[NSUserDefaults standardUserDefaults] stringForKey:kCropRectKey];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        if(rectString) [self setCropRect:NSRectFromString(rectString)];
        [self setCropRect:(NSRect){
           250,
           250,
           800,
           600
        }];
    });
//
//    [self setContentView:[[SCCapturePanelBackgroundView alloc] initWithFrame:NSZeroRect]];
    
    return self;
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (BOOL)canBecomeKeyWindow
{
    return YES;
}

- (void)keyDown:(NSEvent *)theEvent
{
    switch ([theEvent keyCode])
    {
        case 53: //Esc
        {
            if ([self.delegate windowShouldClose:self]) {
                [self orderOut:self];     
            }
            break;
        }
        default:
        {
            [super keyDown:theEvent];
            break;
        }
    }
}

- (void)setCropRect:(NSRect)cropRect
{
    _cropRect = NSIntegralRect(cropRect);
    self.bgView.cropRect = _cropRect;
}
//
//- (SCCapturePanelBackgroundView*)bgView
//{
//    return (SCCapturePanelBackgroundView*)self.contentView;
//}

@end
