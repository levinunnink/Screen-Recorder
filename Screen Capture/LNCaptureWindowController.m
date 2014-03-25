//
//  SCCaptureWindowController.m
//  Screen Capture
//
//  Created by Levi Nunnink on 3/6/14.
//  Copyright (c) 2014 Levi Nunnink. All rights reserved.
//

#import "LNCaptureWindowController.h"
#import "LNCapturePanel.h"
#import "LNOverlayView.h"
#import "LNCaptureButtonCell.h"

#define kMinCropSize (NSSize){ 60 , 60 }

@interface LNCaptureWindowController () <NSWindowDelegate>

@property (nonatomic, assign) NSPoint startPoint;
@property (nonatomic, readonly) LNCapturePanel *capturePanel;
@property (nonatomic, strong) NSButton *confirmationButton;
@property (nonatomic, strong) NSButton *stopRecordingButton;
@property (nonatomic, strong) LNOverlayView *overlay;

@end

@implementation LNCaptureWindowController

+ (LNCaptureWindowController*)instance
{
    
    static LNCaptureWindowController* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        LNCapturePanel* panel = [[LNCapturePanel alloc]
                                        initWithContentRect:NSZeroRect styleMask: NSNonactivatingPanelMask
                                        backing:NSBackingStoreBuffered defer:NO];
        instance = [[LNCaptureWindowController alloc] initWithWindow:panel];
        panel.delegate = instance;
        
        NSButton *confirm = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 160, 25)];
        [confirm setCell:[[LNCaptureButtonCell alloc] init]];
        [confirm setTitle: @"Start Recording"];
        [confirm setButtonType:NSMomentaryLightButton]; //Set what type button You want
        [confirm setBezelStyle:NSRoundedBezelStyle]; //Set what style You want
        confirm.target = instance;
        confirm.action = @selector(startRecording:);
        instance.confirmationButton = confirm;
        
        NSButton *stop = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 160, 25)];
        //[stop setCell:[[LNCaptureButtonCell alloc] init]];
        [stop setTitle: @"Stop Recording"];
        [stop setKeyEquivalent:@"\E"];
        [stop setButtonType:NSMomentaryLightButton]; //Set what type button You want
        [stop setBezelStyle:NSRoundedBezelStyle]; //Set what style You want
        stop.target = instance;
        stop.action = @selector(stopRecording:);
        instance.stopRecordingButton = stop;
    });
    
    return instance;
}

-(BOOL)acceptsFirstResponder
{
    return YES;
}

#pragma mark Actions

- (void)startRecording:(id)sender
{
    self.recording = YES;
    [self.confirmationButton setHidden:YES];
    [self showStopRecordingButton];
    [self.captureDelegate beginCaptureForScreen:self.capturePanel.screen inRect:self.capturePanel.cropRect];
}

- (void)stopRecording:(id)sender
{
    [self endScreenCapture];
    [self.captureDelegate endScreenCapture];
}

#pragma mark NSWindowDelegate

- (BOOL)windowShouldClose:(id)sender
{
    DMARK;
    //if (self.recording) {
        [self stopRecording:nil];
    //}
    return YES;
}

- (void)windowWillClose:(NSNotification *)notification
{
    DMARK;
}

#pragma mark -

- (void)beginScreenCaptureForScreen:(NSScreen *)screen
{
    [[NSCursor crosshairCursor] push];
    
    self.recording = NO;
    [self.confirmationButton setHidden:YES];
    [self.stopRecordingButton setHidden:YES];
    self.capturePanel.cropRect = NSZeroRect;
    [self.window setFrame:screen.frame display:YES];
    if (!self.overlay.isHidden)
        [self hideOverlay];
    [self showOverlay];
    [self showWindow:self];
    [self.capturePanel becomeKeyWindow];
}

- (void)endScreenCapture
{
    self.recording = NO;
    [self.window orderOut:self];
}

#pragma mark NSRsponder

- (void)mouseDown:(NSEvent *)theEvent
{
    if (!self.overlay.isHidden)
        [self hideOverlay];
    
    [self.confirmationButton setHidden:YES];
    self.startPoint = [theEvent locationInWindow];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    if (!self.overlay.isHidden)
        [self hideOverlay];
    
    NSPoint curPoint = [theEvent locationInWindow];
    CGRect cropRect = (CGRect){
                          MIN(_startPoint.x, curPoint.x),
                          MIN(_startPoint.y, curPoint.y),
                          fabs(_startPoint.x - curPoint.x),
                          fabs(_startPoint.y - curPoint.y)
                        };
    
    self.capturePanel.cropRect = cropRect;
}

- (void)mouseUp:(NSEvent *)theEvent
{
    NSPoint curPoint = [theEvent locationInWindow];
    if (self.capturePanel.cropRect.size.width < kMinCropSize.width   ||
        self.capturePanel.cropRect.size.height < kMinCropSize.height ||
        !NSPointInRect(curPoint, self.capturePanel.cropRect)
        ) {
        if (_recording) {
            [self stopRecording:nil];
        } else {
            [self endScreenCapture];
        }
        return;
    }
    
    if (!_recording)
        [self showConfirmationButton];
}

- (void)keyDown:(NSEvent *)theEvent
{
    switch ([theEvent keyCode])
    {
        case 53: //Esc
        {
            [self.window orderOut:self];
            break;
        }
        default:
        {
            [super keyDown:theEvent];
            break;
        }
    }
}

#pragma mark Private Helpers

- (void)showConfirmationButton
{
    [self.capturePanel.contentView addSubview:self.confirmationButton];
    [self.confirmationButton setFrame:(NSRect){
        self.capturePanel.cropRect.origin.x + (self.capturePanel.cropRect.size.width / 2) - (self.confirmationButton.frame.size.width / 2),
        self.capturePanel.cropRect.origin.y + (self.capturePanel.cropRect.size.height / 2) - (self.confirmationButton.frame.size.height / 2),
        self.confirmationButton.frame.size.width,
        self.confirmationButton.frame.size.height
    }];
    [self.confirmationButton setHidden:NO];
}

- (void)showStopRecordingButton
{
    if (!_hideStopButton) {
        [self.capturePanel.contentView addSubview:self.stopRecordingButton];
        
        NSRect overlayFrame = self.capturePanel.cropRect;

        [self.stopRecordingButton setFrame:(NSRect){
            overlayFrame.origin.x,
            overlayFrame.origin.y,
            self.stopRecordingButton.frame.size.width,
            self.stopRecordingButton.frame.size.height
        }];
        [self.stopRecordingButton setHidden:NO];
    }
}

- (LNCapturePanel*)capturePanel
{
    return (LNCapturePanel*)self.window;
}

- (void)showOverlay
{
    if (!self.overlay) {
        self.overlay = [[LNOverlayView alloc] initWithFrame:NSMakeRect(0, 0, 600, 200)];
        self.overlay.label = self.overlayMessage ? self.overlayMessage : @"Drag on screen to record video.";
        [self.window.contentView addSubview:self.overlay];
    }
    [self.overlay centerInSuperview];
    [self.overlay setHidden:NO];
    [self.overlay setNeedsDisplay:YES];
}

- (void)hideOverlay
{
    [self.overlay setHidden:YES];
}

@end
