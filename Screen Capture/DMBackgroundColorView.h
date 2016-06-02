//
//  DMBackgroundColorView.h
//  Screen Capture
//
//  Created by zhubch on 1/20/16.
//  Copyright © 2016 Levi Nunnink. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DMBackgroundColorView : NSView

@property (nonatomic,strong) IBInspectable NSColor *backgroundColor;

@property (nonatomic,strong) NSString *title;

@property (nonatomic,assign) CGFloat cornorRadius;

@end
