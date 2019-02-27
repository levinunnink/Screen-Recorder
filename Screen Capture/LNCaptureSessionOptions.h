//
//  LNCaptureSessionOptions.h
//  Screen Capture
//
//  Created by Levi Nunnink on 2/26/19.
//  Copyright © 2019 Levi Nunnink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LNCaptureSessionOptions : NSObject

+(LNCaptureSessionOptions*)currentOptions;

@property (strong, nullable) AVCaptureDevice *mic;
@property (assign) BOOL showMouseClicks;
@property (assign) BOOL disableAudioRecording;
@property (assign) int startDelay;
@property (assign) CGRect captureRect;

@end

NS_ASSUME_NONNULL_END
