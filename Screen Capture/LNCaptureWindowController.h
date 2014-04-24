//
//  SCCaptureWindowController.h
//  Screen Capture
//
//  Created by Levi Nunnink on 3/6/14.
//  Copyright (c) 2014 Levi Nunnink. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol SCCaptureDelegate <NSObject>

- (void)beginCaptureForScreen:(NSScreen*)screen inRect:(NSRect)rect;
- (void)endScreenCapture;
- (void)captureRectTooSmall;

@end

@interface LNCaptureWindowController : NSWindowController

@property (nonatomic, assign) id<SCCaptureDelegate>captureDelegate;

@property (nonatomic, assign) BOOL recording;
@property (nonatomic, assign) BOOL hideStopButton;
@property (nonatomic, strong) NSString* overlayMessage;

+ (LNCaptureWindowController*)instance;

- (void)beginScreenCaptureForScreen:(NSScreen*)screen;
- (void)endScreenCapture;
- (void)stopRecording:(id)sender;

@end
