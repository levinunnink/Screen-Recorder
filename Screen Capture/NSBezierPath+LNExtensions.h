//
//  NSBezierPath+LNExtensions.h
//  Screen Capture
//
//  Created by Levi Nunnink on 2/25/19.
//  Copyright © 2019 Levi Nunnink. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSBezierPath (LNExtensions)

- (CGPathRef)CGPath;
+ (NSBezierPath *)bezierPathWithCGPath:(CGPathRef)pathRef;

@end

NS_ASSUME_NONNULL_END
