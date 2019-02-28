//
//  LNCaptureSessionOptions.m
//  Screen Capture
//
//  Created by Levi Nunnink on 2/26/19.
//  Copyright © 2019 Levi Nunnink. All rights reserved.
//

#import "LNCaptureSessionOptions.h"

#define kStartDelayKey @"kStartDelayKey"
#define kShowMouseClicksKey @"kShowMouseClicksKey"
#define kDefaultMicIdKey @"kDefaultMicIdKey"

@implementation LNCaptureSessionOptions

+ (LNCaptureSessionOptions*)currentOptions
{
    static LNCaptureSessionOptions* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        instance = [[self alloc] init];
        instance.showMouseClicks = [defaults valueForKey:kShowMouseClicksKey] ? [[defaults valueForKey:kShowMouseClicksKey] boolValue] : YES;
        instance.startDelay =  [defaults valueForKey:kStartDelayKey] ? [[defaults valueForKey:kStartDelayKey] intValue] : 5;
        instance.defaultMicID =  [defaults valueForKey:kDefaultMicIdKey] ? (NSString*)[defaults valueForKey:kDefaultMicIdKey] : nil;
        [instance addObservers];
    });
    return instance;
}

- (void)addObservers
{
    [self addObserver:self forKeyPath:@"startDelay" options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:@"showMouseClicks" options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:@"defaultMicID" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if([keyPath isEqualToString:@"startDelay"]) {
        [defaults setValue:change[NSKeyValueChangeNewKey] forKey:kStartDelayKey];
    }
    if([keyPath isEqualToString:@"showMouseClicks"]) {
        [defaults setValue:change[NSKeyValueChangeNewKey] forKey:kShowMouseClicksKey];
    }
    if([keyPath isEqualToString:@"defaultMicID"]) {
        if([change[NSKeyValueChangeNewKey] isKindOfClass:[NSNull class]]) {
            [defaults removeObjectForKey:kDefaultMicIdKey];
            [defaults synchronize];
            return;
        }
        [defaults setValue:change[NSKeyValueChangeNewKey] forKey:kDefaultMicIdKey];
    }
    [defaults synchronize];
}

@end
