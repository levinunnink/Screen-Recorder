//
//  SCAppDelegate.m
//  Screen Capture
//
//  Created by Levi Nunnink on 3/6/14.
//  Copyright (c) 2014 Levi Nunnink. All rights reserved.
//

#import "LNCaptureAppDelegate.h"
#import "LNCaptureWindowController.h"
#import "LNGIFConverter.h"
#import <AVFoundation/AVFoundation.h>

@interface LNCaptureAppDelegate () <SCCaptureDelegate,AVCaptureFileOutputRecordingDelegate>

@property (nonatomic, strong) LNCaptureWindowController *captureWindow;
@property (nonatomic, strong) AVCaptureSession *mSession;
@property (nonatomic, strong) AVCaptureMovieFileOutput *mMovieFileOutput;

@end

@implementation LNCaptureAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [LNCaptureWindowController instance].captureDelegate = self;
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    NSLog(@"Capturing screen");
    if (![LNCaptureWindowController instance].recording) {
        [[LNCaptureWindowController instance] beginScreenCaptureForScreen:[NSScreen mainScreen]];
    }
}

- (void)applicationDidResignActive:(NSNotification *)notification
{
    if (![LNCaptureWindowController instance].recording) {
        [[LNCaptureWindowController instance] endScreenCapture];
    }
}

#pragma mark SCCaptureDelegate

- (void)beginCaptureForScreen:(NSScreen*)screen inRect:(NSRect)rect
{
    // Create a capture session
    self.mSession = [[AVCaptureSession alloc] init];
    
    // Set the session preset as you wish
    self.mSession.sessionPreset = AVCaptureSessionPresetHigh;
    
    // If you're on a multi-display system and you want to capture a secondary display,
    // you can call CGGetActiveDisplayList() to get the list of all active displays.
    // For this example, we just specify the main display.
    CGDirectDisplayID displayId = kCGDirectMainDisplay;
    
    // Create a ScreenInput with the display and add it to the session
    AVCaptureScreenInput *input = [[AVCaptureScreenInput alloc] initWithDisplayID:displayId];
    input.cropRect = rect;
    input.capturesMouseClicks = YES;
    
    if ([self.mSession canAddInput:input])
        [self.mSession addInput:input];
    
    // Create a MovieFileOutput and add it to the session
    self.mMovieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    if ([self.mSession canAddOutput:self.mMovieFileOutput])
        [self.mSession addOutput:self.mMovieFileOutput];
    
    // Start running the session
    [self.mSession startRunning];
    
    // Delete any existing movie file first
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self captureTemporaryFilePath]])
    {
        NSError *err;
        if (![[NSFileManager defaultManager] removeItemAtPath:[self captureTemporaryFilePath] error:&err])
        {
            NSLog(@"Error deleting existing movie %@",[err localizedDescription]);
        }
    }
    NSLog(@"Recording to: %@",[self captureTemporaryFilePath]);
    // Start recording to the destination movie file
    // The destination path is assumed to end with ".mov", for example, @"/users/master/desktop/capture.mov"
    // Set the recording delegate to self
    NSURL *fileURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:[self captureTemporaryFilePath]];
    [self.mMovieFileOutput startRecordingToOutputFileURL:fileURL recordingDelegate:self];

}

- (void)endScreenCapture
{
    [self.mMovieFileOutput stopRecording];
    NSURL *fileURL = self.mMovieFileOutput.outputFileURL;
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[fileURL]];
//    double delayInSeconds = 2.0;
//    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
//    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//        [[SCGIFConverter instance] convertFileAtPath:fileURL];
//    });

}

#pragma mark AVCapDelegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    NSLog(@"Did finish recording to %@ due to error %@", [outputFileURL description], [error description]);
    
    // Stop running the session
    [self.mSession stopRunning];

}

#pragma mark Private helpers

- (NSString*)captureTemporaryFilePath
{
    static NSDateFormatter* dateFormatter = nil;
    static NSDateFormatter* timeFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    }
    if (timeFormatter == nil) {
        timeFormatter = [[NSDateFormatter alloc] init];
        [timeFormatter setDateFormat:@"HH-mm-ss"];
    }
    
    NSDate* now = [NSDate date];
    NSString* date = [dateFormatter stringFromDate:now];
    NSString* time = [timeFormatter stringFromDate:now];
    
    NSString *fileName = [NSString stringWithFormat:@"%@ on %@ at %@.%@", @"Screen Capture", date, time, @"mov"];
    
    return fileName;
}

@end
