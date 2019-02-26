//
//  LNCaptureSession.h
//  Screen Capture
//
//  Created by Levi Nunnink on 2/26/19.
//  Copyright © 2019 Levi Nunnink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LNCaptureSessionOptions.h"

NS_ASSUME_NONNULL_BEGIN

@interface LNCaptureSession : NSObject

+(LNCaptureSession*)currentSession;

- (void)beginRecordingWithOptions:(LNCaptureSessionOptions*)options;
- (void)endRecordingComplete:(void (^ _Nullable)(NSError *error, NSURL *fileURL))complete;

@end

NS_ASSUME_NONNULL_END
