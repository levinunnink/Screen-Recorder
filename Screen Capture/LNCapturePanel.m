//
//  SCCapturePanel.m
//  Screen Capture
//
//  Created by Levi Nunnink on 3/6/14.
//  Copyright (c) 2014 Levi Nunnink. All rights reserved.
//

#import "LNCapturePanel.h"

#import <QuartzCore/QuartzCore.h>

@interface SCCapturePanelBackgroundView : NSView

@property (nonatomic, assign) NSRect cropRect;
@property (nonatomic, strong) CAShapeLayer *cropLine;
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
        self.layer.backgroundColor = [NSColor colorWithWhite:0.0 alpha:0.5].CGColor;
        [self setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
        [self setAutoresizesSubviews:YES];
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
    
    CAShapeLayer *maskLayer;
    if(self.layer.mask) {
        maskLayer = self.layer.mask;
    } else {
        maskLayer = [CAShapeLayer layer];
    }
    CGMutablePathRef maskPath = CGPathCreateMutable();
    CGPathAddRect(maskPath, NULL, self.bounds); // this line is new
    CGPathAddPath(maskPath, nil, CGPathCreateWithRect(cropRect, nil) );
    [maskLayer setPath:maskPath];
    maskLayer.fillRule = kCAFillRuleEvenOdd;         // this line is new
    CGPathRelease(maskPath);
    self.layer.mask = maskLayer;
    
    if(!self.cropLine) {
        self.cropLine = [CAShapeLayer layer];
        self.cropLine.fillColor = [NSColor whiteColor].CGColor;
        [self.layer addSublayer:self.cropLine];
    }

    self.cropLine.path = CGPathCreateWithRect((CGRect){
        cropRect.origin.x - 1,
        cropRect.origin.y - 1,
        cropRect.size.width + 2,
        cropRect.size.height + 2,
    }, nil);
    
    [CATransaction commit];

}

- (void)mouseEntered:(NSEvent *)theEvent
{
    [[NSCursor crosshairCursor] push];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    [[NSCursor crosshairCursor] pop];
}

- (void)setFrame:(NSRect)frameRect
{
    [super setFrame:frameRect];
    [self updateTrackingAreas];
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
    
    self.bgView = [[SCCapturePanelBackgroundView alloc] initWithFrame:contentRect];
    self.bgView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self.contentView addSubview:self.bgView];
    
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
