//
//  LNVideoControlsViewController.h
//  Screen Capture
//
//  Created by Levi Nunnink on 2/25/19.
//  Copyright © 2019 Levi Nunnink. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum LNCaptureOptionTags {
    LNTimerNone = 1,
    LNTimerFive,
    LNTimerTen,
    LNAudioNone,
    LNShowMouseClicks,
    LNAudioMic,
} LNCaptureOptionTags;

#define kLNVideoControllerBeginRecordingNotification @"LNVideoControllerBeginRecordingNotification"
#define kLNVideoControllerEndCaptureNotification @"LNVideoControllerEndCaptureNotification"

NS_ASSUME_NONNULL_BEGIN

@interface LNVideoControlsViewController : NSViewController

@property (weak) IBOutlet NSMenu *captureOptionsMenu;
@property (weak) IBOutlet NSButton *recordButton;

- (IBAction)setSessionOptions:(id)sender;
- (IBAction)beginRecording:(id)sender;
- (IBAction)closeSession:(id)sender;

@end

NS_ASSUME_NONNULL_END
