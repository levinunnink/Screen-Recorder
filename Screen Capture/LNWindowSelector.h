//
//  LNWindowSelector.h
//  Screen Capture
//
//  Created by Levi Nunnink on 2/27/19.
//  Copyright © 2019 Levi Nunnink. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface LNWindowSelector : CALayer

@property (strong) NSDictionary* representedWindow;

+(LNWindowSelector*)windowSelectorWithWindowObject:(NSDictionary*)window positionedInFrame:(CGRect)frame;

@end

NS_ASSUME_NONNULL_END
