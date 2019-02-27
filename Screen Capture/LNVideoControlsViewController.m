//
//  LNVideoControlsViewController.m
//  Screen Capture
//
//  Created by Levi Nunnink on 2/25/19.
//  Copyright © 2019 Levi Nunnink. All rights reserved.
//

#import "LNVideoControlsViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "LNCaptureSessionOptions.h"

@interface LNVideoControlsViewController ()

@property (nullable, strong) NSString* selectedMicID;
@property (assign) BOOL audioGranted;
@property (assign) BOOL videoGranted;
@property (assign) NSTimer *countdownTimer;

@end

@implementation LNVideoControlsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupMenu];
    [[LNCaptureSessionOptions currentOptions] addObserver:self forKeyPath:@"disableAudioRecording" options:NSKeyValueObservingOptionNew context:nil];
    // Do view setup here.
}

- (void)dealloc
{
    [[LNCaptureSessionOptions currentOptions] removeObserver:self forKeyPath:@"disableAudioRecording"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self setupMenu];
}

- (IBAction)setSessionOptions:(id)sender
{
    DMARK;
    NSMenuItem *item = [sender selectedItem];
    NSArray *allDevices= [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    
    switch (item.tag) {
        case LNTimerNone:
            [LNCaptureSessionOptions currentOptions].startDelay = 0;
            break;
        case LNTimerFive:
            [LNCaptureSessionOptions currentOptions].startDelay = 5;
            break;
        case LNTimerTen:
            [LNCaptureSessionOptions currentOptions].startDelay = 10;
            break;
        case LNAudioNone:
            self.selectedMicID = nil;
            [LNCaptureSessionOptions currentOptions].mic = nil;
            [LNCaptureSessionOptions currentOptions].defaultMicID = nil;
            break;
        case LNShowMouseClicks:
            [LNCaptureSessionOptions currentOptions].showMouseClicks = ![LNCaptureSessionOptions currentOptions].showMouseClicks;
            break;
        case LNAudioMic: {
            for (AVCaptureDevice *mic in allDevices) {
                if ([mic.localizedName isEqualToString:item.title]) {
                    [LNCaptureSessionOptions currentOptions].mic = mic;
                    self.selectedMicID = mic.uniqueID;
                    [LNCaptureSessionOptions currentOptions].defaultMicID = mic.uniqueID;
                }
            }
            [self requestAudioPermission];
            break;
            }
        default:
            break;
    }
    [self setupMenu];
}

- (IBAction)beginRecording:(id)sender
{
    [self requestVideoPermissionComplete:^(){
        DLOG(@"Starting countdown");
        [self countdown:[LNCaptureSessionOptions currentOptions].startDelay complete:^(){
            DLOG(@"Sending notification %@", kLNVideoControllerBeginRecordingNotification);
            [[NSNotificationCenter defaultCenter] postNotificationName:kLNVideoControllerBeginRecordingNotification object:nil];
        }];
    }];
}

- (IBAction)closeSession:(id)sender
{
    [self.countdownTimer invalidate];
    [[NSNotificationCenter defaultCenter] postNotificationName:kLNVideoControllerEndCaptureNotification object:nil];
}

#pragma mark - Private Helpers

- (void)setupMenu
{
    while([self.captureOptionsMenu itemWithTag:LNAudioMic]) {
        [self.captureOptionsMenu removeItem:[self.captureOptionsMenu itemWithTag:LNAudioMic]];
    }

    NSArray *allDevices= [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    
    NSMenuItem *noneAudioItem = [self.captureOptionsMenu itemWithTag:LNAudioNone];
    
    for(AVCaptureDevice *mic in allDevices) {
        NSMenuItem *micItem = [NSMenuItem new];
        micItem.title = mic.localizedName;
        if(self.selectedMicID && [mic.uniqueID isEqualToString:self.selectedMicID]) {
            micItem.state = NSOnState;
        }
        if([[LNCaptureSessionOptions currentOptions].defaultMicID isEqualToString:mic.uniqueID]) {
            micItem.state = NSOnState;
            [LNCaptureSessionOptions currentOptions].mic = mic;
        }
        DLOG(@"Settings %d", [LNCaptureSessionOptions currentOptions].disableAudioRecording);
        micItem.enabled = ![LNCaptureSessionOptions currentOptions].disableAudioRecording;
        micItem.tag = LNAudioMic;
        [self.captureOptionsMenu insertItem:micItem atIndex:[self.captureOptionsMenu indexOfItem:noneAudioItem]];
    }

    [self.captureOptionsMenu itemWithTag:LNShowMouseClicks].state = [LNCaptureSessionOptions currentOptions].showMouseClicks ? NSOnState : NSOffState;
    [self.captureOptionsMenu itemWithTag:LNTimerNone].state = [LNCaptureSessionOptions currentOptions].startDelay == 0 ? NSOnState : NSOffState;
    [self.captureOptionsMenu itemWithTag:LNTimerFive].state = [LNCaptureSessionOptions currentOptions].startDelay == 5 ? NSOnState : NSOffState;
    [self.captureOptionsMenu itemWithTag:LNTimerTen].state = [LNCaptureSessionOptions currentOptions].startDelay == 10 ? NSOnState : NSOffState;
    if(![LNCaptureSessionOptions currentOptions].mic) {
        [self.captureOptionsMenu itemWithTag:LNAudioNone].state = NSOnState;
    } else {
        [self.captureOptionsMenu itemWithTag:LNAudioNone].state = NSOffState;
    }
}

- (void)requestAudioPermission
{
    if (@available(macOS 10.14, *)) {
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
        self.audioGranted = status == AVAuthorizationStatusAuthorized;
        if(status != AVAuthorizationStatusAuthorized) {
            // We have to do this because the window makes the alert unclickable
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.view.window setIgnoresMouseEvents:YES];
                [self.view.window setLevel:NSNormalWindowLevel];
            });
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.view.window setIgnoresMouseEvents:NO];
                    [self.view.window setLevel:NSStatusWindowLevel];
                });
                self.audioGranted = granted;
                if(!granted){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSAlert *alert = [NSAlert new];
                        alert.messageText = @"Error trying to record audio";
                        alert.informativeText = @"Please allow access to record your mic under System Preferences > Security & Privacy > Privacy > Microphone.";
                        [alert runModal];
                    });
                }
                return;
            }];
        }
    } else {
        self.audioGranted = YES;
    }
}

