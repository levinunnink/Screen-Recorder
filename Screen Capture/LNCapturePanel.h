//
//  SCCapturePanel.h
//  Screen Capture
//
//  Created by Levi Nunnink on 3/6/14.
//  Copyright (c) 2014 Levi Nunnink. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LNResizeHandle.h"

typedef enum LNSelectType {
    LNSelectTypeMarquee = 0,
    LNSelectTypeSnapToWindow,
} LNSelectType;

@interface LNCapturePanel : NSPanel

@property (nonatomic) NSRect cropRect;

- (void)setIsRecording:(BOOL)isRecording;
- (void)setSelectType:(LNSelectType)selectType;

@end
