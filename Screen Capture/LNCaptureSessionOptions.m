//
//  LNCaptureSessionOptions.m
//  Screen Capture
//
//  Created by Levi Nunnink on 2/26/19.
//  Copyright © 2019 Levi Nunnink. All rights reserved.
//

#import "LNCaptureSessionOptions.h"

@implementation LNCaptureSessionOptions

+ (LNCaptureSessionOptions*)currentSession
{
    static LNCaptureSessionOptions* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        instance.showMouseClicks = YES;
        instance.startDelay = 5;
    });
    return instance;
}

@end
