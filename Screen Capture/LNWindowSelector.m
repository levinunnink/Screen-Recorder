//
//  LNWindowSelector.m
//  Screen Capture
//
//  Created by Levi Nunnink on 2/27/19.
//  Copyright © 2019 Levi Nunnink. All rights reserved.
//

#import "LNWindowSelector.h"

@implementation LNWindowSelector

+(LNWindowSelector*)windowSelectorWithWindowObject:(NSDictionary *)window positionedInFrame:(CGRect)frame
{
    LNWindowSelector *selector = [LNWindowSelector layer];
    selector.representedWindow = window;

    CGPoint windowOrigin = (CGPoint){
        [[[window[@"windowOrigin"] componentsSeparatedByString:@"/"] firstObject] floatValue],
        [[[window[@"windowOrigin"] componentsSeparatedByString:@"/"] lastObject] floatValue]
    };
    CGSize windowSize = (CGSize){
        [[[window[@"windowSize"] componentsSeparatedByString:@"*"] firstObject] floatValue],
        [[[window[@"windowSize"] componentsSeparatedByString:@"*"] lastObject] floatValue]
    };
    CGRect windowRect = (CGRect){
        windowOrigin.x,
        (frame.size.height-(windowSize.height+windowOrigin.y)),
        windowSize.width,
        windowSize.height
    };
    selector.frame = windowRect;
    selector.borderColor = [NSColor blueColor].CGColor;
    selector.borderWidth = 2.0;
    selector.opacity = 0.0;
    selector.backgroundColor = [NSColor colorWithWhite:1.0 alpha:0.1].CGColor;

    return selector;
}

@end
