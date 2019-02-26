//
//  SCCaptureWindowController.h
//  Screen Capture
//
//  Created by Levi Nunnink on 3/6/14.
//  Copyright (c) 2014 Levi Nunnink. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LNCapturePanel.h"

@protocol SCCaptureDelegate <NSObject>

- (void)beginCaptureForScreen:(NSScreen*)screen;
- (void)endScreenCapture;
- (void)cancelScreenCapture;

@end

@interface LNCaptureWindowController : NSWindowController

@property (nonatomic, assign) id<SCCaptureDelegate>captureDelegate;

@property (nonatomic, readonly) LNCapturePanel *capturePanel;

//+ (LNCaptureWindowController*)instance;

- (void)beginScreenCaptureForScreen:(NSScreen*)screen;
- (void)endScreenCapture;
- (void)cancelRecording:(id)sender;
- (void)stopRecording:(id)sender;

- (IBAction)setPreset:(id)sender;

@end
