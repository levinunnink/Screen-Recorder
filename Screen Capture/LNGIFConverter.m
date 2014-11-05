//
//  SCGIFConverter.m
//  Screen Capture
//
//  Created by Levi Nunnink on 3/6/14.
//  Copyright (c) 2014 Levi Nunnink. All rights reserved.
//

#import "LNGIFConverter.h"
#import <AVFoundation/AVFoundation.h>

NSString* const kLNNotificationGIFCreationBegan = @"LNNotificationGIFCreationBegan";
NSString* const kLNNotificationGIFCreationProgress = @"LNNotificationGIFCreationProgress";
NSString* const kLNNotificationGIFCreationComplete = @"LNNotificationGIFCreationComplete";
NSString* const kLNGIFCreationProgressValueKey = @"LNGIFCreationProgressValueKey";
NSString* const kLNGIFCreationProgressMinValueKey = @"LNGIFCreationProgressMinValueKey";
NSString* const kLNGIFCreationProgressMaxValueKey = @"LNGIFCreationProgressMaxValueKey";

@implementation LNGIFConverter

+ (LNGIFConverter*)instance
{
    
    static LNGIFConverter* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LNGIFConverter alloc] init];
    });
    
    return instance;
}

- (NSURL*)convertFileAtPath:(NSURL *)filePath withName:(NSString *)fileName scaleFactor:(float)scale
{
    AVURLAsset* asset = [AVURLAsset URLAssetWithURL:filePath options:nil];
    
    NSString *directory = NSTemporaryDirectory();
    NSString *filename = [self captureTemporaryFilePathWithName:fileName];
    
    NSURL *saveURL = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:filename]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[saveURL path]])
    {
        NSError *err;
        if (![[NSFileManager defaultManager] removeItemAtPath:[saveURL path] error:&err])
        {
            NSLog(@"Error deleting existing movie %@",[err localizedDescription]);
        }
    } else {
        [[NSFileManager defaultManager] createFileAtPath:[saveURL path] contents:nil attributes:nil];
    }
    
    NSLog(@"Saved GIF to: %@",[saveURL path]);
    
    [self makeAnimatedGifFromAsset:asset andSaveToPath:saveURL scaleFactor:scale];
    
    return saveURL;
    
}

- (NSString*)saveImageSequenceAsGIF:(NSArray*)images withName:(NSString *)fileName
{
    NSString *directory = NSTemporaryDirectory();
    NSString *filename = [self captureTemporaryFilePathWithName:fileName];
    NSURL *saveURL = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:filename]];

    if ([[NSFileManager defaultManager] fileExistsAtPath:[saveURL path]])
    {
        NSError *err;
        if (![[NSFileManager defaultManager] removeItemAtPath:[saveURL path] error:&err])
        {
            NSLog(@"Error deleting existing movie %@",[err localizedDescription]);
        }
    } else {
        [[NSFileManager defaultManager] createFileAtPath:[saveURL path] contents:nil attributes:nil];
    }
    
    [self makeAnimatedGifFromArray:images andSaveToPath:saveURL];
    
    NSLog(@"Saved GIF to: %@",[saveURL path]);
    
    return [saveURL path];
}

#pragma mark Private Helpers

- (void) makeAnimatedGifFromArray:(NSArray*)imageArray andSaveToPath:(NSURL*)path
{
    NSDictionary *fileProperties = @{ //AWESOME!!!!
                                     (__bridge id)kCGImagePropertyGIFDictionary: @{
                                             (__bridge id)kCGImagePropertyGIFLoopCount: @0, // 0 means loop forever
                                             },
                                     (__bridge id)kCGImagePropertyHasAlpha : (id)kCFBooleanFalse};
    
    const uint8_t colorTable[ 6 ] = { 0, 0, 0, 255, 255 , 255};
    NSData* colorTableData = [ NSData dataWithBytes: colorTable length:6];
    
    NSDictionary *frameProperties = @{
                                      (__bridge id)kCGImagePropertyGIFDictionary: @{
                                              (__bridge id)kCGImagePropertyGIFDelayTime: @0.08f, // a float (not double!) in seconds, rounded to centiseconds in the GIF data
                                              (__bridge id)kCGImagePropertyGIFUnclampedDelayTime: @0.08f,
                                              (__bridge id)kCGImagePropertyHasAlpha : (id)kCFBooleanFalse
                                              },
                                      (__bridge id)kCGImagePropertyHasAlpha : (id)kCFBooleanFalse
                                      };
    
    NSUInteger frames = imageArray.count;
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)path, kUTTypeGIF, frames, NULL);
    CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)fileProperties);
    
    for (NSUInteger i = 0; i < frames; i++) {
        NSData *imageData = [[imageArray objectAtIndex:i] TIFFRepresentation];
        CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
        CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
        CGImageDestinationAddImage(destination, image, (__bridge CFDictionaryRef)frameProperties);
    }
    
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"failed to finalize image destination");
    }
    
    CFRelease(destination); //RElease?!!!
    
    NSString *launchPath = [self executablePathNamed:@"DroplrGIFHelper"];
    
    // If Gifsicle is installed, run the optimization
    if (launchPath) {
        NSArray *taskOptions = @[@"-o", path, @"-O3", @"--resize",@"480x", @"--careful",@"--no-comments",@"--no-names",@"--same-delay",@"--same-loopcount",@"--no-warnings", @"--", path];
        
        NSTask *gifTask = [[NSTask alloc] init];
        gifTask.launchPath = launchPath;
        gifTask.arguments = taskOptions;
        [gifTask launch];
        [gifTask waitUntilExit];
    }

}


