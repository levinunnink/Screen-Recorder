//
//  SCGIFConverter.m
//  Screen Capture
//
//  Created by Levi Nunnink on 3/6/14.
//  Copyright (c) 2014 Levi Nunnink. All rights reserved.
//

#import "LNGIFConverter.h"
#import <AVFoundation/AVFoundation.h>

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

- (void)convertFileAtPath:(NSURL *)filePath
{
    AVURLAsset* asset = [AVURLAsset URLAssetWithURL:filePath options:nil];
    
    NSString *directory = NSTemporaryDirectory();
    NSString *filename = [self captureTemporaryFilePath];
    
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
    
    [self makeAnimatedGifFromAsset:asset andSaveToPath:saveURL];
    
}

#pragma mark Private Helpers

- (void) makeAnimatedGifFromAsset:(AVAsset*)asset andSaveToPath:(NSURL*)path
{
    CMTime kFrameCount = CMTimeMakeWithSeconds(CMTimeGetSeconds(asset.duration), 25);
    
    AVAssetImageGenerator* imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
    imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    
    NSDictionary *fileProperties = @{
                                     (__bridge id)kCGImagePropertyGIFDictionary: @{
                                             (__bridge id)kCGImagePropertyGIFLoopCount: @0, // 0 means loop forever
                                             }
                                     };
    
    NSDictionary *frameProperties = @{
                                      (__bridge id)kCGImagePropertyGIFDictionary: @{
                                              (__bridge id)kCGImagePropertyGIFDelayTime: @0.08f, // a float (not double!) in seconds, rounded to centiseconds in the GIF data
                                              (__bridge id)kCGImagePropertyGIFUnclampedDelayTime: @0.08f
                                              }
                                      };
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)path, kUTTypeGIF, kFrameCount.value, NULL);
    CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)fileProperties);
    
    for (NSUInteger i = 1; i <= kFrameCount.value; i++) {
        @autoreleasepool {
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
}

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
    
    NSString *fileName = [NSString stringWithFormat:@"%@ on %@ at %@.%@", @"Screencapture", date, time, @"gif"];
    
    return fileName;
}


@end
