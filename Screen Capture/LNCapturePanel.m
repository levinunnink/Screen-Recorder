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
#import "LNVideoControlsViewController.h"
#import "LNWindowInspector.h"

#define kCropRectKey @"LNCropRectKey"

@interface SCCapturePanelBackgroundView : NSView <LNLayerHandleDelegate> {
    BOOL _isRecording;
}
@property (nonatomic, assign) NSRect cropRect;
@property (nonatomic, strong) CAShapeLayer *cropLine;
@property (strong) NSMutableArray<LNResizeHandle*>*resizeHandles;
@property (strong) CALayer *backgroundColorLayer;
@property (assign) CGPoint startPoint;
@property (assign) CGRect startRect;
@property (assign) BOOL liveResize;
@property (assign) LNResizeHandle *activeHandle;
@property (strong) NSArray<NSDictionary*>* windows;
@property (strong) LNWindowInspector *windowInspector;
@property (strong) NSRunningApplication* foremostApplication;
@property (strong) NSDictionary* foremostWindowRect;

@end


@interface LNCapturePanel () {
    BOOL _isRecording;
    CGRect _cropRect;
}

@property (strong) SCCapturePanelBackgroundView* bgView;
@property (strong) LNVideoControlsViewController* controls;

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
        self.resizeHandles = [NSMutableArray arrayWithCapacity:8];
    }
    
    return self;
}

- (BOOL)acceptsFirstMouse
{
    return YES;
}

- (void)setCropRect:(NSRect)cropRect
{
    if(cropRect.size.height == 0 || cropRect.size.width == 0) {
        return;
    }
    _cropRect = cropRect;
    [CATransaction begin];
    [CATransaction setDisableActions: YES];
    
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

    CGPathRef linePath = CGPathCreateWithRect((CGRect){
        cropRect.origin.x - 1,
        cropRect.origin.y - 1,
        cropRect.size.width + 2,
        cropRect.size.height + 2,
    }, nil);
    
    self.cropLine.path = linePath;
    
    CGPathRelease(linePath);
    
    if(self.resizeHandles.count == 0) [self initHandles];
    [self positionHandlesForRect:cropRect];
    
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
    if(_isRecording) {
        return [[NSCursor arrowCursor] set];
    }

    if ([layer isKindOfClass:[LNResizeHandle class]]) {
        [[(LNResizeHandle*)layer cursor] push];
        return;
    } else if (CGRectContainsPoint(self.cropRect, point)) {
        [[NSCursor openHandCursor] push];
        return;
    } else {
        [[NSCursor arrowCursor] set];
    }
}

- (void)mouseDragged:(NSEvent *)event
{
    CGPoint point = [self convertPoint:event.locationInWindow fromView:nil];
    if(self.liveResize) {
        CGRect rect = (CGRect){
            MIN(self.startPoint.x, point.x),
            MIN(self.startPoint.y, point.y),
            fabs(self.startPoint.x - point.x),
            fabs(self.startPoint.y - point.y)
        };
        [self setCropRect:rect];
        return;
    }
    if (self.activeHandle) {
        [self.activeHandle setRepresentedPoint:point];
    } else if (CGRectContainsPoint(self.cropRect, point)) {
        [self moveCropRectFromPoint:self.startPoint ToPoint:point];
    }

}

- (void)mouseDown:(NSEvent *)theEvent
{
    DMARK;
    CGPoint point = [self convertPoint:theEvent.locationInWindow fromView:nil];
    CALayer* layer = [self.layer hitTest:point];
    
    if ([layer isKindOfClass:[LNResizeHandle class]]) {
        self.activeHandle = (LNResizeHandle*)layer;
    } else if(CGRectContainsPoint(self.cropRect, point))  {
        self.startPoint = point;
        self.startRect = self.cropRect;
    } else  {
        self.liveResize = YES;
        self.startPoint = point;
    }
}

- (void)mouseUp:(NSEvent *)event
{
    DMARK;
    self.activeHandle = nil;
    self.liveResize = NO;
}

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    [self addTrackingArea:[[NSTrackingArea alloc] initWithRect:self.frame options:NSTrackingMouseMoved|NSTrackingActiveAlways|NSTrackingMouseEnteredAndExited owner:self userInfo:nil]];
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
    }else{
        bounding.size.width -= CGRectGetMaxX(bounding) - point.x;
    }
    
    if (sender.resizeLocation == LNResizePositionTopLeft || sender.resizeLocation == LNResizePositionTopRight) {
        bounding.size.height = CGRectGetHeight(bounding) - (CGRectGetMaxY(bounding) - point.y);
        bounding.origin.y    = point.y - CGRectGetHeight(bounding);
    }else{
        bounding.size.height = CGRectGetHeight(bounding) + (CGRectGetMinY(bounding) - point.y);
        bounding.origin.y    = point.y;
    }
    
    [self setCropRect:bounding];
}

