//
//  SCCapturePanel.m
//  Screen Capture
//
//  Created by Levi Nunnink on 3/6/14.
//  Copyright (c) 2014 Levi Nunnink. All rights reserved.
//

#import "LNCapturePanel.h"
#import "DMBackgroundColorView.h"

#import <QuartzCore/QuartzCore.h>

@interface SCCapturePanelBackgroundView : NSView

@property (nonatomic, assign) NSRect cropRect;
@property (nonatomic, weak) DMBackgroundColorView *cropScreen;

@end

@interface LNCapturePanel ()

- (SCCapturePanelBackgroundView*)bgView;

@end

@implementation SCCapturePanelBackgroundView

- (id) initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];

    if (self) {
        [self setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
        [self setAutoresizesSubviews:YES];
        DMBackgroundColorView *crop = [[DMBackgroundColorView alloc] initWithFrame:CGRectZero];
        crop.backgroundColor = [NSColor clearColor];
        [self addSubview:crop];
        self.cropScreen = crop;
    }
    
    return self;
}

- (void)setCropRect:(NSRect)cropRect
{
    DMARK;
    _cropRect = cropRect;
    self.cropScreen.frame = cropRect;
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

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle
                  backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    self = [super initWithContentRect:NSZeroRect styleMask:aStyle
                              backing:NSBackingStoreBuffered defer:NO];
    [self setFloatingPanel:YES];
    [self setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary];
    [self setBackgroundColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.5]];
    [self setMovableByWindowBackground:NO];
    [self setExcludedFromWindowsMenu:YES];
    [self setAlphaValue:1.0];
    [self setOpaque:NO];
    [self setHasShadow:NO];
    [self setHidesOnDeactivate:NO];
    [self setLevel:kCGMaximumWindowLevel];
    [self setRestorable:NO];
    [self disableSnapshotRestoration];
    
    [self setContentView:[[SCCapturePanelBackgroundView alloc] initWithFrame:NSZeroRect]];
    
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

- (SCCapturePanelBackgroundView*)bgView
{
    return (SCCapturePanelBackgroundView*)self.contentView;
}

@end
