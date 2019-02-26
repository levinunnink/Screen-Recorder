//
//  SCCapturePanel.h
//  Screen Capture
//
//  Created by Levi Nunnink on 3/6/14.
//  Copyright (c) 2014 Levi Nunnink. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LNResizeHandle.h"

@interface LNCapturePanel : NSPanel

@property (nonatomic, assign) NSRect cropRect;

@end
