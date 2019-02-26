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
            break;
            }
        default:
            break;
    }
    [self setupMenu];
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

@end
