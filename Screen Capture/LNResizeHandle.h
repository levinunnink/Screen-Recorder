//
//  LNResizeHandle.h
//  Screen Capture
//
//  Created by Levi Nunnink on 2/25/19.
//  Copyright © 2019 Levi Nunnink. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#define DEFAULT_HANDLE_WIDTH 8

NS_ASSUME_NONNULL_BEGIN

typedef enum LNResizePosition {
    LNResizePositionTop = 0,
    LNResizePositionTopLeft,
    LNResizePositionTopRight,
    LNResizePositionRight,
    LNResizePositionBottomRight,
    LNResizePositionBottom,
    LNResizePositionBottomLeft,
    LNResizePositionLeft,
    LNResizePositionCount,
} LNResizePosition;


@class LNResizeHandle;

@protocol LNLayerHandleDelegate <NSObject>
- (void)handle:(LNResizeHandle*)sender pointDidChangeTo:(CGPoint)point;
@end

@interface LNResizeHandle : CAShapeLayer

+(id)handleWithPosition:(LNResizePosition)position;

@property (weak)   id<LNLayerHandleDelegate> handleDelegate;
@property (assign, nonatomic) CGPoint representedPoint;
@property (assign) BOOL active;
@property (assign) BOOL selected;
@property (readonly) LNResizePosition resizeLocation;
@property (readonly) NSCursor *cursor;
@end

NS_ASSUME_NONNULL_END
