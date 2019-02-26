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
@property (nonatomic, strong) NSButton *confirmationButton;
@property (nonatomic, strong) NSButton *stopRecordingButton;
@property (nonatomic, assign) BOOL mouseDidDrag;

@end

@implementation LNCaptureWindowController

//+ (LNCaptureWindowController*)instance
//{
//
//    static LNCaptureWindowController* instance = nil;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        LNCapturePanel* panel = [[LNCapturePanel alloc]
//                                        initWithContentRect:NSZeroRect styleMask: NSWindowStyleMaskNonactivatingPanel|NSWindowStyleMaskBorderless
//                                        backing:NSBackingStoreBuffered defer:NO];
//        instance = [[LNCaptureWindowController alloc] initWithWindow:panel];
//        panel.delegate = instance;
//
//        NSButton *confirm = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 160, 25)];
//        [confirm setCell:[[LNCaptureButtonCell alloc] init]];
//        [confirm setTitle: @"Start Recording"];
//        [confirm setButtonType:NSMomentaryLightButton]; //Set what type button You want
//        [confirm setBezelStyle:NSRoundedBezelStyle]; //Set what style You want
//        confirm.target = instance;
//        confirm.action = @selector(startRecording:);
//        instance.confirmationButton = confirm;
//
//        NSButton *stop = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 160, 25)];
//        //[stop setCell:[[LNCaptureButtonCell alloc] init]];
//        [stop setTitle: @"Stop Recording"];
//        [stop setKeyEquivalent:@"\E"];
//        [stop setButtonType:NSMomentaryLightButton]; //Set what type button You want
//        [stop setBezelStyle:NSRoundedBezelStyle]; //Set what style You want
//        stop.target = instance;
//        stop.action = @selector(stopRecording:);
//        instance.stopRecordingButton = stop;
//    });
//
//    return instance;
//}

- (id)init
{
    LNCapturePanel* panel = [[LNCapturePanel alloc]
                             initWithContentRect:NSZeroRect styleMask: NSWindowStyleMaskNonactivatingPanel|NSWindowStyleMaskBorderless
                             backing:NSBackingStoreBuffered defer:NO];
    self = [super initWithWindow:panel];
    panel.delegate = self;
    
    NSButton *confirm = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 160, 25)];
    [confirm setCell:[[LNCaptureButtonCell alloc] init]];
    [confirm setTitle: @"Start Recording"];
    [confirm setButtonType:NSMomentaryLightButton]; //Set what type button You want
    [confirm setBezelStyle:NSRoundedBezelStyle]; //Set what style You want
    confirm.target = self;
    confirm.action = @selector(startRecording:);
    self.confirmationButton = confirm;
    
    NSButton *stop = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 160, 25)];
    //[stop setCell:[[LNCaptureButtonCell alloc] init]];
    [stop setTitle: @"Stop Recording"];
    [stop setKeyEquivalent:@"\E"];
    [stop setButtonType:NSMomentaryLightButton]; //Set what type button You want
    [stop setBezelStyle:NSRoundedBezelStyle]; //Set what style You want
    stop.target = self;
    stop.action = @selector(stopRecording:);
    self.stopRecordingButton = stop;
    
    return self;
}

-(BOOL)acceptsFirstResponder
{
    return YES;
}

#pragma mark Actions

- (void)startRecording:(id)sender
{
    self.recording = YES;
    self.window.ignoresMouseEvents = YES;
    [self.confirmationButton setHidden:YES];
    // We do this to prevent the button showing
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.02 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self showStopRecordingButton];
        [self.captureDelegate beginCaptureForScreen:self.capturePanel.screen inRect:self.capturePanel.cropRect];
    });
}

- (void)stopRecording:(id)sender
{
    self.window.ignoresMouseEvents = NO;
    [self endScreenCapture];
    [self.captureDelegate endScreenCapture];
}

- (void)cancelRecording:(id)sender
{
    DMARK;
    self.window.ignoresMouseEvents = NO;
    [self endScreenCapture];
    [self.captureDelegate cancelScreenCapture];
}

#pragma mark NSWindowDelegate

- (BOOL)windowShouldClose:(id)sender
{
    if (!_recording) [self.captureDelegate captureRectClickOutside];
    //if (self.recording) {
        [self stopRecording:nil];
    //}
    return YES;
}

- (void)windowWillClose:(NSNotification *)notification
{
    
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
    [self showWindow:self];
    [self.capturePanel becomeKeyWindow];
}

- (void)endScreenCapture
{
    
    self.recording = NO;
    [self.window orderOut:self];
}

#pragma mark - Actions

- (IBAction)setPreset:(id)sender
{
    NSString *selectedPreset = [sender titleOfSelectedItem];
    NSRect currentScreenFrame = [NSScreen mainScreen].frame;
    if([selectedPreset isEqualToString:@"Fullscreen"]) {
        self.capturePanel.cropRect = currentScreenFrame;
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

#pragma mark NSRsponder

- (void)mouseDown:(NSEvent *)theEvent
{
    
    if (_recording) return;
    
    self.mouseDidDrag = NO;
    
    [self.confirmationButton setHidden:YES];
    self.startPoint = [theEvent locationInWindow];
    self.capturePanel.cropRect = CGRectMake(self.startPoint.x, self.startPoint.y, 0, 0);
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    
    if (_recording) return;
    
    self.mouseDidDrag = YES;
    
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
    DMARK;
    if (_recording) return;
    
    NSPoint curPoint = [theEvent locationInWindow];
    
    if (self.capturePanel.cropRect.size.width < kMinCropSize.width   ||
        self.capturePanel.cropRect.size.height < kMinCropSize.height ||
        (!NSPointInRect(curPoint, self.capturePanel.cropRect) && !_mouseDidDrag)
        ) {

        [self.captureDelegate captureRectClickOutside];
        
        if (_recording) {
            [self stopRecording:nil];
        } else {
            [self endScreenCapture];
        }
        return;
    }
    
    if (!_recording) [self showConfirmationButton];
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
    DMARK;
    DLOG(@"self.confirmationButton %@", self.confirmationButton);
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

@end