- (void) makeAnimatedGifFromAsset:(AVAsset*)asset andSaveToPath:(NSURL*)path scaleFactor:(float)scaleFactor
{
    
    
    int32_t frameRate = [(AVAssetTrack*)[[asset tracks] objectAtIndex:0] nominalFrameRate];
    CMTime kFrameCount = CMTimeMakeWithSeconds(CMTimeGetSeconds(asset.duration), frameRate);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kLNNotificationGIFCreationBegan object:nil userInfo:@{kLNGIFCreationProgressMinValueKey : @(1), kLNGIFCreationProgressMaxValueKey : @(kFrameCount.value)}];
    
    
    NSLog(@"Frame Count: %lld",kFrameCount.value);
    
    AVAssetImageGenerator* imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
    imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    
    NSDictionary *fileProperties = @{
                                     (__bridge id)kCGImagePropertyGIFDictionary: @{
                                             (__bridge id)kCGImagePropertyGIFLoopCount: @0, // 0 means loop forever
                                             },
                                     (__bridge id)kCGImagePropertyHasAlpha : (id)kCFBooleanFalse};
    
//    const uint8_t colorTable[ 6 ] = { 0, 0, 0, 255, 255 , 255};
//    NSData* colorTableData = [ NSData dataWithBytes: colorTable length:6];

    NSDictionary *frameProperties = @{
                                      (__bridge id)kCGImagePropertyGIFDictionary: @{
                                              (__bridge id)kCGImagePropertyGIFDelayTime: @0.2f, // a float (not double!) in seconds, rounded to centiseconds in the GIF data
                                              (__bridge id)kCGImagePropertyGIFUnclampedDelayTime: @0.2f,
//                                              (__bridge id)kCGImagePropertyGIFImageColorMap : colorTableData,
                                              (__bridge id)kCGImagePropertyHasAlpha : (id)kCFBooleanFalse
                                              },
                                      (__bridge id)kCGImagePropertyHasAlpha : (id)kCFBooleanFalse
                                      };
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)path, kUTTypeGIF, kFrameCount.value, NULL);
    CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)fileProperties);
    
    for (CGFloat i = 1; i <= kFrameCount.value; i++) {
        @autoreleasepool {
            CGFloat progress = i / [[NSNumber numberWithInteger: kFrameCount.value] floatValue];
            [[NSNotificationCenter defaultCenter] postNotificationName:kLNNotificationGIFCreationProgress object:nil userInfo:@{kLNGIFCreationProgressValueKey : @(progress)}];
            
            NSError* err;
            CMTime actualTime;
            CMTime requestedTime = CMTimeConvertScale(CMTimeMake(i, kFrameCount.timescale), asset.duration.timescale, kCMTimeRoundingMethod_RoundHalfAwayFromZero);
            CGImageRef image = [imageGenerator copyCGImageAtTime:requestedTime actualTime:&actualTime error:&err];
            CGImageDestinationAddImage(destination, image, (__bridge CFDictionaryRef)frameProperties);
        }
    }
    
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"failed to finalize image destination");
    }
    
    CFRelease(destination);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kLNNotificationGIFCreationComplete object:nil];
    
    // If Gifsicle is installed, run the optimization
    if ([self GIFTaskExists]) {
        [self executeGIFTaskWithArgs:@[@"-o", path, @"-O3", @"--careful",@"--no-comments",@"--no-names",@"--same-delay",@"--same-loopcount", path]];
        if (scaleFactor < 1.0) {
            [self executeGIFTaskWithArgs:@[@"-o", path, [NSString stringWithFormat:@"--scale=%0.2f", scaleFactor], path]];
        }
    }
    
}

-(NSString *)executablePathNamed:(NSString*)resourceName
{
    NSString *path = nil;
    
    path = [[NSBundle mainBundle] pathForAuxiliaryExecutable:resourceName];
    if (!path) {
        path = [[NSBundle mainBundle] pathForResource:resourceName ofType:@""];
    }
    
    if (path) {
        if ([[NSFileManager defaultManager] isExecutableFileAtPath:path]) {
            return path;
        } else {
            NSLog(@"File %@ for %@ is not executable", path, resourceName);
        }
    }
    
    NSLog(@"Returning gifscicle %@ %@", resourceName,path);
    
    NSBeep();
    
    return nil;
}


- (NSString*)captureTemporaryFilePathWithName:(NSString*)name
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
    NSString* date = [dateFormatter stringFromDate:now]; //THis is cool!!!
    NSString* time = [timeFormatter stringFromDate:now];
    
    NSString *fileName = [NSString stringWithFormat:@"%@ on %@ at %@.%@", name, date, time, @"gif"];
    
    return fileName;
}

- (BOOL)GIFTaskExists
{
    return [self executablePathNamed:@"DroplrGIFHelper"] != nil;
}

- (void)executeGIFTaskWithArgs:(NSArray*)args
{
    NSString *launchPath = [self executablePathNamed:@"DroplrGIFHelper"];
    NSTask *gifTask = [[NSTask alloc] init];
    gifTask.launchPath = launchPath;
    gifTask.arguments = args;
    [gifTask launch];
    [gifTask waitUntilExit];
}


@end
