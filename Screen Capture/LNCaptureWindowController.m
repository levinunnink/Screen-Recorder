//
//  SCCaptureWindowController.m
//  Screen Capture
//
//  Created by Levi Nunnink on 3/6/14.
//  Copyright (c) 2014 Levi Nunnink. All rights reserved.
//

#import "LNCaptureWindowController.h"
#import "LNVideoControlsViewController.h"
#import "LNCapturePanel.h"
#import "LNOverlayView.h"
#import "LNCaptureButtonCell.h"
#import "LNCaptureSessionOptions.h"
#import "LNCaptureSession.h"
#import "LNWindowInspector.h"

@interface LNCaptureWindowController () <NSWindowDelegate>

@property (strong) LNCaptureSession *captureSession;

@end

@implementation LNCaptureWindowController

- (id)init
{
    LNCapturePanel* panel = [[LNCapturePanel alloc]
                             initWithContentRect:NSZeroRect styleMask: NSWindowStyleMaskNonactivatingPanel|NSWindowStyleMaskBorderless
                             backing:NSBackingStoreBuffered defer:NO];
    self = [super initWithWindow:panel];
    panel.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startRecording:) name:kLNVideoControllerBeginRecordingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleControllerEndCaptureNotification:) name:kLNVideoControllerEndCaptureNotification object:nil];

    return self;
}

-(BOOL)acceptsFirstResponder
{
    return YES;
}

#pragma mark Actions

- (IBAction)startRecording:(id)sender
{
    [self.capturePanel setIsRecording:YES];
    self.window.ignoresMouseEvents = YES;
    [LNCaptureSessionOptions currentOptions].captureRect = self.capturePanel.cropRect;
    if(self.captureDelegate) [self.captureDelegate recordingStarted];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.02 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.captureSession = [LNCaptureSession new];
        [self.captureSession beginRecordingWithOptions:[LNCaptureSessionOptions currentOptions]];
    });
}

- (IBAction)stopRecording:(id)sender
{
    self.window.ignoresMouseEvents = NO;
    [self.captureSession endRecordingComplete:^(NSError *error, NSURL *recordingURL) {
        if(error) return DLOG(@"Got error while recording %@", error);
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[recordingURL]];
    }];
}

- (void)cancelRecording:(id)sender
{
    DMARK;
    self.window.ignoresMouseEvents = NO;
    [self endScreenCapture];
    [self.captureSession endRecordingComplete:^(NSError *error, NSURL *recordingURL) {
        if(error) return DLOG(@"Got error while recording %@", error);
        if ([[NSFileManager defaultManager] fileExistsAtPath:[recordingURL path]])
        {
            [[NSFileManager defaultManager] removeItemAtPath:[recordingURL path] error:nil];
        }
    }];
}

#pragma mark NSWindowDelegate

- (BOOL)windowShouldClose:(id)sender
{
    DMARK;
    [self stopRecording:nil];
    return YES;
}

#pragma mark -

- (void)beginScreenCaptureForScreen:(NSScreen *)screen
{
    [LNCaptureSessionOptions currentOptions].disableAudioRecording = self.disableAudioRecording;
    self.capturePanel.cropRect = NSZeroRect;
    [self.window setFrame:screen.frame display:YES];
    [self showWindow:self];
    [self.capturePanel becomeKeyWindow];
}

- (void)endRecordingComplete:(void (^ _Nullable)(NSError *error, NSURL *fileURL))complete;
{
    self.window.ignoresMouseEvents = NO;
    [self.captureSession endRecordingComplete:^(NSError *err, NSURL *fileURL) {
        complete(err, fileURL);
        [self.window orderOut:nil];
        [self.capturePanel setIsRecording:NO];
    }];
}

- (void)endScreenCapture
{
    [self.capturePanel setIsRecording:NO];
    [self.window orderOut:self];
}

#pragma mark - Actions

- (IBAction)setPreset:(id)sender
{
    NSString *selectedPreset = [sender titleOfSelectedItem];
    NSRect currentScreenFrame = [NSScreen mainScreen].frame;
    if([selectedPreset isEqualToString:@"Fullscreen"]) {
        DLOG(@"Setting fullscreen %@", NSStringFromRect(currentScreenFrame));
        self.capturePanel.cropRect = (CGRect){
            0, 0, currentScreenFrame.size.width, currentScreenFrame.size.height,
        };
        return;
    }
    if([selectedPreset isEqualToString:@"Snap to window"]) {
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            LNWindowInspector *windowInspector = [LNWindowInspector new];
            NSDictionary* frontWindow = [windowInspector getFrontWindow];
            dispatch_async(dispatch_get_main_queue(), ^{
                CGRect windowRect = [self windowToRect: frontWindow];
                self.capturePanel.cropRect = windowRect;
            });
        });
        return;
    }
    NSArray* components;
    if(![selectedPreset containsString:@" "]) {
        components = @[selectedPreset];
    } else {
        components = [selectedPreset componentsSeparatedByString:@" "];
    }
    NSArray* sizeComponents = [components.lastObject componentsSeparatedByString:@"×"];
    CGFloat width = [[sizeComponents objectAtIndex:0] floatValue];
    CGFloat height = [[sizeComponents objectAtIndex:1] floatValue];
    
    CGRect newRect = (CGRect){
        currentScreenFrame.size.width / 2 - (width/2),
        currentScreenFrame.size.height / 2 - (height / 2),
        width,
        height
    };
    self.capturePanel.cropRect = newRect;
}

#pragma mark - Notifications

- (void)handleControllerEndCaptureNotification:(NSNotification*)sender
{
    [self close];
    [self.captureDelegate recordingCancelled];
}

#pragma mark NSRsponder

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

- (CGRect)windowToRect:(NSDictionary*)window
{
    CGPoint windowOrigin = (CGPoint){
        [[[window[@"windowOrigin"] componentsSeparatedByString:@"/"] firstObject] floatValue],
        [[[window[@"windowOrigin"] componentsSeparatedByString:@"/"] lastObject] floatValue]
    };
    CGSize windowSize = (CGSize){
        [[[window[@"windowSize"] componentsSeparatedByString:@"*"] firstObject] floatValue],
        [[[window[@"windowSize"] componentsSeparatedByString:@"*"] lastObject] floatValue]
    };
    CGRect windowRect = (CGRect){
        windowOrigin.x,
        (self.window.frame.size.height-(windowSize.height+windowOrigin.y)),
        windowSize.width,
        windowSize.height
    };
    return windowRect;
}

- (LNCapturePanel*)capturePanel
{
    return (LNCapturePanel*)self.window;
}

@end