#pragma mark - Private Helpers

- (void)initHandles
{
    for (int i = 0; i < LNResizePositionCount; ++i) {
        LNResizeHandle *handle = [LNResizeHandle handleWithPosition:(LNResizePosition)i];
        handle.handleDelegate = self;
        [self.layer addSublayer:handle];
        [self.resizeHandles addObject:handle];
    }
}

- (void)positionHandlesForRect:(CGRect)cropRect
{
    for(LNResizeHandle* handle in self.resizeHandles) {
        switch (handle.resizeLocation) {
            case LNResizePositionTopLeft:
                handle.position = CGPointMake(cropRect.origin.x, cropRect.origin.y + cropRect.size.height);
                break;
            case LNResizePositionTopRight:
                handle.position = CGPointMake(cropRect.origin.x + cropRect.size.width, cropRect.origin.y + cropRect.size.height);
                break;
            case LNResizePositionBottomLeft:
                handle.position = CGPointMake(cropRect.origin.x, cropRect.origin.y);
                break;
            case LNResizePositionBottomRight:
                handle.position = CGPointMake(cropRect.origin.x + cropRect.size.width, cropRect.origin.y);
                break;
            case LNResizePositionTop:
                handle.position = CGPointMake(cropRect.origin.x + (cropRect.size.width / 2), cropRect.origin.y + cropRect.size.height);
                break;
            case LNResizePositionRight:
                handle.position = CGPointMake(cropRect.origin.x + cropRect.size.width, cropRect.origin.y + (cropRect.size.height / 2));
                break;
            case LNResizePositionBottom:
                handle.position = CGPointMake(cropRect.origin.x + (cropRect.size.width / 2), cropRect.origin.y);
                break;
            case LNResizePositionLeft:
                handle.position = CGPointMake(cropRect.origin.x, cropRect.origin.y + (cropRect.size.height / 2));
                break;
            default:
                break;
        }
    }
}

- (void)setIsRecording:(BOOL)isRecording
{
    _isRecording = isRecording;
    for(LNResizeHandle *handle in self.resizeHandles) {
        handle.hidden = isRecording;
    }
    self.cropLine.hidden = isRecording;
    self.backgroundColorLayer.backgroundColor = isRecording ? [NSColor colorWithWhite:0.0 alpha:0.7].CGColor : [NSColor colorWithWhite:0.0 alpha:0.5].CGColor;
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
        if(rectString) [self setCropRect:NSRectFromString(rectString)];
        if(!rectString || NSRectFromString(rectString).size.width == 0 || NSRectFromString(rectString).size.height == 0) {
            // Default rect
            [self setCropRect:(NSRect) {
                self.screen.frame.size.width / 2 - 300,
                self.screen.frame.size.height / 2 - 300,
                600,
                600
            }];
        }
    });
    
    self.controls = [[LNVideoControlsViewController alloc] initWithNibName:@"LNVideoControlsViewController" bundle:nil];
    self.controls.view.wantsLayer = YES; // Otherwise this will be placed below the crop layer on older macOS Versions
    [self.contentView addSubview:self.controls.view];
    [self positionControls];
    return self;
}

- (void)setIsRecording:(BOOL)isRecording
{
    _isRecording = isRecording;
    self.controls.view.hidden = isRecording;
    [self.bgView setIsRecording:isRecording];
    [self setIgnoresMouseEvents:!isRecording];
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
                [[NSNotificationCenter defaultCenter] postNotificationName:kLNVideoControllerEndCaptureNotification object:nil];
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

- (void)setFrame:(NSRect)frameRect display:(BOOL)flag
{
    [super setFrame:frameRect display:flag];
    [self positionControls];
}

- (void)setCropRect:(NSRect)cropRect
{
    _cropRect = NSIntegralRect(cropRect);
    self.bgView.cropRect = _cropRect;
}

- (CGRect)cropRect
{
    return self.bgView.cropRect;
}

- (void)performClose:(id)sender
{
    DMARK;
    [self orderOut:sender];
}

- (void)positionControls
{
    self.controls.view.frame = (NSRect){
        (self.frame.size.width / 2) - self.controls.view.frame.size.width / 2, 15, self.controls.view.frame.size.width, self.controls.view.frame.size.height
    };
}

@end
