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

@interface LNCaptureAppDelegate ()

@property (nonatomic, strong) LNCaptureWindowController *captureWindow;

@end

@implementation LNCaptureAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.captureWindow = [[LNCaptureWindowController alloc] init];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    [self.captureWindow beginScreenCaptureForScreen:[NSScreen mainScreen]];
}

@end
