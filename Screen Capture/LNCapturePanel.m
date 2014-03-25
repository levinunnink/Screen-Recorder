//
//  SCCapturePanel.m
//  Screen Capture
//
//  Created by Levi Nunnink on 3/6/14.
//  Copyright (c) 2014 Levi Nunnink. All rights reserved.
//

#import "LNCapturePanel.h"

@interface SCCapturePanelBackgroundView : NSView

@property (nonatomic, assign) NSRect cropRect;

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
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.5] setFill];
    NSRectFill(dirtyRect);
    
    [[NSColor clearColor] setFill];
    NSRectFill(_cropRect);
    
    [[NSGraphicsContext currentContext] setShouldAntialias: NO];
    
    [[NSColor blackColor] setStroke];
    NSBezierPath *line = [NSBezierPath bezierPathWithRect:NSIntegralRect(_cropRect)];
    line.lineWidth = 1.0;
    [line stroke];
    
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
    [self useOptimizedDrawing:YES];
    [self setHidesOnDeactivate:NO];
    [self setLevel:kCGMaximumWindowLevel];
    [self setRestorable:NO];
    [self disableSnapshotRestoration];
    [self setAutorecalculatesKeyViewLoop:YES];
    
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
    [self.bgView setNeedsDisplay:YES];
}

- (SCCapturePanelBackgroundView*)bgView
{
    return (SCCapturePanelBackgroundView*)self.contentView;
}

@end
