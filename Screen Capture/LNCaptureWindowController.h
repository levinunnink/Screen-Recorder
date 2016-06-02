//
//  SCCaptureWindowController.h
//  Screen Capture
//
//  Created by Levi Nunnink on 3/6/14.
//  Copyright (c) 2014 Levi Nunnink. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <LNCapturePanel.h>

@protocol SCCaptureDelegate <NSObject>

- (void)beginCaptureForScreen:(NSScreen*)screen inRect:(NSRect)rect;
- (void)endScreenCapture;
- (void)cancelScreenCapture;
- (void)captureRectTooSmall;
- (void)captureRectClickOutside;

@end

@interface LNCaptureWindowController : NSWindowController

@property (nonatomic, assign) id<SCCaptureDelegate>captureDelegate;

@property (nonatomic, assign) BOOL recording;
@property (nonatomic, assign) BOOL hideStopButton;
@property (nonatomic, strong) NSString* overlayMessage;
@property (nonatomic, readonly) LNCapturePanel *capturePanel;

+ (LNCaptureWindowController*)instance;

- (void)beginScreenCaptureForScreen:(NSScreen*)screen;
- (void)endScreenCapture;
- (void)cancelRecording:(id)sender;
- (void)stopRecording:(id)sender;

@end