- (void)requestVideoPermissionComplete:(void (^)(void))complete;
{
    if (@available(macOS 10.14, *)) {
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        self.videoGranted = status == AVAuthorizationStatusAuthorized;
        if(self.videoGranted) return complete();
        if(status != AVAuthorizationStatusAuthorized) {
            // We have to do this because the window makes the alert unclickable
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.view.window setIgnoresMouseEvents:YES];
                [self.view.window setLevel:NSNormalWindowLevel];
            });
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.view.window setIgnoresMouseEvents:NO];
                    [self.view.window setLevel:NSStatusWindowLevel];
                });
                self.videoGranted = granted;
                if(!granted){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSAlert *alert = [NSAlert new];
                        alert.messageText = @"Error trying to record your screen";
                        alert.informativeText = @"Please allow access to record your screen under System Preferences > Security & Privacy > Privacy > Camera.";
                        [alert runModal];
                    });
                } else {
                    complete();
                }
            }];
        }
    } else {
        self.videoGranted = YES;
        complete();
    }
}

- (void)countdown:(int)seconds complete:(void (^)(void))complete
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(seconds == 0) return complete();
        __block int currentSeconds = seconds;
        self.countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer *timer) {
            DLOG(@"Current seconds %d", currentSeconds);
            if(currentSeconds == 0) {
                [timer invalidate];
                self.recordButton.enabled = YES;
                [self.recordButton setTitle:@"Record"];
                return complete();
            }
            self.recordButton.enabled = NO;
            [self.recordButton setTitle:[NSString stringWithFormat:@"%d", currentSeconds]];
            currentSeconds = currentSeconds - 1;
        }];
    });
}

@end
