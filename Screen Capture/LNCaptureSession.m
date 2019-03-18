//
//  LNCaptureSession.m
//  Screen Capture
//
//  Created by Levi Nunnink on 2/26/19.
//  Copyright © 2019 Levi Nunnink. All rights reserved.
//

#import "LNCaptureSession.h"
#import <AVFoundation/AVFoundation.h>

@interface LNCaptureSession () <AVCaptureFileOutputRecordingDelegate>

@property (nonatomic, strong) AVCaptureSession *mSession;
@property (nonatomic, strong) AVCaptureMovieFileOutput *mMovieFileOutput;
@property (nonatomic, copy) void (^complete)(NSError *error, NSURL *fileURL);

@end

@implementation LNCaptureSession

- (void)beginRecordingWithOptions:(LNCaptureSessionOptions *)options
{
    // Create a capture session
    self.mSession = [[AVCaptureSession alloc] init];
    
    // Set the session preset as you wish
    self.mSession.sessionPreset = AVCaptureSessionPresetHigh;
    
    CGDirectDisplayID displayId = kCGDirectMainDisplay;
    if ([[[NSScreen mainScreen] deviceDescription] valueForKey:@"NSScreenNumber"]){
        displayId = (CGDirectDisplayID)[[[[NSScreen mainScreen] deviceDescription] valueForKey:@"NSScreenNumber"] pointerValue];
    }
    CGRect captureRect = options.captureRect;
    AVCaptureScreenInput *input = [[AVCaptureScreenInput alloc] initWithDisplayID:displayId];
    input.cropRect = captureRect;
    input.capturesMouseClicks = options.showMouseClicks;
    
    if ([self.mSession canAddInput:input])
        [self.mSession addInput:input];
    
    // Create a MovieFileOutput and add it to the session
    self.mMovieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    if ([self.mSession canAddOutput:self.mMovieFileOutput])
        [self.mSession addOutput:self.mMovieFileOutput];
    
    if(options.mic && !options.disableAudioRecording) {
        AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:options.mic error:nil];
        if([self.mSession canAddInput:audioInput]) [self.mSession addInput:audioInput];
    }
    
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
    // Start recording to the destination movie file
    // The destination path is assumed to end with ".mov", for example, @"/users/master/desktop/capture.mov"
    // Set the recording delegate to self
    NSURL *fileURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:[self captureTemporaryFilePath]];
    NSLog(@"Recording to: %@",fileURL.absoluteString);
    [self.mMovieFileOutput startRecordingToOutputFileURL:fileURL recordingDelegate:self];

}

- (void)endRecordingComplete:(void (^ _Nullable)(NSError *, NSURL *))complete
{
    self.complete = complete;
    [self.mMovieFileOutput stopRecording];
}

#pragma mark AVCapDelegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    DLOG(@"Did finish recording to %@ due to error %@", [outputFileURL description], [error description]);
    [self.mSession stopRunning];
    if(self.complete) self.complete(error, outputFileURL);
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
