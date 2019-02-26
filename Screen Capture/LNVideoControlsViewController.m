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
    // Do view setup here.
}

- (IBAction)setSessionOptions:(id)sender
{
    DMARK;
    NSMenuItem *item = [sender selectedItem];
    NSArray *allDevices= [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    
    switch (item.tag) {
        case LNTimerNone:
            [LNCaptureSessionOptions currentSession].startDelay = 0;
            break;
        case LNTimerFive:
            [LNCaptureSessionOptions currentSession].startDelay = 5;
            break;
        case LNTimerTen:
            [LNCaptureSessionOptions currentSession].startDelay = 10;
            break;
        case LNAudioNone:
            self.selectedMicID = nil;
            [LNCaptureSessionOptions currentSession].mic = nil;
            break;
        case LNShowMouseClicks:
            [LNCaptureSessionOptions currentSession].showMouseClicks = ![LNCaptureSessionOptions currentSession].showMouseClicks;
            break;
        case LNAudioMic: {
            for (AVCaptureDevice *mic in allDevices) {
                if ([mic.localizedName isEqualToString:item.title]) {
                    [LNCaptureSessionOptions currentSession].mic = mic;
                    self.selectedMicID = mic.uniqueID;
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
        [self countdown:[LNCaptureSessionOptions currentSession].startDelay complete:^(){
            
        }];
    }];
}

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
        micItem.tag = LNAudioMic;
        [self.captureOptionsMenu insertItem:micItem atIndex:[self.captureOptionsMenu indexOfItem:noneAudioItem]];
    }

    [self.captureOptionsMenu itemWithTag:LNShowMouseClicks].state = [LNCaptureSessionOptions currentSession].showMouseClicks ? NSOnState : NSOffState;
    [self.captureOptionsMenu itemWithTag:LNTimerNone].state = [LNCaptureSessionOptions currentSession].startDelay == 0 ? NSOnState : NSOffState;
    [self.captureOptionsMenu itemWithTag:LNTimerFive].state = [LNCaptureSessionOptions currentSession].startDelay == 5 ? NSOnState : NSOffState;
    [self.captureOptionsMenu itemWithTag:LNTimerTen].state = [LNCaptureSessionOptions currentSession].startDelay == 10 ? NSOnState : NSOffState;
    if(![LNCaptureSessionOptions currentSession].mic) {
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
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
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

- (void)requestVideoPermissionComplete:(void (^)())complete;
{
    if (@available(macOS 10.14, *)) {
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        self.videoGranted = status == AVAuthorizationStatusAuthorized;
        if(self.videoGranted) return complete();
        if(status != AVAuthorizationStatusAuthorized) {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
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

- (void)countdown:(int)seconds complete:(void (^)())complete
{
    if(seconds == 0) return complete();
    __block int currentSeconds = seconds;
    self.countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer *timer) {
        if(currentSeconds == 0) {
            [timer invalidate];
            self.recordButton.enabled = YES;
            [self.recordButton setTitle:@"Record"];
            return complete();
        }
        self.recordButton.enabled = NO;
        [self.recordButton setTitle:[NSString stringWithFormat:@"%d s...", currentSeconds]];
        currentSeconds = currentSeconds - 1;
    }];
}

@end
